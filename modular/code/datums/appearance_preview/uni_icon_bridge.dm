/**
 * Phase 3 bridge: `uni_icon_from_manifest(category, state_key, dir)`
 *
 * Lets runtime DM code treat any build-time appearance-preview manifest
 * entry as a declarative `/datum/universal_icon` recipe. Callers can then
 * layer further transforms (blend_color, blend_icon, crop, scale) on top
 * and hand the result to `/datum/asset/spritesheet_batched.insert_icon()`
 * without re-authoring the source (icon_file, icon_state, dir, frame)
 * tuple the build pipeline already hashed and shipped.
 *
 * Data sources (both written by the build pipeline, validated at boot by
 * `/datum/asset/simple/appearance_preview.mount_bundle`):
 *
 *   tgui/public/appearance_preview/manifest.json          — v2 envelope.
 *       Used here to resolve (category, state_key) -> family.
 *   tgui/public/appearance_preview/iconforge_plan.json    — per-family
 *       sprite recipes keyed by "<icon_state>__<dir>". Each recipe is
 *       already shaped as `{icon_file, icon_state, dir, frame, transform}`
 *       — the exact contract `/datum/universal_icon.to_list()` emits, so
 *       `universal_icon_from_list` deserialises it with no translation.
 *
 * Both files are ALSO loaded at asset-mount time; this bridge uses its own
 * lazy GLOB cache so the hot path does no fs/json work. Cache is populated
 * on first call and holds for the life of the world (bundle is immutable
 * within a round). Admin rebuild clears the cache via `_clear()` below.
 *
 * This bridge is READ-ONLY. It never invokes iconforge and never writes to
 * disk. Errors fall back to null + stack_trace so a missing/malformed
 * manifest degrades gracefully (caller can fall back to the legacy icon
 * pipeline) rather than crashing the round.
 */

/// Lazily-loaded parsed `manifest.json`. Null = not loaded yet or load
/// failed. A failed load records a stack_trace once and does not retry
/// until `uni_icon_manifest_bridge_clear_cache()` is called.
GLOBAL_VAR_INIT(appearance_preview_manifest_cache, null)
/// Lazily-loaded parsed `iconforge_plan.json`, indexed by family name.
/// Shape: list(family_name = list(sprites_key = sprite_entry_list)).
GLOBAL_LIST_EMPTY(appearance_preview_plan_sprites_by_family)
/// TRUE once we have attempted a load (success or fail) so repeated
/// lookups against a broken bundle don't re-parse the JSON every call.
GLOBAL_VAR_INIT(appearance_preview_bridge_loaded, FALSE)

/// Clear the bridge's cached parsed manifest + plan. Call this after an
/// admin rebuild of the appearance-preview bundle so the next
/// `uni_icon_from_manifest` call picks up the new data.
/proc/uni_icon_manifest_bridge_clear_cache()
	GLOB.appearance_preview_manifest_cache = null
	GLOB.appearance_preview_plan_sprites_by_family = list()
	GLOB.appearance_preview_bridge_loaded = FALSE

/// Internal: ensure the parse cache is populated. Returns TRUE on success,
/// FALSE on any parse/validation failure (logged once).
/proc/_uni_icon_manifest_bridge_ensure_loaded()
	if(GLOB.appearance_preview_bridge_loaded)
		return !isnull(GLOB.appearance_preview_manifest_cache)
	GLOB.appearance_preview_bridge_loaded = TRUE

	var/manifest_path = "tgui/public/appearance_preview/manifest.json"
	var/plan_path = "tgui/public/appearance_preview/iconforge_plan.json"
	if(!fexists(manifest_path) || !fexists(plan_path))
		stack_trace("uni_icon_from_manifest: bundle artifacts missing ([manifest_path] / [plan_path]); bridge disabled for this round")
		return FALSE

	var/manifest_raw = rustg_file_read(manifest_path)
	var/plan_raw = rustg_file_read(plan_path)
	if(!istext(manifest_raw) || !length(manifest_raw) || !istext(plan_raw) || !length(plan_raw))
		stack_trace("uni_icon_from_manifest: bundle artifacts unreadable; bridge disabled for this round")
		return FALSE

	var/list/manifest
	var/list/plan
	try
		manifest = json_decode(manifest_raw)
		plan = json_decode(plan_raw)
	catch(var/exception/e)
		stack_trace("uni_icon_from_manifest: json_decode failed ([e.name]); bridge disabled for this round")
		return FALSE

	if(!islist(manifest) || !islist(plan) || !islist(plan["jobs"]))
		stack_trace("uni_icon_from_manifest: decoded bundle has wrong shape; bridge disabled for this round")
		return FALSE

	// Index the plan's per-family sprite maps for O(1) family-keyed lookup
	// on the hot path. Each job's `sprites` key is the pre-computed
	// `<icon_state>__<dir>` compound used by the builder (see
	// tools/build/appearance_preview/rustg_bridge.ts:spritesKey).
	var/list/sprites_by_family = list()
	for(var/list/job in plan["jobs"])
		var/job_family = job["spritesheetName"]
		var/list/job_sprites = job["sprites"]
		if(istext(job_family) && length(job_family) && islist(job_sprites))
			sprites_by_family[job_family] = job_sprites

	GLOB.appearance_preview_manifest_cache = manifest
	GLOB.appearance_preview_plan_sprites_by_family = sprites_by_family
	return TRUE

/// Direction normaliser. Accepts either a BYOND dir constant (SOUTH/NORTH/
/// EAST/WEST) or a short direction string ("s"/"n"/"e"/"w") and returns
/// the short string — the compound key the builder uses. Returns null on
/// unknown input (diagonals, 0, bad text) so callers can surface it.
/proc/_uni_icon_manifest_bridge_dir_key(dir)
	if(istext(dir))
		switch(lowertext(dir))
			if("s")
				return "s"
			if("n")
				return "n"
			if("e")
				return "e"
			if("w")
				return "w"
		return null
	switch(dir)
		if(SOUTH)
			return "s"
		if(NORTH)
			return "n"
		if(EAST)
			return "e"
		if(WEST)
			return "w"
	return null

/**
 * Resolve a manifest state to a declarative `/datum/universal_icon`.
 *
 * Arguments:
 *   category  — manifest category key (e.g. "genitals", "sticker"). Must
 *               appear in `manifest.categoryOrder`.
 *   state_key — `StateRecord.iconState` within that category. Must be
 *               listed in `manifest.categories[category].states`.
 *   dir       — optional. BYOND dir const or "s"/"n"/"e"/"w". Defaults to
 *               SOUTH. Not every state declares every direction; unknown
 *               or undeclared dirs return null.
 *
 * Returns: a fresh `/datum/universal_icon` on success; null on any miss
 * (missing bundle, unknown category/state/dir). Misses stack_trace at
 * most once per (category, state_key, dir) tuple via the underlying
 * `universal_icon_from_list` — callers should treat null as "fall back to
 * the legacy icon path" rather than a hard error.
 */
/proc/uni_icon_from_manifest(category, state_key, dir = SOUTH)
	if(!istext(category) || !length(category) || !istext(state_key) || !length(state_key))
		return null
	if(!_uni_icon_manifest_bridge_ensure_loaded())
		return null

	var/list/manifest = GLOB.appearance_preview_manifest_cache
	var/list/categories = manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES]
	var/list/category_record = islist(categories) ? categories[category] : null
	if(!islist(category_record))
		return null
	var/list/category_states = category_record["states"]
	if(!islist(category_states) || !(state_key in category_states))
		return null

	var/list/states = manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_STATES]
	var/list/state_record = islist(states) ? states[state_key] : null
	if(!islist(state_record))
		return null
	var/family = state_record["family"]
	if(!istext(family) || !length(family))
		return null

	var/dir_key = _uni_icon_manifest_bridge_dir_key(dir)
	if(isnull(dir_key))
		return null
	var/list/family_sprites = GLOB.appearance_preview_plan_sprites_by_family[family]
	if(!islist(family_sprites))
		return null
	var/list/sprite_entry = family_sprites["[state_key]__[dir_key]"]
	if(!islist(sprite_entry))
		return null

	// universal_icon_from_list expects exactly the shape the plan already
	// emits: {icon_file, icon_state, dir, frame, transform}. We feed it the
	// plan entry verbatim — no translation layer, no field renames. If the
	// builder's emit shape ever drifts from `/datum/universal_icon.to_list`,
	// the ts unit test at rustg_bridge.test.ts catches it before ship.
	return universal_icon_from_list(sprite_entry)

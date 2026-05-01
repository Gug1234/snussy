/**
 * Phase 2 scaffold: per-client runtime-batched preview tile sheet.
 *
 * This is an ABSTRACT subtype of /datum/asset/spritesheet_batched. It has no
 * concrete consumer yet (spec §4.4: Phase 2 is opt-in for future editors that
 * need live-tinted per-player tile thumbnails — skin-tone-baked piercing
 * previews, wing-colour preset swatches, etc.). It exists so the next editor
 * that needs such tiles has a 20-line on-ramp rather than writing the rustg
 * plumbing from scratch.
 *
 * Contract for future concrete subtypes:
 *   1. Subclass /datum/asset/spritesheet_batched/char_preview_tiles.
 *   2. Pass a ckey to New() — instance is namespaced per ckey so two clients
 *      editing at once don't collide in the CSS classname space or the
 *      cross-round cache.
 *   3. Override create_spritesheets() to call insert_icon(name, uni_icon) for
 *      each live-composited tile. The uni_icon recipe is what rustg bakes.
 *   4. Register the instance into ui_assets() on the editor datum. The sheet
 *      is deferred through SSasset_loading until the first send() and cached
 *      cross-round via the smart-cache directory.
 *
 * CSS class namespace: "char_preview_tiles_<xxh64-of-ckey>" — short, stable,
 * non-PII (hash-only, no raw ckey leaks into DOM classnames).
 */

/datum/asset/spritesheet_batched/char_preview_tiles
	_abstract = /datum/asset/spritesheet_batched/char_preview_tiles
	/// ckey this sheet was built for. Debug/logging only; NEVER emitted into
	/// CSS or asset filenames — use `ckey_hash` for public identifiers.
	var/ckey
	/// xxh64(ckey). Cached once in New(). Used to build `name` and every
	/// public-facing identifier the sheet produces.
	var/ckey_hash

/datum/asset/spritesheet_batched/char_preview_tiles/New(owner_ckey)
	if(!istext(owner_ckey) || !length(owner_ckey))
		CRASH("char_preview_tiles: invalid owner_ckey [owner_ckey]")
	src.ckey = owner_ckey
	src.ckey_hash = rustg_hash_string(RUSTG_HASH_XXH64, owner_ckey)
	// `name` drives the sheet filename, CSS class prefix, and smart-cache
	// key. Keep it collision-free across clients by appending ckey_hash.
	// Concrete subclasses MAY append a further suffix (e.g. "_piercings")
	// by overriding New() and re-setting `name` after calling ..().
	src.name = "char_preview_tiles_[ckey_hash]"
	return ..()

/**
 * Per-ckey instance registry.
 *
 * Keeps one sheet instance per (subtype, ckey) pair so repeated opens of the
 * same editor reuse one asset datum (and therefore one rustg generate job /
 * cache-hit check). Keyed by "<subtype>::<ckey>".
 *
 * Not a GLOB list — scoped inside this file's static registry to avoid
 * leaking the storage shape. Access via
 * `GLOB.char_preview_tiles_registry[key]` is intentionally not supported.
 */
GLOBAL_LIST_EMPTY(char_preview_tiles_instances)

/**
 * Factory: return the (constructed, registered) per-ckey sheet for a
 * concrete subtype. Creates on first call, reuses thereafter.
 *
 * Call this from an editor's ui_assets():
 *     var/datum/asset/spritesheet_batched/char_preview_tiles/foo/sheet = \
 *         get_char_preview_tile_sheet(/datum/asset/spritesheet_batched/char_preview_tiles/foo, user.ckey)
 *     return list(sheet)
 *
 * Returns null on bad input rather than CRASH so the editor UI still opens
 * without tile thumbnails if the ckey pipeline hiccups.
 */
/proc/get_char_preview_tile_sheet(subtype, owner_ckey)
	if(!ispath(subtype, /datum/asset/spritesheet_batched/char_preview_tiles))
		stack_trace("get_char_preview_tile_sheet: [subtype] is not a /datum/asset/spritesheet_batched/char_preview_tiles subtype")
		return null
	if(!istext(owner_ckey) || !length(owner_ckey))
		stack_trace("get_char_preview_tile_sheet: invalid owner_ckey [owner_ckey]")
		return null
	var/key = "[subtype]::[owner_ckey]"
	var/datum/asset/spritesheet_batched/char_preview_tiles/sheet = GLOB.char_preview_tiles_instances[key]
	if(!isnull(sheet))
		return sheet
	sheet = new subtype(owner_ckey)
	GLOB.char_preview_tiles_instances[key] = sheet
	// register() kicks the sheet into SSasset_loading (deferred) or
	// realizes immediately if DO_NOT_DEFER_ASSETS is set. Matches the
	// contract every other /datum/asset/spritesheet_batched honours.
	sheet.register()
	return sheet

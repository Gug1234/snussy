/**
 * # Taur Genital Offset Editor (TGUI, v2 sheet-backed runtime)
 *
 * A lobby-specific TGUI panel for fine-tuning per-direction taur genital
 * sprite properties (offset, rotation, flip, scale, hide, layer override).
 *
 * ## v2 contract (Step 10 refactor)
 *
 * The editor is now purely client-first. TGUI owns the draft state from the
 * moment the panel opens; the server does not receive any mutation events
 * while the user is editing. On Save or Close, the client posts a single
 * `commit` action carrying a full draft snapshot. The server validates,
 * sanitises, persists, and refreshes the lobby mannequin exactly once per
 * commit.
 *
 * Removed in this step: per-field server actions (`set_field`, `nudge_field`,
 * `toggle_field`, `reset_dir`, `reset_part`, `mirror_east_to_west`,
 * `toggle_global_hide`), the mannequin-side preview renderer
 * (`_get_preview_base64`, `_build_part_preview`), and the dirty-on-destroy
 * commit (client now owns the dirty flag and drives the commit explicitly).
 *
 * ## Preview pipeline
 *
 * The client still renders from the shared v2 sheet manifest, but Step 10 now
 * exposes `hybrid_descriptors` with server-resolved guide layer icon states.
 * The legacy `preview_descriptors` payload remains until Step 11 migrates the
 * TSX renderer to `HybridOffsetOverlay`.
 */

/// Rate-limit for ui_act() calls per client. With per-field actions removed
/// legitimate traffic is now &lt;=2/sec (part/dir tab switches + commit); this
/// ceiling exists only to catch a jammed client or a scripted abuser.
#define TAUR_EDITOR_MAX_ACTS_PER_SECOND 10
/// Rolling window (in deciseconds) used to count recent ui_act() calls.
#define TAUR_EDITOR_RATE_WINDOW_DS 10
/// Cooldown (in deciseconds) between admin notifications for the same abuser,
/// so a flood doesn't spam the admin channel.
#define TAUR_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS 300
/// Singleton guard: at most one taur genital editor per client. Repeat opens
/// focus/refresh the existing window instead of spawning duplicates.
/client/var/datum/taur_genital_offset_editor/taur_genital_editor_instance

/**
 * Opener for the taur genital offset editor.
 *
 * Arguments:
 *   user      — the mob requesting the editor. Required.
 *   part      — initial part tab to focus (`penis` / `testicles` / `vagina`).
 *   standalone — Phase-1 Step 9 routing flag.
 *     * `FALSE` (default, player path): routes through the tabbed
 *       PreferencesMenu shell. The prefs datum switches to the
 *       `taur_offsets` tab and binds this editor to `prefs.active_editor`
 *       with the active part as target metadata. The preview view currently
 *       hides the taur family while editing; later hybrid-overlay steps
 *       narrow that to the active part. The standalone TGUI window is ALSO
 *       opened — roguetown's
 *       taur editor carries a full client-side draft + commit envelope
 *       that cannot be inlined into the shell's ui_data without a much
 *       larger refactor, so the window rides alongside the shell for
 *       Phase 1. The singleton enforcement lives on the prefs datum.
 *     * `TRUE` (admin / debug path): legacy behaviour — per-client
 *       singleton, no prefs tab binding, standalone window only. Kept
 *       under the APPEARANCE_PREVIEW_LEGACY_FLATTEN compile flag contract
 *       for admin VV tooling.
 */
/datum/preferences/proc/open_taur_genital_editor(mob/user, part = "penis", standalone = FALSE)
	if(!user || !(part in GLOB.taur_genital_part_keys))
		return
	var/client/opening_client = user.client
	// Reuse any existing open window on this client. Works for both
	// standalone and player paths — the singleton lives on /client regardless
	// of who opened it so a second call from any path refocuses.
	if(opening_client?.taur_genital_editor_instance)
		var/datum/taur_genital_offset_editor/existing = opening_client.taur_genital_editor_instance
		if(QDELETED(existing))
			opening_client.taur_genital_editor_instance = null
		else
			existing.initial_part = part
			if(!standalone)
				// Keep the prefs tab in sync with the focused editor.
				set_active_tab(APPEARANCE_PREVIEW_TAB_TAUR_OFFSETS)
				set_active_editor(existing, APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, part)
			existing.ui_interact(user)
			return
	var/datum/taur_genital_offset_editor/editor = new(src, part)
	if(opening_client)
		opening_client.taur_genital_editor_instance = editor
		editor.owning_client = opening_client
	if(!standalone)
		// Player path: bind to the prefs singleton so the preview view's
		// strip pass knows which taur part is under edit. The current preview
		// view hides the taur family as the smallest safe fallback; Step 10
		// narrows this once DM emits server-resolved guide descriptors.
		set_active_tab(APPEARANCE_PREVIEW_TAB_TAUR_OFFSETS)
		set_active_editor(editor, APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, part)
	editor.ui_interact(user)

/**
 * Tab-exit hook (addendum §12.5). Called by `/datum/preferences/set_active_tab`
 * via `hascall` when the user navigates away from the taur_offsets tab
 * with `prefs.active_editor == src`.
 *
 * Phase 1 Step 9: the taur editor carries its own client-side draft and
 * commit pipeline, so the "save or discard" resolution has already been
 * handled client-side (via DirtyModal) by the time this hook fires. We
 * close the window so the next tab open starts fresh; any uncommitted
 * draft is lost (client already acknowledged via Discard) and any
 * committed state is already persisted.
 */
/datum/taur_genital_offset_editor/proc/_on_tab_exit()
	SStgui.close_uis(src)

/datum/taur_genital_offset_editor
	parent_type = /datum/appearance_preview_editor
	editor_kind = APPEARANCE_PREVIEW_EDITOR_KIND_TAUR
	pref_key = "taur_genital_offsets"
	family_id = APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS
	/// Initial part tab the TSX should focus on open. Not tracked after open;
	/// the client owns active-tab state once the window is up.
	var/initial_part = "penis"
	/// Shared Topic() flood limiter. Replaces the old per-editor state fields.
	var/datum/ui_act_rate_limiter/rate_limiter
	/// Client that opened this editor; used to clear the singleton slot on close.
	var/client/owning_client

/datum/taur_genital_offset_editor/New(datum/preferences/P, part = "penis")
	if(!P)
		qdel(src)
		return
	prefs = P
	if(part in GLOB.taur_genital_part_keys)
		initial_part = part
	rate_limiter = new(
		"Taur genital editor",
		TAUR_EDITOR_MAX_ACTS_PER_SECOND,
		TAUR_EDITOR_RATE_WINDOW_DS,
		TAUR_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS,
	)

/datum/taur_genital_offset_editor/Destroy()
	// v2 note: dirty state lives on the client. If the window is destroyed
	// without an explicit commit (e.g. the client hard-closed the browser),
	// the draft is lost -- the server's persisted state is still consistent
	// with the last successful commit, so this is safe.
	if(owning_client?.taur_genital_editor_instance == src)
		owning_client.taur_genital_editor_instance = null
	owning_client = null
	prefs = null
	QDEL_NULL(rate_limiter)
	return ..()

/datum/taur_genital_offset_editor/ui_close(mob/user)
	user?.client?.prefs_resume_after_singleton()
	qdel(src)

/datum/taur_genital_offset_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TaurGenitalOffsetEditor", "Taur Genital Offsets", 560, 640)
		ui.open()

/datum/taur_genital_offset_editor/ui_state(mob/user)
	return GLOB.always_state

/**
 * Hide every taur genital overlay on the mannequin backdrop. The editor's
 * live preview tile is the movable/colourable sprite the player is
 * editing -- baking the committed genital into the mannequin too would
 * render a second, frozen copy at the saved offset (see user-reported
 * "doppelganger" bug). `apply_taur_genital_offsets` short-circuits and
 * cuts its appearance list when the per-direction global-hide flag is
 * set, so flipping all four cardinals to 1 on the mannequin copy is the
 * cheapest way to scrub the overlay without tearing organs off the
 * dummy (which would desync `sexcon` state for other passes).
 */
/datum/taur_genital_offset_editor/_strip_mannequin_for_preview(mob/living/carbon/human/dummy/mannequin)
	if(!mannequin)
		return
	mannequin.taur_genital_global_hide = list("s" = 1, "n" = 1, "e" = 1, "w" = 1)

/**
 * Ensures all four prefs lists are populated with sanitized defaults before
 * they're serialised into ui_data. Idempotent -- safe to call on every open.
 */
/datum/taur_genital_offset_editor/proc/_ensure_sanitized_state()
	if(!prefs)
		return
	prefs.ensure_sanitized_taur_genital_props()

/**
 * Returns the customizer entry for the requested taur part, or null if none
 * is set. Pure read, no side effects.
 */
/datum/preferences/proc/_get_taur_customizer_entry(part)
	if(!customizer_entries)
		return null
	var/prefix = null
	switch(part)
		if("penis")
			prefix = "/datum/customizer_choice/organ/penis"
		if("testicles")
			prefix = "/datum/customizer_choice/organ/testicles"
		if("vagina")
			prefix = "/datum/customizer_choice/organ/vagina"
	if(!prefix)
		return null
	for(var/datum/customizer_entry/entry as anything in customizer_entries)
		if(!entry?.customizer_choice_type)
			continue
		var/choice_type = "[entry.customizer_choice_type]"
		if(choice_type == prefix || findtext(choice_type, prefix) == 1)
			return entry
	return null

/**
 * Builds the shared taur preview source model used by the legacy tile preview
 * and the new hybrid guide descriptor resolver.
 *
 * The source model contains only server-owned data: selected part, resolved
 * sprite-accessory shape, sanitized tint colors, and organ-specific size /
 * sheath metadata. Callers still choose the direction and arousal state when
 * resolving a concrete guide layer.
 */
/datum/preferences/proc/_build_taur_preview_descriptor_source(part, erect_state = null)
	var/datum/customizer_entry/entry = _get_taur_customizer_entry(part)
	if(!entry)
		return null

	var/datum/customizer_choice/customizer_choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
	if(!customizer_choice)
		return null

	var/datum/organ_dna/preview_dna = customizer_choice.create_organ_dna(entry, src)
	if(!preview_dna || !ispath(preview_dna.organ_type, /obj/item/organ))
		return null

	var/obj/item/organ/preview_organ = preview_dna.create_organ(null)
	if(!preview_organ)
		return null

	if(part == "penis" && isnum(erect_state) && istype(preview_organ, /obj/item/organ/penis))
		var/obj/item/organ/penis/preview_penis = preview_organ
		preview_penis.erect_state = clamp(round(erect_state), ERECT_STATE_NONE, ERECT_STATE_HARD)

	var/datum/sprite_accessory/accessory = null
	if(preview_organ.accessory_type)
		accessory = SPRITE_ACCESSORY(preview_organ.accessory_type)

	if(!preview_organ.accessory_colors && accessory)
		preview_organ.accessory_colors = accessory.get_default_colors(color_key_source_list_from_prefs(src))

	// Tint colours — emitted as an ordered list so the TSX compositor can
	// map each entry onto its DMI color-key layer (`_1`, `_2`). See
	// Remediation Step 3 note in earlier revisions.
	var/list/colors_out = list()
	var/raw_colors = preview_organ.accessory_colors
	if(islist(raw_colors))
		for(var/color_entry in raw_colors)
			if(!istext(color_entry))
				continue
			var/trimmed = trim(color_entry)
			if(length(trimmed))
				colors_out += trimmed
	else if(istext(raw_colors) && length(raw_colors))
		for(var/color_entry in splittext(raw_colors, ","))
			var/trimmed = trim(color_entry)
			if(length(trimmed))
				colors_out += trimmed

	var/list/out = list(
		"part" = part,
		"shape" = accessory ? accessory.icon_state : null,
		"colors" = colors_out,
	)

	switch(part)
		if("penis")
			out["uses_size_sprites"] = 1
			if(istype(preview_organ, /obj/item/organ/penis))
				var/obj/item/organ/penis/pp = preview_organ
				if(istype(accessory, /datum/sprite_accessory/penis))
					var/datum/sprite_accessory/penis/pen_acc = accessory
					out["uses_size_sprites"] = pen_acc.uses_size_sprites ? 1 : 0
				out["size"] = pp.penis_size
				out["sheath_type"] = pp.sheath_type
			else
				out["size"] = DEFAULT_PENIS_SIZE
				out["sheath_type"] = SHEATH_TYPE_NONE
		if("testicles")
			if(istype(preview_organ, /obj/item/organ/testicles))
				var/obj/item/organ/testicles/tt = preview_organ
				out["size"] = tt.ball_size
			else
				out["size"] = DEFAULT_TESTICLES_SIZE

	return out

/**
 * Emits one server-resolved hybrid guide descriptor for a taur target.
 *
 * This is the Step 10 replacement for TS-side runtime state composition. The
 * descriptor carries the manifest category and concrete guide layer state that
 * TGUI should render; the client only decides local transforms until commit.
 */
/datum/preferences/proc/build_taur_hybrid_offset_descriptor(target_key, dir_key, erect_state = null)
	var/part = taur_genital_part_from_target_key(target_key)
	if(!part)
		return null
	var/resolved_erect_state = null
	if(part == "penis")
		var/fallback_erect_state = isnum(erect_state) ? erect_state : preview_erect_state
		resolved_erect_state = taur_genital_erect_state_from_target_key(target_key, fallback_erect_state)

	var/list/source = _build_taur_preview_descriptor_source(part, resolved_erect_state)
	if(!islist(source))
		return null

	var/guide_icon_state = taur_genital_resolve_guide_icon_state(
		part,
		source["shape"],
		dir_key,
		resolved_erect_state,
		source["size"],
		source["sheath_type"],
		source["uses_size_sprites"],
	)
	if(!guide_icon_state)
		return null

	var/list/layer = list(
		HYBRID_OFFSET_LAYER_KEY_ICON_STATE = guide_icon_state,
		HYBRID_OFFSET_LAYER_KEY_ROLE = HYBRID_OFFSET_LAYER_ROLE_GUIDE,
	)
	var/list/colors = source["colors"]
	if(islist(colors) && length(colors))
		layer[HYBRID_OFFSET_LAYER_KEY_COLOR] = colors.Copy()

	var/resolved_target = taur_genital_hybrid_target_key(part, resolved_erect_state)
	var/manifest_category = taur_genital_manifest_category(part)
	return hybrid_offset_build_descriptor(
		APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS,
		resolved_target,
		dir_key,
		manifest_category,
		list(layer),
		GLOB.taur_genital_field_keys,
		HYBRID_OFFSET_DEFAULT_NATIVE_SIZE,
		HYBRID_OFFSET_DEFAULT_NATIVE_SIZE,
		islist(colors) && length(colors),
	)

/**
 * Builds all taur guide descriptors the standalone editor needs on open.
 *
 * Penis descriptors are keyed by arousal state and direction. Testicles and
 * vaginas are keyed directly by direction because they have a single visual
 * state in the current offset editor contract.
 */
/datum/preferences/proc/build_taur_hybrid_offset_descriptor_grid()
	var/list/out = list()
	for(var/part in GLOB.taur_genital_part_keys)
		if(part == "penis")
			var/list/by_state = list()
			for(var/erect_state in GLOB.taur_genital_erect_state_keys)
				var/list/by_dir = list()
				var/target_key = taur_genital_hybrid_target_key(part, erect_state)
				for(var/dir_key in GLOB.taur_genital_dir_keys)
					by_dir[dir_key] = build_taur_hybrid_offset_descriptor(target_key, dir_key, erect_state)
				by_state["[erect_state]"] = by_dir
			out[part] = by_state
			continue
		var/list/by_dir = list()
		for(var/dir_key in GLOB.taur_genital_dir_keys)
			by_dir[dir_key] = build_taur_hybrid_offset_descriptor(part, dir_key)
		out[part] = by_dir
	return out

/**
 * Builds the legacy config descriptor still consumed by the current TSX.
 * Step 11 will remove the TS-side compositor and use `hybrid_descriptors`
 * instead; until then both payloads are emitted from the same server source.
 */
/datum/taur_genital_offset_editor/proc/_get_preview_descriptor(part, erect_state = null)
	if(!prefs)
		return null
	return prefs._build_taur_preview_descriptor_source(part, erect_state)

/**
 * Returns the customizer entry for the requested taur part, or null if none
 * is set. Pure read, no side effects.
 */
/datum/taur_genital_offset_editor/proc/_get_taur_customizer_entry(part)
	if(!prefs)
		return null
	return prefs._get_taur_customizer_entry(part)

/**
 * Builds the legacy preview-descriptor map the current TSX still needs to
 * render every part. Arousal tabs are handled client-side for this payload.
 * Step 11 will swap the renderer to `hybrid_descriptors`, where DM already
 * resolved the concrete guide layer icon states.
 *
 * Shape:
 *   penis     : descriptor | null
 *   testicles : descriptor | null
 *   vagina    : descriptor | null
 */
/datum/taur_genital_offset_editor/proc/_build_preview_descriptors()
	var/list/out = list()
	out["penis"] = _get_preview_descriptor("penis")
	out["testicles"] = _get_preview_descriptor("testicles")
	out["vagina"] = _get_preview_descriptor("vagina")
	return out

/datum/taur_genital_offset_editor/proc/_build_hybrid_descriptors()
	if(!prefs)
		return list()
	return prefs.build_taur_hybrid_offset_descriptor_grid()

/datum/taur_genital_offset_editor/ui_data(mob/user)
	_ensure_sanitized_state()
	var/list/data = list()
	data += appearance_preview_editor_manifest_metadata()
	data += appearance_preview_editor_commit_metadata(src)
	data["mannequin_previews"] = build_mannequin_previews(user)
	data["initial_part"] = initial_part
	data["initial_erect_state"] = prefs ? prefs.preview_erect_state : ERECT_STATE_NONE
	data["part_keys"] = GLOB.taur_genital_part_keys
	data["erect_state_keys"] = GLOB.taur_genital_erect_state_keys
	data["erect_state_labels"] = GLOB.taur_genital_erect_state_labels
	data["dir_keys"] = GLOB.taur_genital_dir_keys
	data["field_keys"] = GLOB.taur_genital_field_keys
	data["preview_descriptors"] = _build_preview_descriptors()
	data["hybrid_descriptors"] = _build_hybrid_descriptors()

	// Full initial prop snapshot for every (part x arousal) combination.
	// The client uses this once to seed its draft state; subsequent edits
	// never touch the server until commit.
	var/list/initial_snapshot = list()
	initial_snapshot["penis_state_props"] = prefs ? prefs.taur_penis_erect_state_props : default_taur_penis_erect_state_props()
	initial_snapshot["testicles_props"] = prefs ? prefs.taur_testicles_props : default_taur_genital_props("testicles")
	initial_snapshot["vagina_props"] = prefs ? prefs.taur_vagina_props : default_taur_genital_props("vagina")
	initial_snapshot["global_hide"] = prefs ? prefs.taur_genital_global_hide : sanitize_taur_genital_global_hide(null)
	data["initial_snapshot"] = initial_snapshot

	return data

/datum/taur_genital_offset_editor/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!prefs)
		return FALSE
	if(rate_limiter?.check_blocked(usr))
		return FALSE

	switch(action)
		if("commit")
			// Pipeline records success/failure into last_commit_result; we
			// always return TRUE so TGUI pushes updated ui_data and the
			// client can read the outcome.
			appearance_preview_process_commit(src, params)
			return TRUE

		if("close")
			SStgui.close_uis(src)
			return TRUE

	return FALSE

/**
 * Accepts a full draft snapshot from the client, sanitises every block
 * through the existing `sanitize_*` helpers (which clamp, type-coerce, and
 * drop unknown keys), and writes the result into prefs. Does NOT itself
 * persist to disk or refresh the mannequin -- that is the caller's job via
 * `appearance_preview_commit_taur_genital_offset_editor`.
 *
 * Returns TRUE on a structurally-valid snapshot, FALSE otherwise. A missing
 * block is treated as "no change" for that block rather than an error, so
 * partial UIs (e.g. a future editor that only manipulates testicles) stay
 * forward-compatible.
 */
/datum/taur_genital_offset_editor/_apply_snapshot(list/snapshot)
	if(!prefs)
		return FALSE
	if(!islist(snapshot))
		return FALSE

	// Penis arousal-state map: { "0": props, "1": props, "2": props }.
	var/list/penis_state = snapshot["penis_state_props"]
	if(islist(penis_state))
		var/list/sanitized_states = list()
		for(var/erect_state in GLOB.taur_genital_erect_state_keys)
			var/key = "[erect_state]"
			var/list/raw = penis_state[key]
			sanitized_states[key] = sanitize_taur_genital_props(islist(raw) ? raw : null, "penis")
		prefs.taur_penis_erect_state_props = sanitized_states
		// Mirror the flaccid (state 0) entry into the legacy flat field so
		// downstream code that hasn't migrated to the per-state map keeps
		// working. Type the intermediate lookup so dreamchecker knows .Copy()
		// targets a /list.
		var/list/flaccid_entry = sanitized_states["[ERECT_STATE_NONE]"]
		// Defensive: sanitize_taur_genital_props is expected to always return
		// a list, but guard the `.Copy()` call so a future regression in the
		// sanitizer cannot runtime-null-deref here and tear down the commit
		// pipeline mid-apply. The fallback is the canonical default penis
		// props, which matches the sanitizer's own fallback.
		if(!islist(flaccid_entry))
			flaccid_entry = default_taur_genital_props("penis")
		prefs.taur_penis_props = flaccid_entry.Copy()

	// Testicles / vagina are single-state.
	var/list/testicles = snapshot["testicles_props"]
	if(islist(testicles))
		prefs.taur_testicles_props = sanitize_taur_genital_props(testicles, "testicles")

	var/list/vagina = snapshot["vagina_props"]
	if(islist(vagina))
		prefs.taur_vagina_props = sanitize_taur_genital_props(vagina, "vagina")

	// Global per-direction hide overlay.
	var/list/global_hide = snapshot["global_hide"]
	if(islist(global_hide))
		prefs.taur_genital_global_hide = sanitize_taur_genital_global_hide(global_hide)

	prefs.taur_genital_props_dirty = FALSE

	return TRUE

/**
 * Step 4 remediation — two-phase persist hooks for the taur editor.
 *
 * Taur has no sidecar files; its entire state lives in the main prefs
 * file. `_stage_persist` is therefore just the defensive re-sanitize
 * that used to live in `_persist`, and `_flush_persist` is a no-op (the
 * pipeline calls `update_preview_icon` after the flush so the single-
 * refresh guarantee still holds).
 *
 * `_capture_prefs_snapshot` / `_restore_prefs_snapshot` shallow-copy the
 * five prefs fields `_apply_snapshot` writes. A shallow copy is safe
 * because `_apply_snapshot` always assigns a *new* list reference — it
 * never mutates the old lists in place — so restoring the old reference
 * on `save_character()` failure fully rolls back the in-memory state.
 */
/datum/taur_genital_offset_editor/_capture_prefs_snapshot()
	if(!prefs)
		prefs_snapshot = null
		return
	prefs_snapshot = list(
		"taur_penis_erect_state_props" = islist(prefs.taur_penis_erect_state_props) ? prefs.taur_penis_erect_state_props.Copy() : prefs.taur_penis_erect_state_props,
		"taur_penis_props" = islist(prefs.taur_penis_props) ? prefs.taur_penis_props.Copy() : prefs.taur_penis_props,
		"taur_testicles_props" = islist(prefs.taur_testicles_props) ? prefs.taur_testicles_props.Copy() : prefs.taur_testicles_props,
		"taur_vagina_props" = islist(prefs.taur_vagina_props) ? prefs.taur_vagina_props.Copy() : prefs.taur_vagina_props,
		"taur_genital_global_hide" = islist(prefs.taur_genital_global_hide) ? prefs.taur_genital_global_hide.Copy() : prefs.taur_genital_global_hide,
	)

/datum/taur_genital_offset_editor/_restore_prefs_snapshot()
	if(!prefs || !islist(prefs_snapshot))
		return
	prefs.taur_penis_erect_state_props = prefs_snapshot["taur_penis_erect_state_props"]
	prefs.taur_penis_props = prefs_snapshot["taur_penis_props"]
	prefs.taur_testicles_props = prefs_snapshot["taur_testicles_props"]
	prefs.taur_vagina_props = prefs_snapshot["taur_vagina_props"]
	prefs.taur_genital_global_hide = prefs_snapshot["taur_genital_global_hide"]
	prefs.taur_genital_props_dirty = FALSE

/datum/taur_genital_offset_editor/_stage_persist()
	if(!prefs)
		return FALSE
	_ensure_sanitized_state()
	return TRUE

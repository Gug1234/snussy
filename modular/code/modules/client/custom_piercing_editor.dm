/**
 * # Custom Piercing Editor (TGUI, v2 sheet-backed runtime)
 *
 * Lobby-capable TGUI panel for the two custom-piercing surfaces:
 *   1. Regular intimate accessory rows (typepath dropdowns mirroring the
 *      lobby intimate accessory menu, plus per-slot directional offsets).
 *   2. Freeform sticker slots (player-authored sticker stacks with
 *      per-entry colours, body-zone gates, and per-direction props).
 *
 * ## v2 contract (Step 11 refactor)
 *
 * Client-first. TGUI owns both draft surfaces from the moment the panel
 * opens; the server does not receive any mutation events while the user is
 * editing. On Save or Close, the client posts a single `commit` action
 * carrying a full snapshot of both surfaces. The server validates,
 * sanitises, persists, and refreshes the lobby mannequin exactly once per
 * commit.
 *
 * Removed in this step: per-field server actions
 * (set_slot_prop_field, nudge_slot_prop_field, reset_slot_props,
 * set_regular_slot_equipped, select_entry, toggle_slot_enabled,
 * toggle_suppress_legacy, set_slot_display_name, toggle_hide_from_examine,
 * add_entry, remove_entry, move_entry, set_color, pick_color,
 * toggle_hide_when_covered, set_entry_zone, set_prop_field,
 * nudge_prop_field, toggle_prop_field, reset_entry_props, set_name_desc,
 * commit_drag, save, select_slot). The dirty-on-destroy autosave is also
 * gone -- client now owns the dirty flag and drives the commit explicitly.
 *
 * Retained server actions: `commit`, `close`, `export_preset`,
 * `import_preset`, `close_io_modal`. Export/import must round-trip through
 * the server because the sanitize + JSON-validate pipeline lives in DM;
 * everything else is pure client state.
 */

/// Rate-limit for ui_act() calls per client. With per-field actions removed
/// legitimate traffic is now commit + close + io on explicit user events,
/// well under 2/sec. This ceiling exists only to catch a jammed client or a
/// scripted abuser.
#define CUSTOM_PIERCING_EDITOR_MAX_ACTS_PER_SECOND 10
/// Rolling window (in deciseconds) used to count recent ui_act() calls.
#define CUSTOM_PIERCING_EDITOR_RATE_WINDOW_DS 10
/// Cooldown (in deciseconds) between admin notifications for the same abuser,
/// so a flood doesn't spam the admin channel.
#define CUSTOM_PIERCING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS 300

/// Singleton guard: at most one custom piercing editor per client. Repeat
/// opens refocus the existing window onto the requested slot instead of
/// spawning duplicates.
/client/var/datum/custom_piercing_editor/custom_piercing_editor_instance

/**
 * Opener for the custom piercing / intimate accessories editor.
 *
 * Arguments:
 *   user       — the mob requesting the editor. Required.
 *   slot_key   — optional freeform sticker slot to focus on open.
 *   standalone — Phase-1 Step 10 routing flag (mirrors Step 9 taur
 *     editor). `FALSE` (default, player path): routes through the
 *     tabbed PreferencesMenu shell — sets `active_tab` to
 *     `intimate_accessories` and binds the editor to
 *     `prefs.active_editor` with the focused slot as target metadata.
 *     The preview view currently suppresses the custom piercing family
 *     while editing; later hybrid-overlay steps narrow that to the
 *     selected entry. The
 *     standalone TGUI window is also opened alongside the shell; the
 *     editor's client-side draft + commit envelope cannot be inlined
 *     into the shell ui_data without a larger refactor. `TRUE`
 *     (admin / debug path): legacy behaviour — per-client singleton
 *     only, no prefs tab binding.
 */
/datum/preferences/proc/open_custom_piercing_editor(mob/user, slot_key, standalone = FALSE)
	if(!user)
		return
	if(slot_key && !(slot_key in GLOB.custom_piercing_freeform_slots))
		slot_key = null
	var/client/opening_client = user.client
	if(opening_client?.custom_piercing_editor_instance)
		var/datum/custom_piercing_editor/existing = opening_client.custom_piercing_editor_instance
		if(QDELETED(existing))
			opening_client.custom_piercing_editor_instance = null
		else
			// Refocus the existing window on the requested slot instead of
			// spawning a second one. The initial_slot field feeds the TSX
			// active-tab seed only; the client is still free to switch tabs.
			if(slot_key)
				existing.initial_slot = slot_key
			if(!standalone)
				set_active_tab(APPEARANCE_PREVIEW_TAB_INTIMATE_ACCESSORIES)
				set_active_editor(existing, APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, existing.get_initial_preview_target_key())
			existing.ui_interact(user)
			return
	var/datum/custom_piercing_editor/editor = new(src, slot_key)
	if(opening_client)
		opening_client.custom_piercing_editor_instance = editor
		editor.owning_client = opening_client
	if(!standalone)
		// Player path: bind to the prefs singleton so the preview view's
		// strip pass knows which slot is under edit. The current preview view
		// suppresses the first selected entry through the composer/post-render
		// path; later TGUI migration can update the active target when the
		// selected entry changes without touching drag movement.
		set_active_tab(APPEARANCE_PREVIEW_TAB_INTIMATE_ACCESSORIES)
		set_active_editor(editor, APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, editor.get_initial_preview_target_key())
	editor.ui_interact(user)

/**
 * Tab-exit hook (addendum §12.5). Called by `/datum/preferences/set_active_tab`
 * via `hascall` when the user navigates away from the
 * intimate_accessories tab with `prefs.active_editor == src`.
 *
 * Phase 1 Step 10: the editor carries its own client-side draft and
 * commit pipeline, so the "save or discard" resolution has already been
 * handled client-side (via DirtyModal) by the time this hook fires. We
 * close the window so the next tab open starts fresh.
 */
/datum/custom_piercing_editor/proc/_on_tab_exit()
	SStgui.close_uis(src)

/**
 * Returns the preview target key matching the entry the TGUI editor selects
 * on open. The current client draft initializes `activeEntry` to zero, so a
 * focused freeform slot maps to the first stored entry (`slot:1`). Empty slots
 * still return a valid key; the composer skip is harmless when no entry exists.
 */
/datum/custom_piercing_editor/proc/get_initial_preview_target_key()
	if(!(initial_slot in GLOB.custom_piercing_freeform_slots))
		return null
	return custom_piercing_hybrid_target_key(initial_slot, 1)

/datum/custom_piercing_editor
	parent_type = /datum/appearance_preview_editor
	editor_kind = APPEARANCE_PREVIEW_EDITOR_KIND_CUSTOM_PIERCING
	pref_key = "custom_piercings"
	family_id = APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS
	/// Slot tab the client should open on. Updated by refocus opens; the TSX
	/// reads it only as the initial seed and never sends it back.
	var/initial_slot = null
	/// Shared Topic() flood limiter. Caught per-client, not per-editor.
	var/datum/ui_act_rate_limiter/rate_limiter
	/// Transient export payload. Populated by `export_preset` and surfaced
	/// in ui_data so the TSX can display it in a copy-able text area.
	/// Cleared on `close_io_modal` or editor destroy. Never persisted.
	var/export_payload = null
	/// Transient import status ("ok: ..." / "error: ..."). Set by
	/// `import_preset` so the TSX can surface feedback.
	var/import_status = null
	/// Transient import payload. When an `import_preset` succeeds, this
	/// holds the sanitised `custom_piercings` map the client should re-seed
	/// its freeform draft from. Cleared after the client re-seeds (via
	/// `close_io_modal`).
	var/list/import_payload = null
	/// Client that opened this editor; used to clear the singleton slot on
	/// close.
	var/client/owning_client

/datum/custom_piercing_editor/New(datum/preferences/P, slot_key)
	if(!P)
		qdel(src)
		return
	prefs = P
	if(slot_key in GLOB.custom_piercing_freeform_slots)
		initial_slot = slot_key
	rate_limiter = new(
		"Custom piercing editor",
		CUSTOM_PIERCING_EDITOR_MAX_ACTS_PER_SECOND,
		CUSTOM_PIERCING_EDITOR_RATE_WINDOW_DS,
		CUSTOM_PIERCING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS,
	)

/datum/custom_piercing_editor/Destroy()
	// v2 contract: no auto-commit on destroy. The client owns the dirty
	// flag and is responsible for posting `commit` before `close`.
	if(owning_client?.custom_piercing_editor_instance == src)
		owning_client.custom_piercing_editor_instance = null
	owning_client = null
	prefs = null
	import_payload = null
	QDEL_NULL(rate_limiter)
	return ..()

/datum/custom_piercing_editor/ui_close(mob/user)
	user?.client?.prefs_resume_after_singleton()
	qdel(src)

/datum/custom_piercing_editor/ui_state(mob/user)
	return GLOB.always_state

/**
 * Scrub every custom piercing off the mannequin backdrop. The editor
 * overlays the live accessory sprite on top; keeping the committed
 * piercings in the mannequin snapshot would render a second, static
 * copy at the saved offset (user-reported "doppelganger" bug). We also
 * clear the regular accessory slots tracked by this editor so the
 * backdrop shows the bare body the player is actually aligning against.
 */
/datum/custom_piercing_editor/_strip_mannequin_for_preview(mob/living/carbon/human/dummy/mannequin)
	if(!mannequin)
		return
	mannequin.custom_piercings = null
	mannequin.custom_piercing_post_render_suppressed = TRUE

/datum/custom_piercing_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CustomPiercingEditor", "Intimate Accessories", 820, 720)
		// Match the lobby-capable sister editors: pin the ui state to
		// always_state on creation and via ui_state() so status resolution
		// from /mob/dead/new_player is unambiguous.
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/custom_piercing_editor/ui_data(mob/user)
	var/list/data = list()
	data += appearance_preview_editor_manifest_metadata()
	data += appearance_preview_editor_commit_metadata(src)

	data["mannequin_previews"] = build_mannequin_previews(user)

	data["initial_slot"] = initial_slot
	data["slot_keys"] = GLOB.custom_piercing_freeform_slots
	data["slot_labels"] = GLOB.custom_piercing_slot_labels
	data["freeform_slots"] = GLOB.custom_piercing_freeform_slots
	data["entry_zones"] = GLOB.custom_piercing_entry_zones
	data["entry_zone_labels"] = GLOB.custom_piercing_entry_zone_labels
	data["dir_keys"] = GLOB.custom_piercing_dir_keys
	data["field_keys"] = GLOB.custom_piercing_field_keys
	data["sticker_icon"] = "[CUSTOM_PIERCING_STICKER_ICON]"
	data["max_per_slot"] = CUSTOM_PIERCING_MAX_PER_SLOT
	data["max_total"] = CUSTOM_PIERCING_MAX_TOTAL_ENTRIES
	data["max_name_length"] = CUSTOM_PIERCING_MAX_NAME_LENGTH
	data["max_desc_length"] = CUSTOM_PIERCING_MAX_DESC_LENGTH
	data["offset_min"] = CUSTOM_PIERCING_OFFSET_MIN
	data["offset_max"] = CUSTOM_PIERCING_OFFSET_MAX
	data["default_metal_color"] = CUSTOM_PIERCING_DEFAULT_METAL_COLOR
	data["default_gem_color"] = CUSTOM_PIERCING_DEFAULT_GEM_COLOR

	// Sticker registry â€” static per session but small enough to inline.
	var/list/registry_out = list()
	for(var/id in GLOB.custom_piercing_stickers)
		var/datum/piercing_sticker/S = GLOB.custom_piercing_stickers[id]
		if(!S)
			continue
		var/list/suggested_slots = list()
		if(islist(S.suggested_slots))
			suggested_slots = S.suggested_slots.Copy()
		var/list/sticker_data = list()
		sticker_data["id"] = S.id
		sticker_data["name"] = S.name
		sticker_data["category"] = S.category
		sticker_data["has_gem"] = S.has_gem ? 1 : 0
		sticker_data["directional"] = S.directional ? 1 : 0
		sticker_data["suggested_slots"] = suggested_slots
		sticker_data["manifest_category"] = S.get_preview_manifest_category()
		// Server-resolved layer prototypes let TGUI assemble a descriptor for
		// new unsaved entries without duplicating the DMI naming convention.
		// Colours stay on the draft entry; these prototype layers carry only
		// whitelisted icon_state + semantic role metadata.
		sticker_data["hybrid_layers"] = custom_piercing_build_sticker_hybrid_guide_layers(S, null, null, FALSE)
		registry_out[id] = sticker_data
	data["sticker_registry"] = registry_out

	// Initial snapshot: the client seeds both surfaces from here once on
	// mount and then owns the draft state until commit. Refocus opens push
	// a fresh snapshot; the client must re-seed when initial_slot changes
	// (the TSX watches for this).
	if(prefs)
		prefs.ensure_custom_piercings()
		data["hybrid_descriptors"] = prefs.build_custom_piercing_hybrid_offset_descriptor_grid()
		data["initial_snapshot"] = list(
			"custom_piercings" = prefs.custom_piercings,
			"regular_slots" = prefs.get_custom_piercing_editor_regular_slot_data(),
		)
	else
		data["hybrid_descriptors"] = list()
		data["initial_snapshot"] = list(
			"custom_piercings" = list(),
			"regular_slots" = list(),
		)

	// Transient io-modal state. Never persisted.
	data["export_payload"] = export_payload
	data["import_status"] = import_status
	data["import_payload"] = import_payload

	return data

/datum/custom_piercing_editor/ui_act(action, list/params)
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

		if("export_preset")
			// Client sends its current live draft for snapshotting so the
			// export reflects unsaved edits. Sanitise, then emit as JSON in
			// the transient export_payload field.
			var/list/cp_draft = params["custom_piercings"]
			if(!islist(cp_draft))
				cp_draft = list()
			var/list/cleaned = sanitize_custom_piercings(cp_draft) || list()
			export_payload = json_encode(list(
				"version" = 1,
				"piercings" = cleaned,
			))
			import_status = null
			import_payload = null
			return TRUE

		if("import_preset")
			// Replace-mode import: decode, sanitize, stash in import_payload
			// for the client to re-seed its freeform draft from.
			var/raw = params["payload"]
			if(!istext(raw) || !length(raw))
				import_status = "error: empty input"
				import_payload = null
				return TRUE
			// Cap input size to prevent decode-bomb griefing -- a healthy
			// full export is under 32 KB even at max entries.
			if(length(raw) > 131072)
				import_status = "error: payload too large"
				import_payload = null
				return TRUE
			var/decoded = safe_json_decode(raw)
			if(!islist(decoded))
				import_status = "error: invalid JSON"
				import_payload = null
				return TRUE
			var/list/slot_map
			if(islist(decoded["piercings"]))
				slot_map = decoded["piercings"]
			else
				slot_map = decoded
			var/list/cleaned = sanitize_custom_piercings(slot_map)
			if(!cleaned || !length(cleaned))
				import_status = "error: no valid entries"
				import_payload = null
				return TRUE
			var/total = 0
			for(var/k in cleaned)
				var/list/c = cleaned[k]
				if(islist(c))
					total += length(c["entries"])
			import_status = "ok: imported [total] entries across [length(cleaned)] slot(s)"
			import_payload = cleaned
			export_payload = null
			return TRUE

		if("close_io_modal")
			export_payload = null
			import_status = null
			import_payload = null
			return TRUE

		if("close")
			SStgui.close_uis(src)
			return TRUE
	return FALSE

/**
 * Applies a client-provided snapshot to prefs. Routes freeform custom
 * piercings through `sanitize_custom_piercings`, and regular accessory
 * slots through the existing per-slot setters + legacy fallback fields.
 * Returns TRUE on success, FALSE if the snapshot shape is invalid.
 *
 * Commit is all-or-nothing: a malformed snapshot shape aborts before any
 * write, so a rejected commit leaves the last-saved state intact and the
 * client's dirty flag stays set.
 */
/datum/custom_piercing_editor/_apply_snapshot(list/snapshot)
	if(!islist(snapshot))
		return FALSE
	if(!prefs)
		return FALSE

	// --- Freeform sticker slots -------------------------------------------------
	var/list/cp = snapshot["custom_piercings"]
	if(!islist(cp))
		cp = list()
	prefs.custom_piercings = sanitize_custom_piercings(cp) || list()
	prefs.custom_piercings_dirty = FALSE
	prefs.custom_piercings_version += 1

	// --- Regular accessory slot dropdowns ---------------------------------------
	// Shape: list("<slot_key>" = "<option display name>" | null, ...).
	// Unknown slot keys and unknown options are silently skipped; the
	// options list is authoritative.
	var/list/regular = snapshot["regular_slots"]
	if(islist(regular))
		for(var/slot_key in regular)
			_apply_regular_slot(slot_key, regular[slot_key])

	return TRUE

/**
 * Applies a single regular-slot selection from the commit snapshot.
 * `chosen_name` is the dropdown option label; null / missing / invalid
 * names are treated as "no change" to preserve the user's previous choice
 * when a migration removes an option mid-session.
 */
/datum/custom_piercing_editor/proc/_apply_regular_slot(slot_key, chosen_name)
	if(!istext(slot_key))
		return
	var/list/options = prefs.get_custom_piercing_slot_options(slot_key)
	if(!islist(options))
		return
	if(!istext(chosen_name) || !(chosen_name in options))
		return
	var/typepath = options[chosen_name]
	switch(slot_key)
		if("genital_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("genital", typepath)
		if("genital_insertable")
			prefs.set_custom_piercing_slot_equipped_typepath("insertable_genital", typepath)
		if("rear_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("rear", typepath)
		if("rear_insertable")
			prefs.set_custom_piercing_slot_equipped_typepath("insertable_rear", typepath)
		if("breast_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("breast", typepath)
		if("breast_insertable")
			prefs.pref_intimate_breast_insertable = typepath
		if("mouth_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("tongue", typepath)
		if("mouth_insertable")
			prefs.pref_intimate_mouth_insertable = typepath
		if("ear_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("ear", typepath)
		if("nose_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("nose", typepath)
		if("belly_piercing")
			prefs.set_custom_piercing_slot_equipped_typepath("belly", typepath)

/**
 * Step 4 remediation — two-phase persist hooks for the custom-piercing
 * editor.
 *
 * `_stage_persist` re-sanitises `prefs.custom_piercings` (defensive,
 * matches the pre-Step-4 behaviour) and computes the sidecar payload via
 * `compute_custom_piercings_payload`. It buffers the payload into
 * `pending_sidecars` WITHOUT writing to disk. The pipeline then runs
 * `save_character()` and, only on success, the base `_flush_persist`
 * drains `pending_sidecars` atomically (write-temp-then-replace). On
 * `save_character()` failure the buffered payload is discarded by
 * `_revert_persist`, so the sidecar can never race ahead of the main
 * prefs file.
 *
 * `_capture_prefs_snapshot` shallow-copies `custom_piercings`. Regular
 * slot fields mutated by `_apply_regular_slot` live in the main prefs
 * file, so a `save_character()` failure leaves them unsaved on disk;
 * the draft stays dirty on the client and the next successful commit
 * re-applies them.
 */
/datum/custom_piercing_editor/_capture_prefs_snapshot()
	if(!prefs)
		prefs_snapshot = null
		return
	prefs_snapshot = list(
		"custom_piercings" = islist(prefs.custom_piercings) ? prefs.custom_piercings.Copy() : prefs.custom_piercings,
	)

/datum/custom_piercing_editor/_restore_prefs_snapshot()
	if(!prefs || !islist(prefs_snapshot))
		return
	prefs.custom_piercings = prefs_snapshot["custom_piercings"]
	prefs.custom_piercings_dirty = FALSE

/datum/custom_piercing_editor/_stage_persist()
	if(!prefs)
		return FALSE
	prefs.ensure_sanitized_custom_piercings()
	var/staged_slot = sanitize_integer(prefs.default_slot, 1, prefs.max_save_slots, 1)
	var/list/payload = prefs.compute_custom_piercings_payload(staged_slot)
	if(!islist(payload))
		// No sidecar directory available (headless test env). Treat as
		// success — there is nothing to flush — so the commit pipeline can
		// still persist the main prefs file.
		pending_sidecars = null
		return TRUE
	pending_sidecars = list(payload)
	return TRUE

/// IC verb: opens the custom piercing editor for the calling player.
/// Mirrors open_sex_flavor_editor -- intimate content gated on `chastenable`.
/mob/living/carbon/human/verb/open_custom_piercing_editor()
	set name = "Edit Custom Piercings"
	set category = "IC"

	if(!client?.prefs || !client.prefs.chastenable)
		to_chat(src, span_warning("I have intimate content disabled."))
		return

	client.prefs.open_custom_piercing_editor(src)

#undef CUSTOM_PIERCING_EDITOR_MAX_ACTS_PER_SECOND
#undef CUSTOM_PIERCING_EDITOR_RATE_WINDOW_DS
#undef CUSTOM_PIERCING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS

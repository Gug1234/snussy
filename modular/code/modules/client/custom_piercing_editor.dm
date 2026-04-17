/**
 * custom_piercing_editor.dm — TGUI panel for building per-character sticker piercings.
 *
 * Uses the same dirty-flag + explicit-save pattern as the custom sex flavor
 * editor: mutations only touch in-memory state and set `dirty = TRUE`. The
 * sidecar JSON is written only on the "Save" button or when the editor
 * datum is destroyed (autosave on window close). This keeps 200+ concurrent
 * editors from hammering disk on every keystroke/nudge.
 *
 * Preview rendering is fully client-side: the TSX composites raw sticker DMI
 * thumbnails using the entry props (x/y/turn/shrink/metal_color). The server
 * never generates a mannequin snapshot. Drag edits use a ghost-commit pattern
 * (see PreviewPanel in the TSX): during a drag, zero Topic() calls fire; on
 * mouseup a single `commit_drag` fires and batches x+y into one dirty-flip.
 */

/// Hard rate-limit on ui_act() calls. Matches the taur editor defaults.
#define CUSTOM_PIERCING_EDITOR_MAX_ACTS_PER_SECOND 25
#define CUSTOM_PIERCING_EDITOR_RATE_WINDOW_DS 10
#define CUSTOM_PIERCING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS 300

/// Singleton guard: at most one custom piercing editor per client. Repeat opens
/// focus/refresh the existing window instead of spawning duplicates.
/client/var/datum/custom_piercing_editor/custom_piercing_editor_instance

/datum/preferences/proc/open_custom_piercing_editor(mob/user, slot_key)
	if(!user)
		return
	if(slot_key && !(slot_key in GLOB.custom_piercing_slot_keys))
		slot_key = null
	var/client/opening_client = user.client
	if(opening_client?.custom_piercing_editor_instance)
		var/datum/custom_piercing_editor/existing = opening_client.custom_piercing_editor_instance
		if(QDELETED(existing))
			opening_client.custom_piercing_editor_instance = null
		else
			// Refocus the existing window on the requested slot instead of spawning a second one.
			if(slot_key)
				existing.active_slot = slot_key
				existing.prefs?.get_custom_piercing_slot(slot_key)
			existing.ui_interact(user)
			return
	var/datum/custom_piercing_editor/editor = new(src, slot_key)
	if(opening_client)
		opening_client.custom_piercing_editor_instance = editor
		editor.owning_client = opening_client
	editor.ui_interact(user)

/datum/custom_piercing_editor
	/// The preferences datum we're editing.
	var/datum/preferences/prefs
	/// Currently-focused slot key (may be null at the picker screen).
	var/active_slot
	/// Currently-selected entry index within the active slot (1-based; 0 = none).
	var/active_entry = 0
	/// TRUE when in-memory data has changed since the last save.
	var/dirty = FALSE
	/// Shared Topic() flood limiter. Replaces the old per-editor state fields.
	var/datum/ui_act_rate_limiter/rate_limiter
	/// Transient export payload. Populated by `export_preset` and surfaced
	/// in ui_data so the TSX can display it in a copy-able text area. Cleared
	/// on `close_io_modal`, slot changes, or editor destroy. Never persisted.
	var/export_payload = null
	/// Transient import status string ("ok" / "error: ..."). Populated by
	/// `import_preset`; the TSX uses it to show success/error feedback.
	var/import_status = null
	/// Client that opened this editor; used to clear the singleton slot on close.
	var/client/owning_client

/datum/custom_piercing_editor/New(datum/preferences/P, slot_key)
	if(!P)
		qdel(src)
		return
	prefs = P
	if(slot_key in GLOB.custom_piercing_slot_keys)
		active_slot = slot_key
		// Ensure the slot cfg exists so the TSX SlotPanel mounts on first
		// open even when the player has never saved any custom piercings.
		prefs.get_custom_piercing_slot(active_slot)
	rate_limiter = new(
		"Custom piercing editor",
		CUSTOM_PIERCING_EDITOR_MAX_ACTS_PER_SECOND,
		CUSTOM_PIERCING_EDITOR_RATE_WINDOW_DS,
		CUSTOM_PIERCING_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS,
	)

/datum/custom_piercing_editor/Destroy()
	if(dirty)
		// Autosave on window close so players don't lose in-progress edits.
		_persist()
		dirty = FALSE
	if(owning_client?.custom_piercing_editor_instance == src)
		owning_client.custom_piercing_editor_instance = null
	owning_client = null
	prefs = null
	QDEL_NULL(rate_limiter)
	return ..()

/datum/custom_piercing_editor/ui_close(mob/user)
	qdel(src)

/datum/custom_piercing_editor/ui_state(mob/user)
	return GLOB.always_state

/datum/custom_piercing_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CustomPiercingEditor", "Custom Piercings", 820, 720)
		// Match the lobby-capable sister editors (sex_flavor_editor,
		// intimate_reaction_editor): pin the ui state to always_state on
		// creation as well as via ui_state(), so status resolution from
		// /mob/dead/new_player is unambiguous.
		ui.set_state(GLOB.always_state)
		ui.open()

/// Full payload for the TSX. Sister lobby-capable editors (taur, sex flavor,
/// intimate reaction) deliver everything via ui_data because ui_static_data
/// does not reach the lobby player reliably. We match that pattern here:
/// schema keys, caps, defaults, and the sticker registry are all shipped on
/// every tick alongside the mutable state. The sticker_registry iteration is
/// light (reads pre-built GLOB datum fields, no string work) so inlining is
/// cheaper than caching and copying.
/datum/custom_piercing_editor/ui_data(mob/user)
	var/list/data = list()

	if(prefs)
		prefs.ensure_custom_piercings()
		data["custom_piercings"] = prefs.custom_piercings
	else
		data["custom_piercings"] = list()

	data["active_slot"] = active_slot
	data["active_entry"] = active_entry
	data["dirty"] = dirty
	data["export_payload"] = export_payload
	data["import_status"] = import_status

	data["slot_keys"] = GLOB.custom_piercing_slot_keys
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
	data["default_metal_color"] = CUSTOM_PIERCING_DEFAULT_METAL_COLOR
	data["default_gem_color"] = CUSTOM_PIERCING_DEFAULT_GEM_COLOR

	var/list/registry_out = list()
	for(var/id in GLOB.custom_piercing_stickers)
		var/datum/piercing_sticker/S = GLOB.custom_piercing_stickers[id]
		if(!S)
			continue
		registry_out[id] = list(
			"id" = S.id,
			"name" = S.name,
			"category" = S.category,
			"has_gem" = S.has_gem ? 1 : 0,
			"directional" = S.directional ? 1 : 0,
			"suggested_slots" = S.suggested_slots?.Copy() || list(),
		)
	data["sticker_registry"] = registry_out

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
		if("select_slot")
			var/slot = params["slot"]
			if(slot in GLOB.custom_piercing_slot_keys)
				active_slot = slot
				active_entry = 0
				// Auto-materialize a default slot config on first focus so
				// the TSX SlotPanel mounts even for players who have never
				// saved a piercing layout. get_custom_piercing_slot() is a
				// no-op if the cfg already exists. Not flagged dirty: an
				// empty default config produced purely by tab navigation
				// should not force a save.
				if(prefs)
					prefs.get_custom_piercing_slot(active_slot)
				return TRUE

		if("select_entry")
			active_entry = _clamp_entry_index(text2num_safe(params["index"], 0))
			return TRUE

		if("toggle_slot_enabled")
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			slot_cfg["enabled"] = slot_cfg["enabled"] ? 0 : 1
			dirty = TRUE
			return TRUE

		if("toggle_suppress_legacy")
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			slot_cfg["suppress_legacy"] = slot_cfg["suppress_legacy"] ? 0 : 1
			dirty = TRUE
			return TRUE

		if("set_slot_display_name")
			// Player-authored label for freeform slots. Shown in the editor
			// tabs and the examine hook. Sanitize identically to entry
			// custom_name so the two share length + escape rules.
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			var/raw = params["name"]
			if(!istext(raw))
				slot_cfg["display_name"] = null
			else
				var/cleaned = strip_html_simple(sanitize_simple(html_decode(copytext(raw, 1, CUSTOM_PIERCING_MAX_NAME_LENGTH + 1))))
				slot_cfg["display_name"] = length(cleaned) ? cleaned : null
			dirty = TRUE
			return TRUE

		if("toggle_hide_from_examine")
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			slot_cfg["hide_from_examine"] = slot_cfg["hide_from_examine"] ? 0 : 1
			dirty = TRUE
			return TRUE

		if("add_entry")
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			var/sticker_id = params["sticker"]
			var/datum/piercing_sticker/S = get_custom_piercing_sticker(sticker_id)
			if(!S)
				return FALSE
			if(!_check_caps(slot_cfg))
				to_chat(usr, span_warning("Too many piercings. Remove one first."))
				return FALSE
			var/list/new_entry = list(
				"sticker" = S.id,
				"metal_color" = CUSTOM_PIERCING_DEFAULT_METAL_COLOR,
				"gem_color" = S.has_gem ? CUSTOM_PIERCING_DEFAULT_GEM_COLOR : null,
				"props" = default_custom_piercing_props(),
				"custom_name" = null,
				"custom_desc" = null,
				"hide_when_covered" = 0,
				"zone" = "",
			)
			slot_cfg["entries"] += list(new_entry)
			active_entry = length(slot_cfg["entries"])
			dirty = TRUE
			return TRUE

		if("remove_entry")
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			var/idx = text2num_safe(params["index"], 0)
			var/list/entries = slot_cfg["entries"]
			if(idx < 1 || idx > length(entries))
				return FALSE
			entries.Cut(idx, idx + 1)
			if(active_entry == idx)
				active_entry = 0
			else if(active_entry > idx)
				active_entry--
			dirty = TRUE
			return TRUE

		if("move_entry")
			var/list/slot_cfg = _active_slot_cfg()
			if(!slot_cfg)
				return FALSE
			var/idx = text2num_safe(params["index"], 0)
			var/delta = text2num_safe(params["delta"], 0)
			var/list/entries = slot_cfg["entries"]
			var/new_idx = idx + delta
			if(idx < 1 || idx > length(entries) || new_idx < 1 || new_idx > length(entries))
				return FALSE
			var/list/moved = entries[idx]
			entries.Cut(idx, idx + 1)
			entries.Insert(new_idx, null)
			entries[new_idx] = moved
			if(active_entry == idx)
				active_entry = new_idx
			dirty = TRUE
			return TRUE

		if("set_color")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/which = params["which"]
			var/color = sanitize_hexcolor(params["color"], 6, TRUE, null)
			if(!color)
				return FALSE
			switch(which)
				if("metal")
					entry["metal_color"] = color
				if("gem")
					var/datum/piercing_sticker/S = get_custom_piercing_sticker(entry["sticker"])
					if(!S?.has_gem)
						return FALSE
					entry["gem_color"] = color
				else
					return FALSE
			dirty = TRUE
			return TRUE

		if("pick_color")
			// Opens the native BYOND color picker for metal/gem. Needed
			// because BYOND's embedded browser can't use <input type=color>.
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/which = params["which"]
			var/current
			switch(which)
				if("metal")
					current = entry["metal_color"] || CUSTOM_PIERCING_DEFAULT_METAL_COLOR
				if("gem")
					var/datum/piercing_sticker/S = get_custom_piercing_sticker(entry["sticker"])
					if(!S?.has_gem)
						return FALSE
					current = entry["gem_color"] || CUSTOM_PIERCING_DEFAULT_GEM_COLOR
				else
					return FALSE
			var/new_color = input(usr, "Pick [which] color", "Custom Piercing", current) as color|null
			if(!new_color)
				return FALSE
			new_color = sanitize_hexcolor(new_color, 6, TRUE, null)
			if(!new_color)
				return FALSE
			if(which == "metal")
				entry["metal_color"] = new_color
			else
				entry["gem_color"] = new_color
			dirty = TRUE
			return TRUE

		if("toggle_hide_when_covered")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			entry["hide_when_covered"] = entry["hide_when_covered"] ? 0 : 1
			dirty = TRUE
			return TRUE

		if("set_entry_zone")
			// Per-entry body-zone gate. Empty string = always visible; any
			// other value must be in the allowlist or the change is rejected.
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/new_zone = params["zone"]
			if(!istext(new_zone))
				new_zone = ""
			if(!(new_zone in GLOB.custom_piercing_entry_zones))
				return FALSE
			entry["zone"] = new_zone
			dirty = TRUE
			return TRUE

		if("set_prop_field")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/dir_key = params["dir"]
			var/field = params["field"]
			if(!(dir_key in GLOB.custom_piercing_dir_keys))
				return FALSE
			if(!(field in GLOB.custom_piercing_field_keys))
				return FALSE
			var/list/props = entry["props"]
			if(!islist(props))
				props = default_custom_piercing_props()
				entry["props"] = props
			props["[dir_key][field]"] = params["value"]
			entry["props"] = sanitize_custom_piercing_props(props)
			dirty = TRUE
			return TRUE

		if("nudge_prop_field")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/dir_key = params["dir"]
			var/field = params["field"]
			if(!(dir_key in GLOB.custom_piercing_dir_keys))
				return FALSE
			if(!(field in GLOB.custom_piercing_field_keys))
				return FALSE
			var/list/props = entry["props"]
			if(!islist(props))
				props = default_custom_piercing_props()
				entry["props"] = props
			var/key = "[dir_key][field]"
			var/delta = text2num_safe(params["delta"], 0)
			props[key] = text2num_safe(props[key], 0) + delta
			entry["props"] = sanitize_custom_piercing_props(props)
			dirty = TRUE
			return TRUE

		if("toggle_prop_field")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/dir_key = params["dir"]
			var/field = params["field"]
			if(!(dir_key in GLOB.custom_piercing_dir_keys))
				return FALSE
			if(!(field in list("flip", "above", "hide")))
				return FALSE
			var/list/props = entry["props"]
			if(!islist(props))
				props = default_custom_piercing_props()
				entry["props"] = props
			var/key = "[dir_key][field]"
			props[key] = props[key] ? 0 : 1
			dirty = TRUE
			return TRUE

		if("reset_entry_props")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			entry["props"] = default_custom_piercing_props()
			dirty = TRUE
			return TRUE

		if("set_name_desc")
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			entry["custom_name"] = params["name"]
			entry["custom_desc"] = params["desc"]
			var/list/cleaned = sanitize_custom_piercing_entry(entry)
			if(cleaned)
				entry["custom_name"] = cleaned["custom_name"]
				entry["custom_desc"] = cleaned["custom_desc"]
			dirty = TRUE
			return TRUE

		if("commit_drag")
			// Called once on mouseup at the end of a client-side ghost-drag.
			// Batches any subset of {x, y, turn, shrink} absolute values into
			// a single dirty-flip, instead of one set_prop_field per axis.
			// No server-side preview regen needed — the piercing editor's
			// preview is composited client-side from DmIcon thumbnails, so
			// offset/rotation/scale changes cost exactly one ui_act call.
			var/list/entry = _entry_at(params["index"])
			if(!entry)
				return FALSE
			var/dir_key = params["dir"]
			if(!(dir_key in GLOB.custom_piercing_dir_keys))
				return FALSE
			var/list/props = entry["props"]
			if(!islist(props))
				props = default_custom_piercing_props()
				entry["props"] = props
			var/any_applied = FALSE
			for(var/field in list("x", "y", "turn", "shrink"))
				if(!(field in params))
					continue
				if(!(field in GLOB.custom_piercing_field_keys))
					continue
				props["[dir_key][field]"] = params[field]
				any_applied = TRUE
			if(!any_applied)
				return FALSE
			entry["props"] = sanitize_custom_piercing_props(props)
			dirty = TRUE
			return TRUE

		if("save")
			if(dirty)
				_persist()
				dirty = FALSE
			return TRUE

		if("export_preset")
			// Snapshots the current (sanitized) config into a player-readable
			// JSON string. Does NOT touch disk. The TSX renders this in a
			// readonly textarea with a clipboard-copy button.
			prefs.ensure_custom_piercings()
			var/list/envelope = list(
				"version" = 1,
				"piercings" = prefs.custom_piercings,
			)
			export_payload = json_encode(envelope)
			import_status = null
			return TRUE

		if("import_preset")
			// Replace-mode import: decode, sanitize, assign. Accepts either
			// the envelope format from `export_preset` or a bare slot map
			// (so fragments pasted from older sidecar files also work).
			var/raw = params["payload"]
			if(!istext(raw) || !length(raw))
				import_status = "error: empty input"
				return TRUE
			// Cap input size to prevent decode-bomb griefing — a healthy
			// full export is under 32 KB even at max entries.
			if(length(raw) > 131072)
				import_status = "error: payload too large"
				return TRUE
			var/decoded = safe_json_decode(raw)
			if(!islist(decoded))
				import_status = "error: invalid JSON"
				return TRUE
			var/list/slot_map
			if(islist(decoded["piercings"]))
				slot_map = decoded["piercings"]
			else
				slot_map = decoded
			var/list/cleaned = sanitize_custom_piercings(slot_map)
			if(!cleaned || !length(cleaned))
				import_status = "error: no valid entries"
				return TRUE
			prefs.custom_piercings = cleaned
			dirty = TRUE
			active_entry = 0
			export_payload = null
			var/total = 0
			for(var/k in cleaned)
				var/list/c = cleaned[k]
				if(islist(c))
					total += length(c["entries"])
			import_status = "ok: imported [total] entries across [length(cleaned)] slot(s)"
			return TRUE

		if("close_io_modal")
			export_payload = null
			import_status = null
			return TRUE

		if("close")
			SStgui.close_uis(src)
			return TRUE
	return FALSE

/// Returns the active slot's config list (creating it on demand). Null if no
/// slot is selected or the slot key is invalid.
/datum/custom_piercing_editor/proc/_active_slot_cfg()
	if(!(active_slot in GLOB.custom_piercing_slot_keys))
		return null
	return prefs.get_custom_piercing_slot(active_slot)

/// Resolves a 1-based entry index into the actual entry list. Null if oob.
/datum/custom_piercing_editor/proc/_entry_at(raw_index)
	var/list/slot_cfg = _active_slot_cfg()
	if(!slot_cfg)
		return null
	var/idx = text2num_safe(raw_index, 0)
	var/list/entries = slot_cfg["entries"]
	if(!islist(entries) || idx < 1 || idx > length(entries))
		return null
	return entries[idx]

/// Clamps an entry index into [0, len]. 0 means "nothing selected".
/datum/custom_piercing_editor/proc/_clamp_entry_index(idx)
	var/list/slot_cfg = _active_slot_cfg()
	var/list/entries = slot_cfg?["entries"]
	var/max_idx = islist(entries) ? length(entries) : 0
	return clamp(idx, 0, max_idx)

/// Verifies per-slot and global entry caps before adding a new entry.
/datum/custom_piercing_editor/proc/_check_caps(list/slot_cfg)
	var/list/entries = slot_cfg["entries"]
	if(length(entries) >= CUSTOM_PIERCING_MAX_PER_SLOT)
		return FALSE
	prefs.ensure_custom_piercings()
	var/total = 0
	for(var/key in prefs.custom_piercings)
		var/list/other = prefs.custom_piercings[key]
		if(!islist(other))
			continue
		total += length(other["entries"])
	if(total >= CUSTOM_PIERCING_MAX_TOTAL_ENTRIES)
		return FALSE
	return TRUE

/// Persists `custom_piercings` to the sidecar JSON. Only called on explicit
/// save (the "Save" button) or on editor destroy (autosave on window close).
/datum/custom_piercing_editor/proc/_persist()
	if(!prefs)
		return
	prefs.custom_piercings = sanitize_custom_piercings(prefs.custom_piercings)
	prefs.save_custom_piercings(prefs.default_slot)

/// IC verb: opens the custom piercing editor for the calling player.
/// Mirrors open_sex_flavor_editor — intimate content gated on `chastenable`.
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

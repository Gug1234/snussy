/**
 * preferences_custom_piercings.dm — Modular extension to /datum/preferences.
 *
 * Adds the `custom_piercings` character-scoped list and its sidecar JSON
 * load/save helpers. Data is stored in a per-slot sidecar file
 * (custom_piercings_[slot].json) to avoid the BYOND savefile ~64 KB per-entry
 * limit; a single character with many stickers can approach the cap easily.
 *
 * Load is owned by the normal character-slot read path. Writes are owned by
 * the custom-piercing editor's two-phase commit pipeline: the editor computes
 * a payload before /datum/preferences/proc/save_character(), then flushes that
 * payload only after the main savefile write succeeds. Keeping the sidecar out
 * of save_character() prevents custom_piercings_[slot].json from advancing
 * ahead of the authoritative character savefile.
 */

/datum/preferences
	/**
	 * Per-character custom piercing configuration.
	 *
	 * Shape (associative, keyed by entries in GLOB.custom_piercing_slot_keys):
	 *   "ear" = list(
	 *     "enabled"         = 0|1,
	 *     "suppress_legacy" = 0|1,
	 *     "entries"         = list(list(sticker, metal_color, gem_color,
	 *                                    props, custom_name, custom_desc,
	 *                                    hide_when_covered), ...),
	 *   ),
	 *   ...
	 *
	 * null when the player has not configured any custom piercings.
	 * Serialized to the per-slot sidecar file custom_piercings_[slot].json.
	 *
	 * Normalized on load, import/editor commit, save, and copy_to. Hot read
	 * helpers assume that boundary validation has already happened.
	 */
	var/list/custom_piercings = null
	/// TRUE when taur genital props need a sanitize pass.
	var/tmp/taur_genital_props_dirty = TRUE
	/// TRUE when custom piercing prefs need a sanitize pass.
	var/tmp/custom_piercings_dirty = TRUE
	/// Monotonic version for sanitized custom piercing state.
	var/tmp/custom_piercings_version = 0

/datum/preferences/proc/mark_taur_genital_props_dirty()
	taur_genital_props_dirty = TRUE

/datum/preferences/proc/mark_custom_piercings_dirty()
	custom_piercings_dirty = TRUE

/datum/preferences/proc/ensure_sanitized_taur_genital_props()
	if(!taur_genital_props_dirty)
		return
	taur_penis_props = sanitize_taur_genital_props(taur_penis_props, "penis")
	taur_penis_erect_state_props = sanitize_taur_penis_erect_state_props(taur_penis_erect_state_props, taur_penis_props)
	taur_testicles_props = sanitize_taur_genital_props(taur_testicles_props, "testicles")
	taur_vagina_props = sanitize_taur_genital_props(taur_vagina_props, "vagina")
	taur_genital_global_hide = sanitize_taur_genital_global_hide(taur_genital_global_hide)
	taur_genital_props_dirty = FALSE

/datum/preferences/proc/ensure_sanitized_custom_piercings()
	if(!custom_piercings_dirty)
		return
	custom_piercings = sanitize_custom_piercings(custom_piercings)
	custom_piercings_dirty = FALSE
	custom_piercings_version += 1

/**
 * Loads custom piercing configuration from the per-slot sidecar JSON file
 * into `custom_piercings`. Called from the savefile read path (Phase 2).
 * Safe to call with a missing file — sets the var to null.
 */
/datum/preferences/proc/load_custom_piercings(slot)
	custom_piercings = null
	custom_piercings_dirty = FALSE
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return
	var/path = "[sa_dir]/custom_piercings_[slot].json"
	if(!fexists(path))
		return
	var/raw = rustg_file_read(path)
	if(!istext(raw) || !length(raw))
		return
	var/decoded = safe_json_decode(raw)
	custom_piercings = sanitize_custom_piercings(decoded)
	custom_piercings_version += 1

/**
 * Step 4 remediation (two-phase persist): builds the JSON payload that
 * `save_custom_piercings` would write, without touching disk. Returns a
 * list with keys:
 *   - `"path"`:   absolute sidecar path
 *   - `"bytes"`:  sanitised JSON string to write
 *   - `"delete"`: TRUE when the sidecar should be removed instead of written
 * Returns null when the sidecar directory is unavailable (e.g. a headless
 * unit test). Callers buffer the return value in
 * `/datum/appearance_preview_editor/pending_sidecars` and drain it after
 * `save_character()` succeeds, so a main-prefs save failure can never
 * leave the sidecar ahead of the authoritative prefs file.
 */
/datum/preferences/proc/compute_custom_piercings_payload(slot)
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return null
	var/path = "[sa_dir]/custom_piercings_[slot].json"
	ensure_sanitized_custom_piercings()
	if(!islist(custom_piercings) || !length(custom_piercings))
		return list("path" = path, "delete" = TRUE)
	if(!custom_piercings)
		return list("path" = path, "delete" = TRUE)
	return list("path" = path, "bytes" = json_encode(custom_piercings))

/**
 * Writes a precomputed payload from `compute_custom_piercings_payload`.
 * Normal editor commits should reach this through
 * /datum/appearance_preview_editor/proc/_flush_persist() after the main
 * savefile succeeds. The helper remains available for narrow test/debug
 * callers and uses the same temp-then-replace discipline so a failed write
 * does not leave a truncated sidecar at the final path.
 *
 * Returns TRUE on success; FALSE on any recoverable failure (malformed
 * payload, missing path, temp write failure, replacement failure).
 */
/datum/preferences/proc/write_custom_piercings_payload(list/payload)
	if(!islist(payload))
		return FALSE
	var/path = payload["path"]
	if(!istext(path) || !length(path))
		return FALSE
	if(payload["delete"])
		if(fexists(path))
			fdel(path)
		return TRUE
	var/bytes = payload["bytes"]
	if(!istext(bytes))
		return FALSE
	var/tmp_path = "[path].tmp"
	rustg_file_write(bytes, tmp_path)
	if(!fexists(tmp_path))
		return FALSE
	if(fexists(path))
		fdel(path)
	fcopy(tmp_path, path)
	fdel(tmp_path)
	return fexists(path)

/**
 * Writes `custom_piercings` to its per-slot sidecar JSON file, or deletes the
 * sidecar if the var is empty.
 *
 * Legacy/debug wrapper around the split compute/write helpers above. Do not
 * call this from /datum/preferences/proc/save_character(); production editor
 * commits must stage the payload and let the shared commit pipeline flush it
 * after the main character save succeeds.
 */
/datum/preferences/proc/save_custom_piercings(slot)
	var/list/payload = compute_custom_piercings_payload(slot)
	if(!islist(payload))
		return
	write_custom_piercings_payload(payload)

/**
 * Ensures the custom_piercings list exists. Load/import/commit/copy paths
 * normalize the shape; this hot helper is used by TGUI data builders and
 * mutators, so it avoids re-sanitizing already-normalized state every tick.
 * Returns a reference to the stored list for convenience.
 */
/datum/preferences/proc/ensure_custom_piercings()
	if(!islist(custom_piercings))
		custom_piercings = list()
	return custom_piercings

/**
 * Builds the opaque hybrid-overlay target key for a custom piercing entry.
 *
 * Target keys are intentionally slot/index based, not sticker-id based. The
 * descriptor builder resolves sticker ids from sanitized prefs state so TGUI
 * cannot forge arbitrary icon states by changing the target string.
 */
/proc/custom_piercing_hybrid_target_key(slot_key, entry_index)
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return null
	var/index = isnum(entry_index) ? entry_index : text2num_safe(entry_index, 0)
	if(index != round(index))
		return null
	index = round(index)
	if(index < 1 || index > CUSTOM_PIERCING_MAX_PER_SLOT)
		return null
	return "[slot_key]:[index]"

/**
 * Parses a custom piercing hybrid target key into a slot key and 1-based entry
 * index. Returns null for malformed input so descriptor callers fail closed.
 */
/proc/custom_piercing_parse_hybrid_target_key(target_key)
	if(!istext(target_key) || !length(target_key))
		return null
	var/list/parts = splittext(target_key, ":")
	if(length(parts) != 2)
		return null
	var/slot_key = parts[1]
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return null
	var/raw_index = text2num_safe(parts[2], 0)
	if(raw_index != round(raw_index))
		return null
	var/entry_index = round(raw_index)
	if(entry_index < 1 || entry_index > CUSTOM_PIERCING_MAX_PER_SLOT)
		return null
	return list(
		"slot_key" = slot_key,
		"entry_index" = entry_index,
	)

/**
 * Resolves one stored custom piercing entry into a hybrid overlay descriptor.
 *
 * Arguments:
 *   target_key - opaque `slot:index` key from custom_piercing_hybrid_target_key.
 *   dir_key    - canonical TGUI direction key or BYOND cardinal direction.
 *
 * The source of truth is sanitized prefs state plus the sticker registry. TGUI
 * never supplies icon paths or icon states; it only asks for a known target.
 */
/datum/preferences/proc/build_custom_piercing_hybrid_offset_descriptor(target_key, dir_key)
	var/list/target = custom_piercing_parse_hybrid_target_key(target_key)
	if(!islist(target))
		return null
	var/sanitized_dir = hybrid_offset_sanitize_direction_key(dir_key)
	if(!sanitized_dir)
		return null

	ensure_sanitized_custom_piercings()
	if(!islist(custom_piercings))
		return null
	var/slot_key = target["slot_key"]
	var/entry_index = target["entry_index"]
	var/list/slot_cfg = custom_piercings[slot_key]
	if(!islist(slot_cfg))
		return null
	var/list/entries = slot_cfg["entries"]
	if(!islist(entries) || entry_index > length(entries))
		return null
	var/list/entry = entries[entry_index]
	if(!islist(entry))
		return null

	var/list/layers = custom_piercing_build_entry_hybrid_guide_layers(entry)
	if(!length(layers))
		return null

	var/resolved_target = custom_piercing_hybrid_target_key(slot_key, entry_index)
	return hybrid_offset_build_descriptor(
		APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS,
		resolved_target,
		sanitized_dir,
		APPEARANCE_PREVIEW_CATEGORY_STICKER,
		layers,
		GLOB.custom_piercing_field_keys,
		HYBRID_OFFSET_DEFAULT_NATIVE_SIZE,
		HYBRID_OFFSET_DEFAULT_NATIVE_SIZE,
		TRUE,
	)

/**
 * Builds the descriptor grid for the currently saved custom piercing entries.
 *
 * Shape:
 *   list(
 *     "<slot_key>" = list(
 *       "<1-based entry index>" = list(
 *         "s" = descriptor,
 *         "n" = descriptor,
 *         ...
 *       )
 *     )
 *   )
 *
 * This is an editor-open payload only. It is not used during drag and performs
 * no runtime icon generation; every layer comes from the sticker whitelist.
 */
/datum/preferences/proc/build_custom_piercing_hybrid_offset_descriptor_grid()
	var/list/out = list()
	ensure_sanitized_custom_piercings()
	if(!islist(custom_piercings))
		return out

	for(var/slot_key in custom_piercings)
		if(!(slot_key in GLOB.custom_piercing_slot_keys))
			continue
		var/list/slot_cfg = custom_piercings[slot_key]
		if(!islist(slot_cfg))
			continue
		var/list/entries = slot_cfg["entries"]
		if(!islist(entries) || !length(entries))
			continue
		var/list/by_entry = list()
		for(var/i in 1 to entries.len)
			var/target_key = custom_piercing_hybrid_target_key(slot_key, i)
			if(!target_key)
				continue
			var/list/by_dir = list()
			for(var/dir_key in GLOB.custom_piercing_dir_keys)
				var/list/descriptor = build_custom_piercing_hybrid_offset_descriptor(target_key, dir_key)
				if(islist(descriptor))
					by_dir[dir_key] = descriptor
			if(length(by_dir))
				by_entry["[i]"] = by_dir
		if(length(by_entry))
			out[slot_key] = by_entry
	return out

/**
 * Returns the slot config for the given slot key, creating a default entry
 * if one does not yet exist. Returns null for unknown slot keys.
 */
/datum/preferences/proc/get_custom_piercing_slot(slot_key)
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return null
	ensure_custom_piercings()
	var/list/cfg = custom_piercings[slot_key]
	if(!islist(cfg))
		cfg = sanitize_custom_piercing_slot_config(slot_key, null)
		custom_piercings[slot_key] = cfg
		mark_custom_piercings_dirty()
	return cfg

/**
 * Returns the slot-level directional transform block for a slot, creating a
 * default block if one does not yet exist.
 */
/datum/preferences/proc/get_custom_piercing_slot_props(slot_key)
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return null
	var/list/cfg = get_custom_piercing_slot(slot_key)
	if(!cfg)
		return null
	var/list/props = cfg["slot_props"]
	if(!islist(props))
		props = default_custom_piercing_slot_props()
		cfg["slot_props"] = props
		cfg["props"] = props
	return props

/**
 * Stores the slot-level directional transform block for a slot.
 */
/datum/preferences/proc/set_custom_piercing_slot_props(slot_key, list/props)
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return FALSE
	var/list/cfg = get_custom_piercing_slot(slot_key)
	if(!cfg)
		return FALSE
	var/list/cleaned = sanitize_custom_piercing_slot_props(props)
	cfg["slot_props"] = cleaned
	cfg["props"] = cleaned
	mark_custom_piercings_dirty()
	return TRUE

/**
 * Returns the equipped accessory typepath for a slot, falling back to the
 * legacy per-slot preference vars if the slot has not yet been migrated.
 */
/datum/preferences/proc/get_custom_piercing_slot_equipped_typepath(slot_key)
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return null
	ensure_custom_piercings()
	var/list/cfg = custom_piercings[slot_key]
	var/equipped = islist(cfg) ? cfg["equipped_typepath"] : null
	if(!ispath(equipped, /obj/item/intimate_accessory) && !istext(equipped))
		equipped = islist(cfg) ? cfg["typepath"] : null
	if(ispath(equipped, /obj/item/intimate_accessory))
		return equipped
	if(istext(equipped) && length(equipped))
		var/path = text2path(equipped)
		if(ispath(path, /obj/item/intimate_accessory))
			cfg["equipped_typepath"] = "[path]"
			cfg["enabled"] = 1
			mark_custom_piercings_dirty()
			return path
	var/legacy_equipped = _custom_piercing_legacy_equipped_typepath(slot_key)
	if(legacy_equipped)
		if(!islist(cfg))
			cfg = get_custom_piercing_slot(slot_key)
		cfg["equipped_typepath"] = "[legacy_equipped]"
		cfg["enabled"] = 1
		mark_custom_piercings_dirty()
		return legacy_equipped
	return null

/**
 * Stores the equipped accessory typepath for a slot and mirrors the legacy
 * preference vars so older consumers continue to see the same choice.
 */
/datum/preferences/proc/set_custom_piercing_slot_equipped_typepath(slot_key, typepath)
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return FALSE
	ensure_custom_piercings()
	var/list/cfg = get_custom_piercing_slot(slot_key)
	if(!cfg)
		return FALSE
	var/normalized = null
	if(ispath(typepath, /obj/item/intimate_accessory))
		normalized = "[typepath]"
	else if(istext(typepath) && length(typepath))
		var/path = text2path(typepath)
		if(ispath(path, /obj/item/intimate_accessory))
			normalized = "[path]"
	cfg["equipped_typepath"] = normalized
	cfg["typepath"] = normalized
	cfg["enabled"] = normalized ? 1 : 0
	_custom_piercing_sync_legacy_equipped_typepath(slot_key, normalized ? text2path(normalized) : null)
	mark_custom_piercings_dirty()
	return TRUE

/datum/preferences/proc/_custom_piercing_legacy_equipped_typepath(slot_key)
	switch(slot_key)
		if("genital")
			return pref_intimate_genital_piercing
		if("insertable_genital")
			return pref_intimate_genital_insertable
		if("rear")
			return pref_intimate_rear_piercing
		if("insertable_rear")
			return pref_intimate_rear_insertable
		if("breast")
			return pref_intimate_breast_piercing
		if("tongue")
			return pref_intimate_mouth_piercing
		if("ear")
			return pref_intimate_ear_piercing
		if("nose")
			return pref_intimate_nose_piercing
		if("belly")
			return pref_intimate_belly_piercing
	return null

/datum/preferences/proc/_custom_piercing_sync_legacy_equipped_typepath(slot_key, typepath)
	switch(slot_key)
		if("genital")
			pref_intimate_genital_piercing = typepath
		if("insertable_genital")
			pref_intimate_genital_insertable = typepath
		if("rear")
			pref_intimate_rear_piercing = typepath
		if("insertable_rear")
			pref_intimate_rear_insertable = typepath
		if("breast")
			pref_intimate_breast_piercing = typepath
		if("tongue")
			pref_intimate_mouth_piercing = typepath
		if("ear")
			pref_intimate_ear_piercing = typepath
		if("nose")
			pref_intimate_nose_piercing = typepath
		if("belly")
			pref_intimate_belly_piercing = typepath

/**
 * preferences_custom_piercings.dm — Modular extension to /datum/preferences.
 *
 * Adds the `custom_piercings` character-scoped list and its sidecar JSON
 * load/save helpers. Data is stored in a per-slot sidecar file
 * (custom_piercings_[slot].json) to avoid the BYOND savefile ~64 KB per-entry
 * limit; a single character with many stickers can approach the cap easily.
 *
 * Phase 1: plumbing only. Nothing invokes load_custom_piercings() /
 * save_custom_piercings() automatically yet — the read/write hook sites in
 * preferences_savefile.dm are added in Phase 2 once the editor UI exists to
 * populate the data. This keeps existing save/load paths byte-identical on
 * disk until players opt in.
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
	 * ALWAYS read/write through sanitize_custom_piercings() — never assume
	 * the structure is valid even after load, because sidecar files can be
	 * tampered with out-of-band by admins / external tools.
	 */
	var/list/custom_piercings = null

/**
 * Loads custom piercing configuration from the per-slot sidecar JSON file
 * into `custom_piercings`. Called from the savefile read path (Phase 2).
 * Safe to call with a missing file — sets the var to null.
 */
/datum/preferences/proc/load_custom_piercings(slot)
	custom_piercings = null
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

/**
 * Writes `custom_piercings` to its per-slot sidecar JSON file, or deletes the
 * sidecar if the var is empty. Called from the savefile write path (Phase 2).
 */
/datum/preferences/proc/save_custom_piercings(slot)
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return
	var/path = "[sa_dir]/custom_piercings_[slot].json"
	if(islist(custom_piercings) && length(custom_piercings))
		// Re-sanitize on write as a defensive layer: validates anything the
		// editor might have written without passing through sanitize first.
		var/list/cleaned = sanitize_custom_piercings(custom_piercings)
		if(cleaned)
			rustg_file_write(json_encode(cleaned), path)
		else if(fexists(path))
			fdel(path)
	else if(fexists(path))
		fdel(path)

/**
 * Ensures the custom_piercings list exists and is sanitized. Callers that
 * mutate entries should run this first so downstream code can rely on the
 * shape. Returns a reference to the stored list for convenience.
 */
/datum/preferences/proc/ensure_custom_piercings()
	custom_piercings = sanitize_custom_piercings(custom_piercings) || list()
	return custom_piercings

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
			return path
	var/legacy_equipped = _custom_piercing_legacy_equipped_typepath(slot_key)
	if(legacy_equipped)
		if(!islist(cfg))
			cfg = get_custom_piercing_slot(slot_key)
		cfg["equipped_typepath"] = "[legacy_equipped]"
		cfg["enabled"] = 1
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

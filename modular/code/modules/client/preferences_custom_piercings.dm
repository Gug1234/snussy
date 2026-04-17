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
		cfg = sanitize_custom_piercing_slot_config(null)
		custom_piercings[slot_key] = cfg
	return cfg

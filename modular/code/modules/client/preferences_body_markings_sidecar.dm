/**
 * preferences_body_markings_sidecar.dm — Sidecar JSON persistence for
 * /datum/preferences.body_markings.
 *
 * The main savefile uses a legacy flat shape (zone → name → hex string) and
 * bumps up against the BYOND ~64 KB per-entry limit when the dict shape is
 * written directly. The TGUI editor needs the full dict shape (color, pixel
 * offsets, transform flags) so we persist that shape to a per-slot sidecar
 * JSON file — same pattern as preferences_custom_piercings.dm.
 *
 * The main-sav write still happens (legacy downgrade via
 * serialize_body_markings_for_savefile) so old clients/admin tools keep a
 * readable fallback. On load, if the sidecar exists and parses cleanly, it
 * wins over the main-sav blob.
 */

/datum/preferences
	/// Schema version for body_markings persistence. Bumped to 2 when
	/// the sidecar JSON path is engaged. Legacy characters load as 1 and
	/// fall back to the main-sav flat-hex shape.
	var/body_markings_v = 1

/**
 * Writes `C.prefs.body_markings` (full dict shape) to the per-slot sidecar
 * JSON file. No-op if the client / prefs are missing. If the list is empty,
 * the sidecar is deleted to avoid leaving stale blobs behind.
 */
/proc/save_body_markings_sidecar(client/C, slot)
	if(!C || !C.prefs)
		return FALSE
	var/datum/preferences/P = C.prefs
	var/sa_dir = P._sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return FALSE
	var/path = "[sa_dir]/body_markings_[slot].json"
	if(islist(P.body_markings) && length(P.body_markings))
		rustg_file_write(json_encode(P.body_markings), path)
	else if(fexists(path))
		fdel(path)
	return TRUE

/**
 * Reads the per-slot sidecar JSON into `C.prefs.body_markings`. Returns
 * TRUE if the sidecar existed and produced a usable list (caller should
 * skip the legacy main-sav load). Returns FALSE if missing/unreadable.
 *
 * The returned list is run through `normalize_body_markings()` so downstream
 * readers see the full dict shape with clamped offsets, even for sidecars
 * hand-edited out of band.
 */
/proc/load_body_markings_sidecar(client/C, slot)
	if(!C || !C.prefs)
		return FALSE
	var/datum/preferences/P = C.prefs
	var/sa_dir = P._sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return FALSE
	var/path = "[sa_dir]/body_markings_[slot].json"
	if(!fexists(path))
		return FALSE
	var/raw = rustg_file_read(path)
	if(!istext(raw) || !length(raw))
		return FALSE
	var/decoded = safe_json_decode(raw)
	if(!islist(decoded))
		return FALSE
	P.body_markings = decoded
	P.validate_body_markings()
	P.normalize_body_markings()
	return TRUE

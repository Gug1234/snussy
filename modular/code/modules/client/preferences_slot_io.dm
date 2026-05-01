/**
 * preferences_slot_io.dm — Character slot import/export.
 *
 * Produces a versioned JSON envelope that round-trips an entire character
 * slot (all fields save_character() writes to the savefile + every sidecar
 * JSON blob). Import writes the payload into the player's real savefile at
 * the chosen slot, then runs the normal load_character() pipeline so
 * savefile version migrations AND the full sanitize chain (species
 * validation, reject_bad_name, sanitize_inlist, etc.) apply automatically.
 *
 * Forward-compat strategy: we never enumerate the 150+ character fields
 * ourselves — ExportText / ImportText handle arbitrary savefile subtrees,
 * so new fields added to save_character() flow through exports on the
 * same day with zero maintenance.
 *
 * Schema envelope (schema = 1):
 *   {
 *     "schema":           1,
 *     "savefile_version": <int, = SAVEFILE_VERSION_MAX at export time>,
 *     "exported_at":      "YYYY-MM-DD hh:mm:ss",
 *     "source_ckey":      "<exporter ckey, optional>",
 *     "character_text":   "<ExportText output for /character[slot]>",
 *     "sidecars": {
 *       "<sidecar_key>": <decoded JSON value or null>,
 *       ...
 *     }
 *   }
 *
 * Sidecars are discovered dynamically from files named
 * <sidecar_key>_<slot>.json in the player's sidecar directory.
 */

/// Hard cap on accepted import payload size. Full slot with many stickers
/// + flavors can reach a few hundred KB; 2 MB is generous headroom.
#define SLOT_IO_MAX_PAYLOAD_BYTES (2 * 1024 * 1024)

/// Current envelope schema. Bump only if the envelope layout changes
/// (NOT when new fields are added inside `character_text` — those are
/// covered by the savefile_version migration system instead).
#define SLOT_IO_SCHEMA_VERSION 1

/**
 * Serializes the character at `slot` (defaults to current default_slot)
 * to a JSON envelope. Returns the JSON text, or null on failure.
 */
/datum/preferences/proc/export_character_slot_json(slot)
	if(!path)
		return null
	if(!fexists(path))
		return null
	if(!slot)
		slot = default_slot
	slot = sanitize_integer(slot, 1, max_save_slots, initial(default_slot))

	var/savefile/S = new /savefile(path)
	if(!S)
		return null

	// Confirm the slot actually contains data — otherwise we'd ship an
	// empty blob that overwrites the target slot with nothing on import.
	S.cd = "/character[slot]"
	if(!length(S.dir))
		return null

	var/character_text = S.ExportText("/character[slot]")
	if(!istext(character_text) || !length(character_text))
		return null

	var/list/sidecars = _export_slot_sidecars(slot)

	var/list/envelope = list(
		"schema"           = SLOT_IO_SCHEMA_VERSION,
		"savefile_version" = SAVEFILE_VERSION_MAX,
		"exported_at"      = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"source_ckey"      = (parent?.ckey ? parent.ckey : null),
		"character_text"   = character_text,
		"sidecars"         = sidecars,
	)
	return json_encode(envelope)

/**
 * Reads each sidecar JSON file for `slot` and returns a map of decoded
 * contents (list or null per slot). Never returns null — empty sidecars
 * are represented with null values so the structure round-trips exactly.
 */
/datum/preferences/proc/_export_slot_sidecars(slot)
	var/list/out = list()
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return out

	var/list/filemap = _slot_sidecar_filemap(slot)
	for(var/key in filemap)
		var/sp = filemap[key]
		if(!fexists(sp))
			continue
		var/raw = rustg_file_read(sp)
		if(!istext(raw) || !length(raw))
			continue
		out[key] = safe_json_decode(raw)
	return out

/**
 * Returns key->path for every sidecar file matching
 * <sidecar_key>_<slot>.json in this player's sidecar directory.
 */
/datum/preferences/proc/_slot_sidecar_filemap(slot)
	var/list/out = list()
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return out

	var/list/entries = flist(sa_dir)
	if(!islist(entries) || !length(entries))
		return out

	var/suffix = "_[slot].json"
	var/suffix_len = length(suffix)
	for(var/entry in entries)
		if(!istext(entry))
			continue
		// flist can include folders; skip directory entries.
		if(copytext(entry, length(entry), length(entry) + 1) == "/")
			continue
		if(length(entry) <= suffix_len)
			continue
		var/start = length(entry) - suffix_len + 1
		if(copytext(entry, start, start + suffix_len) != suffix)
			continue
		var/key = copytext(entry, 1, start)
		if(!_is_valid_sidecar_key(key))
			continue
		out[key] = "[sa_dir]/[entry]"
	return out

/// Restrictive validation to prevent path traversal in sidecar file keys.
/datum/preferences/proc/_is_valid_sidecar_key(key)
	if(!istext(key) || !length(key))
		return FALSE
	if(findtext(key, "/") || findtext(key, "\\") || findtext(key, "..") || findtext(key, ":"))
		return FALSE
	return TRUE

/**
 * Imports a JSON envelope into `target_slot` (defaults to current
 * default_slot). Returns an associative list:
 *   list("ok" = TRUE|FALSE, "message" = "<human-readable status>")
 *
 * On success the target slot has been overwritten, load_character() has
 * been called (migrations + sanitize applied), and save_character() has
 * re-persisted the slot at SAVEFILE_VERSION_MAX.
 *
 * On failure the original slot contents are restored via an in-memory
 * ExportText backup taken before any writes.
 */
/datum/preferences/proc/import_character_slot_json(payload, target_slot)
	if(!path)
		return list("ok" = FALSE, "message" = "No savefile path set.")
	if(!istext(payload) || !length(payload))
		return list("ok" = FALSE, "message" = "Empty payload.")
	if(length(payload) > SLOT_IO_MAX_PAYLOAD_BYTES)
		return list("ok" = FALSE, "message" = "Payload exceeds [SLOT_IO_MAX_PAYLOAD_BYTES] bytes.")

	var/decoded = safe_json_decode(payload)
	if(!islist(decoded))
		return list("ok" = FALSE, "message" = "Payload is not valid JSON.")

	var/list/envelope = decoded
	var/schema = envelope["schema"]
	if(!isnum(schema) || schema < 1 || schema > SLOT_IO_SCHEMA_VERSION)
		return list("ok" = FALSE, "message" = "Unsupported schema version: [schema]. This build supports up to [SLOT_IO_SCHEMA_VERSION].")

	var/savefile_version = envelope["savefile_version"]
	if(!isnum(savefile_version))
		return list("ok" = FALSE, "message" = "Missing savefile_version in payload.")
	if(savefile_version > SAVEFILE_VERSION_MAX)
		return list("ok" = FALSE, "message" = "Export is from a newer build (savefile v[savefile_version] > v[SAVEFILE_VERSION_MAX]). Upgrade the server before importing.")
	if(savefile_version < SAVEFILE_VERSION_MIN)
		return list("ok" = FALSE, "message" = "Export is too old (savefile v[savefile_version] < v[SAVEFILE_VERSION_MIN]). No migration path.")

	var/character_text = envelope["character_text"]
	if(!istext(character_text) || !length(character_text))
		return list("ok" = FALSE, "message" = "Payload missing character_text.")

	if(!target_slot)
		target_slot = default_slot
	target_slot = sanitize_integer(target_slot, 1, max_save_slots, initial(default_slot))

	// Open (or create) the real savefile.
	var/savefile/S = new /savefile(path)
	if(!S)
		return list("ok" = FALSE, "message" = "Failed to open savefile.")

	// Back up the existing slot in memory so we can roll back on failure.
	var/backup_text = null
	S.cd = "/character[target_slot]"
	if(length(S.dir))
		backup_text = S.ExportText("/character[target_slot]")

	// Back up existing sidecars, then delete them so the imported slot
	// doesn't inherit a mix of old + new data if the import only supplies
	// some sidecars (or none).
	var/list/sidecar_backup = _export_slot_sidecars(target_slot)
	_delete_slot_sidecars(target_slot)

	// Clear the target subtree before ImportText so we don't keep stale
	// fields that the new slot doesn't set. Snapshot dir first to avoid
	// iteration-during-mutation hazards.
	S.cd = "/character[target_slot]"
	var/list/stale_keys = S.dir.Copy()
	for(var/entry in stale_keys)
		S.dir -= entry

	// Apply the new character data.
	S.ImportText("/character[target_slot]", character_text)

	// Write incoming sidecars to the slot's sidecar files.
	var/list/sidecars = envelope["sidecars"]
	if(islist(sidecars))
		_write_slot_sidecars(target_slot, sidecars)

	// Force the savefile version tag to the imported value so
	// update_character() runs the correct migration chain on load.
	S.cd = "/character[target_slot]"
	WRITE_FILE(S["version"], savefile_version)

	// Persist the savefile object before we read it back, otherwise the
	// pending writes sit in memory and the new /savefile in load_character
	// will see the old contents.
	S = null

	// Run the normal load pipeline — this executes update_character()
	// migrations for old exports and the full sanitize chain.
	var/prior_default = default_slot
	default_slot = target_slot
	if(!load_character(target_slot))
		// Roll back: re-open savefile, restore backup, restore sidecars.
		default_slot = prior_default
		_restore_slot_from_backup(target_slot, backup_text, sidecar_backup)
		return list("ok" = FALSE, "message" = "load_character() failed after import — original slot restored.")

	// Re-save so the on-disk version tag is bumped to SAVEFILE_VERSION_MAX
	// and any field adjustments made by sanitize are persisted.
	if(!save_character())
		return list("ok" = FALSE, "message" = "Import loaded into memory but save_character() failed — slot state may be inconsistent.")

	// Commit contract (Step 12): persist-then-refresh semantics apply to
	// slot import too. The just-imported slot becomes the current default
	// slot, so the lobby mannequin must reflect the freshly loaded fields.
	appearance_preview_refresh_character_preview(src)

	return list("ok" = TRUE, "message" = "Imported into slot [target_slot].")

/**
 * Writes sidecar contents from an import envelope to the sidecar files
 * for `target_slot`. Each value must be a list or null (null deletes).
 */
/datum/preferences/proc/_write_slot_sidecars(target_slot, list/sidecars)
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return
	for(var/key in sidecars)
		if(!_is_valid_sidecar_key(key))
			continue
		var/sp = "[sa_dir]/[key]_[target_slot].json"
		var/value = sidecars[key]
		if(isnull(value))
			if(fexists(sp))
				fdel(sp)
		else
			rustg_file_write(json_encode(value), sp)

/**
 * Deletes all sidecar files for `slot`. Used to clear the slot before
 * writing new sidecars so partial imports don't inherit stale data.
 */
/datum/preferences/proc/_delete_slot_sidecars(slot)
	var/list/filemap = _slot_sidecar_filemap(slot)
	for(var/key in filemap)
		var/sp = filemap[key]
		if(fexists(sp))
			fdel(sp)

/**
 * Restores a slot to its pre-import state from the in-memory backup.
 * Best-effort: if backup_text is null (slot was empty before import),
 * simply clears the slot.
 */
/datum/preferences/proc/_restore_slot_from_backup(slot, backup_text, list/sidecar_backup)
	var/savefile/S = new /savefile(path)
	if(S)
		S.cd = "/character[slot]"
		var/list/stale_keys = S.dir.Copy()
		for(var/entry in stale_keys)
			S.dir -= entry
		if(istext(backup_text) && length(backup_text))
			S.ImportText("/character[slot]", backup_text)
		S = null
	_delete_slot_sidecars(slot)
	if(islist(sidecar_backup))
		_write_slot_sidecars(slot, sidecar_backup)
	// Re-sync the in-memory prefs datum with the restored on-disk slot.
	load_character(slot)

#undef SLOT_IO_MAX_PAYLOAD_BYTES
#undef SLOT_IO_SCHEMA_VERSION

/**
 * Debug verbs — hidden. Useful for development and admin testing before
 * the TGUI surface lands. Export dumps to chat; import prompts for a
 * JSON blob via tgui_input_text.
 */
/client/verb/export_character_slot()
	set name = "Export Character Slot"
	set category = "Preferences"
	set desc = "Dumps the current character slot as a JSON envelope for sharing or backup."

	if(!prefs)
		to_chat(src, span_warning("No preferences datum."))
		return
	var/payload = prefs.export_character_slot_json()
	if(!istext(payload))
		to_chat(src, span_warning("Export failed — no data in slot [prefs.default_slot]?"))
		return
	// Display in a browse window so it can be copied out cleanly.
	var/escaped = replacetext(payload, "&", "&amp;")
	escaped = replacetext(escaped, "<", "&lt;")
	escaped = replacetext(escaped, ">", "&gt;")
	var/html = {"<!doctype html><html><body style='font-family:monospace;font-size:11px;'>
<p>Copy the JSON below to share or back up character slot [prefs.default_slot]. Recommended to save your precious OC's data as a .json or .txt file as a backup! (I would use Notepad++=)</p>
<p>(Length: [length(payload)] bytes)</p>
<textarea style='width:100%;height:90%;' readonly>[escaped]</textarea>
</body></html>"}
	src << browse(html, "window=slot_export;size=700x500")

/client/verb/import_character_slot()
	set name = "Import Character Slot"
	set category = "Preferences"
	set desc = "Overwrites the current character slot with a pasted JSON export."

	if(!prefs)
		to_chat(src, span_warning("No preferences datum."))
		return
	var/payload = tgui_input_text(src, "Paste character slot JSON. Overwrites slot [prefs.default_slot].", "Import Character Slot", multiline = TRUE, encode = FALSE, bigmodal = TRUE)
	if(!istext(payload) || !length(payload))
		return
	if(alert(src, "This will OVERWRITE slot [prefs.default_slot]. Continue?", "Confirm Import", "Import", "Cancel") != "Import")
		return
	var/list/result = prefs.import_character_slot_json(payload)
	if(result["ok"])
		to_chat(src, span_notice("[result["message"]]"))
		prefs.ShowChoices(mob)
	else
		to_chat(src, span_warning("Import failed: [result["message"]]"))

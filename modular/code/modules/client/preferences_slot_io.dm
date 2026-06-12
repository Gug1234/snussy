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

/// The pasted chunk-envelope text is base64 + JSON wrapped, so it can be
/// larger than the decoded slot payload.
#define SLOT_IO_MAX_IMPORT_TEXT_BYTES (SLOT_IO_MAX_PAYLOAD_BYTES * 2)

/// Defensive cap for the self-contained TGUI import transfer.
#define SLOT_IO_MAX_IMPORT_TRANSFER_CHUNKS 4096

/// Current envelope schema. Bump only if the envelope layout changes
/// (NOT when new fields are added inside `character_text` — those are
/// covered by the savefile_version migration system instead).
#define SLOT_IO_SCHEMA_VERSION 1

/// Returns the directory that stores sidecar JSON files next to this savefile.
/datum/preferences/proc/_sidecar_dir()
	if(!istext(path) || !length(path))
		return null
	var/last_slash = findlasttext(path, "/")
	if(!last_slash)
		last_slash = findlasttext(path, "\\")
	if(last_slash)
		return copytext(path, 1, last_slash + 1)
	return null

/**
 * Reads and decodes one ERP sidecar for a character slot.
 *
 * Inputs:
 * - `slot`: the numeric character slot.
 * - `sidecar_key`: a restrictive file key validated by _is_valid_sidecar_key().
 *
 * Returns a decoded associative/list value, or null when no valid sidecar is
 * present. Invalid JSON is treated as absent so load_character() can continue.
 */
/datum/preferences/proc/_read_json_sidecar(slot, sidecar_key)
	if(!_is_valid_sidecar_key(sidecar_key))
		return null
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return null
	var/sidecar_path = "[sa_dir][sidecar_key]_[slot].json"
	if(!fexists(sidecar_path))
		return null
	var/raw = rustg_file_read(sidecar_path)
	if(!istext(raw) || !length(raw))
		return null
	var/decoded = safe_json_decode(raw)
	return islist(decoded) ? decoded : null

/**
 * Atomically commits one ERP sidecar after the main savefile write succeeds.
 *
 * The write goes to a temporary path first, then replaces the final sidecar.
 * That keeps sidecar data from moving ahead of the main character slot save.
 */
/datum/preferences/proc/_commit_json_sidecar(slot, sidecar_key, value)
	if(!_is_valid_sidecar_key(sidecar_key))
		return FALSE
	var/sa_dir = _sidecar_dir()
	if(!istext(sa_dir) || !length(sa_dir))
		return FALSE
	var/final_path = "[sa_dir][sidecar_key]_[slot].json"
	if(!islist(value) || !length(value))
		if(fexists(final_path))
			fdel(final_path)
		return TRUE
	var/temp_path = "[sa_dir].[sidecar_key]_[slot].tmp"
	rustg_file_write(json_encode(value), temp_path)
	if(!fexists(temp_path))
		return FALSE
	if(fexists(final_path))
		fdel(final_path)
	if(!fcopy(temp_path, final_path))
		fdel(temp_path)
		return FALSE
	fdel(temp_path)
	return TRUE

/// Loads the ERP sidecars owned by the first-PR systems for `slot`.
/datum/preferences/proc/_load_erp_sidecars(slot)
	custom_sex_flavors = _read_json_sidecar(slot, "sex_flavors")
	validate_custom_sex_flavors()
	custom_sex_actions = _read_json_sidecar(slot, "sex_actions")
	validate_custom_sex_actions()
	custom_intimate_reactions = _read_json_sidecar(slot, "intimate_reactions")
	validate_custom_intimate_reactions()
	erp_preview_tokens = _read_json_sidecar(slot, "erp_preview_tokens")
	validate_erp_preview_tokens()
	custom_anatomy_tokens = _read_json_sidecar(slot, "anatomy_tokens")
	validate_custom_anatomy_tokens()

/// Saves ERP sidecars after save_character() has written the main slot data.
/datum/preferences/proc/_save_erp_sidecars(slot)
	if(!_commit_json_sidecar(slot, "sex_flavors", custom_sex_flavors))
		return FALSE
	if(!_commit_json_sidecar(slot, "sex_actions", custom_sex_actions))
		return FALSE
	if(!_commit_json_sidecar(slot, "intimate_reactions", custom_intimate_reactions))
		return FALSE
	if(!_commit_json_sidecar(slot, "erp_preview_tokens", erp_preview_tokens))
		return FALSE
	if(!_commit_json_sidecar(slot, "anatomy_tokens", custom_anatomy_tokens))
		return FALSE
	return TRUE

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
		out[key] = "[sa_dir][entry]"
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
		var/value = sidecars[key]
		if(isnull(value))
			_commit_json_sidecar(target_slot, key, null)
		else if(islist(value))
			_commit_json_sidecar(target_slot, key, value)

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

/datum/preferences/proc/open_character_slot_io_menu(mob/user)
	var/client/C = user?.client
	if(!C || C.prefs != src)
		return FALSE
	var/datum/character_slot_io_menu/menu = new(src)
	menu.ui_interact(user)
	return TRUE

/datum/character_slot_io_menu
	var/datum/preferences/prefs
	var/export_text = ""
	var/export_chunk_count = 0
	var/export_payload_bytes = 0
	var/status_text = ""
	var/status_kind = "info"
	var/list/pending_import_chunks
	var/pending_import_chunk_count = 0
	var/pending_import_text_length = 0

/datum/character_slot_io_menu/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P

/datum/character_slot_io_menu/Destroy(force)
	clear_pending_import()
	prefs = null
	return ..()

/datum/character_slot_io_menu/proc/set_status(message, kind = "info")
	status_text = message || ""
	status_kind = kind || "info"

/datum/character_slot_io_menu/proc/clear_export()
	export_text = ""
	export_chunk_count = 0
	export_payload_bytes = 0

/datum/character_slot_io_menu/proc/clear_pending_import()
	pending_import_chunks = null
	pending_import_chunk_count = 0
	pending_import_text_length = 0

/datum/character_slot_io_menu/proc/apply_import_payload_text(raw, mob/user)
	var/list/chunk_result = parse_chunked_export_chunks(raw, ERP_EXPORT_KIND_CHARACTER_SLOT, SLOT_IO_MAX_PAYLOAD_BYTES)
	if(!chunk_result["ok"])
		set_status(chunk_result["message"], "danger")
		return FALSE

	var/list/result = prefs.import_character_slot_json(chunk_result["payload"])
	if(result["ok"])
		clear_export()
		set_status(result["message"], "success")
		if(user)
			prefs.ShowChoices(user)
		return TRUE

	set_status("Import failed: [result["message"]]", "danger")
	return FALSE

/datum/character_slot_io_menu/proc/begin_import_payload(raw_chunk_count, raw_text_length)
	var/chunk_count = sanitize_integer(raw_chunk_count, 1, SLOT_IO_MAX_IMPORT_TRANSFER_CHUNKS, 0)
	if(!chunk_count)
		clear_pending_import()
		set_status("Import failed: invalid transfer chunk count.", "danger")
		return FALSE

	var/text_length = sanitize_integer(raw_text_length, 1, SLOT_IO_MAX_IMPORT_TEXT_BYTES, 0)
	if(!text_length)
		clear_pending_import()
		set_status("Import failed: transfer text is too large.", "danger")
		return FALSE

	pending_import_chunks = list()
	pending_import_chunk_count = chunk_count
	pending_import_text_length = 0
	set_status("Receiving import data: 0/[chunk_count] chunks.", "info")
	return TRUE

/datum/character_slot_io_menu/proc/append_import_payload_chunk(raw_index, raw_chunk_count, chunk, mob/user)
	if(!pending_import_chunks || !pending_import_chunk_count)
		set_status("Import failed: transfer was not initialized. Try importing again.", "danger")
		return FALSE

	var/chunk_count = sanitize_integer(raw_chunk_count, 1, SLOT_IO_MAX_IMPORT_TRANSFER_CHUNKS, 0)
	if(chunk_count != pending_import_chunk_count)
		clear_pending_import()
		set_status("Import failed: transfer chunk count changed.", "danger")
		return FALSE

	var/chunk_index = sanitize_integer(raw_index, 1, pending_import_chunk_count, 0)
	if(!chunk_index || !istext(chunk))
		clear_pending_import()
		set_status("Import failed: invalid transfer chunk.", "danger")
		return FALSE

	var/chunk_key = "[chunk_index]"
	if(!isnull(pending_import_chunks[chunk_key]))
		clear_pending_import()
		set_status("Import failed: duplicate transfer chunk [chunk_index].", "danger")
		return FALSE

	pending_import_text_length += length(chunk)
	if(pending_import_text_length > SLOT_IO_MAX_IMPORT_TEXT_BYTES)
		clear_pending_import()
		set_status("Import failed: transfer text is too large.", "danger")
		return FALSE

	pending_import_chunks[chunk_key] = chunk
	var/received_count = length(pending_import_chunks)
	if(received_count < pending_import_chunk_count)
		set_status("Receiving import data: [received_count]/[pending_import_chunk_count] chunks.", "info")
		return TRUE

	var/raw = ""
	for(var/index in 1 to pending_import_chunk_count)
		var/piece = pending_import_chunks["[index]"]
		if(!istext(piece))
			clear_pending_import()
			set_status("Import failed: missing transfer chunk [index].", "danger")
			return FALSE
		raw += piece

	clear_pending_import()
	return apply_import_payload_text(raw, user)

/datum/character_slot_io_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CharacterSlotIOMenu", "Character Slot Transfer", 720, 620)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/character_slot_io_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/character_slot_io_menu/ui_data(mob/user)
	var/list/data = list()
	data["slot"] = prefs?.default_slot || 0
	data["max_slots"] = prefs?.max_save_slots || 0
	data["export_text"] = export_text
	data["export_chunk_count"] = export_chunk_count
	data["export_payload_bytes"] = export_payload_bytes
	data["export_text_length"] = length(export_text)
	data["status_text"] = status_text
	data["status_kind"] = status_kind
	data["max_import_bytes"] = SLOT_IO_MAX_PAYLOAD_BYTES
	data["max_import_text_bytes"] = SLOT_IO_MAX_IMPORT_TEXT_BYTES
	return data

/datum/character_slot_io_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(!prefs)
		return FALSE

	switch(action)
		if("generate_export")
			var/payload = prefs.export_character_slot_json()
			if(!istext(payload))
				clear_export()
				set_status("Export failed: no data was found in slot [prefs.default_slot].", "danger")
				return TRUE
			var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_CHARACTER_SLOT, payload)
			if(!length(chunks))
				clear_export()
				set_status("Export failed: no payload could be generated.", "danger")
				return TRUE
			export_text = chunks.Join("\n")
			export_chunk_count = length(chunks)
			export_payload_bytes = length(payload)
			set_status("Export ready for slot [prefs.default_slot]: [export_chunk_count] chunk[export_chunk_count == 1 ? "" : "s"], [export_payload_bytes] bytes.", "success")
			return TRUE

		if("clear_export")
			clear_export()
			set_status("Export text cleared.", "info")
			return TRUE

		if("import_payload")
			var/raw = params["payload"]
			if(!istext(raw) || !length(trim(raw)))
				set_status("Import failed: no data was provided.", "danger")
				return TRUE
			apply_import_payload_text(trim(raw), ui?.user || usr)
			return TRUE

		if("begin_import_payload")
			begin_import_payload(params["chunk_count"], params["text_length"])
			return TRUE

		if("append_import_payload_chunk")
			append_import_payload_chunk(params["chunk_index"], params["chunk_count"], params["chunk"], ui?.user || usr)
			return TRUE

	return FALSE

/datum/character_slot_io_menu/ui_close(mob/user)
	var/client/C = user?.client
	if(C)
		addtimer(CALLBACK(C, TYPE_PROC_REF(/client, prefs_resume_after_singleton)), 1)
	return ..()

#undef SLOT_IO_MAX_PAYLOAD_BYTES
#undef SLOT_IO_MAX_IMPORT_TEXT_BYTES
#undef SLOT_IO_MAX_IMPORT_TRANSFER_CHUNKS
#undef SLOT_IO_SCHEMA_VERSION

/// Hidden utility verbs. Both open the same self-contained slot transfer panel.
/client/verb/export_character_slot()
	set name = "Export Character Slot"
	set category = "Preferences"
	set desc = "Opens the character slot export/import panel."

	prefs?.open_character_slot_io_menu(mob)

/client/verb/import_character_slot()
	set name = "Import Character Slot"
	set category = "Preferences"
	set desc = "Opens the character slot export/import panel."

	prefs?.open_character_slot_io_menu(mob)

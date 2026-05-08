/// Shared chunked import/export helpers for large preference payloads.
///
/// BYOND input controls and chat surfaces can truncate very large JSON strings.
/// The ERP editors and character-slot import/export paths use this contract to
/// split a portable payload into bounded chunks, then verify and reassemble the
/// chunks before any savefile state is changed.

/// Returns a normalized parse result for chunked import/export helpers.
/proc/_chunked_export_result(success, message, payload)
	. = list("ok" = !!success, "message" = message || "")
	if(success)
		.["payload"] = payload || ""

/// Builds newline-safe base64 JSON chunk envelopes for a large text payload.
/proc/build_chunked_export_chunks(export_kind, payload, chunk_size = ERP_EXPORT_DEFAULT_CHUNK_SIZE)
	if(!istext(export_kind) || !length(export_kind) || !istext(payload))
		return list()
	if(!isnum(chunk_size) || chunk_size < 1)
		chunk_size = ERP_EXPORT_DEFAULT_CHUNK_SIZE

	var/list/pieces = list()
	var/payload_length = length(payload)
	if(!payload_length)
		pieces += ""
	else
		for(var/start = 1, start <= payload_length, start += chunk_size)
			pieces += copytext(payload, start, min(start + chunk_size, payload_length + 1))

	var/checksum = md5(payload)
	var/chunk_count = length(pieces)
	var/list/chunks = list()
	for(var/index in 1 to chunk_count)
		var/list/envelope = list(
			"kind" = export_kind,
			"version" = ERP_EXPORT_CONTRACT_VERSION,
			"chunk_index" = index,
			"chunk_count" = chunk_count,
			"checksum" = checksum,
			"payload" = pieces[index]
		)
		chunks += rustg_encode_base64(json_encode(envelope))
	return chunks

/// Extracts decodable chunk envelopes from player-pasted text.
/proc/_decode_chunked_export_tokens(raw_text)
	var/normalized = replacetext(raw_text, ascii2text(13), " ")
	normalized = replacetext(normalized, ascii2text(10), " ")
	normalized = replacetext(normalized, ascii2text(9), " ")

	var/list/envelopes = list()
	for(var/token in splittext(normalized, " "))
		token = trim(token)
		if(!length(token))
			continue
		var/decoded = rustg_decode_base64(token)
		if(!istext(decoded) || !length(decoded))
			continue
		var/list/envelope
		try
			envelope = json_decode(decoded)
		catch
			continue
		if(islist(envelope) && envelope["version"] == ERP_EXPORT_CONTRACT_VERSION)
			envelopes += list(envelope)
	return envelopes

/// Reassembles and verifies a chunked export pasted by a player.
/proc/parse_chunked_export_chunks(raw_text, expected_kind, max_payload_length = ERP_EXPORT_MAX_PAYLOAD_LENGTH)
	if(!istext(raw_text) || !length(trim(raw_text)))
		return _chunked_export_result(FALSE, "Import failed: no data was provided.")
	if(!istext(expected_kind) || !length(expected_kind))
		return _chunked_export_result(FALSE, "Import failed: no expected data kind was configured.")
	if(!isnum(max_payload_length) || max_payload_length < 1)
		max_payload_length = ERP_EXPORT_MAX_PAYLOAD_LENGTH

	var/list/envelopes = _decode_chunked_export_tokens(raw_text)
	if(!length(envelopes))
		return _chunked_export_result(FALSE, "Import failed: no valid export chunks were found.")

	var/chunk_count
	var/checksum
	var/list/pieces = list()
	for(var/list/envelope as anything in envelopes)
		if(envelope["kind"] != expected_kind)
			return _chunked_export_result(FALSE, "Import failed: this export is for [envelope["kind"] || "unknown data"], not [expected_kind].")
		var/index = envelope["chunk_index"]
		var/count = envelope["chunk_count"]
		if(!isnum(index) || !isnum(count) || index < 1 || count < 1 || index > count)
			return _chunked_export_result(FALSE, "Import failed: one chunk has invalid numbering.")
		if(isnull(chunk_count))
			chunk_count = count
		else if(chunk_count != count)
			return _chunked_export_result(FALSE, "Import failed: chunk count mismatch.")
		var/chunk_checksum = envelope["checksum"]
		if(!istext(chunk_checksum) || !length(chunk_checksum))
			return _chunked_export_result(FALSE, "Import failed: one chunk is missing a checksum.")
		if(isnull(checksum))
			checksum = chunk_checksum
		else if(checksum != chunk_checksum)
			return _chunked_export_result(FALSE, "Import failed: checksum mismatch between chunks.")
		if(!istext(envelope["payload"]))
			return _chunked_export_result(FALSE, "Import failed: one chunk has no payload.")
		if(!isnull(pieces["[index]"]))
			return _chunked_export_result(FALSE, "Import failed: duplicate chunk [index].")
		pieces["[index]"] = envelope["payload"]

	if(length(pieces) != chunk_count)
		return _chunked_export_result(FALSE, "Import failed: expected [chunk_count] chunks but received [length(pieces)].")

	var/reassembled = ""
	for(var/index in 1 to chunk_count)
		var/piece = pieces["[index]"]
		if(isnull(piece))
			return _chunked_export_result(FALSE, "Import failed: missing chunk [index].")
		reassembled += piece

	if(length(reassembled) > max_payload_length)
		return _chunked_export_result(FALSE, "Import failed: payload is too large.")
	if(md5(reassembled) != checksum)
		return _chunked_export_result(FALSE, "Import failed: checksum validation failed.")
	return _chunked_export_result(TRUE, "Import payload verified.", reassembled)

/// Sends a chunked export to a user's chat as copyable lines.
/proc/send_chunked_export_to_chat(mob/user, title, export_kind, payload)
	if(!user || !istext(payload))
		return FALSE
	var/list/chunks = build_chunked_export_chunks(export_kind, payload)
	if(!length(chunks))
		to_chat(user, span_warning("Export failed: no payload could be generated."))
		return FALSE
	to_chat(user, span_notice("<b>[title]</b> export generated [length(chunks)] chunk[length(chunks) == 1 ? "" : "s"]. Copy every chunk line into the matching import box."))
	for(var/chunk in chunks)
		to_chat(user, "<span class='notice' style='word-break:break-all;'>[chunk]</span>")
	return TRUE

/// Session-local state for self-contained TGUI export/import panels.
/datum/erp_chunked_export_panel_state
	var/export_text = ""
	var/export_chunk_count = 0
	var/export_payload_bytes = 0
	var/status_text = ""
	var/status_kind = "info"
	var/list/pending_import_chunks
	var/pending_import_chunk_count = 0
	var/pending_import_text_length = 0

/datum/erp_chunked_export_panel_state/Destroy(force)
	clear_pending_import()
	return ..()

/datum/erp_chunked_export_panel_state/proc/set_status(message, kind = "info")
	status_text = message || ""
	status_kind = kind || "info"

/datum/erp_chunked_export_panel_state/proc/clear_export()
	export_text = ""
	export_chunk_count = 0
	export_payload_bytes = 0

/datum/erp_chunked_export_panel_state/proc/clear_pending_import()
	pending_import_chunks = null
	pending_import_chunk_count = 0
	pending_import_text_length = 0

/datum/erp_chunked_export_panel_state/proc/set_export_from_payload(export_kind, payload, label)
	if(!istext(payload) || !length(payload))
		clear_export()
		set_status("Export failed: no payload could be generated.", "danger")
		return FALSE
	var/list/chunks = build_chunked_export_chunks(export_kind, payload)
	if(!length(chunks))
		clear_export()
		set_status("Export failed: no payload could be generated.", "danger")
		return FALSE
	export_text = chunks.Join("\n")
	export_chunk_count = length(chunks)
	export_payload_bytes = length(payload)
	set_status("[label] export ready: [export_chunk_count] chunk[export_chunk_count == 1 ? "" : "s"], [export_payload_bytes] bytes.", "success")
	return TRUE

/datum/erp_chunked_export_panel_state/proc/begin_import_payload(raw_chunk_count, raw_text_length, max_chunks = ERP_EXPORT_MAX_IMPORT_TRANSFER_CHUNKS, max_text_length = ERP_EXPORT_MAX_IMPORT_TEXT_LENGTH)
	var/chunk_count = sanitize_integer(raw_chunk_count, 1, max_chunks, 0)
	if(!chunk_count)
		clear_pending_import()
		set_status("Import failed: invalid transfer chunk count.", "danger")
		return FALSE

	var/text_length = sanitize_integer(raw_text_length, 1, max_text_length, 0)
	if(!text_length)
		clear_pending_import()
		set_status("Import failed: transfer text is too large.", "danger")
		return FALSE

	pending_import_chunks = list()
	pending_import_chunk_count = chunk_count
	pending_import_text_length = 0
	set_status("Receiving import data: 0/[chunk_count] chunks.", "info")
	return TRUE

/datum/erp_chunked_export_panel_state/proc/append_import_payload_chunk(raw_index, raw_chunk_count, chunk, max_text_length = ERP_EXPORT_MAX_IMPORT_TEXT_LENGTH)
	if(!pending_import_chunks || !pending_import_chunk_count)
		set_status("Import failed: transfer was not initialized. Try importing again.", "danger")
		return list("ok" = FALSE)

	var/chunk_count = sanitize_integer(raw_chunk_count, 1, pending_import_chunk_count, 0)
	if(chunk_count != pending_import_chunk_count)
		clear_pending_import()
		set_status("Import failed: transfer chunk count changed.", "danger")
		return list("ok" = FALSE)

	var/chunk_index = sanitize_integer(raw_index, 1, pending_import_chunk_count, 0)
	if(!chunk_index || !istext(chunk))
		clear_pending_import()
		set_status("Import failed: invalid transfer chunk.", "danger")
		return list("ok" = FALSE)

	var/chunk_key = "[chunk_index]"
	if(!isnull(pending_import_chunks[chunk_key]))
		clear_pending_import()
		set_status("Import failed: duplicate transfer chunk [chunk_index].", "danger")
		return list("ok" = FALSE)

	pending_import_text_length += length(chunk)
	if(pending_import_text_length > max_text_length)
		clear_pending_import()
		set_status("Import failed: transfer text is too large.", "danger")
		return list("ok" = FALSE)

	pending_import_chunks[chunk_key] = chunk
	var/received_count = length(pending_import_chunks)
	if(received_count < pending_import_chunk_count)
		set_status("Receiving import data: [received_count]/[pending_import_chunk_count] chunks.", "info")
		return list("ok" = TRUE, "complete" = FALSE)

	var/raw = ""
	for(var/index in 1 to pending_import_chunk_count)
		var/piece = pending_import_chunks["[index]"]
		if(!istext(piece))
			clear_pending_import()
			set_status("Import failed: missing transfer chunk [index].", "danger")
			return list("ok" = FALSE)
		raw += piece

	clear_pending_import()
	return list("ok" = TRUE, "complete" = TRUE, "payload" = raw)

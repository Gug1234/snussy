/datum/unit_test/chunked_export_round_trip

/datum/unit_test/chunked_export_round_trip/Run()
	var/source = "abcdefghijklmnopqrstuvwxyz0123456789"
	var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_SEX_MENU, source, 10)
	TEST_ASSERT_EQUAL(length(chunks), 4, "expected multiple chunks")

	var/list/result = parse_chunked_export_chunks(chunks.Join("\n"), ERP_EXPORT_KIND_SEX_MENU, 128)
	TEST_ASSERT(result["ok"], result["message"])
	TEST_ASSERT_EQUAL(result["payload"], source, "round-trip payload mismatch")

/datum/unit_test/chunked_export_rejects_wrong_kind

/datum/unit_test/chunked_export_rejects_wrong_kind/Run()
	var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_REACTIONS, "payload", 10)
	var/list/result = parse_chunked_export_chunks(chunks.Join("\n"), ERP_EXPORT_KIND_SEX_MENU, 128)
	TEST_ASSERT(!result["ok"], "wrong export kind should be rejected")

/datum/unit_test/chunked_export_rejects_missing_chunk

/datum/unit_test/chunked_export_rejects_missing_chunk/Run()
	var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_CHARACTER_SLOT, "abcdefghijklmnopqrstuvwxyz", 8)
	chunks.Cut(2, 3)

	var/list/result = parse_chunked_export_chunks(chunks.Join("\n"), ERP_EXPORT_KIND_CHARACTER_SLOT, 128)
	TEST_ASSERT(!result["ok"], "missing chunk should be rejected")

/datum/unit_test/chunked_export_rejects_duplicate_chunk

/datum/unit_test/chunked_export_rejects_duplicate_chunk/Run()
	var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_CHARACTER_SLOT, "abcdefghijklmnopqrstuvwxyz", 8)
	chunks += chunks[1]

	var/list/result = parse_chunked_export_chunks(chunks.Join("\n"), ERP_EXPORT_KIND_CHARACTER_SLOT, 128)
	TEST_ASSERT(!result["ok"], "duplicate chunk should be rejected")

/datum/unit_test/chunked_export_rejects_checksum_mismatch

/datum/unit_test/chunked_export_rejects_checksum_mismatch/Run()
	var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_SEX_MENU, "abcdefghijklmnop", 8)
	var/list/envelope = json_decode(rustg_decode_base64(chunks[1]))
	envelope["payload"] = "ZZZZZZZZ"
	chunks[1] = rustg_encode_base64(json_encode(envelope))

	var/list/result = parse_chunked_export_chunks(chunks.Join("\n"), ERP_EXPORT_KIND_SEX_MENU, 128)
	TEST_ASSERT(!result["ok"], "checksum mismatch should be rejected")

/datum/unit_test/chunked_export_rejects_oversized_payload

/datum/unit_test/chunked_export_rejects_oversized_payload/Run()
	var/list/chunks = build_chunked_export_chunks(ERP_EXPORT_KIND_REACTIONS, "abcdefghijklmnopqrstuvwxyz", 8)

	var/list/result = parse_chunked_export_chunks(chunks.Join("\n"), ERP_EXPORT_KIND_REACTIONS, 8)
	TEST_ASSERT(!result["ok"], "oversized payload should be rejected")

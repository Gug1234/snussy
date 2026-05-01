/*
 * prefs_validators.dm — Unit tests for the TGUI preferences dispatch
 * value validators (plan Step 18).
 *
 * Scope:
 *   Exercise every shape the ui_act("set_pref") payload can take against
 *   each validator proc / factory in modular/code/modules/client/
 *   appearance_preview/prefs_validators.dm. Boundary values are the
 *   point — the dispatcher silently drops any payload whose validator
 *   returns FALSE, so the validators ARE the security boundary.
 */

/datum/unit_test/prefs_validate_bool/Run()
	// Accepted shapes: BYOND-native bool and text form emitted by JSON.
	TEST_ASSERT(prefs_validate_bool(0), "0 must be accepted")
	TEST_ASSERT(prefs_validate_bool(1), "1 must be accepted")
	TEST_ASSERT(prefs_validate_bool(TRUE), "TRUE must be accepted")
	TEST_ASSERT(prefs_validate_bool(FALSE), "FALSE must be accepted")
	TEST_ASSERT(prefs_validate_bool("0"), "text '0' must be accepted")
	TEST_ASSERT(prefs_validate_bool("1"), "text '1' must be accepted")
	// Rejected shapes.
	TEST_ASSERT(!prefs_validate_bool(2), "2 must be rejected")
	TEST_ASSERT(!prefs_validate_bool(-1), "-1 must be rejected")
	TEST_ASSERT(!prefs_validate_bool("true"), "string 'true' must be rejected (only '0'/'1')")
	TEST_ASSERT(!prefs_validate_bool("false"), "string 'false' must be rejected")
	TEST_ASSERT(!prefs_validate_bool(null), "null must be rejected")
	TEST_ASSERT(!prefs_validate_bool(list()), "list must be rejected")

/datum/unit_test/prefs_validate_intrange/Run()
	var/datum/callback/cb = prefs_validate_intrange(1, 10)
	TEST_ASSERT_NOTNULL(cb, "intrange factory must return a callback")
	TEST_ASSERT(!cb.Invoke(0), "0 must be rejected for range 1..10")
	TEST_ASSERT(cb.Invoke(1), "1 must be accepted (lower bound)")
	TEST_ASSERT(cb.Invoke(5), "5 must be accepted (interior)")
	TEST_ASSERT(cb.Invoke(10), "10 must be accepted (upper bound)")
	TEST_ASSERT(!cb.Invoke(11), "11 must be rejected (above upper bound)")
	TEST_ASSERT(!cb.Invoke(null), "null must be rejected")
	TEST_ASSERT(!cb.Invoke("5"), "text '5' must be rejected — intrange requires num")
	TEST_ASSERT(!cb.Invoke(1.5), "non-integer float must be rejected")

/datum/unit_test/prefs_validate_enum/Run()
	var/datum/callback/cb = prefs_validate_enum(list("a", "b", "c"))
	TEST_ASSERT(cb.Invoke("a"), "'a' must be accepted")
	TEST_ASSERT(cb.Invoke("b"), "'b' must be accepted")
	TEST_ASSERT(!cb.Invoke("d"), "'d' must be rejected (not in allow-list)")
	TEST_ASSERT(!cb.Invoke(null), "null must be rejected")
	TEST_ASSERT(!cb.Invoke(""), "empty string must be rejected")
	// Numeric enum members.
	var/datum/callback/cb_num = prefs_validate_enum(list(1, 2, 3))
	TEST_ASSERT(cb_num.Invoke(2), "numeric enum entry must be accepted")
	TEST_ASSERT(!cb_num.Invoke(4), "numeric enum non-member must be rejected")

/datum/unit_test/prefs_validate_hex/Run()
	TEST_ASSERT(prefs_validate_hex("#FFFFFF"), "#FFFFFF must be accepted")
	TEST_ASSERT(prefs_validate_hex("#ffffff"), "#ffffff must be accepted (lowercase)")
	TEST_ASSERT(prefs_validate_hex("FFFFFF"), "FFFFFF (no hash) must be accepted")
	TEST_ASSERT(prefs_validate_hex("#012abc"), "#012abc mixed digits/letters must be accepted")
	TEST_ASSERT(!prefs_validate_hex("#fff"), "#fff (short form) must be rejected")
	TEST_ASSERT(!prefs_validate_hex("#GGGGGG"), "#GGGGGG (non-hex chars) must be rejected")
	TEST_ASSERT(!prefs_validate_hex("#1234567"), "#1234567 (too long) must be rejected")
	TEST_ASSERT(!prefs_validate_hex("#12345"), "#12345 (too short) must be rejected")
	TEST_ASSERT(!prefs_validate_hex(null), "null must be rejected")
	TEST_ASSERT(!prefs_validate_hex(""), "empty string must be rejected")
	TEST_ASSERT(!prefs_validate_hex(0xFFFFFF), "numeric form must be rejected — text only")

/datum/unit_test/prefs_validate_string/Run()
	var/datum/callback/cb = prefs_validate_string(16)
	TEST_ASSERT(cb.Invoke(""), "empty string must be accepted")
	TEST_ASSERT(cb.Invoke("hello"), "short string must be accepted")
	TEST_ASSERT(cb.Invoke("1234567890123456"), "exactly 16 chars must be accepted (boundary)")
	TEST_ASSERT(!cb.Invoke("12345678901234567"), "17 chars must be rejected (over cap)")
	TEST_ASSERT(!cb.Invoke(null), "null must be rejected")
	TEST_ASSERT(!cb.Invoke(5), "number must be rejected — text only")

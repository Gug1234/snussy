/*
 * prefs_dispatch_table.dm — Unit tests for the TGUI preferences dispatch
 * registry integrity (plan Step 18).
 *
 * Scope:
 *   Walk the dispatch tables populated by ensure_prefs_dispatch_tables()
 *   and assert every registration is internally well-formed. The walk
 *   mirrors the dispatcher's own lookup path, so drift between a new
 *   PREF_KEY_* define and its /datum/preferences setter proc lights up
 *   at CI time rather than at runtime.
 *
 * Guarantees asserted:
 *   1. Every GLOB.prefs_setter_table entry has a resolvable setter proc
 *      (hascall on /datum/preferences) and a non-null /datum/callback
 *      validator.
 *   2. Every GLOB.prefs_action_table entry has a resolvable handler
 *      proc on /datum/preferences.
 *   3. The two tables are disjoint by key — ui_act("set_pref") MUST NOT
 *      be able to reach a bottom-bar action even on key collision.
 *   4. GLOB.prefs_action_table contains exactly the three seeded keys.
 */

/datum/unit_test/prefs_dispatch_table_setters/Run()
	ensure_prefs_dispatch_tables()
	TEST_ASSERT(GLOB.prefs_dispatch_tables_registered, "ensure_prefs_dispatch_tables should flip the registered flag")

	var/list/setter_table = GLOB.prefs_setter_table
	TEST_ASSERT(islist(setter_table), "setter table must be a list")
	TEST_ASSERT(length(setter_table) > 0, "setter table must not be empty after registration")

	// Use a prefs instance as the hascall receiver. /datum/preferences has
	// a non-trivial /New, but hascall only needs the type — we use a
	// freshly constructed stub subtype with a no-op /New (borrowed from
	// the appearance_preview test prefs pattern) so construction is free.
	var/datum/preferences/appearance_preview_test_prefs/probe = new
	for(var/key in setter_table)
		var/datum/prefs_setter/setter = setter_table[key]
		TEST_ASSERT_NOTNULL(setter, "setter for key '[key]' must not be null")
		TEST_ASSERT_EQUAL(setter.key, key, "setter.key must match its table key for '[key]'")
		TEST_ASSERT(istext(setter.setter_name) && length(setter.setter_name), "setter_name missing for key '[key]'")
		TEST_ASSERT(hascall(probe, setter.setter_name), "setter '[setter.setter_name]' for key '[key]' is not a proc on /datum/preferences")
		// Every validator is normalized to /datum/callback in /datum/prefs_setter/New.
		TEST_ASSERT(istype(setter.validator, /datum/callback), "validator for key '[key]' must be /datum/callback after normalization")

/datum/unit_test/prefs_dispatch_table_actions/Run()
	ensure_prefs_dispatch_tables()

	var/list/action_table = GLOB.prefs_action_table
	TEST_ASSERT(islist(action_table), "action table must be a list")
	TEST_ASSERT_EQUAL(length(action_table), 3, "action table must contain exactly 3 bottom-bar actions (join_round, observe, join_migrant)")

	TEST_ASSERT_NOTNULL(action_table[PREFS_ACTION_JOIN_ROUND], "join_round action must be registered")
	TEST_ASSERT_NOTNULL(action_table[PREFS_ACTION_OBSERVE], "observe action must be registered")
	TEST_ASSERT_NOTNULL(action_table[PREFS_ACTION_JOIN_MIGRANT], "join_migrant action must be registered")

	var/datum/preferences/appearance_preview_test_prefs/probe = new
	for(var/key in action_table)
		var/datum/prefs_action/action = action_table[key]
		TEST_ASSERT_EQUAL(action.key, key, "action.key must match its table key for '[key]'")
		TEST_ASSERT(istext(action.handler_name) && length(action.handler_name), "handler_name missing for action '[key]'")
		TEST_ASSERT(hascall(probe, action.handler_name), "action handler '[action.handler_name]' for key '[key]' is not a proc on /datum/preferences")

/datum/unit_test/prefs_dispatch_table_disjoint/Run()
	ensure_prefs_dispatch_tables()

	// The security boundary: ui_act("set_pref", {key, value}) routes
	// through prefs_setter_table only. If a bottom-bar action key ever
	// collides with a setter key, an unvalidated write could reach the
	// action handler OR vice versa. Assert disjointness explicitly.
	for(var/key in GLOB.prefs_action_table)
		TEST_ASSERT(isnull(GLOB.prefs_setter_table[key]), "action key '[key]' must NOT appear in prefs_setter_table")
	for(var/key in GLOB.prefs_setter_table)
		TEST_ASSERT(isnull(GLOB.prefs_action_table[key]), "setter key '[key]' must NOT appear in prefs_action_table")

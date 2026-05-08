/datum/unit_test/intimate_reaction_preferences/Run()
	var/datum/preferences/prefs = new
	prefs.custom_intimate_reactions = list(
		"neutral_movement" = list("one step"),
		"weight_neutral_movement" = list(100),
		"audience_neutral_movement" = INTIMATE_AUDIENCE_NEARBY,
		"audience_neutral_sex_received" = "invalid",
		"audience_not_a_real_category" = INTIMATE_AUDIENCE_VIEW,
	)

	prefs.validate_custom_intimate_reactions()

	TEST_ASSERT_EQUAL(prefs.custom_intimate_reactions["audience_neutral_movement"], INTIMATE_AUDIENCE_NEARBY, "valid audience metadata should survive preference validation")
	TEST_ASSERT_NULL(prefs.custom_intimate_reactions["audience_neutral_sex_received"], "invalid audience values should be removed")
	TEST_ASSERT_NULL(prefs.custom_intimate_reactions["audience_not_a_real_category"], "audience metadata for unknown categories should be removed")
	TEST_ASSERT_EQUAL(prefs.get_intimate_reaction_audience("neutral_movement", INTIMATE_AUDIENCE_SELF), INTIMATE_AUDIENCE_NEARBY, "stored audience should override the default")
	TEST_ASSERT_EQUAL(prefs.get_intimate_reaction_audience("neutral_sex_received", INTIMATE_AUDIENCE_SELF), INTIMATE_AUDIENCE_SELF, "missing audience metadata should return the caller's default")

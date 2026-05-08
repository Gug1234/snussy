/datum/unit_test/erp_preview_tokens/Run()
	var/datum/preferences/prefs = new
	prefs.real_name = "Preview Ratwood"
	prefs.pronouns = SHE_HER

	prefs.refresh_erp_preview_tokens_from_preferences()

	TEST_ASSERT(islist(prefs.erp_preview_tokens), "refresh should create a preview token profile")
	TEST_ASSERT_EQUAL(prefs.erp_preview_tokens["user_name"], "Preview Ratwood", "refresh should copy the character name")
	TEST_ASSERT_EQUAL(prefs.erp_preview_tokens["user_they"], "she", "refresh should copy subject pronouns")
	TEST_ASSERT_EQUAL(prefs.erp_preview_tokens["target_name"], "John Ratwood", "default target should be the masculine preset")

	prefs.set_erp_preview_token("target_preset", "jane")
	TEST_ASSERT_EQUAL(prefs.erp_preview_tokens["target_name"], "Jane Ratwood", "target preset should update target name")
	TEST_ASSERT_EQUAL(prefs.erp_preview_tokens["target_they"], "she", "target preset should update target pronouns")

	prefs.set_erp_preview_token("target_vag", "furred slit")
	prefs.refresh_erp_preview_tokens_from_preferences()
	TEST_ASSERT_EQUAL(prefs.erp_preview_tokens["target_vag"], "furred slit", "refresh should not overwrite target dropdown choices")

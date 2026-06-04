/datum/unit_test/custom_sex_action_feedback_validation/Run()
	var/datum/preferences/prefs = new
	prefs.custom_sex_actions = list(
		list(
			"slot" = 1,
			"name" = "Wet Rhythm",
			"template" = "penetration",
			"sound_course" = CUSTOM_SEX_SOUND_INTERCOURSE_WET,
			"animation_type" = CUSTOM_SEX_ANIMATION_SOFT_THRUST,
			"on_start_text" = "",
			"on_perform_text" = "",
			"on_finish_text" = "",
			"user_arousal" = 1,
			"target_arousal" = 2,
			"user_pain" = 0,
			"target_pain" = 0,
			"stamina_cost" = 1,
			"category" = SEX_CATEGORY_PENETRATE,
			"user_sex_part" = SEX_PART_COCK,
			"target_sex_part" = SEX_PART_CUNT,
			"requires_other" = TRUE,
			"continuous" = TRUE,
		),
		list(
			"slot" = 2,
			"name" = "Legacy Silent",
			"template" = "manual",
			"sound_course" = "bad-sound",
			"animation_type" = "bad-animation",
			"on_start_text" = "",
			"on_perform_text" = "",
			"on_finish_text" = "",
			"user_arousal" = 1,
			"target_arousal" = 1,
			"user_pain" = 0,
			"target_pain" = 0,
			"stamina_cost" = 0,
			"category" = SEX_CATEGORY_MISC,
			"user_sex_part" = SEX_PART_NULL,
			"target_sex_part" = SEX_PART_NULL,
			"requires_other" = TRUE,
			"continuous" = TRUE,
		),
	)

	prefs.validate_custom_sex_actions()

	TEST_ASSERT_EQUAL(prefs.custom_sex_actions[1]["sound_course"], CUSTOM_SEX_SOUND_INTERCOURSE_WET, "valid custom action sound courses must survive preference validation")
	TEST_ASSERT_EQUAL(prefs.custom_sex_actions[1]["animation_type"], CUSTOM_SEX_ANIMATION_SOFT_THRUST, "valid custom action animation types must survive preference validation")
	TEST_ASSERT_EQUAL(prefs.custom_sex_actions[2]["sound_course"], CUSTOM_SEX_SOUND_NONE, "invalid custom action sound courses should fall back to none")
	TEST_ASSERT_EQUAL(prefs.custom_sex_actions[2]["animation_type"], CUSTOM_SEX_ANIMATION_NONE, "invalid custom action animation types should fall back to none")

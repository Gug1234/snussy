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

/datum/unit_test/custom_sex_action_feedback_tokens/Run()
	var/mob/living/carbon/human/consistent/user = allocate(/mob/living/carbon/human/consistent)
	var/mob/living/carbon/human/consistent/target = allocate(/mob/living/carbon/human/consistent)

	var/obj/item/organ/vagina/user_vagina = allocate(/obj/item/organ/vagina)
	user_vagina.Insert(user)
	var/obj/item/organ/penis/knotted/target_penis = allocate(/obj/item/organ/penis/knotted)
	target_penis.Insert(target)

	var/datum/sex_action/custom/action = allocate(/datum/sex_action/custom)
	var/resolved = action.resolve_sex_flavor_tokens("\[UCOCK] against \[UVAG], then \[TCOCK].", user, target)

	TEST_ASSERT(!findtext(resolved, "\[UCOCK]"), "custom sex user cock token should resolve")
	TEST_ASSERT(!findtext(resolved, "\[UVAG]"), "custom sex user vagina token should resolve")
	TEST_ASSERT(!findtext(resolved, "\[TCOCK]"), "custom sex target cock token should resolve")

/datum/unit_test/custom_anatomy_token_preferences/Run()
	var/datum/preferences/prefs = new

	TEST_ASSERT(prefs.set_custom_anatomy_token("cock", "<b>big ol dick</b>"), "valid custom anatomy tokens should save")
	TEST_ASSERT_EQUAL(prefs.get_custom_anatomy_token("cock"), "big ol dick", "custom anatomy tokens should sanitize saved text")
	TEST_ASSERT(!prefs.set_custom_anatomy_token("bad_key", "ignored"), "unknown custom anatomy token keys should be rejected")

	TEST_ASSERT_EQUAL(resolve_custom_anatomy_token(null, "cock", CUSTOM_ANATOMY_TOKEN_BARE, "plain cock", prefs), "big ol dick", "bare custom anatomy tokens should omit pronouns")
	TEST_ASSERT_EQUAL(resolve_custom_anatomy_token(null, "cock", CUSTOM_ANATOMY_TOKEN_POSSESSIVE, "plain cock", prefs), "their big ol dick", "third-person custom anatomy tokens should add possessive pronouns")
	TEST_ASSERT_EQUAL(resolve_custom_anatomy_token(null, "cock", CUSTOM_ANATOMY_TOKEN_SECOND_PERSON, "plain cock", prefs), "your big ol dick", "second-person custom anatomy tokens should add second-person possessive pronouns")

	TEST_ASSERT(prefs.clear_custom_anatomy_token("cock"), "clearing a valid custom anatomy token should succeed")
	TEST_ASSERT_NULL(prefs.get_custom_anatomy_token("cock"), "cleared custom anatomy tokens should not remain in preferences")

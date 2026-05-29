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

/datum/unit_test/intimate_reaction_character_flavor_attachment/Run()
	var/mob/living/carbon/human/preview = allocate(/mob/living/carbon/human)
	var/datum/preferences/prefs = new

	prefs.custom_intimate_reactions = list(
		"audience_neutral_movement" = INTIMATE_AUDIENCE_NEARBY,
		"weight_neutral_movement" = list(100),
	)
	prefs.apply_character_flavor_component(preview)
	TEST_ASSERT_NULL(preview.GetComponent(/datum/component/intimate_reaction/character_flavor), "metadata-only character flavor prefs must not attach the component")

	prefs.custom_intimate_reactions = list("neutral_movement" = list("one custom step"))
	prefs.apply_character_flavor_component(preview)
	var/datum/component/intimate_reaction/character_flavor/reaction = preview.GetComponent(/datum/component/intimate_reaction/character_flavor)
	TEST_ASSERT_NOTNULL(reaction, "custom character flavor strings should attach the component")
	TEST_ASSERT_EQUAL(reaction.pick_flavor_string("neutral_movement", null, null), "one custom step", "attached component should use player-written character flavor strings")

/datum/unit_test/intimate_reaction_preferences/Run()
	var/datum/preferences/prefs = new
	prefs.custom_intimate_reactions = list(
		"neutral_movement" = list("one step"),
		"weight_neutral_movement" = list(100),
		"audience_neutral_movement" = INTIMATE_AUDIENCE_NEARBY,
		"audience_neutral_sex_received" = "invalid",
		"audience_not_a_real_category" = INTIMATE_AUDIENCE_VIEW,
		"disabled_chastity_jingle_cloth" = TRUE,
		"disabled_chastity_arousal_denial" = TRUE,
		"disabled_chastity_pain_high" = TRUE,
		"disabled_not_a_real_category" = TRUE,
	)

	prefs.validate_custom_intimate_reactions()

	TEST_ASSERT_EQUAL(prefs.custom_intimate_reactions["audience_neutral_movement"], INTIMATE_AUDIENCE_NEARBY, "valid audience metadata should survive preference validation")
	TEST_ASSERT_NULL(prefs.custom_intimate_reactions["audience_neutral_sex_received"], "invalid audience values should be removed")
	TEST_ASSERT_NULL(prefs.custom_intimate_reactions["audience_not_a_real_category"], "audience metadata for unknown categories should be removed")
	TEST_ASSERT_EQUAL(prefs.custom_intimate_reactions["disabled_chastity_jingle_cloth"], TRUE, "valid disabled category metadata should survive preference validation")
	TEST_ASSERT_EQUAL(prefs.custom_intimate_reactions["disabled_chastity_arousal_denial"], TRUE, "valid arousal disabled metadata should survive preference validation")
	TEST_ASSERT_EQUAL(prefs.custom_intimate_reactions["disabled_chastity_pain_high"], TRUE, "valid pain disabled metadata should survive preference validation")
	TEST_ASSERT_NULL(prefs.custom_intimate_reactions["disabled_not_a_real_category"], "disabled metadata for unknown categories should be removed")
	TEST_ASSERT_EQUAL(prefs.get_intimate_reaction_audience("neutral_movement", INTIMATE_AUDIENCE_SELF), INTIMATE_AUDIENCE_NEARBY, "stored audience should override the default")
	TEST_ASSERT_EQUAL(prefs.get_intimate_reaction_audience("neutral_sex_received", INTIMATE_AUDIENCE_SELF), INTIMATE_AUDIENCE_SELF, "missing audience metadata should return the caller's default")
	TEST_ASSERT(!prefs.intimate_reaction_category_enabled("chastity_jingle_cloth"), "disabled category metadata should suppress that category")
	TEST_ASSERT(!prefs.intimate_reaction_category_enabled("chastity_arousal_denial"), "disabled arousal category metadata should suppress that category")
	TEST_ASSERT(!prefs.intimate_reaction_category_enabled("chastity_pain_high"), "disabled pain category metadata should suppress that category")
	TEST_ASSERT(prefs.intimate_reaction_category_enabled("chastity_jingle_emotes"), "categories without disabled metadata should stay enabled")
	TEST_ASSERT(!prefs.can_emit_intimate_reaction_category("chastity_jingle_cloth", INTIMATE_CONTENT_CHASTITY), "disabled category should not emit")
	TEST_ASSERT(!prefs.can_emit_intimate_reaction_category("chastity_arousal_denial", INTIMATE_CONTENT_CHASTITY), "disabled arousal bank should not emit")
	TEST_ASSERT(!prefs.can_emit_intimate_reaction_category("chastity_pain_high", INTIMATE_CONTENT_CHASTITY | INTIMATE_CONTENT_EXTREME), "disabled pain bank should not emit")
	TEST_ASSERT(prefs.set_intimate_reaction_category_enabled("chastity_jingle_cloth", TRUE), "valid category should accept enabled toggle")
	TEST_ASSERT(prefs.intimate_reaction_category_enabled("chastity_jingle_cloth"), "enabling a category should remove disabled metadata")
	TEST_ASSERT(!prefs.set_intimate_reaction_category_enabled("not_a_real_category", FALSE), "unknown category should reject enabled toggle")

	prefs.intimate_reaction_enabled = FALSE
	TEST_ASSERT(!prefs.can_emit_intimate_reaction_category("chastity_jingle_emotes", INTIMATE_CONTENT_CHASTITY), "master toggle should suppress source emission")
	prefs.intimate_reaction_enabled = TRUE
	prefs.intimate_reaction_show_chastity = FALSE
	TEST_ASSERT(!prefs.can_emit_intimate_reaction_category("chastity_jingle_emotes", INTIMATE_CONTENT_CHASTITY), "chastity reaction toggle should suppress source emission")

/datum/unit_test/intimate_reaction_token_perspective/Run()
	var/mob/living/carbon/human/consistent/source = allocate(/mob/living/carbon/human/consistent)
	source.name = "Josh Killerfang"

	var/raw_text = "\[USERPOS] tail blooms while \[USER] can feel it."
	TEST_ASSERT_EQUAL(resolve_intimate_reaction_tokens(raw_text, source, null, TRUE), "your tail blooms while you can feel it.", "wearer-facing tokens should resolve in second person")
	TEST_ASSERT_EQUAL(resolve_intimate_reaction_tokens(raw_text, source), "Josh Killerfang's tail blooms while Josh Killerfang can feel it.", "viewer-facing tokens should resolve in third person")

/datum/unit_test/intimate_reaction_character_flavor_attachment/Run()
	var/mob/living/carbon/human/consistent/preview = allocate(/mob/living/carbon/human/consistent)
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

	prefs.intimate_reaction_enabled = FALSE
	prefs.apply_character_flavor_component(preview)
	TEST_ASSERT_NULL(preview.GetComponent(/datum/component/intimate_reaction/character_flavor), "disabling intimate reactions should remove the character flavor component")

	prefs.intimate_reaction_enabled = TRUE
	prefs.apply_character_flavor_component(preview)
	TEST_ASSERT_NOTNULL(preview.GetComponent(/datum/component/intimate_reaction/character_flavor), "re-enabling intimate reactions should reattach custom character flavor strings")

/datum/unit_test/content_gated_visible_message_helper/proc/allows_expected_viewer(mob/allowed, mob/blocked, mob/viewer)
	return viewer == allowed && viewer != blocked

/datum/unit_test/content_gated_visible_message_helper/Run()
	var/mob/living/carbon/human/consistent/source = allocate(/mob/living/carbon/human/consistent)
	source.forceMove(run_loc_bottom_left)

	var/mob/living/carbon/human/consistent/allowed = allocate(/mob/living/carbon/human/consistent)
	allowed.forceMove(run_loc_bottom_left)

	var/mob/living/carbon/human/consistent/blocked = allocate(/mob/living/carbon/human/consistent)
	blocked.forceMove(run_loc_bottom_left)

	var/datum/callback/filter = CALLBACK(src, PROC_REF(allows_expected_viewer), allowed, blocked)
	var/accepted_viewers = send_gated_visible_message(source, "observer text", "self text", DEFAULT_MESSAGE_RANGE, filter)

	TEST_ASSERT_EQUAL(accepted_viewers, 1, "The helper should scan local hearers once, skip the self-message target, and count only filter-approved observers.")

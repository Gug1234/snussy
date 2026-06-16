/datum/preferences/unit_test_genital_customizer_preferences/New(client/C)
	return

/datum/unit_test/lobby_arousal_preview_preference_contract/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_genital_customizer_preferences(null)
	TEST_ASSERT(("preview_erect_state" in prefs.vars), "preferences should expose a transient lobby arousal preview state")
	TEST_ASSERT_EQUAL(prefs.vars["preview_erect_state"], ERECT_STATE_NONE, "lobby arousal preview should default to none")
	TEST_ASSERT(hascall(prefs, "cycle_preview_erect_state"), "preferences should expose a helper for cycling lobby arousal preview state")
	TEST_ASSERT(hascall(prefs, "apply_preview_erect_state_to_mannequin"), "preferences should expose a helper for applying arousal preview state")

	call(prefs, "cycle_preview_erect_state")()
	TEST_ASSERT_EQUAL(prefs.vars["preview_erect_state"], ERECT_STATE_PARTIAL, "lobby arousal preview should cycle none to partial")
	call(prefs, "cycle_preview_erect_state")()
	TEST_ASSERT_EQUAL(prefs.vars["preview_erect_state"], ERECT_STATE_HARD, "lobby arousal preview should cycle partial to hard")
	call(prefs, "cycle_preview_erect_state")()
	TEST_ASSERT_EQUAL(prefs.vars["preview_erect_state"], ERECT_STATE_NONE, "lobby arousal preview should cycle hard back to none")

	var/mob/living/carbon/human/dummy/preview = allocate(/mob/living/carbon/human/dummy, null)
	var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
	penis.Insert(preview)
	prefs.vars["preview_erect_state"] = ERECT_STATE_HARD
	call(prefs, "apply_preview_erect_state_to_mannequin")(preview)
	TEST_ASSERT_EQUAL(penis.erect_state, ERECT_STATE_HARD, "lobby arousal preview should apply to the preview mannequin penis")

	qdel(prefs)

/datum/unit_test/penis_customizer_sheath_preference_contract/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_genital_customizer_preferences(null)
	var/datum/customizer_choice/organ/penis/human/choice = new
	var/datum/customizer_entry/organ/penis/entry = new
	entry.customizer_type = /datum/customizer/organ/penis/human
	entry.customizer_choice_type = /datum/customizer_choice/organ/penis/human

	TEST_ASSERT(("sheath_type" in entry.vars), "penis customizer entries should save a sheath/slit preference")
	TEST_ASSERT_EQUAL(entry.vars["sheath_type"], SHEATH_TYPE_NONE, "penis customizer sheath preference should default to none")

	var/list/dat = list()
	choice.generate_pref_choices(dat, prefs, entry, /datum/customizer/organ/penis/human)
	var/html = dat.Join()
	TEST_ASSERT(findtext(html, "Sheath"), "penis customizer UI should show the sheath/slit selector")
	TEST_ASSERT(findtext(html, "customizer_task=sheath_type"), "penis customizer UI should route sheath selector clicks")

	entry.vars["sheath_type"] = SHEATH_TYPE_SLIT
	var/datum/organ_dna/penis/penis_dna = choice.create_organ_dna(entry, prefs)
	TEST_ASSERT(("sheath_type" in penis_dna.vars), "penis organ DNA should save the customizer sheath/slit preference")
	TEST_ASSERT_EQUAL(penis_dna.vars["sheath_type"], SHEATH_TYPE_SLIT, "penis organ DNA should receive the selected sheath/slit preference")

	var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
	penis_dna.imprint_organ(penis)
	TEST_ASSERT_EQUAL(penis.sheath_type, SHEATH_TYPE_SLIT, "generated penis organs should receive the selected sheath/slit preference")

	qdel(choice)
	qdel(prefs)

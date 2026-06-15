/datum/preferences/unit_test_tailmaw_customizer/New(client/C)
	return

/datum/unit_test/tailmaw_customizer_uses_manticore_tail_organ

/datum/unit_test/tailmaw_customizer_uses_manticore_tail_organ/proc/make_tail_entry(accessory_type)
	var/datum/customizer_entry/entry = new /datum/customizer_entry()
	entry.customizer_choice_type = /datum/customizer_choice/organ/tail/demihuman
	entry.accessory_type = accessory_type
	allocated += entry
	return entry

/datum/unit_test/tailmaw_customizer_uses_manticore_tail_organ/Run()
	var/datum/preferences/prefs = new /datum/preferences/unit_test_tailmaw_customizer(null)
	allocated += prefs
	var/datum/customizer_choice/organ/tail/demihuman/tail_choice = CUSTOMIZER_CHOICE(/datum/customizer_choice/organ/tail/demihuman)
	var/list/tailmaw_accessories = list(
		/datum/sprite_accessory/tail/tailmaw,
		/datum/sprite_accessory/tail/tailmaw2,
		/datum/sprite_accessory/tail/tailmaw2_head,
		/datum/sprite_accessory/tail/tailmaw2_stripes,
		/datum/sprite_accessory/tail/tailmaw2_headstripes,
	)

	for(var/accessory_type as anything in tailmaw_accessories)
		var/datum/customizer_entry/entry = make_tail_entry(accessory_type)
		var/datum/organ_dna/organ_dna = tail_choice.create_organ_dna(entry, prefs)
		TEST_ASSERT(ispath(organ_dna.organ_type, /obj/item/organ/tail/manticore), "[accessory_type] must create a manticore-tail organ")

/datum/unit_test/manticore_tail_arousal_updates_wagging_and_examine

/datum/unit_test/manticore_tail_arousal_updates_wagging_and_examine/proc/list_has_text(list/lines, needle)
	for(var/line in lines)
		if(findtext(line, needle))
			return TRUE
	return FALSE

/datum/unit_test/manticore_tail_arousal_updates_wagging_and_examine/proc/list_has_all_text(list/lines, list/needles)
	for(var/line in lines)
		var/has_all = TRUE
		for(var/needle in needles)
			if(!findtext(line, needle))
				has_all = FALSE
				break
		if(has_all)
			return TRUE
	return FALSE

/datum/unit_test/manticore_tail_arousal_updates_wagging_and_examine/Run()
	var/mob/living/carbon/human/consistent/H = allocate(/mob/living/carbon/human/consistent)
	H.forceMove(run_loc_bottom_left)
	H.gender = MALE

	var/obj/item/organ/tail/manticore/tail = allocate(/obj/item/organ/tail/manticore, null)
	tail.Insert(H, drop_if_replaced = FALSE)
	TEST_ASSERT_EQUAL(H.getorganslot(ORGAN_SLOT_TAIL), tail, "manticore tail should be inserted into the tail organ slot")

	TEST_ASSERT(!tail.maw_engorged, "manticore tail maw should begin closed")
	TEST_ASSERT(!tail.wagging, "manticore tail should begin in its non-wagging sprite state")
	var/obj/item/organ/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		penis = allocate(/obj/item/organ/penis, null)
		penis.Insert(H)
	var/list/visible_genital_lines = build_cool_description(H.get_mob_descriptors(FALSE, H), H, H)
	TEST_ASSERT(list_has_all_text(visible_genital_lines, list("<span style='color:#ff66cc'>", "soft and flaccid")), "visible genital descriptor text should use ERP pink without leaving the descriptor bank")

	H.underwear = allocate(/obj/item/undies)
	var/list/closed_top_lines = H.human_modular_examine_extension(H, FALSE, "He is", "his", "He has")
	TEST_ASSERT(!list_has_text(closed_top_lines, "sealed tightly shut"), "closed manticore tail state should not appear in the top-level modular examine block")
	var/list/closed_descriptor_lines = build_cool_description(H.get_mob_descriptors(FALSE, H), H, H)
	TEST_ASSERT(list_has_all_text(closed_descriptor_lines, list("<span style='color:#ff66cc'>", "sealed tightly")), "closed manticore tail state should appear in the descriptor bank with ERP pink even when the groin is covered")

	H.sexcon.set_arousal(40)
	TEST_ASSERT(tail.maw_engorged, "manticore tail maw should open after arousal rises above its threshold")
	TEST_ASSERT(tail.wagging, "manticore tail should switch to its wagging sprite state after arousal rises above its threshold")
	var/list/open_top_lines = H.human_modular_examine_extension(H, FALSE, "He is", "his", "He has")
	TEST_ASSERT(!list_has_text(open_top_lines, "splayed open"), "open manticore tail state should not appear in the top-level modular examine block")
	var/list/open_descriptor_lines = build_cool_description(H.get_mob_descriptors(FALSE, H), H, H)
	TEST_ASSERT(list_has_all_text(open_descriptor_lines, list("<span style='color:#ff5555'>", "splayed open")), "open manticore tail state should appear in the descriptor bank with red arousal coloring")

	H.sexcon.set_arousal(0)
	TEST_ASSERT(!tail.maw_engorged, "manticore tail maw should close after arousal falls below its threshold")
	TEST_ASSERT(!tail.wagging, "manticore tail should stop wagging after arousal falls below its threshold")
	var/list/reclosed_descriptor_lines = build_cool_description(H.get_mob_descriptors(FALSE, H), H, H)
	TEST_ASSERT(list_has_all_text(reclosed_descriptor_lines, list("<span style='color:#ff66cc'>", "sealed tightly")), "closed manticore tail state should return to ERP pink after arousal falls below its threshold")

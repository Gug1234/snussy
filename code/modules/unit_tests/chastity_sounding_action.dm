/datum/unit_test/chastity_sounding_action_requires_sounding_rod/proc/make_human_with_penis()
	var/mob/living/carbon/human/consistent/H = allocate(/mob/living/carbon/human/consistent)
	if(!H.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
		penis.Insert(H)
	return H

/datum/unit_test/chastity_sounding_action_requires_sounding_rod/Run()
	var/mob/living/carbon/human/consistent/user = make_human_with_penis()
	var/mob/living/carbon/human/consistent/target = make_human_with_penis()
	user.forceMove(run_loc_bottom_left)
	target.forceMove(run_loc_bottom_left)
	var/obj/item/chastity/chastity_cage/cage = allocate(/obj/item/chastity/chastity_cage, target)
	cage.finalize_chastity_equip(target)
	cage.apply_standard_chastity_traits(target)

	var/datum/sex_action/chastityplay/sounding_cock_cage/action = new()
	TEST_ASSERT(!action.shows_on_menu(user, target), "caged sounding action should not appear without a sounding rod")
	TEST_ASSERT(!action.can_perform(user, target), "caged sounding action should not perform without a sounding rod")

	var/obj/item/intimate_accessory/genital/plug/sounding_rod/gold/user_sounding_rod = allocate(/obj/item/intimate_accessory/genital/plug/sounding_rod/gold)
	user.intimate_genital_insertable = user_sounding_rod
	TEST_ASSERT(!action.shows_on_menu(user, target), "caged sounding action should not appear when only the user has a sounding rod")
	TEST_ASSERT(!action.can_perform(user, target), "caged sounding action should not perform when only the user has a sounding rod")

	var/obj/item/intimate_accessory/genital/plug/gold/vaginal_plug = allocate(/obj/item/intimate_accessory/genital/plug/gold)
	target.intimate_genital_insertable = vaginal_plug
	TEST_ASSERT(!action.shows_on_menu(user, target), "caged sounding action should not appear with a non-sounding genital insertable")
	TEST_ASSERT(!action.can_perform(user, target), "caged sounding action should not perform with a non-sounding genital insertable")

	var/obj/item/intimate_accessory/genital/plug/sounding_rod/gold/target_sounding_rod = allocate(/obj/item/intimate_accessory/genital/plug/sounding_rod/gold)
	target.intimate_genital_insertable = target_sounding_rod
	TEST_ASSERT(action.shows_on_menu(user, target), "caged sounding action should appear when the target has a sounding rod")
	TEST_ASSERT(action.can_perform(user, target), "caged sounding action should perform when the target has a sounding rod")

	qdel(action)

/datum/unit_test/chastity_climax_marks_groin_not_face/proc/make_chaste_human_with_penis()
	var/mob/living/carbon/human/consistent/H = allocate(/mob/living/carbon/human/consistent)
	if(!H.getorganslot(ORGAN_SLOT_PENIS))
		var/obj/item/organ/penis/penis = allocate(/obj/item/organ/penis, null)
		penis.Insert(H)
	var/obj/item/chastity/chastity_cage/cage = allocate(/obj/item/chastity/chastity_cage, H)
	cage.finalize_chastity_equip(H)
	cage.apply_standard_chastity_traits(H)
	return H

/datum/unit_test/chastity_climax_marks_groin_not_face/Run()
	var/mob/living/carbon/human/consistent/wearer = make_chaste_human_with_penis()
	wearer.forceMove(run_loc_bottom_left)

	wearer.sexcon.modular_apply_chastity_cum_to_groin()

	TEST_ASSERT_NULL(wearer.has_status_effect(/datum/status_effect/facial), "chastity climax should not apply facial cum")
	TEST_ASSERT_NULL(wearer.has_status_effect(/datum/status_effect/facial/external), "chastity climax should not apply generic body cum")
	TEST_ASSERT_NOTNULL(wearer.has_status_effect(/datum/status_effect/facial/internal), "chastity climax should mark cum on the groin")

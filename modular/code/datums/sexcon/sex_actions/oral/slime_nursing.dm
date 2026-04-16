/datum/sex_action/slime_nursing
	name = "Nurse from their slime-coated breasts"
	check_same_tile = FALSE
	user_sex_part = SEX_PART_JAWS

/datum/sex_action/slime_nursing/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!target.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(target)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/slime_nursing/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!check_location_accessible(user, target, BODY_ZONE_CHEST, TRUE))
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(target)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/slime_nursing/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] lowers [user.p_their()] mouth to the slime-sheathed curves of [target]'s breasts..."))

/datum/sex_action/slime_nursing/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(target)
	if(!jelly)
		return
	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] suckles at [target]'s breasts while the slime nurses greedily alongside [user.p_them()]."))
	user.sexcon.oralcourse_noise(user)
	apply_silver_intimate_contact("mouth", user, target)

	user.sexcon.perform_sex_action(target, 1, 4, TRUE)
	target.sexcon.handle_passive_ejaculation()

	var/show_nursing_messages = prob(35)
	jelly.handle_breast_nursing(target, user, show_nursing_messages)

/datum/sex_action/slime_nursing/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] lifts [user.p_their()] mouth away from [target]'s slime-sheathed breasts."))

/datum/sex_action/slime_nursing/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


// ════════════════════════════════════════════════════════════════════════════
// SOLO JELLY NURSING — The jelly nurses from the wearer's own breasts.
// Self-target only. No second participant required.
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_nursing_solo
	name = "Let the slime nurse from my breasts"
	check_same_tile = FALSE
	category = SEX_CATEGORY_MISC
	stamina_cost = 0.3

/datum/sex_action/slime_nursing_solo/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(user)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/slime_nursing_solo/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_CHEST, TRUE))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(user)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/slime_nursing_solo/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] cradles [user.p_their()] breasts, coaxing the slime draped across them to begin nursing..."))

/datum/sex_action/slime_nursing_solo/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(user)
	if(!jelly)
		return

	var/message
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			message = "The slime kneads [user]'s breasts in slow, lazy pulses, its membrane rippling as it suckles at [user.p_their()] nipple with gentle, insistent pressure."
		if(SEX_FORCE_MID)
			message = "The slime's tendrils wrap tighter around [user]'s breasts, squeezing in rhythmic waves as its mouth-like opening latches on and nurses with greedy, wet suction."
		if(SEX_FORCE_HIGH)
			message = "The slime engulfs [user]'s breasts almost entirely, its body pulsing in hard, milking contractions, the suction at [user.p_their()] nipples bordering on painful."
		if(SEX_FORCE_EXTREME)
			message = "The slime clamps down on [user]'s breasts with bruising force, its entire mass undulating in frenzied nursing spasms, draining every drop it can wring from the abused flesh."
	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.make_sucking_noise()

	user.sexcon.perform_sex_action(user, 2, 1, FALSE)

	var/show_nursing_messages = prob(35)
	jelly.handle_breast_nursing(user, null, show_nursing_messages)

/datum/sex_action/slime_nursing_solo/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("The slime reluctantly releases [user]'s breasts, its membrane peeling away from [user.p_their()] nipples with a soft, wet pop."))

/datum/sex_action/slime_nursing_solo/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return user.sexcon.finished_check()

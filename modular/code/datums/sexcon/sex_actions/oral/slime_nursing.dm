/datum/sex_action/slime_nursing
	name = "Nurse from their slime-coated breasts"
	check_same_tile = FALSE
	user_sex_part = SEX_PART_JAWS

/datum/sex_action/slime_nursing/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(target)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/slime_nursing/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
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
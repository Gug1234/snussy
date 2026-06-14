/datum/sex_action/suck_nipples
	name = "Suck their nipples"
	check_same_tile = FALSE
	user_sex_part = SEX_PART_JAWS

/datum/sex_action/suck_nipples/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!target.get_visible_genital_organ(ORGAN_SLOT_BREASTS))
		return FALSE
	return TRUE

/datum/sex_action/suck_nipples/can_perform(mob/living/user, mob/living/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_CHEST, TRUE))
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!target.get_visible_genital_organ(ORGAN_SLOT_BREASTS))
		return FALSE
	return TRUE

/datum/sex_action/suck_nipples/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(get_breast_piercing(target))
		user.visible_message(span_warning("[user] starts sucking around [target]'s pierced nipples..."))
	else
		user.visible_message(span_warning("[user] starts sucking [target]'s nipples..."))

/datum/sex_action/suck_nipples/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(get_breast_piercing(target))
		user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] sucks and tugs at [target]'s pierced nipples..."))
	else
		user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] sucks [target]'s nipples..."))
	user.sexcon.oralcourse_noise(user)
	apply_silver_intimate_contact("mouth", user, target)
	apply_silver_intimate_contact("breast", target, user)

	user.sexcon.perform_sex_action(target, 1, 3, TRUE)
	target.sexcon.handle_passive_ejaculation()

	var/obj/item/organ/breasts/breasts = target.get_visible_genital_organ(ORGAN_SLOT_BREASTS)
	var/milk_to_add = min(max(breasts.breast_size, 1), breasts.milk_stored)
	if(breasts.lactating && milk_to_add > 0 && prob(25))
		user.reagents.add_reagent(/datum/reagent/consumable/milk, milk_to_add)
		breasts.milk_stored -= milk_to_add
		to_chat(user, span_notice("I can taste milk."))
		to_chat(target, span_notice("I can feel milk leak from my buds."))

/datum/sex_action/suck_nipples/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] stops sucking [target]'s nipples ..."))

/datum/sex_action/suck_nipples/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE

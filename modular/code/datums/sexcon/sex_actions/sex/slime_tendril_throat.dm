/datum/sex_action/slime_tendril_throat
	name = "Let the slime invade their throat"
	check_same_tile = FALSE
	stamina_cost = 1.0
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_JAWS

/datum/sex_action/slime_tendril_throat/proc/get_target_tendril_jelly(mob/living/carbon/human/target)
	if(!target)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_mouth_jelly(target)
	if(jelly)
		return jelly
	for(var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly as anything in target.intimate_accessories)
		if(strange_jelly.active_cocoon?.inhabitant == target)
			return strange_jelly
	return null

/datum/sex_action/slime_tendril_throat/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	return !!get_target_tendril_jelly(target)

/datum/sex_action/slime_tendril_throat/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!get_target_tendril_jelly(target))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_throat/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		user.visible_message(span_warning("[user] teases the cocoon until its hungry tendrils find [target]'s throat!"))
		return
	user.visible_message(span_warning("[user] coaxes the slime at [target]'s lips into [target.p_their()] throat!"))

/datum/sex_action/slime_tendril_throat/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		message = strange_jelly.get_cocoon_action_flavor(target, user.sexcon)
		if(strange_jelly.active_cocoon?.inhabitant == target)
			strange_jelly.add_cocoon_cum(1)
	if(!message)
		message = "[user] [user.sexcon.get_generic_force_adjective()] works the slime deeper into [target]'s throat as it writhes and burrows inside [target.p_them()]."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target, TRUE)
	user.sexcon.oralcourse_noise(target)
	apply_silver_intimate_contact("mouth", target, user)

	user.sexcon.perform_sex_action(target, 1, 6, TRUE)
	if(!user.sexcon.considered_limp())
		user.sexcon.perform_deepthroat_oxyloss(target, 1.2)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_throat/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] leaves the slime to slip back out of [target]'s throat."))

/datum/sex_action/slime_tendril_throat/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE
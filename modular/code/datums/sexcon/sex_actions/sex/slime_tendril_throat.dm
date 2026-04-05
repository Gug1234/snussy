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
	var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = target.intimate_jelly
	if(istype(strange_jelly))
		return strange_jelly
	return null

/datum/sex_action/slime_tendril_throat/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return !!get_target_tendril_jelly(target)

/datum/sex_action/slime_tendril_throat/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!get_target_tendril_jelly(target))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_throat/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	var/self_target = (user == target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		if(self_target)
			user.visible_message(span_warning("[user] teases the cocoon until its hungry tendrils find [user.p_their()] own throat!"))
		else
			user.visible_message(span_warning("[user] teases the cocoon until its hungry tendrils find [target]'s throat!"))
		return
	if(self_target)
		user.visible_message(span_warning("[user] coaxes [user.p_their()] own slime past [user.p_their()] lips and into [user.p_their()] throat!"))
	else
		user.visible_message(span_warning("[user] coaxes the slime at [target]'s lips into [target.p_their()] throat!"))

/datum/sex_action/slime_tendril_throat/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			message = strange_jelly.get_cocoon_action_flavor("throat", target, user.sexcon)
			strange_jelly.add_cocoon_cum(1)
		else
			message = strange_jelly.get_tendril_action_flavor("throat", target, user.sexcon)
	if(!message)
		if(user == target)
			message = "[user] [user.sexcon.get_generic_force_adjective()] works the slime deeper into [user.p_their()] own throat, gagging as it burrows inside [user.p_them()]."
		else
			message = "[user] [user.sexcon.get_generic_force_adjective()] works the slime deeper into [target]'s throat as it writhes and burrows inside [target.p_them()]."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target, TRUE)
	user.sexcon.oralcourse_noise(target)
	apply_silver_intimate_contact("mouth", target, user)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly = jelly
		bond_jelly.advance_bond_from_sex()

	user.sexcon.perform_sex_action(target, 1, 6, TRUE)
	if(!user.sexcon.considered_limp())
		user.sexcon.perform_deepthroat_oxyloss(target, 1.2)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_throat/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		user.visible_message(span_warning("[user] lets the slime slip back out of [user.p_their()] own throat."))
	else
		user.visible_message(span_warning("[user] leaves the slime to slip back out of [target]'s throat."))

/datum/sex_action/slime_tendril_throat/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE

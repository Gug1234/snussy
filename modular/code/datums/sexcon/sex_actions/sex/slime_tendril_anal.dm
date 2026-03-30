/**
 * Jelly Anal Tendril Fuck
 * The user coaxes a rear-slot (or strange) jelly into driving a tendril into the target's rear.
 * Requires jelly in the target's rear slot, or any strange jelly capable of extending tendrils.
 */

/datum/sex_action/slime_tendril_anal
	name = "Let the slime invade their rear"
	check_same_tile = FALSE
	stamina_cost = 1.0
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_ANUS

/// Returns the jelly that will supply the anal tendril, or null if none is available.
/datum/sex_action/slime_tendril_anal/proc/get_target_tendril_jelly(mob/living/carbon/human/target)
	if(!target)
		return null
	// Rear-slot jelly is the primary source; strange jelly in any slot can also reach.
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_rear_jelly(target)
	if(jelly)
		return jelly
	for(var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly as anything in target.intimate_accessories)
		if(strange_jelly.active_cocoon?.inhabitant == target)
			return strange_jelly
	return null

/datum/sex_action/slime_tendril_anal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	return !!get_target_tendril_jelly(target)

/datum/sex_action/slime_tendril_anal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	if(!get_target_tendril_jelly(target))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_anal/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		user.visible_message(span_warning("[user] kneads the cocoon walls, urging its hungry tendrils toward [target]'s rear!"))
		return
	user.visible_message(span_warning("[user] coaxes the slime at [target]'s rear, urging it deeper inside [target.p_them()]!"))

/datum/sex_action/slime_tendril_anal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
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
		message = "[user] [user.sexcon.get_generic_force_adjective()] drives the slime's tendril deeper into [target]'s rear as it writhes and burrows inside [target.p_them()]."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target)
	apply_silver_intimate_contact("rear", target, user)

	user.sexcon.perform_sex_action(target, 1, 6, TRUE)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_anal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] lets the slime withdraw its tendril from [target]'s rear."))

/datum/sex_action/slime_tendril_anal/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


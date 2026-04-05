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
	// Rear-region jelly is the primary source; any strange jelly can also reach.
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_rear_jelly(target)
	if(jelly)
		return jelly
	// Fall back to the dedicated jelly slot — strange jelly can sprout tendrils from any region.
	var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = target.intimate_jelly
	if(istype(strange_jelly))
		return strange_jelly
	return null

/datum/sex_action/slime_tendril_anal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return !!get_target_tendril_jelly(target)

/datum/sex_action/slime_tendril_anal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	if(!get_target_tendril_jelly(target))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_anal/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	var/self_target = (user == target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		if(self_target)
			user.visible_message(span_warning("[user] kneads the cocoon walls, urging its hungry tendrils toward [user.p_their()] own rear!"))
		else
			user.visible_message(span_warning("[user] kneads the cocoon walls, urging its hungry tendrils toward [target]'s rear!"))
		return
	if(self_target)
		user.visible_message(span_warning("[user] coaxes [user.p_their()] own slime deeper into [user.p_their()] rear!"))
	else
		user.visible_message(span_warning("[user] coaxes the slime at [target]'s rear, urging it deeper inside [target.p_them()]!"))

/datum/sex_action/slime_tendril_anal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_target_tendril_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			message = strange_jelly.get_cocoon_action_flavor("anal", target, user.sexcon)
			strange_jelly.add_cocoon_cum(1)
		else
			message = strange_jelly.get_tendril_action_flavor("anal", target, user.sexcon)
	if(!message)
		if(user == target)
			message = "[user] [user.sexcon.get_generic_force_adjective()] drives the slime's tendril deeper into [user.p_their()] own rear, writhing as it burrows inside [user.p_them()]."
		else
			message = "[user] [user.sexcon.get_generic_force_adjective()] drives the slime's tendril deeper into [target]'s rear as it writhes and burrows inside [target.p_them()]."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target)
	apply_silver_intimate_contact("rear", target, user)
	// Advance bond from consensual interaction
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly = jelly
		bond_jelly.advance_bond_from_sex()

	user.sexcon.perform_sex_action(target, 1, 6, TRUE)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_anal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		user.visible_message(span_warning("[user] lets the slime withdraw its tendril from [user.p_their()] own rear."))
	else
		user.visible_message(span_warning("[user] lets the slime withdraw its tendril from [target]'s rear."))

/datum/sex_action/slime_tendril_anal/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


/**
 * Multi-Tendril Jelly Fuck
 * Simultaneous penetration of all available orifices. Requires either:
 *   - A Strange Jelly (Baothan Ooze) on the target — it can sprout multiple tendrils anywhere.
 *   - OR a mouth jelly PLUS a rear/genital jelly — two separate jellies working in concert.
 * Both the throat and groin must be accessible.
 */

/datum/sex_action/slime_tendril_multi
	name = "Let the slime fill every hole"
	check_same_tile = FALSE
	stamina_cost = 1.5
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_JAWS|SEX_PART_ANUS

/// Returns TRUE if the target has the jelly configuration needed for multi-tendril penetration.
/datum/sex_action/slime_tendril_multi/proc/has_multi_tendril_setup(mob/living/carbon/human/target)
	if(!target)
		return FALSE
	// Strange jelly can sprout several tendrils independently.
	if(istype(target.intimate_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		return TRUE
	// Otherwise needs a mouth jelly AND a rear-or-genital jelly simultaneously.
	if(!get_mouth_jelly(target))
		return FALSE
	return !!(get_rear_jelly(target) || get_genital_jelly(target))

/// Returns the primary jelly driving this action (for cocoon flavour lookup).
/datum/sex_action/slime_tendril_multi/proc/get_primary_jelly(mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = target.intimate_jelly
	if(istype(strange_jelly))
		return strange_jelly
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_rear_jelly(target)
	if(jelly)
		return jelly
	return get_mouth_jelly(target)

/datum/sex_action/slime_tendril_multi/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return has_multi_tendril_setup(target)

/datum/sex_action/slime_tendril_multi/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!has_multi_tendril_setup(target))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_multi/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_primary_jelly(target)
	var/self_target = (user == target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		if(self_target)
			user.visible_message(span_warning("[user] runs [user.p_their()] hands across the cocoon, coaxing it into filling [user.p_them()] completely with writhing tendrils!"))
		else
			user.visible_message(span_warning("[user] runs [user.p_their()] hands across the cocoon, coaxing it into filling [target] completely with writhing tendrils!"))
		return
	if(self_target)
		user.visible_message(span_warning("[user] coaxes [user.p_their()] own slime, urging it to fill every opening at once!"))
	else
		user.visible_message(span_warning("[user] coaxes the slime, urging it to fill every one of [target]'s openings at once!"))

/datum/sex_action/slime_tendril_multi/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_primary_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			message = strange_jelly.get_cocoon_action_flavor("multi", target, user.sexcon)
			strange_jelly.add_cocoon_cum(1)
		else
			message = strange_jelly.get_tendril_action_flavor("multi", target, user.sexcon)
	if(!message)
		if(user == target)
			message = "[user] [user.sexcon.get_generic_force_adjective()] urges the slime to drive its tendrils deeper — filled completely, [user.p_their()] throat and rear stuffed and writhing."
		else
			message = "[user] [user.sexcon.get_generic_force_adjective()] urges the slime to drive its tendrils deeper — [target] is filled completely, throat and rear stuffed and writhing."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target, TRUE)
	user.sexcon.oralcourse_noise(target)
	apply_silver_intimate_contact("mouth", target, user)
	apply_silver_intimate_contact("rear", target, user)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly = jelly
		bond_jelly.advance_bond_from_sex(2) // double for multi-penetration

	// Heavy dual-penetration arousal and pain; throat tendril causes oxyloss at higher force.
	user.sexcon.perform_sex_action(target, 2, 8, TRUE)
	if(!user.sexcon.considered_limp())
		user.sexcon.perform_deepthroat_oxyloss(target, 1.5)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_multi/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		user.visible_message(span_warning("[user] eases up, letting the slime retract its tendrils from [user.p_their()] throat and rear simultaneously."))
	else
		user.visible_message(span_warning("[user] eases up, letting the slime retract its tendrils from [target]'s throat and rear simultaneously."))

/datum/sex_action/slime_tendril_multi/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


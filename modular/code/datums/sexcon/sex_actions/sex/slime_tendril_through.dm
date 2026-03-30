/**
 * Jelly Tendril All-The-Way-Through
 * The tendril enters from the target's rear or groin and pushes upward until it
 * protrudes from their throat / mouth. Requires:
 *   - A rear-slot OR genital-slot jelly (the entry point).
 *   - Both the groin AND mouth zones must be accessible.
 *
 * Special on_finish: if the jelly (or the action itself) triggered an ejaculation,
 * the tendril expels fluid directly through the target's mouth — producing a unique
 * climax message before withdrawing.
 */

/datum/sex_action/slime_tendril_through
	name = "Have the slime go all the way through"
	check_same_tile = FALSE
	stamina_cost = 1.5
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_ANUS|SEX_PART_JAWS

/// Returns the entry-point jelly (rear > genital > strange), or null.
/datum/sex_action/slime_tendril_through/proc/get_entry_jelly(mob/living/carbon/human/target)
	if(!target)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_rear_jelly(target)
	if(jelly)
		return jelly
	jelly = get_genital_jelly(target)
	if(jelly)
		return jelly
	for(var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly as anything in target.intimate_accessories)
		return strange_jelly
	return null

/datum/sex_action/slime_tendril_through/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	return !!get_entry_jelly(target)

/datum/sex_action/slime_tendril_through/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_entry_jelly(target))
		return FALSE
	// Both the entry and exit zones must be unobstructed.
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_through/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_entry_jelly(target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		user.visible_message(span_warning("[user] kneads the cocoon beneath [target], urging its tendril upward — it will not stop until it finds [target]'s throat!"))
		return
	user.visible_message(span_warning("[user] coaxes the jelly into [target]'s rear, urging it onward and upward — a tendril begins its slow, inexorable journey through [target]."))

/datum/sex_action/slime_tendril_through/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_entry_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		message = strange_jelly.get_cocoon_action_flavor(target, user.sexcon)
		if(strange_jelly.active_cocoon?.inhabitant == target)
			strange_jelly.add_cocoon_cum(1)
	if(!message)
		message = "[user] [user.sexcon.get_generic_force_adjective()] urges the tendril further — [target] can feel it squirm through [target.p_their()] gut, pressing up into [target.p_their()] throat, tip just visible past [target.p_their()] lips."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target)
	user.sexcon.oralcourse_noise(target)
	apply_silver_intimate_contact("rear", target, user)
	apply_silver_intimate_contact("mouth", target, user)

	// Intense dual-zone penetration — high arousal, significant pain.
	user.sexcon.perform_sex_action(target, 1.5, 8, TRUE)
	// Throat occupation causes oxyloss scaled to force.
	user.sexcon.perform_deepthroat_oxyloss(target, 1.8)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_through/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	// Special ejaculation-through-mouth flavor when the jelly expels fluid on withdrawal.
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_entry_jelly(target)
	if(jelly && istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			user.visible_message(span_warning("As [user] coaxes the tendril back, the cocoon shudders — a gush of slick fluid erupts from [target]'s mouth as the tendril withdraws completely."))
			return
	// Standard finish message if the jelly did not produce the dramatic cum-through effect.
	user.visible_message(span_warning("[user] eases up, letting the tendril slip back the way it came — [target]'s throat and rear both twitch as it withdraws."))

/datum/sex_action/slime_tendril_through/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


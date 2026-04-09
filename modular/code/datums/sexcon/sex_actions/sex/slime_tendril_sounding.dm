/**
 * Jelly Tendril Urethral Sounding
 * A genital-slot (or strange) jelly extends a thin tendril into the target's urethra.
 * Requires:
 *   - A genital-slot jelly OR any strange jelly on the target.
 *   - Target must have a penis (ORGAN_SLOT_PENIS) that is NOT slit-type (no urethral opening).
 *
 * Effects per perform:
 *   - Very high pain, moderate arousal (same profile as the chastity sounding probe).
 *   - try_do_pain_scream fires each perform — the sensation is inescapably intense.
 */

/datum/sex_action/slime_tendril_sounding
	name = "Have the slime sound their urethra"
	check_same_tile = FALSE
	stamina_cost = 1.0
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_COCK

/// Returns the jelly that will supply the sounding tendril, or null if none available.
/datum/sex_action/slime_tendril_sounding/proc/get_sounding_jelly(mob/living/carbon/human/target)
	if(!target)
		return null
	// Genital-slot jelly is the primary source; any eora jelly in any slot can also reach.
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_genital_jelly(target)
	if(jelly)
		return jelly
	var/obj/item/intimate_accessory/jelly/eora/any_jelly = target.intimate_jelly
	if(istype(any_jelly))
		return any_jelly
	return null

/datum/sex_action/slime_tendril_sounding/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/organ/penis/cock = target.getorganslot(ORGAN_SLOT_PENIS)
	if(!cock)
		return FALSE
	// Slit-type penises have no discrete urethral opening to probe.
	if(cock.sheath_type == SHEATH_TYPE_SLIT)
		return FALSE
	return !!get_sounding_jelly(target)

/datum/sex_action/slime_tendril_sounding/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/organ/penis/cock = target.getorganslot(ORGAN_SLOT_PENIS)
	if(!cock)
		return FALSE
	if(cock.sheath_type == SHEATH_TYPE_SLIT)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	if(!get_sounding_jelly(target))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_sounding/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_sounding_jelly(target)
	var/self_target = (user == target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		if(self_target)
			user.visible_message(span_warning("[user] prods at the cocoon, coaxing it to thread a thin tendril into [user.p_their()] own urethral slit!"))
		else
			user.visible_message(span_warning("[user] prods at the cocoon, coaxing it to thread a thin tendril into [target]'s urethral slit!"))
		return
	if(self_target)
		user.visible_message(span_warning("[user] presses [user.p_their()] own slime close to [user.p_their()] tip, urging it to thin itself into a probing tendril!"))
	else
		user.visible_message(span_warning("[user] presses the slime close to [target]'s tip, urging it to thin itself into a probing tendril!"))

/datum/sex_action/slime_tendril_sounding/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_sounding_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			message = strange_jelly.get_cocoon_action_flavor("sounding", target, user.sexcon)
			strange_jelly.add_cocoon_cum(1)
		else
			message = strange_jelly.get_tendril_action_flavor("sounding", target, user.sexcon)
	if(!message)
		if(user == target)
			message = "[user] [user.sexcon.get_generic_force_adjective()] works the tendril deeper into [user.p_their()] own urethra — the sensation is overwhelming, burning and intimate all at once."
		else
			message = "[user] [user.sexcon.get_generic_force_adjective()] works the tendril deeper into [target]'s urethra — the sensation is overwhelming, burning and intimate all at once."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target)
	apply_silver_intimate_contact("genital", target, user)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly = jelly
		bond_jelly.advance_bond_from_sex()

	// High pain, modest arousal — urethral penetration is intense and sharp.
	user.sexcon.perform_sex_action(target, 0.6, 9.0, TRUE)
	user.sexcon.try_do_pain_scream(target, 9.0)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_sounding/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		user.visible_message(span_warning("[user] lets the slime withdraw its tendril from [user.p_their()] own urethra in one slow, relentless pull."))
	else
		user.visible_message(span_warning("[user] lets the slime withdraw its tendril from [target]'s urethra in one slow, relentless pull."))

/datum/sex_action/slime_tendril_sounding/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


/**
 * Jelly Tendril Asphyxiation
 * The user coaxes the jelly into wrapping its tendrils around the target's throat,
 * constricting their airway. Any Eoran Jelly on the target can reach the neck.
 * Oxyloss scales with force; higher force also inflicts pain.
 */

/datum/sex_action/slime_tendril_asphyxiation
	name = "Have the slime constrict their throat"
	check_same_tile = FALSE
	stamina_cost = 1.0
	category = SEX_CATEGORY_MISC

/datum/sex_action/slime_tendril_asphyxiation/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	return !!get_any_eora_jelly(target)

/datum/sex_action/slime_tendril_asphyxiation/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_any_eora_jelly(target))
		return FALSE
	// The head/throat must not be fully armoured or blocked.
	if(!check_location_accessible(user, target, BODY_ZONE_HEAD))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_asphyxiation/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_any_eora_jelly(target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		user.visible_message(span_warning("[user] squeezes the cocoon, urging it to tighten around [target]'s throat!"))
		return
	user.visible_message(span_warning("[user] coaxes the slime into sending a tendril snaking toward [target]'s throat!"))

/datum/sex_action/slime_tendril_asphyxiation/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_any_eora_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		message = strange_jelly.get_cocoon_action_flavor(target, user.sexcon)
	if(!message)
		message = "[user] [user.sexcon.get_generic_force_adjective()] urges the tendril tighter around [target]'s throat — [target.p_their()] breath comes in ragged, stolen gasps."

	user.visible_message(user.sexcon.spanify_force(message))

	// Oxyloss scales directly with force — this is the primary effect of the action.
	var/oxyloss = 0
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			oxyloss = 0.8
		if(SEX_FORCE_MID)
			oxyloss = 2.0
		if(SEX_FORCE_HIGH)
			oxyloss = 4.0
		if(SEX_FORCE_EXTREME)
			oxyloss = 7.0
	target.adjustOxyLoss(oxyloss)

	// Low arousal, moderate pain — constriction is primarily distressing, not pleasurable.
	user.sexcon.perform_sex_action(target, 0.3, 5, TRUE)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_asphyxiation/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] eases up, letting the slime loosen its grip on [target]'s throat."))

/datum/sex_action/slime_tendril_asphyxiation/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


/**
 * Jelly Tendril Ear Fuck
 * The jelly sends a tendril into the target's ears, producing a stupefying and invasive
 * sensation. Any Eoran Jelly can reach the ears.
 *
 * Effects per perform:
 *   - Applies / refreshes the Stupefied status effect (INT -2, 2 min).
 *   - HIGH force: chance to deal minor ear damage (ringing / partial deafness tick).
 *   - EXTREME force: guaranteed ear damage tick.
 *
 * Uses /mob/living/carbon/adjustEarDamage(ddmg, ddeaf) which proxies to the ear organ.
 */

/datum/sex_action/slime_tendril_ear
	name = "Have the slime invade their ears"
	check_same_tile = FALSE
	stamina_cost = 1.0
	category = SEX_CATEGORY_MISC

/datum/sex_action/slime_tendril_ear/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	return !!get_any_eora_jelly(target)

/datum/sex_action/slime_tendril_ear/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_any_eora_jelly(target))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_EARS))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_ear/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_any_eora_jelly(target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		user.visible_message(span_warning("[user] taps the cocoon beside [target]'s head, coaxing its tendrils toward [target.p_their()] ears!"))
		return
	user.visible_message(span_warning("[user] guides the slime toward [target]'s ears, urging a thin tendril inside!"))

/datum/sex_action/slime_tendril_ear/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_any_eora_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		message = strange_jelly.get_cocoon_action_flavor(target, user.sexcon)
	if(!message)
		message = "[user] [user.sexcon.get_generic_force_adjective()] urges the tendril deeper into [target]'s ears — [target] can feel it pulsing behind [target.p_their()] eyes."

	user.visible_message(user.sexcon.spanify_force(message))

	// The stupefying sensation clouds the target's thoughts. Refreshes each perform.
	target.apply_status_effect(/datum/status_effect/debuff/jelly_stupefied)
	to_chat(target, span_warning("Something pulses deep inside my skull..."))

	// Higher force risks damaging the ear canal.
	switch(user.sexcon.force)
		if(SEX_FORCE_HIGH)
			if(prob(35))
				target.adjustEarDamage(1, 2)
				to_chat(target, span_warning("The tendril presses further — a sharp ring tears through my ears!"))
		if(SEX_FORCE_EXTREME)
			target.adjustEarDamage(2, 4)
			to_chat(target, span_boldwarning("Something tears inside my ear — the ringing is unbearable!"))

	// Low arousal, mild pain — the sensation is disorienting more than erotic.
	user.sexcon.perform_sex_action(target, 0.3, 4, TRUE)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_ear/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] eases the slime back, its tendril withdrawing slowly from [target]'s ears."))

/datum/sex_action/slime_tendril_ear/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


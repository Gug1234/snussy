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
	return !!get_any_eora_jelly(target)

/datum/sex_action/slime_tendril_ear/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!get_any_eora_jelly(target))
		return FALSE
	// Ears are always accessible — no clothing blocks them and BODY_ZONE_PRECISE_EARS
	// has no entry in the get_accessible_body_zone bitfield system.
	return TRUE

/datum/sex_action/slime_tendril_ear/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_any_eora_jelly(target)
	var/self_target = (user == target)
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange) && target.loc == jelly:active_cocoon)
		if(self_target)
			user.visible_message(span_warning("[user] taps the cocoon beside [user.p_their()] own head, coaxing its tendrils toward [user.p_their()] ears!"))
		else
			user.visible_message(span_warning("[user] taps the cocoon beside [target]'s head, coaxing its tendrils toward [target.p_their()] ears!"))
		return
	if(self_target)
		user.visible_message(span_warning("[user] guides [user.p_their()] own slime toward [user.p_their()] ears, urging a thin tendril inside!"))
	else
		user.visible_message(span_warning("[user] guides the slime toward [target]'s ears, urging a thin tendril inside!"))

/datum/sex_action/slime_tendril_ear/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_any_eora_jelly(target)
	if(!jelly)
		return

	var/message = null
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			message = strange_jelly.get_cocoon_action_flavor("ear", target, user.sexcon)
		else
			message = strange_jelly.get_tendril_action_flavor("ear", target, user.sexcon)
	if(!message)
		if(user == target)
			message = "[user] [user.sexcon.get_generic_force_adjective()] urges the tendril deeper into [user.p_their()] own ears — [user.p_they(TRUE)] can feel it pulsing behind [user.p_their()] eyes."
		else
			message = "[user] [user.sexcon.get_generic_force_adjective()] urges the tendril deeper into [target]'s ears — [target] can feel it pulsing behind [target.p_their()] eyes."

	user.visible_message(user.sexcon.spanify_force(message))
	if(istype(jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly = jelly
		bond_jelly.advance_bond_from_sex()

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
	if(user == target)
		user.visible_message(span_warning("[user] eases the slime back, its tendril withdrawing slowly from [user.p_their()] own ears."))
	else
		user.visible_message(span_warning("[user] eases the slime back, its tendril withdrawing slowly from [target]'s ears."))

/datum/sex_action/slime_tendril_ear/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


/**
 * Jelly Tendril Oroboros Loop
 * Two participants, each bearing at least one Eoran Jelly, are joined in a closed loop:
 * user's tendril enters target while target's tendril enters user, forming an unbroken
 * circuit of squirming slime. Both parties suffer oxyloss and receive arousal every tick.
 *
 * Requirements:
 *   - Any Eoran Jelly on the USER (get_any_eora_jelly(user)).
 *   - Any Eoran Jelly on the TARGET (get_any_eora_jelly(target)).
 *   - Both groin zones must be accessible (the primary loop junction).
 *
 * Notes:
 *   - perform_sex_action is called twice — once via user.sexcon (affects target) and once
 *     via target.sexcon (affects user) — so both receive the arousal/pain calculation.
 *   - Oxyloss is applied directly to both via adjustOxyLoss, scaled to the user's current
 *     force tier (the initiator sets the pace for both).
 */

/datum/sex_action/slime_tendril_oroboros
	name = "Join the slimes in an oroboros loop"
	check_same_tile = FALSE
	stamina_cost = 2.0
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_ANUS|SEX_PART_COCK|SEX_PART_CUNT

/datum/sex_action/slime_tendril_oroboros/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_any_eora_jelly(user))
		return FALSE
	return !!get_any_eora_jelly(target)

/datum/sex_action/slime_tendril_oroboros/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!get_any_eora_jelly(user))
		return FALSE
	if(!get_any_eora_jelly(target))
		return FALSE
	// Both intimate zones must be reachable for the loop to close.
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN))
		return FALSE
	return TRUE

/datum/sex_action/slime_tendril_oroboros/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] presses close to [target], coaxing each jelly toward the other \u2014 the tendrils find each other and interlock, a living loop of writhing slime binding them together!"))

/datum/sex_action/slime_tendril_oroboros/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/user_jelly = get_any_eora_jelly(user)
	var/obj/item/intimate_accessory/jelly/eora/target_jelly = get_any_eora_jelly(target)
	if(!user_jelly || !target_jelly)
		return

	var/message = null
	// Strange jellies on the target produce cocoon flavour if they can.
	if(istype(target_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = target_jelly
		if(strange_jelly.active_cocoon?.inhabitant == target)
			message = strange_jelly.get_cocoon_action_flavor("through", target, user.sexcon)
			strange_jelly.add_cocoon_cum(1)
		else
			message = strange_jelly.get_tendril_action_flavor("through", target, user.sexcon)
	if(!message)
		message = "[user] and [target] are locked in a closed circuit of slime — each tendril drives deeper as the loop [user.sexcon.get_generic_force_adjective()] tightens around both of them."

	user.visible_message(user.sexcon.spanify_force(message))
	user.sexcon.intercourse_noise(target)
	apply_silver_intimate_contact("rear", target, user)
	apply_silver_intimate_contact("rear", user, target)
	// Advance bond on both jellies if applicable
	if(istype(target_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly = target_jelly
		bond_jelly.advance_bond_from_sex(2)
	if(istype(user_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/bond_jelly2 = user_jelly
		bond_jelly2.advance_bond_from_sex(2)

	// Oxyloss for both: the loop constricts airways as it tightens.
	var/oxyloss = 0
	switch(user.sexcon.force)
		if(SEX_FORCE_LOW)
			oxyloss = 0.5
		if(SEX_FORCE_MID)
			oxyloss = 1.5
		if(SEX_FORCE_HIGH)
			oxyloss = 3.0
		if(SEX_FORCE_EXTREME)
			oxyloss = 5.0
	user.adjustOxyLoss(oxyloss)
	target.adjustOxyLoss(oxyloss)

	// Arousal and pain applied symmetrically to both participants.
	user.sexcon.perform_sex_action(target, 1.2, 5, TRUE)
	target.sexcon.perform_sex_action(user, 1.2, 5, FALSE)
	user.sexcon.handle_passive_ejaculation()
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/slime_tendril_oroboros/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] and [target] disengage as the tendrils unweave from each other, the loop dissolving with a wet, reluctant shudder."))

/datum/sex_action/slime_tendril_oroboros/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check())
		return TRUE
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE


// Lets a mind imprint itself as the controlling master of a cursed chastity device.
/obj/item/chastity/cursed/attack_self(mob/user)
	if(!user?.mind)
		return
	if(tgui_alert(user, "Become the master of this device?", "[src]", list("Yes", "No")) != "Yes")
		return
	var/datum/component/collar_master/CM = user.mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		user.mind.AddComponent(/datum/component/collar_master)
	chastity_master = user.mind
	to_chat(user, span_userdanger(pick_chastity_string("chastity_cursed_messages.json", "chastity_imprint")))
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		log_chastity_command(H, user.mind, CHASTITY_LOG_IMPRINT, "device=[src]")

// Returns the controlling collar-master component for cursed chastity bindings, if available.
/obj/item/chastity/proc/get_cursed_master_component()
	if(!chastity_cursed || !chastity_master)
		return null
	return chastity_master.GetComponent(/datum/component/collar_master)

/obj/item/chastity/proc/record_nonself_ejaculation(mob/living/carbon/human/source, mob/living/carbon/human/wearer)
	if(!chastity_cursed)
		return FALSE
	if(!source || !wearer)
		return FALSE
	if(source == wearer)
		return FALSE
	if(loc != wearer)
		return FALSE
	if(wearer.chastity_device != src)
		return FALSE

	var/added = get_tally_increment_for_source(source)
	received_cum_count += added
	var/tally_msg = added == 1 ? "A metal scraping sound is briefly heard, a tally mark suddenly appears on [wearer]'s chastity device." : "A metal scraping sound is briefly heard, two tally marks suddenly appear on [wearer]'s chastity device."
	for(var/mob/M in viewers(1, wearer))
		to_chat(M, span_notice(tally_msg))
	return TRUE

/obj/item/chastity/proc/get_tally_increment_for_source(mob/living/carbon/human/source)
	return tally_increment_for_ejaculation_source(source)

/obj/item/chastity/proc/reset_received_cum_count()
	received_cum_count = 0

// Releases cursed collar-master ownership without relying on a global master scan.
/obj/item/chastity/proc/cleanup_cursed_binding(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE

	reset_received_cum_count()

	SEND_SIGNAL(H, COMSIG_CARBON_LOSE_CHASTITY, src)

	var/datum/component/collar_master/CM = get_cursed_master_component()
	if(CM)
		if(H in CM.registered_pets)
			CM.remove_pet(H)
		else if(H in CM.my_pets)
			CM.cleanup_pet(H)
		else
			// Defensive: wearer wasn't in either tracked list (unusual state),
			// but still may have stale signal handlers from a prior add_pet.
			// Explicitly unregister to avoid leaking handlers into later life.
			CM.cleanup_pet_signals(H)

	if(chastity_gilded)
		REMOVE_TRAIT(H, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
		gilded_limped = FALSE
	REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	return TRUE

// Rebuilds cursed trait state from current cursed toggles (front mode, anal mode, spikes, lock).
/obj/item/chastity/proc/apply_cursed_state(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE

	REMOVE_TRAIT(H, TRAIT_CHASTITY_FULL, TRAIT_SOURCE_CHASTITY)
	REMOVE_TRAIT(H, TRAIT_CHASTITY_CAGE, TRAIT_SOURCE_CHASTITY)
	REMOVE_TRAIT(H, TRAIT_CHASTITY_PENIS_BLOCKED, TRAIT_SOURCE_CHASTITY)
	REMOVE_TRAIT(H, TRAIT_CHASTITY_VAGINA_BLOCKED, TRAIT_SOURCE_CHASTITY)
	REMOVE_TRAIT(H, TRAIT_CHASTITY_ANAL, TRAIT_SOURCE_CHASTITY)
	REMOVE_TRAIT(H, TRAIT_CHASTITY_SPIKED, TRAIT_SOURCE_CHASTITY)
	REMOVE_TRAIT(H, TRAIT_CHASTITY_LOCKED, TRAIT_SOURCE_CHASTITY)

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)

	// Mode 1 opens penis, mode 3 opens all front access.
	if(!(cursed_front_mode == 1 || cursed_front_mode == 3) && has_penis)
		ADD_TRAIT(H, TRAIT_CHASTITY_PENIS_BLOCKED, TRAIT_SOURCE_CHASTITY)
		ADD_TRAIT(H, TRAIT_CHASTITY_CAGE, TRAIT_SOURCE_CHASTITY)
	// Mode 2 opens vagina, mode 3 opens all front access.
	if(!(cursed_front_mode == 2 || cursed_front_mode == 3) && has_vagina)
		ADD_TRAIT(H, TRAIT_CHASTITY_VAGINA_BLOCKED, TRAIT_SOURCE_CHASTITY)

	if(!cursed_anal_open)
		ADD_TRAIT(H, TRAIT_CHASTITY_ANAL, TRAIT_SOURCE_CHASTITY)
	if(cursed_spikes_on)
		ADD_TRAIT(H, TRAIT_CHASTITY_SPIKED, TRAIT_SOURCE_CHASTITY)
	if(locked)
		ADD_TRAIT(H, TRAIT_CHASTITY_LOCKED, TRAIT_SOURCE_CHASTITY)

	notify_chastity_state_change(H, "cursed_state_applied")

	return TRUE

// Updates cursed worn sprite accessory presentation to match open/closed front state.
// The physical item's icon stays fixed; only bodypart-feature overlays should change.
/obj/item/chastity/proc/update_cursed_visual(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)
	var/is_open_front = FALSE

	if(has_penis && has_vagina)
		is_open_front = (cursed_front_mode != 0)
	else if(has_penis)
		is_open_front = (cursed_front_mode == 1)
	else if(has_vagina)
		is_open_front = (cursed_front_mode == 2)

	icon_state = initial(icon_state)
	mob_overlay_icon = initial(mob_overlay_icon)

	// Keep bodypart-feature rendering in sync with open/closed cursed states and flat/standard style.
	var/new_sprite_acc
	if(chastity_gilded)
		if(has_penis && has_vagina)
			new_sprite_acc = /datum/sprite_accessory/chastity/intersex
		else if(has_penis)
			new_sprite_acc = chastity_flat ? /datum/sprite_accessory/chastity/flat : /datum/sprite_accessory/chastity/cage
		else
			new_sprite_acc = /datum/sprite_accessory/chastity/full
	else if(has_penis && has_vagina)
		new_sprite_acc = is_open_front ? /datum/sprite_accessory/chastity/intersex : /datum/sprite_accessory/chastity/cursed_intersex
	else if(has_penis)
		if(chastity_flat)
			new_sprite_acc = is_open_front ? /datum/sprite_accessory/chastity/flat : /datum/sprite_accessory/chastity/cursed_flat
		else
			new_sprite_acc = is_open_front ? /datum/sprite_accessory/chastity/cage : /datum/sprite_accessory/chastity/cursed_cage
	else
		new_sprite_acc = is_open_front ? /datum/sprite_accessory/chastity/full : /datum/sprite_accessory/chastity/cursed_belt

	sprite_acc = new_sprite_acc
	if(chastity_feature)
		chastity_feature.accessory_type = new_sprite_acc

	// Force a visual refresh so genital sprites become visible when an opening is exposed.
	H.update_body()
	H.update_body_parts(TRUE)

	return TRUE

/obj/item/chastity/proc/get_cursed_front_state_name(mob/living/carbon/human/H)
	if(!H)
		return "SEALED"

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)
	var/state_name = "SEALED"

	if(has_penis && has_vagina)
		state_name = "ALL SEALED"
		switch(cursed_front_mode)
			if(1)
				state_name = "PENIS OPEN"
			if(2)
				state_name = "VAGINA OPEN"
			if(3)
				state_name = "ALL OPEN"
	else if(has_penis)
		state_name = (cursed_front_mode == 1) ? "PENIS OPEN" : "SEALED"
	else if(has_vagina)
		state_name = (cursed_front_mode == 2) ? "VAGINA OPEN" : "SEALED"

	return state_name

/obj/item/chastity/proc/log_cursed_chastity_command(mob/living/carbon/human/H, log_type, details = "")
	if(!H)
		return
	log_chastity_command(H, chastity_master, log_type, details, chastity_master && chastity_master != H.mind)

/obj/item/chastity/proc/get_gilded_recipient_label()
	switch(gilded_recipient)
		if(GILDED_CHASTITY_RECIPIENT_MASTER)
			return "master"
		if(GILDED_CHASTITY_RECIPIENT_TREASURY)
			return "Keep Treasury"
		if(GILDED_CHASTITY_RECIPIENT_HOARDMASTER)
			return "Bandit Hoardmaster"
	return "unknown"

/obj/item/chastity/proc/set_gilded_recipient(mob/living/carbon/human/H, recipient)
	if(!chastity_gilded || !H)
		return FALSE
	if(!is_valid_gilded_chastity_recipient(recipient))
		return FALSE
	if(recipient == GILDED_CHASTITY_RECIPIENT_MASTER && chastity_master?.current == H)
		recipient = GILDED_CHASTITY_RECIPIENT_TREASURY
	gilded_recipient = recipient
	to_chat(H, span_notice("The gilded device warms as its coinage link turns toward [get_gilded_recipient_label()]."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_RECIPIENT, "recipient=[gilded_recipient]")
	return TRUE

/obj/item/chastity/proc/set_gilded_drain_amount(mob/living/carbon/human/H, amount)
	if(!chastity_gilded || !H)
		return FALSE
	gilded_drain_amount = clamp(round(text2num("[amount]")), GILDED_CHASTITY_MIN_DRAIN, GILDED_CHASTITY_MAX_DRAIN)
	to_chat(H, span_notice("The gilded device clicks to [gilded_drain_amount] mammon per orgasm."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_DRAIN, "amount=[gilded_drain_amount]")
	return TRUE

/obj/item/chastity/proc/force_gilded_payment(mob/living/carbon/human/H)
	if(!can_gilded_drain_wearer(H))
		return FALSE
	drain_gilded_nervelock(H, TRUE)
	return TRUE

/obj/item/chastity/proc/set_gilded_impotence(mob/living/carbon/human/H, should_enable)
	if(!chastity_gilded || !H)
		return FALSE
	if(!H.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	var/enabled = !!text2num("[should_enable]")
	if(enabled)
		if(!HAS_TRAIT_FROM(H, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE))
			ADD_TRAIT(H, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
		gilded_limped = TRUE
		to_chat(H, span_userdanger("The gilded cage drinks the strength from my cock, leaving me limp at my master's whim."))
	else
		if(HAS_TRAIT_FROM(H, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE))
			REMOVE_TRAIT(H, TRAIT_LIMPDICK, GILDED_CHASTITY_TRAIT_SOURCE)
		gilded_limped = FALSE
		to_chat(H, span_notice("The gilded cage loosens its curse, letting my body answer again."))
	H.sexcon?.update_erect_state()
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_IMPOTENCE, "enabled=[enabled]")
	return TRUE

/proc/is_valid_gilded_chastity_overdraw_effect(effect)
	return effect in list(
		GILDED_CHASTITY_OVERDRAW_SHRINK,
		GILDED_CHASTITY_OVERDRAW_PAIN,
		GILDED_CHASTITY_OVERDRAW_STRIP
	)

/proc/is_valid_gilded_chastity_forced_message_kind(kind)
	return kind in list(
		GILDED_CHASTITY_FORCED_MESSAGE_SAY,
		GILDED_CHASTITY_FORCED_MESSAGE_ME
	)

/obj/item/chastity/proc/get_gilded_overdraw_effect_label()
	switch(gilded_overdraw_effect)
		if(GILDED_CHASTITY_OVERDRAW_PAIN)
			return "pain"
		if(GILDED_CHASTITY_OVERDRAW_STRIP)
			return "strip"
	return "shrink"

/obj/item/chastity/proc/set_gilded_overdraw_effect(mob/living/carbon/human/H, effect)
	if(!chastity_gilded || !H)
		return FALSE
	if(!is_valid_gilded_chastity_overdraw_effect(effect))
		return FALSE
	gilded_overdraw_effect = effect
	to_chat(H, span_notice("The gilded device clicks; overdrawn Nervelocks will answer with [get_gilded_overdraw_effect_label()]."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_OVERDRAW_EFFECT, "effect=[gilded_overdraw_effect]")
	return TRUE

/obj/item/chastity/proc/ensure_gilded_forced_messages()
	if(!islist(gilded_forced_messages))
		gilded_forced_messages = list()
	return gilded_forced_messages

/obj/item/chastity/proc/get_configured_gilded_forced_messages()
	var/list/messages = ensure_gilded_forced_messages()
	var/list/configured_messages = list()
	var/message_count = min(length(messages), GILDED_CHASTITY_MAX_FORCED_MESSAGES)
	if(message_count <= 0)
		return configured_messages
	for(var/i in 1 to message_count)
		var/list/entry = messages[i]
		if(!islist(entry))
			continue
		var/kind = entry["kind"]
		var/message = entry["message"]
		if(!is_valid_gilded_chastity_forced_message_kind(kind) || !istext(message) || !length(message))
			continue
		configured_messages += list(list(
			"kind" = kind,
			"message" = message
		))
	return configured_messages

/obj/item/chastity/proc/get_gilded_forced_message_ui_data()
	var/list/messages = ensure_gilded_forced_messages()
	var/list/ui_messages = list()
	for(var/i in 1 to GILDED_CHASTITY_MAX_FORCED_MESSAGES)
		var/kind = GILDED_CHASTITY_FORCED_MESSAGE_SAY
		var/message = ""
		if(i <= length(messages))
			var/list/entry = messages[i]
			if(islist(entry))
				if(is_valid_gilded_chastity_forced_message_kind(entry["kind"]))
					kind = entry["kind"]
				if(istext(entry["message"]))
					message = entry["message"]
		ui_messages += list(list(
			"kind" = kind,
			"message" = message
		))
	return ui_messages

/obj/item/chastity/proc/set_gilded_forced_message_enabled(mob/living/carbon/human/H, should_enable)
	if(!chastity_gilded || !H)
		return FALSE
	gilded_forced_message_enabled = !!text2num("[should_enable]")
	to_chat(H, span_notice("The gilded device [gilded_forced_message_enabled ? "will now" : "will no longer"] force a message from empty Nervelock punishments."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_FORCED_MESSAGE, "enabled=[gilded_forced_message_enabled]")
	return TRUE

/obj/item/chastity/proc/set_gilded_forced_message(mob/living/carbon/human/H, index, kind, message)
	if(!chastity_gilded || !H)
		return FALSE
	var/message_index = round(text2num("[index]"))
	if(message_index < 1 || message_index > GILDED_CHASTITY_MAX_FORCED_MESSAGES)
		return FALSE
	kind = "[kind]"
	if(!is_valid_gilded_chastity_forced_message_kind(kind))
		return FALSE
	var/message_text = trim(copytext_char(sanitize("[message]"), 1, MAX_MESSAGE_LEN))
	var/list/messages = ensure_gilded_forced_messages()
	if(length(messages) < message_index)
		messages.len = message_index
	if(!length(message_text))
		messages[message_index] = null
		to_chat(H, span_notice("The gilded device clears forced message [message_index]."))
		log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_FORCED_MESSAGE, "index=[message_index] cleared=TRUE")
		return TRUE
	messages[message_index] = list(
		"kind" = kind,
		"message" = message_text
	)
	to_chat(H, span_notice("The gilded device remembers forced [kind == GILDED_CHASTITY_FORCED_MESSAGE_ME ? "/me" : "/say"] message [message_index]."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_FORCED_MESSAGE, "index=[message_index] kind=[kind]")
	return TRUE

/obj/item/chastity/proc/credit_gilded_master(mob/living/carbon/human/wearer, amount)
	if(amount <= 0)
		return FALSE
	var/mob/living/carbon/human/master = chastity_master?.current
	if(!istype(master))
		return credit_gilded_treasury(wearer, amount, TRUE)
	if(master == wearer)
		return credit_gilded_treasury(wearer, amount, TRUE)
	if(!(master in SStreasury.bank_accounts))
		SStreasury.bank_accounts[master] = 0
	SStreasury.bank_accounts[master] += amount
	SStreasury.log_to_steward("+[amount] gilded chastity drain from [wearer?.real_name || "unknown"] to [master.real_name]")
	return TRUE

/obj/item/chastity/proc/credit_gilded_treasury(mob/living/carbon/human/wearer, amount, master_fallback = FALSE)
	if(amount <= 0)
		return FALSE
	var/source = master_fallback ? "Gilded Chastity fallback from [wearer?.real_name || "unknown"]" : "Gilded Chastity from [wearer?.real_name || "unknown"]"
	SStreasury.give_money_treasury(amount, source)
	return TRUE

/obj/item/chastity/proc/credit_gilded_hoardmaster(mob/living/carbon/human/wearer, amount)
	if(amount <= 0)
		return FALSE
	if(SSmapping?.retainer)
		SSmapping.retainer.bandit_contribute += amount
	for(var/mob/player in GLOB.player_list)
		if(!player.mind)
			continue
		var/datum/antagonist/bandit/bandit_player = player.mind.has_antag_datum(/datum/antagonist/bandit)
		if(!bandit_player)
			continue
		bandit_player.favor += amount
		bandit_player.totaldonated += amount
		to_chat(player, "<font color='yellow'>A gilded chastity tithe from [wearer?.real_name || "someone"] reaches the Hoardmaster. You now have [bandit_player.favor] favor.</font>")
	record_round_statistic(STATS_SHRINE_VALUE, amount)
	SStreasury.log_to_steward("+[amount] gilded chastity drain from [wearer?.real_name || "unknown"] to the Bandit Hoardmaster")
	return TRUE

/obj/item/chastity/proc/credit_gilded_recipient(mob/living/carbon/human/wearer, amount)
	switch(gilded_recipient)
		if(GILDED_CHASTITY_RECIPIENT_MASTER)
			return credit_gilded_master(wearer, amount)
		if(GILDED_CHASTITY_RECIPIENT_TREASURY)
			return credit_gilded_treasury(wearer, amount)
		if(GILDED_CHASTITY_RECIPIENT_HOARDMASTER)
			return credit_gilded_hoardmaster(wearer, amount)
	return credit_gilded_master(wearer, amount)

/obj/item/chastity/proc/apply_gilded_shrink(mob/living/carbon/human/H, silent = FALSE)
	if(!chastity_gilded || !H)
		return FALSE
	var/obj/item/organ/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		return FALSE
	if(penis.penis_size <= MIN_PENIS_SIZE)
		if(!silent)
			to_chat(H, span_warning("The gilded cage tightens, but there is nowhere left for it to take from you."))
			log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_SHRINK, "changed=FALSE size=[penis.penis_size]")
		return FALSE
	penis.penis_size = max(MIN_PENIS_SIZE, penis.penis_size - 1)
	H.update_body_parts(TRUE)
	H.sexcon?.update_erect_state()
	if(!silent)
		H.visible_message(span_warning("[H]'s gilded chastity device constricts with a cruel metallic whine."), span_userdanger("The gilded cage constricts around me, stealing size with merciless pressure."))
		playsound(H, 'sound/items/garrote.ogg', 50, TRUE)
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_SHRINK, "changed=TRUE size=[penis.penis_size]")
	return TRUE

/obj/item/chastity/proc/apply_gilded_drain_milestones(mob/living/carbon/human/H)
	if(!chastity_gilded || !H)
		return FALSE
	var/handled = FALSE
	while(gilded_total_drained >= gilded_next_shrink_threshold)
		apply_gilded_shrink(H)
		gilded_next_shrink_threshold += GILDED_CHASTITY_SHRINK_DRAIN_STEP
		handled = TRUE
	return handled

/obj/item/chastity/proc/apply_gilded_overdraw_effect(mob/living/carbon/human/H)
	if(!chastity_gilded || !H)
		return FALSE
	gilded_zero_fund_orgasms++
	var/effect_handled = FALSE
	switch(gilded_overdraw_effect)
		if(GILDED_CHASTITY_OVERDRAW_PAIN)
			effect_handled = apply_gilded_pain(H)
		if(GILDED_CHASTITY_OVERDRAW_STRIP)
			effect_handled = apply_gilded_strip(H)
		else
			effect_handled = apply_gilded_shrink(H)
	var/message_handled = apply_gilded_forced_message(H)
	return effect_handled || message_handled

/obj/item/chastity/proc/apply_gilded_pain(mob/living/carbon/human/H)
	if(!chastity_gilded || !H)
		return FALSE
	if(!H.sexcon)
		H.sexcon = new /datum/sex_controller(H)
	H.sexcon.receive_sex_action(0, PAIN_MED_EFFECT, FALSE, SEX_FORCE_MID, SEX_SPEED_MID)
	to_chat(H, span_userdanger("The gilded device twists into a precise burst of pain."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_PAIN)
	return TRUE

/obj/item/chastity/proc/apply_gilded_strip(mob/living/carbon/human/H)
	if(!chastity_gilded || !H)
		return FALSE
	var/removed_anything = FALSE
	H.drop_all_held_items()
	for(var/obj/item/I in H.get_equipped_items())
		if(istype(I, /obj/item/chastity))
			continue
		if(HAS_TRAIT(I, TRAIT_NODROP))
			continue
		if(I.item_flags & ABSTRACT)
			continue
		if(I.slot_flags & ITEM_SLOT_NECK)
			continue
		if(H.dropItemToGround(I, TRUE))
			removed_anything = TRUE
	if(removed_anything)
		to_chat(H, span_userdanger("The gilded device bites into me and forces my hands to tear away my clothing."))
		H.visible_message(span_warning("[H]'s gilded chastity device rings sharply as they strip in a forced panic."))
		playsound(H, 'sound/misc/vampirespell.ogg', 50, TRUE)
	else
		to_chat(H, span_warning("The gilded device tugs for clothing to strip away, but finds nothing it can force loose."))
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_STRIP, "changed=[removed_anything]")
	return removed_anything

/obj/item/chastity/proc/apply_gilded_forced_message(mob/living/carbon/human/H)
	if(!chastity_gilded || !H)
		return FALSE
	if(!gilded_forced_message_enabled)
		return FALSE
	var/list/messages = get_configured_gilded_forced_messages()
	if(!length(messages))
		return FALSE
	var/list/entry = pick(messages)
	var/kind = entry["kind"]
	var/message = entry["message"]
	if(!is_valid_gilded_chastity_forced_message_kind(kind) || !istext(message) || !length(message))
		return FALSE
	to_chat(H, span_userdanger("The gilded cage seizes my voice and forces out my master's words."))
	if(kind == GILDED_CHASTITY_FORCED_MESSAGE_ME)
		if(!run_gilded_forced_me(H, message))
			return FALSE
	else
		H.say(message, forced = "gilded chastity")
	if(!H.is_shifted)
		H.do_jitter_animation(10)
	playsound(H, 'sound/misc/vampirespell.ogg', 50, TRUE)
	log_cursed_chastity_command(H, CHASTITY_LOG_GILDED_FORCED_MESSAGE, "kind=[kind]")
	return TRUE

/obj/item/chastity/proc/run_gilded_forced_me(mob/living/carbon/human/H, message)
	if(!H || !istext(message) || !length(message))
		return FALSE
	var/list/custom_emotes = GLOB.emote_list["me"]
	for(var/datum/emote/emote_datum in custom_emotes)
		if(emote_datum.run_emote(H, message, EMOTE_VISIBLE, TRUE))
			return TRUE
	return FALSE

// Plays the most appropriate front-state transition sound for cursed devices.
/obj/item/chastity/proc/play_cursed_front_mode_change_sound(mob/living/carbon/human/H, old_mode, new_mode)
	if(!H)
		return FALSE

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)
	var/was_penis_open = has_penis && (old_mode == 1 || old_mode == 3)
	var/is_penis_open = has_penis && (new_mode == 1 || new_mode == 3)
	var/was_vagina_open = has_vagina && (old_mode == 2 || old_mode == 3)
	var/is_vagina_open = has_vagina && (new_mode == 2 || new_mode == 3)

	if((was_penis_open && !is_penis_open) || (was_vagina_open && !is_vagina_open))
		playsound(H, 'sound/foley/doors/windowdown.ogg', 50, TRUE)
		return TRUE

	if(!was_vagina_open && is_vagina_open && (was_penis_open == is_penis_open))
		playsound(H, 'sound/foley/doors/windowup.ogg', 50, TRUE)
		return TRUE

	if((!was_penis_open && is_penis_open) || (!was_vagina_open && is_vagina_open))
		playsound(H, pick('sound/foley/equip/swordlarge1.ogg', 'sound/foley/equip/swordlarge2.ogg'), 50, TRUE)
		return TRUE

	return FALSE

// Toggles cursed lock state and reapplies cursed trait effects.
/obj/item/chastity/proc/toggle_cursed_lock(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE
	locked = !locked
	apply_cursed_state(H)
	playsound(H, locked ? 'sound/foley/doors/lock.ogg' : 'sound/foley/doors/unlock.ogg', 50, TRUE)
	to_chat(H, locked ? span_warning(pick_chastity_string("chastity_lock_messages.json", "chastity_remote_lock")) : span_notice(pick_chastity_string("chastity_lock_messages.json", "chastity_remote_unlock")))
	log_cursed_chastity_command(H, CHASTITY_LOG_LOCK, "locked=[locked]")
	return TRUE

// Sets cursed lock state directly to avoid repeated cycle/toggle interactions in UI.
/obj/item/chastity/proc/set_cursed_lock(mob/living/carbon/human/H, should_lock)
	if(!chastity_cursed || !H)
		return FALSE
	var/new_state = !!should_lock
	if(locked == new_state)
		log_cursed_chastity_command(H, CHASTITY_LOG_LOCK, "locked=[locked] changed=FALSE")
		return TRUE
	locked = new_state
	apply_cursed_state(H)
	playsound(H, locked ? 'sound/foley/doors/lock.ogg' : 'sound/foley/doors/unlock.ogg', 50, TRUE)
	to_chat(H, locked ? span_warning(pick_chastity_string("chastity_lock_messages.json", "chastity_remote_lock")) : span_notice(pick_chastity_string("chastity_lock_messages.json", "chastity_remote_unlock")))
	log_cursed_chastity_command(H, CHASTITY_LOG_LOCK, "locked=[locked] changed=TRUE")
	return TRUE

// Cycles cursed front access modes valid for the wearer's current anatomy.
/obj/item/chastity/proc/cycle_cursed_front_mode(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)
	var/list/valid_modes = list(0)

	if(has_penis)
		valid_modes += 1
	if(has_vagina)
		valid_modes += 2
	if(has_penis && has_vagina)
		valid_modes += 3

	var/current_index = valid_modes.Find(cursed_front_mode)
	if(!current_index)
		current_index = 1

	var/old_mode = cursed_front_mode
	var/next_index = (current_index % length(valid_modes)) + 1
	cursed_front_mode = valid_modes[next_index]

	apply_cursed_state(H)
	play_cursed_front_mode_change_sound(H, old_mode, cursed_front_mode)

	var/state_name = get_cursed_front_state_name(H)

	to_chat(H, span_notice(replacetext(pick_chastity_string("chastity_cursed_messages.json", "chastity_front_shift"), "%STATE%", state_name)))
	// Atmospheric wearer reaction on major front state transitions (sealed <-> any-open)
	if(old_mode == 0 && cursed_front_mode > 0)
		to_chat(H, span_notice(pick_chastity_string("chastity_mode_messages.json", "chastity_front_open")))
	else if(old_mode > 0 && cursed_front_mode == 0)
		to_chat(H, span_warning(pick_chastity_string("chastity_mode_messages.json", "chastity_front_close")))
	log_cursed_chastity_command(H, CHASTITY_LOG_FRONT, "mode=[cursed_front_mode] state=[state_name]")
	return TRUE

// Sets cursed front mode directly. Invalid/unsupported values are clamped to a valid mode.
/obj/item/chastity/proc/set_cursed_front_mode(mob/living/carbon/human/H, mode)
	if(!chastity_cursed || !H)
		return FALSE

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)
	var/list/valid_modes = list(0)
	if(has_penis)
		valid_modes += 1
	if(has_vagina)
		valid_modes += 2
	if(has_penis && has_vagina)
		valid_modes += 3

	var/new_mode = clamp(text2num("[mode]"), 0, 3)
	if(!(new_mode in valid_modes))
		new_mode = valid_modes[1]

	if(cursed_front_mode == new_mode)
		var/state_name = get_cursed_front_state_name(H)
		log_cursed_chastity_command(H, CHASTITY_LOG_FRONT, "mode=[cursed_front_mode] state=[state_name] changed=FALSE")
		return TRUE

	var/old_mode = cursed_front_mode
	cursed_front_mode = new_mode
	apply_cursed_state(H)
	play_cursed_front_mode_change_sound(H, old_mode, new_mode)

	var/state_name = get_cursed_front_state_name(H)

	to_chat(H, span_notice(replacetext(pick_chastity_string("chastity_cursed_messages.json", "chastity_front_shift"), "%STATE%", state_name)))
	// Atmospheric wearer reaction on major front state transitions (sealed <-> any-open)
	if(old_mode == 0 && cursed_front_mode > 0)
		to_chat(H, span_notice(pick_chastity_string("chastity_mode_messages.json", "chastity_front_open")))
	else if(old_mode > 0 && cursed_front_mode == 0)
		to_chat(H, span_warning(pick_chastity_string("chastity_mode_messages.json", "chastity_front_close")))
	log_cursed_chastity_command(H, CHASTITY_LOG_FRONT, "mode=[cursed_front_mode] state=[state_name] changed=TRUE")
	return TRUE

// Toggles whether anal access is sealed or open on cursed devices.
/obj/item/chastity/proc/toggle_cursed_anal_open(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE
	cursed_anal_open = !cursed_anal_open
	apply_cursed_state(H)
	playsound(H, cursed_anal_open ? 'sound/items/uncork.ogg' : 'sound/misc/mat/pop.ogg', 50, TRUE)
	to_chat(H, cursed_anal_open ? span_notice(pick_chastity_string("chastity_cursed_messages.json", "chastity_anal_open")) : span_warning(pick_chastity_string("chastity_cursed_messages.json", "chastity_anal_closed")))
	// Atmospheric wearer reaction to rear shield state change
	to_chat(H, cursed_anal_open ? span_notice(pick_chastity_string("chastity_mode_messages.json", "chastity_rear_open")) : span_warning(pick_chastity_string("chastity_mode_messages.json", "chastity_rear_close")))
	log_cursed_chastity_command(H, CHASTITY_LOG_ANAL, "open=[cursed_anal_open]")
	return TRUE

// Sets cursed anal access directly for one-click UI controls.
/obj/item/chastity/proc/set_cursed_anal_open(mob/living/carbon/human/H, should_open)
	if(!chastity_cursed || !H)
		return FALSE
	var/new_state = !!should_open
	if(cursed_anal_open == new_state)
		log_cursed_chastity_command(H, CHASTITY_LOG_ANAL, "open=[cursed_anal_open] changed=FALSE")
		return TRUE
	cursed_anal_open = new_state
	apply_cursed_state(H)
	playsound(H, cursed_anal_open ? 'sound/items/uncork.ogg' : 'sound/misc/mat/pop.ogg', 50, TRUE)
	to_chat(H, cursed_anal_open ? span_notice(pick_chastity_string("chastity_cursed_messages.json", "chastity_anal_open")) : span_warning(pick_chastity_string("chastity_cursed_messages.json", "chastity_anal_closed")))
	// Atmospheric wearer reaction to rear shield state change
	to_chat(H, cursed_anal_open ? span_notice(pick_chastity_string("chastity_mode_messages.json", "chastity_rear_open")) : span_warning(pick_chastity_string("chastity_mode_messages.json", "chastity_rear_close")))
	log_cursed_chastity_command(H, CHASTITY_LOG_ANAL, "open=[cursed_anal_open] changed=TRUE")
	return TRUE

// Toggles internal spike punishment on cursed devices.
/obj/item/chastity/proc/toggle_cursed_spikes(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE
	// Deploying spikes is extreme content — block if the wearer has opted out.
	// Retraction is always permitted regardless of the toggle.
	if(!cursed_spikes_on && (H.client?.prefs && !H.client.prefs.extreme_erp))
		to_chat(H, span_warning("Eora intervenes. The spikes strain in their housing but cannot deploy."))
		return FALSE
	cursed_spikes_on = !cursed_spikes_on
	apply_cursed_state(H)
	playsound(H, cursed_spikes_on ? 'sound/items/beartrap.ogg' : 'sound/foley/flesh_rem.ogg', 50, TRUE)
	to_chat(H, cursed_spikes_on ? span_warning(pick_chastity_string("chastity_cursed_messages.json", "chastity_spikes_extend")) : span_notice(pick_chastity_string("chastity_cursed_messages.json", "chastity_spikes_retract")))
	log_cursed_chastity_command(H, CHASTITY_LOG_SPIKES, "enabled=[cursed_spikes_on]")
	return TRUE

// Sets cursed spikes directly for one-click UI controls.
/obj/item/chastity/proc/set_cursed_spikes(mob/living/carbon/human/H, should_enable)
	if(!chastity_cursed || !H)
		return FALSE
	var/new_state = !!should_enable
	// Deploying spikes is extreme content — block if the wearer has opted out.
	// Retraction (new_state == FALSE) is always permitted.
	if(new_state && (H.client?.prefs && !H.client.prefs.extreme_erp))
		to_chat(H, span_warning("Eora intervenes. The spikes strain in their housing but cannot deploy."))
		return FALSE
	if(cursed_spikes_on == new_state)
		log_cursed_chastity_command(H, CHASTITY_LOG_SPIKES, "enabled=[cursed_spikes_on] changed=FALSE")
		return TRUE
	cursed_spikes_on = new_state
	apply_cursed_state(H)
	playsound(H, cursed_spikes_on ? 'sound/items/beartrap.ogg' : 'sound/foley/flesh_rem.ogg', 50, TRUE)
	to_chat(H, cursed_spikes_on ? span_warning(pick_chastity_string("chastity_cursed_messages.json", "chastity_spikes_extend")) : span_notice(pick_chastity_string("chastity_cursed_messages.json", "chastity_spikes_retract")))
	log_cursed_chastity_command(H, CHASTITY_LOG_SPIKES, "enabled=[cursed_spikes_on] changed=TRUE")
	return TRUE

// Toggles between flat and standard cage style for cursed devices.
/obj/item/chastity/proc/toggle_cursed_flat(mob/living/carbon/human/H)
	if(!chastity_cursed || !H)
		return FALSE
	chastity_flat = !chastity_flat
	notify_chastity_state_change(H, "cursed_flat_toggled")
	playsound(H, chastity_flat ? 'sound/items/garrote.ogg' : 'sound/items/garrote2.ogg', 50, TRUE)
	to_chat(H, chastity_flat ? span_warning(pick_chastity_string("chastity_mode_messages.json", "chastity_flat_enable")) : span_notice(pick_chastity_string("chastity_mode_messages.json", "chastity_flat_disable")))
	log_cursed_chastity_command(H, CHASTITY_LOG_FLAT, "flat=[chastity_flat]")
	return TRUE

// Sets cursed flat state directly for one-click UI controls.
/obj/item/chastity/proc/set_cursed_flat(mob/living/carbon/human/H, should_be_flat)
	if(!chastity_cursed || !H)
		return FALSE
	var/new_state = !!should_be_flat
	if(chastity_flat == new_state)
		log_cursed_chastity_command(H, CHASTITY_LOG_FLAT, "flat=[chastity_flat] changed=FALSE")
		return TRUE
	chastity_flat = new_state
	notify_chastity_state_change(H, "cursed_flat_set")
	playsound(H, chastity_flat ? 'sound/items/garrote.ogg' : 'sound/items/garrote2.ogg', 50, TRUE)
	to_chat(H, chastity_flat ? span_warning(pick_chastity_string("chastity_mode_messages.json", "chastity_flat_enable")) : span_notice(pick_chastity_string("chastity_mode_messages.json", "chastity_flat_disable")))
	log_cursed_chastity_command(H, CHASTITY_LOG_FLAT, "flat=[chastity_flat] changed=TRUE")
	return TRUE

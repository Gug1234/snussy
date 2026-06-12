/**
 * # Cursed Collar Round-start Preferences
 *
 * Per-character state for choosing a cursed collar, cursed chastity device, or
 * cursed piercing before spawning. Account-level cursed/chastity/intimate
 * toggles still gate whether the selected item is applied.
 */

/datum/preferences/var/pref_cursed_roundstart_device = CURSED_ROUNDSTART_NONE
/datum/preferences/var/pref_cursed_master_name = ""
/datum/preferences/var/pref_cursed_self_master = FALSE
/datum/preferences/var/pref_gilded_chastity_recipient = GILDED_CHASTITY_RECIPIENT_MASTER
/datum/preferences/var/pref_cursed_piercing_slot = INTIMATE_SLOT_GENITAL

/proc/is_valid_gilded_chastity_recipient(recipient)
	if(!istext(recipient))
		return FALSE
	return recipient in list(
		GILDED_CHASTITY_RECIPIENT_MASTER,
		GILDED_CHASTITY_RECIPIENT_TREASURY,
		GILDED_CHASTITY_RECIPIENT_HOARDMASTER,
	)

/proc/get_gilded_chastity_recipient_options()
	return list(
		"Master" = GILDED_CHASTITY_RECIPIENT_MASTER,
		"Keep Treasury" = GILDED_CHASTITY_RECIPIENT_TREASURY,
		"Bandit Hoardmaster" = GILDED_CHASTITY_RECIPIENT_HOARDMASTER,
	)

/proc/is_valid_cursed_piercing_slot(slot)
	if(istext(slot))
		slot = text2num(slot)
	return slot in list(
		INTIMATE_SLOT_GENITAL,
		INTIMATE_SLOT_REAR,
		INTIMATE_SLOT_BREAST,
		INTIMATE_SLOT_MOUTH,
		INTIMATE_SLOT_EAR,
		INTIMATE_SLOT_NOSE,
		INTIMATE_SLOT_BELLY,
	)

/proc/get_cursed_piercing_slot_options()
	return list(
		"Genital" = INTIMATE_SLOT_GENITAL,
		"Rear" = INTIMATE_SLOT_REAR,
		"Breast" = INTIMATE_SLOT_BREAST,
		"Mouth" = INTIMATE_SLOT_MOUTH,
		"Ear" = INTIMATE_SLOT_EAR,
		"Nose" = INTIMATE_SLOT_NOSE,
		"Belly" = INTIMATE_SLOT_BELLY,
	)

/datum/preferences/proc/get_cursed_roundstart_device_options()
	return list(
		"None" = CURSED_ROUNDSTART_NONE,
		"Cursed Collar" = CURSED_ROUNDSTART_COLLAR,
		"Cursed Chastity" = CURSED_ROUNDSTART_CHASTITY,
		"Gilded Chastity" = CURSED_ROUNDSTART_GILDED_CHASTITY,
		"Cursed Piercing" = CURSED_ROUNDSTART_PIERCING,
	)

/datum/preferences/proc/is_valid_cursed_roundstart_device(device)
	if(!istext(device))
		return FALSE
	return device in list(
		CURSED_ROUNDSTART_NONE,
		CURSED_ROUNDSTART_COLLAR,
		CURSED_ROUNDSTART_CHASTITY,
		CURSED_ROUNDSTART_GILDED_CHASTITY,
		CURSED_ROUNDSTART_PIERCING,
	)

/datum/preferences/proc/set_cursed_roundstart_device(device)
	if(!is_valid_cursed_roundstart_device(device))
		return FALSE
	pref_cursed_roundstart_device = device
	return TRUE

/datum/preferences/proc/set_cursed_roundstart_master_name(master_name)
	if(!istext(master_name))
		return FALSE
	master_name = trim(sanitize_text(master_name))
	if(length_char(master_name) > MAX_NAME_LEN)
		master_name = copytext_char(master_name, 1, MAX_NAME_LEN + 1)
	pref_cursed_master_name = master_name
	return TRUE

/datum/preferences/proc/set_gilded_chastity_recipient(recipient)
	if(!is_valid_gilded_chastity_recipient(recipient))
		return FALSE
	pref_gilded_chastity_recipient = recipient
	apply_gilded_self_master_recipient_default()
	return TRUE

/datum/preferences/proc/set_cursed_piercing_slot(slot)
	if(istext(slot))
		slot = text2num(slot)
	if(!is_valid_cursed_piercing_slot(slot))
		return FALSE
	pref_cursed_piercing_slot = slot
	return TRUE

/datum/preferences/proc/apply_gilded_self_master_recipient_default()
	if(!pref_cursed_self_master)
		return FALSE
	if(pref_gilded_chastity_recipient != GILDED_CHASTITY_RECIPIENT_MASTER)
		return FALSE
	pref_gilded_chastity_recipient = GILDED_CHASTITY_RECIPIENT_TREASURY
	return TRUE

/datum/preferences/proc/has_cursed_roundstart_device()
	return pref_cursed_roundstart_device != CURSED_ROUNDSTART_NONE

/datum/preferences/proc/uses_cursed_roundstart_chastity()
	return pref_cursed_roundstart_device in list(CURSED_ROUNDSTART_CHASTITY, CURSED_ROUNDSTART_GILDED_CHASTITY)

/datum/preferences/proc/find_cursed_roundstart_master_mind(mob/living/carbon/human/wearer)
	if(pref_cursed_self_master)
		return wearer?.mind
	if(!length(pref_cursed_master_name))
		return null

	var/lower_master_name = LOWER_TEXT(pref_cursed_master_name)
	for(var/client/C as anything in GLOB.clients)
		if(!C?.prefs?.cursed_enabled)
			continue
		var/mob/living/carbon/human/candidate = C?.mob
		if(!istype(candidate) || !candidate.mind || !istext(candidate.real_name))
			continue
		if(LOWER_TEXT(candidate.real_name) == lower_master_name)
			if(candidate == wearer && !pref_cursed_self_master)
				return null
			return candidate.mind
	return null

/datum/preferences/proc/schedule_cursed_roundstart_retry(mob/living/carbon/human/wearer, retry_count)
	if(!wearer || QDELETED(wearer))
		return FALSE
	if(retry_count >= 10)
		to_chat(wearer, span_warning("Your cursed round-start item could not find its configured master."))
		return FALSE
	addtimer(CALLBACK(src, PROC_REF(apply_cursed_collar_preferences), wearer, retry_count + 1), 1 SECONDS)
	return TRUE

/datum/preferences/proc/apply_cursed_collar_preferences(mob/living/carbon/human/wearer, retry_count = 0)
	if(!wearer || !has_cursed_roundstart_device())
		return FALSE
	if(!cursed_enabled)
		return FALSE

	var/visual_only = istype(wearer, /mob/living/carbon/human/dummy)
	var/datum/mind/master_mind
	var/defer_piercing_master_binding = FALSE
	if(!visual_only)
		master_mind = find_cursed_roundstart_master_mind(wearer)
		if(!master_mind)
			if(pref_cursed_roundstart_device == CURSED_ROUNDSTART_PIERCING && (pref_cursed_self_master || length(pref_cursed_master_name)))
				defer_piercing_master_binding = TRUE
			else
				return schedule_cursed_roundstart_retry(wearer, retry_count)

	switch(pref_cursed_roundstart_device)
		if(CURSED_ROUNDSTART_COLLAR)
			return apply_roundstart_cursed_collar(wearer, master_mind, visual_only)
		if(CURSED_ROUNDSTART_CHASTITY)
			if(!chastenable)
				return FALSE
			return apply_roundstart_cursed_chastity(wearer, master_mind, visual_only)
		if(CURSED_ROUNDSTART_GILDED_CHASTITY)
			if(!chastenable)
				return FALSE
			return apply_roundstart_cursed_chastity(wearer, master_mind, visual_only, /obj/item/chastity/cursed/gilded)
		if(CURSED_ROUNDSTART_PIERCING)
			if(!intimate_enabled)
				return FALSE
			var/applied = apply_roundstart_cursed_piercing(wearer, master_mind, visual_only)
			if(applied && defer_piercing_master_binding)
				schedule_cursed_roundstart_retry(wearer, retry_count)
			return applied
	return FALSE

/datum/preferences/proc/apply_roundstart_cursed_collar(mob/living/carbon/human/wearer, datum/mind/master_mind, visual_only = FALSE)
	if(!wearer)
		return FALSE
	if(wearer.get_item_by_slot(SLOT_NECK))
		return FALSE
	var/obj/item/chastity/existing_chastity = wearer.chastity_device
	if(istype(existing_chastity) && existing_chastity.chastity_cursed)
		return FALSE

	var/obj/item/clothing/neck/roguetown/cursed_collar/collar = new(wearer)
	collar.applying = TRUE
	collar.collar_master = master_mind
	collar.roundstart_self_master_binding = !!(master_mind && wearer.mind == master_mind)
	if(!wearer.equip_to_slot_if_possible(collar, SLOT_NECK, TRUE, TRUE, TRUE, TRUE))
		return FALSE
	collar.applying = FALSE
	if(visual_only)
		return TRUE

	var/datum/component/collar_master/CM = master_mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		CM = master_mind.AddComponent(/datum/component/collar_master)
	if(!CM || (!CM.add_pet(wearer) && !(wearer in CM.my_pets)))
		wearer.dropItemToGround(collar, force = TRUE)
		return FALSE

	SEND_SIGNAL(wearer, COMSIG_CARBON_COLLAR_BOUND, master_mind, collar)
	ADD_TRAIT(collar, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	addtimer(CALLBACK(collar, TYPE_PROC_REF(/obj/item/clothing/neck/roguetown/cursed_collar, send_collar_signal), wearer), 2)
	to_chat(wearer, span_userdanger("The cursed collar around your neck clicks shut."))
	return TRUE

/datum/preferences/proc/apply_roundstart_cursed_chastity(mob/living/carbon/human/wearer, datum/mind/master_mind, visual_only = FALSE, device_type = /obj/item/chastity/cursed)
	if(!wearer || wearer.chastity_device)
		return FALSE
	var/obj/item/clothing/neck/roguetown/cursed_collar/existing_collar = wearer.get_item_by_slot(SLOT_NECK)
	if(istype(existing_collar))
		return FALSE

	var/obj/item/chastity/cursed/device = new device_type(wearer)
	device.chastity_master = master_mind
	device.roundstart_self_master_binding = !!(master_mind && wearer.mind == master_mind)
	if(device.chastity_gilded)
		device.gilded_recipient = pref_gilded_chastity_recipient
		if(device.roundstart_self_master_binding && device.gilded_recipient == GILDED_CHASTITY_RECIPIENT_MASTER)
			device.gilded_recipient = GILDED_CHASTITY_RECIPIENT_TREASURY
	device.ensure_chastity_feature(wearer)
	if(!device.attach_chastity_feature(wearer))
		qdel(device)
		return FALSE
	device.finalize_chastity_equip(wearer)
	device.locked = TRUE
	if(device.cursed_front_mode < 0 || device.cursed_front_mode > 3)
		device.cursed_front_mode = 0
	device.apply_cursed_state(wearer)
	if(visual_only)
		return TRUE

	var/datum/component/collar_master/CM = master_mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		CM = master_mind.AddComponent(/datum/component/collar_master)
	if(!CM || (!CM.add_pet(wearer) && !(wearer in CM.my_pets)))
		device.remove_chastity(wearer)
		qdel(device)
		return FALSE

	ADD_TRAIT(device, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	to_chat(wearer, span_userdanger("[device.chastity_gilded ? "The gilded chastity device" : "The cursed chastity device"] seals itself around you."))
	return TRUE

/datum/preferences/proc/bind_roundstart_cursed_piercing(mob/living/carbon/human/wearer, obj/item/intimate_accessory/piercing/cursed/piercing, datum/mind/master_mind)
	if(!wearer || !piercing || !master_mind)
		return FALSE
	var/datum/component/collar_master/CM = master_mind.GetComponent(/datum/component/collar_master)
	if(piercing.cursed_piercing_master == master_mind && CM && (wearer in CM.my_pets))
		return TRUE
	piercing.cursed_piercing_master = master_mind
	piercing.roundstart_self_master_binding = !!(wearer.mind == master_mind)
	if(!CM)
		CM = master_mind.AddComponent(/datum/component/collar_master)
	if(!CM || (!CM.add_pet(wearer) && !(wearer in CM.my_pets)))
		piercing.remove_intimate_accessory(wearer)
		qdel(piercing)
		return FALSE

	SEND_SIGNAL(wearer, COMSIG_CARBON_COLLAR_BOUND, master_mind, piercing)
	to_chat(wearer, span_userdanger("The cursed piercing twists shut around you."))
	return TRUE

/datum/preferences/proc/apply_roundstart_cursed_piercing(mob/living/carbon/human/wearer, datum/mind/master_mind, visual_only = FALSE)
	if(!wearer)
		return FALSE
	var/obj/item/clothing/neck/roguetown/cursed_collar/existing_collar = wearer.get_item_by_slot(SLOT_NECK)
	if(istype(existing_collar))
		return FALSE
	var/obj/item/chastity/existing_chastity = wearer.chastity_device
	if(istype(existing_chastity) && existing_chastity.chastity_cursed)
		return FALSE
	var/obj/item/intimate_accessory/piercing/cursed/piercing = wearer.get_cursed_piercing()
	if(istype(piercing))
		if(visual_only || !master_mind)
			return TRUE
		return bind_roundstart_cursed_piercing(wearer, piercing, master_mind)

	piercing = new(wearer)
	piercing.cursed_piercing_master = master_mind
	piercing.roundstart_self_master_binding = !!(master_mind && wearer.mind == master_mind)
	var/slot = pref_cursed_piercing_slot
	if(!is_valid_cursed_piercing_slot(slot) || !piercing.set_current_intimate_slot(slot))
		qdel(piercing)
		return FALSE
	var/obj/item/intimate_accessory/existing_accessory = piercing.get_worn_in_slot(wearer, slot)
	if(existing_accessory)
		existing_accessory.remove_intimate_accessory(wearer)
		qdel(existing_accessory)
	if(!piercing.is_slot_available(wearer, slot))
		qdel(piercing)
		return FALSE
	if(!piercing.attach_intimate_feature(wearer))
		qdel(piercing)
		return FALSE
	piercing.roundstart_equipped = TRUE
	piercing.finalize_intimate_equip(wearer)
	if(visual_only || !master_mind)
		return TRUE
	return bind_roundstart_cursed_piercing(wearer, piercing, master_mind)

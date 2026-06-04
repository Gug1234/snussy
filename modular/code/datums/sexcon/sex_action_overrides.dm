// Unified silver check for intimate regions (mouth, breast, genital, etc.)
/datum/sex_action/proc/get_tongue_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/piercing/tongue/tongue_piercing = owner.intimate_mouth_piercing
	if(!istype(tongue_piercing))
		return null
	return tongue_piercing

/datum/sex_action/proc/get_genital_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/piercing/genital/genital_piercing = owner.intimate_genital_piercing
	if(!istype(genital_piercing))
		return null
	return genital_piercing

/datum/sex_action/proc/get_genital_plug(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/genital/plug/genital_plug = owner.intimate_genital_insertable
	if(!istype(genital_plug))
		return null
	return genital_plug


/datum/sex_action/proc/get_rear_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/rear_item = owner.intimate_rear_piercing
	if(!istype(rear_item, /obj/item/intimate_accessory))
		return null
	return rear_item

/datum/sex_action/proc/get_front_piercing(mob/living/carbon/human/owner)
	return get_breast_piercing(owner)


/datum/sex_action/proc/apply_silver_intimate_contact(region, owner, contact_target)
	if(!owner || !contact_target)
		return FALSE
	var/obj/item/intimate_accessory/piercing/piercing = null
	switch(region)
		if("mouth")
			piercing = get_tongue_piercing(owner)
		if("breast")
			piercing = get_breast_piercing(owner)
		if("genital")
			piercing = get_genital_piercing(owner)
		if("rear")
			piercing = get_rear_piercing(owner)
	return !!piercing

/datum/sex_action/custom/name = "Custom Action"
/datum/sex_action/custom/category = SEX_CATEGORY_MISC
/datum/sex_action/custom/var/slot_number = 0

/datum/sex_action/custom/proc/get_slot_config(mob/living/carbon/human/user)
	if(!user?.client?.prefs || !islist(user.client.prefs.custom_sex_actions))
		return null

	for(var/list/config as anything in user.client.prefs.custom_sex_actions)
		if(!islist(config))
			continue
		if(text2num("[config["slot"]]") == slot_number)
			return config
	return null

/datum/sex_action/custom/get_display_name(mob/living/carbon/human/user)
	var/list/config = get_slot_config(user)
	if(!config)
		return ..()
	var/custom_name = config["name"]
	if(istext(custom_name) && length(custom_name))
		return custom_name
	return ..()

/datum/sex_action/custom/get_runtime_category(mob/living/carbon/human/user)
	var/list/config = get_slot_config(user)
	if(!config)
		return ..()
	return clamp(text2num("[config["category"]]"), SEX_CATEGORY_MISC, SEX_CATEGORY_MISC | SEX_CATEGORY_HANDS | SEX_CATEGORY_PENETRATE)

/datum/sex_action/custom/get_runtime_stamina_cost(mob/living/carbon/human/user)
	var/list/config = get_slot_config(user)
	if(!config)
		return ..()
	return clamp(text2num("[config["stamina_cost"]]"), 0, 3)

/datum/sex_action/custom/proc/has_custom_chastity_requirement(mob/living/carbon/human/H, requirement)
	if(requirement == 1)
		return !!H?.chastity_device
	if(requirement == 2)
		return !H?.chastity_device
	return TRUE

/datum/sex_action/custom/proc/has_custom_held_dildo(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	for(var/obj/item/held_item in H.held_items)
		if(istype(held_item, /obj/item/dildo))
			return TRUE
	return FALSE

/datum/sex_action/custom/proc/has_custom_mounted_dildo(mob/living/carbon/human/H)
	return !!H?.chastity_device?.attached_toy

/datum/sex_action/custom/proc/has_custom_toy_requirement(mob/living/carbon/human/user, requirement)
	switch(requirement)
		if(1)
			return has_custom_held_dildo(user)
		if(2)
			return has_custom_mounted_dildo(user)
		if(3)
			return has_custom_held_dildo(user) || has_custom_mounted_dildo(user)
	return TRUE

/datum/sex_action/custom/proc/has_custom_piercing_requirement(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	if(H.intimate_genital_piercing || H.intimate_rear_piercing || H.intimate_breast_piercing)
		return TRUE
	if(H.intimate_mouth_piercing || H.intimate_ear_piercing || H.intimate_nose_piercing || H.intimate_belly_piercing)
		return TRUE
	return FALSE

/datum/sex_action/custom/proc/has_custom_plug_requirement(mob/living/carbon/human/H, requirement)
	if(requirement <= 0)
		return TRUE
	if(!H)
		return FALSE

	var/obj/item/intimate_accessory/rear/plug/rear_plug = H.intimate_rear_insertable
	var/obj/item/intimate_accessory/genital/plug/genital_plug = H.intimate_genital_insertable
	switch(requirement)
		if(1)
			return !!(rear_plug || genital_plug)
		if(2)
			return !!rear_plug
		if(3)
			return istype(rear_plug, /obj/item/intimate_accessory/rear/plug/analbeads)
		if(4)
			return !!genital_plug
		if(5)
			return istype(genital_plug, /obj/item/intimate_accessory/genital/plug/sounding_rod)
	return TRUE

/datum/sex_action/custom/proc/has_custom_manticore_tail_requirement(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	return istype(H.getorganslot(ORGAN_SLOT_TAIL), /obj/item/organ/tail/manticore)

/datum/sex_action/custom/proc/check_requirements(list/config, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!config || !user || !target)
		return FALSE
	if(!has_custom_chastity_requirement(user, text2num("[config["req_user_chastity"]]")))
		return FALSE
	if(!has_custom_chastity_requirement(target, text2num("[config["req_target_chastity"]]")))
		return FALSE
	if(!has_custom_toy_requirement(user, text2num("[config["req_toy"]]")))
		return FALSE
	if(config["req_user_piercing"] && !has_custom_piercing_requirement(user))
		return FALSE
	if(config["req_target_piercing"] && !has_custom_piercing_requirement(target))
		return FALSE
	if(!has_custom_plug_requirement(user, text2num("[config["req_user_plug"]]")))
		return FALSE
	if(!has_custom_plug_requirement(target, text2num("[config["req_target_plug"]]")))
		return FALSE
	if(config["req_no_rear_plug"] && target.intimate_rear_insertable)
		return FALSE
	if(config["req_user_manticore_tail"] && !has_custom_manticore_tail_requirement(user))
		return FALSE
	if(config["req_target_manticore_tail"] && !has_custom_manticore_tail_requirement(target))
		return FALSE
	return TRUE

/datum/sex_action/custom/proc/resolve_sex_flavor_tokens(text, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!istext(text))
		return ""

	var/user_name = user ? "[user]" : "someone"
	var/target_name = target ? "[target]" : "someone"
	text = replacetext(text, "\[USER]", user_name)
	text = replacetext(text, "\[TARGET]", target_name)
	if(user)
		text = replacetext(text, "\[THEY]", user.p_they())
		text = replacetext(text, "\[THEM]", user.p_them())
		text = replacetext(text, "\[THEIR]", user.p_their())
	if(target)
		text = replacetext(text, "\[TTHEY]", target.p_they())
		text = replacetext(text, "\[TTHEM]", target.p_them())
		text = replacetext(text, "\[TTHEIR]", target.p_their())
	if(user?.sexcon)
		text = replacetext(text, "\[FORCE]", user.sexcon.get_generic_force_adjective())
	return text

/datum/sex_action/custom/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return FALSE
	if(!user || !target)
		return FALSE
	if(config["requires_other"] && user == target)
		return FALSE
	// Check user anatomy against configured user_sex_part.
	var/upart = config["user_sex_part"]
	if(upart & SEX_PART_COCK)
		if(!user.getorganslot(ORGAN_SLOT_PENIS))
			return FALSE
	if(upart & SEX_PART_CUNT)
		if(!user.getorganslot(ORGAN_SLOT_VAGINA))
			return FALSE
	// Check target anatomy against configured target_sex_part.
	var/tpart = config["target_sex_part"]
	if(tpart & SEX_PART_COCK)
		if(!target.getorganslot(ORGAN_SLOT_PENIS))
			return FALSE
	if(tpart & SEX_PART_CUNT)
		if(!target.getorganslot(ORGAN_SLOT_VAGINA))
			return FALSE
	// Validate unique requirement checks.
	if(!check_requirements(config, user, target))
		return FALSE
	return TRUE

/datum/sex_action/custom/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return FALSE
	if(config["requires_other"] && user == target)
		return FALSE
	if(!user.sexcon.Adjacent_Or_Closet(target))
		return FALSE
	// Re-validate requirements at perform time (equipment may change mid-act).
	if(!check_requirements(config, user, target))
		return FALSE
	return TRUE

/datum/sex_action/custom/proc/apply_custom_sound_course(list/config, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!config || !user?.sexcon || !target)
		return
	switch(sanitize_custom_sex_sound_course(config["sound_course"]))
		if(CUSTOM_SEX_SOUND_GENERIC)
			user.sexcon.generic_sex_noise()
		if(CUSTOM_SEX_SOUND_SUCKING)
			user.sexcon.make_sucking_noise()
		if(CUSTOM_SEX_SOUND_ORAL)
			user.sexcon.oralcourse_noise(target)
		if(CUSTOM_SEX_SOUND_OUTERCOURSE)
			user.sexcon.outercourse_noise(target)
		if(CUSTOM_SEX_SOUND_OUTERCOURSE_WET)
			user.sexcon.outercourse_noise(target, TRUE)
		if(CUSTOM_SEX_SOUND_INTERCOURSE)
			user.sexcon.intercourse_noise(target)
		if(CUSTOM_SEX_SOUND_INTERCOURSE_WET)
			user.sexcon.intercourse_noise(target, TRUE)
		if(CUSTOM_SEX_SOUND_CHASTITY)
			user.sexcon.chastitycourse_noise(target)

/datum/sex_action/custom/proc/apply_custom_animation(list/config, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!config || !user?.sexcon || !target)
		return
	switch(sanitize_custom_sex_animation_type(config["animation_type"]))
		if(CUSTOM_SEX_ANIMATION_THRUST)
			user.sexcon.do_thrust_animate(target)
		if(CUSTOM_SEX_ANIMATION_SOFT_THRUST)
			user.sexcon.do_thrust_animate(target, pixels = 2, time = 3)
		if(CUSTOM_SEX_ANIMATION_HARD_THRUST)
			user.sexcon.do_thrust_animate(target, pixels = 5, time = 2)

/datum/sex_action/custom/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return
	log_game("CUSTOM_SEX_ACTION: [key_name(user)] used custom action '[config["name"]]' (slot [slot_number]) on [key_name(target)] at [AREACOORD(user)]")
	var/text = config["on_start_text"]
	if(istext(text) && length(text))
		text = resolve_sex_flavor_tokens(text, user, target)
		user.visible_message(span_warning(text))
	else
		user.visible_message(span_warning("[user] begins a custom act with [target]..."))

/datum/sex_action/custom/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return
	var/text = config["on_perform_text"]
	if(istext(text) && length(text))
		text = resolve_sex_flavor_tokens(text, user, target)
		user.visible_message(user.sexcon.spanify_force(text))
	else
		user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] continues the act with [target]."))
	apply_custom_sound_course(config, user, target)
	apply_custom_animation(config, user, target)
	// Apply configured stats.
	var/user_arousal = config["user_arousal"]
	var/target_arousal = config["target_arousal"]
	var/user_pain = config["user_pain"]
	var/target_pain = config["target_pain"]
	user.sexcon.perform_sex_action(user, user_arousal, user_pain, TRUE)
	user.sexcon.perform_sex_action(target, target_arousal, target_pain, FALSE)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/custom/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return
	var/text = config["on_finish_text"]
	if(istext(text) && length(text))
		text = resolve_sex_flavor_tokens(text, user, target)
		user.visible_message(span_warning(text))
	else
		user.visible_message(span_warning("[user] stops the custom act with [target]."))

/datum/sex_action/custom/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return TRUE
	if(!config["continuous"])
		return TRUE
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE

// ── Concrete slot subtypes (not abstract, so they register in GLOB.sex_actions)
/datum/sex_action/custom/slot_1/name = "Custom Action 1"
/datum/sex_action/custom/slot_1/slot_number = 1

/datum/sex_action/custom/slot_2/name = "Custom Action 2"
/datum/sex_action/custom/slot_2/slot_number = 2

/datum/sex_action/custom/slot_3/name = "Custom Action 3"
/datum/sex_action/custom/slot_3/slot_number = 3

/datum/sex_action/custom/slot_4/name = "Custom Action 4"
/datum/sex_action/custom/slot_4/slot_number = 4

/datum/sex_action/custom/slot_5/name = "Custom Action 5"
/datum/sex_action/custom/slot_5/slot_number = 5

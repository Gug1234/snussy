/**
 * # Cursed Collar Lobby Menu
 *
 * Character-sheet TGUI for selecting a round-start cursed binding and the
 * character name that should control it.
 */

/datum/cursed_collar_lobby_menu
	var/datum/preferences/prefs

/datum/cursed_collar_lobby_menu/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P

/datum/cursed_collar_lobby_menu/Destroy()
	prefs = null
	return ..()

/datum/cursed_collar_lobby_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CursedCollarPrefsMenu", "Cursed Collar", 480, 430)
		ui.open()

/datum/cursed_collar_lobby_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/cursed_collar_lobby_menu/ui_data(mob/user)
	var/list/data = list()
	var/list/device_options = list()
	var/list/raw_options = prefs.get_cursed_roundstart_device_options()
	for(var/label in raw_options)
		device_options += list(list(
			"label" = label,
			"value" = raw_options[label],
		))
	var/list/gilded_recipient_options = list()
	var/list/raw_recipient_options = get_gilded_chastity_recipient_options()
	for(var/label in raw_recipient_options)
		gilded_recipient_options += list(list(
			"label" = label,
			"value" = raw_recipient_options[label],
		))
	var/list/piercing_slot_options = list()
	var/list/raw_piercing_slot_options = get_cursed_piercing_slot_options()
	for(var/label in raw_piercing_slot_options)
		piercing_slot_options += list(list(
			"label" = label,
			"value" = raw_piercing_slot_options[label],
		))

	data["cursed_enabled"] = prefs.cursed_enabled
	data["chastenable"] = prefs.chastenable
	data["intimate_enabled"] = prefs.intimate_enabled
	data["device"] = prefs.pref_cursed_roundstart_device
	data["device_options"] = device_options
	data["gilded_recipient"] = prefs.pref_gilded_chastity_recipient
	data["gilded_recipient_options"] = gilded_recipient_options
	data["piercing_slot"] = prefs.pref_cursed_piercing_slot
	data["piercing_slot_options"] = piercing_slot_options
	data["master_name"] = prefs.pref_cursed_master_name
	data["self_master"] = prefs.pref_cursed_self_master
	data["character_name"] = prefs.real_name
	return data

/datum/cursed_collar_lobby_menu/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("set_device")
			var/device = params["device"]
			if(!prefs.set_cursed_roundstart_device(device))
				return FALSE
			if(device == CURSED_ROUNDSTART_GILDED_CHASTITY)
				prefs.apply_gilded_self_master_recipient_default()
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("set_gilded_recipient")
			if(!prefs.set_gilded_chastity_recipient(params["recipient"]))
				return FALSE
			prefs.save_character()
			return TRUE

		if("set_piercing_slot")
			if(!prefs.set_cursed_piercing_slot(params["slot"]))
				return FALSE
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("set_master_name")
			var/master_name = params["master_name"]
			if(isnull(master_name))
				master_name = params["name"]
			if(!prefs.set_cursed_roundstart_master_name(master_name))
				return FALSE
			if(length(prefs.pref_cursed_master_name))
				prefs.pref_cursed_self_master = FALSE
			prefs.save_character()
			return TRUE

		if("toggle_self_master")
			prefs.pref_cursed_self_master = !prefs.pref_cursed_self_master
			prefs.apply_gilded_self_master_recipient_default()
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

	return FALSE

/datum/cursed_collar_lobby_menu/ui_close(mob/user)
	var/client/C = user?.client
	if(C)
		addtimer(CALLBACK(C, TYPE_PROC_REF(/client, prefs_resume_after_singleton)), 1)
	return ..()

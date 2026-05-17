/**
 * # Intimate Lobby Menu
 *
 * Lobby-side TGUI panel for selecting first-PR intimate accessories. This
 * talks only to direct per-slot preference typepaths; custom piercing sidecars
 * and offset editors are intentionally out of scope.
 */

/datum/intimate_lobby_menu
	/// The preferences datum being edited.
	var/datum/preferences/prefs

/datum/intimate_lobby_menu/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P

/datum/intimate_lobby_menu/Destroy(force)
	prefs = null
	return ..()

/datum/intimate_lobby_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntimatePrefsMenu", "Intimate Accessories", 500, 480)
		ui.open()

/datum/intimate_lobby_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/intimate_lobby_menu/ui_data(mob/user)
	var/list/data = list()
	data["slots"] = prefs?.get_intimate_accessory_slot_rows() || list()
	return data

/datum/intimate_lobby_menu/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(!prefs)
		return FALSE

	switch(action)
		if("select")
			var/slot_key = params["slot"]
			var/chosen = params["option"]
			var/list/options = prefs.get_intimate_accessory_slot_options(slot_key)
			if(!(chosen in options))
				return FALSE
			if(!prefs.set_intimate_accessory_slot_typepath(slot_key, options[chosen]))
				return FALSE
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("clear")
			var/slot_key = params["slot"]
			if(!prefs.set_intimate_accessory_slot_typepath(slot_key, null))
				return FALSE
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("set_descriptor")
			var/slot_key = params["slot"]
			if(!prefs.set_intimate_piercing_descriptor(slot_key, params["descriptor"]))
				return FALSE
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

	return FALSE

/datum/intimate_lobby_menu/ui_close(mob/user)
	var/client/C = user?.client
	if(C)
		addtimer(CALLBACK(C, TYPE_PROC_REF(/client, prefs_resume_after_singleton)), 1)
	return ..()

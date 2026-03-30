/**
 * # Intimate Lobby Menu (TGUI)
 *
 * A lobby-specific TGUI panel for selecting intimate accessories before spawning.
 * Unlike the in-game IntimateMenu (which manages equipped items on a live mob),
 * this operates purely on preference data — setting typepaths that are applied
 * during `copy_to` when the character spawns.
 *
 * Opened from the vices menu "Intimate Accessories" tab.
 */

/datum/intimate_lobby_menu
	/// The preferences datum we're editing.
	var/datum/preferences/prefs

/datum/intimate_lobby_menu/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P

/datum/intimate_lobby_menu/Destroy()
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
	var/list/slots = list()

	// Slot definitions: key, label, pref var value, option list proc
	var/list/slot_defs = list(
		list("key" = "genital", "label" = "Genital",  "pref" = prefs.pref_intimate_genital),
		list("key" = "rear",    "label" = "Rear",     "pref" = prefs.pref_intimate_rear),
		list("key" = "breast",  "label" = "Breast",   "pref" = prefs.pref_intimate_breast),
		list("key" = "mouth",   "label" = "Mouth",    "pref" = prefs.pref_intimate_mouth),
	)

	for(var/list/def in slot_defs)
		var/list/options = _get_options_for_slot(def["key"])
		var/list/option_names = list()
		for(var/name in options)
			option_names += name

		var/current_display = prefs.get_intimate_option_display_name(def["pref"])
		slots += list(list(
			"key"     = def["key"],
			"label"   = def["label"],
			"current" = current_display,
			"options" = option_names,
		))

	data["slots"] = slots
	return data

/// Returns the assoc options list for a given slot key string.
/datum/intimate_lobby_menu/proc/_get_options_for_slot(slot_key)
	switch(slot_key)
		if("genital")
			return prefs.get_intimate_genital_options()
		if("rear")
			return prefs.get_intimate_rear_options()
		if("breast")
			return prefs.get_intimate_breast_options()
		if("mouth")
			return prefs.get_intimate_mouth_options()
	return list()

/datum/intimate_lobby_menu/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("select")
			var/slot_key = params["slot"]
			var/chosen = params["option"]
			var/list/options = _get_options_for_slot(slot_key)
			if(!options)
				return FALSE
			var/typepath = null
			if(chosen in options)
				typepath = options[chosen]

			switch(slot_key)
				if("genital")
					prefs.pref_intimate_genital = typepath
				if("rear")
					prefs.pref_intimate_rear = typepath
				if("breast")
					prefs.pref_intimate_breast = typepath
				if("mouth")
					prefs.pref_intimate_mouth = typepath
				else
					return FALSE

			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("clear")
			var/slot_key = params["slot"]
			switch(slot_key)
				if("genital")
					prefs.pref_intimate_genital = null
				if("rear")
					prefs.pref_intimate_rear = null
				if("breast")
					prefs.pref_intimate_breast = null
				if("mouth")
					prefs.pref_intimate_mouth = null
				else
					return FALSE

			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

	return FALSE


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

	// Each region has two sub-slots: piercing and insertable.
	var/list/slot_defs = list(
		list("key" = "genital_piercing",    "label" = "Genital Piercing",    "pref" = prefs.pref_intimate_genital_piercing),
		list("key" = "genital_insertable",  "label" = "Genital Insertable",  "pref" = prefs.pref_intimate_genital_insertable),
		list("key" = "rear_piercing",       "label" = "Rear Piercing",       "pref" = prefs.pref_intimate_rear_piercing),
		list("key" = "rear_insertable",     "label" = "Rear Insertable",     "pref" = prefs.pref_intimate_rear_insertable),
		list("key" = "breast_piercing",     "label" = "Breast Piercing",     "pref" = prefs.pref_intimate_breast_piercing),
		list("key" = "breast_insertable",   "label" = "Breast Insertable",   "pref" = prefs.pref_intimate_breast_insertable),
		list("key" = "mouth_piercing",      "label" = "Mouth Piercing",      "pref" = prefs.pref_intimate_mouth_piercing),
		list("key" = "mouth_insertable",    "label" = "Mouth Insertable",    "pref" = prefs.pref_intimate_mouth_insertable),
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
		if("genital_piercing")
			return prefs.get_intimate_genital_piercing_options()
		if("genital_insertable")
			return prefs.get_intimate_genital_insertable_options()
		if("rear_piercing")
			return prefs.get_intimate_rear_piercing_options()
		if("rear_insertable")
			return prefs.get_intimate_rear_insertable_options()
		if("breast_piercing")
			return prefs.get_intimate_breast_piercing_options()
		if("breast_insertable")
			return prefs.get_intimate_breast_insertable_options()
		if("mouth_piercing")
			return prefs.get_intimate_mouth_piercing_options()
		if("mouth_insertable")
			return prefs.get_intimate_mouth_insertable_options()
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
				if("genital_piercing")
					prefs.pref_intimate_genital_piercing = typepath
				if("genital_insertable")
					prefs.pref_intimate_genital_insertable = typepath
				if("rear_piercing")
					prefs.pref_intimate_rear_piercing = typepath
				if("rear_insertable")
					prefs.pref_intimate_rear_insertable = typepath
				if("breast_piercing")
					prefs.pref_intimate_breast_piercing = typepath
				if("breast_insertable")
					prefs.pref_intimate_breast_insertable = typepath
				if("mouth_piercing")
					prefs.pref_intimate_mouth_piercing = typepath
				if("mouth_insertable")
					prefs.pref_intimate_mouth_insertable = typepath
				else
					return FALSE

			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("clear")
			var/slot_key = params["slot"]
			switch(slot_key)
				if("genital_piercing")
					prefs.pref_intimate_genital_piercing = null
				if("genital_insertable")
					prefs.pref_intimate_genital_insertable = null
				if("rear_piercing")
					prefs.pref_intimate_rear_piercing = null
				if("rear_insertable")
					prefs.pref_intimate_rear_insertable = null
				if("breast_piercing")
					prefs.pref_intimate_breast_piercing = null
				if("breast_insertable")
					prefs.pref_intimate_breast_insertable = null
				if("mouth_piercing")
					prefs.pref_intimate_mouth_piercing = null
				if("mouth_insertable")
					prefs.pref_intimate_mouth_insertable = null
				else
					return FALSE

			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

	return FALSE


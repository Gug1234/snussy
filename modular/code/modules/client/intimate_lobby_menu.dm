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

	for(var/list/def in prefs.get_custom_piercing_editor_regular_slot_defs())
		var/list/options = _get_options_for_slot(def["key"])
		var/list/option_names = list()
		for(var/name in options)
			option_names += name

		var/current_pref = _get_current_pref_for_slot_def(def)
		var/current_display = prefs.get_intimate_option_display_name(current_pref)
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
	return prefs.get_custom_piercing_slot_options(slot_key)

/// Returns the currently selected typepath for one shared regular-slot row.
/datum/intimate_lobby_menu/proc/_get_current_pref_for_slot_def(list/slot_def)
	if(!islist(slot_def))
		return null
	var/custom_key = slot_def["custom_key"]
	if(custom_key)
		return prefs.get_custom_piercing_slot_equipped_typepath(custom_key)
	switch(slot_def["key"])
		if("breast_insertable")
			return prefs.pref_intimate_breast_insertable
		if("mouth_insertable")
			return prefs.pref_intimate_mouth_insertable
	return null

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
					prefs.set_custom_piercing_slot_equipped_typepath("genital", typepath)
				if("genital_insertable")
					prefs.set_custom_piercing_slot_equipped_typepath("insertable_genital", typepath)
				if("rear_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("rear", typepath)
				if("rear_insertable")
					prefs.set_custom_piercing_slot_equipped_typepath("insertable_rear", typepath)
				if("breast_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("breast", typepath)
				if("breast_insertable")
					prefs.pref_intimate_breast_insertable = typepath
				if("mouth_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("tongue", typepath)
				if("mouth_insertable")
					prefs.pref_intimate_mouth_insertable = typepath
				if("ear_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("ear", typepath)
				if("nose_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("nose", typepath)
				if("belly_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("belly", typepath)
				else
					return FALSE

			prefs.save_custom_piercings(prefs.default_slot)
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("clear")
			var/slot_key = params["slot"]
			switch(slot_key)
				if("genital_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("genital", null)
				if("genital_insertable")
					prefs.set_custom_piercing_slot_equipped_typepath("insertable_genital", null)
				if("rear_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("rear", null)
				if("rear_insertable")
					prefs.set_custom_piercing_slot_equipped_typepath("insertable_rear", null)
				if("breast_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("breast", null)
				if("breast_insertable")
					prefs.pref_intimate_breast_insertable = null
				if("mouth_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("tongue", null)
				if("mouth_insertable")
					prefs.pref_intimate_mouth_insertable = null
				if("ear_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("ear", null)
				if("nose_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("nose", null)
				if("belly_piercing")
					prefs.set_custom_piercing_slot_equipped_typepath("belly", null)
				else
					return FALSE

			prefs.save_custom_piercings(prefs.default_slot)
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

	return FALSE

/datum/intimate_lobby_menu/ui_close(mob/user)
	user?.client?.prefs_resume_after_singleton()
	return ..()

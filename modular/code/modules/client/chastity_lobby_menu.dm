/**
 * # Chastity Lobby Menu (TGUI)
 *
 * A lobby-specific TGUI panel for configuring chastity device preferences
 * before spawning. Uses a toggle-based system instead of a typepath dropdown:
 *   1. Enabled on/off (auto-fits device to character's genitals)
 *   2. Cage style: Standard / Flat (only for cock cages)
 *   3. Anal shield: Yes / No
 *   4. Spikes: Yes / No (requires extreme ERP)
 *   5. Spawn locked, spawn with key, key stash targets
 *
 * Key stashes store **character names** (not ckeys). On round-start, matching
 * online characters receive a copy of the key.
 *
 * Opened from the character setup "Chastity Device" link.
 */

/datum/chastity_lobby_menu
	/// The preferences datum we're editing.
	var/datum/preferences/prefs

/datum/chastity_lobby_menu/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P

/datum/chastity_lobby_menu/Destroy()
	prefs = null
	return ..()

/datum/chastity_lobby_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChastityPrefsMenu", "Chastity Device", 480, 520)
		ui.open()

/datum/chastity_lobby_menu/ui_state(mob/user)
	return GLOB.always_state

/datum/chastity_lobby_menu/ui_data(mob/user)
	var/list/data = list()

	data["chastenable"] = prefs.chastenable
	data["extreme_erp"] = prefs.extreme_erp

	// Toggle states
	data["enabled"] = prefs.pref_chastity_enabled
	data["flat"] = prefs.pref_chastity_flat
	data["anal"] = prefs.pref_chastity_anal
	data["spiked"] = prefs.pref_chastity_spiked
	data["locked"] = prefs.pref_chastity_locked
	data["spawn_key"] = prefs.pref_chastity_spawn_key

	// Genital info for the UI to show/hide options
	data["has_penis"] = prefs.has_genital_in_prefs(ORGAN_SLOT_PENIS)
	data["has_vagina"] = prefs.has_genital_in_prefs(ORGAN_SLOT_VAGINA)

	// Key stash list (character names)
	data["key_stashes"] = prefs.pref_chastity_key_stashes ? prefs.pref_chastity_key_stashes : list()

	// Random key distribution toggle
	data["random_keys"] = prefs.pref_chastity_random_keys

	return data

/datum/chastity_lobby_menu/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("toggle_enabled")
			prefs.pref_chastity_enabled = !prefs.pref_chastity_enabled
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("toggle_flat")
			prefs.pref_chastity_flat = !prefs.pref_chastity_flat
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("toggle_anal")
			prefs.pref_chastity_anal = !prefs.pref_chastity_anal
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("toggle_spiked")
			prefs.pref_chastity_spiked = !prefs.pref_chastity_spiked
			prefs.save_character()
			prefs.update_preview_icon()
			return TRUE

		if("toggle_locked")
			prefs.pref_chastity_locked = !prefs.pref_chastity_locked
			prefs.save_character()
			return TRUE

		if("toggle_spawn_key")
			prefs.pref_chastity_spawn_key = !prefs.pref_chastity_spawn_key
			prefs.save_character()
			return TRUE

		if("toggle_random_keys")
			prefs.pref_chastity_random_keys = !prefs.pref_chastity_random_keys
			prefs.save_character()
			return TRUE

		if("add_stash")
			var/name_input = params["name"]
			if(!istext(name_input) || !length(name_input))
				return FALSE
			// Basic sanitization — strip leading/trailing whitespace
			name_input = trim(name_input)
			if(!length(name_input))
				return FALSE
			if(!prefs.pref_chastity_key_stashes)
				prefs.pref_chastity_key_stashes = list()
			// Prevent duplicates (case-insensitive)
			for(var/existing in prefs.pref_chastity_key_stashes)
				if(LOWER_TEXT(existing) == LOWER_TEXT(name_input))
					return FALSE
			// Cap at 5 stash targets to prevent abuse
			if(length(prefs.pref_chastity_key_stashes) >= 5)
				return FALSE
			prefs.pref_chastity_key_stashes += name_input
			prefs.save_character()
			return TRUE

		if("remove_stash")
			var/name_target = params["name"]
			if(!istext(name_target) || !prefs.pref_chastity_key_stashes)
				return FALSE
			prefs.pref_chastity_key_stashes -= name_target
			if(!length(prefs.pref_chastity_key_stashes))
				prefs.pref_chastity_key_stashes = null
			prefs.save_character()
			return TRUE

	return FALSE

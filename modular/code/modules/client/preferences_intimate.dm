/**
 * # Intimate Accessory Preferences
 *
 * Keeps the first-PR intimate accessory scope deliberately small: each
 * character slot stores direct typepaths for base piercings, plugs, beads, and
 * rods. Shelved decoration editors and placement tooling are not part of this
 * branch.
 */

/// Account-level opt-in for intimate accessory equip/use behavior.
/datum/preferences/var/intimate_enabled = FALSE
/// Allows other players to see intimate accessory details through examine when uncovered.
/datum/preferences/var/show_intimate_examine = FALSE
/// Reserved UI preference for future compact paper-doll accessory widgets.
/datum/preferences/var/intimate_visual_widgets = FALSE
/// Round-start intimate accessory selections for the active character slot.
/datum/preferences/var/pref_intimate_genital_piercing = null
/datum/preferences/var/pref_intimate_genital_insertable = null
/datum/preferences/var/pref_intimate_rear_piercing = null
/datum/preferences/var/pref_intimate_rear_insertable = null
/datum/preferences/var/pref_intimate_breast_piercing = null
/datum/preferences/var/pref_intimate_breast_insertable = null
/datum/preferences/var/pref_intimate_mouth_piercing = null
/datum/preferences/var/pref_intimate_mouth_insertable = null
/datum/preferences/var/pref_intimate_ear_piercing = null
/datum/preferences/var/pref_intimate_nose_piercing = null
/datum/preferences/var/pref_intimate_belly_piercing = null
/datum/preferences/var/pref_intimate_genital_piercing_descriptor = null
/datum/preferences/var/pref_intimate_rear_piercing_descriptor = null
/datum/preferences/var/pref_intimate_breast_piercing_descriptor = null
/datum/preferences/var/pref_intimate_mouth_piercing_descriptor = null
/datum/preferences/var/pref_intimate_ear_piercing_descriptor = null
/datum/preferences/var/pref_intimate_nose_piercing_descriptor = null
/datum/preferences/var/pref_intimate_belly_piercing_descriptor = null

/// Clears per-character intimate and chastity prefs before loading a slot.
/datum/preferences/proc/reset_intimate_accessory_preferences()
	pref_intimate_genital_piercing = initial(pref_intimate_genital_piercing)
	pref_intimate_genital_insertable = initial(pref_intimate_genital_insertable)
	pref_intimate_rear_piercing = initial(pref_intimate_rear_piercing)
	pref_intimate_rear_insertable = initial(pref_intimate_rear_insertable)
	pref_intimate_breast_piercing = initial(pref_intimate_breast_piercing)
	pref_intimate_breast_insertable = initial(pref_intimate_breast_insertable)
	pref_intimate_mouth_piercing = initial(pref_intimate_mouth_piercing)
	pref_intimate_mouth_insertable = initial(pref_intimate_mouth_insertable)
	pref_intimate_ear_piercing = initial(pref_intimate_ear_piercing)
	pref_intimate_nose_piercing = initial(pref_intimate_nose_piercing)
	pref_intimate_belly_piercing = initial(pref_intimate_belly_piercing)
	pref_intimate_genital_piercing_descriptor = initial(pref_intimate_genital_piercing_descriptor)
	pref_intimate_rear_piercing_descriptor = initial(pref_intimate_rear_piercing_descriptor)
	pref_intimate_breast_piercing_descriptor = initial(pref_intimate_breast_piercing_descriptor)
	pref_intimate_mouth_piercing_descriptor = initial(pref_intimate_mouth_piercing_descriptor)
	pref_intimate_ear_piercing_descriptor = initial(pref_intimate_ear_piercing_descriptor)
	pref_intimate_nose_piercing_descriptor = initial(pref_intimate_nose_piercing_descriptor)
	pref_intimate_belly_piercing_descriptor = initial(pref_intimate_belly_piercing_descriptor)
	pref_chastity_enabled = initial(pref_chastity_enabled)
	pref_chastity_flat = initial(pref_chastity_flat)
	pref_chastity_anal = initial(pref_chastity_anal)
	pref_chastity_spiked = initial(pref_chastity_spiked)
	pref_chastity_locked = initial(pref_chastity_locked)
	pref_chastity_spawn_key = initial(pref_chastity_spawn_key)
	pref_chastity_key_stashes = initial(pref_chastity_key_stashes)
	pref_chastity_random_keys = initial(pref_chastity_random_keys)
	pref_cursed_roundstart_device = initial(pref_cursed_roundstart_device)
	pref_cursed_master_name = initial(pref_cursed_master_name)
	pref_cursed_self_master = initial(pref_cursed_self_master)
	pref_gilded_chastity_recipient = initial(pref_gilded_chastity_recipient)
	pref_cursed_piercing_slot = initial(pref_cursed_piercing_slot)

/// Returns insertable options for the rear slot.
/datum/preferences/proc/get_intimate_rear_insertable_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Butt Plug" = /obj/item/intimate_accessory/rear/plug/iron,
			"Copper Butt Plug" = /obj/item/intimate_accessory/rear/plug/copper,
			"Steel Butt Plug" = /obj/item/intimate_accessory/rear/plug/steel,
			"Bronze Butt Plug" = /obj/item/intimate_accessory/rear/plug/bronze,
			"Silver Butt Plug" = /obj/item/intimate_accessory/rear/plug/silver,
			"Gold Butt Plug" = /obj/item/intimate_accessory/rear/plug/gold,
			"Iron Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/iron,
			"Copper Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/copper,
			"Steel Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/steel,
			"Bronze Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/bronze,
			"Silver Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/silver,
			"Gold Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/gold,
		)
	return options

/// Returns piercing options for the rear slot.
/datum/preferences/proc/get_intimate_rear_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/iron,
			"Copper Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/copper,
			"Steel Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/steel,
			"Bronze Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bronze,
			"Silver Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/silver,
			"Gold Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/gold,
			"Iron Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/iron,
			"Copper Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/copper,
			"Steel Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/steel,
			"Bronze Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/bronze,
			"Silver Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/silver,
			"Gold Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/gold,
		)
	return options

/// Returns insertable options for the genital slot.
/datum/preferences/proc/get_intimate_genital_insertable_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/iron,
			"Copper Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/copper,
			"Steel Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/steel,
			"Bronze Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/bronze,
			"Silver Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/silver,
			"Gold Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/gold,
			"Iron Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/iron,
			"Copper Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/copper,
			"Steel Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/steel,
			"Bronze Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/bronze,
			"Silver Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/silver,
			"Gold Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/gold,
		)

	var/list/filtered_options = list()
	for(var/label in options)
		var/typepath = options[label]
		if(!is_intimate_genital_insertable_allowed_for_prefs(typepath))
			continue
		filtered_options[label] = typepath
	return filtered_options

/// Returns TRUE when this character slot has the anatomy required for a genital insertable.
/datum/preferences/proc/is_intimate_genital_insertable_allowed_for_prefs(typepath)
	if(isnull(typepath))
		return TRUE
	if(istext(typepath))
		typepath = text2path(typepath)
	if(ispath(typepath, /obj/item/intimate_accessory/genital/plug/sounding_rod))
		return has_genital_in_prefs(ORGAN_SLOT_PENIS)
	if(ispath(typepath, /obj/item/intimate_accessory/genital/plug))
		return has_genital_in_prefs(ORGAN_SLOT_VAGINA)
	return TRUE

/// Returns piercing options for the genital slot.
/datum/preferences/proc/get_intimate_genital_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/iron,
			"Copper Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/copper,
			"Steel Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/steel,
			"Bronze Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/bronze,
			"Silver Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/silver,
			"Gold Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/gold,
			"Iron Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/iron,
			"Copper Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/copper,
			"Steel Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/steel,
			"Bronze Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/bronze,
			"Silver Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/silver,
			"Gold Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/gold,
			"Stone Psydonic Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/psydonic,
			"Silver Psydonic Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/psydonic/silver_cross,
			"Golden Psydonic Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/psydonic/golden_cross,
			"Ancient Psydonic Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/psydonic/ancient_cross,
			"Iron Zizite Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/zizite,
			"Ancient Zizite Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/zizite/ancient_cross,
		)
	return options

/// Returns piercing options for the breast slot.
/datum/preferences/proc/get_intimate_breast_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/iron,
			"Copper Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/copper,
			"Steel Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/steel,
			"Bronze Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bronze,
			"Silver Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/silver,
			"Gold Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/gold,
			"Iron Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/iron,
			"Copper Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/copper,
			"Steel Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/steel,
			"Bronze Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/bronze,
			"Silver Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/silver,
			"Gold Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/gold,
			"Stone Psydonic Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/psydonic,
			"Silver Psydonic Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/psydonic/silver_cross,
			"Golden Psydonic Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/psydonic/golden_cross,
			"Ancient Psydonic Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/psydonic/ancient_cross,
			"Iron Zizite Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/zizite,
			"Ancient Zizite Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/zizite/ancient_cross,
		)
	return options

/// Returns insertable options for the breast slot.
/datum/preferences/proc/get_intimate_breast_insertable_options()
	return list("None" = null)

/// Returns piercing options for the mouth slot.
/datum/preferences/proc/get_intimate_mouth_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/iron,
			"Copper Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/copper,
			"Steel Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/steel,
			"Bronze Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/bronze,
			"Silver Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/silver,
			"Gold Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/gold,
		)
	return options

/// Returns insertable options for the mouth slot.
/datum/preferences/proc/get_intimate_mouth_insertable_options()
	return list("None" = null)

/// Returns piercing options for the ear slot.
/datum/preferences/proc/get_intimate_ear_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Earring" = /obj/item/intimate_accessory/piercing/ear/iron,
			"Copper Earring" = /obj/item/intimate_accessory/piercing/ear/copper,
			"Steel Earring" = /obj/item/intimate_accessory/piercing/ear/steel,
			"Bronze Earring" = /obj/item/intimate_accessory/piercing/ear/bronze,
			"Silver Earring" = /obj/item/intimate_accessory/piercing/ear/silver,
			"Gold Earring" = /obj/item/intimate_accessory/piercing/ear/gold,
			"Blacksteel Earring" = /obj/item/intimate_accessory/piercing/ear/blacksteel,
			"Stone Psydonic Earring" = /obj/item/intimate_accessory/piercing/ear/psydonic,
			"Silver Psydonic Earring" = /obj/item/intimate_accessory/piercing/ear/psydonic/silver_cross,
			"Golden Psydonic Earring" = /obj/item/intimate_accessory/piercing/ear/psydonic/golden_cross,
			"Ancient Psydonic Earring" = /obj/item/intimate_accessory/piercing/ear/psydonic/ancient_cross,
			"Iron Zizite Earring" = /obj/item/intimate_accessory/piercing/ear/zizite,
			"Ancient Zizite Earring" = /obj/item/intimate_accessory/piercing/ear/zizite/ancient_cross,
		)
	return options

/// Returns piercing options for the nose slot.
/datum/preferences/proc/get_intimate_nose_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/iron,
			"Copper Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/copper,
			"Steel Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/steel,
			"Bronze Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/bronze,
			"Silver Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/silver,
			"Gold Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/gold,
			"Blacksteel Nose Piercing" = /obj/item/intimate_accessory/piercing/nose/blacksteel,
		)
	return options

/// Returns piercing options for the belly slot.
/datum/preferences/proc/get_intimate_belly_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None" = null,
			"Iron Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/iron,
			"Copper Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/copper,
			"Steel Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/steel,
			"Bronze Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/bronze,
			"Silver Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/silver,
			"Gold Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/gold,
			"Blacksteel Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/blacksteel,
			"Stone Psydonic Belly Piercing" = /obj/item/intimate_accessory/piercing/belly/psydonic,
			"Silver Psydonic Belly Piercing" = /obj/item/intimate_accessory/piercing/belly/psydonic/silver_cross,
			"Golden Psydonic Belly Piercing" = /obj/item/intimate_accessory/piercing/belly/psydonic/golden_cross,
			"Ancient Psydonic Belly Piercing" = /obj/item/intimate_accessory/piercing/belly/psydonic/ancient_cross,
			"Iron Zizite Belly Piercing" = /obj/item/intimate_accessory/piercing/belly/zizite,
			"Ancient Zizite Belly Piercing" = /obj/item/intimate_accessory/piercing/belly/zizite/ancient_cross,
		)
	return options

/// Returns static row definitions used by the lobby TGUI.
/datum/preferences/proc/get_intimate_accessory_slot_defs()
	return list(
		list("key" = "genital_piercing", "label" = "Genital Piercing", "group" = "genital", "pref" = "pref_intimate_genital_piercing"),
		list("key" = "genital_insertable", "label" = "Genital Insertable", "group" = "genital", "pref" = "pref_intimate_genital_insertable"),
		list("key" = "rear_piercing", "label" = "Rear Piercing", "group" = "rear", "pref" = "pref_intimate_rear_piercing"),
		list("key" = "rear_insertable", "label" = "Rear Insertable", "group" = "rear", "pref" = "pref_intimate_rear_insertable"),
		list("key" = "breast_piercing", "label" = "Breast Piercing", "group" = "torso", "pref" = "pref_intimate_breast_piercing"),
		list("key" = "breast_insertable", "label" = "Breast Insertable", "group" = "torso", "pref" = "pref_intimate_breast_insertable"),
		list("key" = "mouth_piercing", "label" = "Mouth Piercing", "group" = "head", "pref" = "pref_intimate_mouth_piercing"),
		list("key" = "mouth_insertable", "label" = "Mouth Insertable", "group" = "head", "pref" = "pref_intimate_mouth_insertable"),
		list("key" = "ear_piercing", "label" = "Ear Piercing", "group" = "head", "pref" = "pref_intimate_ear_piercing"),
		list("key" = "nose_piercing", "label" = "Nose Piercing", "group" = "head", "pref" = "pref_intimate_nose_piercing"),
		list("key" = "belly_piercing", "label" = "Belly Piercing", "group" = "torso", "pref" = "pref_intimate_belly_piercing"),
	)

/// Returns the dropdown option list for one direct slot key.
/datum/preferences/proc/get_intimate_accessory_slot_options(slot_key)
	switch(slot_key)
		if("genital_piercing")
			return get_intimate_genital_piercing_options()
		if("genital_insertable")
			return get_intimate_genital_insertable_options()
		if("rear_piercing")
			return get_intimate_rear_piercing_options()
		if("rear_insertable")
			return get_intimate_rear_insertable_options()
		if("breast_piercing")
			return get_intimate_breast_piercing_options()
		if("breast_insertable")
			return get_intimate_breast_insertable_options()
		if("mouth_piercing")
			return get_intimate_mouth_piercing_options()
		if("mouth_insertable")
			return get_intimate_mouth_insertable_options()
		if("ear_piercing")
			return get_intimate_ear_piercing_options()
		if("nose_piercing")
			return get_intimate_nose_piercing_options()
		if("belly_piercing")
			return get_intimate_belly_piercing_options()
	return list("None" = null)

/// Returns the display label for a selected intimate accessory typepath.
/datum/preferences/proc/get_intimate_option_display_name(typepath)
	if(!typepath)
		return "None"
	if(istext(typepath))
		typepath = text2path(typepath)
	for(var/list/slot_def as anything in get_intimate_accessory_slot_defs())
		var/list/options = get_intimate_accessory_slot_options(slot_def["key"])
		for(var/label in options)
			if(options[label] == typepath)
				return label
	return "[typepath]"

/// Returns the preference var name for a direct intimate accessory slot.
/datum/preferences/proc/get_intimate_accessory_slot_pref_var(slot_key)
	for(var/list/slot_def as anything in get_intimate_accessory_slot_defs())
		if(slot_def["key"] == slot_key)
			return slot_def["pref"]
	return null

/datum/preferences/proc/get_intimate_piercing_descriptor_pref_var(slot_key)
	switch(slot_key)
		if("genital_piercing")
			return "pref_intimate_genital_piercing_descriptor"
		if("rear_piercing")
			return "pref_intimate_rear_piercing_descriptor"
		if("breast_piercing")
			return "pref_intimate_breast_piercing_descriptor"
		if("mouth_piercing")
			return "pref_intimate_mouth_piercing_descriptor"
		if("ear_piercing")
			return "pref_intimate_ear_piercing_descriptor"
		if("nose_piercing")
			return "pref_intimate_nose_piercing_descriptor"
		if("belly_piercing")
			return "pref_intimate_belly_piercing_descriptor"
	return null

/datum/preferences/proc/get_intimate_piercing_descriptor(slot_key)
	var/pref_var = get_intimate_piercing_descriptor_pref_var(slot_key)
	if(!pref_var || !(pref_var in vars))
		return null
	return sanitize_intimate_piercing_descriptor(vars[pref_var])

/datum/preferences/proc/set_intimate_piercing_descriptor(slot_key, descriptor)
	var/pref_var = get_intimate_piercing_descriptor_pref_var(slot_key)
	if(!pref_var || !(pref_var in vars))
		return FALSE
	vars[pref_var] = sanitize_intimate_piercing_descriptor(descriptor)
	return TRUE

/// Reads a selected typepath for a direct intimate accessory slot.
/datum/preferences/proc/get_intimate_accessory_slot_typepath(slot_key)
	var/pref_var = get_intimate_accessory_slot_pref_var(slot_key)
	if(!pref_var || !(pref_var in vars))
		return null
	return vars[pref_var]

/// Sets a direct slot typepath after validating against the slot whitelist.
/datum/preferences/proc/set_intimate_accessory_slot_typepath(slot_key, typepath)
	var/pref_var = get_intimate_accessory_slot_pref_var(slot_key)
	if(!pref_var || !(pref_var in vars))
		return FALSE
	var/list/options = get_intimate_accessory_slot_options(slot_key)
	if(istext(typepath))
		typepath = text2path(typepath)
	var/valid = isnull(typepath)
	if(!valid)
		for(var/label in options)
			if(options[label] == typepath)
				valid = TRUE
				break
	if(!valid)
		return FALSE
	vars[pref_var] = typepath
	return TRUE

/**
 * Sanitizes character-slot intimate accessory and chastity selections after
 * load/import. Saved direct typepaths must still exist in the static option
 * whitelist for their slot; unknown or shelved editor paths are dropped.
 */
/datum/preferences/proc/sanitize_intimate_accessory_preferences()
	for(var/list/slot_def as anything in get_intimate_accessory_slot_defs())
		var/slot_key = slot_def["key"]
		var/pref_var = slot_def["pref"]
		if(!pref_var || !(pref_var in vars))
			continue
		var/typepath = vars[pref_var]
		if(istext(typepath))
			typepath = text2path(typepath)
		if(!set_intimate_accessory_slot_typepath(slot_key, typepath))
			vars[pref_var] = null

		var/descriptor_pref_var = get_intimate_piercing_descriptor_pref_var(slot_key)
		if(descriptor_pref_var && (descriptor_pref_var in vars))
			vars[descriptor_pref_var] = sanitize_intimate_piercing_descriptor(vars[descriptor_pref_var])

	pref_chastity_enabled = sanitize_integer(pref_chastity_enabled, FALSE, TRUE, initial(pref_chastity_enabled))
	pref_chastity_flat = sanitize_integer(pref_chastity_flat, FALSE, TRUE, initial(pref_chastity_flat))
	pref_chastity_anal = sanitize_integer(pref_chastity_anal, FALSE, TRUE, initial(pref_chastity_anal))
	pref_chastity_spiked = sanitize_integer(pref_chastity_spiked, FALSE, TRUE, initial(pref_chastity_spiked))
	pref_chastity_locked = sanitize_integer(pref_chastity_locked, FALSE, TRUE, initial(pref_chastity_locked))
	pref_chastity_spawn_key = sanitize_integer(pref_chastity_spawn_key, FALSE, TRUE, initial(pref_chastity_spawn_key))
	pref_chastity_random_keys = sanitize_integer(pref_chastity_random_keys, FALSE, TRUE, initial(pref_chastity_random_keys))
	pref_chastity_key_stashes = SANITIZE_LIST(pref_chastity_key_stashes)
	if(!is_valid_cursed_roundstart_device(pref_cursed_roundstart_device))
		pref_cursed_roundstart_device = initial(pref_cursed_roundstart_device)
	set_cursed_roundstart_master_name(istext(pref_cursed_master_name) ? pref_cursed_master_name : initial(pref_cursed_master_name))
	pref_cursed_self_master = sanitize_integer(pref_cursed_self_master, FALSE, TRUE, initial(pref_cursed_self_master))
	if(!set_gilded_chastity_recipient(pref_gilded_chastity_recipient))
		pref_gilded_chastity_recipient = initial(pref_gilded_chastity_recipient)
	if(!set_cursed_piercing_slot(pref_cursed_piercing_slot))
		pref_cursed_piercing_slot = initial(pref_cursed_piercing_slot)

/// Builds lobby TGUI rows with option labels and the current selected label.
/datum/preferences/proc/get_intimate_accessory_slot_rows()
	var/list/rows = list()
	for(var/list/slot_def as anything in get_intimate_accessory_slot_defs())
		var/list/options = get_intimate_accessory_slot_options(slot_def["key"])
		var/list/option_names = list()
		var/current_typepath = get_intimate_accessory_slot_typepath(slot_def["key"])
		var/current = "None"
		if(istext(current_typepath))
			current_typepath = text2path(current_typepath)
		for(var/label in options)
			option_names += label
			if(options[label] == current_typepath)
				current = label
		rows += list(list(
			"key" = slot_def["key"],
			"label" = slot_def["label"],
			"group" = slot_def["group"],
			"current" = current,
			"options" = option_names,
			"can_customize_descriptor" = !!get_intimate_piercing_descriptor_pref_var(slot_def["key"]),
			"descriptor" = get_intimate_piercing_descriptor(slot_def["key"]) || "",
		))
	return rows

/**
 * Instantiates and equips selected intimate accessory prefs onto a character.
 *
 * This bypasses click-time `can_attach_target()` checks because lobby-spawned
 * characters do not yet have the same runtime mind/user context. Anatomy,
 * silver weakness, and slot support are still validated before equip.
 */
/datum/preferences/proc/apply_intimate_preferences(mob/living/carbon/human/H)
	if(!istype(H) || !intimate_enabled)
		return

	var/list/slot_prefs = list(
		list("slot" = INTIMATE_SLOT_GENITAL, "path" = pref_intimate_genital_piercing, "descriptor" = pref_intimate_genital_piercing_descriptor),
		list("slot" = INTIMATE_SLOT_GENITAL, "path" = pref_intimate_genital_insertable),
		list("slot" = INTIMATE_SLOT_REAR, "path" = pref_intimate_rear_piercing, "descriptor" = pref_intimate_rear_piercing_descriptor),
		list("slot" = INTIMATE_SLOT_REAR, "path" = pref_intimate_rear_insertable),
		list("slot" = INTIMATE_SLOT_BREAST, "path" = pref_intimate_breast_piercing, "descriptor" = pref_intimate_breast_piercing_descriptor),
		list("slot" = INTIMATE_SLOT_BREAST, "path" = pref_intimate_breast_insertable),
		list("slot" = INTIMATE_SLOT_MOUTH, "path" = pref_intimate_mouth_piercing, "descriptor" = pref_intimate_mouth_piercing_descriptor),
		list("slot" = INTIMATE_SLOT_MOUTH, "path" = pref_intimate_mouth_insertable),
		list("slot" = INTIMATE_SLOT_EAR, "path" = pref_intimate_ear_piercing, "descriptor" = pref_intimate_ear_piercing_descriptor),
		list("slot" = INTIMATE_SLOT_NOSE, "path" = pref_intimate_nose_piercing, "descriptor" = pref_intimate_nose_piercing_descriptor),
		list("slot" = INTIMATE_SLOT_BELLY, "path" = pref_intimate_belly_piercing, "descriptor" = pref_intimate_belly_piercing_descriptor),
	)

	for(var/list/slot_pref as anything in slot_prefs)
		var/item_path = slot_pref["path"]
		if(!item_path || !ispath(item_path, /obj/item/intimate_accessory))
			continue

		if(ispath(item_path, /obj/item/intimate_accessory/genital/plug) && !ispath(item_path, /obj/item/intimate_accessory/genital/plug/sounding_rod))
			if(!H.getorganslot(ORGAN_SLOT_VAGINA))
				continue
		if(ispath(item_path, /obj/item/intimate_accessory/genital/plug/sounding_rod))
			if(!H.getorganslot(ORGAN_SLOT_PENIS))
				continue
		if(initial(item_path:is_silver) && HAS_TRAIT(H, TRAIT_SILVER_WEAK))
			continue

		var/obj/item/intimate_accessory/accessory = new item_path(H)
		if(istype(accessory, /obj/item/intimate_accessory/piercing))
			var/obj/item/intimate_accessory/piercing/piercing = accessory
			piercing.set_custom_piercing_descriptor(slot_pref["descriptor"])
		var/slot = slot_pref["slot"]
		if(!accessory.set_current_intimate_slot(slot))
			qdel(accessory)
			continue
		if(!accessory.attach_intimate_feature(H))
			qdel(accessory)
			continue
		accessory.roundstart_equipped = TRUE
		accessory.sellprice = 1
		accessory.finalize_intimate_equip(H)

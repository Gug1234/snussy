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
/// Per-slot round-start socket keys, keyed by the direct intimate accessory slot key.
/datum/preferences/var/list/pref_intimate_accessory_sockets = null
/// Rear insertable tail socket picker state.
/datum/preferences/var/pref_intimate_rear_insertable_tail_type = /datum/sprite_accessory/tail/cat
/datum/preferences/var/pref_intimate_rear_insertable_tail_colors = null
/datum/preferences/var/pref_intimate_rear_insertable_tail_icon = "catplug"
/// Rear insertable anal bead shape and transferred metal state.
/datum/preferences/var/pref_intimate_rear_insertable_bead_shape = "standard"
/datum/preferences/var/pref_intimate_rear_insertable_bead_metal = "steel"

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
	pref_intimate_accessory_sockets = initial(pref_intimate_accessory_sockets)
	pref_intimate_rear_insertable_tail_type = initial(pref_intimate_rear_insertable_tail_type)
	pref_intimate_rear_insertable_tail_colors = initial(pref_intimate_rear_insertable_tail_colors)
	pref_intimate_rear_insertable_tail_icon = initial(pref_intimate_rear_insertable_tail_icon)
	pref_intimate_rear_insertable_bead_shape = initial(pref_intimate_rear_insertable_bead_shape)
	pref_intimate_rear_insertable_bead_metal = initial(pref_intimate_rear_insertable_bead_metal)
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
			"Blacksteel Butt Plug" = /obj/item/intimate_accessory/rear/plug/blacksteel,
			"Iron Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/iron,
			"Copper Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/copper,
			"Steel Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/steel,
			"Bronze Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/bronze,
			"Silver Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/silver,
			"Gold Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/gold,
			"Blacksteel Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/blacksteel,
			"Standard Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads,
			"Five-Bead Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/fivebeads,
			"Six-Bead Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/sixbeads,
			"Small Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/small12,
			"Small Pyramid Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small,
			"Medium Pyramid Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium,
			"Large Pyramid Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large,
			"Inflexible Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/inflexible,
			"Mixed Small-Medium Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/mixed12,
			"Mixed Medium-Large Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/mixed8,
			"Snaking Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/snake,
			"Giant Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/giant,
			"Glass Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/glass,
			"Spiked Anal Beads" = /obj/item/intimate_accessory/rear/plug/analbeads/spiked,
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
			"Blacksteel Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/blacksteel,
			"Iron Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/iron,
			"Copper Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/copper,
			"Steel Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/steel,
			"Bronze Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/bronze,
			"Silver Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/silver,
			"Gold Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/gold,
			"Blacksteel Bell Rear Piercing" = /obj/item/intimate_accessory/piercing/rear/bell/blacksteel,
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
			"Blacksteel Vaginal Plug" = /obj/item/intimate_accessory/genital/plug/blacksteel,
			"Iron Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/iron,
			"Copper Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/copper,
			"Steel Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/steel,
			"Bronze Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/bronze,
			"Silver Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/silver,
			"Gold Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/gold,
			"Blacksteel Sounding Rod" = /obj/item/intimate_accessory/genital/plug/sounding_rod/blacksteel,
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
			"Blacksteel Genital Piercing" = /obj/item/intimate_accessory/piercing/genital/blacksteel,
			"Iron Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/iron,
			"Copper Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/copper,
			"Steel Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/steel,
			"Bronze Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/bronze,
			"Silver Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/silver,
			"Gold Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/gold,
			"Blacksteel Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/blacksteel,
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
			"Blacksteel Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/blacksteel,
			"Iron Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/iron,
			"Copper Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/copper,
			"Steel Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/steel,
			"Bronze Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/bronze,
			"Silver Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/silver,
			"Gold Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/gold,
			"Blacksteel Bell Nipple Piercing" = /obj/item/intimate_accessory/piercing/breast/bell/blacksteel,
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
			"Blacksteel Tongue Piercing" = /obj/item/intimate_accessory/piercing/tongue/blacksteel,
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

/proc/get_intimate_roundstart_metal_options()
	return list(
		list("key" = "iron", "label" = "Iron", "name" = "iron", "color" = "#9EA48E", "silver" = FALSE),
		list("key" = "copper", "label" = "Copper", "name" = "copper", "color" = "#8C4734", "silver" = FALSE),
		list("key" = "steel", "label" = "Steel", "name" = "steel", "color" = "#9BADB7", "silver" = FALSE),
		list("key" = "bronze", "label" = "Bronze", "name" = "bronze", "color" = "#CBBF9A", "silver" = FALSE),
		list("key" = "silver", "label" = "Silver", "name" = "silver", "color" = "#C6D5E1", "silver" = TRUE),
		list("key" = "gold", "label" = "Gold", "name" = "gold", "color" = "#C4B651", "silver" = FALSE),
		list("key" = "blacksteel", "label" = "Blacksteel", "name" = "blacksteel", "color" = "#A2CBE3", "silver" = FALSE),
		list("key" = "stone", "label" = "Stone", "name" = "stone", "color" = "#9BADB7", "silver" = FALSE),
		list("key" = "wood", "label" = "Wood", "name" = "wooden", "color" = "#8F6A43", "silver" = FALSE),
		list("key" = "golden", "label" = "Golden", "name" = "golden", "color" = "#C4B651", "silver" = FALSE),
		list("key" = "ancient", "label" = "Ancient", "name" = "ancient", "color" = "#BB9696", "silver" = FALSE),
	)

/proc/get_intimate_roundstart_socket_options()
	return list(
		list("key" = "none", "label" = "None", "descriptor" = null, "color" = "#FFFFFF", "type" = null),
		list("key" = "ruby", "label" = "Rontz", "descriptor" = "rontz", "color" = "#B4142C", "type" = /obj/item/roguegem/ruby),
		list("key" = "green", "label" = "Gemerald", "descriptor" = "gemerald", "color" = "#2FAE5A", "type" = /obj/item/roguegem/green),
		list("key" = "jade", "label" = "Jade", "descriptor" = "jade", "color" = "#2FAE5A", "type" = /obj/item/roguegem/jade),
		list("key" = "blue", "label" = "Blortz", "descriptor" = "blortz", "color" = "#60C9FF", "type" = /obj/item/roguegem/blue),
		list("key" = "yellow", "label" = "Toper", "descriptor" = "toper", "color" = "#F0BE38", "type" = /obj/item/roguegem/yellow),
		list("key" = "amber", "label" = "Amber", "descriptor" = "amber", "color" = "#F0BE38", "type" = /obj/item/roguegem/amber),
		list("key" = "violet", "label" = "Saffira", "descriptor" = "saffira", "color" = "#9A5CFF", "type" = /obj/item/roguegem/violet),
		list("key" = "amethyst", "label" = "Amythortz", "descriptor" = "amythortz", "color" = "#9A5CFF", "type" = /obj/item/roguegem/amethyst),
		list("key" = "diamond", "label" = "Dorpel", "descriptor" = "dorpel", "color" = "#EAF3FF", "type" = /obj/item/roguegem/diamond),
		list("key" = "opal", "label" = "Opal", "descriptor" = "opal", "color" = "#EAF3FF", "type" = /obj/item/roguegem/opal),
		list("key" = "oyster", "label" = "Fossilized Clam", "descriptor" = "fossilized clam", "color" = "#EAF3FF", "type" = /obj/item/roguegem/oyster),
		list("key" = "onyxa", "label" = "Onyxa", "descriptor" = "onyxa", "color" = "#1D2130", "type" = /obj/item/roguegem/onyxa),
		list("key" = "coral", "label" = "Heartstone", "descriptor" = "heartstone", "color" = "#FF6E66", "type" = /obj/item/roguegem/coral),
		list("key" = "turq", "label" = "Cerulite", "descriptor" = "cerulite", "color" = "#2CC6C8", "type" = /obj/item/roguegem/turq),
	)

/proc/get_intimate_roundstart_rear_bead_metal_options()
	var/list/options = list()
	for(var/list/metal_option as anything in get_intimate_roundstart_metal_options())
		if(!(metal_option["key"] in list("iron", "copper", "steel", "bronze", "silver", "gold", "blacksteel")))
			continue
		options += list(metal_option.Copy())
	return options

/proc/get_intimate_roundstart_rear_bead_shape_options()
	return list(
		list("key" = "standard", "label" = "Standard (4 beads)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "five", "label" = "Five Beads (5)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/fivebeads, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "six", "label" = "Six Beads (6)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/sixbeads, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "small12", "label" = "Small (12 beads)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/small12, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "pyramid_small", "label" = "Small Pyramid (4 graduating)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_small, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "pyramid_medium", "label" = "Medium Pyramid (5 graduating)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_medium, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "pyramid_large", "label" = "Large Pyramid (8 graduating)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/pyramid_large, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "inflexible", "label" = "Inflexible (4 rigid)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/inflexible, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "mixed12", "label" = "Mixed Small+Medium (12)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/mixed12, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "mixed8", "label" = "Mixed Medium+Large (8)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/mixed8, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "snake", "label" = "Snake (27 beads)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/snake, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "giant", "label" = "Giant (6 fist-sized)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/giant, "extreme" = FALSE, "tail_socket" = TRUE),
		list("key" = "glass", "label" = "Glass (4, fragile)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/glass, "extreme" = TRUE, "tail_socket" = FALSE),
		list("key" = "spiked", "label" = "Spiked (6, extreme)", "type" = /obj/item/intimate_accessory/rear/plug/analbeads/spiked, "extreme" = TRUE, "tail_socket" = FALSE),
	)

/proc/find_intimate_roundstart_option(list/options, option_key)
	if(!option_key)
		return null
	for(var/list/option as anything in options)
		if(option["key"] == option_key)
			return option
	return null

/datum/preferences/proc/get_intimate_roundstart_metal_option(metal_key)
	var/list/option = find_intimate_roundstart_option(get_intimate_roundstart_metal_options(), metal_key)
	if(option)
		return option.Copy()
	return null

/datum/preferences/proc/get_intimate_accessory_type_key(typepath)
	if(!typepath)
		return "none"
	if(istext(typepath))
		typepath = text2path(typepath)
	if(ispath(typepath, /obj/item/intimate_accessory/rear/plug/analbeads))
		return "anal_beads"
	if(ispath(typepath, /obj/item/intimate_accessory/rear/plug))
		return "butt_plug"
	if(ispath(typepath, /obj/item/intimate_accessory/genital/plug/sounding_rod))
		return "sounding_rod"
	if(ispath(typepath, /obj/item/intimate_accessory/genital/plug))
		return "vaginal_plug"
	if(ispath(typepath, /obj/item/intimate_accessory/piercing/genital/psydonic) || ispath(typepath, /obj/item/intimate_accessory/piercing/breast/psydonic) || ispath(typepath, /obj/item/intimate_accessory/piercing/tongue/psydonic) || ispath(typepath, /obj/item/intimate_accessory/piercing/ear/psydonic) || ispath(typepath, /obj/item/intimate_accessory/piercing/belly/psydonic))
		return "psydonic"
	if(ispath(typepath, /obj/item/intimate_accessory/piercing/genital/zizite) || ispath(typepath, /obj/item/intimate_accessory/piercing/breast/zizite) || ispath(typepath, /obj/item/intimate_accessory/piercing/tongue/zizite) || ispath(typepath, /obj/item/intimate_accessory/piercing/ear/zizite) || ispath(typepath, /obj/item/intimate_accessory/piercing/belly/zizite))
		return "zizite"
	if(ispath(typepath, /obj/item/intimate_accessory/piercing))
		return "piercing"
	return null

/datum/preferences/proc/get_intimate_accessory_type_label(type_key)
	switch(type_key)
		if("none")
			return "None"
		if("piercing")
			return "Piercing"
		if("psydonic")
			return "Psydonic"
		if("zizite")
			return "Zizite"
		if("vaginal_plug")
			return "Vaginal Plug"
		if("sounding_rod")
			return "Sounding Rod"
		if("butt_plug")
			return "Butt Plug"
		if("anal_beads")
			return "Anal Beads"
		if("tail_plug")
			return "Tail Plug"
		if("tail_beads")
			return "Tail Beads"
	return "[type_key]"

/datum/preferences/proc/get_intimate_accessory_metal_key(typepath)
	if(!typepath)
		return null
	if(istext(typepath))
		typepath = text2path(typepath)
	var/metal_name = initial(typepath:intimate_metal_name)
	if(!istext(metal_name))
		return null
	metal_name = lowertext(metal_name)
	switch(metal_name)
		if("wooden")
			return "wood"
	return metal_name

/datum/preferences/proc/get_intimate_standard_anal_beads_path(metal_key)
	switch(metal_key)
		if("iron")
			return /obj/item/intimate_accessory/rear/plug/analbeads/iron
		if("copper")
			return /obj/item/intimate_accessory/rear/plug/analbeads/copper
		if("bronze")
			return /obj/item/intimate_accessory/rear/plug/analbeads/bronze
		if("silver")
			return /obj/item/intimate_accessory/rear/plug/analbeads/silver
		if("gold")
			return /obj/item/intimate_accessory/rear/plug/analbeads/gold
		if("blacksteel")
			return /obj/item/intimate_accessory/rear/plug/analbeads/blacksteel
	return /obj/item/intimate_accessory/rear/plug/analbeads/steel

/datum/preferences/proc/get_intimate_accessory_rear_bead_shape_option(bead_shape_key)
	var/list/shape_option = find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_shape_options(), bead_shape_key)
	if(shape_option)
		return shape_option.Copy()
	return null

/datum/preferences/proc/get_intimate_accessory_rear_bead_shape_key(typepath = null)
	if(!typepath)
		typepath = get_intimate_accessory_slot_typepath("rear_insertable")
	if(istext(typepath))
		typepath = text2path(typepath)
	for(var/list/shape_option as anything in get_intimate_roundstart_rear_bead_shape_options())
		if(typepath == shape_option["type"])
			return shape_option["key"]
	if(ispath(typepath, /obj/item/intimate_accessory/rear/plug/analbeads))
		return "standard"
	return pref_intimate_rear_insertable_bead_shape || "standard"

/datum/preferences/proc/get_intimate_accessory_rear_bead_metal_key(typepath = null)
	var/derived_metal = get_intimate_accessory_metal_key(typepath || get_intimate_accessory_slot_typepath("rear_insertable"))
	if(find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_metal_options(), derived_metal))
		return derived_metal
	var/list/pref_metal = find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_metal_options(), pref_intimate_rear_insertable_bead_metal)
	if(pref_metal)
		return pref_metal["key"]
	return "steel"

/datum/preferences/proc/get_intimate_accessory_rear_bead_shape_options(for_tail_socket = FALSE)
	var/list/shape_options = list()
	for(var/list/shape_option as anything in get_intimate_roundstart_rear_bead_shape_options())
		var/list/copied_option = shape_option.Copy()
		if(copied_option["extreme"] && !extreme_erp)
			copied_option["disabled"] = TRUE
			copied_option["tooltip"] = "Requires extreme ERP to be enabled."
		if(for_tail_socket && !copied_option["tail_socket"])
			copied_option["disabled"] = TRUE
			copied_option["tooltip"] = "This bead shape has no socket for a fake tail."
		shape_options += list(copied_option)
	return shape_options

/datum/preferences/proc/get_intimate_accessory_rear_bead_typepath(bead_shape_key = null, metal_key = null)
	if(!bead_shape_key)
		bead_shape_key = get_intimate_accessory_rear_bead_shape_key()
	if(!metal_key)
		metal_key = get_intimate_accessory_rear_bead_metal_key()
	var/list/shape_option = get_intimate_accessory_rear_bead_shape_option(bead_shape_key)
	if(!shape_option)
		shape_option = get_intimate_accessory_rear_bead_shape_option("standard")
	if(shape_option["key"] == "standard")
		return get_intimate_standard_anal_beads_path(metal_key)
	return shape_option["type"]

/datum/preferences/proc/get_intimate_accessory_slot_current_type_key(slot_key, typepath = null)
	var/type_key = get_intimate_accessory_type_key(typepath || get_intimate_accessory_slot_typepath(slot_key))
	if(slot_key == "rear_insertable" && get_intimate_accessory_slot_socket(slot_key) == "tail")
		if(type_key == "butt_plug")
			return "tail_plug"
		if(type_key == "anal_beads")
			return "tail_beads"
	return type_key

/datum/preferences/proc/is_intimate_accessory_bell_typepath(typepath)
	if(!typepath)
		return FALSE
	if(istext(typepath))
		typepath = text2path(typepath)
	return ispath(typepath, /obj/item/intimate_accessory/piercing/genital/bell) || ispath(typepath, /obj/item/intimate_accessory/piercing/rear/bell) || ispath(typepath, /obj/item/intimate_accessory/piercing/breast/bell)

/datum/preferences/proc/intimate_accessory_type_supports_roundstart_socket(typepath)
	if(!typepath)
		return FALSE
	var/type_key = get_intimate_accessory_type_key(typepath)
	if(type_key in list("psydonic", "zizite"))
		return FALSE
	return ispath(typepath, /obj/item/intimate_accessory/piercing) || ispath(typepath, /obj/item/intimate_accessory/genital/plug) || ispath(typepath, /obj/item/intimate_accessory/rear/plug)

/datum/preferences/proc/has_tail_in_prefs()
	return has_genital_in_prefs(ORGAN_SLOT_TAIL)

/datum/preferences/proc/get_intimate_accessory_slot_type_options(slot_key)
	var/list/type_options = list(list("key" = "none", "label" = "None"))
	var/list/seen_type_keys = list("none" = TRUE)
	var/list/options = get_intimate_accessory_slot_options(slot_key)
	for(var/label in options)
		var/typepath = options[label]
		if(!typepath)
			continue
		var/type_key = get_intimate_accessory_type_key(typepath)
		if(!type_key || seen_type_keys[type_key])
			continue
		seen_type_keys[type_key] = TRUE
		type_options += list(list(
			"key" = type_key,
			"label" = get_intimate_accessory_type_label(type_key),
		))
	if(slot_key == "rear_insertable")
		var/tail_disabled = has_tail_in_prefs()
		type_options += list(list(
			"key" = "tail_plug",
			"label" = get_intimate_accessory_type_label("tail_plug"),
			"disabled" = tail_disabled,
			"tooltip" = tail_disabled ? "Unavailable while this character has a natural tail." : null,
		))
		type_options += list(list(
			"key" = "tail_beads",
			"label" = get_intimate_accessory_type_label("tail_beads"),
			"disabled" = tail_disabled,
			"tooltip" = tail_disabled ? "Unavailable while this character has a natural tail." : null,
		))
	return type_options

/datum/preferences/proc/get_intimate_accessory_slot_metal_options(slot_key, type_key = null, has_bell = null)
	if(!type_key)
		type_key = get_intimate_accessory_slot_current_type_key(slot_key)
	if(slot_key == "rear_insertable" && (type_key == "anal_beads" || type_key == "tail_beads"))
		return get_intimate_roundstart_rear_bead_metal_options()
	if(type_key == "tail_plug")
		type_key = "butt_plug"
	var/list/metal_options = list()
	var/list/seen_metal_keys = list()
	var/list/options = get_intimate_accessory_slot_options(slot_key)
	for(var/label in options)
		var/typepath = options[label]
		if(!typepath)
			continue
		if(get_intimate_accessory_type_key(typepath) != type_key)
			continue
		if(!isnull(has_bell) && is_intimate_accessory_bell_typepath(typepath) != !!has_bell)
			continue
		var/metal_key = get_intimate_accessory_metal_key(typepath)
		if(!metal_key || seen_metal_keys[metal_key])
			continue
		var/list/metal_option = get_intimate_roundstart_metal_option(metal_key)
		if(!metal_option)
			continue
		seen_metal_keys[metal_key] = TRUE
		metal_options += list(metal_option)
	return metal_options

/datum/preferences/proc/get_intimate_accessory_path_for_components(slot_key, type_key, metal_key, has_bell = FALSE)
	if(!type_key || type_key == "none")
		return null
	if(type_key == "tail_plug")
		type_key = "butt_plug"
	if(type_key == "tail_beads")
		type_key = "anal_beads"
	if(slot_key == "rear_insertable" && type_key == "anal_beads")
		return get_intimate_accessory_rear_bead_typepath(metal_key = metal_key)
	var/list/options = get_intimate_accessory_slot_options(slot_key)
	for(var/label in options)
		var/typepath = options[label]
		if(!typepath)
			continue
		if(get_intimate_accessory_type_key(typepath) != type_key)
			continue
		if(get_intimate_accessory_metal_key(typepath) != metal_key)
			continue
		if(is_intimate_accessory_bell_typepath(typepath) != !!has_bell)
			continue
		return typepath
	return null

/datum/preferences/proc/intimate_accessory_slot_can_bell(slot_key, type_key = null)
	if(!type_key)
		type_key = get_intimate_accessory_type_key(get_intimate_accessory_slot_typepath(slot_key))
	if(type_key != "piercing")
		return FALSE
	var/list/options = get_intimate_accessory_slot_options(slot_key)
	for(var/label in options)
		var/typepath = options[label]
		if(typepath && get_intimate_accessory_type_key(typepath) == type_key && is_intimate_accessory_bell_typepath(typepath))
			return TRUE
	return FALSE

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

/datum/preferences/proc/get_intimate_accessory_slot_socket(slot_key)
	if(!pref_intimate_accessory_sockets)
		return "none"
	var/socket_key = pref_intimate_accessory_sockets[slot_key]
	if(!istext(socket_key) || !length(socket_key))
		return "none"
	var/list/options = get_intimate_accessory_slot_socket_options(slot_key)
	for(var/list/option as anything in options)
		if(option["key"] == socket_key && !option["disabled"])
			return socket_key
	return "none"

/datum/preferences/proc/get_intimate_accessory_tail_socket_options()
	var/list/tail_options = list()
	var/datum/customizer_choice/organ/tail/anthro/tail_choice = new
	for(var/accessory_type in tail_choice.sprite_accessories)
		var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(accessory_type)
		if(!accessory)
			continue
		tail_options += list(list(
			"key" = "[accessory_type]",
			"label" = accessory.name,
			"type" = accessory_type,
		))
	qdel(tail_choice)
	return tail_options

/datum/preferences/proc/is_intimate_accessory_tail_socket_type(tail_type)
	if(istext(tail_type))
		tail_type = text2path(tail_type)
	if(!ispath(tail_type, /datum/sprite_accessory/tail))
		return FALSE
	for(var/list/option as anything in get_intimate_accessory_tail_socket_options())
		if(option["type"] == tail_type)
			return TRUE
	return FALSE

/datum/preferences/proc/get_intimate_accessory_tail_icon_options()
	return list(
		list("key" = "dogplug", "label" = "Dog"),
		list("key" = "catplug", "label" = "Cat"),
		list("key" = "ratplug", "label" = "Rat"),
		list("key" = "lizardplug", "label" = "Lizard"),
		list("key" = "rabbitplug", "label" = "Bunny"),
	)

/datum/preferences/proc/is_intimate_accessory_tail_icon(icon_key)
	for(var/list/option as anything in get_intimate_accessory_tail_icon_options())
		if(option["key"] == icon_key)
			return TRUE
	return FALSE

/datum/preferences/proc/get_intimate_accessory_tail_socket_colors(tail_type = null, tail_colors = null)
	if(!tail_type)
		tail_type = pref_intimate_rear_insertable_tail_type
	if(istext(tail_type))
		tail_type = text2path(tail_type)
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_type)
	if(!accessory)
		return "#FFFFFF"
	if(!tail_colors)
		tail_colors = pref_intimate_rear_insertable_tail_colors
	if(!tail_colors)
		tail_colors = accessory.get_default_colors(color_key_source_list_from_prefs(src))
	return accessory.sanitize_color_string(tail_colors)

/datum/preferences/proc/get_intimate_accessory_tail_socket_color_list()
	var/tail_type = pref_intimate_rear_insertable_tail_type
	if(istext(tail_type))
		tail_type = text2path(tail_type)
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_type)
	var/color_string = get_intimate_accessory_tail_socket_colors(tail_type)
	var/list/colors = color_string_to_list(color_string)
	if(!colors)
		colors = list()
	var/color_count = max(1, accessory?.color_keys || 1)
	while(length(colors) < color_count)
		colors += "#FFFFFF"
	return colors

/datum/preferences/proc/get_intimate_accessory_tail_socket_primary_color()
	var/list/colors = get_intimate_accessory_tail_socket_color_list()
	if(length(colors) >= 1)
		return colors[1]
	return "#FFFFFF"

/datum/preferences/proc/set_intimate_accessory_tail_socket(slot_key, tail_type, tail_colors = null, tail_icon = null)
	if(slot_key != "rear_insertable")
		return FALSE
	if(istext(tail_type))
		tail_type = text2path(tail_type)
	if(!is_intimate_accessory_tail_socket_type(tail_type))
		return FALSE
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_type)
	if(!accessory)
		return FALSE
	var/clean_colors = get_intimate_accessory_tail_socket_colors(tail_type, tail_colors)
	if(!clean_colors)
		return FALSE
	if(!tail_icon)
		tail_icon = pref_intimate_rear_insertable_tail_icon || initial(pref_intimate_rear_insertable_tail_icon)
	if(!is_intimate_accessory_tail_icon(tail_icon))
		return FALSE
	pref_intimate_rear_insertable_tail_type = tail_type
	pref_intimate_rear_insertable_tail_colors = clean_colors
	pref_intimate_rear_insertable_tail_icon = tail_icon
	return TRUE

/datum/preferences/proc/set_intimate_accessory_tail_socket_color(slot_key, color_index, color)
	if(slot_key != "rear_insertable")
		return FALSE
	var/list/colors = get_intimate_accessory_tail_socket_color_list()
	color_index = sanitize_integer(color_index, 1, length(colors), 1)
	var/clean_color = sanitize_hexcolor(color, 6, TRUE)
	if(!clean_color)
		return FALSE
	colors[color_index] = clean_color
	return set_intimate_accessory_tail_socket(slot_key, pref_intimate_rear_insertable_tail_type, color_list_to_string(colors), pref_intimate_rear_insertable_tail_icon)

/datum/preferences/proc/get_intimate_accessory_slot_socket_options(slot_key)
	var/list/socket_options = list(list("key" = "none", "label" = "None", "descriptor" = null, "color" = "#FFFFFF"))
	var/typepath = get_intimate_accessory_slot_typepath(slot_key)
	if(!intimate_accessory_type_supports_roundstart_socket(typepath))
		return socket_options
	for(var/list/socket_option as anything in get_intimate_roundstart_socket_options())
		if(socket_option["key"] == "none")
			continue
		socket_options += list(socket_option.Copy())
	if(slot_key == "rear_insertable" && ispath(typepath, /obj/item/intimate_accessory/rear/plug))
		socket_options += list(list(
			"key" = "tail",
			"label" = "Tail",
			"descriptor" = "tail",
			"color" = get_intimate_accessory_tail_socket_primary_color(),
			"disabled" = has_tail_in_prefs(),
			"tooltip" = has_tail_in_prefs() ? "Unavailable while this character has a natural tail." : null,
		))
	return socket_options

/datum/preferences/proc/set_intimate_accessory_slot_socket(slot_key, socket_key)
	if(!istext(socket_key) || !length(socket_key) || socket_key == "none")
		if(pref_intimate_accessory_sockets)
			pref_intimate_accessory_sockets[slot_key] = null
		return TRUE
	var/list/socket_options = get_intimate_accessory_slot_socket_options(slot_key)
	for(var/list/socket_option as anything in socket_options)
		if(socket_option["key"] != socket_key)
			continue
		if(socket_option["disabled"])
			return FALSE
		LAZYINITLIST(pref_intimate_accessory_sockets)
		pref_intimate_accessory_sockets[slot_key] = socket_key
		return TRUE
	return FALSE

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
	if(!typepath || !intimate_accessory_type_supports_roundstart_socket(typepath))
		set_intimate_accessory_slot_socket(slot_key, "none")
	return TRUE

/datum/preferences/proc/set_intimate_accessory_rear_bead_design(type_key, metal_key = null)
	if(!(type_key in list("anal_beads", "tail_beads")))
		return FALSE
	var/for_tail_socket = (type_key == "tail_beads")
	if(for_tail_socket && has_tail_in_prefs())
		return FALSE

	var/bead_shape_key = pref_intimate_rear_insertable_bead_shape || get_intimate_accessory_rear_bead_shape_key()
	var/list/shape_option = find_intimate_roundstart_option(get_intimate_accessory_rear_bead_shape_options(for_tail_socket), bead_shape_key)
	if(!shape_option || shape_option["disabled"])
		if(!for_tail_socket)
			return FALSE
		bead_shape_key = "standard"
		shape_option = find_intimate_roundstart_option(get_intimate_accessory_rear_bead_shape_options(for_tail_socket), bead_shape_key)
		if(!shape_option || shape_option["disabled"])
			return FALSE

	var/list/metal_option = find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_metal_options(), metal_key)
	if(!metal_option)
		metal_option = find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_metal_options(), get_intimate_accessory_rear_bead_metal_key())
	if(!metal_option)
		metal_option = get_intimate_roundstart_rear_bead_metal_options()[1]
	if(!metal_option)
		return FALSE

	pref_intimate_rear_insertable_bead_shape = shape_option["key"]
	pref_intimate_rear_insertable_bead_metal = metal_option["key"]
	var/bead_typepath = get_intimate_accessory_rear_bead_typepath(pref_intimate_rear_insertable_bead_shape, pref_intimate_rear_insertable_bead_metal)
	if(!set_intimate_accessory_slot_typepath("rear_insertable", bead_typepath))
		return FALSE
	return set_intimate_accessory_slot_socket("rear_insertable", for_tail_socket ? "tail" : "none")

/datum/preferences/proc/set_intimate_accessory_rear_bead_shape(bead_shape_key)
	var/current_type = get_intimate_accessory_slot_current_type_key("rear_insertable")
	var/for_tail_socket = (current_type == "tail_beads")
	var/list/shape_option = find_intimate_roundstart_option(get_intimate_accessory_rear_bead_shape_options(for_tail_socket), bead_shape_key)
	if(!shape_option || shape_option["disabled"])
		return FALSE
	pref_intimate_rear_insertable_bead_shape = shape_option["key"]
	if(current_type in list("anal_beads", "tail_beads"))
		return set_intimate_accessory_rear_bead_design(current_type)
	return TRUE

/datum/preferences/proc/set_intimate_accessory_slot_design(slot_key, type_key = null, metal_key = null, has_bell = null)
	if(!type_key)
		type_key = get_intimate_accessory_slot_current_type_key(slot_key)
	if(!type_key || type_key == "none")
		return set_intimate_accessory_slot_typepath(slot_key, null)
	if(slot_key == "rear_insertable")
		if(type_key == "tail_plug")
			if(has_tail_in_prefs())
				return FALSE
			if(!set_intimate_accessory_slot_design(slot_key, type_key = "butt_plug", metal_key = metal_key, has_bell = FALSE))
				return FALSE
			return set_intimate_accessory_slot_socket(slot_key, "tail")
		if(type_key == "anal_beads" || type_key == "tail_beads")
			return set_intimate_accessory_rear_bead_design(type_key, metal_key)
	if(isnull(has_bell))
		has_bell = is_intimate_accessory_bell_typepath(get_intimate_accessory_slot_typepath(slot_key))
	if(!intimate_accessory_slot_can_bell(slot_key, type_key))
		has_bell = FALSE
	var/list/metal_options = get_intimate_accessory_slot_metal_options(slot_key, type_key, has_bell)
	if(!length(metal_options) && has_bell)
		has_bell = FALSE
		metal_options = get_intimate_accessory_slot_metal_options(slot_key, type_key, has_bell)
	if(!length(metal_options))
		return FALSE
	var/current_metal = get_intimate_accessory_metal_key(get_intimate_accessory_slot_typepath(slot_key))
	var/metal_is_valid = FALSE
	if(metal_key)
		for(var/list/metal_option as anything in metal_options)
			if(metal_option["key"] == metal_key)
				metal_is_valid = TRUE
				break
	if(!metal_is_valid && current_metal)
		for(var/list/metal_option as anything in metal_options)
			if(metal_option["key"] == current_metal)
				metal_key = current_metal
				metal_is_valid = TRUE
				break
	if(!metal_is_valid)
		var/list/first_metal = metal_options[1]
		metal_key = first_metal["key"]
	var/resolved_path = get_intimate_accessory_path_for_components(slot_key, type_key, metal_key, has_bell)
	if(!resolved_path)
		return FALSE
	return set_intimate_accessory_slot_typepath(slot_key, resolved_path)

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

	pref_intimate_accessory_sockets = SANITIZE_LIST(pref_intimate_accessory_sockets)
	if(!set_intimate_accessory_tail_socket("rear_insertable", pref_intimate_rear_insertable_tail_type, pref_intimate_rear_insertable_tail_colors, pref_intimate_rear_insertable_tail_icon))
		set_intimate_accessory_tail_socket("rear_insertable", initial(pref_intimate_rear_insertable_tail_type), initial(pref_intimate_rear_insertable_tail_colors), initial(pref_intimate_rear_insertable_tail_icon))
	pref_intimate_rear_insertable_bead_shape = get_intimate_accessory_rear_bead_shape_key(pref_intimate_rear_insertable)
	pref_intimate_rear_insertable_bead_metal = get_intimate_accessory_rear_bead_metal_key(pref_intimate_rear_insertable)
	var/current_rear_type = get_intimate_accessory_slot_current_type_key("rear_insertable", pref_intimate_rear_insertable)
	if(current_rear_type in list("anal_beads", "tail_beads"))
		if(!set_intimate_accessory_rear_bead_design(current_rear_type, pref_intimate_rear_insertable_bead_metal))
			pref_intimate_rear_insertable_bead_shape = "standard"
			set_intimate_accessory_rear_bead_design(current_rear_type, pref_intimate_rear_insertable_bead_metal)
	for(var/list/slot_def as anything in get_intimate_accessory_slot_defs())
		var/slot_key = slot_def["key"]
		var/socket_key = pref_intimate_accessory_sockets ? pref_intimate_accessory_sockets[slot_key] : null
		if(socket_key && !set_intimate_accessory_slot_socket(slot_key, socket_key))
			set_intimate_accessory_slot_socket(slot_key, "none")

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
		var/current_type = get_intimate_accessory_slot_current_type_key(slot_def["key"], current_typepath)
		var/current_bell = is_intimate_accessory_bell_typepath(current_typepath)
		var/current_metal = (slot_def["key"] == "rear_insertable" && (current_type == "anal_beads" || current_type == "tail_beads")) ? get_intimate_accessory_rear_bead_metal_key(current_typepath) : get_intimate_accessory_metal_key(current_typepath)
		var/can_bell = intimate_accessory_slot_can_bell(slot_def["key"], current_type)
		var/show_socket = !!(current_typepath && intimate_accessory_type_supports_roundstart_socket(current_typepath) && !(current_type in list("tail_plug", "tail_beads")))
		var/show_tail_picker = !!(current_type in list("tail_plug", "tail_beads"))
		var/show_bead_shape = !!(current_type in list("anal_beads", "tail_beads"))
		rows += list(list(
			"key" = slot_def["key"],
			"label" = slot_def["label"],
			"group" = slot_def["group"],
			"current" = current,
			"options" = option_names,
			"current_type" = current_type || "none",
			"current_metal" = current_metal,
			"type_options" = get_intimate_accessory_slot_type_options(slot_def["key"]),
			"metal_options" = get_intimate_accessory_slot_metal_options(slot_def["key"], current_type, current_bell),
			"current_socket" = get_intimate_accessory_slot_socket(slot_def["key"]),
			"socket_options" = get_intimate_accessory_slot_socket_options(slot_def["key"]),
			"show_socket" = show_socket,
			"can_bell" = can_bell,
			"has_bell" = current_bell,
			"show_bead_shape" = show_bead_shape,
			"current_bead_shape" = show_bead_shape ? get_intimate_accessory_rear_bead_shape_key(current_typepath) : null,
			"bead_shape_options" = show_bead_shape ? get_intimate_accessory_rear_bead_shape_options(current_type == "tail_beads") : list(),
			"show_tail_picker" = show_tail_picker,
			"tail_options" = (slot_def["key"] == "rear_insertable") ? get_intimate_accessory_tail_socket_options() : list(),
			"tail_icon_options" = (slot_def["key"] == "rear_insertable") ? get_intimate_accessory_tail_icon_options() : list(),
			"tail_current_type" = (slot_def["key"] == "rear_insertable") ? "[pref_intimate_rear_insertable_tail_type]" : null,
			"tail_current_colors" = (slot_def["key"] == "rear_insertable") ? get_intimate_accessory_tail_socket_color_list() : list(),
			"tail_current_icon" = (slot_def["key"] == "rear_insertable") ? pref_intimate_rear_insertable_tail_icon : null,
			"tail_blocked" = (slot_def["key"] == "rear_insertable") ? has_tail_in_prefs() : FALSE,
			"can_customize_descriptor" = !!get_intimate_piercing_descriptor_pref_var(slot_def["key"]),
			"descriptor" = get_intimate_piercing_descriptor(slot_def["key"]) || "",
		))
	return rows

/datum/preferences/proc/apply_intimate_accessory_socket_preference(slot_key, obj/item/intimate_accessory/accessory, mob/living/carbon/human/H)
	if(!slot_key || !accessory)
		return TRUE
	var/socket_key = get_intimate_accessory_slot_socket(slot_key)
	if(!socket_key || socket_key == "none")
		return TRUE
	if(socket_key == "tail")
		if(H?.getorganslot(ORGAN_SLOT_TAIL))
			return FALSE
		if(!istype(accessory, /obj/item/intimate_accessory/rear/plug))
			return FALSE
		var/obj/item/intimate_accessory/rear/plug/rear_plug = accessory
		return rear_plug.apply_roundstart_tail_socket(pref_intimate_rear_insertable_tail_type, get_intimate_accessory_tail_socket_colors(), pref_intimate_rear_insertable_tail_icon)
	return accessory.apply_roundstart_gem_socket(socket_key)

/datum/preferences/proc/apply_intimate_rear_bead_metal_preference(obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(!beads)
		return FALSE
	var/list/metal_option = find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_metal_options(), get_intimate_accessory_rear_bead_metal_key(beads.type))
	if(!metal_option)
		return FALSE
	if(!istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/spiked))
		if(!istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/glass))
			beads.intimate_metal_name = metal_option["name"]
		beads.intimate_metal_color = metal_option["color"]
		beads.is_silver = !!metal_option["silver"]
	beads.refresh_rear_plug_state()
	return TRUE

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
		list("key" = "genital_piercing", "slot" = INTIMATE_SLOT_GENITAL, "path" = pref_intimate_genital_piercing, "descriptor" = pref_intimate_genital_piercing_descriptor),
		list("key" = "genital_insertable", "slot" = INTIMATE_SLOT_GENITAL, "path" = pref_intimate_genital_insertable),
		list("key" = "rear_piercing", "slot" = INTIMATE_SLOT_REAR, "path" = pref_intimate_rear_piercing, "descriptor" = pref_intimate_rear_piercing_descriptor),
		list("key" = "rear_insertable", "slot" = INTIMATE_SLOT_REAR, "path" = pref_intimate_rear_insertable),
		list("key" = "breast_piercing", "slot" = INTIMATE_SLOT_BREAST, "path" = pref_intimate_breast_piercing, "descriptor" = pref_intimate_breast_piercing_descriptor),
		list("key" = "breast_insertable", "slot" = INTIMATE_SLOT_BREAST, "path" = pref_intimate_breast_insertable),
		list("key" = "mouth_piercing", "slot" = INTIMATE_SLOT_MOUTH, "path" = pref_intimate_mouth_piercing, "descriptor" = pref_intimate_mouth_piercing_descriptor),
		list("key" = "mouth_insertable", "slot" = INTIMATE_SLOT_MOUTH, "path" = pref_intimate_mouth_insertable),
		list("key" = "ear_piercing", "slot" = INTIMATE_SLOT_EAR, "path" = pref_intimate_ear_piercing, "descriptor" = pref_intimate_ear_piercing_descriptor),
		list("key" = "nose_piercing", "slot" = INTIMATE_SLOT_NOSE, "path" = pref_intimate_nose_piercing, "descriptor" = pref_intimate_nose_piercing_descriptor),
		list("key" = "belly_piercing", "slot" = INTIMATE_SLOT_BELLY, "path" = pref_intimate_belly_piercing, "descriptor" = pref_intimate_belly_piercing_descriptor),
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
		if(slot_pref["key"] == "rear_insertable" && ispath(item_path, /obj/item/intimate_accessory/rear/plug/analbeads) && !ispath(item_path, /obj/item/intimate_accessory/rear/plug/analbeads/spiked))
			var/bead_metal_key = get_intimate_accessory_rear_bead_metal_key(item_path)
			var/list/bead_metal = find_intimate_roundstart_option(get_intimate_roundstart_rear_bead_metal_options(), bead_metal_key)
			if(bead_metal && bead_metal["silver"] && HAS_TRAIT(H, TRAIT_SILVER_WEAK))
				continue
		if(initial(item_path:is_silver) && HAS_TRAIT(H, TRAIT_SILVER_WEAK))
			continue

		var/obj/item/intimate_accessory/accessory = new item_path(H)
		if(slot_pref["key"] == "rear_insertable" && istype(accessory, /obj/item/intimate_accessory/rear/plug/analbeads))
			var/obj/item/intimate_accessory/rear/plug/analbeads/beads = accessory
			apply_intimate_rear_bead_metal_preference(beads)
		if(istype(accessory, /obj/item/intimate_accessory/piercing))
			var/obj/item/intimate_accessory/piercing/piercing = accessory
			piercing.set_custom_piercing_descriptor(slot_pref["descriptor"])
		if(!apply_intimate_accessory_socket_preference(slot_pref["key"], accessory, H))
			qdel(accessory)
			continue
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

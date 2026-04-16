/**
 * # Intimate Accessory Preferences
 *
 * Extends /datum/preferences with helper procs for the lobby-based intimate
 * accessory selection UI.  Each region (genital, rear, breast, mouth) has TWO
 * sub-slots: one for piercings, one for insertables. Each stores a typepath
 * that is instantiated and force-equipped during `copy_to` when the character
 * spawns or when the lobby preview mannequin is dressed.
 *
 * Option lists are built lazily via static vars so the first call pays the
 * init cost and every subsequent call is a no-op lookup.
 */

// ── Option-list helpers ────────────────────────────────────────────────────
// Each region now has separate piercing and insertable option lists.

/// Returns insertable options for the REAR slot (plugs, beads).
/datum/preferences/proc/get_intimate_rear_insertable_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                    = null,
			"Iron Butt Plug"          = /obj/item/intimate_accessory/rear/plug/iron,
			"Copper Butt Plug"        = /obj/item/intimate_accessory/rear/plug/copper,
			"Steel Butt Plug"         = /obj/item/intimate_accessory/rear/plug/steel,
			"Bronze Butt Plug"        = /obj/item/intimate_accessory/rear/plug/bronze,
			"Silver Butt Plug"        = /obj/item/intimate_accessory/rear/plug/silver,
			"Gold Butt Plug"          = /obj/item/intimate_accessory/rear/plug/gold,
			"Iron Anal Beads"         = /obj/item/intimate_accessory/rear/plug/analbeads/iron,
			"Copper Anal Beads"       = /obj/item/intimate_accessory/rear/plug/analbeads/copper,
			"Steel Anal Beads"        = /obj/item/intimate_accessory/rear/plug/analbeads/steel,
			"Bronze Anal Beads"       = /obj/item/intimate_accessory/rear/plug/analbeads/bronze,
			"Silver Anal Beads"       = /obj/item/intimate_accessory/rear/plug/analbeads/silver,
			"Gold Anal Beads"         = /obj/item/intimate_accessory/rear/plug/analbeads/gold,
			"Eora's Jelly"            = /obj/item/intimate_accessory/jelly/eora,
		)
	return options

/// Returns piercing options for the REAR slot.
/datum/preferences/proc/get_intimate_rear_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                        = null,
			"Iron Rear Piercing"          = /obj/item/intimate_accessory/piercing/rear/iron,
			"Copper Rear Piercing"        = /obj/item/intimate_accessory/piercing/rear/copper,
			"Steel Rear Piercing"         = /obj/item/intimate_accessory/piercing/rear/steel,
			"Bronze Rear Piercing"        = /obj/item/intimate_accessory/piercing/rear/bronze,
			"Silver Rear Piercing"        = /obj/item/intimate_accessory/piercing/rear/silver,
			"Gold Rear Piercing"          = /obj/item/intimate_accessory/piercing/rear/gold,
			"Iron Bell Rear Piercing"     = /obj/item/intimate_accessory/piercing/rear/bell/iron,
			"Copper Bell Rear Piercing"   = /obj/item/intimate_accessory/piercing/rear/bell/copper,
			"Steel Bell Rear Piercing"    = /obj/item/intimate_accessory/piercing/rear/bell/steel,
			"Bronze Bell Rear Piercing"   = /obj/item/intimate_accessory/piercing/rear/bell/bronze,
			"Silver Bell Rear Piercing"   = /obj/item/intimate_accessory/piercing/rear/bell/silver,
			"Gold Bell Rear Piercing"     = /obj/item/intimate_accessory/piercing/rear/bell/gold,
		)
	return options

/// Returns insertable options for the GENITAL slot (vaginal plugs, sounding rods).
/datum/preferences/proc/get_intimate_genital_insertable_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                        = null,
			"Iron Vaginal Plug"           = /obj/item/intimate_accessory/genital/plug/iron,
			"Copper Vaginal Plug"         = /obj/item/intimate_accessory/genital/plug/copper,
			"Steel Vaginal Plug"          = /obj/item/intimate_accessory/genital/plug/steel,
			"Bronze Vaginal Plug"         = /obj/item/intimate_accessory/genital/plug/bronze,
			"Silver Vaginal Plug"         = /obj/item/intimate_accessory/genital/plug/silver,
			"Gold Vaginal Plug"           = /obj/item/intimate_accessory/genital/plug/gold,
			"Iron Sounding Rod"           = /obj/item/intimate_accessory/genital/plug/sounding_rod/iron,
			"Copper Sounding Rod"         = /obj/item/intimate_accessory/genital/plug/sounding_rod/copper,
			"Steel Sounding Rod"          = /obj/item/intimate_accessory/genital/plug/sounding_rod/steel,
			"Bronze Sounding Rod"         = /obj/item/intimate_accessory/genital/plug/sounding_rod/bronze,
			"Silver Sounding Rod"         = /obj/item/intimate_accessory/genital/plug/sounding_rod/silver,
			"Gold Sounding Rod"           = /obj/item/intimate_accessory/genital/plug/sounding_rod/gold,
		)
	return options

/// Returns piercing options for the GENITAL slot.
/datum/preferences/proc/get_intimate_genital_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                        = null,
			"Iron Genital Piercing"       = /obj/item/intimate_accessory/piercing/genital/iron,
			"Copper Genital Piercing"     = /obj/item/intimate_accessory/piercing/genital/copper,
			"Steel Genital Piercing"      = /obj/item/intimate_accessory/piercing/genital/steel,
			"Bronze Genital Piercing"     = /obj/item/intimate_accessory/piercing/genital/bronze,
			"Silver Genital Piercing"     = /obj/item/intimate_accessory/piercing/genital/silver,
			"Gold Genital Piercing"       = /obj/item/intimate_accessory/piercing/genital/gold,
			"Iron Genital Bell Piercing"  = /obj/item/intimate_accessory/piercing/genital/bell/iron,
			"Copper Genital Bell Piercing"= /obj/item/intimate_accessory/piercing/genital/bell/copper,
			"Steel Genital Bell Piercing" = /obj/item/intimate_accessory/piercing/genital/bell/steel,
			"Bronze Genital Bell Piercing"= /obj/item/intimate_accessory/piercing/genital/bell/bronze,
			"Silver Genital Bell Piercing"= /obj/item/intimate_accessory/piercing/genital/bell/silver,
			"Gold Genital Bell Piercing"  = /obj/item/intimate_accessory/piercing/genital/bell/gold,
			"Stone Psydonic Genital Piercing"    = /obj/item/intimate_accessory/piercing/genital/psydonic,
			"Silver Psydonic Genital Piercing"   = /obj/item/intimate_accessory/piercing/genital/psydonic/silver_cross,
			"Golden Psydonic Genital Piercing"   = /obj/item/intimate_accessory/piercing/genital/psydonic/golden_cross,
			"Ancient Psydonic Genital Piercing"  = /obj/item/intimate_accessory/piercing/genital/psydonic/ancient_cross,
			"Iron Zizite Genital Piercing"       = /obj/item/intimate_accessory/piercing/genital/zizite,
			"Ancient Zizite Genital Piercing"    = /obj/item/intimate_accessory/piercing/genital/zizite/ancient_cross,
		)
	return options

/// Returns piercing options for the BREAST slot.
/datum/preferences/proc/get_intimate_breast_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                         = null,
			"Iron Nipple Piercing"         = /obj/item/intimate_accessory/piercing/breast/iron,
			"Copper Nipple Piercing"       = /obj/item/intimate_accessory/piercing/breast/copper,
			"Steel Nipple Piercing"        = /obj/item/intimate_accessory/piercing/breast/steel,
			"Bronze Nipple Piercing"       = /obj/item/intimate_accessory/piercing/breast/bronze,
			"Silver Nipple Piercing"       = /obj/item/intimate_accessory/piercing/breast/silver,
			"Gold Nipple Piercing"         = /obj/item/intimate_accessory/piercing/breast/gold,
			"Iron Bell Nipple Piercing"    = /obj/item/intimate_accessory/piercing/breast/bell/iron,
			"Copper Bell Nipple Piercing"  = /obj/item/intimate_accessory/piercing/breast/bell/copper,
			"Steel Bell Nipple Piercing"   = /obj/item/intimate_accessory/piercing/breast/bell/steel,
			"Bronze Bell Nipple Piercing"  = /obj/item/intimate_accessory/piercing/breast/bell/bronze,
			"Silver Bell Nipple Piercing"  = /obj/item/intimate_accessory/piercing/breast/bell/silver,
			"Gold Bell Nipple Piercing"    = /obj/item/intimate_accessory/piercing/breast/bell/gold,
			"Stone Psydonic Nipple Piercing"     = /obj/item/intimate_accessory/piercing/breast/psydonic,
			"Silver Psydonic Nipple Piercing"    = /obj/item/intimate_accessory/piercing/breast/psydonic/silver_cross,
			"Golden Psydonic Nipple Piercing"    = /obj/item/intimate_accessory/piercing/breast/psydonic/golden_cross,
			"Ancient Psydonic Nipple Piercing"   = /obj/item/intimate_accessory/piercing/breast/psydonic/ancient_cross,
			"Iron Zizite Nipple Piercing"        = /obj/item/intimate_accessory/piercing/breast/zizite,
			"Ancient Zizite Nipple Piercing"     = /obj/item/intimate_accessory/piercing/breast/zizite/ancient_cross,
		)
	return options

/// Returns insertable options for the BREAST slot (currently none, placeholder).
/datum/preferences/proc/get_intimate_breast_insertable_options()
	var/static/list/options
	if(!options)
		options = list("None" = null)
	return options

/// Returns piercing options for the MOUTH slot.
/datum/preferences/proc/get_intimate_mouth_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                     = null,
			"Iron Tongue Piercing"     = /obj/item/intimate_accessory/piercing/tongue/iron,
			"Copper Tongue Piercing"   = /obj/item/intimate_accessory/piercing/tongue/copper,
			"Steel Tongue Piercing"    = /obj/item/intimate_accessory/piercing/tongue/steel,
			"Bronze Tongue Piercing"   = /obj/item/intimate_accessory/piercing/tongue/bronze,
			"Silver Tongue Piercing"   = /obj/item/intimate_accessory/piercing/tongue/silver,
			"Gold Tongue Piercing"     = /obj/item/intimate_accessory/piercing/tongue/gold,
		)
	return options

/// Returns insertable options for the MOUTH slot (currently none, placeholder).
/datum/preferences/proc/get_intimate_mouth_insertable_options()
	var/static/list/options
	if(!options)
		options = list("None" = null)
	return options

/// Returns piercing options for the EAR slot.
/datum/preferences/proc/get_intimate_ear_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                        = null,
			"Iron Earring"                = /obj/item/intimate_accessory/piercing/ear/iron,
			"Copper Earring"              = /obj/item/intimate_accessory/piercing/ear/copper,
			"Steel Earring"               = /obj/item/intimate_accessory/piercing/ear/steel,
			"Bronze Earring"              = /obj/item/intimate_accessory/piercing/ear/bronze,
			"Silver Earring"              = /obj/item/intimate_accessory/piercing/ear/silver,
			"Gold Earring"                = /obj/item/intimate_accessory/piercing/ear/gold,
			"Blacksteel Earring"          = /obj/item/intimate_accessory/piercing/ear/blacksteel,
			"Stone Psydonic Earring"      = /obj/item/intimate_accessory/piercing/ear/psydonic,
			"Silver Psydonic Earring"     = /obj/item/intimate_accessory/piercing/ear/psydonic/silver_cross,
			"Golden Psydonic Earring"     = /obj/item/intimate_accessory/piercing/ear/psydonic/golden_cross,
			"Ancient Psydonic Earring"    = /obj/item/intimate_accessory/piercing/ear/psydonic/ancient_cross,
			"Iron Zizite Earring"         = /obj/item/intimate_accessory/piercing/ear/zizite,
			"Ancient Zizite Earring"      = /obj/item/intimate_accessory/piercing/ear/zizite/ancient_cross,
		)
	return options

/// Returns piercing options for the NOSE slot.
/datum/preferences/proc/get_intimate_nose_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                        = null,
			"Iron Nose Piercing"          = /obj/item/intimate_accessory/piercing/nose/iron,
			"Copper Nose Piercing"        = /obj/item/intimate_accessory/piercing/nose/copper,
			"Steel Nose Piercing"         = /obj/item/intimate_accessory/piercing/nose/steel,
			"Bronze Nose Piercing"        = /obj/item/intimate_accessory/piercing/nose/bronze,
			"Silver Nose Piercing"        = /obj/item/intimate_accessory/piercing/nose/silver,
			"Gold Nose Piercing"          = /obj/item/intimate_accessory/piercing/nose/gold,
			"Blacksteel Nose Piercing"    = /obj/item/intimate_accessory/piercing/nose/blacksteel,
		)
	return options

/// Returns piercing options for the BELLY slot.
/datum/preferences/proc/get_intimate_belly_piercing_options()
	var/static/list/options
	if(!options)
		options = list(
			"None"                             = null,
			"Iron Belly Button Piercing"       = /obj/item/intimate_accessory/piercing/belly/iron,
			"Copper Belly Button Piercing"     = /obj/item/intimate_accessory/piercing/belly/copper,
			"Steel Belly Button Piercing"      = /obj/item/intimate_accessory/piercing/belly/steel,
			"Bronze Belly Button Piercing"     = /obj/item/intimate_accessory/piercing/belly/bronze,
			"Silver Belly Button Piercing"     = /obj/item/intimate_accessory/piercing/belly/silver,
			"Gold Belly Button Piercing"       = /obj/item/intimate_accessory/piercing/belly/gold,
			"Blacksteel Belly Button Piercing" = /obj/item/intimate_accessory/piercing/belly/blacksteel,
			"Stone Psydonic Belly Piercing"    = /obj/item/intimate_accessory/piercing/belly/psydonic,
			"Silver Psydonic Belly Piercing"   = /obj/item/intimate_accessory/piercing/belly/psydonic/silver_cross,
			"Golden Psydonic Belly Piercing"   = /obj/item/intimate_accessory/piercing/belly/psydonic/golden_cross,
			"Ancient Psydonic Belly Piercing"  = /obj/item/intimate_accessory/piercing/belly/psydonic/ancient_cross,
			"Iron Zizite Belly Piercing"       = /obj/item/intimate_accessory/piercing/belly/zizite,
			"Ancient Zizite Belly Piercing"    = /obj/item/intimate_accessory/piercing/belly/zizite/ancient_cross,
		)
	return options

/// Given a typepath, search all option lists and return the display name.
/// Falls back to the typepath string if not found.
/datum/preferences/proc/get_intimate_option_display_name(typepath)
	if(!typepath)
		return "None"
	var/list/all_options = get_intimate_rear_insertable_options() + get_intimate_rear_piercing_options() \
		+ get_intimate_genital_insertable_options() + get_intimate_genital_piercing_options() \
		+ get_intimate_breast_piercing_options() + get_intimate_breast_insertable_options() \
		+ get_intimate_mouth_piercing_options() + get_intimate_mouth_insertable_options() \
		+ get_intimate_ear_piercing_options() + get_intimate_nose_piercing_options() \
		+ get_intimate_belly_piercing_options()
	for(var/label in all_options)
		if(all_options[label] == typepath)
			return label
	return "[typepath]"

// ── Force-equip for spawn / preview ────────────────────────────────────────
/**
 * Instantiates and equips the split intimate accessory prefs onto a character.
 * Each region has two sub-slots (piercing + insertable). Bypasses `can_attach_target`
 * (which requires a `mind`) by calling `set_current_intimate_slot` ->
 * `attach_intimate_feature` -> `finalize_intimate_equip` directly.
 * Anatomy checks (e.g. vagina requirement for genital plugs) are replicated inline.
 */
/datum/preferences/proc/apply_intimate_preferences(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(!intimate_enabled)
		return

	// Helper list: slot constant -> pref typepath
	// Each region has two entries: piercing and insertable.
	var/list/slot_prefs = list(
		"[INTIMATE_SLOT_GENITAL]_p" = pref_intimate_genital_piercing,
		"[INTIMATE_SLOT_GENITAL]_i" = pref_intimate_genital_insertable,
		"[INTIMATE_SLOT_REAR]_p"    = pref_intimate_rear_piercing,
		"[INTIMATE_SLOT_REAR]_i"    = pref_intimate_rear_insertable,
		"[INTIMATE_SLOT_BREAST]_p"  = pref_intimate_breast_piercing,
		"[INTIMATE_SLOT_BREAST]_i"  = pref_intimate_breast_insertable,
		"[INTIMATE_SLOT_MOUTH]_p"   = pref_intimate_mouth_piercing,
		"[INTIMATE_SLOT_MOUTH]_i"   = pref_intimate_mouth_insertable,
		"[INTIMATE_SLOT_EAR]_p"     = pref_intimate_ear_piercing,
		"[INTIMATE_SLOT_NOSE]_p"    = pref_intimate_nose_piercing,
		"[INTIMATE_SLOT_BELLY]_p"   = pref_intimate_belly_piercing,
	)

	for(var/slot_key in slot_prefs)
		var/item_path = slot_prefs[slot_key]
		if(!item_path || !ispath(item_path, /obj/item/intimate_accessory))
			continue

		// Parse the region from the key (everything before the underscore suffix)
		var/slot = text2num(copytext(slot_key, 1, findtext(slot_key, "_")))

		// Genital plugs require a vagina — skip silently if anatomy doesn't match
		if(ispath(item_path, /obj/item/intimate_accessory/genital/plug))
			if(!ispath(item_path, /obj/item/intimate_accessory/genital/plug/sounding_rod))
				if(!H.getorganslot(ORGAN_SLOT_VAGINA))
					continue

		// Sounding rods require a penis
		if(ispath(item_path, /obj/item/intimate_accessory/genital/plug/sounding_rod))
			if(!H.getorganslot(ORGAN_SLOT_PENIS))
				continue

		// Silver check — skip for silver-weak characters
		if(initial(item_path:is_silver) && HAS_TRAIT(H, TRAIT_SILVER_WEAK))
			continue

		// Instantiate and force-equip
		var/obj/item/intimate_accessory/accessory = new item_path(H)
		// Jelly uses INTIMATE_SLOT_JELLY for storage; set its region for visuals
		if(accessory.intimate_flags & INTIMATE_FLAG_JELLY)
			accessory.current_intimate_slot = slot
		if(!accessory.set_current_intimate_slot(slot))
			qdel(accessory)
			continue
		// Mark as round-start so the base material has no sell value —
		// only socketed gems should contribute to the price.
		accessory.roundstart_equipped = TRUE
		accessory.sellprice = 1
		accessory.attach_intimate_feature(H)
		accessory.finalize_intimate_equip(H)

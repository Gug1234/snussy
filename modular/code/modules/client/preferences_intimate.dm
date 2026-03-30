/**
 * # Intimate Accessory Preferences
 *
 * Extends /datum/preferences with helper procs for the lobby-based intimate
 * accessory selection UI.  Each slot (genital, rear, breast, mouth) stores a
 * typepath that is instantiated and force-equipped during `copy_to` when the
 * character spawns or when the lobby preview mannequin is dressed.
 *
 * Option lists are built lazily via static vars so the first call pays the
 * init cost and every subsequent call is a no-op lookup.
 */

// ── Option-list helpers ────────────────────────────────────────────────────
/// Returns an assoc list of "Display Name" = typepath for the REAR slot.
/datum/preferences/proc/get_intimate_rear_options()
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

/// Returns an assoc list of "Display Name" = typepath for the GENITAL slot.
/// Plugs require ORGAN_SLOT_VAGINA; piercings do not.
/datum/preferences/proc/get_intimate_genital_options()
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
		)
	return options

/// Returns an assoc list of "Display Name" = typepath for the BREAST slot.
/datum/preferences/proc/get_intimate_breast_options()
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
		)
	return options

/// Returns an assoc list of "Display Name" = typepath for the MOUTH slot.
/datum/preferences/proc/get_intimate_mouth_options()
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



/// Given a typepath, search all option lists and return the display name.
/// Falls back to the typepath string if not found.
/datum/preferences/proc/get_intimate_option_display_name(typepath)
	if(!typepath)
		return "None"
	var/list/all_options = get_intimate_rear_options() + get_intimate_genital_options() + get_intimate_breast_options() + get_intimate_mouth_options()
	for(var/label in all_options)
		if(all_options[label] == typepath)
			return label
	return "[typepath]"

// ── Force-equip for spawn / preview ────────────────────────────────────────
/**
 * Instantiates and equips the four intimate accessory prefs onto a character.
 * Bypasses `can_attach_target` (which requires a `mind`) by calling
 * `set_current_intimate_slot` -> `attach_intimate_feature` -> `finalize_intimate_equip`
 * directly.  Anatomy checks (e.g. vagina requirement for genital plugs) are
 * replicated inline.
 */
/datum/preferences/proc/apply_intimate_preferences(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(!intimate_enabled)
		return

	// Helper list: slot constant -> pref typepath
	var/list/slot_prefs = list(
		"[INTIMATE_SLOT_GENITAL]" = pref_intimate_genital,
		"[INTIMATE_SLOT_REAR]"    = pref_intimate_rear,
		"[INTIMATE_SLOT_BREAST]"  = pref_intimate_breast,
		"[INTIMATE_SLOT_MOUTH]"   = pref_intimate_mouth,
	)

	for(var/slot_key in slot_prefs)
		var/item_path = slot_prefs[slot_key]
		if(!item_path || !ispath(item_path, /obj/item/intimate_accessory))
			continue

		var/slot = text2num(slot_key)

		// Genital plugs require a vagina — skip silently if anatomy doesn't match
		if(ispath(item_path, /obj/item/intimate_accessory/genital/plug))
			if(!H.getorganslot(ORGAN_SLOT_VAGINA))
				continue

		// Silver check — skip for silver-weak characters
		if(initial(item_path:is_silver) && HAS_TRAIT(H, TRAIT_SILVER_WEAK))
			continue

		// Instantiate and force-equip
		var/obj/item/intimate_accessory/accessory = new item_path(H)
		if(!accessory.set_current_intimate_slot(slot))
			qdel(accessory)
			continue
		// Mark as round-start so the base material has no sell value —
		// only socketed gems should contribute to the price.
		accessory.roundstart_equipped = TRUE
		accessory.sellprice = 1
		accessory.attach_intimate_feature(H)
		accessory.finalize_intimate_equip(H)

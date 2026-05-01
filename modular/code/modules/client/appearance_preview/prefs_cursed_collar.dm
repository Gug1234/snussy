/*
 * prefs_cursed_collar.dm — Step 17.
 *
 * Registers the remaining cursed-collar setters (master_mode +
 * specified_name) and implements the round-start equip path that
 * mirrors the chastity roundstart flow in preferences_chastity.dm.
 *
 * The opt setter (cursed_collar_opt) is owned by the Step 3 dispatch
 * seed in prefs_set_pref_dispatch.dm; this file extends the surface
 * with the two dependent fields used when opt != NONE.
 *
 * Security:
 *   master_mode is intrange-gated against the 3 enum values.
 *   specified_name is string-capped at CURSED_COLLAR_SPECIFIED_NAME_MAX
 *   to prevent an attacker from stuffing multi-KB text into the save.
 *
 * Round-start:
 *   apply_cursed_collar_preferences() fires from /datum/preferences/copy_to
 *   alongside apply_chastity_preferences(). Gated by `cursed_enabled`
 *   (the account-level opt-in from erp_preferences_menu.dm) so players
 *   who disabled cursed content never receive the item, even if the
 *   per-char slot still has cursed_collar_opt set from a prior round.
 */

/// Length cap for the specified-master character-name field. Matches the
/// ceiling used by real-name input elsewhere in preferences.
#define CURSED_COLLAR_SPECIFIED_NAME_MAX 48

/proc/register_prefs_cursed_collar_setters()
	register_prefs_setter(
		PREF_KEY_CURSED_COLLAR_MASTER_MODE,
		prefs_validate_intrange(CURSED_COLLAR_MASTER_SELF, CURSED_COLLAR_MASTER_SPECIFIED),
		"set_pref_cursed_collar_master_mode",
	)
	register_prefs_setter(
		PREF_KEY_CURSED_COLLAR_SPECIFIED_NAME,
		prefs_validate_string(CURSED_COLLAR_SPECIFIED_NAME_MAX),
		"set_pref_cursed_collar_specified_name",
	)

/datum/preferences/proc/set_pref_cursed_collar_master_mode(value)
	cursed_collar_master_mode = text2num("[value]")

/datum/preferences/proc/set_pref_cursed_collar_specified_name(value)
	cursed_collar_specified_name = istext(value) ? trim(value) : ""

// ── Round-start equip ───────────────────────────────────────────────────

/**
 * Called from /datum/preferences/copy_to at spawn if `cursed_enabled` is
 * true. Honors cursed_collar_opt (NONE / COLLAR / CHASTITY_DEVICE) and
 * cursed_collar_master_mode (SELF / RANDOM / SPECIFIED). Silently returns
 * when prerequisites are missing; never runtimes on bad input.
 */
/datum/preferences/proc/apply_cursed_collar_preferences(mob/living/carbon/human/H)
	if(!istype(H) || !H.mind)
		return
	if(!cursed_enabled)
		return
	if(cursed_collar_opt == CURSED_COLLAR_OPT_NONE)
		return
	// Don't double-equip if something already equipped a cursed device.
	if(H.chastity_device && H.chastity_device.chastity_cursed)
		return
	if(cursed_collar_opt == CURSED_COLLAR_OPT_COLLAR && H.get_item_by_slot(SLOT_NECK))
		return

	var/datum/mind/master_mind = resolve_cursed_collar_master(H)
	// No master found -> fall back to SELF so the wearer isn't silently
	// skipped. Matches spec §4.5 "No-master-found → wearer prompted to
	// self-master or have the device fall off"; at round-start the
	// prompt is skipped in favor of the self-master default.
	if(!master_mind)
		master_mind = H.mind

	// Ensure the master mind owns a collar_master component so the
	// pet-binding handshake has a target.
	var/datum/component/collar_master/CM = master_mind.GetComponent(/datum/component/collar_master)
	if(!CM)
		CM = master_mind.AddComponent(/datum/component/collar_master)

	switch(cursed_collar_opt)
		if(CURSED_COLLAR_OPT_COLLAR)
			_equip_roundstart_cursed_collar(H, master_mind, CM)
		if(CURSED_COLLAR_OPT_CHASTITY_DEVICE)
			_equip_roundstart_cursed_chastity(H, master_mind, CM)

/**
 * Resolves the master-mind for a round-start cursed-collar equip based
 * on the wearer's master_mode preference. Returns null if RANDOM found
 * no eligible player or SPECIFIED found no matching character.
 */
/datum/preferences/proc/resolve_cursed_collar_master(mob/living/carbon/human/wearer)
	switch(cursed_collar_master_mode)
		if(CURSED_COLLAR_MASTER_SELF)
			return wearer.mind
		if(CURSED_COLLAR_MASTER_SPECIFIED)
			var/target_name = cursed_collar_specified_name
			if(!istext(target_name) || !length(target_name))
				return null
			var/lower_name = LOWER_TEXT(target_name)
			for(var/client/C in GLOB.clients)
				var/mob/living/carbon/human/candidate = C.mob
				if(!istype(candidate) || !candidate.mind || candidate == wearer)
					continue
				if(!C.prefs?.cursed_enabled)
					continue
				if(LOWER_TEXT(candidate.real_name) == lower_name)
					return candidate.mind
			return null
		if(CURSED_COLLAR_MASTER_RANDOM)
			var/list/candidates = list()
			for(var/client/C in GLOB.clients)
				var/mob/living/carbon/human/candidate = C.mob
				if(!istype(candidate) || !candidate.mind || candidate == wearer)
					continue
				if(!C.prefs?.cursed_enabled)
					continue
				candidates += candidate.mind
			if(!length(candidates))
				return null
			return pick(candidates)
	return null

/**
 * Creates and equips a cursed collar onto the wearer with `master_mind`
 * pre-imprinted. Bypasses the wearer-prompt flow in handle_equip() by
 * pre-setting applying = TRUE during equip and binding the pet record
 * directly afterward. The collar's post-equip signal path still fires.
 */
/datum/preferences/proc/_equip_roundstart_cursed_collar(mob/living/carbon/human/H, datum/mind/master_mind, datum/component/collar_master/CM)
	var/obj/item/clothing/neck/roguetown/cursed_collar/collar = new(H)
	collar.collar_master = master_mind
	collar.applying = TRUE
	if(!H.equip_to_slot_if_possible(collar, SLOT_NECK, TRUE, TRUE))
		qdel(collar)
		return
	collar.applying = FALSE
	if(!CM.add_pet(H))
		H.dropItemToGround(collar, force = TRUE)
		qdel(collar)
		return
	SEND_SIGNAL(H, COMSIG_CARBON_COLLAR_BOUND, master_mind, collar)
	ADD_TRAIT(collar, TRAIT_NODROP, CURSED_ITEM_TRAIT)

/**
 * Creates and equips a cursed chastity device in the character's
 * inventory with `master_mind` pre-imprinted. Reuses the cursed device's
 * own attach/finalize helpers so all the collar_master wiring runs
 * exactly as it does in the player-equip path.
 */
/datum/preferences/proc/_equip_roundstart_cursed_chastity(mob/living/carbon/human/H, datum/mind/master_mind, datum/component/collar_master/CM)
	if(H.chastity_device)
		return
	var/obj/item/chastity/cursed/device = new(H)
	device.chastity_master = master_mind
	if(!device.chastity_genital_check(H))
		qdel(device)
		return
	device.ensure_chastity_feature(H)
	if(!device.attach_chastity_feature(H))
		qdel(device)
		return
	device.finalize_chastity_equip(H)
	device.apply_standard_chastity_traits(H)
	device.sellprice = 1
	CM.add_pet(H)
	ADD_TRAIT(device, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	H.update_body_parts(TRUE)

#undef CURSED_COLLAR_SPECIFIED_NAME_MAX

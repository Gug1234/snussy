/**
 * # Chastity Device Preferences
 *
 * Extends /datum/preferences with helper procs for the lobby-based chastity
 * device toggle system. Instead of picking a typepath from a list, players
 * set boolean toggles (enabled, flat cage, anal shield, spikes) and the
 * correct device typepath is resolved at equip time based on the character's
 * genitals.
 *
 * Key stashes use **character names** rather than ckeys — if a matching
 * character is found online at round-start, a key copy is placed in their
 * inventory.
 *
 * Excludes /obj/item/chastity/cursed — cursed devices are master-bound only.
 */

// ── Genital detection from prefs ─────────────────────────────────────────

/// Returns TRUE if the current character slot has an enabled (non-disabled)
/// customizer entry for the given organ slot (e.g. ORGAN_SLOT_PENIS).
/// Works in the lobby context where no mob exists yet.
/datum/preferences/proc/has_genital_in_prefs(organ_slot)
	for(var/datum/customizer_entry/entry as anything in customizer_entries)
		if(entry.disabled)
			continue
		var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
		if(!istype(choice, /datum/customizer_choice/organ))
			continue
		var/datum/customizer_choice/organ/organ_choice = choice
		if(organ_choice.organ_slot == organ_slot)
			return TRUE
	return FALSE

// ── Typepath resolution ──────────────────────────────────────────────────

/**
 * Resolves the correct chastity device typepath from the boolean toggle prefs
 * and the character's genital configuration.
 *
 * Returns null if the character has no eligible genitals or chastity is disabled.
 *
 * Anatomy rules:
 *   - Penis only  → cock cage variants (flat toggle applies)
 *   - Vagina only → insertable belt variants (flat toggle ignored)
 *   - Both        → intersex device (flat & anal toggles ignored)
 */
/datum/preferences/proc/resolve_chastity_typepath()
	if(!pref_chastity_enabled)
		return null

	var/has_penis = has_genital_in_prefs(ORGAN_SLOT_PENIS)
	var/has_vagina = has_genital_in_prefs(ORGAN_SLOT_VAGINA)

	if(!has_penis && !has_vagina)
		return null

	// Intersex — only spiked modifier applies
	if(has_penis && has_vagina)
		if(pref_chastity_spiked && extreme_erp)
			return /obj/item/chastity/intersex/spiked
		return /obj/item/chastity/intersex

	// Cock cage — flat and anal modifiers apply
	if(has_penis)
		if(pref_chastity_flat)
			if(pref_chastity_spiked && extreme_erp)
				return pref_chastity_anal ? /obj/item/chastity/chastity_cage/flat/spiked_anal : /obj/item/chastity/chastity_cage/flat/spiked
			return pref_chastity_anal ? /obj/item/chastity/chastity_cage/flat/anal : /obj/item/chastity/chastity_cage/flat
		// Standard cage
		if(pref_chastity_spiked && extreme_erp)
			return pref_chastity_anal ? /obj/item/chastity/chastity_cage/spiked_anal : /obj/item/chastity/chastity_cage/spiked
		return pref_chastity_anal ? /obj/item/chastity/chastity_cage/anal : /obj/item/chastity/chastity_cage

	// Insertable belt (vagina only) — anal modifier applies, flat does not
	if(pref_chastity_spiked && extreme_erp)
		return pref_chastity_anal ? /obj/item/chastity/chastity_belt/spiked_anal : /obj/item/chastity/chastity_belt/spiked
	return pref_chastity_anal ? /obj/item/chastity/chastity_belt/anal : /obj/item/chastity/chastity_belt

// ── Force-equip for spawn / preview ────────────────────────────────────────
/**
 * Resolves and equips the chastity device based on boolean toggle prefs.
 * Validates anatomy requirements via chastity_genital_check() before equipping.
 * Spiked devices require extreme_erp to be enabled (enforced in resolve).
 *
 * Handles:
 *   - Typepath resolution from toggles + genitals
 *   - Device creation and equip (ensure_chastity_feature -> attach -> finalize)
 *   - Standard chastity trait application
 *   - Key generation (if pref_chastity_spawn_key is TRUE)
 *   - Lock state (if pref_chastity_locked is TRUE)
 *   - Round-start sell price neutralization
 */
/datum/preferences/proc/apply_chastity_preferences(mob/living/carbon/human/H)
	if(!istype(H))
		return
	if(!chastenable || !pref_chastity_enabled)
		return
	// Don't double-equip if something already equipped a device
	if(H.chastity_device)
		return

	var/resolved_path = resolve_chastity_typepath()
	if(!resolved_path)
		return

	var/obj/item/chastity/device = new resolved_path(H)

	// Anatomy validation — silently skip if genitals don't match
	if(!device.chastity_genital_check(H))
		qdel(device)
		return

	// Standard equip flow (mirrors equip_standard_chastity but without do_after)
	device.ensure_chastity_feature(H)
	if(!device.attach_chastity_feature(H))
		qdel(device)
		return
	device.finalize_chastity_equip(H)
	device.apply_standard_chastity_traits(H)

	// Round-start: neutralize sell value so the base device isn't free money
	device.sellprice = 1

	// Key handling
	if(pref_chastity_spawn_key)
		device.generate_chastity_key(H, H)
		// Place key in the character's hands or at their feet
		if(device.generated_key && !QDELETED(device.generated_key))
			if(!H.put_in_hands(device.generated_key))
				device.generated_key.forceMove(get_turf(H))

	// Lock state
	if(pref_chastity_locked)
		device.locked = TRUE
		ADD_TRAIT(H, TRAIT_CHASTITY_LOCKED, TRAIT_SOURCE_CHASTITY)

	// Distribute key copies to stash targets
	if(pref_chastity_key_stashes && length(pref_chastity_key_stashes) && device.generated_key)
		distribute_chastity_key_stashes(H, device)

	// Random key distribution — send to an eligible chastenable player not already in the stash list
	if(pref_chastity_random_keys && device.generated_key)
		distribute_chastity_key_random(H, device)

	H.update_body_parts(TRUE)

// ── Key stash distribution ────────────────────────────────────────────────
/**
 * Distributes copies of a chastity key to other players' stashes.
 * For each **character name** in pref_chastity_key_stashes, searches all
 * connected clients for a human mob whose real_name matches (case-insensitive).
 * If found, a physical key copy is created and placed in their inventory.
 * If the target character is NOT found online, the delivery is registered in
 * GLOB.pending_chastity_keys so it can be fulfilled when that character
 * latejoins later in the round.
 */
/datum/preferences/proc/distribute_chastity_key_stashes(mob/living/carbon/human/owner, obj/item/chastity/device)
	if(!device || !pref_chastity_key_stashes)
		return
	// Build a lowered name → mob lookup table once for O(1) per stash name.
	var/list/name_to_mob = list()
	for(var/client/C in GLOB.clients)
		var/mob/living/carbon/human/candidate = C.mob
		if(!istype(candidate) || !candidate.mind)
			continue
		name_to_mob[LOWER_TEXT(candidate.real_name)] = candidate
	for(var/target_name in pref_chastity_key_stashes)
		if(!istext(target_name) || !length(target_name))
			continue
		var/lower_name = LOWER_TEXT(target_name)
		var/mob/living/carbon/human/target_mob = name_to_mob[lower_name]
		if(!target_mob)
			// Target not online yet — register for latejoin delivery
			LAZYINITLIST(GLOB.pending_chastity_keys[lower_name])
			GLOB.pending_chastity_keys[lower_name] += list(list(
				"lockhash" = device.lockhash,
				"owner_name" = owner.real_name
			))
			to_chat(owner, span_notice("A copy of my chastity key has been set aside for [target_name]. It will be delivered when they arrive."))
			continue
		// Create a copy of the key with matching lockhash
		deliver_chastity_key_copy(target_mob, device.lockhash, owner.real_name)
		to_chat(owner, span_notice("A copy of my chastity key has been delivered to [target_mob.real_name]."))
		to_chat(target_mob, span_notice("A copy of [owner.real_name]'s chastity key has been entrusted to you."))

// ── Random key distribution ───────────────────────────────────────────────
/**
 * Finds a random eligible player to receive a copy of the chastity key.
 * Eligible = has chastenable ON, is a living human with a mind, and is NOT
 * already in the wearer's key stash list or the wearer themselves.
 */
/datum/preferences/proc/distribute_chastity_key_random(mob/living/carbon/human/owner, obj/item/chastity/device)
	if(!device?.generated_key || !owner)
		return
	var/list/candidates = list()
	var/list/stash_lower = list()
	// Build a lowered set of stash names for fast exclusion
	if(pref_chastity_key_stashes)
		for(var/sname in pref_chastity_key_stashes)
			stash_lower += LOWER_TEXT(sname)
	for(var/client/C in GLOB.clients)
		if(!C.prefs?.chastenable)
			continue
		var/mob/living/carbon/human/candidate = C.mob
		if(!istype(candidate) || !candidate.mind)
			continue
		if(candidate == owner)
			continue
		if(LOWER_TEXT(candidate.real_name) in stash_lower)
			continue
		candidates += candidate
	if(!length(candidates))
		return
	var/mob/living/carbon/human/lucky = pick(candidates)
	deliver_chastity_key_copy(lucky, device.lockhash, owner.real_name)
	to_chat(lucky, span_notice("You found a forlorn chastity key shimmering in the dirt, it appears to belong to [owner.real_name]."))
	to_chat(owner, span_notice("A copy of my chastity key has found its way to a stranger."))

// ── Latejoin pending key delivery ─────────────────────────────────────────
/**
 * Called during copy_to for every spawning character. Checks if this
 * character's name has any pending chastity key deliveries registered by
 * wearers who spawned earlier in the round. If found, delivers the keys
 * and removes the pending entries.
 */
/datum/preferences/proc/check_pending_chastity_keys(mob/living/carbon/human/H)
	if(!istype(H) || !length(GLOB.pending_chastity_keys))
		return
	var/lower_name = LOWER_TEXT(H.real_name)
	var/list/pending = GLOB.pending_chastity_keys[lower_name]
	if(!islist(pending) || !length(pending))
		return
	for(var/list/entry in pending)
		var/lockhash = entry["lockhash"]
		var/owner_name = entry["owner_name"]
		if(!lockhash)
			continue
		deliver_chastity_key_copy(H, lockhash, owner_name)
		to_chat(H, span_notice("A copy of [owner_name]'s chastity key was waiting for you."))
	// All delivered — clean up
	GLOB.pending_chastity_keys -= lower_name

// ── Shared key delivery helper ────────────────────────────────────────────
/**
 * Creates a chastity key copy with the given lockhash and places it in the
 * target mob's hands (or at their feet). Used by both immediate distribution
 * and latejoin pending delivery.
 */
/datum/preferences/proc/deliver_chastity_key_copy(mob/living/carbon/human/target, lockhash, owner_name)
	if(!istype(target) || !lockhash)
		return
	var/obj/item/roguekey/chastity/key_copy = new(get_turf(target))
	key_copy.lockhash = lockhash
	key_copy.name = "[owner_name]'s chastity key"
	key_copy.desc = "A small key for [owner_name]'s chastity device."
	if(!target.put_in_hands(key_copy))
		key_copy.forceMove(get_turf(target))

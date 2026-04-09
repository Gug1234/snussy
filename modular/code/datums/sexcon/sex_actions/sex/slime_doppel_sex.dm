// ── Slime Doppelganger Sex Actions ───────────────────────────────────────────
// Sex actions mediated by the strange jelly's doppelganger clone.
//
// Self-targeted actions: the user targets themselves, the jelly spawns a
// translucent slime clone that performs the act on the user. The doppelganger
// is qdel'd when the action finishes.
//
// Gangbang actions: the user targets another person, the jelly spawns a clone
// that assists — the user and the clone double-team the target.
//
// All doppelganger actions require a strange jelly with bond_escalation_level >= 2.

/// Helper — finds the user's eora jelly (strange or base), or null.
/datum/sex_action/proc/get_user_strange_jelly(mob/living/carbon/human/user)
	if(!user)
		return null
	var/obj/item/intimate_accessory/jelly/eora/J = user.intimate_jelly
	if(istype(J))
		return J
	return null

// ════════════════════════════════════════════════════════════════════════════
// Base doppelganger action — handles spawn/dismiss lifecycle
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_doppel
	abstract_type = /datum/sex_action/slime_doppel
	check_same_tile = FALSE
	stamina_cost = 1.5
	category = SEX_CATEGORY_PENETRATE
	/// Minimum bond level required (only enforced for strange jellies).
	var/required_bond_level = 2
	/// The spawned doppelganger, tracked per-action instance.
	var/mob/living/carbon/human/slime_doppelganger/active_doppel
	/// Cached jelly reference, set in ensure_doppelganger() to avoid repeated lookups.
	var/obj/item/intimate_accessory/jelly/eora/cached_jelly

/// Finds the user's eora jelly and checks bond level (strange only).
/// Base eora jellies always pass — they have no bond/needs system.
/datum/sex_action/slime_doppel/proc/get_jelly_if_ready(mob/living/carbon/human/user)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_user_strange_jelly(user)
	if(!jelly)
		return null
	// Base eora jellies have no bond system — always ready.
	// Strange jellies must meet the bond threshold.
	if(jelly.is_strange_jelly())
		var/obj/item/intimate_accessory/jelly/eora/strange/strange = jelly
		if(strange.bond_escalation_level < required_bond_level)
			return null
	return jelly

/// Spawns the doppelganger via the jelly. Returns the doppel or null.
/datum/sex_action/slime_doppel/proc/ensure_doppelganger(mob/living/carbon/human/user)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_jelly_if_ready(user)
	if(!jelly)
		return null
	cached_jelly = jelly
	var/mob/living/carbon/human/slime_doppelganger/doppel = jelly.spawn_doppelganger()
	active_doppel = doppel
	return doppel

/// Dismisses the doppelganger via the jelly and triggers feeding for strange jellies.
/datum/sex_action/slime_doppel/proc/cleanup_doppelganger(mob/living/carbon/human/user)
	var/obj/item/intimate_accessory/jelly/eora/jelly = cached_jelly || get_user_strange_jelly(user)
	if(jelly)
		// Feed the jelly on doppelganger sex completion (strange jellies only).
		if(jelly.is_strange_jelly())
			var/obj/item/intimate_accessory/jelly/eora/strange/strange = jelly
			strange.on_doppelganger_sex_complete(user)
		jelly.dismiss_doppelganger()
	active_doppel = null
	cached_jelly = null

/// Returns TRUE if the tracked doppelganger is still alive and usable.
/datum/sex_action/slime_doppel/proc/is_doppel_valid()
	return active_doppel && !QDELETED(active_doppel)

/// Framework abort hook — stops the action if the doppelganger was lost.
/datum/sex_action/slime_doppel/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!is_doppel_valid())
		return TRUE
	return ..()

/**
 * Fetches a random doppelganger flavor message from the JSON string bank.
 * Resolves [USER] and [TARGET] tokens via the jelly's resolver.
 * Args:
 *   bank_key - the JSON key in jelly_doppelganger_messages.json
 *   user     - the user mob (token: [USER])
 *   target   - the target mob (token: [TARGET], optional)
 */
/datum/sex_action/slime_doppel/proc/get_doppel_flavor(bank_key, mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = cached_jelly || get_user_strange_jelly(user)
	if(!jelly)
		return null
	return jelly.get_doppelganger_flavor(bank_key, user, target)

// ════════════════════════════════════════════════════════════════════════════
// Self-target: Doppelganger fucks user's vagina
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_doppel/self_vaginal
	name = "Let the slime take me (Vaginal)"
	user_sex_part = SEX_PART_CUNT
	target_sex_part = SEX_PART_CUNT

/datum/sex_action/slime_doppel/self_vaginal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/self_vaginal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/self_vaginal/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/mob/living/carbon/human/slime_doppelganger/doppel = ensure_doppelganger(user)
	if(!doppel)
		return
	var/flavor = get_doppel_flavor("doppel_self_vaginal_start", user)
	if(flavor)
		user.visible_message(span_warning(flavor))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/self_vaginal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!is_doppel_valid())
		cleanup_doppelganger(user)
		return
	user.sexcon.perform_sex_action(user, 3, 0, FALSE)
	user.sexcon.receive_sex_action(3, 0, FALSE, user.sexcon.force, user.sexcon.speed)
	var/flavor = get_doppel_flavor("doppel_self_vaginal_perform", user)
	if(flavor)
		user.visible_message(span_warning(flavor))
	cached_jelly?.advance_bond_from_sex()

/datum/sex_action/slime_doppel/self_vaginal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/flavor = get_doppel_flavor("doppel_self_vaginal_finish", user)
	if(flavor)
		user.visible_message(span_notice(flavor))
	cleanup_doppelganger(user)

// ════════════════════════════════════════════════════════════════════════════
// Self-target: Doppelganger fucks user's ass
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_doppel/self_anal
	name = "Let the slime take me (Anal)"
	user_sex_part = SEX_PART_ANUS
	target_sex_part = SEX_PART_ANUS

/datum/sex_action/slime_doppel/self_anal/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/self_anal/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE


/datum/sex_action/slime_doppel/self_anal/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/mob/living/carbon/human/slime_doppelganger/doppel = ensure_doppelganger(user)
	if(!doppel)
		return
	var/flavor = get_doppel_flavor("doppel_self_anal_start", user)
	if(flavor)
		user.visible_message(span_warning(flavor))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/self_anal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!is_doppel_valid())
		cleanup_doppelganger(user)
		return
	user.sexcon.perform_sex_action(user, 3, 0, FALSE)
	user.sexcon.receive_sex_action(3, 0, FALSE, user.sexcon.force, user.sexcon.speed)
	var/flavor = get_doppel_flavor("doppel_self_anal_perform", user)
	if(flavor)
		user.visible_message(span_warning(flavor))
	cached_jelly?.advance_bond_from_sex()

/datum/sex_action/slime_doppel/self_anal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/flavor = get_doppel_flavor("doppel_self_anal_finish", user)
	if(flavor)
		user.visible_message(span_notice(flavor))
	cleanup_doppelganger(user)

// ════════════════════════════════════════════════════════════════════════════
// Self-target: Doppelganger fucks user's throat
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_doppel/self_oral
	name = "Let the slime take me (Oral)"
	user_sex_part = SEX_PART_JAWS
	target_sex_part = SEX_PART_JAWS

/datum/sex_action/slime_doppel/self_oral/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/self_oral/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/self_oral/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/mob/living/carbon/human/slime_doppelganger/doppel = ensure_doppelganger(user)
	if(!doppel)
		return
	var/flavor = get_doppel_flavor("doppel_self_oral_start", user)
	if(flavor)
		user.visible_message(span_warning(flavor))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/self_oral/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!is_doppel_valid())
		cleanup_doppelganger(user)
		return
	user.sexcon.perform_sex_action(user, 2.5, 0, FALSE)
	user.sexcon.receive_sex_action(2.5, 0, FALSE, user.sexcon.force, user.sexcon.speed)
	var/flavor = get_doppel_flavor("doppel_self_oral_perform", user)
	if(flavor)
		user.visible_message(span_warning(flavor))
	cached_jelly?.advance_bond_from_sex()

/datum/sex_action/slime_doppel/self_oral/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/flavor = get_doppel_flavor("doppel_self_oral_finish", user)
	if(flavor)
		user.visible_message(span_notice(flavor))
	cleanup_doppelganger(user)

// ════════════════════════════════════════════════════════════════════════════
// Gangbang: User + doppelganger double-team target (vaginal + anal)
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_doppel/gangbang_dp
	name = "Double-team them with slime (DP)"
	user_sex_part = SEX_PART_COCK
	target_sex_part = SEX_PART_CUNT|SEX_PART_ANUS
	knot_on_finish = TRUE

/datum/sex_action/slime_doppel/gangbang_dp/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!target.getorganslot(ORGAN_SLOT_VAGINA))
		return FALSE
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/gangbang_dp/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!get_jelly_if_ready(user))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/gangbang_dp/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/mob/living/carbon/human/slime_doppelganger/doppel = ensure_doppelganger(user)
	if(!doppel)
		return
	var/flavor = get_doppel_flavor("doppel_gangbang_dp_start", user, target)
	if(flavor)
		user.visible_message(span_warning(flavor))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/gangbang_dp/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!is_doppel_valid())
		cleanup_doppelganger(user)
		return
	user.sexcon.perform_sex_action(target, 4, 1, TRUE)
	if(target.sexcon)
		target.sexcon.receive_sex_action(4, 1, FALSE, user.sexcon.force, user.sexcon.speed)
	var/flavor = get_doppel_flavor("doppel_gangbang_dp_perform", user, target)
	if(flavor)
		user.visible_message(span_warning(flavor))
	cached_jelly?.advance_bond_from_sex(2)

/datum/sex_action/slime_doppel/gangbang_dp/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/flavor = get_doppel_flavor("doppel_gangbang_dp_finish", user, target)
	if(flavor)
		user.visible_message(span_notice(flavor))
	cleanup_doppelganger(user)

// ════════════════════════════════════════════════════════════════════════════
// Gangbang: User + doppelganger — user fucks, doppel takes throat
// ════════════════════════════════════════════════════════════════════════════

/datum/sex_action/slime_doppel/gangbang_spit
	name = "Spit-roast them with slime"
	user_sex_part = SEX_PART_COCK
	target_sex_part = SEX_PART_CUNT|SEX_PART_JAWS
	knot_on_finish = TRUE

/datum/sex_action/slime_doppel/gangbang_spit/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!get_jelly_if_ready(user))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/gangbang_spit/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!get_jelly_if_ready(user))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/slime_doppel/gangbang_spit/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/mob/living/carbon/human/slime_doppelganger/doppel = ensure_doppelganger(user)
	if(!doppel)
		return
	var/flavor = get_doppel_flavor("doppel_gangbang_spit_start", user, target)
	if(flavor)
		user.visible_message(span_warning(flavor))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/gangbang_spit/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!is_doppel_valid())
		cleanup_doppelganger(user)
		return
	user.sexcon.perform_sex_action(target, 4, 0.5, TRUE)
	if(target.sexcon)
		target.sexcon.receive_sex_action(4, 0.5, FALSE, user.sexcon.force, user.sexcon.speed)
	var/flavor = get_doppel_flavor("doppel_gangbang_spit_perform", user, target)
	if(flavor)
		user.visible_message(span_warning(flavor))
	cached_jelly?.advance_bond_from_sex(2)

/datum/sex_action/slime_doppel/gangbang_spit/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/flavor = get_doppel_flavor("doppel_gangbang_spit_finish", user, target)
	if(flavor)
		user.visible_message(span_notice(flavor))
	cleanup_doppelganger(user)

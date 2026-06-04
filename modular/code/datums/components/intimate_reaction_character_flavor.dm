/**
 * Character Flavor — accessory-free intimate reaction component.
 *
 * Unlike the other intimate_reaction subtypes (chastity, piercing, insertable)
 * which attach to an /obj/item, this component attaches directly to the MOB.
 * It provides player-authored movement flavor and sex-action reaction text
 * that fires even when no intimate accessory is equipped.
 *
 * String source:
 *   1. Player-defined custom strings from custom_intimate_reactions pref.
 *
 * All output strings are run through resolve_intimate_reaction_tokens() for
 * anatomy-aware placeholder expansion ([USER], [PENIS_TYPE], [CUPSIZE], etc.).
 *
 * Preference gating:
 *   - intimate_reaction_enabled must be TRUE on the viewer's prefs to see output.
 *   - intimate_reaction_show_accessory_free must be TRUE on the viewer's prefs.
 *   - The component only attaches when the wearer's intimate_reaction_enabled is TRUE.
 *

 */

/datum/component/intimate_reaction/character_flavor
	dupe_mode = COMPONENT_DUPE_UNIQUE
	movement_message_cooldown = 15 SECONDS
	/// Cooldown for sex_received flavor channel, separate from movement.
	var/last_sex_flavor_time = 0
	var/sex_flavor_cooldown = 8 SECONDS
	/// Preference datum that requested the component. Used during copy_to() before the mob owns its client.
	var/datum/preferences/source_preferences = null
	/// Cached reference to the wearer's custom_intimate_reactions list (from prefs).
	/// Refreshed on bind; null means there is no character flavor to emit.
	var/list/custom_strings = null
	/// Timer ID for the afterglow expiry callback (TIMER_STOPPABLE). Null when inactive.
	var/afterglow_timer_id = null
	/// Timer ID for the withdrawal expiry callback (TIMER_STOPPABLE). Null when inactive.
	var/withdrawal_timer_id = null
	/// Tracks the highest arousal the wearer reached since last reset.
	/// Used to detect when arousal crashes from a high peak for withdrawal.
	var/peak_arousal = 0

/**
 * Accepts a mob/living/carbon/human parent instead of an item.
 * Immediately binds to the parent mob.
 */
/datum/component/intimate_reaction/character_flavor/Initialize(datum/preferences/source_prefs)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	// Skip the base Initialize which checks isitem(parent).
	source_preferences = source_prefs
	var/mob/living/carbon/human/H = parent
	bind_to_wearer(H)

/**
 * Binds to the wearer mob, registering movement and sex-action signals.
 * Caches the player's custom string pool from their preferences.
 */
/datum/component/intimate_reaction/character_flavor/bind_to_wearer(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	if(wearer == H)
		return TRUE
	if(wearer)
		unbind_from_wearer(wearer)
	wearer = H
	// Register both signal channels directly — no need to call ..() since
	// we intentionally skip the base isitem() init path.
	RegisterSignal(H, COMSIG_CARBON_SEX_ACTION_RECEIVED, PROC_REF(on_wearer_sex_action_received))
	RegisterSignal(H, COMSIG_MOB_EJACULATED, PROC_REF(on_wearer_ejaculated))
	register_movement_reaction(H)
	// Cache custom strings from preferences.
	refresh_custom_strings()
	return TRUE

/**
 * Unbinds from the wearer, cleaning up all registered signals.
 */
/datum/component/intimate_reaction/character_flavor/unbind_from_wearer(mob/living/carbon/human/H)
	if(!H)
		H = wearer
	if(!H)
		return FALSE
	unregister_movement_reaction(H)
	UnregisterSignal(H, COMSIG_CARBON_SEX_ACTION_RECEIVED)
	UnregisterSignal(H, COMSIG_MOB_EJACULATED)
	// Clean up any active afterglow/withdrawal state.
	clear_afterglow(H)
	clear_withdrawal(H)
	peak_arousal = 0
	if(H == wearer)
		wearer = null
	custom_strings = null
	return TRUE

/datum/component/intimate_reaction/character_flavor/Destroy(force, silent)
	if(wearer)
		unbind_from_wearer(wearer)
	source_preferences = null
	custom_strings = null
	return ..()

/// Wearer identity check — parent is the mob itself.
/datum/component/intimate_reaction/character_flavor/is_valid_wearer_source(mob/living/carbon/human/source)
	return source && !QDELETED(source) && source == wearer && source == parent

/**
 * Refreshes the cached custom_strings from the wearer's client preferences.
 * Called on bind and can be called externally if prefs change mid-round.
 */
/datum/component/intimate_reaction/character_flavor/proc/refresh_custom_strings()
	custom_strings = null
	var/datum/preferences/P = wearer?.client?.prefs || source_preferences
	if(!P)
		return
	if(islist(P.custom_intimate_reactions) && length(P.custom_intimate_reactions))
		custom_strings = P.custom_intimate_reactions

/**
 * Checks whether the viewer mob has accessory-free flavor enabled.
 * Returns TRUE if the viewer should see character flavor text from this component.
 */
/datum/component/intimate_reaction/character_flavor/proc/viewer_can_see_flavor(mob/living/carbon/human/viewer)
	return viewer_can_see_intimate_reaction(viewer, require_accessory_free = TRUE)

/**
 * Picks a string from the player's custom pool for the given category,
 * with tier-aware fallback. Tries the requested category first, then walks
 * the custom-string fallback chain until strings are found or exhausted.
 *
 * Arguments:
 *   category  — tier-prefixed category key (e.g., "overwhelmed_sex_received")
 *   json_file — unused, kept for old callsites.
 *   json_key  — unused, kept for old callsites.
 */
/datum/component/intimate_reaction/character_flavor/proc/pick_flavor_string(category, json_file = null, json_key = null)
	if(custom_strings)
		// Try the exact requested category first.
		if(islist(custom_strings[category]) && length(custom_strings[category]))
			return _weighted_pick(category)

		// Extract the tier and context from the category key (e.g., "overwhelmed" + "sex_received").
		var/underscore_pos = findtext(category, "_")
		if(underscore_pos)
			var/tier = copytext(category, 1, underscore_pos)
			var/context = copytext(category, underscore_pos + 1)

			// Walk the fallback chain for this tier.
			var/static/list/fallback_map = INTIMATE_TIER_FALLBACK
			var/list/fallbacks = fallback_map[tier]
			if(islist(fallbacks))
				for(var/fallback_tier in fallbacks)
					var/fallback_key = "[fallback_tier]_[context]"
					if(islist(custom_strings[fallback_key]) && length(custom_strings[fallback_key]))
						return _weighted_pick(fallback_key)

			// Also check legacy bare keys as last resort (e.g., "movement", "sex_received").
			if(islist(custom_strings[context]) && length(custom_strings[context]))
				return _weighted_pick(context)

	return null

/**
 * Picks a random string from the given category, respecting per-string weights.
 * Each weight is an independent prob() gate (0-100%). Strings that pass the gate
 * enter the eligible pool and one is chosen uniformly at random.
 * If no strings pass, returns a uniformly random pick as fallback.
 */
/datum/component/intimate_reaction/character_flavor/proc/_weighted_pick(category)
	var/list/strings = custom_strings[category]
	if(!islist(strings) || !length(strings))
		return null
	var/weight_key = "weight_[category]"
	var/list/weights = custom_strings[weight_key]
	if(!islist(weights) || !length(weights))
		return pick(strings)
	var/list/eligible = list()
	for(var/i in 1 to strings.len)
		var/w = (i <= weights.len) ? weights[i] : 100
		if(prob(w))
			eligible += strings[i]
	if(!eligible.len)
		return pick(strings)
	return pick(eligible)

/**
 * Determines the current arousal/state tier for the wearer.
 * Checks incapacitation states first, then force threshold, then arousal levels.
 *
 * Arguments:
 *   source       — the wearer mob
 *   applied_force — the force level of the current action (0 for movement)
 *   pain_amt      — pain amount from the current action (0 for movement)
 *
 * Returns one of the INTIMATE_TIER_* string constants.
 */
/datum/component/intimate_reaction/character_flavor/proc/get_intimate_tier(mob/living/carbon/human/source, applied_force = 0, pain_amt = 0)
	// Broken: unconscious, dead, paralyzed, or in soft crit.
	if(source.stat >= SOFT_CRIT || source.IsParalyzed())
		return INTIMATE_TIER_BROKEN

	// Roughuse: high force overrides arousal-based tiers.
	if(applied_force >= INTIMATE_FORCE_ROUGHUSE)
		return INTIMATE_TIER_ROUGHUSE

	// Afterglow: post-orgasm haze (set by ejaculation hook, temporary trait).
	if(HAS_TRAIT(source, TRAIT_INTIMATE_AFTERGLOW))
		return INTIMATE_TIER_AFTERGLOW

	// Get arousal from sex controller.
	var/arousal = 0
	var/datum/sex_controller/sexcon = source.sexcon
	if(sexcon)
		arousal = sexcon.arousal

	// Overwhelmed: near or at orgasm threshold.
	if(arousal >= INTIMATE_AROUSAL_OVERWHELMED)
		return INTIMATE_TIER_OVERWHELMED

	// Building: moderate arousal.
	if(arousal >= INTIMATE_AROUSAL_BUILDING)
		return INTIMATE_TIER_BUILDING

	// Lusty: low-moderate arousal.
	if(arousal >= INTIMATE_AROUSAL_LUSTY)
		return INTIMATE_TIER_LUSTY

	// Withdrawal: arousal crashed from a high peak (temporary trait).
	if(HAS_TRAIT(source, TRAIT_INTIMATE_WITHDRAWAL))
		return INTIMATE_TIER_WITHDRAWAL

	return INTIMATE_TIER_NEUTRAL

// ── Afterglow / Withdrawal Hooks ─────────────────────────────────────────────

/**
 * Signal handler for COMSIG_MOB_EJACULATED.
 * Applies the afterglow trait for INTIMATE_AFTERGLOW_DURATION.
 */
/datum/component/intimate_reaction/character_flavor/proc/on_wearer_ejaculated(datum/source)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	apply_afterglow()

/**
 * Applies the afterglow trait and starts an expiry timer.
 * If afterglow is already active, the timer is reset (re-ejaculation extends it).
 */
/datum/component/intimate_reaction/character_flavor/proc/apply_afterglow()
	if(!wearer)
		return
	// Clear any existing withdrawal — afterglow supersedes it.
	clear_withdrawal(wearer)
	// Apply/refresh the afterglow trait.
	if(!HAS_TRAIT(wearer, TRAIT_INTIMATE_AFTERGLOW))
		ADD_TRAIT(wearer, TRAIT_INTIMATE_AFTERGLOW, TRAIT_SOURCE_INTIMATE_REACTION)
	// Reset/start the expiry timer.
	if(afterglow_timer_id)
		deltimer(afterglow_timer_id)
	afterglow_timer_id = addtimer(CALLBACK(src, PROC_REF(expire_afterglow)), INTIMATE_AFTERGLOW_DURATION, TIMER_STOPPABLE)

/**
 * Called when the afterglow timer expires. Removes the trait and
 * checks whether to trigger withdrawal (if arousal dropped significantly).
 */
/datum/component/intimate_reaction/character_flavor/proc/expire_afterglow()
	afterglow_timer_id = null
	if(!wearer)
		return
	REMOVE_TRAIT(wearer, TRAIT_INTIMATE_AFTERGLOW, TRAIT_SOURCE_INTIMATE_REACTION)
	// After the post-orgasm glow fades, check for withdrawal:
	// If the wearer's arousal is now low but they had been at a high peak, trigger withdrawal.
	var/current_arousal = 0
	var/datum/sex_controller/sexcon = wearer.sexcon
	if(sexcon)
		current_arousal = sexcon.arousal
	if(peak_arousal >= INTIMATE_WITHDRAWAL_AROUSAL_PEAK && current_arousal < INTIMATE_AROUSAL_BUILDING)
		apply_withdrawal()
	// Reset peak tracking after afterglow resolves.
	peak_arousal = 0

/**
 * Removes the afterglow trait and cleans up its timer.
 */
/datum/component/intimate_reaction/character_flavor/proc/clear_afterglow(mob/living/carbon/human/H)
	if(afterglow_timer_id)
		deltimer(afterglow_timer_id)
		afterglow_timer_id = null
	if(H && HAS_TRAIT(H, TRAIT_INTIMATE_AFTERGLOW))
		REMOVE_TRAIT(H, TRAIT_INTIMATE_AFTERGLOW, TRAIT_SOURCE_INTIMATE_REACTION)

/**
 * Applies the withdrawal trait for INTIMATE_WITHDRAWAL_DURATION.
 * Withdrawal triggers when: afterglow expires AND arousal has dropped from a high peak.
 */
/datum/component/intimate_reaction/character_flavor/proc/apply_withdrawal()
	if(!wearer)
		return
	if(!HAS_TRAIT(wearer, TRAIT_INTIMATE_WITHDRAWAL))
		ADD_TRAIT(wearer, TRAIT_INTIMATE_WITHDRAWAL, TRAIT_SOURCE_INTIMATE_REACTION)
	if(withdrawal_timer_id)
		deltimer(withdrawal_timer_id)
	withdrawal_timer_id = addtimer(CALLBACK(src, PROC_REF(expire_withdrawal)), INTIMATE_WITHDRAWAL_DURATION, TIMER_STOPPABLE)

/**
 * Called when the withdrawal timer expires. Removes the trait.
 */
/datum/component/intimate_reaction/character_flavor/proc/expire_withdrawal()
	withdrawal_timer_id = null
	if(!wearer)
		return
	REMOVE_TRAIT(wearer, TRAIT_INTIMATE_WITHDRAWAL, TRAIT_SOURCE_INTIMATE_REACTION)

/**
 * Removes the withdrawal trait and cleans up its timer.
 */
/datum/component/intimate_reaction/character_flavor/proc/clear_withdrawal(mob/living/carbon/human/H)
	if(withdrawal_timer_id)
		deltimer(withdrawal_timer_id)
		withdrawal_timer_id = null
	if(H && HAS_TRAIT(H, TRAIT_INTIMATE_WITHDRAWAL))
		REMOVE_TRAIT(H, TRAIT_INTIMATE_WITHDRAWAL, TRAIT_SOURCE_INTIMATE_REACTION)



// ── Movement Handler ─────────────────────────────────────────────────────────

/**
 * Fires a private movement flavor message to the wearer on a cooldown + probability gate.
 * Determines the current arousal tier and picks from the matching tier-aware category.
 */
/datum/component/intimate_reaction/character_flavor/try_handle_wearer_moved(mob/living/carbon/human/source)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_movement_message_time + movement_message_cooldown >= world.time)
		return FALSE
	if(!prob(12))
		return FALSE
	if(!viewer_can_see_flavor(source))
		return FALSE

	var/tier = get_intimate_tier(source)
	var/category = "[tier]_[INTIMATE_CONTEXT_MOVEMENT]"
	var/message = pick_flavor_string(category)
	if(!message)
		return FALSE

	var/source_message = resolve_intimate_reaction_tokens_for_viewer(message, source, null, source)
	var/viewer_message = resolve_intimate_reaction_tokens_for_viewer(message, source, null, null)
	last_movement_message_time = world.time
	emit_intimate_reaction_message(source, span_notice(viewer_message), category, INTIMATE_AUDIENCE_SELF, require_accessory_free = TRUE, self_message = span_notice(source_message))
	return TRUE

// ── Sex Action Handler ───────────────────────────────────────────────────────

/**
 * Fires a private sex-action reaction message to the wearer.
 * Determines the current arousal tier and picks from the matching tier-aware category.
 * Only fires for the receiving party (not the acting mob).
 */
/datum/component/intimate_reaction/character_flavor/try_handle_wearer_sex_action_received(mob/living/carbon/human/source, mob/living/carbon/human/acting_mob, datum/sex_controller/acting_sexcon, datum/sex_action/action, receiver_part, giving, arousal_amt, pain_amt, applied_force, applied_speed)
	if(!is_valid_wearer_source(source))
		return FALSE
	// Track peak arousal for withdrawal detection.
	var/datum/sex_controller/wearer_sexcon = source.sexcon
	if(wearer_sexcon && wearer_sexcon.arousal > peak_arousal)
		peak_arousal = wearer_sexcon.arousal
	// Broken tier allows incapacitated mobs to receive text. Only skip if dead.
	if(source.stat >= DEAD)
		return FALSE
	if(last_sex_flavor_time + sex_flavor_cooldown >= world.time)
		return FALSE
	if(!viewer_can_see_flavor(source))
		return FALSE

	var/tier = get_intimate_tier(source, applied_force, pain_amt)
	var/message
	var/message_category
	// Try anal-specific strings first when receiving anal.
	if(receiver_part & SEX_PART_ANUS)
		var/anal_category = "[tier]_[INTIMATE_CONTEXT_ANAL_SEX_RECEIVED]"
		message = pick_flavor_string(anal_category)
		if(message)
			message_category = anal_category
	// Fall back to generic sex_received if no anal-specific string was found.
	if(!message)
		var/category = "[tier]_[INTIMATE_CONTEXT_SEX_RECEIVED]"
		message = pick_flavor_string(category)
		if(message)
			message_category = category
	if(!message)
		return FALSE

	var/source_message = resolve_intimate_reaction_tokens_for_viewer(message, source, acting_mob, source)
	var/viewer_message = resolve_intimate_reaction_tokens_for_viewer(message, source, acting_mob, null)
	var/partner_resolved_message = acting_mob ? resolve_intimate_reaction_tokens_for_viewer(message, source, acting_mob, acting_mob) : null
	last_sex_flavor_time = world.time
	emit_intimate_reaction_message(source, span_notice(viewer_message), message_category, INTIMATE_AUDIENCE_SELF, require_accessory_free = TRUE, partner = acting_mob, self_message = span_notice(source_message), partner_message = partner_resolved_message ? span_notice(partner_resolved_message) : null)
	return TRUE

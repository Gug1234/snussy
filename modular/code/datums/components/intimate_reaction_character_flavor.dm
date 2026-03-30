/**
 * Character Flavor — accessory-free intimate reaction component.
 *
 * Unlike the other intimate_reaction subtypes (chastity, piercing, insertable)
 * which attach to an /obj/item, this component attaches directly to the MOB.
 * It provides player-authored movement flavor and sex-action reaction text
 * that fires even when no intimate accessory is equipped.
 *
 * String sources (in priority order):
 *   1. Player-defined custom strings from custom_intimate_reactions pref.
 *   2. Fallback JSON banks (character_movement_messages.json, etc.).
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

/// Root directory for character flavor fallback JSON banks.
#define CHARACTER_FLAVOR_STRINGS_PATH "modular/code/datums/components/strings"

/datum/component/intimate_reaction/character_flavor
	dupe_mode = COMPONENT_DUPE_UNIQUE
	movement_message_cooldown = 15 SECONDS
	/// Cooldown for sex_received flavor channel, separate from movement.
	var/last_sex_flavor_time = 0
	var/sex_flavor_cooldown = 8 SECONDS
	/// Cached reference to the wearer's custom_intimate_reactions list (from prefs).
	/// Refreshed on bind; null means "use fallback JSON banks only".
	var/list/custom_strings = null

/**
 * Accepts a mob/living/carbon/human parent instead of an item.
 * Immediately binds to the parent mob.
 */
/datum/component/intimate_reaction/character_flavor/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	// Skip the base Initialize which checks isitem(parent).
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
	if(H == wearer)
		wearer = null
	custom_strings = null
	return TRUE

/datum/component/intimate_reaction/character_flavor/Destroy(force, silent)
	if(wearer)
		unbind_from_wearer(wearer)
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
	if(!wearer?.client?.prefs)
		return
	var/datum/preferences/P = wearer.client.prefs
	if(islist(P.custom_intimate_reactions) && length(P.custom_intimate_reactions))
		custom_strings = P.custom_intimate_reactions

/**
 * Checks whether the viewer mob has accessory-free flavor enabled.
 * Returns TRUE if the viewer should see character flavor text from this component.
 */
/datum/component/intimate_reaction/character_flavor/proc/viewer_can_see_flavor(mob/living/carbon/human/viewer)
	if(!viewer?.client?.prefs)
		return TRUE // NPCs / offline mobs default to visible
	var/datum/preferences/P = viewer.client.prefs
	if(!P.intimate_reaction_enabled)
		return FALSE
	if(!P.intimate_reaction_show_accessory_free)
		return FALSE
	return TRUE

/**
 * Picks a string from the player's custom pool for the given category.
 * Falls back to the JSON bank if the player has no custom strings for that category.
 *
 * Arguments:
 *   category  — one of INTIMATE_REACTION_CATEGORIES ("movement", "sex_received", etc.)
 *   json_file — fallback JSON filename
 *   json_key  — key within the fallback JSON
 */
/datum/component/intimate_reaction/character_flavor/proc/pick_flavor_string(category, json_file, json_key)
	// Only use player-authored strings. Default JSON banks serve as templates
	// in the editor — they do not fire automatically. If the player has no
	// custom strings for this category, nothing fires.
	if(custom_strings && islist(custom_strings[category]) && length(custom_strings[category]))
		return pick(custom_strings[category])
	return null



// ── Movement Handler ─────────────────────────────────────────────────────────

/**
 * Fires a private movement flavor message to the wearer on a cooldown + probability gate.
 * Uses the "movement" category from custom strings or character_movement_messages.json fallback.
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

	var/message = pick_flavor_string("movement", "character_movement_messages.json", "character_movement")
	if(!message)
		return FALSE

	message = resolve_intimate_reaction_tokens(message, source)
	last_movement_message_time = world.time
	to_chat(source, span_notice(message))
	return TRUE

// ── Sex Action Handler ───────────────────────────────────────────────────────

/**
 * Fires a private sex-action reaction message to the wearer.
 * Uses the "sex_received" category from custom strings or character_sex_received_messages.json fallback.
 * Only fires for the receiving party (not the acting mob).
 */
/datum/component/intimate_reaction/character_flavor/try_handle_wearer_sex_action_received(mob/living/carbon/human/source, mob/living/carbon/human/acting_mob, datum/sex_controller/acting_sexcon, datum/sex_action/action, receiver_part, giving, arousal_amt, pain_amt, applied_force, applied_speed)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_sex_flavor_time + sex_flavor_cooldown >= world.time)
		return FALSE
	if(!viewer_can_see_flavor(source))
		return FALSE

	var/message = pick_flavor_string("sex_received", "character_sex_received_messages.json", "character_sex_received")
	if(!message)
		return FALSE

	message = resolve_intimate_reaction_tokens(message, source, acting_mob)
	last_sex_flavor_time = world.time
	to_chat(source, span_notice(message))
	return TRUE

#undef CHARACTER_FLAVOR_STRINGS_PATH

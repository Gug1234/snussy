// â”€â”€ Jelly Autonomous Behavior â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Adds autonomous flavor text and bead interaction to both jelly types.
// Hooks into handle_passive_insertable_effect via try_autonomous_behavior().
// The strange jelly has additional possessive/jealous behaviors.
//
// Autonomous actions fire on a cooldown to prevent spam.
// Each action has its own probability to keep things unpredictable.
//
// Flavor text loaded from strings/jelly_autonomy_flavor.json via the strings() proc.
// Tokens: [JELLY] = the jelly's display name, [PLUG] = a plug's display name.

/// Minimum interval between autonomous actions (2 minutes).
#define JELLY_AUTONOMY_INTERVAL (2 MINUTES)
/// Probability (%) of the jelly interacting with beads per passive tick.
#define JELLY_BEAD_INTERACT_CHANCE 20
/// Probability (%) of the jelly emitting ambient flavor text per passive tick.
#define JELLY_AMBIENT_FLAVOR_CHANCE 25
// Uses JELLY_STRINGS_PATH from intimate_jelly.dm (kept alive through jelly_doppelganger.dm).

/obj/item/intimate_accessory/jelly/eora
	/// Timestamp of the last autonomous action; 0 = never.
	var/last_autonomous_action = 0

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Core autonomous behavior â€” called from handle_passive_insertable_effect
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Attempts an autonomous action (bead interaction, flavor text, etc.)
/// Returns TRUE if an action was performed.
/obj/item/intimate_accessory/jelly/eora/proc/try_autonomous_behavior(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD)
		return FALSE
	if(last_autonomous_action && world.time < last_autonomous_action + JELLY_AUTONOMY_INTERVAL)
		return FALSE

	// Try bead interaction first â€” it's the most interesting
	if(prob(JELLY_BEAD_INTERACT_CHANCE) && try_bead_interaction(H))
		last_autonomous_action = world.time
		return TRUE

	// Otherwise try ambient flavor
	if(prob(JELLY_AMBIENT_FLAVOR_CHANCE) && try_ambient_flavor(H))
		last_autonomous_action = world.time
		return TRUE

	return FALSE

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Bead Interaction â€” push or pull beads worn in the same body region
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Finds any analbeads on the same wearer and pushes/pulls a bead.
/obj/item/intimate_accessory/jelly/eora/proc/try_bead_interaction(mob/living/carbon/human/H)
	var/obj/item/intimate_accessory/rear/plug/analbeads/beads
	if(istype(H.intimate_rear_insertable, /obj/item/intimate_accessory/rear/plug/analbeads))
		beads = H.intimate_rear_insertable
	if(!beads || beads.wearer != H)
		return FALSE
	if(beads.get_max_beads() <= 0)
		return FALSE

	var/max_b = beads.get_max_beads()
	var/inserted = beads.beads_inserted

	// Decide: push or pull?
	var/action
	if(inserted <= 0)
		action = "push"
	else if(inserted >= max_b)
		action = "pull"
	else
		action = prob(50) ? "push" : "pull"

	if(action == "push")
		return jelly_push_bead(H, beads)
	else
		return jelly_pull_bead(H, beads)

/// The jelly nudges a bead deeper.
/obj/item/intimate_accessory/jelly/eora/proc/jelly_push_bead(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(beads.beads_inserted >= beads.get_max_beads())
		return FALSE
	beads.beads_inserted = min(beads.beads_inserted + 1, beads.get_max_beads())
	var/msg = get_bead_push_flavor(H, beads)
	to_chat(H, span_notice(msg))
	playsound(H, 'sound/misc/mat/pop.ogg', 25, TRUE, ignore_walls = FALSE)
	beads.notify_intimate_state_change(H, "bead_pushed")
	if(H.sexcon && !H.sexcon.arousal_frozen)
		H.sexcon.adjust_arousal(0.5)
	return TRUE

/// The jelly tugs a bead free.
/obj/item/intimate_accessory/jelly/eora/proc/jelly_pull_bead(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(beads.beads_inserted <= 0)
		return FALSE
	beads.beads_inserted = max(beads.beads_inserted - 1, 0)
	var/msg = get_bead_pull_flavor(H, beads)
	to_chat(H, span_notice(msg))
	playsound(H, 'sound/misc/mat/pop.ogg', 25, TRUE, ignore_walls = FALSE)
	beads.notify_intimate_state_change(H, "bead_pulled")
	if(H.sexcon && !H.sexcon.arousal_frozen)
		H.sexcon.adjust_arousal(0.5)
	return TRUE

// â”€â”€ Bead flavor text â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Resolves [JELLY] and [PLUG] tokens in a flavor string loaded from JSON.
/obj/item/intimate_accessory/jelly/eora/proc/resolve_autonomy_tokens(text, obj/plug_item)
	. = replacetext(text, "\[JELLY\]", "[src]")
	if(plug_item)
		. = replacetext(., "\[PLUG\]", "[plug_item]")

/// Returns flavor text for the jelly pushing a bead in. Base jelly is curious and gentle.
/obj/item/intimate_accessory/jelly/eora/proc/get_bead_push_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	var/list/bank = strings("jelly_autonomy_flavor.json", "bead_push", JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_autonomy_tokens(pick(bank), beads)

/// Returns flavor text for the jelly pulling a bead out. Base jelly is playful.
/obj/item/intimate_accessory/jelly/eora/proc/get_bead_pull_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	var/list/bank = strings("jelly_autonomy_flavor.json", "bead_pull", JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_autonomy_tokens(pick(bank), beads)

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Ambient Flavor Text â€” idle jelly behavior unrelated to beads
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Emits ambient flavor text based on wearer state. Override for strange jelly.
/obj/item/intimate_accessory/jelly/eora/proc/try_ambient_flavor(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	var/msg

	// Context-sensitive flavor â€” arousal
	if(H.sexcon && H.sexcon.arousal > 70)
		msg = get_aroused_flavor(H)
	else if(H.sexcon && H.sexcon.arousal > 30)
		msg = get_restless_flavor(H)
	else
		msg = get_idle_flavor(H)

	if(!msg)
		return FALSE
	to_chat(H, span_notice(msg))
	return TRUE

/// Flavor when wearer is highly aroused. Base jelly responds sympathetically.
/obj/item/intimate_accessory/jelly/eora/proc/get_aroused_flavor(mob/living/carbon/human/H)
	var/list/bank = strings("jelly_autonomy_flavor.json", "aroused", JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_autonomy_tokens(pick(bank))

/// Flavor when wearer is moderately aroused.
/obj/item/intimate_accessory/jelly/eora/proc/get_restless_flavor(mob/living/carbon/human/H)
	var/list/bank = strings("jelly_autonomy_flavor.json", "restless", JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_autonomy_tokens(pick(bank))

/// Flavor when wearer is calm. Base jelly is content and sleepy.
/obj/item/intimate_accessory/jelly/eora/proc/get_idle_flavor(mob/living/carbon/human/H)
	var/list/bank = strings("jelly_autonomy_flavor.json", "idle", JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_autonomy_tokens(pick(bank))

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Strange Jelly Overrides â€” possessive, needy, and reactive
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Strange jelly has more opinionated bead interaction â€” possessive at high bond.
/obj/item/intimate_accessory/jelly/eora/strange/get_bead_push_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(bond_escalation_level >= 3)
		var/list/bank = strings("jelly_autonomy_flavor.json", "bead_push_possessive", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank), beads)
	if(bond_escalation_level >= 1)
		var/list/bank = strings("jelly_autonomy_flavor.json", "bead_push_bonded", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank), beads)
	return ..()

/// Strange jelly pulling beads â€” at high bond it's reluctant to give up space.
/obj/item/intimate_accessory/jelly/eora/strange/get_bead_pull_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(bond_escalation_level >= 3)
		var/list/bank = strings("jelly_autonomy_flavor.json", "bead_pull_possessive", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank), beads)
	if(bond_escalation_level >= 1)
		var/list/bank = strings("jelly_autonomy_flavor.json", "bead_pull_bonded", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank), beads)
	return ..()

/// Strange jelly aroused flavor â€” more intense and demanding.
/obj/item/intimate_accessory/jelly/eora/strange/get_aroused_flavor(mob/living/carbon/human/H)
	if(bond_escalation_level >= 3)
		var/list/bank = strings("jelly_autonomy_flavor.json", "aroused_possessive", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank))
	if(bond_escalation_level >= 2)
		var/list/bank = strings("jelly_autonomy_flavor.json", "aroused_bonded", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank))
	return ..()

/// Strange jelly restless flavor — agitated and demanding at high bond, attentive at low.
/obj/item/intimate_accessory/jelly/eora/strange/get_restless_flavor(mob/living/carbon/human/H)
	if(bond_escalation_level >= 3)
		var/list/bank = strings("jelly_autonomy_flavor.json", "restless_possessive", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank))
	if(bond_escalation_level >= 1)
		var/list/bank = strings("jelly_autonomy_flavor.json", "restless_bonded", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank))
	return ..()

/// Strange jelly idle flavor â€” needier, with personality.
/obj/item/intimate_accessory/jelly/eora/strange/get_idle_flavor(mob/living/carbon/human/H)
	if(bond_escalation_level >= 3)
		var/list/bank = strings("jelly_autonomy_flavor.json", "idle_possessive", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank))
	if(bond_escalation_level >= 1)
		var/list/bank = strings("jelly_autonomy_flavor.json", "idle_bonded", JELLY_STRINGS_PATH)
		if(length(bank))
			return resolve_autonomy_tokens(pick(bank))
	return ..()


// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Reactive Flavor â€” combat, plugs, sounding rods, and environment
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

/// Additional autonomous behavior for strange jellies â€” reacts to plugs, combat, etc.
/// Suppressed entirely when a player is controlling the jelly (they ARE the jelly).
/obj/item/intimate_accessory/jelly/eora/strange/try_autonomous_behavior(mob/living/carbon/human/H)
	if(has_bound_controller())
		return FALSE
	. = ..()
	if(.)
		return TRUE

	// Already on cooldown
	if(last_autonomous_action && world.time < last_autonomous_action + JELLY_AUTONOMY_INTERVAL)
		return FALSE

	// React to pain/combat â€” jelly notices when wearer is hurt
	if(prob(30) && H.getBruteLoss() > 30 && try_combat_reaction(H))
		last_autonomous_action = world.time
		return TRUE

	// React to plugs in adjacent slots â€” the jelly has opinions about neighbors
	if(prob(15) && try_plug_reaction(H))
		last_autonomous_action = world.time
		return TRUE

	return FALSE

/// Strange jelly reacts to the wearer being injured.
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_combat_reaction(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD)
		return FALSE
	var/json_key
	if(bond_escalation_level >= 3)
		json_key = "combat_possessive"
	else if(bond_escalation_level >= 1)
		json_key = "combat_bonded"
	else
		json_key = "combat_base"
	var/list/bank = strings("jelly_autonomy_flavor.json", json_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return FALSE
	to_chat(H, span_notice(resolve_autonomy_tokens(pick(bank))))
	return TRUE

/// Strange jelly reacts to plugs or sounding rods sharing the same body.
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_plug_reaction(mob/living/carbon/human/H)
	// Check for a genital plug or sounding rod
	var/obj/item/intimate_accessory/genital/plug/plug = H.intimate_genital_insertable
	if(!istype(plug))
		return FALSE
	var/json_key
	if(bond_escalation_level >= 3)
		json_key = "plug_possessive"
	else if(bond_escalation_level >= 1)
		json_key = "plug_bonded"
	else
		json_key = "plug_base"
	var/list/bank = strings("jelly_autonomy_flavor.json", json_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return FALSE
	to_chat(H, span_notice(resolve_autonomy_tokens(pick(bank), plug)))
	return TRUE

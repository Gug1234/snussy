// ── Slime Doppelganger ───────────────────────────────────────────────────────
// A semi-transparent slime clone of the wearer, spawned by the strange jelly
// for sex actions, idle companionship, or direct player projection.
//
// Most of the time the doppelganger behaves like a mindless puppet. At higher
// bond levels, the bonded wearer can project their own mind into the double and
// move it around within a short radius for ERP-focused play.
//
// Limitations while player-controlled:
// - cannot stray far from the wearer
// - cannot speak
// - cannot attack or do ordinary work
// - cannot carry normal gear beyond intimate accessories

/// Trait applied to slime doppelgangers to exempt them from mind/client gates.
#define TRAIT_SLIME_DOPPELGANGER "slime_doppelganger"
/// Alpha value for the semi-transparent doppelganger.
#define DOPPELGANGER_ALPHA 220
/// Minimum bond level required to manually summon the doppelganger.
#define DOPPELGANGER_SUMMON_BOND_LEVEL 2
/// Interval between idle doppelganger emotes (in deciseconds).
#define DOPPELGANGER_IDLE_EMOTE_INTERVAL 45 SECONDS
/// Maximum range for doppelganger follow behavior and direct control.
#define DOPPELGANGER_FOLLOW_RANGE 3
/// Filter name for the jelly-type color overlay on doppelgangers.
#define DOPPELGANGER_COLOR_FILTER "doppelganger_jelly_color"
/// Jelly-type overlay color for strange jelly doppelgangers.
#define DOPPELGANGER_COLOR_STRANGE "#e262c5"
/// Jelly-type overlay color for regular jelly doppelgangers.
#define DOPPELGANGER_COLOR_REGULAR "#7ec08d"
// Uses JELLY_STRINGS_PATH from intimate_jelly.dm (kept alive for this file via deferred #undef).
/mob/living/carbon/human/slime_doppelganger
	name = "slime doppelganger"
	/// The jelly that created this doppelganger.
	var/obj/item/intimate_accessory/jelly/eora/source_jelly
	/// The original human this doppelganger is cloned from.
	var/mob/living/carbon/human/source_human
	/// The body currently projecting into this doppelganger, if any.
	var/mob/living/carbon/human/controller_body
	/// The hidden shell currently projecting into this doppelganger, if any.
	var/mob/living/jelly_controller_shell/controller_shell
	/// World.time after which the next idle emote can fire.
	var/next_idle_emote = 0

/mob/living/carbon/human/slime_doppelganger/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_SLIME_DOPPELGANGER, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_INFINITE_STAMINA, TRAIT_GENERIC) // So the doppel doesn't run out of energy during sex

/mob/living/carbon/human/slime_doppelganger/Login()
	. = ..()
	if(istype(source_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = source_jelly
		strange_jelly.handle_controller_doppel_login(src)

/mob/living/carbon/human/slime_doppelganger/Logout()
	if(istype(source_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = source_jelly
		strange_jelly.handle_controller_doppel_logout(src)
	. = ..()

/// Prevents the doppelganger from being given a fresh mind on spawn.
/mob/living/carbon/human/slime_doppelganger/mind_initialize()
	return

/// Whether a player is currently projecting into this slime body.
/mob/living/carbon/human/slime_doppelganger/proc/is_player_controlled()
	return !!(mind && ((controller_body && !QDELETED(controller_body)) || (controller_shell && !QDELETED(controller_shell))))

/// Only intimate accessories are allowed to be carried in this limited form.
/mob/living/carbon/human/slime_doppelganger/proc/is_allowed_slime_item(obj/item/I)
	return istype(I, /obj/item/intimate_accessory)

/// Returns the projected player's mind to their original body.
/mob/living/carbon/human/slime_doppelganger/proc/return_controller_to_body(show_flavor = TRUE)
	if(!mind)
		return FALSE

	var/datum/mind/controller_mind = mind
	var/mob/living/carbon/human/H = controller_body
	var/mob/living/jelly_controller_shell/shell = controller_shell
	controller_body = null
	controller_shell = null

	if(shell && !QDELETED(shell))
		controller_mind.transfer_to(shell, TRUE)
		shell.refresh_controller_perspective()
		if(istype(source_jelly, /obj/item/intimate_accessory/jelly/eora/strange))
			var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = source_jelly
			if(shell == strange_jelly.controller_shell)
				strange_jelly.set_controller_state(shell.client ? "shell_bound" : "suspended")
				strange_jelly.grant_controller_action(shell)
				strange_jelly.log_controller_admin_event("[shell.ckey] returned from [strange_jelly]'s slime double to the hidden shell.")
				strange_jelly.add_controller_activity("controller", "return", "[shell.ckey] returned from slime double")
		if(show_flavor)
			var/shell_flavor = source_jelly?.get_doppelganger_flavor("doppel_return", source_human)
			if(shell_flavor && source_human)
				source_human.visible_message(span_notice(shell_flavor))
			to_chat(shell, span_notice("My awareness settles back into my resting body."))
		// Clean up the now-empty doppelganger so it doesn't linger as an SSD body.
		cleanup_doppelganger_body()
		return TRUE

	if(!H || QDELETED(H))
		return FALSE

	controller_mind.transfer_to(H, TRUE)

	if(show_flavor)
		var/flavor = source_jelly?.get_doppelganger_flavor("doppel_return", H)
		if(flavor)
			H.visible_message(span_notice(flavor))
		to_chat(H, span_notice("My awareness settles back into my own body."))
	// Clean up the now-empty doppelganger so it doesn't linger as an SSD body.
	cleanup_doppelganger_body()
	return TRUE

/**
 * Cleans up this doppelganger body after the mind has already been transferred out.
 * Clears the jelly's active_doppelganger reference and qdels the mob.
 * Safe to call when the doppelganger has no mind — Destroy() will skip re-entry.
 */
/mob/living/carbon/human/slime_doppelganger/proc/cleanup_doppelganger_body()
	if(source_jelly && source_jelly.active_doppelganger == src)
		source_jelly.active_doppelganger = null
	qdel(src)

/**
 * Resets doppelganger state for pool parking without destroying the mob.
 * Called by dismiss_doppelganger when returning a puppet body to the jelly's
 * pool slot. Clears visual overlays, controller refs, and moves to nullspace
 * so the body is inert until the next spawn_doppelganger call re-dresses it.
 * The caller is responsible for ensuring no player mind is currently inhabiting
 * this body (dismiss_doppelganger handles that via return_controller_to_body).
 */
/mob/living/carbon/human/slime_doppelganger/proc/wipe_state()
	controller_body = null
	controller_shell = null
	source_human = null
	next_idle_emote = 0
	remove_filter(DOPPELGANGER_COLOR_FILTER)
	remove_atom_colour(FIXED_COLOUR_PRIORITY)
	alpha = initial(alpha)
	moveToNullspace()

/mob/living/carbon/human/slime_doppelganger/Destroy()
	if(is_player_controlled())
		return_controller_to_body(FALSE)
	if(source_jelly && source_jelly.active_doppelganger == src)
		source_jelly.active_doppelganger = null
	source_jelly = null
	source_human = null
	controller_body = null
	controller_shell = null
	return ..()

/// Doppelgangers can't speak.
/mob/living/carbon/human/slime_doppelganger/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced)
	return

/// No autonomous life processing — the double is a puppet body.
/mob/living/carbon/human/slime_doppelganger/Life(delta_time, times_fired)
	return

/// Any incoming damage dismisses the doppelganger instead of being applied.
/// Prevents slime body-blocking abuse while keeping it strikeable.
/mob/living/carbon/human/slime_doppelganger/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = 0, forced = FALSE, spread_damage = FALSE)
	if(damage <= 0 && !forced)
		return 0
	var/turf/T = get_turf(src)
	if(T)
		T.visible_message(span_notice("[src] shudders as the blow passes through, then collapses into a wave of warm slime."))
	if(source_jelly && !QDELETED(source_jelly))
		source_jelly.dismiss_doppelganger(TRUE)
	else
		qdel(src)
	return 1

/// Enforces the short leash on player-controlled movement.
/// When already past the leash (wearer walked away), moves that close the
/// distance are still allowed so the doppel can chase back into range.
/mob/living/carbon/human/slime_doppelganger/Move(NewLoc, Dir, step_x, step_y)
	if(is_player_controlled() && source_human && !QDELETED(source_human))
		var/turf/new_turf = get_turf(NewLoc)
		var/turf/owner_turf = get_turf(source_human)
		if(new_turf && owner_turf)
			var/new_dist = get_dist(new_turf, owner_turf)
			if(new_dist > DOPPELGANGER_FOLLOW_RANGE)
				var/current_dist = get_dist(src, source_human)
				if(new_dist >= current_dist)
					to_chat(src, span_warning("I can't drift any farther from my wearer in this form."))
					return FALSE
	return ..()

/// The slime double can only carry intimate accessories, not normal equipment.
/mob/living/carbon/human/slime_doppelganger/put_in_hands(obj/item/I, del_on_fail = FALSE, merge_stacks = TRUE, forced = FALSE)
	if(forced || is_allowed_slime_item(I))
		return ..()
	to_chat(src, span_warning("This slime body can't carry ordinary gear."))
	if(del_on_fail && I)
		qdel(I)
	return FALSE

/mob/living/carbon/human/slime_doppelganger/proc/open_jelly_interface()
	set name = "Open Communion"
	set category = "Jelly"
	set desc = "Open the communion panel."

	if(!source_jelly || QDELETED(source_jelly))
		to_chat(src, span_warning("I have no stable host to anchor an interface right now."))
		return
	var/obj/item/intimate_accessory/jelly/eora/strange/strange = source_jelly
	if(!istype(strange))
		to_chat(src, span_warning("This jelly does not support a communion interface."))
		return
	strange.open_controller_menu(src)

/// Prevent equipping normal gameplay gear on the slime body.
/mob/living/carbon/human/slime_doppelganger/can_equip(obj/item/I, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE)
	if(is_allowed_slime_item(I))
		return ..()
	if(!disable_warning)
		to_chat(src, span_warning("This slime body isn't suited for equipment or adventuring gear."))
	return FALSE

/// Blocks combat and ordinary work interactions; this body is for presence, not gameplay advantage.
/mob/living/carbon/human/slime_doppelganger/UnarmedAttack(atom/A, proximity, params)
	if(A == source_human || istype(A, /obj/item/intimate_accessory))
		return ..()
	to_chat(src, span_warning("This slime body can hover and tease, but it can't fight or do ordinary labor."))
	return

/// Slime bodies cannot grab or pull.
/mob/living/carbon/human/slime_doppelganger/start_pulling(atom/movable/AM, state, force, supress_message = FALSE, obj/item/item_override)
	return FALSE

/mob/living/carbon/human/slime_doppelganger/proc/return_to_wearer_body()
	set name = "Return To Body"
	set category = "Jelly"
	set desc = "Let this shape dissolve and return to my resting body."

	if(!is_player_controlled())
		to_chat(src, span_notice("No awareness inhabits this shape right now."))
		return
	return_controller_to_body(TRUE)

/// Custom examine text indicating this is a slime construct.
/mob/living/carbon/human/slime_doppelganger/examine(mob/user)
	. = ..()
	. += span_notice("This is a translucent slime construct — a doppelganger formed from living jelly. It shimmers faintly, its features an uncanny echo of someone familiar.")
	if(source_human)
		. += span_notice("It bears the likeness of [source_human.real_name], rendered in quivering slime.")
	if(is_player_controlled())
		. += span_notice("A living will animates it, tethered close to its host.")

// ════════════════════════════════════════════════════════════════════════════
// Spawn / Dismiss — called by the strange jelly
// ════════════════════════════════════════════════════════════════════════════

/// Spawns a doppelganger of the wearer at the wearer's location.
/// Returns the doppelganger mob, or null on failure.
/// Reuses the jelly's pooled doppelganger mob when available to avoid paying
/// /mob/living/carbon/human Initialize cost on every spawn/dismiss cycle.
/obj/item/intimate_accessory/jelly/eora/proc/spawn_doppelganger()
	if(!wearer || QDELETED(wearer))
		return null
	// Only one doppelganger at a time
	if(active_doppelganger && !QDELETED(active_doppelganger))
		return active_doppelganger

	var/mob/living/carbon/human/slime_doppelganger/doppel
	var/turf/spawn_turf = get_turf(wearer)
	if(pooled_doppelganger && !QDELETED(pooled_doppelganger))
		doppel = pooled_doppelganger
		pooled_doppelganger = null
		if(spawn_turf)
			doppel.forceMove(spawn_turf)
	else
		doppel = new(spawn_turf)
	doppel.source_jelly = src
	doppel.source_human = wearer

	// Copy the wearer's appearance via DNA transfer
	if(!wearer.dna)
		QDEL_NULL(doppel)
		return null
	wearer.dna.transfer_identity(doppel)

	// Copy visual vars that transfer_identity doesn't cover
	doppel.gender = wearer.gender
	doppel.real_name = "[wearer.real_name]'s slime double"
	doppel.name = doppel.real_name
	doppel.hair_color = wearer.hair_color
	doppel.facial_hair_color = wearer.facial_hair_color
	doppel.hairstyle = wearer.hairstyle
	doppel.facial_hairstyle = wearer.facial_hairstyle
	doppel.skin_tone = wearer.skin_tone
	doppel.eye_color = wearer.eye_color
	doppel.detail = wearer.detail
	doppel.detail_color = wearer.detail_color
	doppel.voice_color = wearer.voice_color
	doppel.highlight_color = wearer.highlight_color
	doppel.accessory = wearer.accessory
	doppel.marking = wearer.marking

	// Apply the jelly's hueshift color
	if(intimate_metal_color)
		doppel.add_atom_colour(intimate_metal_color, FIXED_COLOUR_PRIORITY)
	// Semi-transparent
	doppel.alpha = DOPPELGANGER_ALPHA
	// Jelly-type colored overlay
	var/overlay_color = is_strange_jelly() ? DOPPELGANGER_COLOR_STRANGE : DOPPELGANGER_COLOR_REGULAR
	doppel.add_filter(DOPPELGANGER_COLOR_FILTER, 2, list("type" = "outline", "color" = overlay_color, "alpha" = 60, "size" = 1))

	// Apply body markings — transfer_identity() copies dna.body_markings AFTER
	// set_species(), so on_species_gain()'s apply_markings_to_body_parts() ran
	// with an empty list. Re-apply now that the data is present.
	apply_markings_to_body_parts(doppel.dna.body_markings, doppel)
	// Render appearance directly. We intentionally skip updateappearance()
	// because its parent proc overwrites gender from dna.uni_identity, which
	// still encodes the wearer's stale default gender (copy_to / transfer_identity
	// never regenerate uni_identity after setting the real gender).
	doppel.update_hair()
	doppel.update_body_parts(TRUE)

	active_doppelganger = doppel
	return doppel

/// Dismisses the active doppelganger with optional flavor text.
/// Pass silent = TRUE when the caller already displayed its own flavor.
/// The doppelganger mob is parked in the jelly's pool slot rather than
/// qdeleted so it can be reused by the next spawn without paying the full
/// /mob/living/carbon/human Initialize cost. It is only qdeleted on jelly
/// destruction or if the pool slot is already occupied.
/obj/item/intimate_accessory/jelly/eora/proc/dismiss_doppelganger(silent = FALSE)
	if(!active_doppelganger || QDELETED(active_doppelganger))
		active_doppelganger = null
		return
	var/mob/living/carbon/human/slime_doppelganger/doppel = active_doppelganger
	if(doppel.is_player_controlled())
		doppel.return_controller_to_body(TRUE)
	// return_controller_to_body() may have already cleaned up via cleanup_doppelganger_body().
	if(!silent && wearer && !QDELETED(wearer) && !QDELETED(doppel))
		wearer.visible_message(span_notice("[doppel] shudders, loses cohesion, and collapses into a wave of warm slime that flows back into [wearer]."))
	if(active_doppelganger == doppel)
		active_doppelganger = null
	if(QDELETED(doppel))
		return
	// Return to the pool rather than destroying. If the pool already holds a
	// different stale mob, qdel the newcomer to avoid leaking two at once.
	if(pooled_doppelganger && !QDELETED(pooled_doppelganger) && pooled_doppelganger != doppel)
		qdel(doppel)
		return
	doppel.wipe_state()
	pooled_doppelganger = doppel

// ════════════════════════════════════════════════════════════════════════════
// Doppelganger flavor — JSON-backed string banks with token resolution
// ════════════════════════════════════════════════════════════════════════════

/**
 * Fetches a random doppelganger flavor template from the JSON string bank
 * and resolves [USER] and [TARGET] tokens.
 * Args:
 *   bank_key - the JSON key in jelly_doppelganger_messages.json
 *   user     - mob to substitute for [USER] tokens (and pronoun helpers)
 *   target   - mob to substitute for [TARGET] tokens (optional, for gangbang actions)
 * Returns the resolved string, or null if the bank is empty/missing.
 */
/obj/item/intimate_accessory/jelly/eora/proc/get_doppelganger_flavor(bank_key, mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/bank = strings("jelly_doppelganger_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!LAZYLEN(bank))
		return null
	var/template = pick(bank)
	return resolve_doppelganger_tokens(template, user, target)

/**
 * Resolves [USER], [USER.p_them()], [USER.p_their()],
 * [TARGET], [TARGET.p_them()], [TARGET.p_their()] tokens in a template string.
 */
/obj/item/intimate_accessory/jelly/eora/proc/resolve_doppelganger_tokens(template, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!template)
		return null
	var/result = template
	if(user)
		result = replacetext(result, "\[USER\]", "[user]")
		result = replacetext(result, "\[USER.p_they()\]", "[user.p_they()]")
		result = replacetext(result, "\[USER.p_them()\]", "[user.p_them()]")
		result = replacetext(result, "\[USER.p_their()\]", "[user.p_their()]")
	if(target)
		result = replacetext(result, "\[TARGET\]", "[target]")
		result = replacetext(result, "\[TARGET.p_they()\]", "[target.p_they()]")
		result = replacetext(result, "\[TARGET.p_them()\]", "[target.p_them()]")
		result = replacetext(result, "\[TARGET.p_their()\]", "[target.p_their()]")
	return result

// ════════════════════════════════════════════════════════════════════════════
// Manual Summon / Dismiss — verb granted to the bonded wearer
// ════════════════════════════════════════════════════════════════════════════

/**
 * Grants the "Summon Slime Double" verb to the wearer.
 * Called from finalize_intimate_equip on strange jellies at bond >= DOPPELGANGER_SUMMON_BOND_LEVEL.
 */
/obj/item/intimate_accessory/jelly/eora/proc/grant_doppelganger_verb(mob/living/carbon/human/H)
	if(!H || !H.client)
		return
	H.verbs += /mob/living/carbon/human/proc/toggle_slime_doppelganger
	H.verbs += /mob/living/carbon/human/proc/project_into_slime_double

/**
 * Removes the slime-double verbs from the wearer.
 * Called from remove_intimate_accessory cleanup.
 */
/obj/item/intimate_accessory/jelly/eora/proc/revoke_doppelganger_verb(mob/living/carbon/human/H)
	if(!H)
		return
	H.verbs -= /mob/living/carbon/human/proc/toggle_slime_doppelganger
	H.verbs -= /mob/living/carbon/human/proc/project_into_slime_double

/**
 * Player verb: toggles the slime doppelganger on/off.
 * Requires the wearer's strange jelly to be at bond level >= DOPPELGANGER_SUMMON_BOND_LEVEL.
 */
/mob/living/carbon/human/proc/toggle_slime_doppelganger()
	set name = "Summon Slime Double"
	set category = "Jelly"
	set desc = "Call forth — or dismiss — your jelly's translucent double."

	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = intimate_jelly
	if(!istype(jelly) || !jelly.is_strange_jelly())
		to_chat(src, span_warning("I don't have a bonded strange jelly to command."))
		return
	if(jelly.bond_escalation_level < DOPPELGANGER_SUMMON_BOND_LEVEL)
		to_chat(src, span_warning("The jelly's bond isn't deep enough to manifest a double."))
		return

	// Toggle: dismiss if active, summon if not.
	if(jelly.active_doppelganger && !QDELETED(jelly.active_doppelganger))
		var/dismiss_flavor = jelly.get_doppelganger_flavor("doppel_dismiss", src)
		if(dismiss_flavor)
			visible_message(span_notice(dismiss_flavor))
		jelly.dismiss_doppelganger(silent = TRUE)
	else
		var/mob/living/carbon/human/slime_doppelganger/doppel = jelly.spawn_doppelganger()
		if(!doppel)
			to_chat(src, span_warning("The jelly strains but cannot form a double right now."))
			return
		var/summon_flavor = jelly.get_doppelganger_flavor("doppel_summon", src)
		if(summon_flavor)
			visible_message(span_warning(summon_flavor))

/**
 * Player verb: projects the bonded wearer's own mind into the slime double.
 * This is the actual player-controlled slime mode: a short-range, non-combat,
 * ERP-focused body that stays tethered to the wearer.
 */
/mob/living/carbon/human/proc/project_into_slime_double()
	set name = "Project Into Slime Double"
	set category = "Jelly"
	set desc = "Let the bonded jelly carry my awareness into its slime double."

	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = intimate_jelly
	if(!istype(jelly) || !jelly.is_strange_jelly())
		to_chat(src, span_warning("I don't have a bonded strange jelly to project through."))
		return
	jelly.try_project_doppelganger(src)

/**
 * Transfers the bonded wearer's mind into the doppelganger, spawning it first
 * if needed. The projected form is intentionally limited: short-range, mute,
 * no meaningful combat, and no normal gear carrying.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_project_doppelganger(mob/living/carbon/human/H)
	if(!H || H != wearer || !matches_bonded_wearer(H))
		return FALSE
	if(!H.client || !H.mind)
		to_chat(H, span_warning("My awareness can't quite catch hold of the slime right now."))
		return FALSE
	if(H.stat == DEAD)
		to_chat(H, span_warning("The dead can't project themselves into the jelly."))
		return FALSE
	if(bond_escalation_level < doppel_control_bond_level)
		to_chat(H, span_warning("The bond isn't deep enough yet for true projection into the slime double."))
		return FALSE

	var/mob/living/carbon/human/slime_doppelganger/doppel = spawn_doppelganger()
	if(!doppel || QDELETED(doppel))
		to_chat(H, span_warning("The jelly quivers, but fails to hold a stable humanoid shape."))
		return FALSE
	if(doppel.is_player_controlled())
		if(doppel.controller_body == H)
			to_chat(H, span_notice("My awareness is already threaded through the slime double."))
		else
			to_chat(H, span_warning("That slime double is already occupied."))
		return FALSE

	doppel.controller_body = H
	H.mind.transfer_to(doppel, TRUE)
	doppel.verbs += /mob/living/carbon/human/slime_doppelganger/proc/open_jelly_interface
	doppel.verbs += /mob/living/carbon/human/slime_doppelganger/proc/return_to_wearer_body

	var/flavor = get_doppelganger_flavor("doppel_project", H)
	if(flavor)
		doppel.visible_message(span_love(flavor))
	to_chat(doppel, span_notice("I settle into the slime-double. This form can't stray far from my body, can't fight, and can't carry ordinary gear."))
	return TRUE

// ════════════════════════════════════════════════════════════════════════════
// Idle Behavior — periodic emotes and follow behavior
// ════════════════════════════════════════════════════════════════════════════

/**
 * Ticks the doppelganger's idle behavior: follow the wearer and emit emotes.
 * Called from the strange jelly's passive tick when a doppelganger is active
 * and no sex action is using it.
 * Returns TRUE if an emote was emitted.
 */
/obj/item/intimate_accessory/jelly/eora/proc/tick_doppelganger_idle(mob/living/carbon/human/H)
	if(!active_doppelganger || QDELETED(active_doppelganger))
		return FALSE
	if(!H || QDELETED(H))
		return FALSE
	// Player-controlled: snap back to the wearer if they've drifted too far away.
	if(active_doppelganger.is_player_controlled())
		if(get_dist(active_doppelganger, H) > DOPPELGANGER_FOLLOW_RANGE)
			var/turf/target = get_step_towards(H, active_doppelganger)
			if(target)
				active_doppelganger.forceMove(target)
				to_chat(active_doppelganger, span_notice("The tether to my wearer pulls me back."))
		return FALSE

	// ── Follow behavior: step toward the wearer if too far ──
	if(get_dist(active_doppelganger, H) > 1)
		step_towards(active_doppelganger, H)

	// ── Idle emote: periodic flavor text ──
	if(world.time < active_doppelganger.next_idle_emote)
		return FALSE
	active_doppelganger.next_idle_emote = world.time + DOPPELGANGER_IDLE_EMOTE_INTERVAL

	var/flavor = get_doppelganger_flavor("doppel_idle", H)
	if(flavor)
		H.visible_message(span_notice(flavor))
		return TRUE
	return FALSE

// ════════════════════════════════════════════════════════════════════════════
// Cocoon Auto-Spawn — doppelganger spawns during cocoon
// ════════════════════════════════════════════════════════════════════════════

/**
 * Auto-spawns the doppelganger when the wearer enters a cocoon.
 * Called from the cocoon enter/update logic.
 * The doppelganger remains until the cocoon is removed.
 */
/obj/item/intimate_accessory/jelly/eora/proc/cocoon_spawn_doppelganger()
	if(!wearer || QDELETED(wearer))
		return null
	if(active_doppelganger && !QDELETED(active_doppelganger))
		return active_doppelganger
	var/mob/living/carbon/human/slime_doppelganger/doppel = spawn_doppelganger()
	if(doppel && wearer)
		var/flavor = get_doppelganger_flavor("doppel_summon", wearer)
		if(flavor)
			wearer.visible_message(span_warning(flavor))
	return doppel

#undef JELLY_STRINGS_PATH

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
	var/mob/living/carbon/human/slime_doppelganger/doppel = jelly.spawn_doppelganger()
	active_doppel = doppel
	return doppel

/// Dismisses the doppelganger via the jelly.
/datum/sex_action/slime_doppel/proc/cleanup_doppelganger(mob/living/carbon/human/user)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_user_strange_jelly(user)
	if(jelly)
		jelly.dismiss_doppelganger()
	active_doppel = null

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
	user.visible_message(span_warning("[user]'s jelly surges outward, coalescing into a translucent copy of [user] that pins [user.p_them()] down and pushes between [user.p_their()] legs."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/self_vaginal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.perform_sex_action(user, 3, 0, FALSE)
	user.sexcon.receive_sex_action(3, 0, FALSE, user.sexcon.force, user.sexcon.speed)
	var/msg = pick(\
		"The slime-double rolls its hips into [user], its translucent member sliding deep — every ridge and vein rendered in warm, yielding gel.",\
		"[user]'s doppelganger thrusts with rhythmic precision, the slime's body rippling with each stroke, filling [user] with pulsing warmth.",\
		"The clone drives itself into [user] with inhuman patience, the gel-flesh molding to every curve inside [user] for maximum stimulation.",\
		"[user]'s translucent double pins [user.p_their()] wrists and rocks into [user] with slow, possessive strokes, the jelly vibrating from root to tip.")
	user.visible_message(span_warning(msg))
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = get_user_strange_jelly(user)
	jelly?.advance_bond_from_sex()

/datum/sex_action/slime_doppel/self_vaginal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_notice("The slime-double shudders, loses form, and flows back into [user] in a warm rush — the jelly settling back into place with a satisfied pulse."))
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
	user.visible_message(span_warning("[user]'s jelly erupts from [user.p_their()] body, shaping itself into a translucent double that grabs [user]'s hips and spreads [user.p_them()] open from behind."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/self_anal/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.perform_sex_action(user, 3, 0, FALSE)
	user.sexcon.receive_sex_action(3, 0, FALSE, user.sexcon.force, user.sexcon.speed)
	var/msg = pick(\
		"The slime-double buries itself in [user]'s rear, the translucent shaft stretching [user] open with each slow, deliberate thrust.",\
		"[user]'s clone hammers into [user.p_their()] ass with wet, rhythmic slaps, the gel-flesh rippling with each impact.",\
		"The doppelganger hilts inside [user] and grinds, the slime vibrating in deep, pulsing waves that radiate through [user]'s core.",\
		"[user]'s translucent double drives into [user.p_their()] rear relentlessly, the slime adapting its girth to stretch [user] to the edge of comfort.")
	user.visible_message(span_warning(msg))
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = get_user_strange_jelly(user)
	jelly?.advance_bond_from_sex()

/datum/sex_action/slime_doppel/self_anal/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_notice("The slime-double melts mid-thrust, collapsing back into [user] as a warm tide of gel that leaves [user]'s rear twitching and empty."))
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
	user.visible_message(span_warning("[user]'s jelly flows upward and outward, forming a translucent clone that cups [user]'s jaw and pushes past [user.p_their()] lips."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/self_oral/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.perform_sex_action(user, 2.5, 0, FALSE)
	user.sexcon.receive_sex_action(2.5, 0, FALSE, user.sexcon.force, user.sexcon.speed)
	var/msg = pick(\
		"The doppelganger feeds itself into [user]'s mouth with slow, rocking thrusts, its translucent shaft sliding across [user]'s tongue.",\
		"[user]'s clone cradles [user.p_their()] head and pushes deeper, the warm gel filling [user]'s throat with a pulsing, living pressure.",\
		"The slime-double rocks against [user]'s face, its hips moving with lazy, possessive rhythm while its fingers knot in [user]'s hair.",\
		"[user] gags softly around the clone's slick girth, the translucent shaft visible through [user.p_their()] bulging cheek.")
	user.visible_message(span_warning(msg))
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = get_user_strange_jelly(user)
	jelly?.advance_bond_from_sex()

/datum/sex_action/slime_doppel/self_oral/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_notice("The slime-double pulls free of [user]'s mouth with a wet pop and melts, flowing back into [user]'s body and leaving [user.p_their()] lips glossy with slime."))
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
	user.visible_message(span_warning("[user]'s jelly surges out and coalesces into a translucent double of [user]. The two of them — flesh and slime — close in on [target] from both sides."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/gangbang_dp/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.perform_sex_action(target, 4, 1, TRUE)
	if(target.sexcon)
		target.sexcon.receive_sex_action(4, 1, FALSE, user.sexcon.force, user.sexcon.speed)
	var/msg = pick(\
		"[user] drives into [target] from the front while the slime-double takes [target]'s rear — the two thrust in alternating rhythm, filling both holes at once.",\
		"The translucent clone hilts inside [target]'s ass as [user] buries [user.p_them()]self in [target]'s cunt — trapped between flesh and gel, [target] can only take it.",\
		"[user] and [user.p_their()] slime double work [target] in tandem, one thrusting as the other withdraws, keeping [target] perpetually, maddeningly full.",\
		"The doppelganger grips [target]'s hips from behind as [user] pounds [target] from the front — [target] is sandwiched between two identical bodies, one warm, one cool and slick.")
	user.visible_message(span_warning(msg))
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = get_user_strange_jelly(user)
	jelly?.advance_bond_from_sex(2)

/datum/sex_action/slime_doppel/gangbang_dp/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_notice("[user]'s slime-double shudders and collapses mid-thrust, flooding [target]'s rear with warm gel before flowing back across the floor and into [user]."))
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
	user.visible_message(span_warning("[user]'s jelly erupts and takes [user]'s shape — the translucent clone steps in front of [target] and grips [target.p_their()] jaw as [user] lines up behind."))
	playsound(user, 'sound/misc/mat/insert (1).ogg', 50, TRUE, ignore_walls = FALSE)

/datum/sex_action/slime_doppel/gangbang_spit/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.sexcon.perform_sex_action(target, 4, 0.5, TRUE)
	if(target.sexcon)
		target.sexcon.receive_sex_action(4, 0.5, FALSE, user.sexcon.force, user.sexcon.speed)
	var/msg = pick(\
		"[user] thrusts into [target] from behind while the slime-double feeds its translucent member into [target]'s mouth — [target] is skewered between flesh and gel.",\
		"The clone rocks its hips against [target]'s face in time with [user]'s thrusts from behind, the two working in perfect, inhuman synchronization.",\
		"[target] gags around the doppelganger's slick girth as [user] hammers into [target] from the rear — every thrust from one end forces [target] deeper onto the other.",\
		"[user] and [user.p_their()] translucent double lock [target] between them, flesh and slime working in tandem until [target] is drooling and glassy-eyed.")
	user.visible_message(span_warning(msg))
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = get_user_strange_jelly(user)
	jelly?.advance_bond_from_sex(2)

/datum/sex_action/slime_doppel/gangbang_spit/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_notice("[user]'s slime-double pulls free of [target]'s mouth and dissolves, collapsing into a puddle of warm gel that slides across the floor and flows back into [user]."))
	cleanup_doppelganger(user)
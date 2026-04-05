// ── Jelly Autonomous Behavior ────────────────────────────────────────────────
// Adds autonomous flavor text and bead interaction to both jelly types.
// Hooks into handle_passive_insertable_effect via try_autonomous_behavior().
// The strange jelly has additional possessive/jealous behaviors.
//
// Autonomous actions fire on a cooldown to prevent spam.
// Each action has its own probability to keep things unpredictable.

/// Minimum interval between autonomous actions (2 minutes).
#define JELLY_AUTONOMY_INTERVAL (2 MINUTES)
/// Probability (%) of the jelly interacting with beads per passive tick.
#define JELLY_BEAD_INTERACT_CHANCE 20
/// Probability (%) of the jelly emitting ambient flavor text per passive tick.
#define JELLY_AMBIENT_FLAVOR_CHANCE 25

/obj/item/intimate_accessory/jelly/eora
	/// Timestamp of the last autonomous action; 0 = never.
	var/last_autonomous_action = 0

// ════════════════════════════════════════════════════════════════════════════
// Core autonomous behavior — called from handle_passive_insertable_effect
// ════════════════════════════════════════════════════════════════════════════

/// Attempts an autonomous action (bead interaction, flavor text, etc.)
/// Returns TRUE if an action was performed.
/obj/item/intimate_accessory/jelly/eora/proc/try_autonomous_behavior(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD)
		return FALSE
	if(last_autonomous_action && world.time < last_autonomous_action + JELLY_AUTONOMY_INTERVAL)
		return FALSE

	// Try bead interaction first — it's the most interesting
	if(prob(JELLY_BEAD_INTERACT_CHANCE) && try_bead_interaction(H))
		last_autonomous_action = world.time
		return TRUE

	// Otherwise try ambient flavor
	if(prob(JELLY_AMBIENT_FLAVOR_CHANCE) && try_ambient_flavor(H))
		last_autonomous_action = world.time
		return TRUE

	return FALSE

// ════════════════════════════════════════════════════════════════════════════
// Bead Interaction — push or pull beads worn in the same body region
// ════════════════════════════════════════════════════════════════════════════

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

// ── Bead flavor text ─────────────────────────────────────────────────────────

/// Returns flavor text for the jelly pushing a bead in. Base jelly is curious and gentle.
/obj/item/intimate_accessory/jelly/eora/proc/get_bead_push_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	return pick(\
		"[src] extends a curious tendril, nudging one of my beads a little deeper with a wet pop.",\
		"A pseudopod from [src] curls around one of my beads and presses it inward, the slime vibrating with apparent satisfaction.",\
		"[src] ripples lazily, and in the motion a bead slips deeper — pushed by the jelly's idle shifting.",\
		"[src] finds one of my beads and pushes it further in, the slime's membrane pulsing around the cord.",\
		"A warm tendril from [src] coils around a bead and slowly, deliberately works it deeper inside me.")

/// Returns flavor text for the jelly pulling a bead out. Base jelly is playful.
/obj/item/intimate_accessory/jelly/eora/proc/get_bead_pull_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	return pick(\
		"[src] wraps a tendril around one of my beads and tugs it free with a soft, wet pop.",\
		"A pseudopod from [src] hooks under a bead and slowly draws it out, the jelly quivering at the sensation.",\
		"[src] playfully plucks a bead loose, the slime's surface rippling with what might be amusement.",\
		"[src] coils around the bead cord and pulls — one sphere slides free, the jelly examining it briefly before losing interest.",\
		"A warm, insistent tug from [src] drags a bead free, the slime pulsing happily around the empty space left behind.")

// ════════════════════════════════════════════════════════════════════════════
// Ambient Flavor Text — idle jelly behavior unrelated to beads
// ════════════════════════════════════════════════════════════════════════════

/// Emits ambient flavor text based on wearer state. Override for strange jelly.
/obj/item/intimate_accessory/jelly/eora/proc/try_ambient_flavor(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	var/msg

	// Context-sensitive flavor — arousal
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
	return pick(\
		"[src] pulses in time with my heartbeat, its warmth spreading deeper as my arousal builds.",\
		"[src] squirms against me, its membrane flush with heat — feeding on the arousal or sharing it, I can't tell.",\
		"[src] tightens its grip on me, undulating in slow waves that match the ache building between my legs.",\
		"[src] begins to vibrate softly, a low hum that resonates through my most sensitive flesh.",\
		"[src] presses itself deeper, a warm, insistent presence that knows exactly how worked up I am.")

/// Flavor when wearer is moderately aroused.
/obj/item/intimate_accessory/jelly/eora/proc/get_restless_flavor(mob/living/carbon/human/H)
	return pick(\
		"[src] shifts restlessly, a lazy tendril tracing circles against my inner walls.",\
		"[src] stretches inside me, the slime exploring its confines with idle curiosity.",\
		"[src] pulses once, testing — then settles back down, not quite ready to commit to anything.",\
		"[src] kneads against me in slow, rhythmic pulses, not quite stimulating but impossible to ignore.",\
		"A warm ripple passes through [src], the jelly settling into a slightly different position with a wet sound only I can hear.")

/// Flavor when wearer is calm. Base jelly is content and sleepy.
/obj/item/intimate_accessory/jelly/eora/proc/get_idle_flavor(mob/living/carbon/human/H)
	return pick(\
		"[src] nestles quietly, its warmth a gentle reminder that I'm not alone in my own skin.",\
		"[src] shifts minutely, settling into my body's curves like a cat finding the perfect sleeping position.",\
		"[src]'s membrane slowly rises and falls — breathing, almost. The rhythm is oddly soothing.",\
		"[src] is still, save for the faintest pulse of warmth that radiates through my core.",\
		"A tiny tendril from [src] extends, brushes against something sensitive, then retracts — the jelly equivalent of turning over in its sleep.")

// ════════════════════════════════════════════════════════════════════════════
// Strange Jelly Overrides — possessive, needy, and reactive
// ════════════════════════════════════════════════════════════════════════════

/// Strange jelly has more opinionated bead interaction — possessive at high bond.
/obj/item/intimate_accessory/jelly/eora/strange/get_bead_push_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(bond_escalation_level >= 3)
		return pick(\
			"[src] seizes one of my beads with a possessive tendril and drives it deeper, claiming the territory as its own.",\
			"[src] wraps around a bead and shoves it inward with surprising force — the jelly does NOT appreciate sharing space with inert metal.",\
			"A thick pseudopod from [src] coils around the bead cord and pushes everything deeper, the jelly's surface bristling with territorial aggression.")
	if(bond_escalation_level >= 1)
		return pick(\
			"[src] nudges one of my beads deeper with what feels like deliberate intent, its membrane pulsing approvingly as the sphere settles.",\
			"[src] extends a warm tendril and works a bead further in, the jelly seeming to enjoy the way it changes the pressure inside me.",\
			"[src] pushes a bead inward with gentle insistence, the slime vibrating softly against the displaced sphere.")
	return ..()

/// Strange jelly pulling beads — at high bond it's reluctant to give up space.
/obj/item/intimate_accessory/jelly/eora/strange/get_bead_pull_flavor(mob/living/carbon/human/H, obj/item/intimate_accessory/rear/plug/analbeads/beads)
	if(bond_escalation_level >= 3)
		return pick(\
			"[src] grips a bead and wrenches it free with almost vindictive force — the jelly immediately expanding to fill the vacated space, refusing to cede an inch.",\
			"[src] yanks a bead loose and engulfs the empty space before my body can close around it, the slime's membrane flush with possessive heat.",\
			"A thick tendril from [src] plucks a bead free and flicks it outward, the jelly pulsing with territorial satisfaction as it claims more room inside me.")
	return ..()

/// Strange jelly aroused flavor — more intense and demanding.
/obj/item/intimate_accessory/jelly/eora/strange/get_aroused_flavor(mob/living/carbon/human/H)
	if(bond_escalation_level >= 2)
		return pick(\
			"[src] throbs inside me, its entire mass undulating in demanding waves — it can feel my arousal and it wants MORE.",\
			"[src] latches onto every sensitive surface it can reach, pulsing and sucking in frantic rhythm, the jelly drunk on my arousal.",\
			"[src] swells against my walls, tendrils probing deeper, the jelly's hunger indistinguishable from my own need.",\
			"[src] vibrates with a low, possessive hum, its membrane flushing hot as it feeds on the arousal pouring through me.",\
			"[src] clenches around me like a fist, then releases, then clenches again — milking my arousal with mechanical precision.")
	return ..()

/// Strange jelly idle flavor — needier, with personality.
/obj/item/intimate_accessory/jelly/eora/strange/get_idle_flavor(mob/living/carbon/human/H)
	if(bond_escalation_level >= 3)
		return pick(\
			"[src] grumbles silently inside me, a petulant pulse of warmth that says 'pay attention to me' without words.",\
			"[src] squeezes me once — firmly, deliberately — then settles back, its version of clearing its throat.",\
			"[src] extends a tendril to poke something sensitive, then retracts it when I flinch. Testing. Always testing.",\
			"[src] shifts its weight inside me, rearranging itself with the fussy energy of a cat that can't get comfortable when it's being ignored.",\
			"[src] pulses with low, sulky warmth. I can feel it pouting.")
	if(bond_escalation_level >= 1)
		return pick(\
			"[src] nuzzles against my inner walls, a warm, affectionate gesture from something that shouldn't be capable of affection.",\
			"[src] hums with quiet contentment, its membrane rising and falling in a rhythm that mirrors my own breathing.",\
			"[src] curls tighter, a warm weight that feels less like a parasite and more like a companion.")
	return ..()


// ════════════════════════════════════════════════════════════════════════════
// Reactive Flavor — combat, plugs, sounding rods, and environment
// ════════════════════════════════════════════════════════════════════════════

/// Additional autonomous behavior for strange jellies — reacts to plugs, combat, etc.
/obj/item/intimate_accessory/jelly/eora/strange/try_autonomous_behavior(mob/living/carbon/human/H)
	. = ..()
	if(.)
		return TRUE

	// Already on cooldown
	if(last_autonomous_action && world.time < last_autonomous_action + JELLY_AUTONOMY_INTERVAL)
		return FALSE

	// React to pain/combat — jelly notices when wearer is hurt
	if(prob(30) && H.getBruteLoss() > 30 && try_combat_reaction(H))
		last_autonomous_action = world.time
		return TRUE

	// React to plugs in adjacent slots — the jelly has opinions about neighbors
	if(prob(15) && try_plug_reaction(H))
		last_autonomous_action = world.time
		return TRUE

	return FALSE

/// Strange jelly reacts to the wearer being injured.
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_combat_reaction(mob/living/carbon/human/H)
	if(!H || H.stat == DEAD)
		return FALSE
	var/msg
	if(bond_escalation_level >= 3)
		msg = pick(\
			"[src] clenches around me protectively, its membrane hardening against my walls as if trying to armour me from the inside.",\
			"[src] pulses with agitated heat, tendrils probing my wounds from within — not healing, but cataloguing. Remembering.",\
			"[src] vibrates with a low, angry frequency. Something hurt me, and the jelly is not pleased.",\
			"[src] floods me with a sudden wave of warmth — not arousal, but something fiercer. The jelly is furious on my behalf.")
	else if(bond_escalation_level >= 1)
		msg = pick(\
			"[src] flinches inside me as pain lances through my body, the jelly contracting in sympathetic distress.",\
			"[src] trembles, its membrane rippling with what feels like anxiety as my blood pressure spikes from the injury.",\
			"[src] presses itself flat against my inner walls, making itself small — hiding from the violence.")
	else
		msg = pick(\
			"[src] shifts uncomfortably as pain rocks through me, the jelly disturbed by its host's distress.",\
			"[src] contracts sharply at the impact, an involuntary flinch from a creature that shouldn't be able to feel fear.")
	if(!msg)
		return FALSE
	to_chat(H, span_notice(msg))
	return TRUE

/// Strange jelly reacts to plugs or sounding rods sharing the same body.
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_plug_reaction(mob/living/carbon/human/H)
	// Check for a genital plug or sounding rod
	var/obj/item/intimate_accessory/genital/plug/plug = H.intimate_genital_insertable
	if(!istype(plug))
		return FALSE
	var/msg
	if(bond_escalation_level >= 3)
		// Possessive — the jelly resents the plug
		msg = pick(\
			"[src] extends a tendril toward [plug], prodding it with what feels like disdain. The jelly does not appreciate competition.",\
			"[src] pushes against [plug] from inside, testing if it can dislodge the intruder from its territory.",\
			"[src]'s membrane bristles where it touches [plug], the slime radiating territorial irritation at the inert object occupying space that should be HERS.",\
			"[src] wraps a possessive tendril around [plug] and squeezes — not enough to move it, but enough to make a point.")
	else if(bond_escalation_level >= 1)
		msg = pick(\
			"[src] curls around [plug] with apparent curiosity, the jelly's membrane pulsing as it examines the foreign object.",\
			"[src] nudges against [plug], its tendril tracing the shape of the intruder with something between interest and suspicion.",\
			"[src] presses itself against [plug], sharing warmth with the cold metal in a gesture that's almost... welcoming?")
	else
		return FALSE
	if(!msg)
		return FALSE
	to_chat(H, span_notice(msg))
	return TRUE

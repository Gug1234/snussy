// ── Slime Doppelganger ───────────────────────────────────────────────────────
// A nude, semi-transparent slime clone of the wearer, spawned by the strange
// jelly for sex actions. It has no mind, no client, no AI — it exists solely
// as a physical body for the jelly to puppet during intimate encounters.
//
// The doppelganger copies the wearer's DNA, organs, body markings, and visual
// customization, then applies the jelly's color as a hueshift and lowers alpha
// for a ghostly, semi-translucent look.
//
// Lifecycle: spawned by spawn_doppelganger(), destroyed by dismiss_doppelganger().
// Sex actions manage this lifecycle in on_start/on_finish.

/// Trait applied to slime doppelgangers to exempt them from mind/client gates.
#define TRAIT_SLIME_DOPPELGANGER "slime_doppelganger"
/// Alpha value for the semi-transparent doppelganger.
#define DOPPELGANGER_ALPHA 160

/mob/living/carbon/human/slime_doppelganger
	name = "slime doppelganger"
	status_flags = GODMODE // Invulnerable — it's slime, not flesh
	/// The jelly that created this doppelganger.
	var/obj/item/intimate_accessory/jelly/eora/strange/source_jelly
	/// The original human this doppelganger is cloned from.
	var/mob/living/carbon/human/source_human

/mob/living/carbon/human/slime_doppelganger/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_SLIME_DOPPELGANGER, TRAIT_GENERIC)

/// Prevents the doppelganger from being given a mind.
/mob/living/carbon/human/slime_doppelganger/mind_initialize()
	return

/// Doppelgangers can't speak.
/mob/living/carbon/human/slime_doppelganger/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced)
	return

/// Doppelgangers can't move on their own.
/mob/living/carbon/human/slime_doppelganger/Life(delta_time, times_fired)
	return // No life processing — it's a puppet

/// Custom examine text indicating this is a slime construct.
/mob/living/carbon/human/slime_doppelganger/examine(mob/user)
	. = ..()
	. += span_notice("This is a translucent slime construct — a doppelganger formed from living jelly. It shimmers faintly, its features an uncanny echo of someone familiar.")
	if(source_human)
		. += span_notice("It bears the likeness of [source_human.real_name], rendered in quivering slime.")

// ════════════════════════════════════════════════════════════════════════════
// Spawn / Dismiss — called by the strange jelly
// ════════════════════════════════════════════════════════════════════════════

/// Spawns a doppelganger of the wearer at the wearer's location.
/// Returns the doppelganger mob, or null on failure.
/obj/item/intimate_accessory/jelly/eora/strange/proc/spawn_doppelganger()
	if(!wearer || QDELETED(wearer))
		return null
	// Only one doppelganger at a time
	if(active_doppelganger && !QDELETED(active_doppelganger))
		return active_doppelganger

	var/mob/living/carbon/human/slime_doppelganger/doppel = new(wearer.loc)
	doppel.source_jelly = src
	doppel.source_human = wearer

	// Copy the wearer's appearance via DNA transfer
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

	// Apply the jelly's hueshift color
	if(intimate_metal_color)
		doppel.add_atom_colour(intimate_metal_color, FIXED_COLOUR_PRIORITY)
	// Semi-transparent
	doppel.alpha = DOPPELGANGER_ALPHA

	// Update appearance
	doppel.updateappearance(mutcolor_update = TRUE)
	doppel.update_body()
	doppel.update_hair()
	doppel.update_body_parts()

	active_doppelganger = doppel
	return doppel

/// Dismisses the active doppelganger with flavor text.
/obj/item/intimate_accessory/jelly/eora/strange/proc/dismiss_doppelganger()
	if(!active_doppelganger || QDELETED(active_doppelganger))
		active_doppelganger = null
		return
	var/mob/living/carbon/human/slime_doppelganger/doppel = active_doppelganger
	if(wearer && !QDELETED(wearer))
		wearer.visible_message(span_notice("[doppel] shudders, loses cohesion, and collapses into a wave of warm slime that flows back into [wearer]."))
	active_doppelganger = null
	qdel(doppel)

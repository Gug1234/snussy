// ── Manticore Tail Organ ────────────────────────────────────────────────────
// A monstrous prehensile tail tipped with a fleshy, maw-like orifice lined
// with anemone-like feelers. Functions as both a standard tail and a genital
// organ — the orifice produces sweet nectar, responds to arousal, and is
// capable of gripping, suctioning, and milking with its internal tendrils.
//
// On insertion, automatically attaches the intimate_reaction/manticore_tail
// component which produces movement and sex-received flavor text.
// Works with all existing tail-based sex actions (tailjob, tailpegging, etc.)
// because it occupies the standard ORGAN_SLOT_TAIL.

/obj/item/organ/tail/manticore
	name = "manticore tail"
	desc = "A thick, undulating appendage of dark-furred base \
		tapering into reddish serpentine scales, tipped with a \
		maw-like orifice ringed by interlocking bonelike plates. \
		Even severed, the feelers inside still twitch."
	icon_state = "severedtail"
	accessory_type = /datum/sprite_accessory/tail/manticore
	can_wag = TRUE
	/// Whether the tail orifice is currently engorged/aroused.
	var/maw_engorged = FALSE
	/// The intimate_reaction component reference, for cleanup.
	var/datum/component/intimate_reaction/manticore_tail/reaction_component

/obj/item/organ/tail/manticore/tailmaw
	name = "tailmaw"
	accessory_type = /datum/sprite_accessory/tail/tailmaw
	can_wag = FALSE

/obj/item/organ/tail/manticore/tailmaw2
	name = "tailmaw"
	accessory_type = /datum/sprite_accessory/tail/tailmaw2

/obj/item/organ/tail/manticore/tailmaw2_head
	name = "tailmaw"
	accessory_type = /datum/sprite_accessory/tail/tailmaw2_head

/obj/item/organ/tail/manticore/tailmaw2_stripes
	name = "tailmaw"
	accessory_type = /datum/sprite_accessory/tail/tailmaw2_stripes

/obj/item/organ/tail/manticore/tailmaw2_headstripes
	name = "tailmaw"
	accessory_type = /datum/sprite_accessory/tail/tailmaw2_headstripes

/obj/item/organ/tail/manticore/Initialize(mapload)
	. = ..()
	// Pre-create the component; it won't bind until Insert() provides a wearer.
	reaction_component = AddComponent(/datum/component/intimate_reaction/manticore_tail)

/obj/item/organ/tail/manticore/Destroy()
	reaction_component = null
	return ..()

/obj/item/organ/tail/manticore/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	// Bind the reaction component to the new host
	if(reaction_component)
		reaction_component.bind_to_wearer(H)

/obj/item/organ/tail/manticore/Remove(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	if(ishuman(M) && reaction_component)
		reaction_component.unbind_from_wearer(M)
	return ..()

/// Examine text that reveals the tail's current state.
/obj/item/organ/tail/manticore/proc/get_examine_text(mob/living/carbon/human/looker)
	if(!owner)
		return
	var/datum/mob_descriptor/manticore_tail/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/manticore_tail)
	return descriptor.get_standalone_text(owner, looker)

/obj/item/organ/tail/manticore/proc/get_examine_description()
	if(maw_engorged)
		return "a manticore tail whose tail-tip maw is splayed open, feelers writhing visibly and slick with sweet-smelling nectar"
	return "a manticore tail with bonelike plates sealed tightly around its tail-tip maw, with only a faint bead of fluid visible at the seam"

/datum/mob_descriptor/manticore_tail
	name = "manticore tail"
	verbage = "has"
	show_obscured = TRUE
	descriptor_color = "#ff66cc"

/datum/mob_descriptor/manticore_tail/can_describe(mob/living/described)
	if(!ishuman(described))
		return FALSE
	var/mob/living/carbon/human/H = described
	return istype(H.getorganslot(ORGAN_SLOT_TAIL), /obj/item/organ/tail/manticore)

/datum/mob_descriptor/manticore_tail/get_description(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/tail/manticore/manticore_tail = H.getorganslot(ORGAN_SLOT_TAIL)
	if(!istype(manticore_tail))
		return null
	return manticore_tail.get_examine_description()

/datum/mob_descriptor/manticore_tail/get_descriptor_color(mob/living/described)
	var/mob/living/carbon/human/H = described
	var/obj/item/organ/tail/manticore/manticore_tail = H.getorganslot(ORGAN_SLOT_TAIL)
	if(istype(manticore_tail) && manticore_tail.maw_engorged)
		return "#ff5555"
	return ..()

/// Called by the sex controller's arousal updates to toggle the maw's visual state.
/// Uses the tail's wagging system to swap between icon states:
///   "manticore" (base, unaroused — maw sealed) ↔ "manticore_wagging" (aroused — maw open, feelers visible)
/obj/item/organ/tail/manticore/proc/update_maw_state()
	if(!owner || !owner.sexcon)
		return
	var/new_state = owner.sexcon.arousal > 30
	if(new_state == maw_engorged)
		return
	maw_engorged = new_state
	// Toggle wagging — the sprite accessory's get_icon_state() reads this
	// to swap between "manticore" and "manticore_wagging" automatically
	wagging = maw_engorged
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		H.update_body_parts(TRUE)

// This file contains procs related to the rules for how intimate accessories interact with chastity devices, such as blocking access to certain slots when certain chastity traits are present, and providing reasons for why access is blocked for use in tooltips and error messages.
/obj/item/intimate_accessory/proc/front_access_block_reason(mob/living/carbon/human/H, slot_override = null)
	if(!H || get_effective_intimate_slot(slot_override) != INTIMATE_SLOT_GENITAL)
		return null
	if(!H.chastity_device)
		return null
	if(bypasses_chastity_blockers(H, slot_override))
		return null

	var/has_penis = !!H.getorganslot(ORGAN_SLOT_PENIS)
	var/has_vagina = !!H.getorganslot(ORGAN_SLOT_VAGINA)
	var/penis_blocked = HAS_TRAIT(H, TRAIT_CHASTITY_FULL) || HAS_TRAIT(H, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(H, TRAIT_CHASTITY_PENIS_BLOCKED)
	var/vagina_blocked = HAS_TRAIT(H, TRAIT_CHASTITY_FULL) || HAS_TRAIT(H, TRAIT_CHASTITY_VAGINA_BLOCKED)

	if(intimate_flags & INTIMATE_FLAG_INSERTABLE)
		if(has_vagina && !vagina_blocked)
			return null
		if(has_penis && !penis_blocked)
			return null
		return "[H]'s chastity front is sealed and cannot accept insertable accessories."

	if(has_penis && !penis_blocked)
		return null
	if(has_vagina && !vagina_blocked)
		return null
	return "[H]'s chastity front is fully sealed."

/obj/item/intimate_accessory/proc/rear_access_block_reason(mob/living/carbon/human/H, slot_override = null)
	if(!H || get_effective_intimate_slot(slot_override) != INTIMATE_SLOT_REAR)
		return null
	if(!H.chastity_device)
		return null
	if(bypasses_chastity_blockers(H, slot_override))
		return null

	if(HAS_TRAIT(H, TRAIT_CHASTITY_FULL) || HAS_TRAIT(H, TRAIT_CHASTITY_ANAL))
		return "[H]'s chastity rear shield is closed."

	if((intimate_flags & INTIMATE_FLAG_INSERTABLE) && HAS_TRAIT(H, TRAIT_CHASTITY_SPIKED))
		return "[H]'s rear access is lined with spikes right now."

	return null

/obj/item/intimate_accessory/proc/rear_blocked_by_chastity(mob/living/carbon/human/H, slot_override = null) // Returns whether the rear slot is blocked by chastity.
	return !!rear_access_block_reason(H, slot_override)

/obj/item/intimate_accessory/proc/front_blocked_by_chastity(mob/living/carbon/human/H, slot_override = null) // Returns whether the front slot is blocked by chastity.
	return !!front_access_block_reason(H, slot_override)

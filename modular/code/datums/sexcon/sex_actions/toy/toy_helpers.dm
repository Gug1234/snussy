/proc/get_dildo_in_either_hand(mob/living/carbon/human/user)
	for(var/obj/item/thing in user.held_items)
		if(thing == null)
			continue
		if(!istype(thing, /obj/item/dildo))
			continue
		return thing
	return null

/proc/get_dildo_on_belt(mob/living/carbon/human/user)
	return get_mounted_dildo(user)

/proc/get_dildo_on_chastity(mob/living/carbon/human/user)
	var/obj/item/chastity/chastity_device = user.chastity_device
	if(istype(chastity_device) && chastity_device?.attached_toy)
		return chastity_device.attached_toy
	return null

/proc/get_mounted_dildo(mob/living/carbon/human/user)
	var/obj/item/storage/belt/rogue/belt = user.belt
	if(istype(belt) && belt?.attached_toy)
		return belt.attached_toy
	var/obj/item/dildo/chastity_toy = get_dildo_on_chastity(user)
	if(chastity_toy)
		return chastity_toy
	return null

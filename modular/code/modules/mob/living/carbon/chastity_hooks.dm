/// Handles strip-panel removal of an attached toy from a worn chastity device.
/// The toy is mounted externally, so it can be detached regardless of lock state.
/mob/living/carbon/human/proc/modular_handle_chastity_toy_removal(mob/user)
	if(!user)
		return TRUE
	if(!chastity_device?.attached_toy)
		return TRUE
	if(!get_location_accessible(src, BODY_ZONE_PRECISE_GROIN, grabs = FALSE, skipundies = TRUE))
		to_chat(user, span_warning("I can't reach that! Something is covering it."))
		return TRUE
	user.visible_message(span_warning("[user] starts removing the [chastity_device.attached_toy.name] from [src]'s [chastity_device.name]."), span_warning("I start removing the [chastity_device.attached_toy.name] from [src]'s [chastity_device.name]..."))
	if(do_after(user, 30, needhand = 1, target = src))
		if(!chastity_device?.attached_toy)
			return TRUE
		chastity_device.detach_toy(user)
	return TRUE

/mob/living/carbon/human/proc/modular_handle_chastitything(mob/user)
	if(!user)
		return TRUE
	if(!get_location_accessible(src, BODY_ZONE_PRECISE_GROIN, grabs = FALSE, skipundies = TRUE))
		to_chat(user, span_warning("I can't reach that! Something is covering it."))
		return TRUE
	if(!chastity_device)
		return TRUE
	if(HAS_TRAIT(src, TRAIT_CHASTITY_LOCKED))
		to_chat(user, span_warning("I can't remove [src]'s chastity device while it's locked!"))
		return TRUE
	user.visible_message(span_warning("[user] starts removing [src]'s [chastity_device.name]."),span_warning("I start removing [src]'s [chastity_device.name]..."))
	if(do_after(user, 50, needhand = 1, target = src))
		var/obj/item/chastity/device = chastity_device
		if(!device)
			return TRUE
		device.remove_chastity(src)
		if(iscarbon(user))
			var/mob/living/carbon/carbon_user = user
			if(!carbon_user.put_in_hands(device))
				device.forceMove(get_turf(src))
		else
			device.forceMove(get_turf(src))
	return TRUE

/mob/living/carbon/human/proc/modular_handle_chastity_middleclick_strip(mob/user)
	if(!user)
		return TRUE

	if(!get_location_accessible(src, BODY_ZONE_PRECISE_GROIN, skipundies = TRUE))
		return TRUE

	if(chastity_device?.attached_toy)
		modular_handle_chastity_toy_removal(user)
		return TRUE

	if(chastity_device && chastity_device.locked)
		var/has_hammer = FALSE
		var/has_chisel = FALSE
		for(var/obj/item/held_item in user.held_items)
			if(istype(held_item, /obj/item/rogueweapon/hammer))
				has_hammer = TRUE
			if(istype(held_item, /obj/item/rogueweapon/chisel))
				has_chisel = TRUE
		if(has_hammer && has_chisel)
			var/obj/item/chastity/locked_device = chastity_device
			if(locked_device)
				locked_device.attempt_forced_removal(src, user)

	if(chastity_device && !chastity_device.locked)
		if(src == user)
			src.visible_message(span_notice("[user] begins to take off [chastity_device]..."))
		else
			src.visible_message(span_notice("[user] begins to take off [src]'s [chastity_device]..."))
		if(do_after(user, 30, needhand = 1, target = src))
			var/obj/item/chastity/device = chastity_device
			if(device && !device.locked)
				device.remove_chastity(src)
				if(!user.put_in_hands(device))
					device.forceMove(get_turf(src))

	return TRUE

/mob/living/carbon/human/proc/modular_strippanel_chastity_row()
	if(!get_location_accessible(src, BODY_ZONE_PRECISE_GROIN, skipundies = TRUE))
		return null
	var/chastity_action = "Nothing"
	if(chastity_device)
		if(HAS_TRAIT(src, TRAIT_CHASTITY_LOCKED))
			chastity_action = "Locked"
		else
			chastity_action = "Remove"
	var/chastity_row = "<tr><td><BR><B>Chastity:</B> <A href='?src=[REF(src)];chastitything=1'>"
	chastity_row += chastity_action
	chastity_row += "</A></td></tr>"
	if(chastity_device?.attached_toy)
		chastity_row += "<tr><td><B>Chastity Toy:</B> <A href='?src=[REF(src)];chastitytoything=1'>Remove</A></td></tr>"
	return chastity_row

/mob/living/carbon/human/proc/modular_chastity_attached_toy_overlay()
	if(!istype(chastity_device?.attached_toy, /obj/item/dildo))
		return null

	var/mutable_appearance/mchastitydildo = mutable_appearance('modular/icons/obj/lewd/dildo.dmi', "dildo_belt_[chastity_device.attached_toy.dildo_size]", layer = -ABOVE_BODY_FRONT_LAYER)
	mchastitydildo.color = chastity_device.attached_toy.color

	if(dna && dna.species.sexes && !dna.species.custom_clothes)
		if(gender == MALE)
			if(OFFSET_BELT in dna.species.offset_features)
				mchastitydildo.pixel_x += dna.species.offset_features[OFFSET_BELT][1]
				mchastitydildo.pixel_y += dna.species.offset_features[OFFSET_BELT][2]
		else
			if(OFFSET_BELT_F in dna.species.offset_features)
				mchastitydildo.pixel_x += dna.species.offset_features[OFFSET_BELT_F][1]
				mchastitydildo.pixel_y += dna.species.offset_features[OFFSET_BELT_F][2]

	return mchastitydildo

/**
 * Called by toggle_extreme_ERP() (via hascall) when the player disables extreme ERP content.
 * If the player is currently wearing a spiked chastity device, it is forcibly removed and
 * dropped at their feet — spiked devices are extreme content and must not remain on a player
 * who has opted out of that category. Spiked status is determined by TRAIT_CHASTITY_SPIKED
 * being present in the device's chastity_standard_traits entry (the authoritative source).
 * Non-spiked devices are left undisturbed.
 */
/client/proc/modular_handle_extreme_erp_toggle_disable()
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/human_mob = mob
	var/obj/item/chastity/device = human_mob.chastity_device
	if(!device || !(TRAIT_CHASTITY_SPIKED in GLOB.chastity_standard_traits[device.chastity_type + 1]))
		return
	device.remove_chastity(human_mob)
	device.forceMove(get_turf(human_mob))
	human_mob.visible_message(span_notice("[human_mob]'s spiked chastity device falls away as the divine hand of Eora rejects the cruel ironwork."))

/client/proc/modular_handle_chastity_toggle_disable()
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/human_mob = mob
	var/obj/item/chastity/device = human_mob.chastity_device
	if(device)
		device.remove_chastity(human_mob)
		device.forceMove(get_turf(human_mob))
		human_mob.visible_message(span_notice("The divine hand of Eora slips [device] free from [human_mob]'s loins!"))

/**
 * Called when the player disables cursed-collar content from the options menu.
 * Strips any currently worn cursed collar, cursed chastity device, and/or cursed piercing.
 */
/client/proc/modular_handle_cursed_toggle_disable()
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/human_mob = mob

	// Strip cursed chastity device
	var/obj/item/chastity/device = human_mob.chastity_device
	if(device?.chastity_cursed)
		device.cleanup_cursed_binding(human_mob)
		device.remove_chastity(human_mob)
		device.forceMove(get_turf(human_mob))
		human_mob.visible_message(span_notice("The divine hand of Eora dissolves the cursed bindings from [human_mob]'s loins!"))

	// Strip cursed collar
	var/obj/item/clothing/neck/roguetown/cursed_collar/collar = human_mob.get_item_by_slot(SLOT_NECK)
	if(istype(collar))
		REMOVE_TRAIT(collar, TRAIT_NODROP, CURSED_ITEM_TRAIT)
		SEND_SIGNAL(human_mob, COMSIG_CARBON_LOSE_COLLAR)
		human_mob.dropItemToGround(collar, force = TRUE)
		human_mob.visible_message(span_notice("The divine hand of Eora shatters the cursed collar from [human_mob]'s neck!"))

	// Strip cursed piercings
	if(human_mob.remove_cursed_piercings(FALSE))
		human_mob.visible_message(span_notice("The divine hand of Eora twists the cursed piercing free from [human_mob]'s flesh!"))

/client/proc/modular_handle_intimate_accessories_toggle_disable()
	if(!ishuman(mob))
		return
	var/mob/living/carbon/human/human_mob = mob
	if(human_mob.remove_cursed_piercings(FALSE))
		human_mob.visible_message(span_notice("The divine hand of Eora rejects the cursed intimate piercing from [human_mob]'s body!"))

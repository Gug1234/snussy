/mob/living/carbon/proc/carbon_modular_examine_extension(mob/user, t_He, m1, m2, m3)
	var/list/lines = list()
	if(user.client?.prefs && !user.client.prefs.chastenable)
		return lines
	if(sexcon?.has_chastity_cage() && get_location_accessible(src, BODY_ZONE_PRECISE_GROIN))
		lines += "[t_He] is wearing a chastity device!\n"
	return lines

/mob/living/carbon/human/proc/human_modular_examine_extension(mob/user, observer_privilege, m1, m2, m3)
	var/list/lines = list()
	var/user_is_gnoll = FALSE
	var/user_is_clergy = FALSE
	var/user_is_inquisition = FALSE
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		user_is_gnoll = H.dna?.species?.id == "gnoll"
		user_is_inquisition = HAS_TRAIT(H, TRAIT_INQUISITION) || (H.mind?.assigned_role in GLOB.inquisition_positions)
		user_is_clergy = user_is_inquisition || (H.mind?.assigned_role in GLOB.church_positions)
		if(user_is_gnoll)
			var/datum/antagonist/gnoll/gnoll_antag = H.mind?.has_antag_datum(/datum/antagonist/gnoll)
			if(gnoll_antag?.is_examine_marked_target(src))
				lines += span_cultsmall("Graggar has marked them!")
			if(src.has_gnoll_scent_this_round)
				lines += span_cultsmall("They have gnoll scent, a breeder!")
	if(src.has_gnoll_scent_this_round && !user_is_gnoll)
		if(user_is_inquisition)
			lines += span_warning("They reek of profane beast-taint. This demands scrutiny.")
		else if(user_is_clergy)
			lines += span_warning("A profane, feral scent clings to them.")
		else
			lines += span_warning("They have a strange scent about them...")


	// ── Manticore tail maw examine text ──
	var/obj/item/organ/tail/manticore/manticore_tail = getorganslot(ORGAN_SLOT_TAIL)
	if(istype(manticore_tail))
		var/groin_visible = observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)
		if(groin_visible)
			var/maw_text = manticore_tail.get_examine_text(user)
			if(maw_text)
				lines += maw_text

	var/viewer_chastity_ok = !user.client?.prefs || user.client.prefs.chastenable
	if(viewer_chastity_ok && chastity_device && (observer_privilege || get_location_accessible(src, BODY_ZONE_PRECISE_GROIN)))
		var/chastity_name = get_examine_item_name_with_hover(user, chastity_device)
		var/lock_text = chastity_device.locked ? " locked" : ""
		lines += "<span style='color:#ff66cc'>[m3] [chastity_name][lock_text] over [m2] nethers.</span>"

	var/viewer_intimate_ok = !user.client?.prefs || user.client.prefs.intimate_enabled
	var/wearer_intimate_ok = !client?.prefs || (client.prefs.intimate_enabled && client.prefs.show_intimate_examine)
	if(viewer_intimate_ok && wearer_intimate_ok && length(intimate_accessories))
		add_visible_intimate_examine_accessory(lines, user, intimate_genital_insertable, BODY_ZONE_PRECISE_GROIN, observer_privilege, get_genital_insertable_examine_part(intimate_genital_insertable))
		add_visible_intimate_examine_accessory(lines, user, intimate_rear_insertable, BODY_ZONE_PRECISE_GROIN, observer_privilege, "rear")
		add_visible_intimate_examine_accessory(lines, user, intimate_breast_insertable, BODY_ZONE_CHEST, observer_privilege, "chest")
		add_visible_intimate_examine_accessory(lines, user, intimate_mouth_insertable, BODY_ZONE_PRECISE_MOUTH, observer_privilege, "mouth")

	// Append an examine link to open the intimate accessories panel when:
	//   • the subject has accessories worn
	//   • both parties have intimate accessories enabled
	//   • the wearer has opted in to showing the link (show_intimate_examine)
	if(viewer_intimate_ok && wearer_intimate_ok && length(intimate_accessories))
		lines += span_notice("<a href='?src=[REF(src)];task=view_intimate'>View [m2] intimate accessories...</a>")

	return lines


/mob/living/carbon/human/proc/human_modular_intimate_piercing_examine_lines(mob/user, observer_privilege)
	var/list/lines = list()
	var/viewer_intimate_ok = !user.client?.prefs || user.client.prefs.intimate_enabled
	var/wearer_intimate_ok = !client?.prefs || (client.prefs.intimate_enabled && client.prefs.show_intimate_examine)
	if(!viewer_intimate_ok || !wearer_intimate_ok || !length(intimate_accessories))
		return lines
	if(!has_visible_intimate_piercing_body_descriptor(user, list(/datum/mob_descriptor/penis, /datum/mob_descriptor/vagina)))
		add_visible_intimate_examine_accessory(lines, user, intimate_genital_piercing, BODY_ZONE_PRECISE_GROIN, observer_privilege, "sex", FALSE, FALSE)
	if(!has_visible_intimate_piercing_body_descriptor(user, list(/datum/mob_descriptor/breasts)))
		add_visible_intimate_examine_accessory(lines, user, intimate_breast_piercing, BODY_ZONE_CHEST, observer_privilege, "nipples", TRUE, FALSE)
	add_visible_intimate_examine_accessory(lines, user, intimate_rear_piercing, BODY_ZONE_PRECISE_GROIN, observer_privilege, "rear", FALSE, FALSE)
	add_visible_intimate_examine_accessory(lines, user, intimate_mouth_piercing, BODY_ZONE_PRECISE_MOUTH, observer_privilege, "tongue", FALSE, FALSE)
	add_visible_intimate_examine_accessory(lines, user, intimate_ear_piercing, BODY_ZONE_PRECISE_EARS, observer_privilege, "ears", TRUE, FALSE)
	add_visible_intimate_examine_accessory(lines, user, intimate_nose_piercing, BODY_ZONE_PRECISE_NOSE, observer_privilege, "nose", FALSE, FALSE)
	add_visible_intimate_examine_accessory(lines, user, intimate_belly_piercing, BODY_ZONE_PRECISE_STOMACH, observer_privilege, "belly button", FALSE, FALSE)
	return lines

/mob/living/carbon/human/proc/has_visible_intimate_piercing_body_descriptor(mob/user, list/descriptor_types)
	for(var/descriptor_type in descriptor_types)
		var/datum/mob_descriptor/descriptor = MOB_DESCRIPTOR(descriptor_type)
		if(descriptor.can_describe(src) && descriptor.can_user_see(src, user))
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/human_modular_intimate_jewelry_examine_lines(mob/user, observer_privilege)
	return human_modular_intimate_piercing_examine_lines(user, observer_privilege)


/mob/living/carbon/human/proc/add_visible_intimate_examine_accessory(list/accessory_lines, mob/user, obj/item/intimate_accessory/accessory, body_zone, observer_privilege, part, part_plural = FALSE, explicit_span = TRUE)
	if(!accessory || QDELETED(accessory))
		return
	if(!observer_privilege && !get_location_accessible(src, body_zone))
		return
	var/line = accessory.get_intimate_examine_line(src, user, part, part_plural)
	if(!line)
		return
	if(explicit_span)
		accessory_lines += "<span style='color:#ff66cc'>[line]</span>"
	else
		accessory_lines += line

/mob/living/carbon/human/proc/can_show_intimate_piercing_descriptor(mob/user, obj/item/intimate_accessory/accessory, body_zone)
	if(!user)
		return FALSE
	if(!accessory || QDELETED(accessory))
		return FALSE
	if(!(accessory.intimate_flags & INTIMATE_FLAG_PIERCING))
		return FALSE
	var/viewer_intimate_ok = !user?.client?.prefs || user.client.prefs.intimate_enabled
	var/wearer_intimate_ok = !client?.prefs || (client.prefs.intimate_enabled && client.prefs.show_intimate_examine)
	if(!viewer_intimate_ok || !wearer_intimate_ok)
		return FALSE
	if(!isobserver(user) && !get_location_accessible(src, body_zone))
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/get_inline_intimate_piercing_descriptor(mob/user, obj/item/intimate_accessory/accessory, body_zone)
	if(!can_show_intimate_piercing_descriptor(user, accessory, body_zone))
		return null
	var/accessory_name = get_examine_item_name_with_hover(user, accessory, accessory.get_intimate_examine_colored_name())
	return "pierced through with [accessory.get_intimate_examine_article()] [accessory_name]"

/mob/living/carbon/human/proc/append_inline_intimate_piercing_descriptor(base_description, mob/user, obj/item/intimate_accessory/accessory, body_zone)
	var/piercing_descriptor = get_inline_intimate_piercing_descriptor(user, accessory, body_zone)
	if(!piercing_descriptor)
		return base_description
	return "[base_description], [piercing_descriptor]"


/mob/living/carbon/human/proc/get_genital_insertable_examine_part(obj/item/intimate_accessory/accessory)
	if(istype(accessory, /obj/item/intimate_accessory/genital/plug/sounding_rod))
		return "urethra"
	return "sex"


/mob/living/carbon/human/proc/human_modular_chastity_toy_examine_line(mob/user, m2, m3)
	if(!chastity_device?.attached_toy)
		return null
	if(user.client?.prefs && !user.client.prefs.chastenable)
		return null
	var/perception_level = 15
	if(isliving(user))
		var/mob/living/L = user
		perception_level = L.STAPER
	if(!isobserver(user) && !get_location_accessible(src, BODY_ZONE_PRECISE_GROIN))
		return null
	if(!isobserver(user) && perception_level < 8)
		return null
	return "[m3] [get_examine_item_name_with_hover(user, chastity_device.attached_toy)] attached to [m2] chastity device. "

/**
 * # Intimate Accessory Menu
 *
 * Runtime TGUI panel for inspecting and removing base intimate accessories.
 * This first-PR version only exposes equipped item slots and bead controls.
 * Shelved decoration editors stay outside this player-facing surface.
 */

/mob/living/carbon/human/verb/intimate_accessory_menu()
	set name = "Manage Intimate Accessories"
	set category = "IC"

	if(client?.prefs && !client.prefs.intimate_enabled)
		to_chat(src, span_warning("I have intimate accessories disabled."))
		return
	open_intimate_menu_for(src)

/mob/living/carbon/human/var/datum/intimate_menu/intimate_menu_instance

/// Opens this human's intimate accessory panel for a viewer.
/mob/living/carbon/human/proc/open_intimate_menu_for(mob/viewer)
	if(!viewer)
		return
	if(!intimate_menu_instance || QDELETED(intimate_menu_instance))
		intimate_menu_instance = new /datum/intimate_menu(src)
	intimate_menu_instance.ui_interact(viewer)

/datum/intimate_menu
	/// Human whose accessories are displayed.
	var/mob/living/carbon/human/wearer

/datum/intimate_menu/New(mob/living/carbon/human/H)
	if(!H)
		qdel(src)
		return
	wearer = H
	return ..()

/datum/intimate_menu/Destroy(force)
	wearer = null
	return ..()

/datum/intimate_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntimateMenu", "Intimate Accessories", 520, 580)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/intimate_menu/ui_data(mob/user)
	var/list/data = list()
	if(!wearer || QDELETED(wearer))
		data["invalid"] = TRUE
		return data
	if(user?.client?.prefs && !user.client.prefs.intimate_enabled)
		data["invalid"] = TRUE
		return data
	if(wearer.client?.prefs && !wearer.client.prefs.intimate_enabled)
		data["invalid"] = TRUE
		return data

	var/is_self = (user == wearer)
	data["wearer_name"] = wearer.real_name
	data["is_self"] = is_self

	var/list/slots_data = list()
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_GENITAL, "Genital Piercing", wearer.intimate_genital_piercing, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_GENITAL, "Genital Insertable", wearer.intimate_genital_insertable, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_REAR, "Rear Piercing", wearer.intimate_rear_piercing, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_REAR, "Rear Insertable", wearer.intimate_rear_insertable, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BREAST, "Breast Piercing", wearer.intimate_breast_piercing, BODY_ZONE_CHEST))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BREAST, "Breast Insertable", wearer.intimate_breast_insertable, BODY_ZONE_CHEST))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_MOUTH, "Mouth Piercing", wearer.intimate_mouth_piercing, BODY_ZONE_PRECISE_MOUTH))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_MOUTH, "Mouth Insertable", wearer.intimate_mouth_insertable, BODY_ZONE_PRECISE_MOUTH))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_EAR, "Ear Piercing", wearer.intimate_ear_piercing, BODY_ZONE_PRECISE_EARS))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_NOSE, "Nose Piercing", wearer.intimate_nose_piercing, BODY_ZONE_PRECISE_NOSE))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BELLY, "Belly Piercing", wearer.intimate_belly_piercing, BODY_ZONE_PRECISE_STOMACH))
	data["slots"] = slots_data
	return data

/// Builds one slot row for TGUI.
/datum/intimate_menu/proc/_build_slot_entry(mob/user, is_self, slot, slot_name, obj/item/intimate_accessory/acc, body_zone)
	var/list/entry = list("slot" = slot, "slot_name" = slot_name)
	if(!acc || QDELETED(acc))
		entry["occupied"] = FALSE
		entry["concealed"] = FALSE
		entry["item"] = null
		return entry

	entry["occupied"] = TRUE
	var/visible = is_self || get_location_accessible(wearer, body_zone)
	entry["concealed"] = !visible
	if(!visible)
		entry["item"] = null
		return entry

	entry["item"] = _build_item_data(user, acc, is_self)
	return entry

/// Builds item detail data for a visible accessory.
/datum/intimate_menu/proc/_build_item_data(mob/user, obj/item/intimate_accessory/acc, is_self)
	var/list/data = list(
		"ref" = REF(acc),
		"name" = acc.name,
		"metal" = acc.intimate_metal_name || "metal",
		"metal_color" = acc.intimate_metal_color || acc.color || "#FFFFFF",
		"has_socket" = acc.has_socketed_insert(),
		"socket_desc" = acc.current_gem_descriptor,
		"gem_color" = acc.intimate_gem_color || "#FFFFFF",
		"is_insertable" = !!(acc.intimate_flags & INTIMATE_FLAG_INSERTABLE),
		"is_piercing" = !!(acc.intimate_flags & INTIMATE_FLAG_PIERCING),
		"is_beriddled" = acc.is_beriddled(),
		"is_silver" = acc.is_silver,
		"can_remove" = acc.passes_access_checks(wearer, user, null, TRUE),
		"can_customize_descriptor" = FALSE,
		"custom_descriptor" = "",
	)

	if(is_self && istype(acc, /obj/item/intimate_accessory/piercing))
		var/obj/item/intimate_accessory/piercing/piercing = acc
		data["can_customize_descriptor"] = TRUE
		data["custom_descriptor"] = piercing.custom_piercing_descriptor || ""

	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = acc
	if(istype(beads))
		var/max_beads = beads.get_max_beads()
		var/inserted = clamp(beads.beads_inserted, 0, max_beads)
		data["is_beads"] = TRUE
		data["beads_inserted"] = inserted
		data["max_beads"] = max_beads
		data["can_push_beads"] = inserted < max_beads
		data["can_pull_beads"] = inserted > 0
		data["can_ripcord_beads"] = inserted >= 2
	else
		data["is_beads"] = FALSE
		data["beads_inserted"] = 0
		data["max_beads"] = 0
		data["can_push_beads"] = FALSE
		data["can_pull_beads"] = FALSE
		data["can_ripcord_beads"] = FALSE
	return data

/datum/intimate_menu/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	if(!wearer || QDELETED(wearer))
		return FALSE

	var/obj/item/intimate_accessory/accessory = locate(params["ref"])
	if(!accessory || QDELETED(accessory) || accessory.wearer != wearer)
		return FALSE

	switch(action)
		if("remove_accessory")
			return _intimate_act_remove_accessory(usr, accessory)
		if("set_piercing_descriptor")
			return _intimate_act_set_piercing_descriptor(usr, accessory, params["descriptor"])
		if("push_beads")
			return _intimate_act_push_beads(usr, accessory)
		if("pull_beads")
			return _intimate_act_pull_beads(usr, accessory)
		if("ripcord_beads")
			return _intimate_act_ripcord_beads(usr, accessory)
	return FALSE

/// Returns TRUE when a viewer can manipulate the selected accessory.
/datum/intimate_menu/proc/_can_act_on_accessory(mob/user, obj/item/intimate_accessory/accessory)
	if(!user || !accessory || !wearer || QDELETED(wearer))
		return FALSE
	if(user != wearer && !user.Adjacent(wearer))
		return FALSE
	return accessory.passes_access_checks(wearer, user)

/// Removes an accessory through the panel.
/datum/intimate_menu/proc/_intimate_act_remove_accessory(mob/user, obj/item/intimate_accessory/accessory)
	if(!_can_act_on_accessory(user, accessory))
		return FALSE
	var/remove_delay = (user == wearer) ? 25 : 35
	if(!do_after(user, accessory.get_intimate_action_delay(remove_delay), needhand = 1, target = wearer))
		return FALSE
	if(!_can_act_on_accessory(user, accessory))
		return FALSE
	accessory.remove_intimate_accessory(wearer)
	if(!QDELETED(accessory))
		accessory.forceMove(get_turf(wearer))
	return TRUE

/datum/intimate_menu/proc/_intimate_act_set_piercing_descriptor(mob/user, obj/item/intimate_accessory/accessory, descriptor)
	if(user != wearer)
		return FALSE
	if(!istype(accessory, /obj/item/intimate_accessory/piercing))
		return FALSE
	var/obj/item/intimate_accessory/piercing/piercing = accessory
	piercing.set_custom_piercing_descriptor(descriptor)
	var/slot_key = piercing.get_intimate_preference_slot_key()
	if(slot_key && wearer.client?.prefs)
		wearer.client.prefs.set_intimate_piercing_descriptor(slot_key, piercing.custom_piercing_descriptor)
		wearer.client.prefs.save_character()
	return TRUE

/// Pushes one bead deeper.
/datum/intimate_menu/proc/_intimate_act_push_beads(mob/user, obj/item/intimate_accessory/accessory)
	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = accessory
	if(!istype(beads) || !_can_act_on_accessory(user, beads))
		return FALSE
	if(beads.beads_inserted >= beads.get_max_beads())
		return FALSE
	var/message = beads.get_push_bead_message(user, wearer)
	if(!message)
		message = "[user] pushes another bead into [wearer]."
	user.visible_message(span_notice(message))
	if(!do_after(user, beads.get_intimate_action_delay(20), needhand = 1, target = wearer))
		return FALSE
	if(!_can_act_on_accessory(user, beads) || beads.beads_inserted >= beads.get_max_beads())
		return FALSE
	beads.beads_inserted++
	playsound(wearer, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)
	beads.notify_intimate_state_change(wearer, "beads_pushed")
	return TRUE

/// Pulls one bead outward, removing the accessory when the last bead leaves.
/datum/intimate_menu/proc/_intimate_act_pull_beads(mob/user, obj/item/intimate_accessory/accessory)
	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = accessory
	if(!istype(beads) || !_can_act_on_accessory(user, beads) || beads.beads_inserted <= 0)
		return FALSE
	var/message = beads.get_pull_bead_message(user, wearer)
	if(!message)
		message = "[user] pulls one bead out of [wearer]."
	user.visible_message(span_notice(message))
	if(!do_after(user, beads.get_intimate_action_delay(20), needhand = 1, target = wearer))
		return FALSE
	if(!_can_act_on_accessory(user, beads) || beads.beads_inserted <= 0)
		return FALSE
	beads.beads_inserted--
	playsound(wearer, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)
	if(beads.beads_inserted <= 0)
		beads.remove_intimate_accessory(wearer)
		if(!QDELETED(beads))
			beads.forceMove(get_turf(wearer))
	else
		beads.notify_intimate_state_change(wearer, "beads_pulled")
	return TRUE

/// Pulls all inserted beads out in one action.
/datum/intimate_menu/proc/_intimate_act_ripcord_beads(mob/user, obj/item/intimate_accessory/accessory)
	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = accessory
	if(!istype(beads) || !_can_act_on_accessory(user, beads) || beads.beads_inserted < 2)
		return FALSE
	var/message = beads.get_ripcord_message(user, wearer, FALSE)
	if(message)
		user.visible_message(span_warning(message))
	if(!do_after(user, beads.get_intimate_action_delay(35), needhand = 1, target = wearer))
		return FALSE
	if(!_can_act_on_accessory(user, beads) || beads.beads_inserted < 1)
		return FALSE
	beads.on_ripcord(user, wearer, FALSE)
	beads.beads_inserted = 0
	beads.remove_intimate_accessory(wearer)
	if(!QDELETED(beads))
		beads.forceMove(get_turf(wearer))
	return TRUE

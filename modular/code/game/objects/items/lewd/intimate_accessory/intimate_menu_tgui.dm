/**
 * intimate_menu_tgui.dm — TGUI inventory panel for worn intimate accessories.
 *
 * Opened by the wearer via IC verb, or by observers clicking the examine link.
 * The datum stores the `wearer`; the viewer is tracked as `ui.user` by TGUI.
 *
 * Visibility rules:
 *   - Wearer always sees all four slots and every item detail.
 *   - Observers see item details only when get_location_accessible() confirms
 *     the slot zone is uncovered; otherwise the slot shows as "Concealed".
 *
 * Physical interactions (Remove / Push Beads / Pull Beads) require:
 *   - user.Adjacent(wearer) when user != wearer.
 *   - do_after delay before committing the action.
 *   - Post-delay re-validation of worn state.
 *
 * Anal bead depth cycle (push): short → medium → long (capped).
 * Anal bead depth cycle (pull): long → medium → short → removed.
 *
 * ui_data slot shape:
 *   slot        — INTIMATE_SLOT_* constant (1–4)
 *   slot_name   — display label ("Genital", "Rear", "Breast", "Mouth / Misc")
 *   occupied    — TRUE when an accessory is worn
 *   concealed   — TRUE when worn but hidden by clothing
 *   item        — AccessoryData assoc list, or null when empty/concealed
 *
 * AccessoryData keys:
 *   ref, name, metal, metal_color, has_socket, socket_desc, gem_color,
 *   is_insertable, is_piercing, is_beriddled, is_silver, can_remove,
 *   is_beads, bead_depth, can_push_beads, can_pull_beads
 */

/// Self-inspect shortcut — opens the wearer's own accessory panel.
/mob/living/carbon/human/verb/intimate_accessory_menu()
	set name = "Manage Intimate Accessories"
	set category = "IC"

	if(client?.prefs && !client.prefs.chastenable)
		to_chat(src, span_warning("I have intimate content disabled."))
		return

	open_intimate_menu_for(src)

/**
 * Opens the intimate accessories panel for `viewer` looking at this human.
 * Called from the verb above (self) and from the examine topic handler (observer).
 */
/mob/living/carbon/human/proc/open_intimate_menu_for(mob/viewer)
	if(!viewer)
		return
	var/datum/intimate_menu/menu = new(src)
	menu.ui_interact(viewer)

/datum/intimate_menu
	/// The human whose accessories are displayed in this session.
	var/mob/living/carbon/human/wearer

/datum/intimate_menu/New(mob/living/carbon/human/H)
	if(!H)
		qdel(src)
		return
	wearer = H
	..()

/datum/intimate_menu/Destroy()
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

	// Both parties must have intimate content enabled.
	if(user?.client?.prefs && !user.client.prefs.chastenable)
		data["invalid"] = TRUE
		return data
	if(wearer.client?.prefs && !wearer.client.prefs.chastenable)
		data["invalid"] = TRUE
		return data

	var/is_self = (user == wearer)
	data["wearer_name"] = wearer.real_name
	data["is_self"] = is_self

	// Always emit all four canonical slots so the frontend can render the full inventory grid.
	var/list/slots_data = list()
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_GENITAL, "Genital",    wearer.intimate_genital, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_REAR,    "Rear",       wearer.intimate_rear,    BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BREAST,  "Breast",     wearer.intimate_breast,  BODY_ZONE_CHEST))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_MOUTH,   "Mouth/Misc", (wearer.intimate_mouth || wearer.intimate_misc), BODY_ZONE_PRECISE_MOUTH))
	data["slots"] = slots_data
	return data

/**
 * Builds one slot entry for ui_data.
 * `body_zone` is used only when checking observer visibility via get_location_accessible().
 */
/datum/intimate_menu/proc/_build_slot_entry(mob/user, is_self, slot, slot_name, obj/item/intimate_accessory/acc, body_zone)
	var/list/entry = list()
	entry["slot"]      = slot
	entry["slot_name"] = slot_name

	if(!acc || QDELETED(acc))
		entry["occupied"]  = FALSE
		entry["concealed"] = FALSE
		entry["item"]      = null
		return entry

	entry["occupied"] = TRUE
	// Wearers always see their own slots; observers need the zone to be uncovered.
	var/visible = is_self || get_location_accessible(wearer, body_zone)
	entry["concealed"] = !visible
	entry["item"]      = visible ? _build_item_data(user, acc) : null
	return entry

/// Builds the full AccessoryData assoc list for one visible worn item.
/datum/intimate_menu/proc/_build_item_data(mob/user, obj/item/intimate_accessory/acc)
	var/list/d = list()
	d["ref"]          = REF(acc)
	d["name"]         = acc.name
	d["metal"]        = acc.intimate_metal_name ? acc.intimate_metal_name : "unknown"
	d["metal_color"]  = acc.intimate_metal_color ? acc.intimate_metal_color : "#FFFFFF"
	d["has_socket"]   = acc.has_socketed_insert()
	d["socket_desc"]  = acc.current_gem_descriptor
	d["gem_color"]    = acc.intimate_gem_color ? acc.intimate_gem_color : "#FFFFFF"
	d["is_insertable"] = !!(acc.intimate_flags & INTIMATE_FLAG_INSERTABLE)
	d["is_piercing"]   = !!(acc.intimate_flags & INTIMATE_FLAG_PIERCING)
	d["is_beriddled"]  = acc.is_beriddled()
	d["is_silver"]     = acc.is_silver
	d["can_remove"]    = acc.passes_access_checks(wearer, user, null, TRUE)

	// Anal-bead specific depth data for push/pull UI controls.
	var/is_beads = istype(acc, /obj/item/intimate_accessory/rear/plug/analbeads)
	d["is_beads"] = is_beads
	if(is_beads)
		var/obj/item/intimate_accessory/rear/plug/analbeads/beads = acc
		var/depth = beads.get_bead_length()
		d["bead_depth"]      = depth
		d["can_push_beads"]  = (depth != "long")
		d["can_pull_beads"]  = TRUE
	else
		d["bead_depth"]      = null
		d["can_push_beads"]  = FALSE
		d["can_pull_beads"]  = FALSE

	return d

/datum/intimate_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	var/mob/user = ui?.user || usr

	if(!wearer || QDELETED(wearer))
		return TRUE

	// Re-validate content preferences on every action.
	if(user?.client?.prefs && !user.client.prefs.chastenable)
		return TRUE
	if(wearer.client?.prefs && !wearer.client.prefs.chastenable)
		return TRUE

	// Observers must be adjacent; the wearer is always close enough to themselves.
	if(user != wearer && !user.Adjacent(wearer))
		to_chat(user, span_warning("I need to be closer to interact with that."))
		return TRUE

	switch(action)
		if("remove_accessory")
			return _intimate_act_remove(user, params)
		if("push_beads")
			return _intimate_act_push_beads(user, params)
		if("pull_beads")
			return _intimate_act_pull_beads(user, params)

	return TRUE

/// Removes a worn accessory after a short delay. Re-validates state post-delay.
/datum/intimate_menu/proc/_intimate_act_remove(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE

	var/obj/item/intimate_accessory/acc = locate(acc_ref)
	if(!acc || QDELETED(acc) || !(acc in wearer.intimate_accessories))
		to_chat(user, span_warning("That accessory is no longer worn."))
		return TRUE

	if(!acc.passes_access_checks(wearer, user, null, TRUE))
		to_chat(user, span_warning("I cannot access that right now."))
		return TRUE

	if(user == wearer)
		user.visible_message(span_notice("[user] starts removing [acc]..."))
	else
		user.visible_message(span_notice("[user] starts removing [acc] from [wearer]..."))

	var/remove_delay = (user == wearer) ? 25 : 35
	if(!do_after(user, remove_delay, needhand = 1, target = wearer))
		return TRUE

	if(!wearer || QDELETED(wearer) || QDELETED(acc) || !(acc in wearer.intimate_accessories))
		to_chat(user, span_warning("Something changed while removing the accessory."))
		return TRUE

	acc.remove_intimate_accessory(wearer)
	if(!QDELETED(acc))
		acc.forceMove(get_turf(wearer))

	if(user == wearer)
		to_chat(user, span_notice("I remove [acc]."))
	else
		to_chat(user, span_notice("I remove [acc] from [wearer]."))
	return TRUE

/// Advances anal bead insertion depth one step: short → medium → long.
/datum/intimate_menu/proc/_intimate_act_push_beads(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE

	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = locate(acc_ref)
	if(!beads || QDELETED(beads) || beads.wearer != wearer)
		to_chat(user, span_warning("Those beads are no longer worn."))
		return TRUE

	var/depth = beads.get_bead_length()
	if(depth == "long")
		to_chat(user, span_warning("The beads are already pushed in as far as they can go."))
		return TRUE

	if(user == wearer)
		user.visible_message(span_notice("[user] slowly pushes the beads deeper..."))
	else
		user.visible_message(span_notice("[user] slowly pushes the beads deeper into [wearer]..."))

	if(!do_after(user, 20, needhand = 1, target = wearer))
		return TRUE

	if(!wearer || QDELETED(wearer) || QDELETED(beads) || beads.wearer != wearer)
		return TRUE

	var/next_depth = (depth == "short") ? "medium" : "long"
	beads.bead_count = next_depth
	beads.update_item_visuals()
	beads.notify_intimate_state_change(wearer, "bead_pushed")

	if(user == wearer)
		to_chat(user, span_notice("I push the beads deeper. They sit at [next_depth] depth now."))
	else
		to_chat(user, span_notice("I push the beads deeper into [wearer]. They sit at [next_depth] depth now."))
	return TRUE

/// Reduces anal bead insertion depth one step, removing them entirely at minimum depth.
/datum/intimate_menu/proc/_intimate_act_pull_beads(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE

	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = locate(acc_ref)
	if(!beads || QDELETED(beads) || beads.wearer != wearer)
		to_chat(user, span_warning("Those beads are no longer worn."))
		return TRUE

	if(user == wearer)
		user.visible_message(span_notice("[user] starts pulling the beads out..."))
	else
		user.visible_message(span_notice("[user] starts pulling the beads out of [wearer]..."))

	if(!do_after(user, 20, needhand = 1, target = wearer))
		return TRUE

	if(!wearer || QDELETED(wearer) || QDELETED(beads) || beads.wearer != wearer)
		return TRUE

	var/depth = beads.get_bead_length()
	if(depth == "short")
		// Fully withdraw at minimum depth.
		beads.remove_intimate_accessory(wearer)
		if(!QDELETED(beads))
			beads.forceMove(get_turf(wearer))
		if(user == wearer)
			to_chat(user, span_notice("I pull the beads out completely."))
		else
			to_chat(user, span_notice("I pull the beads out of [wearer] completely."))
		return TRUE

	var/prev_depth = (depth == "long") ? "medium" : "short"
	beads.bead_count = prev_depth
	beads.update_item_visuals()
	beads.notify_intimate_state_change(wearer, "bead_pulled")

	if(user == wearer)
		to_chat(user, span_notice("I pull the beads back a little. They sit at [prev_depth] depth now."))
	else
		to_chat(user, span_notice("I pull the beads back in [wearer]. They sit at [prev_depth] depth now."))
	return TRUE



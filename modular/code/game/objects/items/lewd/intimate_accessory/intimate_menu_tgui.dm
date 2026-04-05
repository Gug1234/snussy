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

	if(client?.prefs && !client.prefs.intimate_enabled)
		to_chat(src, span_warning("I have intimate accessories disabled."))
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

	// Both parties must have intimate accessories enabled.
	if(user?.client?.prefs && !user.client.prefs.intimate_enabled)
		data["invalid"] = TRUE
		return data
	if(wearer.client?.prefs && !wearer.client.prefs.intimate_enabled)
		data["invalid"] = TRUE
		return data

	var/is_self = (user == wearer)
	data["wearer_name"] = wearer.real_name
	data["is_self"] = is_self
	// Propagate the wearer's paper-doll visual preference so the frontend can
	// conditionally render widget imagery once art assets exist.
	data["show_visual_widgets"] = wearer.client?.prefs ? !!wearer.client.prefs.intimate_visual_widgets : FALSE

	// Emit all sub-slots — each region has a piercing and insertable sub-slot, plus the jelly slot.
	var/list/slots_data = list()
	// Genital region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_GENITAL, "Genital Piercing",    wearer.intimate_genital_piercing, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_GENITAL, "Genital Insertable",  wearer.intimate_genital_insertable, BODY_ZONE_PRECISE_GROIN))
	// Rear region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_REAR,    "Rear Piercing",       wearer.intimate_rear_piercing, BODY_ZONE_PRECISE_GROIN))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_REAR,    "Rear Insertable",     wearer.intimate_rear_insertable, BODY_ZONE_PRECISE_GROIN))
	// Breast region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BREAST,  "Breast Piercing",     wearer.intimate_breast_piercing, BODY_ZONE_CHEST))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BREAST,  "Breast Insertable",   wearer.intimate_breast_insertable, BODY_ZONE_CHEST))
	// Mouth region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_MOUTH,   "Mouth Piercing",      wearer.intimate_mouth_piercing, BODY_ZONE_PRECISE_MOUTH))
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_MOUTH,   "Mouth Insertable",    wearer.intimate_mouth_insertable, BODY_ZONE_PRECISE_MOUTH))
	// Jelly slot
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_JELLY,   "Jelly",               wearer.intimate_jelly, BODY_ZONE_PRECISE_GROIN))
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

	// Anal-bead specific data for push/pull UI controls.
	var/is_beads = istype(acc, /obj/item/intimate_accessory/rear/plug/analbeads)
	d["is_beads"] = is_beads
	if(is_beads)
		var/obj/item/intimate_accessory/rear/plug/analbeads/beads = acc
		var/inserted = beads.beads_inserted
		var/max_b = beads.get_max_beads()
		d["beads_inserted"]  = inserted
		d["max_beads"]       = max_b
		d["can_push_beads"]  = (inserted < max_b)
		d["can_pull_beads"]  = TRUE
		d["can_ripcord_beads"] = (inserted >= 2) // Need at least 2 beads for a ripcord
	else
		d["beads_inserted"]  = 0
		d["max_beads"]       = 0
		d["can_push_beads"]  = FALSE
		d["can_pull_beads"]  = FALSE
		d["can_ripcord_beads"] = FALSE

	// Eora jelly — slot management, commands, and (for strange) need/neglect state.
	var/is_eora_jelly = istype(acc, /obj/item/intimate_accessory/jelly/eora)
	d["is_eora_jelly"] = is_eora_jelly
	if(is_eora_jelly)
		var/obj/item/intimate_accessory/jelly/eora/jelly = acc
		var/current_slot = jelly.get_effective_intimate_slot()
		d["current_slot"]      = current_slot
		d["current_slot_name"] = jelly.get_intimate_slot_display_name()
		d["is_internal_slot"]  = jelly.is_internal_jelly_slot()

		// Swap options: every supported slot except the one the jelly currently occupies.
		var/list/swap_opts = list()
		for(var/s in jelly.get_supported_intimate_slots())
			if(s != current_slot)
				swap_opts += list(list("slot" = s, "name" = jelly.get_intimate_slot_display_name(s)))
		d["swap_slot_options"] = swap_opts

		// Stimulate cooldown — hide the button label-only when on cooldown.
		d["can_stimulate"] = !(jelly.last_jelly_stimulate && world.time < jelly.last_jelly_stimulate + jelly.jelly_stimulate_interval)
		d["can_eat_cum"]   = jelly.is_internal_jelly_slot()

		// Strange jelly fields: needs, neglect, bond, and per-viewer action flags.
		var/is_strange = jelly.is_strange_jelly()
		d["is_strange_jelly"] = is_strange
		if(is_strange)
			var/obj/item/intimate_accessory/jelly/eora/strange/strange = jelly
			strange.update_needs_state()
			d["need_level"]          = strange.need_level
			d["max_need_level"]      = strange.max_need_level
			d["need_state"]          = strange.get_need_state()
			d["neglect_level"]       = strange.neglect_level
			d["max_neglect_level"]   = strange.max_neglect_level
			d["neglect_state"]       = strange.get_neglect_state()
			d["bond_escalation_level"] = strange.bond_escalation_level
			d["max_bond_escalation_level"] = strange.max_bond_escalation_level
			d["bond_state"]          = strange.get_bond_state()
			d["bond_progress"]       = strange.bond_progress
			d["bond_progress_threshold"] = strange.bond_progress_threshold
			d["obsession_level"]     = strange.obsession_level
			d["has_bonded_wearer"]   = strange.has_bonded_wearer()
			d["bonded_wearer_name"]  = strange.bonded_name
			d["custom_jelly_name"]   = strange.custom_jelly_name
			d["is_cocooned"]         = strange.cocooned
			// Determine whether the viewer is the bonded wearer.
			var/is_bonded_wearer = ishuman(user) && strange.matches_bonded_wearer(user)
			d["is_bonded_wearer"] = is_bonded_wearer
			// Soothe: only for the bonded wearer when there is need/neglect to address.
			d["can_soothe"] = is_bonded_wearer \
				&& (strange.need_level > 0 || strange.neglect_level > 0) \
				&& !(strange.last_need_soothe && world.time < strange.last_need_soothe + strange.need_soothe_interval)
			// Tend: for adjacent observers who are NOT the bonded wearer.
			d["can_tend"] = !is_bonded_wearer \
				&& strange.has_bonded_wearer() \
				&& !(strange.last_tended && world.time < strange.last_tended + strange.tend_interval)
		else
			d["need_level"]          = 0
			d["max_need_level"]      = 0
			d["need_state"]          = null
			d["neglect_level"]       = 0
			d["max_neglect_level"]   = 0
			d["neglect_state"]       = null
			d["bond_escalation_level"] = 0
			d["max_bond_escalation_level"] = 0
			d["bond_state"]          = null
			d["bond_progress"]       = 0
			d["bond_progress_threshold"] = 0
			d["obsession_level"]     = 0
			d["has_bonded_wearer"]   = FALSE
			d["bonded_wearer_name"]  = null
			d["custom_jelly_name"]   = null
			d["is_cocooned"]         = FALSE
			d["is_bonded_wearer"]    = FALSE
			d["can_soothe"]          = FALSE
			d["can_tend"]            = FALSE
	else
		d["is_eora_jelly"]   = FALSE

	return d

/datum/intimate_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	var/mob/user = ui?.user || usr

	if(!wearer || QDELETED(wearer))
		return TRUE

	// Re-validate content preferences on every action.
	if(user?.client?.prefs && !user.client.prefs.intimate_enabled)
		return TRUE
	if(wearer.client?.prefs && !wearer.client.prefs.intimate_enabled)
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
		if("ripcord_beads")
			return _intimate_act_ripcord_beads(user, params)
		// ── Eora jelly commands ────────────────────────────────────────────────
		if("jelly_swap_slot")
			return _intimate_act_jelly_swap_slot(user, params)
		if("jelly_eat_cum")
			return _intimate_act_jelly_eat_cum(user, params)
		if("jelly_stimulate")
			return _intimate_act_jelly_stimulate(user, params)
		if("jelly_soothe")
			return _intimate_act_jelly_soothe(user, params)
		if("jelly_comfort")
			return _intimate_act_jelly_comfort(user, params)
		if("jelly_rename")
			return _intimate_act_jelly_rename(user, params)

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

/// Pushes one more bead in. Increments beads_inserted up to max_beads.
/datum/intimate_menu/proc/_intimate_act_push_beads(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE

	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = locate(acc_ref)
	if(!beads || QDELETED(beads) || beads.wearer != wearer)
		to_chat(user, span_warning("Those beads are no longer worn."))
		return TRUE

	var/max_b = beads.get_max_beads()
	if(beads.beads_inserted >= max_b)
		to_chat(user, span_warning("All [max_b] beads are already inserted."))
		return TRUE

	var/custom_push_msg = beads.get_push_bead_message(user, wearer)
	if(custom_push_msg)
		user.visible_message(span_notice(custom_push_msg))
	else if(user == wearer)
		user.visible_message(span_notice("[user] slowly pushes another bead in..."))
	else
		user.visible_message(span_notice("[user] slowly pushes another bead into [wearer]..."))

	if(!do_after(user, 20, needhand = 1, target = wearer))
		return TRUE

	if(!wearer || QDELETED(wearer) || QDELETED(beads) || beads.wearer != wearer)
		return TRUE

	if(beads.beads_inserted >= max_b)
		return TRUE

	beads.beads_inserted = min(beads.beads_inserted + 1, max_b)
	playsound(wearer, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)
	beads.notify_intimate_state_change(wearer, "bead_pushed")

	if(user == wearer)
		to_chat(user, span_notice("I push another bead in. [beads.beads_inserted] of [max_b] beads are now inserted."))
	else
		to_chat(user, span_notice("I push another bead into [wearer]. [beads.beads_inserted] of [max_b] beads are now inserted."))
	return TRUE

/// Pulls one bead out. At 1 bead, removes the beads entirely and applies arousal based on how many were inserted.
/datum/intimate_menu/proc/_intimate_act_pull_beads(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE

	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = locate(acc_ref)
	if(!beads || QDELETED(beads) || beads.wearer != wearer)
		to_chat(user, span_warning("Those beads are no longer worn."))
		return TRUE

	var/custom_pull_msg = beads.get_pull_bead_message(user, wearer)
	if(custom_pull_msg)
		user.visible_message(span_notice(custom_pull_msg))
	else if(user == wearer)
		user.visible_message(span_notice("[user] starts pulling a bead out..."))
	else
		user.visible_message(span_notice("[user] starts pulling a bead out of [wearer]..."))

	if(!do_after(user, 20, needhand = 1, target = wearer))
		return TRUE

	if(!wearer || QDELETED(wearer) || QDELETED(beads) || beads.wearer != wearer)
		return TRUE

	if(beads.beads_inserted <= 1)
		// Fully withdraw the last bead — remove_intimate_accessory handles arousal gain.
		beads.remove_intimate_accessory(wearer)
		if(!QDELETED(beads))
			beads.forceMove(get_turf(wearer))
		if(user == wearer)
			to_chat(user, span_notice("I pull the beads out completely."))
		else
			to_chat(user, span_notice("I pull the beads out of [wearer] completely."))
		return TRUE

	beads.beads_inserted = max(beads.beads_inserted - 1, 0)
	playsound(wearer, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)
	beads.notify_intimate_state_change(wearer, "bead_pulled")

	var/max_b = beads.get_max_beads()
	if(user == wearer)
		to_chat(user, span_notice("I pull a bead out. [beads.beads_inserted] of [max_b] beads remain inserted."))
	else
		to_chat(user, span_notice("I pull a bead out of [wearer]. [beads.beads_inserted] of [max_b] beads remain inserted."))
	return TRUE

// ── Ripcord handler — yank all beads out at once ─────────────────────────────

/datum/intimate_menu/proc/_intimate_act_ripcord_beads(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/rear/plug/analbeads/beads = locate(acc_ref)
	if(!istype(beads) || QDELETED(beads))
		return TRUE
	var/mob/living/carbon/human/wearer = beads.wearer
	if(!wearer || QDELETED(wearer) || beads.wearer != wearer)
		return TRUE
	if(beads.beads_inserted <= 0)
		to_chat(user, span_warning("There are no beads inserted to pull out."))
		return TRUE

	var/violent = istype(user.rmb_intent, /datum/rmb_intent/strong)
	var/count = beads.beads_inserted

	// Show the ripcord message
	var/ripcord_msg = beads.get_ripcord_message(user, wearer, violent)
	if(ripcord_msg)
		user.visible_message(span_warning(ripcord_msg))

	// Ripcord delay — violent is fast, gentle is slow
	var/delay = violent ? 10 : (count * 5)
	if(!do_after(user, delay, needhand = 1, target = wearer))
		return TRUE

	if(!wearer || QDELETED(wearer) || QDELETED(beads) || beads.wearer != wearer)
		return TRUE

	// Yank them all
	beads.beads_inserted = 0
	playsound(wearer, 'sound/misc/mat/pop.ogg', 65, TRUE, ignore_walls = FALSE)
	beads.notify_intimate_state_change(wearer, "beads_ripcorded")

	// Apply consequences
	beads.on_ripcord(user, wearer, violent)

	if(user == wearer)
		to_chat(user, span_notice("I rip all [count] beads out at once. 0 of [beads.get_max_beads()] beads remain inserted."))
	else
		to_chat(user, span_notice("I rip all [count] beads out of [wearer] at once. 0 of [beads.get_max_beads()] beads remain inserted."))
	return TRUE

// ── Eora jelly action handlers ────────────────────────────────────────────────

/**
 * Relocates a worn eora jelly to a different intimate slot without a full remove/re-equip.
 * Only the wearer may command their own jelly to move. Slot value arrives as a string
 * from TGUI so text2num conversion is required before forwarding to jelly_swap_to_slot.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_swap_slot(mob/user, list/params)
	if(user != wearer)
		to_chat(user, span_warning("Only the wearer can command the jelly to move."))
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || jelly.wearer != wearer)
		return TRUE
	var/target_slot = text2num(params["slot"])
	if(isnull(target_slot))
		return TRUE
	jelly.jelly_swap_to_slot(target_slot, wearer)
	return TRUE

/**
 * Commands the worn eora jelly to aggressively consume any retained internal fluids.
 * Only functions when the jelly occupies an internal slot (genital or rear).
 */
/datum/intimate_menu/proc/_intimate_act_jelly_eat_cum(mob/user, list/params)
	if(user != wearer)
		to_chat(user, span_warning("Only the wearer can command the jelly."))
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.jelly_eat_internal_cum(wearer)
	return TRUE

/**
 * Triggers a manual stimulation burst from the jelly, applying a larger arousal spike
 * than the passive tick. Subject to jelly_stimulate_interval cooldown.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_stimulate(mob/user, list/params)
	if(user != wearer)
		to_chat(user, span_warning("Only the wearer can command the jelly."))
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.jelly_stimulate_wearer(wearer)
	return TRUE

/**
 * The bonded wearer attends to their strange jelly, reducing need and (when need is zero)
 * also decrementing neglect. Forwards to try_soothe_needs which enforces the cooldown.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_soothe(mob/user, list/params)
	if(user != wearer)
		to_chat(user, span_warning("Only the bonded wearer can soothe this jelly."))
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	if(!jelly.try_soothe_needs(wearer))
		to_chat(user, span_notice("[jelly] doesn't need soothing yet, or is still settling."))
	else
		to_chat(user, span_love("I gently attend to [jelly], and it settles against me with a warm pulse of contentment."))
	return TRUE

/**
 * An adjacent observer comforts a strange jelly worn by someone nearby, providing a
 * half-strength need reduction with no neglect benefit. Forwards to try_comfort_jelly
 * which enforces the tend_interval cooldown. The wearer must use jelly_soothe instead.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_comfort(mob/user, list/params)
	if(user == wearer)
		to_chat(user, span_warning("Use 'Soothe' to attend to the jelly yourself."))
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.try_comfort_jelly(user)
	return TRUE


/**
 * Allows the bonded wearer to give the strange jelly a custom name.
 * Strips HTML, limits to 24 characters. Empty input clears the name.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_rename(mob/user, list/params)
	if(user != wearer)
		to_chat(user, span_warning("Only the bonded wearer can name this jelly."))
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	if(!jelly.matches_bonded_wearer(wearer))
		to_chat(user, span_warning("The jelly doesn't recognize me — it refuses the name."))
		return TRUE

	// Open a proper BYOND text input dialog
	var/new_name = tgui_input_text(user, "Name your jelly (max 24 characters):", "Rename Jelly", jelly.custom_jelly_name || "", 24)
	if(isnull(new_name))
		return TRUE // cancelled
	if(QDELETED(jelly) || jelly.wearer != wearer)
		return TRUE // jelly removed while dialog was open

	new_name = strip_html_simple(new_name, 24)
	if(!length(new_name))
		jelly.custom_jelly_name = null
		jelly.name = initial(jelly.name)
		to_chat(user, span_notice("I let the jelly's name fade — it's just a jelly again."))
		return TRUE

	jelly.custom_jelly_name = new_name
	jelly.name = new_name
	to_chat(user, span_love("I whisper the name '[new_name]' to the jelly. It pulses warmly in recognition."))
	return TRUE

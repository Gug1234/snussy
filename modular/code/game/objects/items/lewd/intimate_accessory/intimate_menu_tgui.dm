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

/mob/living/carbon/human/var/datum/intimate_menu/intimate_menu_instance

/**
 * Opens the intimate accessories panel for `viewer` looking at this human.
 * Called from the verb above (self) and from the examine topic handler (observer).
 */
/mob/living/carbon/human/proc/open_intimate_menu_for(mob/viewer)
	if(!viewer)
		return
	if(!intimate_menu_instance || QDELETED(intimate_menu_instance))
		intimate_menu_instance = new /datum/intimate_menu(src)
	intimate_menu_instance.ui_interact(viewer)

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
	// Ear region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_EAR,     "Ear Piercing",        wearer.intimate_ear_piercing, BODY_ZONE_PRECISE_EARS))
	// Nose region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_NOSE,    "Nose Piercing",       wearer.intimate_nose_piercing, BODY_ZONE_PRECISE_NOSE))
	// Belly region
	slots_data += list(_build_slot_entry(user, is_self, INTIMATE_SLOT_BELLY,   "Belly Piercing",      wearer.intimate_belly_piercing, BODY_ZONE_PRECISE_STOMACH))
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
	if(!visible && istype(acc, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange = acc
		visible = strange.is_controller_viewer(user)
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

	// Eora jelly — slot management, commands, and (for strange) need/jealousy/resentment state.
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
		// Remaining cooldown in seconds (0 when ready).
		if(jelly.last_jelly_stimulate && world.time < jelly.last_jelly_stimulate + jelly.jelly_stimulate_interval)
			d["stimulate_cooldown"] = round((jelly.last_jelly_stimulate + jelly.jelly_stimulate_interval - world.time) / 10)
		else
			d["stimulate_cooldown"] = 0
		d["can_eat_cum"]   = jelly.is_internal_jelly_slot()

		// Strange jelly fields: needs, jealousy, resentment, bond, and per-viewer action flags.
		var/is_strange = jelly.is_strange_jelly()
		d["is_strange_jelly"] = is_strange
		if(is_strange)
			var/obj/item/intimate_accessory/jelly/eora/strange/strange = jelly
			d["need_level"]          = strange.need_level
			d["max_need_level"]      = strange.max_need_level
			d["need_state"]          = strange.get_need_state()
			d["jealousy_level"]      = strange.jealousy_level
			d["max_jealousy_level"]  = strange.max_jealousy_level
			d["jealousy_state"]      = strange.get_jealousy_state()
			d["resentment_level"]    = strange.resentment_level
			d["max_resentment_level"] = strange.max_resentment_level
			d["resentment_state"]    = strange.get_resentment_state()
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
			d["has_bound_controller"] = strange.has_bound_controller()
			d["bound_controller_name"] = strange.get_bound_controller_name()
			d["controller_applications_open"] = strange.is_accepting_controller_applications()
			d["pending_controller_application_count"] = strange.get_pending_controller_application_count()
			// Cache frequently-reused controller state checks to avoid redundant method calls.
			var/cached_controller_state = strange.get_controller_state()
			var/cached_wearer_available = strange.is_controller_wearer_available()
			var/cached_is_viewer = strange.is_controller_viewer(user)
			var/cached_view_mode = strange.get_controller_view_mode(user)
			var/cached_not_suspended = cached_controller_state != "suspended"
			d["controller_state"] = cached_controller_state
			d["controller_state_name"] = strange.get_controller_state_name()
			d["controller_speech_enabled"] = strange.controller_speech_enabled
			d["controller_emote_enabled"] = strange.controller_emote_enabled
			d["controller_manifest_enabled"] = strange.controller_manifest_enabled
			d["controller_direct_control_enabled"] = strange.controller_direct_control_enabled
			d["controller_force_enabled"] = strange.controller_force_enabled
			d["is_controller_viewer"] = cached_is_viewer
			d["controller_view_mode"] = cached_view_mode
			d["controller_wearer_ready"] = cached_wearer_available
			d["controller_wearer_status"] = strange.get_controller_wearer_status_text()
			d["controller_pending_requests"] = strange.get_controller_request_ui_data()
			// When a player IS the jelly (bound controller), bypass all emotional gates.
			var/controller_bypasses_gates = strange.has_bound_controller()
			var/controller_resentment_blocks = !controller_bypasses_gates && strange.resentment_level >= strange.resentment_communication_block_threshold
			var/controller_need_allows_force = controller_bypasses_gates || strange.need_level >= strange.need_force_unlock_threshold
			var/controller_jealousy_allows_cocoon = controller_bypasses_gates || strange.jealousy_level >= strange.jealousy_cocoon_aggression_threshold
			// Use cached values for all controller_can_* permission flags.
			var/controller_shell_base = cached_is_viewer && cached_view_mode == "shell" && cached_not_suspended && cached_wearer_available
			d["controller_can_speak"] = controller_shell_base && strange.controller_speech_enabled && !controller_resentment_blocks
			d["controller_can_emote"] = controller_shell_base && strange.controller_emote_enabled && !controller_resentment_blocks
			d["controller_can_preset_action"] = controller_shell_base && strange.controller_emote_enabled && !controller_resentment_blocks
			d["controller_can_manifest"] = controller_shell_base && strange.controller_manifest_enabled && (controller_bypasses_gates || strange.bond_escalation_level >= strange.doppel_control_bond_level || strange.obsession_level >= strange.obsession_manifest_threshold)
			d["controller_can_stimulate"] = controller_shell_base && controller_need_allows_force
			// Controller-side stimulate cooldown remaining in seconds.
			if(strange.last_jelly_stimulate && world.time < strange.last_jelly_stimulate + strange.jelly_stimulate_interval)
				d["controller_stimulate_cooldown"] = round((strange.last_jelly_stimulate + strange.jelly_stimulate_interval - world.time) / 10)
			else
				d["controller_stimulate_cooldown"] = 0
			d["controller_can_reposition"] = controller_shell_base && !!swap_opts.len
			d["controller_can_force"] = controller_shell_base && strange.controller_force_enabled && controller_need_allows_force
			// Controller-side force action cooldown remaining in seconds.
			if(strange.last_controller_force_action && world.time < strange.last_controller_force_action + strange.controller_force_action_interval)
				d["controller_force_cooldown"] = round((strange.last_controller_force_action + strange.controller_force_action_interval - world.time) / 10)
			else
				d["controller_force_cooldown"] = 0
			d["controller_force_emote_options"] = strange.get_controller_force_emote_options()
			d["controller_wearer_voice_presets"] = strange.get_controller_wearer_voice_preset_labels()
			d["controller_force_posture_options"] = strange.get_controller_force_posture_labels()
			d["controller_can_return"] = cached_is_viewer && cached_view_mode == "doppel"
			d["controller_can_cocoon_command"] = cached_is_viewer && strange.cocooned && strange.active_cocoon && !QDELETED(strange.active_cocoon) && strange.has_bound_controller()
			d["controller_can_cocoon_tighten"] = d["controller_can_cocoon_command"] && controller_jealousy_allows_cocoon
			d["controller_can_cocoon_tendril"] = d["controller_can_cocoon_command"] && controller_jealousy_allows_cocoon
			d["controller_can_start_cocoon"] = cached_is_viewer && !strange.cocooned && strange.has_bound_controller() && cached_wearer_available && strange.matches_bonded_wearer(strange.wearer)
			d["controller_cocoon_stage"] = strange.active_cocoon ? strange.active_cocoon.cocoon_stage : 0
			d["controller_cocoon_stage_name"] = strange.get_cocoon_stage_name()
			d["controller_cocoon_tick_count"] = strange.active_cocoon ? strange.active_cocoon.tick_count : 0
			d["controller_cocoon_next_stage_ticks"] = strange.get_next_cocoon_stage_ticks()
			d["controller_cocoon_tick_interval"] = strange.active_cocoon ? strange.active_cocoon.active_tick_interval / 10 : 3
			d["controller_emotion_blocks_speech"] = controller_resentment_blocks
			d["controller_emotion_needs_force"] = !controller_need_allows_force
			d["controller_emotion_needs_jealousy"] = !controller_jealousy_allows_cocoon
			d["controller_preset_actions"] = strange.get_controller_preset_action_labels()
			// Determine whether the viewer is the bonded wearer.
			var/is_bonded_wearer = ishuman(user) && strange.matches_bonded_wearer(user)
			d["is_bonded_wearer"] = is_bonded_wearer
			// Soothe: only for the bonded wearer when there is need/jealousy/resentment to address.
			d["can_soothe"] = is_bonded_wearer \
				&& (strange.need_level > 0 || strange.jealousy_level > 0 || strange.resentment_level > 0) \
				&& !(strange.last_need_soothe && world.time < strange.last_need_soothe + strange.need_soothe_interval)
			d["can_review_controller_volunteers"] = is_bonded_wearer && !strange.has_bound_controller()
			d["can_toggle_controller_applications"] = is_bonded_wearer && !strange.has_bound_controller()
			d["can_manage_bound_controller"] = is_bonded_wearer && strange.has_bound_controller()
			// Activity history and invitation data — visible to wearer and controller.
			d["controller_activity_log"] = strange.get_controller_activity_ui_data()
			d["controller_pending_invitations"] = strange.get_controller_invitation_ui_data()
			d["can_invite_controller"] = is_bonded_wearer && !strange.has_bound_controller() && strange.is_accepting_controller_applications()
			// Tend: for adjacent observers who are NOT the bonded wearer.
			d["can_tend"] = !is_bonded_wearer \
				&& strange.has_bonded_wearer() \
				&& !(strange.last_tended && world.time < strange.last_tended + strange.tend_interval)
			// Provoke: bonded wearer only, on cooldown.
			d["provoke_ready"] = is_bonded_wearer \
				&& (!strange.last_provoke || world.time >= strange.last_provoke + strange.provoke_interval)
		else
			d["need_level"]          = 0
			d["max_need_level"]      = 0
			d["need_state"]          = null
			d["jealousy_level"]      = 0
			d["max_jealousy_level"]  = 0
			d["jealousy_state"]      = null
			d["resentment_level"]    = 0
			d["max_resentment_level"] = 0
			d["resentment_state"]    = null
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
			d["has_bound_controller"] = FALSE
			d["bound_controller_name"] = null
			d["controller_applications_open"] = FALSE
			d["pending_controller_application_count"] = 0
			d["controller_state"] = "unbound"
			d["controller_state_name"] = "Unbound"
			d["controller_speech_enabled"] = FALSE
			d["controller_emote_enabled"] = FALSE
			d["controller_manifest_enabled"] = FALSE
			d["controller_direct_control_enabled"] = FALSE
			d["is_controller_viewer"] = FALSE
			d["controller_view_mode"] = null
			d["controller_wearer_ready"] = FALSE
			d["controller_wearer_status"] = null
			d["controller_pending_requests"] = list()
			d["controller_can_speak"] = FALSE
			d["controller_can_emote"] = FALSE
			d["controller_can_preset_action"] = FALSE
			d["controller_can_manifest"] = FALSE
			d["controller_can_stimulate"] = FALSE
			d["controller_can_reposition"] = FALSE
			d["controller_can_return"] = FALSE
			d["controller_preset_actions"] = list()
			d["is_bonded_wearer"]    = FALSE
			d["can_soothe"]          = FALSE
			d["can_review_controller_volunteers"] = FALSE
			d["can_toggle_controller_applications"] = FALSE
			d["can_manage_bound_controller"] = FALSE
			d["controller_activity_log"] = list()
			d["controller_pending_invitations"] = list()
			d["can_invite_controller"] = FALSE
			d["can_tend"]            = FALSE
	else
		d["is_eora_jelly"]   = FALSE
		d["is_controller_viewer"] = FALSE
		d["controller_view_mode"] = null
		d["controller_wearer_ready"] = FALSE
		d["controller_wearer_status"] = null
		d["controller_direct_control_enabled"] = FALSE
		d["controller_pending_requests"] = list()
		d["controller_can_speak"] = FALSE
		d["controller_can_emote"] = FALSE
		d["controller_can_preset_action"] = FALSE
		d["controller_can_manifest"] = FALSE
		d["controller_can_stimulate"] = FALSE
		d["controller_can_reposition"] = FALSE
		d["controller_can_return"] = FALSE
		d["controller_preset_actions"] = list()
		d["controller_activity_log"] = list()
		d["controller_pending_invitations"] = list()
		d["can_invite_controller"] = FALSE

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
	var/obj/item/intimate_accessory/jelly/eora/strange/controller_target = null
	var/controller_target_ref = params["ref"]
	if(controller_target_ref)
		var/obj/item/intimate_accessory/potential_target = locate(controller_target_ref)
		if(istype(potential_target, /obj/item/intimate_accessory/jelly/eora/strange))
			controller_target = potential_target
	var/is_controller_viewer = controller_target?.is_controller_viewer(user)

	// Observers must be adjacent; the wearer is always close enough to themselves.
	if(user != wearer && !is_controller_viewer && !user.Adjacent(wearer))
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
		if("jelly_project_doppel")
			return _intimate_act_jelly_project_doppel(user, params)
		if("jelly_review_volunteers")
			return _intimate_act_jelly_review_volunteers(user, params)
		if("jelly_toggle_controller_applications")
			return _intimate_act_jelly_toggle_controller_applications(user, params)
		if("jelly_toggle_controller_permission")
			return _intimate_act_jelly_toggle_controller_permission(user, params)
		if("jelly_toggle_controller_direct_control")
			return _intimate_act_jelly_toggle_controller_direct_control(user, params)
		if("jelly_dismiss_controller")
			return _intimate_act_jelly_dismiss_controller(user, params)
		if("jelly_controller_stimulate")
			return _intimate_act_jelly_controller_stimulate(user, params)
		if("jelly_controller_reposition")
			return _intimate_act_jelly_controller_reposition(user, params)
		if("jelly_controller_speak")
			return _intimate_act_jelly_controller_speak(user, params)
		if("jelly_controller_whisper")
			return _intimate_act_jelly_controller_whisper(user, params)
		if("jelly_controller_emote")
			return _intimate_act_jelly_controller_emote(user, params)
		if("jelly_controller_preset")
			return _intimate_act_jelly_controller_preset(user, params)
		if("jelly_controller_manifest")
			return _intimate_act_jelly_controller_manifest(user, params)
		if("jelly_controller_return")
			return _intimate_act_jelly_controller_return(user, params)
		if("jelly_controller_respond_request")
			return _intimate_act_jelly_controller_respond_request(user, params)
		if("jelly_controller_force_speech")
			return _intimate_act_jelly_controller_force_speech(user, params)
		if("jelly_controller_force_emote")
			return _intimate_act_jelly_controller_force_emote(user, params)
		if("jelly_toggle_controller_force")
			return _intimate_act_jelly_toggle_controller_force(user, params)
		if("jelly_controller_wearer_voice_preset")
			return _intimate_act_jelly_controller_wearer_voice_preset(user, params)
		if("jelly_controller_force_posture")
			return _intimate_act_jelly_controller_force_posture(user, params)
		if("jelly_controller_cocoon_tighten")
			return _intimate_act_jelly_controller_cocoon_tighten(user, params)
		if("jelly_controller_cocoon_release")
			return _intimate_act_jelly_controller_cocoon_release(user, params)
		if("jelly_controller_cocoon_tendril_pulse")
			return _intimate_act_jelly_controller_cocoon_tendril_pulse(user, params)
		if("jelly_controller_start_cocoon")
			return _intimate_act_jelly_controller_start_cocoon(user, params)
		if("jelly_send_invitation")
			return _intimate_act_jelly_send_invitation(user, params)
		if("jelly_cancel_invitation")
			return _intimate_act_jelly_cancel_invitation(user, params)
		if("jelly_respond_invitation")
			return _intimate_act_jelly_respond_invitation(user, params)
		if("jelly_tendril_command")
			return _intimate_act_jelly_tendril_command(user, params)
		if("jelly_request_cocoon")
			return _intimate_act_jelly_request_cocoon(user, params)
		if("jelly_provoke")
			return _intimate_act_jelly_provoke(user, params)

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
	// Spiked and glass beads have extreme insertion text — filter bystanders.
	var/list/excluded
	if(istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/spiked) || istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/glass))
		excluded = get_extreme_content_excluded_mobs(wearer)
	if(custom_push_msg)
		user.visible_message(span_notice(custom_push_msg), ignored_mobs = excluded)
	else if(user == wearer)
		user.visible_message(span_notice("[user] slowly pushes another bead in..."), ignored_mobs = excluded)
	else
		user.visible_message(span_notice("[user] slowly pushes another bead into [wearer]..."), ignored_mobs = excluded)

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
	// Spiked and glass beads have extreme removal text — filter bystanders.
	var/list/excluded
	if(istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/spiked) || istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/glass))
		excluded = get_extreme_content_excluded_mobs(wearer)
	if(custom_pull_msg)
		user.visible_message(span_notice(custom_pull_msg), ignored_mobs = excluded)
	else if(user == wearer)
		user.visible_message(span_notice("[user] starts pulling a bead out..."), ignored_mobs = excluded)
	else
		user.visible_message(span_notice("[user] starts pulling a bead out of [wearer]..."), ignored_mobs = excluded)

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
	// Extreme bead types — filter bystanders who opted out of extreme content.
	var/list/excluded
	if(istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/spiked) || istype(beads, /obj/item/intimate_accessory/rear/plug/analbeads/glass))
		excluded = get_extreme_content_excluded_mobs(wearer)
	if(ripcord_msg)
		user.visible_message(span_warning(ripcord_msg), ignored_mobs = excluded)

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
 * also decrementing jealousy. Forwards to try_soothe_needs which enforces the cooldown.
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
 * half-strength need reduction with no jealousy benefit. Forwards to try_comfort_jelly
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

/**
 * Projects the bonded wearer into the jelly's slime doppelganger.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_project_doppel(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.try_project_doppelganger(wearer)
	return TRUE

/**
 * Opens the wearer-side jelly volunteer review flow.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_review_volunteers(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.review_controller_volunteers(wearer)
	return TRUE

/**
 * Opens or closes targeted controller applications for the bonded wearer's jelly.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_toggle_controller_applications(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/open_state = !!text2num("[params["open"]]")
	jelly.set_controller_applications_open(open_state, wearer)
	return TRUE

/**
 * Toggles wearer-side permissions for an already bound third-party jelly controller.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_toggle_controller_permission(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/permission_key = params["permission"]
	var/enabled = !!text2num("[params["enabled"]]")
	jelly.set_controller_permission(permission_key, enabled, wearer)
	return TRUE

/**
 * Toggles whether wearer-facing controller actions require explicit approval.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_toggle_controller_direct_control(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/enabled = !!text2num("[params["enabled"]]")
	jelly.set_controller_direct_control(enabled, wearer)
	return TRUE

/**
 * Allows the bonded wearer to dismiss a currently bound third-party controller.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_dismiss_controller(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.dismiss_bound_controller(wearer)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_stimulate(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only direct the jelly from the hidden shell."))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_controller_stimulation(shell)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_reposition(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only direct the jelly from the hidden shell."))
		return TRUE
	var/target_slot = text2num(params["slot"])
	if(isnull(target_slot))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_controller_reposition(shell, target_slot)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_speak(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only speak through the jelly while resting in its hidden shell."))
		return TRUE
	var/message = tgui_input_text(user, "What words ripple through the jelly?", "Speak Through Jelly", "", 200)
	if(isnull(message))
		return TRUE
	message = strip_html_simple(message, 200)
	if(!length(message))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.emit_controller_speech(shell, message)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_whisper(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only whisper through the jelly while resting in its hidden shell."))
		return TRUE
	var/message = tgui_input_text(user, "What words do you murmur privately to the wearer?", "Whisper Through Jelly", "", 200)
	if(isnull(message))
		return TRUE
	message = strip_html_simple(message, 200)
	if(!length(message))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.emit_controller_whisper(shell, message)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_emote(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only emote through the jelly while resting in its hidden shell."))
		return TRUE
	var/message = tgui_input_text(user, "What sensation or emote does the jelly convey?", "Emote Through Jelly", "", 200)
	if(isnull(message))
		return TRUE
	message = strip_html_simple(message, 200)
	if(!length(message))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.emit_controller_emote(shell, message)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_preset(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("Preset jelly actions are only available from the hidden shell."))
		return TRUE
	var/action_name = params["preset_action"]
	if(!action_name || !(action_name in jelly.get_controller_preset_action_labels()))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.emit_controller_preset_action(shell, action_name)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_manifest(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only manifest from the hidden shell."))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_or_manifest_bound_controller_doppel(shell)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_return(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "doppel")
		to_chat(user, span_warning("I can only return while actively manifested in the slime double."))
		return TRUE
	var/mob/living/carbon/human/slime_doppelganger/doppel = user
	if(!istype(doppel))
		return TRUE
	doppel.return_controller_to_body(TRUE)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_respond_request(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/request_id = text2num(params["request_id"])
	if(!request_id)
		return TRUE
	var/accepted = !!text2num("[params["accepted"]]")
	jelly.respond_to_controller_request(request_id, accepted, wearer)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_force_speech(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only force speech while resting in the hidden shell."))
		return TRUE
	var/message = tgui_input_text(user, "What words do you force through the wearer's lips?", "Force Wearer Speech", "", 100)
	if(isnull(message))
		return TRUE
	message = strip_html_simple(message, 100)
	if(!length(message))
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_controller_force_speech(shell, message)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_force_emote(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("I can only force emotes while resting in the hidden shell."))
		return TRUE
	var/emote_label = params["emote_label"]
	if(!emote_label)
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_controller_force_emote(shell, emote_label)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_toggle_controller_force(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/enabled = !!text2num("[params["enabled"]]")
	jelly.set_controller_permission("force", enabled, wearer)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_wearer_voice_preset(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("Wearer-voice presets are only available from the hidden shell."))
		return TRUE
	var/preset_label = params["preset_label"]
	if(!preset_label)
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_controller_wearer_voice_preset(shell, preset_label)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_force_posture(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.is_controller_viewer(user))
		return TRUE
	if(jelly.get_controller_view_mode(user) != "shell")
		to_chat(user, span_warning("Forced postures are only available from the hidden shell."))
		return TRUE
	var/posture_label = params["posture_label"]
	if(!posture_label)
		return TRUE
	var/mob/living/jelly_controller_shell/shell = user
	jelly.request_controller_force_posture(shell, posture_label)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_cocoon_tighten(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.can_controller_cocoon_command(user))
		return TRUE
	jelly.controller_cocoon_tighten(user)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_cocoon_release(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.can_controller_cocoon_command(user))
		return TRUE
	jelly.controller_cocoon_release(user)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_cocoon_tendril_pulse(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.can_controller_cocoon_command(user))
		return TRUE
	jelly.controller_cocoon_tendril_pulse(user)
	return TRUE

/datum/intimate_menu/proc/_intimate_act_jelly_controller_start_cocoon(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || !jelly.can_controller_start_cocoon(user))
		return TRUE
	jelly.controller_start_cocoon(user)
	return TRUE

/**
 * Wearer sends a direct invitation to an opted-in candidate.
 * Opens a server-side candidate picker, then calls send_controller_invitation.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_send_invitation(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	// Build a name map of eligible candidates from the global queue.
	var/list/name_map = list()
	for(var/client/C in GLOB.jelly_controller_queue)
		if(!C || !C.ckey || C.ckey == wearer.ckey)
			continue
		if(!jelly.is_valid_jelly_controller_candidate(C.mob))
			continue
		var/datum/jelly_prefs/pref = C.prefs?.jelly_prefs
		if(!pref?.is_profile_ready())
			continue
		// Skip candidates who already have a pending invitation or application.
		if(jelly.find_pending_controller_invitation_by_ckey(C.ckey))
			continue
		if(jelly.pending_controller_applications && jelly.pending_controller_applications[C.ckey])
			continue
		var/label = "[pref.jelly_name] ([C.ckey])"
		name_map[label] = C.ckey
	if(!name_map.len)
		to_chat(user, span_notice("No eligible candidates are available to invite right now."))
		return TRUE
	var/choice = tgui_input_list(user, "Choose a candidate to invite:", "Invite Jelly Controller", name_map)
	if(!choice)
		return TRUE
	var/candidate_ckey = name_map[choice]
	if(!candidate_ckey || !jelly || QDELETED(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.send_controller_invitation(wearer, candidate_ckey)
	return TRUE

/**
 * Wearer cancels a pending invitation.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_cancel_invitation(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/invitation_id = text2num(params["invitation_id"])
	if(!invitation_id)
		return TRUE
	jelly.cancel_controller_invitation(invitation_id, wearer)
	return TRUE

/**
 * Candidate responds to a controller invitation (accept/decline).
 */
/datum/intimate_menu/proc/_intimate_act_jelly_respond_invitation(mob/user, list/params)
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly))
		return TRUE
	var/invitation_id = text2num(params["invitation_id"])
	if(!invitation_id)
		return TRUE
	var/accepted = !!text2num("[params["accepted"]]")
	jelly.respond_to_controller_invitation(invitation_id, accepted, user)
	return TRUE

/**
 * Player directs the jelly to perform a specific tendril action.
 * Requires bonded wearer. Action key passed via params["action_key"].
 */
/datum/intimate_menu/proc/_intimate_act_jelly_tendril_command(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	var/action_key = params["action_key"]
	if(!action_key || !(action_key in list("anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi")))
		return TRUE
	jelly.try_tendril_command(wearer, action_key)
	return TRUE

/**
 * Player requests voluntary cocooning from a deeply bonded jelly.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_request_cocoon(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.try_voluntary_cocoon(wearer)
	return TRUE

/**
 * Player deliberately provokes their jelly, raising jealousy/resentment.
 */
/datum/intimate_menu/proc/_intimate_act_jelly_provoke(mob/user, list/params)
	if(user != wearer)
		return TRUE
	var/acc_ref = params["ref"]
	if(!acc_ref)
		return TRUE
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = locate(acc_ref)
	if(!jelly || QDELETED(jelly) || !istype(jelly) || jelly.wearer != wearer)
		return TRUE
	jelly.try_provoke_jelly(wearer)
	return TRUE

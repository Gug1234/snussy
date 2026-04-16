/**
 * jelly_controller_menu.dm — Standalone TGUI for the jelly controller.
 *
 * Provides a dedicated communion panel that controllers (shell or doppelganger)
 * can open directly, without needing to open the full IntimateMenu.
 * All controller actions are dispatched through the source jelly's procs.
 */

/datum/jelly_controller_menu
	/// The strange jelly backing this controller UI.
	var/obj/item/intimate_accessory/jelly/eora/strange/source_jelly

/datum/jelly_controller_menu/New(obj/item/intimate_accessory/jelly/eora/strange/jelly)
	if(!jelly)
		qdel(src)
		return
	source_jelly = jelly
	..()

/datum/jelly_controller_menu/Destroy()
	source_jelly = null
	return ..()

/datum/jelly_controller_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "JellyControllerMenu", "Jelly Communion", 480, 560)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/jelly_controller_menu/ui_data(mob/user)
	var/list/data = list()

	if(!source_jelly || QDELETED(source_jelly))
		data["invalid"] = TRUE
		return data

	var/ref = REF(source_jelly)
	data["ref"] = ref
	data["name"] = source_jelly.name
	data["custom_jelly_name"] = source_jelly.custom_jelly_name

	// ── Emotional state bars ────────────────────────────────────────────
	data["need_level"] = source_jelly.need_level
	data["max_need_level"] = source_jelly.max_need_level
	data["need_state"] = source_jelly.get_need_state()
	data["jealousy_level"] = source_jelly.jealousy_level
	data["max_jealousy_level"] = source_jelly.max_jealousy_level
	data["jealousy_state"] = source_jelly.get_jealousy_state()
	data["resentment_level"] = source_jelly.resentment_level
	data["max_resentment_level"] = source_jelly.max_resentment_level
	data["resentment_state"] = source_jelly.get_resentment_state()
	data["bond_escalation_level"] = source_jelly.bond_escalation_level
	data["max_bond_escalation_level"] = source_jelly.max_bond_escalation_level
	data["bond_state"] = source_jelly.get_bond_state()
	data["bond_progress"] = source_jelly.bond_progress
	data["bond_progress_threshold"] = source_jelly.bond_progress_threshold
	data["obsession_level"] = source_jelly.obsession_level

	// ── Wearer info ─────────────────────────────────────────────────────
	data["has_bonded_wearer"] = source_jelly.has_bonded_wearer()
	data["bonded_wearer_name"] = source_jelly.bonded_name
	data["is_cocooned"] = source_jelly.cocooned
	data["cocoon_stage_name"] = source_jelly.get_cocoon_stage_name()

	// ── Doppelganger info ───────────────────────────────────────────────
	data["has_doppelganger"] = !!(source_jelly.active_doppelganger && !QDELETED(source_jelly.active_doppelganger))
	data["doppel_is_player_controlled"] = source_jelly.active_doppelganger ? source_jelly.active_doppelganger.is_player_controlled() : FALSE

	// ── Controller state ────────────────────────────────────────────────
	var/cached_controller_state = source_jelly.get_controller_state()
	var/cached_wearer_available = source_jelly.is_controller_wearer_available()
	var/cached_is_viewer = source_jelly.is_controller_viewer(user)
	var/cached_view_mode = source_jelly.get_controller_view_mode(user)
	var/cached_not_suspended = cached_controller_state != "suspended"

	data["controller_state"] = cached_controller_state
	data["controller_state_name"] = source_jelly.get_controller_state_name()
	data["is_controller_viewer"] = cached_is_viewer
	data["controller_view_mode"] = cached_view_mode
	data["controller_wearer_ready"] = cached_wearer_available
	data["controller_wearer_status"] = source_jelly.get_controller_wearer_status_text()
	data["controller_direct_control_enabled"] = source_jelly.controller_direct_control_enabled
	data["controller_force_enabled"] = source_jelly.controller_force_enabled
	data["controller_speech_enabled"] = source_jelly.controller_speech_enabled
	data["controller_emote_enabled"] = source_jelly.controller_emote_enabled
	data["controller_manifest_enabled"] = source_jelly.controller_manifest_enabled

	// ── Gate bypass ─────────────────────────────────────────────────────
	var/controller_bypasses_gates = source_jelly.has_bound_controller()
	var/controller_resentment_blocks = !controller_bypasses_gates && source_jelly.resentment_level >= source_jelly.resentment_communication_block_threshold
	var/controller_need_allows_force = controller_bypasses_gates || source_jelly.need_level >= source_jelly.need_force_unlock_threshold
	var/controller_jealousy_allows_cocoon = controller_bypasses_gates || source_jelly.jealousy_level >= source_jelly.jealousy_cocoon_aggression_threshold

	// ── Permission flags ────────────────────────────────────────────────
	var/controller_shell_base = cached_is_viewer && cached_view_mode == "shell" && cached_not_suspended && cached_wearer_available
	data["controller_can_speak"] = controller_shell_base && source_jelly.controller_speech_enabled && !controller_resentment_blocks
	data["controller_can_emote"] = controller_shell_base && source_jelly.controller_emote_enabled && !controller_resentment_blocks
	data["controller_can_preset_action"] = controller_shell_base && source_jelly.controller_emote_enabled && !controller_resentment_blocks
	data["controller_can_manifest"] = controller_shell_base && source_jelly.controller_manifest_enabled && (controller_bypasses_gates || source_jelly.bond_escalation_level >= source_jelly.doppel_control_bond_level || source_jelly.obsession_level >= source_jelly.obsession_manifest_threshold)
	data["controller_can_stimulate"] = controller_shell_base && controller_need_allows_force
	// Cooldown remaining in seconds (0 when ready).
	if(source_jelly.last_jelly_stimulate && world.time < source_jelly.last_jelly_stimulate + source_jelly.jelly_stimulate_interval)
		data["controller_stimulate_cooldown"] = round((source_jelly.last_jelly_stimulate + source_jelly.jelly_stimulate_interval - world.time) / 10)
	else
		data["controller_stimulate_cooldown"] = 0
	data["controller_can_force"] = controller_shell_base && source_jelly.controller_force_enabled && controller_need_allows_force
	// Controller-side force action cooldown remaining in seconds.
	if(source_jelly.last_controller_force_action && world.time < source_jelly.last_controller_force_action + source_jelly.controller_force_action_interval)
		data["controller_force_cooldown"] = round((source_jelly.last_controller_force_action + source_jelly.controller_force_action_interval - world.time) / 10)
	else
		data["controller_force_cooldown"] = 0
	data["controller_can_return"] = cached_is_viewer && cached_view_mode == "doppel"
	data["controller_can_cocoon_command"] = cached_is_viewer && source_jelly.cocooned && source_jelly.active_cocoon && !QDELETED(source_jelly.active_cocoon) && source_jelly.has_bound_controller()
	data["controller_can_cocoon_tighten"] = data["controller_can_cocoon_command"] && controller_jealousy_allows_cocoon
	data["controller_can_cocoon_tendril"] = data["controller_can_cocoon_command"] && controller_jealousy_allows_cocoon
	data["controller_can_start_cocoon"] = cached_is_viewer && !source_jelly.cocooned && source_jelly.has_bound_controller() && cached_wearer_available && source_jelly.matches_bonded_wearer(source_jelly.wearer)
	data["controller_cocoon_stage"] = source_jelly.active_cocoon ? source_jelly.active_cocoon.cocoon_stage : 0
	data["controller_cocoon_stage_name"] = source_jelly.get_cocoon_stage_name()
	data["controller_cocoon_tick_count"] = source_jelly.active_cocoon ? source_jelly.active_cocoon.tick_count : 0
	data["controller_cocoon_next_stage_ticks"] = source_jelly.get_next_cocoon_stage_ticks()
	data["controller_cocoon_tick_interval"] = source_jelly.active_cocoon ? source_jelly.active_cocoon.active_tick_interval / 10 : 3
	data["controller_emotion_blocks_speech"] = controller_resentment_blocks
	data["controller_emotion_needs_force"] = !controller_need_allows_force
	data["controller_emotion_needs_jealousy"] = !controller_jealousy_allows_cocoon

	// ── Slot reposition ─────────────────────────────────────────────────
	var/current_slot = source_jelly.get_effective_intimate_slot()
	data["current_slot"] = current_slot
	data["current_slot_name"] = source_jelly.get_intimate_slot_display_name()
	var/list/swap_opts = list()
	for(var/s in source_jelly.get_supported_intimate_slots())
		if(s != current_slot)
			swap_opts += list(list("slot" = s, "name" = source_jelly.get_intimate_slot_display_name(s)))
	data["swap_slot_options"] = swap_opts
	data["controller_can_reposition"] = controller_shell_base && !!swap_opts.len

	// ── Dropdown options ────────────────────────────────────────────────
	data["controller_preset_actions"] = source_jelly.get_controller_preset_action_labels()
	data["controller_force_emote_options"] = source_jelly.get_controller_force_emote_options()
	data["controller_wearer_voice_presets"] = source_jelly.get_controller_wearer_voice_preset_labels()
	data["controller_force_posture_options"] = source_jelly.get_controller_force_posture_labels()

	// ── Pending requests ────────────────────────────────────────────────
	data["controller_pending_requests"] = source_jelly.get_controller_request_ui_data()

	// ── Activity log ────────────────────────────────────────────────────
	data["controller_activity_log"] = source_jelly.get_controller_activity_ui_data()

	return data

// ── Action dispatch ──────────────────────────────────────────────────────────

/datum/jelly_controller_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE

	var/mob/user = ui?.user || usr

	if(!source_jelly || QDELETED(source_jelly))
		return TRUE

	switch(action)
		if("controller_speak")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/message = tgui_input_text(user, "What do I say through my host?", "Speak Through Host", "", 200)
			if(isnull(message))
				return TRUE
			message = strip_html_simple(message, 200)
			if(!length(message))
				return TRUE
			source_jelly.emit_controller_speech(user, message)
			return TRUE

		if("controller_whisper")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/message = tgui_input_text(user, "What do I murmur to the host?", "Murmur to Host", "", 200)
			if(isnull(message))
				return TRUE
			message = strip_html_simple(message, 200)
			if(!length(message))
				return TRUE
			source_jelly.emit_controller_whisper(user, message)
			return TRUE

		if("controller_emote")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/message = tgui_input_text(user, "What do I express through my host?", "Express Through Host", "", 200)
			if(isnull(message))
				return TRUE
			message = strip_html_simple(message, 200)
			if(!length(message))
				return TRUE
			source_jelly.emit_controller_emote(user, message)
			return TRUE

		if("controller_preset")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/action_name = params["preset_action"]
			if(!action_name || !(action_name in source_jelly.get_controller_preset_action_labels()))
				return TRUE
			source_jelly.emit_controller_preset_action(user, action_name)
			return TRUE

		if("controller_manifest")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			source_jelly.request_or_manifest_bound_controller_doppel(user)
			return TRUE

		if("controller_return")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "doppel")
				return TRUE
			var/mob/living/carbon/human/slime_doppelganger/doppel = user
			if(!istype(doppel))
				return TRUE
			doppel.return_controller_to_body(TRUE)
			return TRUE

		if("controller_stimulate")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			source_jelly.request_controller_stimulation(user)
			return TRUE

		if("controller_reposition")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/target_slot = text2num(params["slot"])
			if(isnull(target_slot))
				return TRUE
			source_jelly.request_controller_reposition(user, target_slot)
			return TRUE

		if("controller_force_speech")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/message = tgui_input_text(user, "What words do I force through the host's lips?", "Force Host Speech", "", 100)
			if(isnull(message))
				return TRUE
			message = strip_html_simple(message, 100)
			if(!length(message))
				return TRUE
			source_jelly.request_controller_force_speech(user, message)
			return TRUE

		if("controller_force_emote")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/emote_label = params["emote_label"]
			if(!emote_label)
				return TRUE
			source_jelly.request_controller_force_emote(user, emote_label)
			return TRUE

		if("controller_wearer_voice_preset")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/preset_label = params["preset_label"]
			if(!preset_label)
				return TRUE
			source_jelly.request_controller_wearer_voice_preset(user, preset_label)
			return TRUE

		if("controller_force_posture")
			if(!source_jelly.is_controller_viewer(user) || source_jelly.get_controller_view_mode(user) != "shell")
				return TRUE
			var/posture_label = params["posture_label"]
			if(!posture_label)
				return TRUE
			source_jelly.request_controller_force_posture(user, posture_label)
			return TRUE

		if("controller_cocoon_tighten")
			if(!source_jelly.can_controller_cocoon_command(user))
				return TRUE
			source_jelly.controller_cocoon_tighten(user)
			return TRUE

		if("controller_cocoon_release")
			if(!source_jelly.can_controller_cocoon_command(user))
				return TRUE
			source_jelly.controller_cocoon_release(user)
			return TRUE

		if("controller_cocoon_tendril_pulse")
			if(!source_jelly.can_controller_cocoon_command(user))
				return TRUE
			source_jelly.controller_cocoon_tendril_pulse(user)
			return TRUE

		if("controller_start_cocoon")
			if(!source_jelly.can_controller_start_cocoon(user))
				return TRUE
			source_jelly.controller_start_cocoon(user)
			return TRUE

	return TRUE

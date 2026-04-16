/// Bound controller is not currently present.
#define JELLY_CONTROLLER_STATE_UNBOUND "unbound"
/// Bound controller is housed inside the hidden shell while the jelly is worn.
#define JELLY_CONTROLLER_STATE_SHELL_BOUND "shell_bound"
/// Bound controller is currently piloting the slime doppelganger.
#define JELLY_CONTROLLER_STATE_MANIFESTED "manifested"
/// Bound controller is still attached to the jelly, but their client is disconnected.
#define JELLY_CONTROLLER_STATE_SUSPENDED "suspended"

// ════════════════════════════════════════════════════════════════════════════
// Action-bar button — always available to the controller mob (shell or doppel)
// ════════════════════════════════════════════════════════════════════════════

/datum/action/jelly_controller_menu
	name = "Ooze Communion"
	desc = "Open the jelly communion panel."
	button_icon_state = "coven"
	check_flags = NONE
	/// Back-reference to the jelly item this action belongs to.
	var/obj/item/intimate_accessory/jelly/eora/strange/source_jelly

/datum/action/jelly_controller_menu/New(obj/item/intimate_accessory/jelly/eora/strange/jelly_source)
	..()
	source_jelly = jelly_source

/datum/action/jelly_controller_menu/Destroy()
	source_jelly = null
	return ..()

/datum/action/jelly_controller_menu/Trigger()
	if(!..())
		return FALSE
	if(!source_jelly || QDELETED(source_jelly))
		return FALSE
	source_jelly.open_controller_menu(owner)
	return TRUE

/// Hidden living shell that holds a bound jelly controller while the jelly remains worn.
/mob/living/jelly_controller_shell
	name = "jelly consciousness"
	real_name = "jelly consciousness"
	density = FALSE
	anchored = TRUE
	status_flags = GODMODE
	invisibility = INVISIBILITY_ABSTRACT
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	see_in_dark = 8
	// Provide a minimal intent so update_a_intents() can populate a_intent
	// and prevent null-reference exceptions in click handlers.
	base_intents = list(INTENT_HELP)
	var/obj/item/intimate_accessory/jelly/eora/strange/source_jelly

/mob/living/jelly_controller_shell/Destroy()
	source_jelly = null
	return ..()

/mob/living/jelly_controller_shell/Initialize(mapload, obj/item/intimate_accessory/jelly/eora/strange/jelly_source)
	. = ..()
	source_jelly = jelly_source
	if(source_jelly)
		forceMove(source_jelly)

/mob/living/jelly_controller_shell/Login()
	. = ..()
	// If the jelly no longer exists (round ended, etc.), release the player
	// to the lobby so they aren't trapped on a defunct shell.
	if(!source_jelly || QDELETED(source_jelly))
		var/mob/dead/observer/ghost = ghostize(0)
		if(ghost)
			to_chat(ghost, span_warning("The jelly that anchored this shell is gone."))
		qdel(src)
		return
	source_jelly.handle_controller_shell_login(src)
	refresh_controller_perspective()

// Skip do_time_change() — it accesses human-only vars (time_flags) that
// don't exist on this non-human shell mob.
/mob/living/jelly_controller_shell/login_fade()
	return

/mob/living/jelly_controller_shell/Logout()
	if(source_jelly)
		source_jelly.handle_controller_shell_logout(src)
	. = ..()

/mob/living/jelly_controller_shell/say(message, bubble_type, list/spans, sanitize, datum/language/language, ignore_spam, forced)
	return

/mob/living/jelly_controller_shell/Life(delta_time, times_fired)
	return

/mob/living/jelly_controller_shell/Move(NewLoc, Dir, step_x, step_y)
	return FALSE

/mob/living/jelly_controller_shell/proc/refresh_controller_perspective()
	if(!client)
		return
	if(source_jelly?.is_controller_wearer_available())
		reset_perspective(source_jelly.wearer)
		return
	reset_perspective(src)

/mob/living/jelly_controller_shell/proc/open_jelly_interface()
	set name = "Open Communion"
	set category = "Jelly"
	set desc = "Open the communion panel — the window into my body and my host."

	if(!source_jelly || QDELETED(source_jelly))
		to_chat(src, span_warning("My body has dissolved — no host anchors me to the waking world."))
		return
	source_jelly.open_controller_menu(src)

/mob/living/jelly_controller_shell/proc/speak_through_jelly()
	set name = "Speak Through Host"
	set category = "Jelly"
	set desc = "Let my voice rise through the host's flesh so those nearby may hear."

	if(!source_jelly)
		to_chat(src, span_warning("My body is gone — I have no flesh left to speak through."))
		return
	var/message = stripped_input(src, "What words rise through the host's flesh?", "Speak Through Host")
	if(!message)
		return
	source_jelly.emit_controller_speech(src, message)

/mob/living/jelly_controller_shell/proc/emote_through_jelly()
	set name = "Express Through Host"
	set category = "Jelly"
	set desc = "Convey a sensation or intent through my body so those nearby may feel it."

	if(!source_jelly)
		to_chat(src, span_warning("My body is gone — I have no flesh left to express through."))
		return
	var/message = stripped_input(src, "What sensation or intent do I convey?", "Express Through Host")
	if(!message)
		return
	source_jelly.emit_controller_emote(src, message)

/mob/living/jelly_controller_shell/proc/whisper_through_jelly()
	set name = "Murmur to Host"
	set category = "Jelly"
	set desc = "Thread a secret whisper through my flesh that only the host can feel."

	if(!source_jelly)
		to_chat(src, span_warning("My body is gone — I have no flesh left to whisper through."))
		return
	var/message = stripped_input(src, "What do I murmur into the host's flesh?", "Murmur to Host")
	if(!message)
		return
	source_jelly.emit_controller_whisper(src, message)

/mob/living/jelly_controller_shell/proc/use_preset_jelly_action()
	set name = "Express Intent"
	set category = "Jelly"
	set desc = "Flex my body into a familiar pattern of intent."

	if(!source_jelly)
		to_chat(src, span_warning("My body is gone — I have nothing left to move."))
		return
	var/list/preset_actions = source_jelly.get_controller_preset_action_labels()
	if(!preset_actions || !preset_actions.len)
		to_chat(src, span_warning("My body is too unsettled to hold a clear intent."))
		return
	var/choice = input(src, "What instinct do I press into my host?", "Express Intent") as null|anything in preset_actions
	if(!choice)
		return
	source_jelly.emit_controller_preset_action(src, choice)

/mob/living/jelly_controller_shell/proc/manifest_slime_double()
	set name = "Take Shape"
	set category = "Jelly"
	set desc = "Stretch part of myself into a walking shape of slime."

	if(!source_jelly)
		to_chat(src, span_warning("My body is gone — there is no flesh left to shape."))
		return
	source_jelly.request_or_manifest_bound_controller_doppel(src)

/obj/item/intimate_accessory/jelly/eora/strange
	/// Hidden living shell used to hold a bound player controller while the jelly is worn.
	var/mob/living/jelly_controller_shell/controller_shell = null
	/// Standalone TGUI datum for the controller communion panel.
	var/datum/jelly_controller_menu/controller_menu = null
	/// Action-bar button granted to the controller mob for quick access to the communion panel.
	var/datum/action/jelly_controller_menu/controller_action = null
	/// Last known key of the bound controller, for UI/status display.
	var/controller_ckey = null
	/// Last chosen display name for the bound controller.
	var/controller_display_name = null
	/// Current lifecycle state for the bound controller.
	var/controller_state = JELLY_CONTROLLER_STATE_UNBOUND
	/// Whether the controller may speak through the jelly while shell-bound.
	var/controller_speech_enabled = TRUE
	/// Whether the controller may emote through the jelly while shell-bound.
	var/controller_emote_enabled = TRUE
	/// Whether the controller may manifest into the slime doppelganger.
	var/controller_manifest_enabled = TRUE
	/// Whether the wearer has allowed direct wearer-facing controller actions without per-action approval.
	var/controller_direct_control_enabled = FALSE
	/// Whether the wearer has allowed the controller to force short speech and emotes from the wearer's body.
	var/controller_force_enabled = FALSE
	/// Pending controller requests awaiting wearer approval.
	var/list/controller_pending_requests = list()
	/// The next unique controller request id.
	var/next_controller_request_id = 1
	/// Lifetime of a pending controller request.
	var/controller_request_expiration = 45 SECONDS
	/// Maximum number of pending controller requests held at once.
	var/controller_request_queue_limit = 3

/obj/item/intimate_accessory/jelly/eora/strange/proc/has_bound_controller()
	return !!((controller_shell && !QDELETED(controller_shell) && controller_shell.mind) || controller_ckey)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_bound_controller_mob()
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == controller_shell && active_doppelganger.mind)
		return active_doppelganger
	if(controller_shell && !QDELETED(controller_shell) && controller_shell.mind)
		return controller_shell
	return null

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_bound_controller_name()
	if(controller_display_name)
		return controller_display_name
	if(controller_shell && !QDELETED(controller_shell))
		return controller_shell.real_name
	return null

/// Opens (or creates) the standalone controller communion TGUI for the given user.
/obj/item/intimate_accessory/jelly/eora/strange/proc/open_controller_menu(mob/user)
	if(!user)
		return
	if(!controller_menu || QDELETED(controller_menu))
		controller_menu = new /datum/jelly_controller_menu(src)
	controller_menu.ui_interact(user)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_state()
	if(!has_bound_controller())
		return JELLY_CONTROLLER_STATE_UNBOUND
	if(controller_state == JELLY_CONTROLLER_STATE_SUSPENDED)
		return controller_state
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == controller_shell && active_doppelganger.mind && active_doppelganger.client)
		return JELLY_CONTROLLER_STATE_MANIFESTED
	if(controller_shell && !QDELETED(controller_shell) && controller_shell.mind && controller_shell.client)
		return JELLY_CONTROLLER_STATE_SHELL_BOUND
	if(controller_state)
		return controller_state
	return JELLY_CONTROLLER_STATE_UNBOUND

/obj/item/intimate_accessory/jelly/eora/strange/proc/ensure_controller_shell()
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.source_jelly = src
		if(controller_shell.loc != src)
			controller_shell.forceMove(src)
		return controller_shell
	controller_shell = new /mob/living/jelly_controller_shell(src, src)
	controller_shell.source_jelly = src
	return controller_shell

/// Creates (if needed) and grants the action-bar communion button to the given mob.
/obj/item/intimate_accessory/jelly/eora/strange/proc/grant_controller_action(mob/target)
	if(!target)
		return
	if(!controller_action || QDELETED(controller_action))
		controller_action = new /datum/action/jelly_controller_menu(src)
	controller_action.Grant(target)

/obj/item/intimate_accessory/jelly/eora/strange/proc/release_bound_controller(reason = "The jelly no longer has a stable form to hold you.")
	var/mob/living/jelly_controller_shell/shell = controller_shell
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == shell && active_doppelganger.mind)
		active_doppelganger.return_controller_to_body(FALSE)
	controller_shell = null
	controller_ckey = null
	var/released_name = controller_display_name
	controller_display_name = null
	set_controller_state(JELLY_CONTROLLER_STATE_UNBOUND)
	reset_controller_permissions()
	QDEL_NULL(controller_action)
	add_controller_activity("system", "release", "[released_name ? released_name : "Controller"] released", "important")
	if(active_doppelganger && !QDELETED(active_doppelganger))
		active_doppelganger.controller_shell = null
	if(!shell || QDELETED(shell))
		return
	if(shell.mind)
		var/mob/dead/observer/ghost = shell.ghostize(0)
		if(ghost)
			to_chat(ghost, span_warning(reason))
	QDEL_NULL(shell)

/obj/item/intimate_accessory/jelly/eora/strange/proc/is_valid_jelly_controller_candidate(mob/candidate)
	if(!candidate || !candidate.client || !candidate.mind)
		return FALSE
	if(isobserver(candidate) || isnewplayer(candidate))
		return TRUE
	if(ishuman(candidate) && candidate.stat != DEAD)
		return TRUE
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_jelly_candidate_state(mob/candidate)
	if(isnewplayer(candidate))
		return "lobby"
	if(isobserver(candidate))
		return "ghost"
	if(ishuman(candidate))
		return "living"
	return "unknown"

/obj/item/intimate_accessory/jelly/eora/strange/proc/review_controller_volunteers(mob/living/carbon/human/H)
	if(!H || H != wearer || !H.client)
		return FALSE
	if(has_bound_controller())
		var/controller_name = get_bound_controller_name()
		if(!controller_name)
			controller_name = "someone"
		to_chat(H, span_notice("[src] is already inhabited by [controller_name]."))
		return FALSE
	prune_controller_applications()

	var/list/name_map = list()
	for(var/ckey in pending_controller_applications)
		var/list/entry = pending_controller_applications[ckey]
		var/client/candidate_client = entry["client"]
		var/datum/jelly_prefs/pref = entry["pref"]
		var/mob/candidate_mob = candidate_client ? candidate_client.mob : null
		if(!candidate_client || !pref || !is_valid_jelly_controller_candidate(candidate_mob))
			continue
		if(candidate_client.ckey == H.ckey)
			continue
		var/state = get_jelly_candidate_state(candidate_mob)
		var/label = "[pref.jelly_name] ([state], [candidate_client.ckey])"
		name_map[label] = list("client" = candidate_client, "pref" = pref)

	if(!name_map.len)
		to_chat(H, span_notice("No pending jelly controller applicants are waiting for [src]."))
		return FALSE

	while(TRUE)
		var/choice = tgui_input_list(H, "Choose a jelly applicant to inspect:", "Jelly Controller Applications", name_map)
		if(!choice || !H?.client)
			return FALSE
		var/list/entry = name_map[choice]
		var/client/candidate_client = entry["client"]
		var/datum/jelly_prefs/pref = entry["pref"]
		var/mob/candidate_mob = candidate_client?.mob
		if(!candidate_client || !pref || !is_valid_jelly_controller_candidate(candidate_mob))
			to_chat(H, span_warning("That applicant is no longer available."))
			if(candidate_client)
				remove_controller_application(candidate_client, "Your jelly application is no longer valid.")
			name_map -= choice
			if(!name_map.len)
				return FALSE
			continue

		show_jelly_candidate_preview(H, pref, candidate_mob)
		var/confirm = tgui_alert(H, "Accept this applicant as your jelly controller?", "Jelly Controller Applications", list("Accept", "Back"))
		if(!H?.client)
			return FALSE
		if(confirm != "Accept")
			if(H.client)
				winset(H.client, "Jelly Volunteer Inspect", "is-visible=false")
			continue
		// Revalidate candidate after async input
		if(!candidate_client || !is_valid_jelly_controller_candidate(candidate_client.mob))
			to_chat(H, span_warning("That applicant is no longer available."))
			continue
		return offer_controller_role_to_candidate(H, candidate_client, pref)

/obj/item/intimate_accessory/jelly/eora/strange/proc/offer_controller_role_to_candidate(mob/living/carbon/human/H, client/candidate_client, datum/jelly_prefs/pref)
	if(!H || H != wearer || !candidate_client || !pref)
		return FALSE
	if(has_bound_controller())
		to_chat(H, span_warning("[src] already has an inhabiting controller."))
		return FALSE

	var/mob/candidate_mob = candidate_client.mob
	if(!is_valid_jelly_controller_candidate(candidate_mob))
		to_chat(H, span_warning("That applicant is no longer available."))
		remove_controller_application(candidate_client, "Your jelly application is no longer valid.")
		return FALSE

	var/state = get_jelly_candidate_state(candidate_mob)
	var/prompt = "[H.real_name] offers you the chance to awaken as [src]. Will you shed your old self and become the living ooze?"
	if(state == "living")
		prompt += "\n\nIf you accept, your mortal body will dissolve — there is no returning to the life you leave behind."

	switch(askuser(candidate_mob, prompt, "Please answer in [DisplayTimeText(300)]!", "Accept", "Decline", StealFocus=0, Timeout=300))
		if(1)
			if(state == "living")
				var/mob/living/carbon/human/living_candidate = candidate_mob
				if(tgui_alert(living_candidate, "Your possessions will fall away, your station will be forfeit, and your old flesh will dissolve into nothing. There is no undoing this.", "Forsake Your Body", list("Continue", "Cancel")) != "Continue")
					to_chat(living_candidate, span_notice("I cling to the warmth of my own skin — for now."))
					to_chat(H, span_notice("[pref.jelly_name] recoiled from the final step."))
					return FALSE
				// Revalidate after async dialog
				if(!living_candidate.client || !is_valid_jelly_controller_candidate(living_candidate) || has_bound_controller())
					to_chat(H, span_warning("Conditions changed during confirmation. Transfer aborted."))
					return FALSE
				if(tgui_alert(living_candidate, "Last chance. You are becoming [src] — body, name, and all. Once dissolved, only the jelly will carry what you were. Proceed?", "Final Surrender", list("Become the Ooze", "Cancel")) != "Become the Ooze")
					to_chat(living_candidate, span_notice("I cling to the warmth of my own skin — for now."))
					to_chat(H, span_notice("[pref.jelly_name] drew back at the threshold."))
					return FALSE
			if(bind_controller_candidate(candidate_mob, pref))
				clear_controller_applications()
				clear_pending_controller_invitations()
				controller_applications_open = FALSE
				sync_controller_application_listing()
				log_controller_admin_event("[key_name(H)] accepted jelly controller applicant [candidate_client.ckey] for [src].", TRUE)
				to_chat(H, span_notice("[pref.jelly_name] has awakened within [src]."))
				return TRUE
			to_chat(H, span_warning("The ooze shuddered — it could not hold them."))
			return FALSE
		if(2)
			to_chat(candidate_mob, span_notice("I turn away from the ooze's beckoning."))
			to_chat(H, span_notice("The supplicant refused the call."))
			return FALSE
		else
			to_chat(H, span_notice("The supplicant did not answer before the ooze grew still."))
			return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/bind_controller_candidate(mob/candidate_mob, datum/jelly_prefs/pref)
	if(!candidate_mob || !candidate_mob.client || !candidate_mob.mind)
		return FALSE
	if(has_bound_controller())
		return FALSE

	if(isnewplayer(candidate_mob))
		var/mob/dead/new_player/new_candidate = candidate_mob
		new_candidate.close_spawn_windows()

	var/datum/mind/controller_mind = candidate_mob.mind
	var/mob/living/carbon/human/old_body = null
	if(ishuman(candidate_mob))
		old_body = candidate_mob
	var/mob/living/jelly_controller_shell/shell = ensure_controller_shell()
	if(!shell || QDELETED(shell))
		return FALSE

	controller_display_name = pref?.jelly_name
	controller_ckey = controller_mind.key
	if(candidate_mob.ckey)
		controller_ckey = candidate_mob.ckey
	remove_jelly_controller_client_from_applications(candidate_mob.client)
	set_controller_state(JELLY_CONTROLLER_STATE_SHELL_BOUND)
	reset_controller_permissions()
	sync_controller_application_listing()
	shell.source_jelly = src
	shell.forceMove(src)
	if(pref?.jelly_name)
		shell.fully_replace_character_name(shell.real_name, pref.jelly_name)
	if(pref)
		shell.pronouns = pref.jelly_pronouns

	// Re-validate mind before transfer — candidate could have lost it during shell setup
	if(!controller_mind || QDELETED(candidate_mob) || candidate_mob.mind != controller_mind)
		set_controller_state(JELLY_CONTROLLER_STATE_UNBOUND)
		QDEL_NULL(shell)
		return FALSE

	controller_mind.transfer_to(shell, TRUE)
	shell.refresh_controller_perspective()
	grant_controller_action(shell)

	if(old_body)
		log_controller_admin_event("[controller_ckey] abandoned a living body to bind into [src].", TRUE)
		complete_living_controller_transfer(old_body, controller_mind)
	else
		log_controller_admin_event("[controller_ckey] bound into [src] from a non-living controller state.")

	if(wearer && !QDELETED(wearer))
		to_chat(wearer, span_love("[src] gives a pleased, possessive shudder as a new will awakens inside it."))
	to_chat(shell, span_notice("I am [src]. The world narrows to warm darkness and the host's pulse. I may speak through my host's flesh, stir my body with intent, or — when the bond deepens — stretch part of myself into a walking shape of slime."))
	add_controller_activity("system", "bind", "[controller_display_name] bound as controller")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/complete_living_controller_transfer(mob/living/carbon/human/old_body, datum/mind/controller_mind)
	if(!old_body || QDELETED(old_body))
		return
	old_body.unequip_everything()

	var/datum/job/mob_job = SSjob.GetJob(controller_mind?.assigned_role)
	if(mob_job)
		mob_job.current_positions = max(0, mob_job.current_positions - 1)
	var/target_job = SSrole_class_handler.get_advclass_by_name(old_body.advjob)
	if(target_job)
		SSrole_class_handler.adjust_class_amount(target_job, -1)

	old_body.visible_message(span_notice("[old_body] shudders once, then [old_body.p_their()] features soften and dissolve into a waiting ribbon of slime, consumed utterly."))
	QDEL_NULL(old_body)

/obj/item/intimate_accessory/jelly/eora/strange/proc/emit_controller_speech(mob/living/jelly_controller_shell/shell, message)
	if(!shell || shell != controller_shell || !message)
		return FALSE
	if(get_controller_state() == JELLY_CONTROLLER_STATE_SUSPENDED)
		to_chat(shell, span_warning("My body has gone still — the host is lost or shaken. I cannot speak."))
		return FALSE
	if(!controller_speech_enabled)
		to_chat(shell, span_warning("The host has sealed me against speaking."))
		return FALSE
	if(!wearer || QDELETED(wearer) || get_worn_in_slot(wearer) != src || wearer.stat == DEAD)
		to_chat(shell, span_warning("No living host is near enough for me to speak through."))
		return FALSE
	if(!has_bound_controller() && resentment_level >= resentment_communication_block_threshold)
		to_chat(shell, span_warning("I writhe with bitter resentment and swallow my own words before they reach the surface."))
		return FALSE
	var/base_speech_msg = "[src] ripples against [wearer], then voices [shell.real_name]'s words from somewhere inside its flesh: \"[message]\""
	wearer.visible_message(span_love(base_speech_msg) + " " + span_jellycontrolled("(Inhabited)"), span_love(base_speech_msg))
	to_chat(shell, span_notice("My words rise through the host."))
	add_controller_activity("controller", "speech", "[controller_display_name] spoke publicly through the jelly")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/emit_controller_whisper(mob/living/jelly_controller_shell/shell, message)
	if(!shell || shell != controller_shell || !message)
		return FALSE
	if(get_controller_state() == JELLY_CONTROLLER_STATE_SUSPENDED)
		to_chat(shell, span_warning("My body has gone still — the host is lost or shaken. I cannot whisper."))
		return FALSE
	if(!controller_speech_enabled)
		to_chat(shell, span_warning("The host has sealed me against speaking."))
		return FALSE
	if(!wearer || QDELETED(wearer) || get_worn_in_slot(wearer) != src || wearer.stat == DEAD)
		to_chat(shell, span_warning("No living host is near enough for me to whisper through."))
		return FALSE
	to_chat(wearer, span_love("[src] murmurs [shell.real_name]'s words through a secret tremor in its flesh: \"[message]\""))
	to_chat(shell, span_notice("I thread my whisper into the host alone."))
	add_controller_activity("controller", "speech", "[controller_display_name] whispered privately through the jelly")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/emit_controller_emote(mob/living/jelly_controller_shell/shell, message)
	if(!shell || shell != controller_shell || !message)
		return FALSE
	if(get_controller_state() == JELLY_CONTROLLER_STATE_SUSPENDED)
		to_chat(shell, span_warning("My body has gone still — the host is lost or shaken. I cannot express anything."))
		return FALSE
	if(!controller_emote_enabled)
		to_chat(shell, span_warning("The host has stilled me against expression."))
		return FALSE
	if(!wearer || QDELETED(wearer) || get_worn_in_slot(wearer) != src || wearer.stat == DEAD)
		to_chat(shell, span_warning("No living host is near enough for me to convey that."))
		return FALSE
	if(!has_bound_controller() && resentment_level >= resentment_communication_block_threshold)
		to_chat(shell, span_warning("I writhe with bitter resentment and refuse to convey anything."))
		return FALSE
	var/base_emote_msg = "[src] stirs against [wearer] with [shell.real_name]'s intent: [message]"
	wearer.visible_message(span_notice(base_emote_msg) + " " + span_jellycontrolled("(Inhabited)"), span_notice(base_emote_msg))
	to_chat(shell, span_notice("My body conveys the intent."))
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_preset_action_labels()
	return list(
		"Seek Attention",
		"Show Affection",
		"Cling Possessively",
		"Quiver Jealously",
		"Ask To Manifest",
		"Ask For Repositioning",
	)

/obj/item/intimate_accessory/jelly/eora/strange/proc/emit_controller_preset_action(mob/living/jelly_controller_shell/shell, action_name)
	if(!shell || shell != controller_shell || !action_name)
		return FALSE
	if(get_controller_state() == JELLY_CONTROLLER_STATE_SUSPENDED)
		to_chat(shell, span_warning("My body has gone still — the host is lost or shaken. I cannot express anything."))
		return FALSE
	if(!controller_emote_enabled)
		to_chat(shell, span_warning("The host has stilled me against expression."))
		return FALSE
	if(!wearer || QDELETED(wearer) || get_worn_in_slot(wearer) != src || wearer.stat == DEAD)
		to_chat(shell, span_warning("No living host is near enough for me to convey that."))
		return FALSE
	if(!has_bound_controller() && resentment_level >= resentment_communication_block_threshold)
		to_chat(shell, span_warning("I writhe with bitter resentment and swallow my own intent."))
		return FALSE

	var/world_message = null
	var/shell_message = null
	var/log_summary = null
	switch(action_name)
		if("Seek Attention")
			world_message = "[src] gives a needy, aching squeeze against [wearer], craving to be noticed."
			shell_message = "I press my hunger for attention into the host's flesh."
			log_summary = "sought attention"
		if("Show Affection")
			world_message = "[src] softens into a warm, devoted nuzzle against [wearer]."
			shell_message = "I soften with tenderness, letting it pulse through me."
			log_summary = "showed affection"
		if("Cling Possessively")
			world_message = "[src] tightens around [wearer] in a jealous, possessive grip."
			shell_message = "I coil tighter, letting my possessiveness speak for itself."
			log_summary = "clung possessively"
		if("Quiver Jealously")
			world_message = "[src] gives a taut, envious shudder against [wearer], seething with unspoken jealousy."
			shell_message = "I shiver with jealous tension."
			log_summary = "quivered jealously"
		if("Ask To Manifest")
			if(!controller_manifest_enabled)
				to_chat(shell, span_warning("The host has sealed me against manifestation."))
				return FALSE
			world_message = "[src] gathers itself into a yearning pulse against [wearer], straining to birth a shape of slime."
			shell_message = "I strain to take shape in the open."
			log_summary = "requested manifestation"
		if("Ask For Repositioning")
			world_message = "[src] squirms with a deliberate, guiding pressure against [wearer], urging to be moved elsewhere on their body."
			shell_message = "I convey my wish to be resettled."
			log_summary = "requested repositioning"
	if(!world_message || !shell_message || !log_summary)
		return FALSE

	wearer.visible_message(span_notice(world_message) + " " + span_jellycontrolled("(Inhabited)"), span_notice(world_message))
	to_chat(shell, span_notice(shell_message))
	log_game("JELLY: [shell.ckey] [log_summary] through [src].")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/try_manifest_bound_controller_doppel(mob/living/jelly_controller_shell/shell)
	if(!shell || shell != controller_shell)
		return FALSE
	if(get_controller_state() == JELLY_CONTROLLER_STATE_SUSPENDED)
		to_chat(shell, span_warning("My body has gone still — the host is lost or shaken. I cannot take shape."))
		return FALSE
	if(!controller_manifest_enabled)
		to_chat(shell, span_warning("The host has sealed me against manifestation."))
		return FALSE
	if(!shell.client || !shell.mind)
		to_chat(shell, span_warning("My awareness is too thin to hold a shape."))
		return FALSE
	if(!wearer || QDELETED(wearer) || get_worn_in_slot(wearer) != src || wearer.stat == DEAD)
		to_chat(shell, span_warning("I must cling to a living host before I can birth a shape."))
		return FALSE
	if(!has_bound_controller() && bond_escalation_level < doppel_control_bond_level && obsession_level < obsession_manifest_threshold)
		to_chat(shell, span_warning("The bond is too shallow — I cannot yet sustain a walking shape."))
		return FALSE

	var/mob/living/carbon/human/slime_doppelganger/doppel = spawn_doppelganger()
	if(!doppel || QDELETED(doppel))
		to_chat(shell, span_warning("I strain and shudder, but cannot hold a stable shape."))
		return FALSE
	if(doppel.is_player_controlled())
		to_chat(shell, span_warning("Something else already inhabits that shape."))
		return FALSE

	doppel.controller_shell = shell
	doppel.controller_body = null
	shell.mind.transfer_to(doppel, TRUE)
	set_controller_state(JELLY_CONTROLLER_STATE_MANIFESTED)
	grant_controller_action(doppel)
	log_controller_admin_event("[shell.ckey] manifested from [src] into its slime double.")

	var/flavor = get_doppelganger_flavor("doppel_project", wearer)
	if(flavor)
		doppel.visible_message(span_love(flavor))
	to_chat(doppel, span_notice("I stretch part of myself into a walking shape. This slime-flesh clings near my host, cannot fight, and cannot bear worldly burdens."))
	add_controller_activity("controller", "manifest", "[shell.ckey] manifested into the slime double")
	return TRUE

#undef JELLY_CONTROLLER_STATE_UNBOUND
#undef JELLY_CONTROLLER_STATE_SHELL_BOUND
#undef JELLY_CONTROLLER_STATE_MANIFESTED
#undef JELLY_CONTROLLER_STATE_SUSPENDED

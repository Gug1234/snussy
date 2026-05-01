/*
 * prefs_preview_sound.dm — Voice/bark preview ui_act handlers for the
 * TGUI preferences menu. Keep them co-located with the TGUI surface so
 * a future audit of the ui_act switch only needs to grep one folder.
 *
 * Voice: plays a short representative sample from the selected
 * voicepack. The legacy HTML menu had no equivalent surface, so we
 * pick the pack's "laugh" sample (present across every voicepack the
 * body layer exposes) as a deterministic audible cue.
 *
 * Bark: mirrors the legacy `if("barkpreview")` branch of
 * /datum/preferences/process_link() so every gating check (game state,
 * cooldown, parent mob) matches 1:1.
 */

/datum/preferences/proc/act_preview_voice(mob/user, voice_key)
	if(!user?.client)
		return
	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(user, span_warning("Voice previews can't play during initialization!"))
		return
	if(!COOLDOWN_FINISHED(src, bark_previewing))
		return
	COOLDOWN_START(src, bark_previewing, (3 SECONDS))
	// Prefer the explicit voice arg from the TGUI button; fall back to
	// the committed pref when the widget didn't send one (defensive —
	// the current widget always sends it).
	var/key = istext(voice_key) && length(voice_key) ? voice_key : voice_pack
	if(!key || key == "Default")
		to_chat(user, span_notice("Default voicepack has no unique preview."))
		return
	var/voicepack_path = GLOB.voice_packs_list[key]
	if(!voicepack_path)
		to_chat(user, span_warning("Unknown voicepack '[key]'."))
		return
	// The voicepack getters return a cached random sample; call one
	// that exists on every pack shape (old / young / silenced). "laugh"
	// is the most widely populated shared key.
	var/datum/voicepack/vp = new voicepack_path()
	var/sample = vp.getmyoung("laugh") || vp.getmold("laugh") || vp.getfyoung("laugh") || vp.getfold("laugh")
	qdel(vp)
	if(!sample)
		to_chat(user, span_warning("Voicepack '[key]' has no preview sample."))
		return
	SEND_SOUND(user, sound(sample, volume = 75))

/datum/preferences/proc/act_preview_bark(mob/user, bark_key)
	if(!user?.client)
		return
	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(user, span_warning("Bark previews can't play during initialization!"))
		return
	if(!COOLDOWN_FINISHED(src, bark_previewing))
		return
	if(!parent || !parent.mob)
		return
	COOLDOWN_START(src, bark_previewing, (5 SECONDS))
	// Allow the widget to override the pref for a "preview next bark"
	// affordance; fall back to the saved slot.
	var/prev_bark = bark_id
	if(istext(bark_key) && length(bark_key))
		bark_id = bark_key
	var/atom/movable/barkbox = new(get_turf(parent.mob))
	barkbox.set_bark(bark_id)
	var/total_delay = 0
	for(var/i in 1 to (round((32 / bark_speed)) + 1))
		addtimer(CALLBACK(barkbox, TYPE_PROC_REF(/atom/movable, bark), list(parent.mob), 7, 70, BARK_DO_VARY(bark_pitch, bark_variance)), total_delay)
		total_delay += rand(DS2TICKS(bark_speed/4), DS2TICKS(bark_speed/4) + DS2TICKS(bark_speed/4)) TICKS
	QDEL_IN(barkbox, total_delay)
	bark_id = prev_bark

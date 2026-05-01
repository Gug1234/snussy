/*
 * prefs_bottom_bar.dm — Bottom-bar snapshot builder for the TGUI
 * preferences menu (Step 15).
 *
 * Scope: ui_data helpers that describe the lobby state the bottom bar
 * renders — can_join / join_block_reason / migrant_waves / lobby_status.
 * Kept in its own file so the main preferences_tgui.dm ui_data stays
 * terse and the snapshot surface can be unit-tested in isolation.
 *
 * Action execution (join / observe / join_migrant) lives in
 * prefs_action_table.dm; this file only builds the READ-side descriptor.
 */

/**
 * Is this datum being driven by a new_player lobby mob right now?
 *
 * Bottom bar is only meaningful when the player is in the lobby. We
 * check `parent.mob` (the owning client's current mob) rather than
 * `usr` because ui_data is sometimes called out-of-band from a signal
 * handler where `usr` is null.
 */
/datum/preferences/proc/_bottom_bar_new_player()
	if(!parent)
		return null
	if(!istype(parent.mob, /mob/dead/new_player))
		return null
	return parent.mob

/**
 * Build the `{id, label, slots_remaining}` descriptor list for any
 * currently-open migrant wave. There is at most one `current_wave`
 * in the existing SSmigrants model; this returns a list so the TSX
 * dropdown shape is stable if future work introduces concurrent waves.
 *
 * Returns: flat list of assoc lists (empty when no wave is active).
 */
/datum/preferences/proc/_bottom_bar_list_open_waves()
	var/list/out = list()
	if(!SSmigrants || !SSmigrants.current_wave)
		return out
	var/datum/migrant_wave/wave = MIGRANT_WAVE(SSmigrants.current_wave)
	if(!wave)
		return out
	var/total = wave.get_roles_amount()
	var/taken = SSmigrants.get_active_migrant_amount()
	var/remaining = max(0, total - taken)
	out += list(list(
		"id" = "[SSmigrants.current_wave]",
		"label" = wave.name,
		"slots_remaining" = remaining,
	))
	return out

/**
 * Build the (can_join, join_block_reason) pair mirroring the
 * href_list["ready"] / href_list["late_join"] guard rails in
 * new_player.dm. Returns a list `{can_join, reason}` so a single
 * call services both snapshot fields.
 */
/datum/preferences/proc/_bottom_bar_join_gate()
	var/list/out = list("can_join" = FALSE, "reason" = null)
	var/mob/dead/new_player/np = _bottom_bar_new_player()
	if(!np)
		out["reason"] = "You are already in the game."
		return out
	if(!SSticker || SSticker.current_state < GAME_STATE_PREGAME)
		out["reason"] = "The round has not initialized yet."
		return out
	// Mirrors the MINIMUM_FLAVOR_TEXT / MINIMUM_OOC_NOTES gates on the
	// classic href path so the button disable state matches reality
	// instead of letting the user click and get an error toast.
	if(length(flavortext) < MINIMUM_FLAVOR_TEXT)
		out["reason"] = "You need at least [MINIMUM_FLAVOR_TEXT] characters of flavor text."
		return out
	if(length(ooc_notes) < MINIMUM_OOC_NOTES)
		out["reason"] = "You need at least a few words in your OOC notes."
		return out
	if(SSticker.current_state == GAME_STATE_PREGAME)
		out["can_join"] = TRUE
		return out
	if(!SSticker.IsRoundInProgress())
		out["reason"] = "The round is starting or finished; wait for it to resume."
		return out
	if(!GLOB.enter_allowed)
		out["reason"] = "The gates are locked."
		return out
	if(is_active_migrant())
		out["reason"] = "You are in the migrant queue."
		return out
	out["can_join"] = TRUE
	return out

/**
 * Terse one-line lobby status for the right-aligned label in the
 * bottom bar. Leans on SStickers's computed fields so this is
 * read-only and allocation-light.
 */
/datum/preferences/proc/_bottom_bar_status_line()
	if(!SSticker)
		return ""
	if(SSticker.current_state == GAME_STATE_PREGAME)
		var/ready_count = SSticker.totalPlayersReady
		return "Pregame — [ready_count] player(s) ready"
	if(SSticker.current_state == GAME_STATE_SETTING_UP)
		return "Round starting..."
	if(SSticker.IsRoundInProgress())
		var/round_mins = round(SSticker.round_start_time ? (world.time - SSticker.round_start_time) / 600 : 0)
		return "Round in progress — [round_mins] min"
	return "Round ended"

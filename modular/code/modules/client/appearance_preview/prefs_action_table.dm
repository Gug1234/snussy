/*
 * prefs_action_table.dm — Bottom-bar action dispatch registry (Step 3 seed,
 * Step 15 fills bodies).
 *
 * Why a separate table from GLOB.prefs_setter_table:
 *   join_round / observe / join_migrant are NOT prefs mutations — they
 *   are lobby verbs delegated through the prefs window's bottom bar.
 *   Keeping them in a disjoint registry guarantees `ui_act("set_pref")`
 *   cannot reach them, even by key collision, and lets the Step 18 unit
 *   test assert that disjointness directly.
 *
 * Step scope:
 *   This file declares the action datum, the registration helper, and
 *   the registration seed with placeholder bodies. Step 15 replaces the
 *   placeholders with calls into the lobby join / observe / migrant
 *   handlers and wires the bottom-bar snapshot fields.
 */

/**
 * Bottom-bar action descriptor.
 *
 * Fields:
 *   key         — client-facing action string (PREFS_ACTION_* constant).
 *   handler_name — textual name of the proc on /datum/preferences that
 *                  performs the action. Called with (mob/user, list/args).
 *   requires_no_dirty — TRUE for actions that must drain the client
 *                  DirtyLedger before executing (join flows). Step 15
 *                  honors this flag via the Save & Join / Discard & Join
 *                  / Cancel modal.
 */
/datum/prefs_action
	var/key
	var/handler_name
	var/requires_no_dirty = FALSE

/datum/prefs_action/New(key, handler_name, requires_no_dirty = FALSE)
	src.key = key
	src.handler_name = handler_name
	src.requires_no_dirty = requires_no_dirty

/**
 * Registration helper. Keyed on the action string; duplicate registration
 * is a stack_trace to surface config drift early.
 */
/proc/register_prefs_action(key, handler_name, requires_no_dirty = FALSE)
	if(!key || !handler_name)
		stack_trace("register_prefs_action: missing key/handler_name ([key]/[handler_name])")
		return
	if(GLOB.prefs_action_table[key])
		stack_trace("register_prefs_action: duplicate key '[key]' — refusing second registration")
		return
	GLOB.prefs_action_table[key] = new /datum/prefs_action(key, handler_name, requires_no_dirty)

/**
 * Seed registrations for the three bottom-bar actions. Handler bodies
 * are Step 15; placeholders here keep the dispatch table internally
 * consistent so the Step 18 disjointness unit test compiles against a
 * populated action table.
 */
/proc/register_prefs_actions()
	register_prefs_action(PREFS_ACTION_JOIN_ROUND, "action_join_round", TRUE)
	register_prefs_action(PREFS_ACTION_OBSERVE, "action_observe", FALSE)
	register_prefs_action(PREFS_ACTION_JOIN_MIGRANT, "action_join_migrant", TRUE)

// --- Handler bodies (Step 15) --------------------------------------------
// Each handler mirrors the guard rails from the classic new_player.dm
// href_list path so the TGUI bottom-bar button lands the player in the
// same game state as the HTML button would. Return TRUE on successful
// dispatch; the BottomBar.tsx treats a successful act as the terminal
// step (BYOND ui_act is fire-and-forget, and the server closes the
// prefs window as part of the lobby transition).

/**
 * Delegate to the lobby Ready / LateJoin flow.
 *
 * Pregame: flips `ready` to PLAYER_READY_TO_PLAY. The existing
 * ticker machinery handles the rest when the round starts.
 * In-progress: opens LateChoices() (the latejoin job picker). This
 * mirrors what the href="late_join" path does — the picker itself
 * still runs through `AttemptLateSpawn` per job selection.
 */
/datum/preferences/proc/action_join_round(mob/user, list/args)
	if(!istype(user, /mob/dead/new_player))
		to_chat(user, span_warning("You are already in the game."))
		return FALSE
	var/mob/dead/new_player/np = user
	if(length(flavortext) < MINIMUM_FLAVOR_TEXT)
		to_chat(user, span_boldwarning("You need a minimum of [MINIMUM_FLAVOR_TEXT] characters in your flavor text in order to play."))
		return FALSE
	if(length(ooc_notes) < MINIMUM_OOC_NOTES)
		to_chat(user, span_boldwarning("You need at least a few words in your OOC notes in order to play."))
		return FALSE
	if(is_active_migrant())
		to_chat(user, span_boldwarning("You are in the migrant queue."))
		return FALSE
	if(SSticker.current_state <= GAME_STATE_PREGAME)
		np.ready = PLAYER_READY_TO_PLAY
		to_chat(user, span_notice("Thou art ready."))
		SStgui.close_uis(src)
		return TRUE
	if(!SSticker.IsRoundInProgress())
		to_chat(user, span_warning("The round is not ready yet."))
		return FALSE
	if(!GLOB.enter_allowed)
		to_chat(user, span_notice("There is a lock on entering the game!"))
		return FALSE
	SStgui.close_uis(src)
	np.LateChoices()
	return TRUE

/**
 * Delegate to the observe path. Mirrors the href="ready"
 * /PLAYER_READY_TO_OBSERVE branch — sets the ready flag and then
 * calls make_me_an_observer() when the round is already live.
 */
/datum/preferences/proc/action_observe(mob/user, list/args)
	if(!istype(user, /mob/dead/new_player))
		to_chat(user, span_warning("You are already in the game."))
		return FALSE
	var/mob/dead/new_player/np = user
	np.ready = PLAYER_READY_TO_OBSERVE
	if(SSticker && SSticker.current_state > GAME_STATE_PREGAME)
		SStgui.close_uis(src)
		np.make_me_an_observer()
		return TRUE
	to_chat(user, span_notice("You will observe when the round starts."))
	return TRUE

/**
 * Toggle the migrant queue. Matches the `migrant.set_active(TRUE)`
 * path the HTML migrant window currently calls. `wave_id` is
 * informational — the SSmigrants system services the active wave
 * from whoever is queued, independent of per-wave targeting.
 */
/datum/preferences/proc/action_join_migrant(mob/user, list/args)
	if(!istype(user, /mob/dead/new_player))
		to_chat(user, span_warning("You are already in the game."))
		return FALSE
	if(!SSmigrants || !SSmigrants.current_wave)
		to_chat(user, span_warning("There is no open migrant wave right now."))
		return FALSE
	if(!migrant)
		to_chat(user, span_warning("Migrant prefs are unavailable."))
		return FALSE
	migrant.set_active(TRUE)
	return TRUE

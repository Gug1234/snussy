/**
 * prefs_fallback_trigger.dm — Step 16 HTML fallback wiring.
 *
 * Owns the runtime fallback flag that flips `/client/verb/setup_character`
 * (and `/datum/preferences/proc/open_appearance_preferences`) from the
 * TGUI surface back to the legacy HTML `ShowChoices()` path. Two triggers
 * route into this file:
 *
 *   1. Fancy-chat (TGUI panel) fails to initialize within its 5-second
 *      grace. The existing grace-timeout hook in
 *      `code/modules/tgui_panel/tgui_panel.dm` raises
 *      `COMSIG_CLIENT_FANCY_CHAT_FAILED` (declared in
 *      `code/__DEFINES/preferences_tgui.dm`). The listener below flips
 *      `/client.ui_html_fallback = TRUE` for the rest of the session.
 *
 *   2. The per-account `prefs.ui_prefer_classic_html` opt-in toggle. The
 *      TGUI Options body and the legacy HTML options panel both write it;
 *      `should_use_classic_prefs()` folds it into the same gate so a
 *      single check governs every entry point.
 *
 * HTML is never disabled — the `PREFS_MENU_LEGACY_HTML` compile flag
 * (default ON, never to be unset) guarantees `ShowChoices()` remains
 * compiled in. This file assumes that guarantee; if the flag is ever
 * turned off the fallback call site fails to compile and the build
 * breaks loudly, which is the intended safety net.
 *
 * Security / performance: the signal listener is a one-shot flag flip +
 * chat notice. No heap allocation per round, no SS timer, no polling.
 * `ui_html_fallback` lives on `/client` rather than `/datum/preferences`
 * because fancy-chat state is client-session-scoped and must not
 * persist into the next login.
 */

/// Flips TRUE when the fancy-chat panel fails to initialize or when any
/// other cause routes the client onto the legacy HTML prefs surface for
/// the remainder of the session.
/client/var/ui_html_fallback = FALSE

/**
 * Registers the fancy-chat failure listener on this client. Idempotent —
 * safe to call more than once per client. Called from
 * `/client/New()` via the existing appearance-preview wiring; if a new
 * entry point is added it should also call this proc.
 */
/client/proc/register_fancy_chat_fallback_listener()
	RegisterSignal(src, COMSIG_CLIENT_FANCY_CHAT_FAILED, PROC_REF(_on_fancy_chat_failed), override = TRUE)

/**
 * Signal handler for `COMSIG_CLIENT_FANCY_CHAT_FAILED`. Flips the session
 * fallback flag and notifies the player so they know why their Setup
 * Character verb is routing to the classic HTML menu. Silent no-op if
 * the flag is already set (avoids double-notification when the user
 * manually triggers the "reload tguipanel" link and it fails again).
 */
/client/proc/_on_fancy_chat_failed()
	SIGNAL_HANDLER
	if(ui_html_fallback)
		return
	ui_html_fallback = TRUE
	to_chat(src, span_warning("TGUI fancy-chat failed to load; Setup Character will use the classic HTML menu for this session."))

/**
 * Shared fallback gate consulted by both `/client/verb/setup_character`
 * and `/datum/preferences/proc/open_appearance_preferences`. Returns
 * TRUE when the classic HTML `ShowChoices()` path should be used.
 *
 * Intentionally does NOT consult `ui_lobby_button_classic` — that pref
 * controls which path the lobby HUD button takes, not the general
 * Options/verb entry point. Keeping the two axes independent matches
 * the spec §4.6 / project-request freeze.
 */
/client/proc/should_use_classic_prefs()
	if(ui_html_fallback)
		return TRUE
	if(prefs?.ui_prefer_classic_html)
		return TRUE
	return FALSE

/**
 * Core-side `/datum/tgui_panel/proc/on_initialize_timed_out` raises the
 * fancy-chat-failed signal after emitting its chat warning (see the
 * 1-line addition in `code/modules/tgui_panel/tgui_panel.dm`). We keep
 * that emission site in core so the signal name stays colocated with
 * its single producer; the prefs-side listener landing here keeps the
 * consumer in the prefs subsystem's file surface.
 */

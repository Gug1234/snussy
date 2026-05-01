/**
 * preferences_background_state.dm — Modular extension to /datum/preferences.
 *
 * Adds the client-level `background_state` preference, which selects the
 * icon_state used by the live character preview (phase 1a port of tgstation's
 * map_view-hosted dummy). The value is one of the template icon-state names
 * shipped on modular/icons/preview_templates/template*.dmi.
 *
 * This is a client-scoped preference (not character-scoped): changing slots
 * should preserve the player's chosen backdrop. It therefore lives in the
 * global preferences block of the savefile, alongside `ghost_form`,
 * `pda_style`, and other UI chrome preferences.
 *
 * Load / save / sanitize are wired into /datum/preferences/proc/load_preferences
 * and /datum/preferences/proc/save_preferences in
 * code/modules/client/preferences_savefile.dm. Validation is driven by
 * GLOB.appearance_preview_background_states (see
 * code/_globalvars/lists/appearance_preview.dm).
 *
 * Default is `"midgrey"` — the neutral backdrop used by Bubber/Skyrat as the
 * baseline, and the only non-extreme tone in the 8-state template set.
 */

/datum/preferences
	/// Live-preview backdrop icon_state. Must be a member of
	/// GLOB.appearance_preview_background_states.
	var/background_state = "midgrey"

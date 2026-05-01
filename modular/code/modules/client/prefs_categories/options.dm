/**
 * Step 13 — Options category.
 *
 * The four scalar toggles surfaced by the Options body
 * (per_char_hardmode, ui_prefer_classic_html, ui_lobby_button_classic,
 * nickname_color) were already registered in Step 3's dispatch seed
 * (modular/code/modules/client/appearance_preview/prefs_set_pref_dispatch.dm).
 * Bitfield-backed visuals/audio/chat/gameplay toggles still ride the
 * legacy /client/verb/toggle_* surface and remain fully usable; the
 * TGUI Options body intentionally does NOT mirror them today to keep
 * Step 13's PR slim and to avoid double-write hazards on the
 * /datum/preferences.toggles bitmask.
 *
 * Registration hook present for symmetry; populate when bitfield
 * mirroring is introduced.
 */

/proc/register_prefs_options_setters()
	return // intentional no-op for Step 13

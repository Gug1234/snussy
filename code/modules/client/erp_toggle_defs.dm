/**
 * ERP Toggle Definitions
 *
 * The canonical list of ERP preference toggles lives in:
 *   code/modules/client/erp_preferences_menu.dm  — `basic_toggles` static list
 *     inside /datum/preferences/proc/generate_erp_html()
 *
 * To add a new toggle:
 *   1. Declare the var on /datum/preferences in preferences.dm
 *   2. Save/load it in preferences_savefile.dm
 *   3. Append a list() entry to `basic_toggles` in generate_erp_html()
 *   4. Whitelist the key string in the Topic() handler in erp_preferences_menu.dm
 *
 * Chastity hardmode is handled separately (not in basic_toggles) because it
 * requires a confirmation alert on enable and an in-game prayer to disable.
 */

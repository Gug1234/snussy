/**
 * Shared global lists for the Phase 1 live `map_view` character preview port.
 *
 * These globs are the single source of truth for:
 *   - Valid preferences-menu tab identifiers (drives `set_active_tab` validation).
 *   - Tab -> strip-pass family mapping (drives the preview view's
 *     `set_active_editor_context()` call after a tab switch).
 *   - Background-state icon-state enum (drives the `background_state` choiced
 *     preference added in Step 2 and the canvas switch in the preview view
 *     added in Step 3).
 *
 * Adding a new tab requires exactly three edits: a `#define` in
 * code/__DEFINES/preferences.dm, an entry in `appearance_preview_valid_tabs`,
 * and an optional entry in `appearance_preview_tab_to_family` if the tab
 * opens an editor.
 */

/// Authoritative list of preferences-menu tab ids. The `ui_act("set_active_tab")`
/// handler rejects anything not in this list.
GLOBAL_LIST_INIT(appearance_preview_valid_tabs, list(
	APPEARANCE_PREVIEW_TAB_INFO,
	APPEARANCE_PREVIEW_TAB_FEATURES,
	APPEARANCE_PREVIEW_TAB_TAUR_OFFSETS,
	APPEARANCE_PREVIEW_TAB_MARKINGS,
	APPEARANCE_PREVIEW_TAB_INTIMATE_ACCESSORIES,
	APPEARANCE_PREVIEW_TAB_KEYBINDS,
	APPEARANCE_PREVIEW_TAB_GAME,
))

/// Tab id -> strip-pass family. Tabs not present map to
/// APPEARANCE_PREVIEW_FAMILY_NONE (null) implicitly, meaning "no strip pass,
/// render the whole dummy".
///
/// The preview view reads this via
/// `GLOB.appearance_preview_tab_to_family[prefs.active_tab]` after a tab
/// switch, then calls `set_active_editor_context(family, null)`.
GLOBAL_LIST_INIT(appearance_preview_tab_to_family, list(
	APPEARANCE_PREVIEW_TAB_INFO					= APPEARANCE_PREVIEW_FAMILY_NONE,
	APPEARANCE_PREVIEW_TAB_FEATURES				= APPEARANCE_PREVIEW_FAMILY_NONE,
	APPEARANCE_PREVIEW_TAB_TAUR_OFFSETS			= APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS,
	APPEARANCE_PREVIEW_TAB_MARKINGS				= APPEARANCE_PREVIEW_FAMILY_NONE,
	APPEARANCE_PREVIEW_TAB_INTIMATE_ACCESSORIES	= APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS,
	APPEARANCE_PREVIEW_TAB_KEYBINDS				= APPEARANCE_PREVIEW_FAMILY_NONE,
	APPEARANCE_PREVIEW_TAB_GAME					= APPEARANCE_PREVIEW_FAMILY_NONE,
))

/// Icon states present in modular/icons/preview_templates/template*.dmi
/// (all three sheet sizes share the same state names). Drives both the
/// `background_state` choiced preference enum and the canvas switch in
/// /atom/movable/screen/map_view/char_preview.update_body().
///
/// Order here is the order the TSX background-picker swatches render in.
GLOBAL_LIST_INIT(appearance_preview_background_states, list(
	"000",
	"midgrey",
	"FFF",
	"greenstone",
	"wood",
	"cobblestone",
	"sand",
	"church",
))

/*
 * preferences_tgui.dm — Central define surface for the TGUI preferences menu.
 *
 * Scope:
 *   - Canonical pref-key strings (DM <-> TGUI contract). Every key listed here
 *     MUST be registered in GLOB.prefs_setter_table (Step 3) and consumed by a
 *     matching TGUI body (Steps 7+). The allow-list is the sole security
 *     boundary against arbitrary proc invocation via ui_act("set_pref").
 *   - Bottom-bar action keys. These route through GLOB.prefs_action_table and
 *     are intentionally DISJOINT from the setter table; join/observe/migrant
 *     must never be reachable from set_pref.
 *   - Rate-limit caps and dirty-ledger batch caps.
 *   - Compile-flag declarations consumed by preferences_tgui.dm.
 *   - COMSIG_CLIENT_FANCY_CHAT_FAILED — raised by the fancy-chat failure path
 *     so /client/verb/Setup_Character can auto-fallback to the legacy HTML
 *     prefs surface for the remainder of the session.
 *
 * Rule: Adding a new pref = one entry here + one setter registration in
 *       prefs_set_pref_dispatch.dm + one TGUI row in a body module.
 *
 * NOTE: This file is included early so downstream DM modules can reference
 *       these symbols. It deliberately contains no executable code.
 */

// --- Savefile / migration ---------------------------------------------------
// SAVEFILE_VERSION_MAX lives in code/modules/client/preferences_savefile.dm
// and is bumped in Step 1 to gate the additive migration landed in Step 2.
// Do NOT duplicate the version number here to avoid drift.

// --- Rate limiting ---------------------------------------------------------
/// Hard cap on ui_act("set_pref") / ui_act("commit") events accepted per
/// client per second. Drops excess with a log line. Tuned for 200-player
/// lobbies where a runaway client should never be able to stall SStgui.
#define PREFS_ACT_RATE_CAP 20

/// Rolling window (in deciseconds) used to enforce PREFS_ACT_RATE_CAP.
#define PREFS_ACT_RATE_WINDOW_DS 10

/// Maximum number of {key, value} pairs accepted in a single ui_act("commit")
/// envelope. The client DirtyLedger must split larger batches. Keeps any one
/// commit under a predictable BYOND round-trip budget.
#define PREFS_COMMIT_BATCH_MAX 32

// --- Dispatch tables (declared here, populated at SS init in Step 3) -------
GLOBAL_LIST_EMPTY(prefs_setter_table)   // key (string) -> /datum/prefs_setter
GLOBAL_LIST_EMPTY(prefs_action_table)   // key (string) -> /datum/prefs_action

// --- Pref key strings (character-scoped unless noted) ----------------------
// Each constant expands to the exact string the TGUI client sends in
// ui_act("set_pref", {key: "...", value: ...}). Keys are snake_case to match
// existing savefile var naming. Adding a key here is ONLY valid when paired
// with a setter registration (Step 3+).

// Identity / misc
#define PREF_KEY_NICKNAME_COLOR         "nickname_color"

// Internal sentinel: when the client edits a non-key-shaped collection
// (loadout slots, custom piercings, etc.) directly via a dedicated
// ui_act envelope, the client also stages this key in the DirtyLedger
// so the Save/Discard buttons reflect the unsaved state. The setter
// is a no-op; persistence happens via prefs_apply_commit's tail call
// to prefs_persist_dirty, which only requires `dirty_keys` to be
// non-empty (the per-act handler is responsible for adding its own
// real keys to dirty_keys for the actual write).
#define PREF_KEY_PERSIST_ONLY               "__persist_only__"

// Per-character hardmode (replaces the retired client-level toggle).
#define PREF_KEY_PER_CHAR_HARDMODE      "per_char_hardmode"

// Cursed collar round-start equip path (Step 17).
#define PREF_KEY_CURSED_COLLAR_OPT              "cursed_collar_opt"
#define PREF_KEY_CURSED_COLLAR_MASTER_MODE      "cursed_collar_master_mode"
#define PREF_KEY_CURSED_COLLAR_SPECIFIED_NAME   "cursed_collar_specified_name"

// Enum values for PREF_KEY_CURSED_COLLAR_OPT
#define CURSED_COLLAR_OPT_NONE              0
#define CURSED_COLLAR_OPT_COLLAR            1
#define CURSED_COLLAR_OPT_CHASTITY_DEVICE   2

// Enum values for PREF_KEY_CURSED_COLLAR_MASTER_MODE
#define CURSED_COLLAR_MASTER_SELF           0
#define CURSED_COLLAR_MASTER_RANDOM         1
#define CURSED_COLLAR_MASTER_SPECIFIED      2

// Per-account UI toggles (stored at savefile root "/", NOT per character).
#define PREF_KEY_UI_PREFER_CLASSIC_HTML     "ui_prefer_classic_html"
#define PREF_KEY_UI_LOBBY_BUTTON_CLASSIC    "ui_lobby_button_classic"

// Taur mirror toggles (Step 12). Default TRUE; when FALSE the server emits
// per-state/per-side asymmetric offset rows.
#define PREF_KEY_TAUR_CONSISTENT_AROUSAL    "taur_consistent_arousal"
#define PREF_KEY_TAUR_MIRROR_EW             "taur_mirror_ew"
#define PREF_KEY_TESTICLE_MIRROR_EW         "testicle_mirror_ew"

// Body deviation pass (B1): optional race/nobility title freeform text.
// Stored on /datum/preferences.selected_title.
#define PREF_KEY_RACE_TITLE                 "race_title"

// Class & Stats deviation pass (C3/C4/C5): inline statpack / virtue /
// vice / language pickers co-existing with the legacy vices_menu HTML.
// Each wire value is a typepath STRING (text2path'd server-side) so the
// client never sees raw procpaths.
#define PREF_KEY_JOBLESS_ROLE              "joblessrole"
#define PREF_KEY_STATPACK                   "statpack"
#define PREF_KEY_VIRTUE                     "virtue"
#define PREF_KEY_VIRTUE_TWO                 "virtue_two"
#define PREF_KEY_VICE_1                     "vice_1"
#define PREF_KEY_VICE_2                     "vice_2"
#define PREF_KEY_VICE_3                     "vice_3"
#define PREF_KEY_VICE_4                     "vice_4"
#define PREF_KEY_VICE_5                     "vice_5"
#define PREF_KEY_EXTRA_LANGUAGE_1           "extra_language_1"
#define PREF_KEY_EXTRA_LANGUAGE_2           "extra_language_2"

// --- Bottom-bar action keys (Step 15) --------------------------------------
// Routed through GLOB.prefs_action_table, NEVER prefs_setter_table. A unit
// test in Step 18 asserts this disjointness.
#define PREFS_ACTION_JOIN_ROUND     "join_round"
#define PREFS_ACTION_OBSERVE        "observe"
#define PREFS_ACTION_JOIN_MIGRANT   "join_migrant"

// --- Signals ---------------------------------------------------------------
/// Raised on /client when the fancy-chat (TGUI chat) fails to load. Listener
/// in prefs_fallback_trigger.dm (Step 16) flips /client/var/ui_html_fallback
/// to TRUE so Setup_Character routes to legacy ShowChoices() for the rest of
/// the session. Placed here rather than in a new signals_client.dm to keep
/// the include surface minimal; the signal's only consumer is the prefs
/// fallback path.
#define COMSIG_CLIENT_FANCY_CHAT_FAILED "client_fancy_chat_failed"

// --- Compile flags ---------------------------------------------------------
// PREFS_MENU_LEGACY_HTML is declared in code/_compile_options.dm and MUST
// remain defined for the lifetime of this feature. It gates the legacy
// ShowChoices() path that serves the fallback verb and the classic options
// browser. Disabling it would break Step 16's fallback guarantee.

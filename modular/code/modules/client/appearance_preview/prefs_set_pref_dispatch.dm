/*
 * prefs_set_pref_dispatch.dm — Central allow-list for the TGUI
 * preferences menu's `ui_act("set_pref")` envelope (Step 3).
 *
 * Security model:
 *   Every pref key the client can send MUST appear as a row in the
 *   static GLOB.prefs_setter_table. The dispatcher refuses any key it
 *   does not find, so the attack surface is exactly the set of setter
 *   procpaths registered here — no text2path, no dynamic call(src, ...)
 *   on user-supplied input. This is the sole boundary against arbitrary
 *   proc invocation via prefs payloads.
 *
 * Performance:
 *   Registration runs once, idempotently. The guarded helper is reached
 *   on every `ui_act` dispatch (Step 4) but early-outs on the already-
 *   registered flag without rebuilding the tables. List lookup is O(1)
 *   against a single assoc list, which is the cheapest path available
 *   on a 200-player shard.
 *
 * Step scope:
 *   This file seeds only the five trivial setters the plan calls for so
 *   a compile can round-trip without the full category schema. Steps 10+
 *   append per-category rows (identity.dm, body.dm, ...) via the same
 *   register_prefs_setter() helper.
 */

/**
 * Setter descriptor.
 *
 * Fields:
 *   key           — the client-facing string (matches a PREF_KEY_*
 *                   constant in code/__DEFINES/preferences_tgui.dm).
 *   validator     — /proc path (fed a single arg) OR /datum/callback
 *                   returned by a prefs_validate_*() factory. Non-null.
 *   setter_name   — textual name of the proc on /datum/preferences that
 *                   applies the validated value. Resolved via
 *                   PROC_REF() equivalent (call by name) at dispatch.
 *   invalidates_stat_matrix — TRUE when applying this setter changes a
 *                   /datum/preferences field that feeds build_stat_matrix
 *                   (Step 5). Used to bust the matrix cache without a
 *                   second round-trip.
 *   invalidates_preview — TRUE when applying this setter changes a
 *                   character appearance field that the live map_view
 *                   dummy renders. The dirty-ledger dispatch path uses
 *                   this to refresh the preview once after a successful
 *                   mutation, and batches coalesce multiple invalidations
 *                   into one refresh.
 */
/datum/prefs_setter
	var/key
	var/validator
	var/setter_name
	var/invalidates_stat_matrix = FALSE
	var/invalidates_preview = FALSE

/datum/prefs_setter/New(key, validator, setter_name, invalidates_stat_matrix = FALSE, invalidates_preview = FALSE)
	src.key = key
	// Normalise bare /proc path validators into /datum/callback so the
	// validate() fast path has exactly one shape. Relying on
	// call(var_holding_proc_path)() proved unreliable under DM 516 for
	// validators registered via GLOBAL_PROC_REF(), so wrap them here.
	if(validator && !istype(validator, /datum/callback))
		src.validator = CALLBACK(GLOBAL_PROC, validator)
	else
		src.validator = validator
	src.setter_name = setter_name
	src.invalidates_stat_matrix = invalidates_stat_matrix
	src.invalidates_preview = invalidates_preview

/**
 * Runs the registered validator against `value`. Validators are
 * always /datum/callback instances (bare proc paths are wrapped at
 * registration in New() above).
 */
/datum/prefs_setter/proc/validate(value)
	if(isnull(validator))
		return FALSE
	var/datum/callback/cb = validator
	return cb.Invoke(value)

// --- Global flag --------------------------------------------------------
/// Set TRUE by ensure_prefs_dispatch_tables() after the first successful
/// registration pass. The dispatcher (Step 4) calls the ensure helper on
/// every ui_act so registration is lazily primed on the first real edit
/// from any client on the shard; subsequent calls fast-out.
GLOBAL_VAR_INIT(prefs_dispatch_tables_registered, FALSE)

/**
 * Idempotent init for GLOB.prefs_setter_table and GLOB.prefs_action_table.
 *
 * Intentionally not wired to a subsystem: the prefs menu only opens after
 * a client has logged in, so an SS init cycle is unnecessary overhead on
 * roundstart. Lazy init on first open/first edit is O(n) in registration
 * count once per world-run and zero after.
 */
/proc/ensure_prefs_dispatch_tables()
	if(GLOB.prefs_dispatch_tables_registered)
		return
	register_prefs_setters()
	register_prefs_actions()
	register_prefs_singleton_launchers()
	GLOB.prefs_dispatch_tables_registered = TRUE

/**
 * Helper used by per-category files (Steps 10+) to add a row. Keeping
 * the registration surface as a single proc lets unit tests iterate the
 * same call-graph the game uses.
 *
 * Arguments:
 *   invalidates_stat_matrix — TRUE when the setter changes stat matrix inputs.
 *   invalidates_preview — TRUE when the setter changes the rendered dummy.
 */
/proc/register_prefs_setter(key, validator, setter_name, invalidates_stat_matrix = FALSE, invalidates_preview = FALSE)
	if(!key || !validator || !setter_name)
		stack_trace("register_prefs_setter: missing key/validator/setter_name ([key]/[validator]/[setter_name])")
		return
	if(GLOB.prefs_setter_table[key])
		stack_trace("register_prefs_setter: duplicate key '[key]' — refusing second registration")
		return
	GLOB.prefs_setter_table[key] = new /datum/prefs_setter(key, validator, setter_name, invalidates_stat_matrix, invalidates_preview)

/**
 * Seed registrations landed in Step 3. Only the trivial setters the
 * plan calls out — category bodies (Steps 10-14) extend this table.
 *
 * Each setter proc lives on /datum/preferences and accepts a single
 * validated `value` argument.
 */
/proc/register_prefs_setters()
	register_prefs_setter(PREF_KEY_NICKNAME_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_nickname_color")
	register_prefs_setter(PREF_KEY_PER_CHAR_HARDMODE, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_per_char_hardmode")
	register_prefs_setter(PREF_KEY_UI_PREFER_CLASSIC_HTML, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_ui_prefer_classic_html")
	register_prefs_setter(PREF_KEY_UI_LOBBY_BUTTON_CLASSIC, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_ui_lobby_button_classic")
	register_prefs_setter(PREF_KEY_CURSED_COLLAR_OPT, prefs_validate_intrange(CURSED_COLLAR_OPT_NONE, CURSED_COLLAR_OPT_CHASTITY_DEVICE), "set_pref_cursed_collar_opt")
	// Sentinel: client stages this when a collection-shaped envelope
	// (loadout slots, custom piercings) mutates state without going
	// through set_pref. The setter is a no-op; the entry exists purely
	// so prefs_apply_commit accepts the key and its tail call to
	// prefs_persist_dirty fires.
	register_prefs_setter(PREF_KEY_PERSIST_ONLY, GLOBAL_PROC_REF(prefs_validate_anything), "set_pref_persist_only_noop")
	// Per-category extension hooks. Each register_prefs_*_setters proc
	// lives in modular/code/modules/client/prefs_categories/<cat>.dm and
	// is appended here so the dispatch table is always built from one
	// site (the unit test in Step 18 walks this call graph).
	register_prefs_identity_setters()
	register_prefs_identity_extras_setters()
	register_prefs_identity_v2_setters()
	register_prefs_body_setters()
	register_prefs_genital_toggle_setters()
	register_prefs_class_stats_setters()
	register_prefs_intimacy_setters()
	register_prefs_cursed_collar_setters()
	register_prefs_options_setters()
	register_prefs_keybindings_setters()
	register_prefs_heterochromia_setters()

// --- Trivial setters for the seed rows ----------------------------------
// Each one mutates the datum var the client asked for. Values are already
// validated by the time these are called; no defensive re-clamping here
// because the sanitize_*() sweep in load_character runs on next load and
// catches any schema drift.

/datum/preferences/proc/set_pref_nickname_color(value)
	// Canonicalize to "#RRGGBB" for predictable rendering (prefs_validate_hex
	// accepts both forms; we store the leading-#.
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	nickname_color = value

/datum/preferences/proc/set_pref_per_char_hardmode(value)
	per_char_hardmode = !!(isnum(value) ? value : text2num(value))

/datum/preferences/proc/set_pref_ui_prefer_classic_html(value)
	ui_prefer_classic_html = !!(isnum(value) ? value : text2num(value))

/datum/preferences/proc/set_pref_ui_lobby_button_classic(value)
	ui_lobby_button_classic = !!(isnum(value) ? value : text2num(value))

/datum/preferences/proc/set_pref_cursed_collar_opt(value)
	cursed_collar_opt = text2num("[value]")

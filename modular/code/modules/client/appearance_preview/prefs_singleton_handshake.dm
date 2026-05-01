/**
 * @file prefs_singleton_handshake.dm
 * @description Step 14 — singleton-editor launch handshake.
 *
 * Several legacy editors (intimate reactions, intimate accessories,
 * chastity, custom piercings, sex flavor, taur genital offsets, plus
 * the classic class/villain/statpack/loadout/keybindings windows)
 * cannot be inlined into the prefs flat-snapshot ui_data without a
 * larger refactor. The Intimacy / ClassStats / Body / Identity bodies
 * therefore ship a launcher button that fires
 *
 *     act('launch_singleton', { editor: <id> })
 *
 * which the server resolves here, closes the prefs TGUI window, and
 * opens the target standalone editor. When the standalone editor
 * closes (its `ui_close` hook calls `prefs_resume_after_singleton`),
 * the prefs window re-opens to the row the player came from.
 *
 * Design notes:
 *  - Return state lives on `/client` (one open prefs window per
 *    client at a time; the prefs datum itself can be shared by an
 *    admin in standalone mode and we don't want admin VVs to bleed
 *    return state into the targeted player's session).
 *  - The launch table is a static GLOBAL_LIST of editor_id ->
 *    {launcher = procpath, requires_human = bool, label = string}.
 *    Procpaths are registered at compile time only; user input
 *    (the `editor` field) is rejected unless it appears in the
 *    table — same security boundary as `prefs_setter_table`.
 *  - This file owns no /datum/preferences vars; the dispatch is
 *    pure stateless lookup + procpath invocation.
 */

GLOBAL_LIST_EMPTY(prefs_singleton_launchers)
GLOBAL_VAR_INIT(prefs_singleton_launchers_registered, FALSE)

/**
 * Static editor descriptor. Constructed once at registration time;
 * never mutated afterward.
 */
/datum/prefs_singleton_launcher
	/// Stable id matched against `act('launch_singleton', { editor })`.
	var/editor_id
	/// Procpath invoked as `call(<datum/preferences>, launcher_proc)(client)`.
	/// Lives on /datum/preferences so launchers can reach the prefs datum
	/// directly without a second indirection.
	var/launcher_proc
	/// Human-readable label for log lines / runtime traces.
	var/label
	/// When TRUE, launch fails (with a chat warning) if the user is not a
	/// /mob/living/carbon/human. Used by editors that require live mob
	/// state (currently none — the sex-flavor / intimate-reaction lobby
	/// variants explicitly skip the parent New() so they work without a
	/// human mob). Reserved for future singletons.
	var/requires_human = FALSE
	/// Coexistence group id. When set, launching this editor:
	///   * does NOT close the prefs TGUI window (the editor is meant to
	///     be visible alongside it),
	///   * does NOT stash a resume hint (no re-open round-trip needed),
	///   * closes any other launcher in the same group that's currently
	///     tracked on the client (group-scoped mutual exclusion).
	/// Empty string keeps the legacy "close prefs, stash resume" flow.
	var/coexist_group = ""

/datum/prefs_singleton_launcher/New(editor_id, launcher_proc, label, requires_human = FALSE, coexist_group = "")
	src.editor_id = editor_id
	src.launcher_proc = launcher_proc
	src.label = label
	src.requires_human = requires_human
	src.coexist_group = coexist_group

/**
 * Idempotent registry primer. Called from `ensure_prefs_dispatch_tables()`
 * the first time the prefs window opens.
 */
/proc/register_prefs_singleton_launchers()
	if(GLOB.prefs_singleton_launchers_registered)
		return
	GLOB.prefs_singleton_launchers_registered = TRUE

	// Identity-side launchers are no-op stubs for now (Faith / Descriptors
	// / Images bodies route here once their own standalone editors land).
	// Registering the ids reserves them in the security boundary; the
	// launcher procs below emit a friendly "not yet wired" notice rather
	// than runtime, so the buttons stay clickable for QA.
	_register_prefs_launcher("faith",                "_prefs_launch_stub",                          "Faith Selection")
	_register_prefs_launcher("descriptors",          "_prefs_launch_stub",                          "Descriptors")
	_register_prefs_launcher("images",               "_prefs_launch_stub",                          "Character Images")

	// Body-side launchers.
	_register_prefs_launcher("intimate_accessory",   "_prefs_launch_intimate_accessory",            "Intimate Accessories")
	_register_prefs_launcher("body_markings",        "_prefs_launch_stub",                          "Body Markings")
	_register_prefs_launcher("taur_genital_offsets", "_prefs_launch_taur_genital_offsets",          "Taur Genital Offsets")
	// B5/B6 deviation stubs — Head and Extremities currently route the
	// launcher button through the stub path until dedicated TGUI
	// customizer editors land.
	_register_prefs_launcher("head_customizer",      "_prefs_launch_stub",                          "Head Customizer")
	_register_prefs_launcher("extremities_customizer", "_prefs_launch_stub",                        "Extremities Customizer")

	// Class & Stats launchers — the existing pickers continue to own the
	// editing surface for now. All five stub-launch with a notice; the
	// underlying classic windows are reachable from the lobby HUD until
	// per-editor singletons are TGUI-ified in a future PR.
	_register_prefs_launcher("class_picker",         "_prefs_launch_stub",                          "Class Picker")
	_register_prefs_launcher("villain_prefs",        "_prefs_launch_stub",                          "Villain Preferences")
	_register_prefs_launcher("statpack",             "_prefs_launch_stub",                          "Statpack Picker")
	_register_prefs_launcher("virtue_vice",          "_prefs_launch_stub",                          "Virtue / Vice")
	_register_prefs_launcher("language_menu",        "_prefs_launch_stub",                          "Language Menu")
	_register_prefs_launcher("loadout",              "_prefs_launch_stub",                          "Loadout")

	// Intimacy launchers (Step 14 primary surface).
	//
	// These four windows are part of the "intimacy_coexist" group: when
	// the player launches one, the prefs TGUI window stays open and any
	// other member of the group already open is closed. Lets the player
	// edit (e.g.) chastity prefs while still seeing the live mannequin
	// preview in the right column.
	_register_prefs_launcher("intimate_reactions",   "_prefs_launch_intimate_reactions",            "Intimate Reactions",   FALSE, "intimacy_coexist")
	_register_prefs_launcher("sex_flavor",           "_prefs_launch_sex_flavor",                    "Sex Flavor Text",      FALSE, "intimacy_coexist")
	_register_prefs_launcher("custom_piercings",     "_prefs_launch_custom_piercings",              "Custom Piercings",     FALSE, "intimacy_coexist")
	_register_prefs_launcher("chastity",             "_prefs_launch_chastity",                      "Chastity Device",      FALSE, "intimacy_coexist")

	// Options + Keybindings.
	_register_prefs_launcher("classic_options",      "_prefs_launch_classic_options",               "Classic Options")
	_register_prefs_launcher("keybindings",          "_prefs_launch_stub",                          "Keybindings")

/proc/_register_prefs_launcher(editor_id, launcher_proc, label, requires_human = FALSE, coexist_group = "")
	if(GLOB.prefs_singleton_launchers[editor_id])
		stack_trace("Duplicate prefs singleton launcher registration: [editor_id]")
		return
	GLOB.prefs_singleton_launchers[editor_id] = new /datum/prefs_singleton_launcher(editor_id, launcher_proc, label, requires_human)

// --- /client return-state plumbing --------------------------------------

/client
	/// Set by `prefs_stash_return_state` when a singleton launches.
	/// Read+cleared by `prefs_resume_after_singleton`. Either both nullish
	/// or both populated.
	var/prefs_pending_resume_category
	var/prefs_pending_resume_row
	/// Reference to the prefs datum to re-open. Held by weak intent only —
	/// if the player logs out between launch + resume, this is nulled by
	/// /client/Destroy and the resume becomes a no-op.
	var/datum/preferences/prefs_pending_resume_owner
	/// Coexistence tracking: the group + editor id of the currently-open
	/// standalone editor that was launched in coexist mode (i.e. the prefs
	/// window is also open). Used to enforce mutual exclusion within a
	/// group when a second member is launched, and to clear the slot when
	/// the editor closes.
	var/prefs_active_coexist_group = ""
	var/prefs_active_coexist_editor = ""

/**
 * Stash the route the player should return to once the standalone editor
 * closes. Called from the launch_singleton ui_act dispatch right before
 * the prefs window itself closes.
 */
/client/proc/prefs_stash_return_state(datum/preferences/owner, category, row)
	prefs_pending_resume_category = category
	prefs_pending_resume_row = row
	prefs_pending_resume_owner = owner

/**
 * Re-open the prefs window to the saved category/row pair, then clear the
 * stash. No-op when no resume is pending. Called from each singleton
 * editor's ui_close hook.
 */
/client/proc/prefs_resume_after_singleton()
	var/datum/preferences/owner = prefs_pending_resume_owner
	var/cat = prefs_pending_resume_category
	var/row = prefs_pending_resume_row
	prefs_pending_resume_owner = null
	prefs_pending_resume_category = null
	prefs_pending_resume_row = null
	if(!owner || !mob)
		return
	// ui_interact -> tgui_window.initialize -> winexists sleeps, which
	// is illegal in the calling editor's ui_close (marked
	// SpacemanDMM_should_not_sleep). Defer to the next tick so the
	// editor's close path returns synchronously and the new prefs
	// window opens off the main stack.
	owner.pending_resume_category = cat
	owner.pending_resume_row = row
	INVOKE_ASYNC(owner, /datum/preferences/proc/_resume_prefs_for, mob)

/datum/preferences/proc/_resume_prefs_for(mob/user)
	if(!user)
		return
	// Any singleton editor may have mutated statpack/virtue/vice/job/age
	// outside the dispatch table (those writes bypass the setter's
	// invalidates_stat_matrix flag). Bust the cache unconditionally so
	// the right-column stat table rebuilds on reopen.
	invalidate_stat_matrix()
	ui_interact(user)

/datum/preferences
	/// Read once by ui_static_data to seed the client-side route on
	/// re-open after a singleton handshake. Cleared after one read.
	var/pending_resume_category
	var/pending_resume_row
	/// Monotonic token incremented on every resume emission so the
	/// TSX useEffect fires even when the category/row match a prior
	/// hint (same-editor relaunch).
	var/pending_resume_token = 0

// --- Central dispatch for the launch_singleton ui_act envelope -----------

/**
 * Resolve and invoke a singleton launcher. Returns TRUE if the action was
 * handled (regardless of whether the launcher itself succeeded — the
 * envelope is consumed either way to keep the rate limiter honest).
 *
 * Security: every accepted `editor_id` MUST be present in
 * `GLOB.prefs_singleton_launchers`. Unknown ids are dropped + logged.
 */
/datum/preferences/proc/handle_launch_singleton(editor_id, return_category, return_row, mob/user)
	if(!GLOB.prefs_singleton_launchers_registered)
		register_prefs_singleton_launchers()
	var/datum/prefs_singleton_launcher/launcher = GLOB.prefs_singleton_launchers[editor_id]
	if(!launcher)
		log_runtime("prefs_menu: launch_singleton rejected unknown editor id [editor_id] from [user?.ckey]")
		return TRUE
	if(launcher.requires_human && !ishuman(user))
		to_chat(user, span_warning("[launcher.label] needs a live character — try again after spawning."))
		return TRUE
	var/client/C = user?.client
	if(!C)
		return TRUE
	if(launcher.coexist_group)
		// Coexistence path: keep prefs open, close any sibling already
		// up in the same group, hand off without stashing a resume.
		_prefs_close_coexist_group(C, launcher.coexist_group)
		C.prefs_active_coexist_group = launcher.coexist_group
		C.prefs_active_coexist_editor = launcher.editor_id
		call(src, launcher.launcher_proc)(C)
		return TRUE
	// Stash return state BEFORE closing the window so the close path
	// can't race with the resume read on a slow tick.
	C.prefs_stash_return_state(src, return_category, return_row)
	// Close the prefs surface, then hand off to the launcher. The
	// editor opens its own TGUI window; its ui_close fires the resume.
	SStgui.close_uis(src)
	call(src, launcher.launcher_proc)(C)
	return TRUE

/**
 * Close any standalone editor currently tracked on the client for the
 * given coexistence group. Idempotent — if no editor is open, this is
 * a no-op.
 */
/datum/preferences/proc/_prefs_close_coexist_group(client/C, group_id)
	if(!C || !group_id)
		return
	if(C.prefs_active_coexist_group != group_id)
		return
	// SStgui.close_user_uis would also close the prefs window; we want a
	// targeted close. The four intimacy editors all live as datums on
	// /datum/preferences (intimate_lobby_menu / chastity_lobby_menu /
	// intimate_reaction_editor/lobby / sex_flavor_editor/lobby) and use
	// the always_state. Closing every UI on the client tagged with one
	// of those source datums is precise enough without a per-editor
	// registry. tgui_open_uis lives on /mob, not /client.
	var/mob/M = C.mob
	if(M)
		for(var/datum/tgui/ui in M.tgui_open_uis)
			if(istype(ui.src_object, /datum/intimate_lobby_menu) \
				|| istype(ui.src_object, /datum/chastity_lobby_menu) \
				|| istype(ui.src_object, /datum/intimate_reaction_editor) \
				|| istype(ui.src_object, /datum/sex_flavor_editor) \
				|| istype(ui.src_object, /datum/custom_piercing_editor))
				ui.close()
	C.prefs_active_coexist_group = ""
	C.prefs_active_coexist_editor = ""

// --- Launcher procs --------------------------------------------------------
//
// Each launcher receives the calling /client and is responsible for opening
// the standalone editor. Failure modes (no human, missing prereq) emit a
// chat notice and clear the stashed resume so the player isn't stuck with
// a phantom return that never fires.

/datum/preferences/proc/_prefs_launch_stub(client/C)
	to_chat(C, span_notice("This editor is not yet wired to the new prefs menu. Use the lobby HUD's classic window for now."))
	// Drop the stash so the resume doesn't bounce the prefs window back
	// open the next time any unrelated tgui closes.
	C.prefs_pending_resume_owner = null
	C.prefs_pending_resume_category = null
	C.prefs_pending_resume_row = null

/datum/preferences/proc/_prefs_launch_intimate_reactions(client/C)
	if(!C?.mob)
		return
	var/datum/intimate_reaction_editor/lobby/editor = new(src)
	editor.ui_interact(C.mob)

/datum/preferences/proc/_prefs_launch_sex_flavor(client/C)
	if(!C?.mob)
		return
	var/datum/sex_flavor_editor/lobby/editor = new(src)
	editor.ui_interact(C.mob)

/datum/preferences/proc/_prefs_launch_intimate_accessory(client/C)
	if(!C?.mob)
		return
	var/datum/intimate_lobby_menu/menu = new(src)
	menu.ui_interact(C.mob)

/datum/preferences/proc/_prefs_launch_chastity(client/C)
	if(!C?.mob)
		return
	var/datum/chastity_lobby_menu/menu = new(src)
	menu.ui_interact(C.mob)

/datum/preferences/proc/_prefs_launch_classic_options(client/C)
	// Hand the player to the legacy ShowChoices() HTML surface. The
	// classic_options stub used to no-op here, which made the
	// "Open Classic Options" button look broken — closing the prefs
	// window with no follow-up. Calling ShowChoices() directly opens
	// the same window the legacy verb does.
	if(!C?.mob)
		return
	ShowChoices(C.mob)

/datum/preferences/proc/_prefs_launch_custom_piercings(client/C)
	if(!C?.mob)
		return
	open_custom_piercing_editor(C.mob, slot_key = null, standalone = FALSE)

/datum/preferences/proc/_prefs_launch_taur_genital_offsets(client/C)
	if(!C?.mob)
		return
	// Reuses the same opener the legacy `open_taur_editor` ui_act
	// envelope uses; standalone = FALSE keeps the editor bound to
	// prefs.active_editor so the preview pipeline tracks it.
	open_taur_genital_editor(C.mob, "penis", standalone = FALSE)

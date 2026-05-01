/*
 * prefs_dirty_ledger.dm — Server-side dirty-tracking and commit plumbing
 * for the TGUI preferences menu (Step 4).
 *
 * Pairs with the client-side `DirtyLedger.ts` landing in Step 8. The
 * server half exists independent of the client, because:
 *   - `ui_act("set_pref", {key, value})` must be able to apply a single
 *     staged change without waiting for a commit envelope.
 *   - `ui_act("commit", {pairs})` is a batched fast path; either half
 *     can race, so the server is the authority on "what is dirty".
 *
 * Responsibilities:
 *   - Stage a validated pref change in memory (mutate the datum var via
 *     the registered setter, record the key in `dirty_keys`).
 *   - Commit the staged set to the savefile as a single `save_character()
 *     + save_preferences()` pair. Partial-failure degrades to the red
 *     "Save failed — retry" banner per spec §4.3.
 *   - Rate-limit inbound acts per-client to PREFS_ACT_RATE_CAP (§6
 *     threat model). Uses a sliding-window deque on the datum.
 *   - Build the flat `ui_data` snapshot consumed by the TSX shell.
 *
 * Design notes:
 *   - We don't persist per-key snapshots on the server — the client is
 *     the source of truth for "what was the base value when this row
 *     was first shown". The server only tracks WHICH keys are dirty so
 *     the DirtyModal can prompt correctly on slot switch.
 *   - `active_tgui_surface` is a single-session flag (TRUE while a
 *     TGUI prefs window is open for this datum). Enforced by
 *     `ui_interact`/`ui_close`; used to guard against stale background
 *     commits from a closed window.
 *   - Rate limit windows are kept per-datum rather than per-client to
 *     keep the mitigation local to the attack surface (set_pref/commit).
 */

// --- Rate limiter ---------------------------------------------------------

/**
 * Sliding-window rate-limit check.
 *
 * Stores entry timestamps (world.time) in a FIFO list on the datum and
 * drops any outside the rolling PREFS_ACT_RATE_WINDOW_DS window before
 * counting. Returns TRUE when the act is within the PREFS_ACT_RATE_CAP
 * budget; FALSE and logs when it would breach.
 *
 * Called from /datum/preferences/ui_act for every set_pref and commit
 * envelope (not for read-only acts like set_active_tab, rotate,
 * update_background — those are cheap and don't mutate the savefile).
 *
 * Arguments:
 *   user — the mob whose client ownership we log on overflow. Optional;
 *          log line includes the ckey when provided.
 * Returns:
 *   TRUE if the act should proceed, FALSE if it should be dropped.
 */
/datum/preferences/proc/_prefs_rate_limit_check(mob/user)
	var/now = world.time
	if(!last_act_times)
		last_act_times = list()
	// Evict stale entries in-place. We iterate from the head (oldest)
	// and truncate; BYOND list mutations while iterating are valid for
	// Cut() at fixed indices.
	var/window_start = now - PREFS_ACT_RATE_WINDOW_DS
	while(length(last_act_times) && last_act_times[1] < window_start)
		last_act_times.Cut(1, 2)
	if(length(last_act_times) >= PREFS_ACT_RATE_CAP)
		log_admin_private("prefs_rate_limit: ckey=[user?.ckey || parent?.ckey] dropped act (cap=[PREFS_ACT_RATE_CAP] in [PREFS_ACT_RATE_WINDOW_DS]ds)")
		return FALSE
	last_act_times += now
	return TRUE

// --- Dirty staging --------------------------------------------------------

/**
 * Apply a single pref change via the Step 3 dispatch table, mark the
 * key dirty, and record the value in `pending_values` so a later
 * `dirty_commit()` can rebuild the committed set if needed.
 *
 * This is the sole proc permitted to mutate a pref key from TGUI input
 * (outside the seed-setter paths hit via `call`). The call order is:
 *   1. Rate-limit check (caller).
 *   2. Allow-list lookup against GLOB.prefs_setter_table.
 *   3. Validator.
 *   4. Resolved setter proc call on /datum/preferences.
 *   5. Refresh the live preview when the setter declares that the
 *      mutation affects appearance.
 *   6. Mark dirty + cache pending value.
 *
 * Arguments:
 *   key   — client-supplied string; MUST appear in prefs_setter_table.
 *   value — client-supplied value; the setter's validator must accept.
 *   user  — mob for logging.
 *   persist — TRUE for single-key autosave; FALSE for batched commits.
 *   refresh_preview — TRUE for single-key dispatch. Batched commits pass
 *                     FALSE and coalesce preview invalidation after the loop.
 * Returns:
 *   TRUE on successful apply; FALSE on unknown key / validator reject /
 *   missing setter proc. Caller should surface a client toast on FALSE.
 */
/datum/preferences/proc/prefs_apply_set_pref(key, value, mob/user, persist = TRUE, refresh_preview = TRUE)
	if(!key)
		return FALSE
	var/datum/prefs_setter/setter = GLOB.prefs_setter_table[key]
	if(!setter)
		// Unknown key — silent drop on the wire (client toast handles UX).
		// Log rate-limited via the admin private channel so a fuzzer run
		// surfaces in round-end logs.
		log_admin_private("prefs_set_pref: unknown key '[key]' from ckey=[user?.ckey || parent?.ckey]")
		to_chat(user, span_warning("prefs diag: unknown key '[key]'"))
		return FALSE
	if(!setter.validate(value))
		log_admin_private("prefs_set_pref: validator reject key='[key]' from ckey=[user?.ckey || parent?.ckey]")
		to_chat(user, span_warning("prefs diag: validator reject key='[key]' value='[value]'"))
		return FALSE
	// Resolve the registered setter by name. Using call(src, name)(value)
	// keeps the dispatch table free of procpath literals (name-based
	// registration is easier to read and matches what Steps 10+ will
	// write).
	if(!hascall(src, setter.setter_name))
		stack_trace("prefs_set_pref: setter '[setter.setter_name]' missing on /datum/preferences (key='[key]')")
		to_chat(user, span_warning("prefs diag: setter '[setter.setter_name]' missing on /datum/preferences (key='[key]')"))
		return FALSE
	call(src, setter.setter_name)(value)
	if(!dirty_keys)
		dirty_keys = list()
	if(!pending_values)
		pending_values = list()
	dirty_keys |= key
	pending_values[key] = value
	// Step 5: stat-matrix cache invalidation. The setter's declared
	// invalidates_stat_matrix flag drives whether this write forces a
	// rebuild on the next ui_data round. Kept on the dispatch entry
	// (not computed from the key) so non-stat setters never pay the
	// cache-blow cost.
	if(setter.invalidates_stat_matrix)
		invalidate_stat_matrix()
	if(refresh_preview && setter.invalidates_preview)
		render_new_preview_appearance()
	// Single-key autosave path: the DirtyLedger client sends set_pref
	// with `autosave=true` intent and never follows up with a commit.
	// Without persisting here the in-memory mutation would be dropped
	// on the next slot reload (window close/reopen round-trips through
	// the savefile). Commit-batch callers pass persist=FALSE so they
	// can issue a single prefs_persist_dirty at the end of the batch.
	if(persist)
		prefs_persist_dirty(user)
	return TRUE

// --- Batched commit -------------------------------------------------------

/**
 * Batched apply entry point for `ui_act("commit", {pairs})`.
 *
 * Applies each {key, value} in order, collecting failures so the client
 * can surface per-key errors without losing successful writes from the
 * same batch. Enforces PREFS_COMMIT_BATCH_MAX so an adversarial client
 * can't stall the server on one envelope.
 *
 * Arguments:
 *   pairs — list of /list(`key`, `value`) OR assoc list `key = value`.
 *           Both shapes are accepted because TGUI's JSON layer doesn't
 *           preserve tuple order across environments.
 *   user  — mob for logging.
 * Returns:
 *   A list of keys that failed to apply. Empty list == full success.
 */
/datum/preferences/proc/prefs_apply_commit(list/pairs, mob/user)
	var/list/failed = list()
	if(!islist(pairs) || !length(pairs))
		return failed
	if(length(pairs) > PREFS_COMMIT_BATCH_MAX)
		log_admin_private("prefs_commit: oversize batch [length(pairs)] > cap [PREFS_COMMIT_BATCH_MAX] from ckey=[user?.ckey || parent?.ckey]")
		failed += "__batch_too_large"
		return failed
	// Support both tuple-list and assoc-list shapes.
	var/needs_preview_refresh = FALSE
	for(var/entry in pairs)
		var/k
		var/v
		if(islist(entry))
			var/list/pair = entry
			k = pair["key"]
			v = pair["value"]
		else
			k = entry
			v = pairs[entry]
		var/datum/prefs_setter/setter = GLOB.prefs_setter_table[k]
		if(!prefs_apply_set_pref(k, v, user, persist = FALSE, refresh_preview = FALSE))
			failed += k
			continue
		if(setter?.invalidates_preview)
			needs_preview_refresh = TRUE
	if(needs_preview_refresh)
		render_new_preview_appearance()
	// Persist the whole committed set in one pass. We call both save
	// procs because some keys live on the preferences root (per-account)
	// and some on the active character (per-slot); the savefile writer
	// no-ops on unchanged fields so this isn't wasteful.
	prefs_persist_dirty(user)
	return failed

/**
 * Write the in-memory state to disk.
 *
 * Separate from prefs_apply_commit so autosave paths (single-key set_pref
 * with autosave semantics, landing in Step 8 client-side) can persist
 * without going through a commit envelope.
 *
 * On save failure the dirty set is PRESERVED (so the retry banner has
 * something to flush on the next attempt); on success the set is cleared.
 *
 * Arguments:
 *   user — mob for logging.
 * Returns:
 *   TRUE on full success, FALSE if either save proc reported failure.
 */
/datum/preferences/proc/prefs_persist_dirty(mob/user)
	if(!length(dirty_keys))
		return TRUE
	var/ok_prefs = save_preferences()
	var/ok_char = save_character()
	if(ok_prefs && ok_char)
		dirty_keys.Cut()
		pending_values.Cut()
		return TRUE
	// Leave dirty_keys/pending_values intact so the client banner has a
	// retry target and subsequent commits can re-flush.
	log_admin_private("prefs_persist_dirty: partial save failure (prefs=[ok_prefs], char=[ok_char]) ckey=[user?.ckey || parent?.ckey]")
	to_chat(user, span_warning("Preferences failed to persist (prefs_ok=[ok_prefs], char_ok=[ok_char]). Please report this."))
	return FALSE

/**
 * Discard unsaved changes and reload the active slot from disk. Used by
 * the DirtyModal's Discard path on slot switch / close.
 *
 * Arguments:
 *   user — mob for logging.
 */
/datum/preferences/proc/prefs_discard_dirty(mob/user)
	if(!length(dirty_keys))
		return TRUE
	dirty_keys.Cut()
	pending_values.Cut()
	// Reload the slot from savefile so any in-memory mutations from
	// prefs_apply_set_pref are undone. load_character re-sanitizes.
	load_character(default_slot)
	return TRUE

// --- Snapshot builder -----------------------------------------------------

/**
 * Flat pref snapshot for the TGUI shell's `ui_data`.
 *
 * Iterates every key registered in GLOB.prefs_setter_table and asks the
 * per-key snapshot field accessor for the current value. Result is a
 * flat assoc list `{key: value}` the TSX shell diffs against its last
 * render to minimize re-paint (§2.4 State Sync).
 *
 * The keys in this list are exactly the keys the client is allowed to
 * set via set_pref, so the contract is symmetric and easy to audit:
 *   - If a key is in the snapshot, the client can set it.
 *   - If a key is NOT in the snapshot, ui_act will reject it anyway.
 *
 * Step 5 augments this with `stat_matrix`; Step 15 adds bottom-bar
 * fields (`can_join`, `migrant_waves`, `lobby_status`). Both are
 * additive, non-conflicting namespaces.
 *
 * Arguments:
 *   user — mob requesting the snapshot (for future ERP-gated slicing).
 * Returns:
 *   /list — flat assoc list; empty when dispatch tables are unregistered.
 */
/datum/preferences/proc/build_prefs_snapshot(mob/user)
	var/list/out = list()
	if(!GLOB.prefs_dispatch_tables_registered)
		// Open_appearance_preferences guarantees registration before
		// ui_interact, but defensive null-return keeps the builder safe
		// if a future caller skips the opener path.
		return out
	for(var/key in GLOB.prefs_setter_table)
		out[key] = get_pref_snapshot_field(key)
	// Dirty-key list is echoed so the client can reconcile its local
	// ledger (e.g. after a reconnect that restored the TGUI surface).
	out["_dirty_keys"] = (dirty_keys && length(dirty_keys)) ? dirty_keys.Copy() : list()
	return out

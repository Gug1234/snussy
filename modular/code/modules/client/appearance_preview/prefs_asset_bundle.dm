/*
 * prefs_asset_bundle.dm \u2014 Preloaded prefs asset bundle (Step 6).
 *
 * Aggregates every spritesheet the PreferencesMenu TGUI surface consumes
 * (jobs, species portraits, hair, facial hair, traits, loadout) under
 * one /datum/asset/group so a single send() call flushes the full set
 * to a client. The group's children list is intentionally EMPTY at this
 * step \u2014 category modules landing in Steps 10\u201313 register their
 * concrete /datum/asset/spritesheet_batched subtypes by appending their
 * typepath here (see `register_prefs_bundle_child`).
 *
 * Architectural choices:
 *   \u2022 /datum/asset/group (not /datum/asset/spritesheet_batched) because
 *     the 6 sheets already live as independent assets in their respective
 *     category modules \u2014 combining them into one batched sheet would
 *     break the per-category cache keys and force full-bundle rebuilds on
 *     any single-sheet change. The group just aggregates send() calls.
 *   \u2022 Sent at /client/New (post-login, inside the existing send_resources
 *     spawn(10) block) so the bundle piggybacks the existing
 *     asset_simple_preload path without adding a second timer. Non-blocking
 *     by construction because /datum/asset/group.send dispatches to child
 *     assets which each honour SSasset_loading deferral.
 *   \u2022 Empty-children fast-out keeps Step 6 free of runtime churn before
 *     category modules populate the bundle; Build All passes with zero
 *     transport overhead.
 *
 * Performance rationale (\u00a76 threat / \u00a71.3 Critical Path):
 *   At 200 concurrent logins, each bundle send is one network flush across
 *   all children. The group dispatches in registration order; the
 *   underlying SSassets.transport.send_assets tick-budget check prevents
 *   bursty output. Per-client cost is O(n_children) once per session.
 */

/// Aggregator asset for the prefs menu. Children are appended by category
/// modules in later steps. A concrete child typepath must be a subtype of
/// /datum/asset/simple or /datum/asset/spritesheet_batched so the
/// group's register()/send() call signatures resolve.
/datum/asset/group/prefs_bundle
	// children populated dynamically at init via register_prefs_bundle_child
	// so category modules don't all have to edit this file.
	children = list()

/**
 * Registration helper used by category modules (Steps 10\u201313).
 *
 * Appends a child asset datum typepath to the prefs bundle. Safe to call
 * multiple times with the same typepath (idempotent). Must be called at
 * or before the first `queue_prefs_bundle_for(client)` invocation \u2014 i.e.
 * during module init, not from a player-triggered code path.
 *
 * Arguments:
 *   child_type \u2014 /datum/asset subtype path to include in the bundle.
 * Returns:
 *   TRUE on success, FALSE on invalid argument.
 */
/proc/register_prefs_bundle_child(child_type)
	if(!ispath(child_type, /datum/asset))
		stack_trace("register_prefs_bundle_child: non-asset typepath [child_type]")
		return FALSE
	var/datum/asset/group/prefs_bundle/bundle = get_asset_datum(/datum/asset/group/prefs_bundle)
	if(!bundle)
		return FALSE
	if(!bundle.children)
		bundle.children = list()
	if(child_type in bundle.children)
		return TRUE
	bundle.children += child_type
	return TRUE

/**
 * Client-side entrypoint. Hooked from /client/send_resources once per
 * login. Fast-outs when the bundle is empty (pre-Step-10 state) so there
 * is zero overhead until category modules register children.
 *
 * Arguments:
 *   C \u2014 the client receiving the bundle. Caller is responsible for
 *       ensuring C is still connected.
 */
/proc/queue_prefs_bundle_for(client/C)
	if(!istype(C))
		return
	var/datum/asset/group/prefs_bundle/bundle = get_asset_datum(/datum/asset/group/prefs_bundle)
	if(!bundle || !length(bundle.children))
		return
	// /datum/asset/group.send iterates children and calls their own send(),
	// each of which honours SSasset_loading deferral / tick budget.
	bundle.send(C)

/**
 * Introspection helper for ui_static_data. Returns the list of child
 * asset typepaths currently registered, as strings. The TSX shell uses
 * this to assert the bundle landed before rendering sheet-backed rows.
 *
 * Returns:
 *   /list of typepath strings. Empty when nothing is registered.
 */
/proc/get_prefs_bundle_child_names()
	var/datum/asset/group/prefs_bundle/bundle = get_asset_datum(/datum/asset/group/prefs_bundle)
	if(!bundle || !length(bundle.children))
		return list()
	var/list/out = list()
	for(var/child_type in bundle.children)
		out += "[child_type]"
	return out

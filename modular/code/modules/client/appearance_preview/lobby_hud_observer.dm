/**
 * lobby_hud_observer.dm — Phase 1, Step 6 of the tgstation map_view preview
 * port. Replaces the 4× `mutable_appearance` lobby HUD driver
 * (client_procs.dm::show_character_previews) with a passive observer that
 * mirrors `prefs.character_preview_view.body.appearance` onto the 4 cardinal
 * holders in the `character_preview_map` HUD area.
 *
 * Addendum F.2 — single-owner broadcast contract:
 *   - The /atom/movable/screen/map_view/char_preview owned by the prefs datum
 *     is the sole source of truth for the preview dummy's appearance.
 *   - The 4 cardinal lobby holders are pure passive observers: they copy
 *     `body.appearance` and set their own `.dir` for per-cardinal framing.
 *   - Refresh is driven by COMSIG_PREFS_PREVIEW_UPDATED, emitted at the tail
 *     of char_preview/update_body(). No polling, no flatten, no base64.
 *
 * When `APPEARANCE_PREVIEW_LEGACY_FLATTEN` is defined (default during the
 * first build cycle post-Phase-1), `preferences_setup.dm::update_preview_icon`
 * still runs the legacy flatten path for safety parity. When the flag is
 * undefined, update_preview_icon routes here and the legacy proc
 * (`/client/proc/show_character_previews`) is never called.
 *
 * Roguetown adaptations vs. upstream:
 *   - We keep the 4-cardinal 3×3 HUD layout (`character_preview_map` skin
 *     element) because it's a roguetown UX signature. tgstation uses a
 *     single rotatable map_view; our observer simulates the 4 facings by
 *     letting BYOND resolve each holder's .dir against the copied
 *     appearance's dir-aware icon_states.
 *   - Legacy `/atom/movable/screen/char_preview` is reused as the holder
 *     type so the existing `char_render_holders` teardown in Logout()
 *     keeps working without change.
 */

/**
 * Per-client map of observer-path render holders:
 *   "bg"  → /atom/movable/screen/char_preview  (0,0 to 3,3 background tile)
 *   "[D]" → /atom/movable/screen/char_preview  (one per GLOB.cardinals entry)
 *
 * Shares the `char_render_holders` assoc-list that the legacy flatten path
 * already drains in `Logout`, so no new teardown plumbing is required.
 */

/**
 * Mirror `prefs.character_preview_view.body.appearance` onto the 4-cardinal
 * lobby HUD. Idempotent — subsequent calls with the same prefs just refresh
 * the appearance snapshots. Registers a single signal listener on the
 * preferences datum so future `update_body()` calls auto-refresh.
 *
 * Arguments:
 *   prefs — the preferences datum whose character_preview_view owns the dummy.
 *           No-op (and clears any stale holders) when prefs is null.
 */
/client/proc/show_character_previews_from_view(datum/preferences/prefs)
	if(!prefs)
		clear_character_previews_from_view()
		return
	var/atom/movable/screen/map_view/char_preview/view = prefs.character_preview_view
	if(!view || QDELETED(view))
		// Lazy allocate the view if the lobby is the first caller (before any
		// TGUI editor has opened). The view owns its own dummy and refresh loop.
		view = prefs.create_character_preview_view(mob)
	if(!view || !view.body)
		return

	// (Re)attach the signal handler before the first refresh, so subsequent
	// edits from any caller (pref slider, save_character, editor commit) push
	// a refresh without the lobby having to poll.
	UnregisterSignal(prefs, COMSIG_PREFS_PREVIEW_UPDATED)
	RegisterSignal(prefs, COMSIG_PREFS_PREVIEW_UPDATED, PROC_REF(_on_preview_updated))

	// Background tile — static, allocated once and reused across refreshes.
	var/atom/movable/screen/char_preview/background = LAZYACCESS(char_render_holders, "bg")
	if(!background)
		background = new()
		background.screen_loc = "character_preview_map:0,0 to 3,3"
		LAZYSET(char_render_holders, "bg", background)
		screen += background

	// 4 cardinal holders, one per GLOB.cardinals entry. Each gets the same
	// body.appearance snapshot but its own .dir, so BYOND's icon_state
	// direction resolution picks the right frame for each facing.
	_refresh_cardinal_holders(view.body)

/**
 * Signal handler for COMSIG_PREFS_PREVIEW_UPDATED. Source is the prefs datum;
 * second arg is the view. Re-copies the body appearance onto the existing
 * cardinal holders without reallocating them.
 */
/client/proc/_on_preview_updated(datum/source, atom/movable/screen/map_view/char_preview/view)
	SIGNAL_HANDLER
	if(!view || QDELETED(view) || !view.body)
		return
	_refresh_cardinal_holders(view.body)

/**
 * Internal helper: allocate (or reuse) the 4 cardinal holders, re-apply the
 * body's current appearance to each, and stamp per-cardinal `.dir` + screen_loc.
 * Split out so both initial attach and signal-driven refresh share one code path.
 */
/client/proc/_refresh_cardinal_holders(mob/living/carbon/human/dummy/body)
	if(!body)
		return
	var/pos = 0
	for(var/D in GLOB.cardinals)
		pos++
		var/atom/movable/screen/char_preview/O = LAZYACCESS(char_render_holders, "[D]")
		if(!O)
			O = new
			LAZYSET(char_render_holders, "[D]", O)
			screen += O
		// Copy the full appearance (icon, icon_state, overlays) from the
		// view's dummy. Holder's own .dir drives the direction resolution so
		// each cardinal of the 3×3 lobby HUD shows the character facing a
		// different way without 4× flattening.
		O.appearance = body.appearance
		O.dir = D
		// Screen positions mirror the legacy show_character_previews layout.
		switch(pos)
			if(1)
				O.screen_loc = "character_preview_map:2,2"
			if(2)
				O.screen_loc = "character_preview_map:1,2"
			if(3)
				O.screen_loc = "character_preview_map:1,1"
			if(4)
				O.screen_loc = "character_preview_map:2,1"

/**
 * Tear down the observer-path lobby HUD. Unregisters the preview-updated
 * signal, removes the bg + 4 cardinal holders from the screen, qdels them,
 * and clears `char_render_holders`. Safe to call when nothing was attached.
 *
 * Distinct from the legacy `/client/proc/clear_character_previews` so the
 * two paths can coexist under the compile flag during the rollover cycle.
 */
/client/proc/clear_character_previews_from_view()
	if(prefs)
		UnregisterSignal(prefs, COMSIG_PREFS_PREVIEW_UPDATED)
	if(!char_render_holders)
		return
	for(var/key in char_render_holders)
		var/atom/movable/screen/S = char_render_holders[key]
		if(S)
			screen -= S
			qdel(S)
	char_render_holders = list()

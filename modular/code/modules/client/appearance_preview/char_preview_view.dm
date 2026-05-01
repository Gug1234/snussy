/**
 * char_preview_view.dm — Phase 1a of the tgstation map_view character
 * preview port. Live, client-rendered character backdrop that replaces
 * the `getFlatIcon`-based 4× per-edit PNG flatten loop.
 *
 * Architecture (mirrors Bubber/Skyrat):
 *   /atom/movable/screen/map_view             (bare base; BYOND screen obj
 *                                              assignable to a TGUI map
 *                                              control via assigned_map +
 *                                              client.register_map_obj)
 *     └─ /atom/movable/screen/map_view/char_preview
 *          - owns a long-lived /mob/living/carbon/human/dummy (slot:
 *            DUMMY_HUMAN_SLOT_PREFERENCES), checked out for the life of
 *            the view (NOT per edit like the legacy flatten path).
 *          - `update_body()` runs `/datum/preferences/copy_to`, applies
 *            the active-editor strip pass, composites the dummy onto a
 *            size-appropriate background canvas, and reassigns
 *            `src.appearance = canvas.appearance`. Zero flattening,
 *            zero PNG.
 *          - Emits `COMSIG_PREFS_PREVIEW_UPDATED` on the owning prefs
 *            datum at the tail so lobby-HUD observers can refresh.
 *
 * Roguetown adaptations vs. upstream:
 *   - `preferences.copy_to(...)` replaces tgstation's `safe_transfer_prefs_to`
 *     (roguetown has no safe_transfer_prefs_to proc).
 *   - Canvas tier picker is taur-aware via ORGAN_SLOT_TAUR_BODY.
 *   - Strip pass keyed by APPEARANCE_PREVIEW_FAMILY_* (see
 *     code/__DEFINES/preferences.dm). Taur uses the same
 *     `taur_genital_global_hide` trick the legacy editor hook uses.
 *     The view also stores an opaque active target key for the hybrid
 *     overlay pipeline; current family strip hooks use it as metadata
 *     and keep the smallest safe coarse fallback until each editor grows
 *     part/entry-specific suppression.
 *
 * NOTE: This file introduces the view datum only. Prefs datum wiring
 * (character_preview_view var, ui_interact lifecycle, ui_static_data
 * emission) lands in Step 4. Lobby observer wiring lands in Step 6.
 */

// -----------------------------------------------------------------------------
// Base map_view screen (minimal port).
//
// Roguetown already has a lone forward declaration of
// `/atom/movable/screen/map_view/examine_panel_screen` but no concrete base —
// that file never wires the screen to a client. We provide the real base here
// so the char_preview subtype has lifecycle procs to inherit. A future cleanup
// can migrate the examine panel onto this base.
// -----------------------------------------------------------------------------

/atom/movable/screen/map_view
	/// Map-control id used by TGUI (<ByondUi params={{id, type:'map'}}/>).
	/// Must be set by subtypes or the caller before `display_to`.
	var/assigned_map
	/// If TRUE, the screen is qdel'd when the last displaying mob drops it.
	/// Char_preview intentionally keeps this FALSE — lifetime is owned by
	/// the /datum/preferences that created it.
	var/del_on_map_removal = TRUE
	/// Tracks clients currently viewing this screen, for bookkeeping and
	/// unregister on Destroy.
	var/list/client/registered_clients

/atom/movable/screen/map_view/Destroy()
	if(registered_clients)
		for(var/client/C as anything in registered_clients)
			if(C)
				C.screen -= src
		registered_clients = null
	return ..()

/**
 * Register this screen as a map control on the given client. The client
 * will then be able to render the screen inside a TGUI `<ByondUi type="map"/>`
 * whose id matches `assigned_map`.
 */
/atom/movable/screen/map_view/proc/display_to(viewer)
	var/client/C
	if(istype(viewer, /client))
		C = viewer
	else if(ismob(viewer))
		var/mob/M = viewer
		C = M.client
	if(!C)
		return
	// BYOND map control pickup: any movable with screen_loc targeting an
	// `assigned_map` id gets rendered inside the matching TGUI `<ByondUi
	// type="map"/>`. Adding to client.screen is the portable registration
	// pattern used across roguetown's TGUI surfaces.
	if(assigned_map && !screen_loc)
		// CENTER,CENTER so the tile always reads as centred even when
		// the viewer's `client.view` is larger than one tile. The
		// previous `1,1` anchor pinned the backdrop to the bottom-left
		// of the map region, which BYOND draws at the top-left of the
		// TGUI control — hence the "stuck in the corner" symptom.
		screen_loc = "[assigned_map]:CENTER,CENTER"
	C.screen |= src
	LAZYADD(registered_clients, C)

/**
 * Stop showing this screen to the given mob. If `del_on_map_removal` is
 * TRUE and no clients are left, the screen qdels itself.
 */
/atom/movable/screen/map_view/proc/hide_from(viewer)
	var/client/C
	if(istype(viewer, /client))
		C = viewer
	else if(ismob(viewer))
		var/mob/M = viewer
		C = M.client
	if(!C)
		return
	C.screen -= src
	LAZYREMOVE(registered_clients, C)
	if(del_on_map_removal && !LAZYLEN(registered_clients))
		qdel(src)

// -----------------------------------------------------------------------------
// Character preview view.
// -----------------------------------------------------------------------------

/// Canvas tier file paths, indexed by tier label. Matches the 8-state
/// background template set shipped at `modular/icons/preview_templates/`.
GLOBAL_LIST_INIT(appearance_preview_canvas_icons, list(
	"32" = 'modular/icons/preview_templates/template.dmi',
	"64" = 'modular/icons/preview_templates/template_64x64.dmi',
	"96" = 'modular/icons/preview_templates/template_96x96.dmi',
))

/atom/movable/screen/map_view/char_preview
	name = "character preview"
	del_on_map_removal = FALSE
	/// The dummy whose appearance we project. Checked out from
	/// DUMMY_HUMAN_SLOT_PREFERENCES on create_body(), released on Destroy.
	var/mob/living/carbon/human/dummy/body
	/// Owning preferences datum. Non-null for the life of the view.
	/// Preview updates are driven by prefs mutations; COMSIG_PREFS_PREVIEW_UPDATED
	/// is emitted on this datum at the tail of every update_body().
	var/datum/preferences/preferences
	/// If TRUE, copy_to equips job clothes so the lobby preview reflects
	/// the selected role. FALSE for editor contexts that want the bare body.
	var/show_job_clothes = TRUE
	/// One of APPEARANCE_PREVIEW_FAMILY_* (null when the active tab owns
	/// no editor). Drives the strip pass inside update_body.
	var/active_editor_family = APPEARANCE_PREVIEW_FAMILY_NONE
	/// Opaque editor-defined target key for the currently edited part/entry.
	/// The view owns only routing metadata here; editor-specific strip helpers
	/// decide whether they can narrow the hide or must fall back to a family
	/// level strip. Null means "no target-specific hide requested".
	var/active_editor_target_key = null
	/// Backing image for the composited canvas. Allocated on first
	/// update_body; reused when possible to avoid churn.
	var/image/canvas
	/// Pixel-size tier of the current canvas ("32" | "64" | "96"). Tracked
	/// so we only reallocate canvas when the tier actually changes.
	var/last_canvas_size = null
	/// icon_state name currently applied to the canvas, tracked so we
	/// only hit `canvas.icon_state = ...` when the background pref
	/// changed (see Step 5 `update_background` handler).
	var/last_canvas_state = null

/atom/movable/screen/map_view/char_preview/Initialize(mapload, datum/preferences/owning_prefs)
	. = ..()
	preferences = owning_prefs
	// assigned_map is unique per view so multiple prefs windows (e.g.
	// admin-owned-on-behalf) cannot collide on the same BYOND map control id.
	assigned_map = "character_preview_[REF(src)]"
	name = "character preview ([REF(src)])"

/atom/movable/screen/map_view/char_preview/Destroy()
	if(body)
		// Strip the dummy and release the slot. We do NOT qdel(body) —
		// the slot pool owns that reference.
		unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
		body = null
	preferences = null
	active_editor_family = APPEARANCE_PREVIEW_FAMILY_NONE
	active_editor_target_key = null
	canvas = null
	last_canvas_size = null
	last_canvas_state = null
	return ..()

/**
 * Allocate the shared preferences dummy for the lifetime of this view.
 * Idempotent: returns early if a body is already checked out.
 *
 * The dummy lives in GLOB.human_dummy_list and is mutated in place by
 * `update_body()`; we never create a fresh mob per edit.
 */
/atom/movable/screen/map_view/char_preview/proc/create_body()
	if(body)
		return
	body = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	if(!body)
		stack_trace("char_preview/create_body: dummy slot unavailable")
		return
	// Reset any leftover state from a previous consumer before copy_to fills it in.
	body.wipe_state()

/**
 * Refresh the preview to reflect the current preferences state.
 *
 * Flow:
 *   1. Ensure a body is checked out.
 *   2. Wipe prior equipment/overlays so stale items don't leak between refreshes.
 *   3. `preferences.copy_to(body, ...)` equips the full character.
 *   4. Apply the active-editor strip pass (e.g. hide taur genitals when the
 *      taur-offsets tab is open so the editor overlay isn't doubled).
 *   5. Regenerate overlays and composite the body onto the background canvas.
 *   6. Reassign `src.appearance = canvas.appearance` — the client-side map
 *      control picks up the new visual with zero flattening.
 *   7. Emit `COMSIG_PREFS_PREVIEW_UPDATED` so lobby HUD observers refresh.
 *
 * No getFlatIcon, no icon2base64, no per-cardinal PNG. The entire cost is
 * one copy_to + one appearance assignment.
 */
/atom/movable/screen/map_view/char_preview/proc/update_body(skip_intimate_prefs = FALSE)
	if(QDELETED(preferences) || QDELETED(src))
		return
	if(!body)
		create_body()
	if(!body)
		return

	body.wipe_state()
	// Roguetown equivalent of tgstation's safe_transfer_prefs_to.
	// Args: (character, icon_updates = 1, roundstart_checks = TRUE,
	//        character_setup = FALSE, antagonist = FALSE, skip_normal_prefs = FALSE)
	// character_setup = TRUE skips mob-registration side effects that
	// only make sense when the dummy is about to be used as a real body.
	preferences.copy_to(body, icon_updates = 0, roundstart_checks = TRUE, character_setup = TRUE, skip_intimate_prefs = skip_intimate_prefs)

	_strip_for_active_family(body)

	if(show_job_clothes)
		body.regenerate_clothes()
	body.update_body()
	body.update_hair(rebuild_bodyparts = FALSE)
	body.update_body_parts(redraw = TRUE)
	body.rebuild_obscured_flags()
	COMPILE_OVERLAYS(body)

	_refresh_canvas()

	SEND_SIGNAL(preferences, COMSIG_PREFS_PREVIEW_UPDATED, src)

/**
 * Apply the strip predicate for the currently-open editor tab, so the
 * part under active edit is not also rendered by the backdrop.
 *
 * Mirrors the legacy `_strip_mannequin_for_preview` hooks, but the logic
 * is owned by the view (not the editor) so a single code path handles
 * tab switches without round-tripping through each editor datum.
 *
 * `active_editor_target_key` is intentionally opaque at this layer. The first
 * implementation keeps the existing coarse family hides because those are the
 * smallest safe hides exposed by the current render paths; later editor
 * descriptor steps can replace these helpers with target-aware suppression.
 */
/atom/movable/screen/map_view/char_preview/proc/_strip_for_active_family(mob/living/carbon/human/dummy/dummy)
	if(!dummy)
		return
	switch(active_editor_family)
		if(APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS)
			_strip_taur_offset_target(dummy)
		if(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS)
			_strip_custom_piercing_target(dummy)
		if(APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS)
			_strip_intimate_accessory_target(dummy)
		// APPEARANCE_PREVIEW_FAMILY_NONE (null): no-op.

/**
 * Hide the active taur offset target from the DM-rendered backdrop.
 *
 * Current taur render state only exposes a direction-wide global hide list
 * (`taur_genital_global_hide`). Until Step 10 resolves target-specific taur
 * descriptors/hide hooks, hiding the taur family is the smallest safe option:
 * it prevents the TGUI guide sprite from being visually doubled without
 * guessing which DM overlay state maps to `active_editor_target_key`.
 */
/atom/movable/screen/map_view/char_preview/proc/_strip_taur_offset_target(mob/living/carbon/human/dummy/dummy)
	dummy.taur_genital_global_hide = list("s" = 1, "n" = 1, "e" = 1, "w" = 1)

/**
 * Hide custom piercing render output from the backdrop while a selected
 * piercing entry is edited in TGUI.
 *
 * A valid `slot:index` target suppresses only that one entry through the
 * custom-piercing composer. Slot-only legacy targets still fall back to the
 * coarse family hide so old callers never show a doubled overlay.
 */
/atom/movable/screen/map_view/char_preview/proc/_strip_custom_piercing_target(mob/living/carbon/human/dummy/dummy)
	var/list/target = custom_piercing_parse_hybrid_target_key(active_editor_target_key)
	if(islist(target))
		dummy.custom_piercing_preview_suppressed_target_key = custom_piercing_hybrid_target_key(target["slot_key"], target["entry_index"])
		dummy.custom_piercing_post_render_suppressed = FALSE
		return

	dummy.custom_piercing_preview_suppressed_target_key = null
	dummy.custom_piercings = null
	dummy.custom_piercing_post_render_suppressed = TRUE

/**
 * Hide intimate accessory output from the backdrop while base accessory offsets
 * are edited.
 *
 * The Step 5 fallback skipped every intimate preference for this family because
 * no target-level hide was available yet. Step 18 narrows that: `copy_to()` now
 * equips the full set, then this pass clears only the active regular-accessory
 * target before the dummy regenerates bodypart overlays.
 */
/atom/movable/screen/map_view/char_preview/proc/_strip_intimate_accessory_target(mob/living/carbon/human/dummy/dummy)
	dummy.clear_intimate_accessory_offset_target(active_editor_target_key)

/**
 * Update the active editor family/target context and refresh the preview if it
 * changed. Called by tab switches and editor attach/refocus paths.
 *
 * Returns TRUE if context changed and a refresh was queued, FALSE if this was
 * a no-op.
 */
/atom/movable/screen/map_view/char_preview/proc/set_active_editor_context(family = APPEARANCE_PREVIEW_FAMILY_NONE, target_key = null)
	var/sanitized_family = APPEARANCE_PREVIEW_FAMILY_NONE
	if(!isnull(family))
		sanitized_family = hybrid_offset_sanitize_family(family)
		if(!sanitized_family)
			sanitized_family = APPEARANCE_PREVIEW_FAMILY_NONE
	var/sanitized_target = null
	if(sanitized_family != APPEARANCE_PREVIEW_FAMILY_NONE)
		sanitized_target = hybrid_offset_sanitize_target_key(target_key)
	if(active_editor_family == sanitized_family && active_editor_target_key == sanitized_target)
		return FALSE
	active_editor_family = sanitized_family
	active_editor_target_key = sanitized_target
	update_body()
	return TRUE

/**
 * Compatibility wrapper for callers that only know the family. Passing no
 * target explicitly clears target-specific hide metadata.
 */
/atom/movable/screen/map_view/char_preview/proc/set_active_editor_family(family)
	return set_active_editor_context(family, null)

/**
 * Pick a canvas size tier based on the dummy's body shape. Taur bodies
 * need a 96x96 backdrop so the rear half isn't clipped; everything else
 * uses the native 32x32 tile. The 64x64 tier exists for future oversized
 * non-taur cases (large wings, etc.) and is wired through but not
 * auto-selected in Phase 1a.
 */
/atom/movable/screen/map_view/char_preview/proc/_pick_canvas_size()
	if(body?.getorganslot(ORGAN_SLOT_TAUR_BODY))
		return "96"
	return "32"

/**
 * Composite the dummy body onto a size-appropriate background tile and
 * publish the result as this screen's appearance. Reuses the existing
 * `canvas` image when the tier and background haven't changed, so the
 * hot path (same species, slider nudge) is a single overlay swap plus
 * one appearance assignment.
 */
/atom/movable/screen/map_view/char_preview/proc/_refresh_canvas()
	var/size = _pick_canvas_size()
	var/state = preferences?.background_state || "midgrey"
	var/icon/canvas_icon = GLOB.appearance_preview_canvas_icons[size]

	// Render directly onto the screen obj's own appearance rather than
	// routing through an intermediate /image proxy. The old proxy pattern
	// (`appearance = image.appearance`) flattened the overlay tree one
	// level and silently dropped the body's own overlays (hair, clothes,
	// bodyparts, tails) — which is why the preview column only ever
	// showed the backdrop tile with a few stray greyscale shapes.
	icon = canvas_icon
	icon_state = state
	last_canvas_size = size
	last_canvas_state = state
	// Unconditional cut_overlays: the previous implementation left stale
	// body overlays on the canvas when only the icon_state changed,
	// letting successive background swaps accumulate phantom bodies.
	cut_overlays()
	if(body)
		// `body.appearance` preserves the full overlay subtree (species
		// skin, clothes, accessories) so adding it as an overlay on the
		// backdrop renders the complete mannequin in one pass.
		add_overlay(body.appearance)
	// Pinning in the centre of the TGUI map viewport so the backdrop
	// tile always reads as centred regardless of `client.view` size.
	// Without this the obj sat at map (1,1), which BYOND renders at the
	// top-left of the control when the client view is larger than one
	// tile (the lobby + editor panels both pass a new_player client
	// whose view is world.view, never a 1×1 override).
	if(assigned_map)
		screen_loc = "[assigned_map]:CENTER,CENTER"

/**
 * Override BYOND's setDir so turning the screen also turns the underlying
 * dummy and republishes the composited appearance. The lobby 3×3 HUD
 * takes advantage of this to face each holder a different cardinal while
 * sharing the same body — each holder just sets its own dir.
 */
/atom/movable/screen/map_view/char_preview/setDir(newdir)
	. = ..()
	if(!body)
		return
	body.setDir(newdir)
	body.update_body_parts(redraw = TRUE)
	COMPILE_OVERLAYS(body)
	_refresh_canvas()

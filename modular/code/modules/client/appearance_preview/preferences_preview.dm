/**
 * preferences_preview.dm — Phase 1b/1c helper layer bridging
 * /datum/preferences with the live `map_view` character preview view
 * introduced in Step 3 (`/atom/movable/screen/map_view/char_preview`).
 *
 * Scope of this file (Steps 4–5 of the Phase 1 plan):
 *   - Declare the prefs-owned vars that track the preview view, the
 *     currently selected tab, and the (at-most-one) active editor
 *     datum bound to a tab.
 *   - Provide lifecycle helpers: allocate/destroy the view, switch
 *     tabs, bind/unbind an editor, reset on slot switch.
 *   - Hook `/datum/preferences/Destroy` and `load_character` so the
 *     view and tab state cannot outlive the prefs datum or leak across
 *     slot switches.
 *
 * This file does NOT wire a TGUI `ui_interact` onto /datum/preferences
 * — the roguetown preferences menu is still the classic HTML `Topic()`
 * surface. Consumers of the view are the TGUI editors (taur, piercing,
 * future tabbed PreferencesMenu) which request it via
 * `create_character_preview_view(user)` inside their own `ui_interact`
 * / `ui_static_data` / `ui_assets` hooks. The wiring of those hooks
 * lands in Steps 7–10.
 *
 * Contract (addendum D.1 + D.2 + F.1):
 *   - Single-owner preview: the prefs datum owns the view for its
 *     lifetime. Editors observe / request refreshes but do not own it.
 *   - Singleton `active_editor`: at most one editor attached to a tab
 *     at a time. Attach/detach is routed through
 *     `set_active_editor(editor, family, target_key)`.
 *   - Slot switch resets `active_tab` to APPEARANCE_PREVIEW_TAB_INFO,
 *     detaches the active editor without committing, and clears the
 *     preview family so the next open renders a clean dummy.
 */

/datum/preferences
	/// Live preview datum. Lazily allocated on first
	/// `create_character_preview_view()` call by whichever TGUI surface
	/// opens first. Survives tab switches; torn down on prefs Destroy.
	var/atom/movable/screen/map_view/char_preview/character_preview_view
	/// Current tab id (one of APPEARANCE_PREVIEW_TAB_*). Drives the
	/// tab chrome on the eventual TGUI prefs menu and the view's strip
	/// pass via GLOB.appearance_preview_tab_to_family.
	var/active_tab = APPEARANCE_PREVIEW_TAB_INFO
	/// Singleton editor datum bound to the currently open editor tab
	/// (taur offsets, custom piercings). Null when no editor tab is
	/// selected. Attached/detached via `set_active_editor`.
	var/datum/active_editor

/**
 * Lazily create (and return) the character_preview_view owned by this
 * prefs datum. Safe to call repeatedly — subsequent calls return the
 * existing view without re-allocating the body dummy.
 *
 * Arguments:
 *   user — the mob whose client should be registered as a viewer of
 *          the BYOND map control. Typically the prefs owner, but admin
 *          "edit on behalf" flows may pass a different mob.
 *
 * Returns the view datum (non-null on success, null if the prefs
 * datum is mid-destruction).
 */
/datum/preferences/proc/create_character_preview_view(mob/user)
	if(QDELETED(src))
		return null
	if(!character_preview_view)
		character_preview_view = new /atom/movable/screen/map_view/char_preview(null, src)
		character_preview_view.create_body()
		// Apply the current tab's strip pass (no-op when active_tab is
		// a null-family tab) so the first appearance push already matches
		// the tab the UI is about to display.
		var/family = GLOB.appearance_preview_tab_to_family[active_tab]
		character_preview_view.active_editor_family = family
		character_preview_view.active_editor_target_key = null
		character_preview_view.update_body()
	if(user)
		character_preview_view.display_to(user)
	return character_preview_view

/**
 * Tear down the preview view. Called from `/datum/preferences/Destroy`
 * and (optionally) from the tabbed prefs menu's `ui_close` once that
 * lands in Step 8. Idempotent.
 */
/datum/preferences/proc/destroy_character_preview_view()
	if(!character_preview_view)
		return
	QDEL_NULL(character_preview_view)

/**
 * Switch tabs. Returns TRUE if the tab changed (or the request was a
 * valid no-op on the current tab), FALSE on invalid input.
 *
 * Behaviour:
 *   - Validates `tab` against GLOB.appearance_preview_valid_tabs.
 *   - If tab unchanged: no-op, returns TRUE.
 *   - Otherwise: detaches any active editor via `set_active_editor(null)`
 *     (which in turn calls the editor's `_on_tab_exit()` hook once
 *     Steps 9/10 add it), updates `active_tab`, and pushes the new
 *     family/empty target context to the view so the strip pass reflects
 *     the new tab.
 *
 * The ui_act handler in Step 5 is the canonical caller; direct callers
 * (tests, admin verbs) are fine as long as they pass a valid tab id.
 */
/datum/preferences/proc/set_active_tab(tab)
	if(!(tab in GLOB.appearance_preview_valid_tabs))
		return FALSE
	if(active_tab == tab)
		return TRUE
	// Clear any attached editor before we change tab so the editor's
	// tab-exit hook sees the old tab in `active_tab` and can decide
	// whether to commit/discard its draft.
	if(active_editor)
		set_active_editor(null, refresh_preview = FALSE)
	active_tab = tab
	var/family = GLOB.appearance_preview_tab_to_family[tab]
	character_preview_view?.set_active_editor_context(family, null)
	return TRUE

/**
 * Attach or detach the editor datum bound to the current tab.
 *
 * Arguments:
 *   editor — the editor datum (e.g. /datum/taur_genital_offset_editor)
 *            or null to detach.
 *   family — APPEARANCE_PREVIEW_FAMILY_* for the editor (ignored when
 *            editor is null).
 *   target_key — opaque editor-defined target id for the active part/entry.
 *            The preview view stores this only as routing metadata; each
 *            family-specific strip helper decides whether it can narrow the
 *            hide or must use a coarse fallback.
 *   refresh_preview — when detaching, controls whether clearing the target
 *            should immediately refresh. Tab switches pass FALSE to avoid a
 *            redundant old-tab rebuild before they apply the new family.
 *
 * When detaching, if the editor defines `_on_tab_exit()`, that hook is
 * invoked so the editor can commit / discard / flush any pending draft
 * state before the reference is dropped. The hook is optional —
 * editors without draft state (future read-only editors) need no
 * implementation.
 *
 * Singleton contract: at most one editor at a time. Attaching while
 * another editor is bound stacks an implicit detach of the previous
 * one. This mirrors the "save or discard?" modal flow in the TSX —
 * the client side is expected to have already resolved the modal
 * before sending the attach topic.
 */
/datum/preferences/proc/set_active_editor(datum/editor, family = APPEARANCE_PREVIEW_FAMILY_NONE, target_key = null, refresh_preview = TRUE)
	if(active_editor && active_editor != editor)
		if(hascall(active_editor, "_on_tab_exit"))
			call(active_editor, "_on_tab_exit")()
		active_editor = null
	if(!editor)
		// Pure detach. Keep the tab's family active, but clear target metadata
		// so a future targeted strip cannot leak across editor instances.
		if(refresh_preview)
			var/tab_family = GLOB.appearance_preview_tab_to_family[active_tab]
			character_preview_view?.set_active_editor_context(tab_family, null)
		else if(character_preview_view)
			character_preview_view.active_editor_target_key = null
		return TRUE
	active_editor = editor
	character_preview_view?.set_active_editor_context(family, target_key)
	return TRUE

/**
 * Reset preview-adjacent state to safe defaults on a character slot
 * switch. Called from `load_character(slot)` after the new slot has
 * been loaded, so the preview rebuild sees the new character data.
 *
 * Per addendum F.1, a slot switch unconditionally:
 *   - Returns to the Info tab (safe default — no editor draft can
 *     carry across slots).
 *   - Detaches any active editor WITHOUT invoking its `_on_tab_exit`
 *     hook (the old slot's draft is meaningless against the new slot).
 *   - Clears the preview's active_editor_family so nothing is stripped.
 *   - Refreshes the view so the new character appears.
 */
/datum/preferences/proc/change_slot_reset_preview()
	active_tab = APPEARANCE_PREVIEW_TAB_INFO
	active_editor = null
	if(character_preview_view)
		character_preview_view.active_editor_family = APPEARANCE_PREVIEW_FAMILY_NONE
		character_preview_view.active_editor_target_key = null
		character_preview_view.update_body()

/**
 * Convenience: refresh the preview without changing tabs or editors.
 * Called by the set-pref dispatcher when a registered setter declares
 * `invalidates_preview`, and by targeted editor/save flows that need an
 * immediate authoritative rebuild. No-op when the view has not been
 * allocated yet (cold path — nothing is looking at a preview anyway).
 */
/datum/preferences/proc/render_new_preview_appearance()
	character_preview_view?.update_body()

/**
 * Server-owned hybrid offset descriptor entrypoint.
 *
 * This is deliberately editor-agnostic. Step 4 only creates the validated
 * descriptor shell that future taur/custom-piercing/intimate-accessory
 * resolvers will fill with manifest categories and resolved guide layers.
 *
 * Arguments:
 *   editor_family - one of GLOB.hybrid_offset_known_families.
 *   target_key - server/editor-defined opaque id for the active edit target.
 *   dir_key - one of APPEARANCE_PREVIEW_DIR_KEY_* or a BYOND cardinal dir.
 *
 * Returns a sanitized descriptor list, or null when the request is malformed.
 */
/datum/preferences/proc/build_hybrid_offset_descriptor(editor_family, target_key, dir_key)
	if(editor_family == APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS)
		return build_taur_hybrid_offset_descriptor(target_key, dir_key)
	if(editor_family == APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS)
		return build_custom_piercing_hybrid_offset_descriptor(target_key, dir_key)
	if(editor_family == APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS)
		return build_intimate_accessory_hybrid_offset_descriptor(target_key, dir_key)
	return hybrid_offset_build_descriptor(editor_family, target_key, dir_key)

/**
 * Validates a hybrid offset family id against the narrow editor family list.
 */
/proc/hybrid_offset_sanitize_family(editor_family)
	if(!istext(editor_family) || !length(editor_family))
		return null
	if(!(editor_family in GLOB.hybrid_offset_known_families))
		return null
	return editor_family

/**
 * Validates the opaque active target key used by descriptor builders.
 */
/proc/hybrid_offset_sanitize_target_key(target_key)
	if(!istext(target_key) || !length(target_key))
		return null
	if(length(target_key) > HYBRID_OFFSET_TARGET_KEY_MAX_LENGTH)
		return null
	return target_key

/**
 * Validates/normalizes the direction key. Accepts the string keys used by
 * TGUI and cardinal BYOND dirs used by server render helpers.
 */
/proc/hybrid_offset_sanitize_direction_key(dir_key)
	if(isnum(dir_key))
		dir_key = appearance_preview_dir_to_key(dir_key)
	if(!(dir_key in GLOB.appearance_preview_dir_keys))
		return null
	return dir_key

/**
 * Validates an optional appearance-preview manifest category.
 *
 * Descriptor shells are allowed to carry null until an editor-specific
 * resolver supplies real layers. Once layers exist, callers should provide a
 * category so the TGUI renderer can resolve sheet metadata deterministically.
 */
/proc/hybrid_offset_sanitize_manifest_category(manifest_category)
	if(isnull(manifest_category))
		return null
	if(!istext(manifest_category) || !length(manifest_category))
		return null
	if(!(manifest_category in GLOB.appearance_preview_manifest_category_order))
		return null
	return manifest_category

/**
 * Returns a sanitized allowed-field list. Empty input means "all supported
 * fields"; malformed entries are dropped.
 */
/proc/hybrid_offset_sanitize_allowed_fields(list/allowed_fields)
	if(!islist(allowed_fields) || !length(allowed_fields))
		return GLOB.hybrid_offset_allowed_field_keys.Copy()
	var/list/out = list()
	for(var/field in allowed_fields)
		if(!(field in GLOB.hybrid_offset_allowed_field_keys))
			continue
		if(field in out)
			continue
		out += field
	if(!length(out))
		return GLOB.hybrid_offset_allowed_field_keys.Copy()
	return out

/**
 * Sanitizes one descriptor layer. The icon_state must already be resolved by
 * DM; this helper only normalizes the key and copies optional presentation
 * metadata that TGUI may use for guide tinting.
 */
/proc/hybrid_offset_sanitize_layer(list/layer)
	if(!islist(layer))
		return null
	var/icon_state = appearance_preview_manifest_icon_state_key(layer[HYBRID_OFFSET_LAYER_KEY_ICON_STATE])
	if(!icon_state)
		return null
	var/role = layer[HYBRID_OFFSET_LAYER_KEY_ROLE]
	if(!(role in GLOB.hybrid_offset_layer_roles))
		role = HYBRID_OFFSET_LAYER_ROLE_GUIDE
	var/list/out = list(
		HYBRID_OFFSET_LAYER_KEY_ICON_STATE = icon_state,
		HYBRID_OFFSET_LAYER_KEY_ROLE = role,
	)
	var/color = layer[HYBRID_OFFSET_LAYER_KEY_COLOR]
	if(istext(color) && length(color))
		out[HYBRID_OFFSET_LAYER_KEY_COLOR] = color
	else if(islist(color))
		var/list/colors = list()
		for(var/item in color)
			if(istext(item) && length(item))
				colors += item
		if(length(colors))
			out[HYBRID_OFFSET_LAYER_KEY_COLOR] = colors
	return out

/**
 * Generic hybrid offset descriptor builder.
 *
 * Future editor-specific resolvers should call this after resolving manifest
 * categories and icon states through DM. Passing no category/layers returns a
 * valid descriptor shell that TGUI can safely treat as "map backdrop only".
 */
/proc/hybrid_offset_build_descriptor(editor_family, target_key, dir_key, manifest_category = null, list/layers = null, list/allowed_fields = null, native_width = HYBRID_OFFSET_DEFAULT_NATIVE_SIZE, native_height = HYBRID_OFFSET_DEFAULT_NATIVE_SIZE, approximate_color = FALSE)
	var/family = hybrid_offset_sanitize_family(editor_family)
	if(!family)
		return null
	var/sanitized_target = hybrid_offset_sanitize_target_key(target_key)
	if(!sanitized_target)
		return null
	var/sanitized_dir = hybrid_offset_sanitize_direction_key(dir_key)
	if(!sanitized_dir)
		return null
	var/sanitized_category = hybrid_offset_sanitize_manifest_category(manifest_category)

	var/list/sanitized_layers = list()
	if(islist(layers))
		for(var/list/layer as anything in layers)
			var/list/sanitized_layer = hybrid_offset_sanitize_layer(layer)
			if(sanitized_layer)
				sanitized_layers += list(sanitized_layer)
	if(length(sanitized_layers) && !sanitized_category)
		return null

	var/sanitized_width = isnum(native_width) ? round(native_width) : HYBRID_OFFSET_DEFAULT_NATIVE_SIZE
	var/sanitized_height = isnum(native_height) ? round(native_height) : HYBRID_OFFSET_DEFAULT_NATIVE_SIZE
	sanitized_width = max(1, min(sanitized_width, 256))
	sanitized_height = max(1, min(sanitized_height, 256))

	return list(
		HYBRID_OFFSET_DESCRIPTOR_KEY_ID = "[family]:[sanitized_target]:[sanitized_dir]",
		HYBRID_OFFSET_DESCRIPTOR_KEY_FAMILY = family,
		HYBRID_OFFSET_DESCRIPTOR_KEY_TARGET_KEY = sanitized_target,
		HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY = sanitized_category,
		HYBRID_OFFSET_DESCRIPTOR_KEY_DIRECTION = sanitized_dir,
		HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS = sanitized_layers,
		HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_WIDTH = sanitized_width,
		HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_HEIGHT = sanitized_height,
		HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS = hybrid_offset_sanitize_allowed_fields(allowed_fields),
		HYBRID_OFFSET_DESCRIPTOR_KEY_APPROXIMATE_COLOR = approximate_color ? TRUE : FALSE,
	)

/**
 * Prefs datum teardown. The parent New() is unchanged; we only hook
 * Destroy to guarantee the view cannot outlive the prefs datum that
 * owns it. Other fields on /datum/preferences are cleared by the base
 * class / the GC as normal.
 */
/datum/preferences/Destroy()
	destroy_character_preview_view()
	active_editor = null
	return ..()

// -----------------------------------------------------------------------------
// Step 5 — action handlers.
//
// Roguetown's main preferences menu is still the classic HTML Topic() surface,
// so there is no `/datum/preferences/ui_act` to extend. Instead, Step 5 lands
// these as plain helper procs that the eventual TGUI consumers (Steps 8–10)
// forward into from their own `ui_act` switches:
//
//     case("set_active_tab"):
//         prefs.act_set_active_tab(params["tab"])
//     case("rotate"):
//         prefs.act_rotate(params["backwards"])
//     case("update_background"):
//         prefs.act_update_background(params["state"])
//
// The dirty-modal save/discard/cancel flow lives client-side (Step 8); by the
// time a `set_active_tab` reaches here, the client has already resolved the
// user's choice. Server-side dirty tracking is intentionally NOT introduced —
// the existing commit envelopes (Phase 12) already validate draft payloads.
// -----------------------------------------------------------------------------

/// Canonical direction rotation order for the preview view. SOUTH faces
/// the camera by default; rotating "forwards" walks clockwise (S→W→N→E→S),
/// matching the legacy lobby HUD expectation for arrow-button UX.
GLOBAL_LIST_INIT(appearance_preview_rotation_cw, list(SOUTH, WEST, NORTH, EAST))

/**
 * Tab-switch action handler. Thin wrapper over `set_active_tab` that
 * also triggers a body refresh even on a within-family tab change so the
 * tab-body-specific view state (e.g. features tab showing the full body
 * vs. info tab hiding the job clothes hat when the preference changes)
 * stays in sync.
 *
 * Returns TRUE on accepted transitions (including within-tab no-ops),
 * FALSE when `tab` is rejected by validation.
 */
/datum/preferences/proc/act_set_active_tab(tab)
	if(!set_active_tab(tab))
		return FALSE
	// set_active_tab only refreshes when the family changes. If we stayed
	// inside the same family (e.g. info → features, both null-family) the
	// dummy state is identical and no refresh is needed. The refresh path
	// is retained for parity with the tgstation/Bubber handler; call sites
	// that want a guaranteed refresh should call render_new_preview_appearance.
	return TRUE

/**
 * Rotate the preview dummy one quarter-turn.
 *
 * Arguments:
 *   backwards — truthy value rotates counter-clockwise (S→E→N→W→S);
 *               falsy rotates clockwise (S→W→N→E→S).
 *
 * No-op if the view has not been allocated yet (no open TGUI surface).
 * Returns the new direction on success, null otherwise.
 */
/datum/preferences/proc/act_rotate(backwards = FALSE)
	if(!character_preview_view)
		return null
	var/list/order = GLOB.appearance_preview_rotation_cw
	var/current = character_preview_view.dir
	var/idx = order.Find(current)
	if(idx <= 0)
		// Unknown dir (diagonals, 0, etc.). Normalise to SOUTH so the
		// next rotate from here is predictable.
		idx = 1
	var/step = backwards ? -1 : 1
	var/new_idx = idx + step
	if(new_idx < 1)
		new_idx = order.len
	else if(new_idx > order.len)
		new_idx = 1
	var/new_dir = order[new_idx]
	character_preview_view.setDir(new_dir)
	return new_dir

/**
 * Background-state action handler. Validates against
 * GLOB.appearance_preview_background_states, writes the client-scoped
 * pref, persists via save_preferences, and triggers a refresh so the
 * canvas icon_state swap takes effect.
 *
 * Returns TRUE on accepted change, FALSE on invalid state or when no
 * change was needed.
 */
/datum/preferences/proc/act_update_background(state)
	if(!(state in GLOB.appearance_preview_background_states))
		return FALSE
	if(background_state == state)
		return FALSE
	background_state = state
	// Persist immediately so the chrome choice survives reconnect even if
	// the player never mutates a character pref this session.
	save_preferences()
	character_preview_view?.update_body()
	return TRUE

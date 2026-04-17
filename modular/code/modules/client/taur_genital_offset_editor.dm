/**
 * # Taur Genital Offset Editor (TGUI)
 *
 * A lobby-specific TGUI panel for fine-tuning per-direction taur genital sprite
 * properties (offset, rotation, flip, scale, hide, layer override). Opened from
 * the character preferences sheet's "Edit…" link next to each taur genital part.
 *
 * Props are stored on /datum/preferences as `taur_<part>_props` lists keyed by
 * cardinal direction (see default_taur_genital_props for the full schema).
 *
 * Live preview: the editor re-renders the preferences mannequin on every edit
 * and sends the resulting icon as a base64 PNG so the TGUI frontend can show
 * the current direction with all edits applied without a round-trip to the
 * classic character preview window.
 */
/// Time dilation (% reported by SStime_track.time_dilation_avg_fast) at or
/// above which mouse-drag sprite manipulation is force-disabled on the client.
/// Dragging hammers Topic() with many small deltas per second, so when the
/// server is already struggling we want players to fall back to the numeric
/// inputs, which only emit one Topic() per edit.
#define TAUR_EDITOR_DRAG_DISABLE_TIME_DILATION 40

/// Clamp bounds for taur-genital x/y pixel offsets. Wider than the native
/// 32px tile so players can push parts well past the body edge (preview
/// renders into a 96x96 canvas to accommodate). Consumed by both the editor's
/// `_apply_field` and `sanitize_taur_genital_props` in the modular genitals
/// sprite_accessory file (which is included after this file in the DME, so
/// defines live here rather than there).
#define TAUR_GENITAL_OFFSET_MAX 64
#define TAUR_GENITAL_OFFSET_MIN -64

/// Rate-limit for ui_act() calls per client. Drag throttled at ~80ms on the
/// frontend should only ever send ~12/sec; this gives generous headroom for
/// legit bursts (part switch + a few inputs) before we call it abuse.
#define TAUR_EDITOR_MAX_ACTS_PER_SECOND 25
/// Rolling window (in deciseconds) used to count recent ui_act() calls.
#define TAUR_EDITOR_RATE_WINDOW_DS 10
/// Cooldown (in deciseconds) between admin notifications for the same abuser,
/// so a flood doesn't spam the admin channel.
#define TAUR_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS 300
/// Singleton guard: at most one taur genital editor per client. Repeat opens
/// focus/refresh the existing window instead of spawning duplicates.
/client/var/datum/taur_genital_offset_editor/taur_genital_editor_instance

/datum/preferences/proc/open_taur_genital_editor(mob/user, part = "penis")
	if(!user || !(part in GLOB.taur_genital_part_keys))
		return
	var/client/opening_client = user.client
	if(opening_client?.taur_genital_editor_instance)
		var/datum/taur_genital_offset_editor/existing = opening_client.taur_genital_editor_instance
		if(QDELETED(existing))
			opening_client.taur_genital_editor_instance = null
		else
			// Refocus the existing window on the requested part instead of spawning a second one.
			existing.active_part = part
			existing.ui_interact(user)
			return
	var/datum/taur_genital_offset_editor/editor = new(src, part)
	if(opening_client)
		opening_client.taur_genital_editor_instance = editor
		editor.owning_client = opening_client
	editor.ui_interact(user)

/datum/taur_genital_offset_editor
	/// The preferences datum we're editing.
	var/datum/preferences/prefs
	/// Which part is currently selected in the editor ("penis" / "testicles" / "vagina").
	var/active_part = "penis"
	/// Which direction tab is currently selected ("s" / "n" / "e" / "w").
	var/active_dir = "s"
	/// Shared Topic() flood limiter. Replaces the old per-editor state fields.
	var/datum/ui_act_rate_limiter/rate_limiter
	/// Client that opened this editor; used to clear the singleton slot on close.
	var/client/owning_client

/datum/taur_genital_offset_editor/New(datum/preferences/P, part = "penis")
	if(!P)
		qdel(src)
		return
	prefs = P
	if(part in GLOB.taur_genital_part_keys)
		active_part = part
	rate_limiter = new(
		"Taur genital editor",
		TAUR_EDITOR_MAX_ACTS_PER_SECOND,
		TAUR_EDITOR_RATE_WINDOW_DS,
		TAUR_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS,
	)

/datum/taur_genital_offset_editor/Destroy()
	if(owning_client?.taur_genital_editor_instance == src)
		owning_client.taur_genital_editor_instance = null
	owning_client = null
	prefs = null
	QDEL_NULL(rate_limiter)
	return ..()

/datum/taur_genital_offset_editor/ui_close(mob/user)
	qdel(src)

/datum/taur_genital_offset_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TaurGenitalOffsetEditor", "Taur Genital Offsets", 560, 640)
		ui.open()

/datum/taur_genital_offset_editor/ui_state(mob/user)
	return GLOB.always_state

/// Returns the props list for a given part, sanitizing (and writing back) in place
/// so defaults are always present for any new fields added to the schema.
/datum/taur_genital_offset_editor/proc/_get_props(part)
	if(!prefs)
		return null
	switch(part)
		if("penis")
			prefs.taur_penis_props = sanitize_taur_genital_props(prefs.taur_penis_props, "penis")
			return prefs.taur_penis_props
		if("testicles")
			prefs.taur_testicles_props = sanitize_taur_genital_props(prefs.taur_testicles_props, "testicles")
			return prefs.taur_testicles_props
		if("vagina")
			prefs.taur_vagina_props = sanitize_taur_genital_props(prefs.taur_vagina_props, "vagina")
			return prefs.taur_vagina_props
	return null

/// Grabs the pre-rendered per-direction mannequin appearance from the prefs client
/// preview overlays and returns a base64 PNG. Returns null if the preview isn't ready.
///
/// Also populates `part_b64_out` with a part-only, untransformed render of the
/// currently-active part (for the ghost-drag overlay and for the main preview's
/// transform layer). The mannequin's own copy of the active part at the active
/// direction is force-hidden so the frontend can overlay its transformed copy
/// cleanly without a duplicate, untransformed sprite leaking through.
/datum/taur_genital_offset_editor/proc/_get_preview_base64(dir_key, list/part_b64_out)
	if(!prefs?.parent)
		return null
	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	if(!mannequin)
		return null
	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	var/obj/item/organ/penis/preview_penis = mannequin.getorganslot(ORGAN_SLOT_PENIS)
	if(preview_penis)
		preview_penis.erect_state = prefs.preview_erect_state

	// Hide the active part at the active direction on the MANNEQUIN copy only
	// (not on prefs). The frontend renders a separate transformed overlay for
	// this part, and we don't want the mannequin's own non-transformed copy
	// showing through underneath.
	var/hide_key = "[dir_key]hide"
	switch(active_part)
		if("penis")
			if(islist(mannequin.taur_penis_props))
				mannequin.taur_penis_props[hide_key] = 1
		if("testicles")
			if(islist(mannequin.taur_testicles_props))
				mannequin.taur_testicles_props[hide_key] = 1
		if("vagina")
			if(islist(mannequin.taur_vagina_props))
				mannequin.taur_vagina_props[hide_key] = 1

	mannequin.regenerate_clothes()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(redraw = TRUE)
	mannequin.rebuild_obscured_flags()
	var/target_dir = SOUTH
	switch(dir_key)
		if("n")
			target_dir = NORTH
		if("e")
			target_dir = EAST
		if("w")
			target_dir = WEST
	mannequin.setDir(target_dir)
	mannequin.update_body_parts(redraw = TRUE)
	COMPILE_OVERLAYS(mannequin)
	var/icon/flat = getFlatIcon(mannequin, defdir = target_dir, no_anim = TRUE)
	// Pad the 32x32 mannequin render into a 96x96 canvas, centering the
	// original content at (33..64, 33..64). BYOND's `icon.Crop(x1,y1,x2,y2)`
	// accepts negative origins and fills the outside area with transparent
	// pixels, so this gives us a 96-pixel canvas matching the frontend's
	// PREVIEW_SPRITE_PX without needing a new DMI blank. This lets players
	// push parts well past the body edge (up to ±64) without clipping.
	if(flat)
		flat.Crop(-31, -31, 64, 64)

	// Build the part-only preview before releasing the mannequin — it depends
	// on the mannequin's organs + accessory colors.
	if(islist(part_b64_out))
		part_b64_out["b64"] = _build_part_preview(mannequin, active_part, target_dir)

	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	if(!flat)
		return null
	return icon2base64(flat)

/// Renders a colored, 32x32 (base), transform-free icon of just one taur genital
/// part for one cardinal direction. Returns a base64 PNG or null.
///
/// The returned sprite intentionally has NO pixel offsets, NO rotation, and NO
/// flip/scale baked in — the frontend applies those via CSS transforms so the
/// preview updates instantly on each edit (BYOND's `getFlatIcon` does not honor
/// `mutable_appearance.transform`, which is why the mannequin render alone
/// cannot reflect flip/turn/shrink changes).
/datum/taur_genital_offset_editor/proc/_build_part_preview(mob/living/carbon/human/mannequin, part, target_dir)
	if(!mannequin)
		return null
	var/slot
	var/taur_icon_file
	switch(part)
		if("penis")
			slot = ORGAN_SLOT_PENIS
			taur_icon_file = file("modular/icons/obj/lewd/taur_pintle.dmi")
		if("testicles")
			slot = ORGAN_SLOT_TESTICLES
			taur_icon_file = file("modular/icons/obj/lewd/taur_gonads.dmi")
		if("vagina")
			slot = ORGAN_SLOT_VAGINA
			taur_icon_file = file("modular/icons/obj/lewd/taur_nethers.dmi")
		else
			return null
	var/obj/item/organ/organ = mannequin.getorganslot(slot)
	if(!organ)
		return null
	var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(organ.accessory_type)
	if(!accessory)
		return null
	var/obj/item/bodypart/bodypart = mannequin.get_bodypart(BODY_ZONE_CHEST)
	var/icon_state_to_use = accessory.get_icon_state(organ, bodypart, mannequin)
	if(!icon_state_to_use)
		return null
	var/list/appearance_list = generate_taur_genital_overlay(accessory, taur_icon_file, icon_state_to_use, organ.accessory_colors)
	if(!length(appearance_list))
		return null
	// Build a 96x96 transparent canvas by padding a 32x32 blank. The overlay
	// sub-icons are 32x32 and must be shifted +32 on both axes so they land
	// in the centered region (rows/cols 33..64) matching the mannequin's
	// padded render. See `_get_preview_base64` for the matching Crop call.
	var/icon/flat = icon('icons/blanks/32x32.dmi', "nothing")
	flat.Crop(-31, -31, 64, 64)
	for(var/mutable_appearance/MA as anything in appearance_list)
		if(!MA?.icon || !MA.icon_state)
			continue
		var/icon/sub = icon(MA.icon, MA.icon_state, target_dir)
		if(!sub)
			continue
		// +32 pixel_x/pixel_y shift re-centers the sub-icon into the padded
		// canvas. `Blend(... x=, y=)` takes 1-indexed pixel coords on the
		// destination icon, so +32 moves (1,1) → (33,33).
		flat.Blend(sub, ICON_OVERLAY, 33, 33)
	return icon2base64(flat)

/datum/taur_genital_offset_editor/ui_data(mob/user)
	var/list/data = list()
	data["active_part"] = active_part
	data["active_dir"] = active_dir
	data["part_keys"] = GLOB.taur_genital_part_keys
	data["dir_keys"] = GLOB.taur_genital_dir_keys
	data["field_keys"] = GLOB.taur_genital_field_keys

	// Full props for each part so the frontend can switch tabs without a server round-trip.
	var/list/all_props = list()
	for(var/part in GLOB.taur_genital_part_keys)
		all_props[part] = _get_props(part)
	data["props"] = all_props

	// Global per-direction hide toggles.
	if(prefs)
		prefs.taur_genital_global_hide = sanitize_taur_genital_global_hide(prefs.taur_genital_global_hide)
		data["global_hide"] = prefs.taur_genital_global_hide

	// Base64 preview of the mannequin facing the active direction, with all edits applied.
	// `part_bucket["b64"]` is populated as a side-effect by _get_preview_base64 and
	// carries the transform-free, part-only render for the frontend overlay + ghost.
	var/list/part_bucket = list()
	data["preview_b64"] = _get_preview_base64(active_dir, part_bucket)
	data["part_preview_b64"] = part_bucket["b64"]

	// Report live time dilation so the frontend can hard-disable drag when the
	// server is lagging. Drag sends many Topic() calls per second; numeric
	// inputs send one per edit, so under lag we force the lighter path.
	var/time_dilation = 0
	if(SStime_track)
		time_dilation = SStime_track.time_dilation_avg_fast
	data["time_dilation"] = time_dilation
	data["drag_disable_threshold"] = TAUR_EDITOR_DRAG_DISABLE_TIME_DILATION
	data["drag_disabled"] = (time_dilation >= TAUR_EDITOR_DRAG_DISABLE_TIME_DILATION)
	return data

/datum/taur_genital_offset_editor/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!prefs)
		return FALSE
	if(rate_limiter?.check_blocked(usr))
		return FALSE

	switch(action)
		if("select_part")
			var/part = params["part"]
			if(part in GLOB.taur_genital_part_keys)
				active_part = part
				return TRUE

		if("select_dir")
			var/dir_key = params["dir"]
			if(dir_key in GLOB.taur_genital_dir_keys)
				active_dir = dir_key
				return TRUE

		if("set_field")
			// Absolute-value setter used by number inputs.
			// params: part, dir, field, value
			var/part = params["part"]
			var/dir_key = params["dir"]
			var/field = params["field"]
			if(!(part in GLOB.taur_genital_part_keys))
				return FALSE
			if(!(dir_key in GLOB.taur_genital_dir_keys))
				return FALSE
			if(!(field in GLOB.taur_genital_field_keys))
				return FALSE
			var/list/props = _get_props(part)
			if(!props)
				return FALSE
			var/key = "[dir_key][field]"
			var/value = params["value"]
			_apply_field(props, key, field, value)
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

		if("nudge_field")
			// Relative-value adjust used by button steppers and drag handlers.
			// params: part, dir, field, delta
			var/part = params["part"]
			var/dir_key = params["dir"]
			var/field = params["field"]
			if(!(part in GLOB.taur_genital_part_keys))
				return FALSE
			if(!(dir_key in GLOB.taur_genital_dir_keys))
				return FALSE
			if(!(field in GLOB.taur_genital_field_keys))
				return FALSE
			var/list/props = _get_props(part)
			if(!props)
				return FALSE
			var/key = "[dir_key][field]"
			var/delta = text2num_safe(params["delta"], 0)
			var/cur = text2num_safe(props[key], 0)
			_apply_field(props, key, field, cur + delta)
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

		if("toggle_field")
			// Flip a boolean field (flip / above / hide).
			// params: part, dir, field
			var/part = params["part"]
			var/dir_key = params["dir"]
			var/field = params["field"]
			if(!(part in GLOB.taur_genital_part_keys))
				return FALSE
			if(!(dir_key in GLOB.taur_genital_dir_keys))
				return FALSE
			if(!(field in list("flip", "above", "hide")))
				return FALSE
			var/list/props = _get_props(part)
			if(!props)
				return FALSE
			var/key = "[dir_key][field]"
			props[key] = props[key] ? 0 : 1
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

		if("reset_dir")
			// Reset one direction of one part to defaults.
			var/part = params["part"]
			var/dir_key = params["dir"]
			if(!(part in GLOB.taur_genital_part_keys))
				return FALSE
			if(!(dir_key in GLOB.taur_genital_dir_keys))
				return FALSE
			var/list/props = _get_props(part)
			if(!props)
				return FALSE
			var/list/defaults = default_taur_genital_props(part)
			for(var/field in GLOB.taur_genital_field_keys)
				var/key = "[dir_key][field]"
				props[key] = defaults[key]
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

		if("reset_part")
			// Reset all four directions of one part to defaults.
			var/part = params["part"]
			if(!(part in GLOB.taur_genital_part_keys))
				return FALSE
			switch(part)
				if("penis")
					prefs.taur_penis_props = default_taur_genital_props("penis")
				if("testicles")
					prefs.taur_testicles_props = default_taur_genital_props("testicles")
				if("vagina")
					prefs.taur_vagina_props = default_taur_genital_props("vagina")
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

		if("toggle_global_hide")
			var/dir_key = params["dir"]
			if(!(dir_key in GLOB.taur_genital_dir_keys))
				return FALSE
			prefs.taur_genital_global_hide = sanitize_taur_genital_global_hide(prefs.taur_genital_global_hide)
			prefs.taur_genital_global_hide[dir_key] = prefs.taur_genital_global_hide[dir_key] ? 0 : 1
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

		if("commit_drag")
			// Called once on mouseup at the end of a ghost-drag. Applies any
			// subset of {x, y, turn, shrink} absolute values and regens the
			// mannequin preview exactly ONCE, instead of per-mousemove during
			// the drag. Dramatically cuts Topic()+getFlatIcon() load vs. the
			// old drag_xy/drag_turn/drag_shrink per-delta handlers.
			if(_drag_disabled_by_lag())
				return FALSE
			var/part = params["part"]
			var/dir_key = params["dir"]
			if(!(part in GLOB.taur_genital_part_keys))
				return FALSE
			if(!(dir_key in GLOB.taur_genital_dir_keys))
				return FALSE
			var/list/props = _get_props(part)
			if(!props)
				return FALSE
			var/any_applied = FALSE
			for(var/field in list("x", "y", "turn", "shrink"))
				if(!(field in params))
					continue
				_apply_field(props, "[dir_key][field]", field, params[field])
				any_applied = TRUE
			if(!any_applied)
				return FALSE
			prefs.save_preferences()
			prefs.update_preview_icon()
			return TRUE

	return FALSE

/// Returns TRUE when mouse-drag edits should be rejected because the server is
/// lagging hard enough that the flood of Topic() calls from a drag would make
/// things worse. Players are expected to fall back to the numeric inputs in
/// this case, which only emit one Topic() per commit.
/datum/taur_genital_offset_editor/proc/_drag_disabled_by_lag()
	if(!SStime_track)
		return FALSE
	return SStime_track.time_dilation_avg_fast >= TAUR_EDITOR_DRAG_DISABLE_TIME_DILATION

/// Writes a single field into the props list with the appropriate type coercion
/// and clamp for that field. `key` must be the fully-prefixed `<dir><field>` key.
/datum/taur_genital_offset_editor/proc/_apply_field(list/props, key, field, value)
	if(!islist(props))
		return
	switch(field)
		if("x", "y")
			props[key] = clamp(round(text2num_safe(value, 0)), TAUR_GENITAL_OFFSET_MIN, TAUR_GENITAL_OFFSET_MAX)
		if("turn")
			var/t = round(text2num_safe(value, 0))
			props[key] = ((t % 360) + 360) % 360
		if("flip", "above", "hide")
			props[key] = text2num_safe(value, 0) ? 1 : 0
		if("shrink")
			var/s = text2num_safe(value, 1.0)
			props[key] = clamp(s, 0.1, 4.0)

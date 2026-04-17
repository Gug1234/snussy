/**
 * feature_customizer_editor.dm — Server-side TGUI bodypart feature
 * customizer editor datum. Phase 3 scaffolding that replaces the legacy
 * HTML `print_customizers_page()` flow.
 *
 * Mirrors body_marking_editor.dm / custom_piercing_editor.dm:
 *   - Singleton on /client.
 *   - `GLOB.always_state` so it works from the lobby.
 *   - Rate-limited ui_act() via /datum/ui_act_rate_limiter.
 *   - Dirty-flag autosave: mutations only touch the in-prefs
 *     /datum/customizer_entry objects; `prefs.save_character()` runs on
 *     explicit "save", ui_close, and Destroy.
 *
 * Phase 3 is strictly single-entry-per-customizer-type. No composites,
 * no stacking, no sidecar JSON. The Phase 1 transform vars on
 * /datum/customizer_entry already persist via the main savefile's binary
 * serialize, so there is nothing to write separately.
 *
 * Phase 4 will ship the TSX frontend ("FeatureCustomizerEditor"); until
 * then opening the window produces an empty panel, which is expected.
 */

#define FEATURE_CUSTOMIZER_EDITOR_MAX_ACTS_PER_SECOND 30
#define FEATURE_CUSTOMIZER_EDITOR_RATE_WINDOW_DS 10
#define FEATURE_CUSTOMIZER_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS 300

/// Singleton: at most one feature customizer editor per client. Repeat
/// opens refocus the existing window instead of spawning duplicates.
/client/var/datum/feature_customizer_editor/feature_customizer_editor_instance

/datum/feature_customizer_editor
	/// Client that opened this editor. All prefs reads go through owner.prefs.
	var/client/owner
	/// TRUE when an entry has been mutated since the last save_character() call.
	var/dirty = FALSE
	/// Currently focused customizer type path (as text) in the TSX sidebar.
	var/active_customizer_type
	/// Shared ui_act() flood limiter.
	var/datum/ui_act_rate_limiter/rate_limiter

/datum/feature_customizer_editor/New(client/C)
	if(!C)
		qdel(src)
		return
	owner = C
	rate_limiter = new(
		"Feature customizer editor",
		FEATURE_CUSTOMIZER_EDITOR_MAX_ACTS_PER_SECOND,
		FEATURE_CUSTOMIZER_EDITOR_RATE_WINDOW_DS,
		FEATURE_CUSTOMIZER_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS,
	)
	// Default focus: first species-allowed customizer (if any).
	var/datum/preferences/P = owner.prefs
	if(P?.pref_species)
		for(var/customizer_type as anything in P.pref_species.customizers)
			var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
			if(!customizer || !customizer.is_allowed(P))
				continue
			active_customizer_type = "[customizer_type]"
			break

/datum/feature_customizer_editor/Destroy()
	if(dirty)
		_persist()
		dirty = FALSE
	if(owner?.feature_customizer_editor_instance == src)
		owner.feature_customizer_editor_instance = null
	owner = null
	QDEL_NULL(rate_limiter)
	return ..()

/datum/feature_customizer_editor/ui_state(mob/user)
	return GLOB.always_state

/datum/feature_customizer_editor/ui_close(mob/user)
	if(dirty)
		_persist()
		dirty = FALSE
	qdel(src)

/datum/feature_customizer_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FeatureCustomizerEditor", "Bodypart Features", 900, 720)
		// Match sibling lobby-capable editors: pin state on creation as
		// well as via ui_state() so status resolution from
		// /mob/dead/new_player is unambiguous.
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/feature_customizer_editor/ui_data(mob/user)
	var/list/data = list()
	var/datum/preferences/P = owner?.prefs

	data["active_customizer_type"] = active_customizer_type
	data["dirty"] = dirty
	// Phase 7: expose the absolute-ceiling bounds to the TSX UI so sliders
	// cannot emit out-of-bounds values (save gate also rejects them).
	data["offset_min"] = -EXTREME_OFFSET_CLAMP_PX
	data["offset_max"] = EXTREME_OFFSET_CLAMP_PX
	data["rotation_choices"] = FEATURE_ROTATION_CHOICES
	data["scale_choices"] = FEATURE_SCALE_CHOICES

	// Phase 3 — extreme-offset vetting surface.
	// Recompute before emit: cheap (sums a few ints over owned entries)
	// and guarantees aggregate flags track the current payload.
	if(P)
		P.recompute_aggregate_extreme()
		data["aggregate_extreme"] = P.aggregate_extreme ? 1 : 0
		data["aggregate_offset_budget_used"] = P.aggregate_offset_budget_used
		data["acknowledge_extreme_offsets"] = P.acknowledge_extreme_offsets ? 1 : 0
	else
		data["aggregate_extreme"] = 0
		data["aggregate_offset_budget_used"] = 0
		data["acknowledge_extreme_offsets"] = 0
	data["extreme_aggregate_budget"] = GLOB.extreme_aggregate_budget

	var/list/customizers_out = list()
	var/list/available_out = list()

	if(P?.pref_species)
		for(var/customizer_type as anything in P.pref_species.customizers)
			var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
			if(!customizer)
				continue
			var/type_text = "[customizer_type]"
			var/allowed = customizer.is_allowed(P)
			var/datum/customizer_entry/entry = P.get_customizer_entry_for_customizer_type(customizer_type)
			var/list/entry_out = null
			if(entry)
				entry_out = _entry_payload(entry)
			customizers_out += list(list(
				"customizer_type" = type_text,
				"name" = customizer.name,
				"allows_disabling" = customizer.allows_disabling ? 1 : 0,
				"allowed_by_species" = allowed ? 1 : 0,
				"entry" = entry_out,
			))

			// Per-customizer accessory catalog (shared across all choices
			// of this customizer — Phase 3 still assumes a single choice
			// per customizer on the mutation side, but we surface all
			// sprite_accessories the current choice exposes).
			var/datum/customizer_choice/choice
			if(entry)
				choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice && customizer.default_choice)
				choice = CUSTOMIZER_CHOICE(customizer.default_choice)
			available_out[type_text] = _accessory_catalog(choice)

	data["customizers"] = customizers_out
	data["available_accessories"] = available_out
	data["hair_gradients"] = _hair_gradient_catalog()

	return data

/datum/feature_customizer_editor/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!owner || !owner.prefs)
		return FALSE
	if(rate_limiter?.check_blocked(usr))
		return FALSE

	. = _dispatch_ui_act(action, params)
	// Refresh the lobby mannequin preview whenever the player actually
	// mutates a customizer entry so rotation/color/offset/etc changes are
	// visible immediately. Navigation-only actions (sidebar switch, window
	// close) skip the (expensive) rebuild. Mirrors the taur genital offset
	// editor's per-mutation refresh cadence.
	if(. && owner?.prefs && !(action in list("select_customizer", "close")))
		owner.prefs.update_preview_icon()

/// Original ui_act switch body. Split off so the public ui_act wrapper can
/// refresh the lobby preview after successful mutations without rewriting
/// every branch.
/datum/feature_customizer_editor/proc/_dispatch_ui_act(action, list/params)
	var/datum/preferences/P = owner.prefs

	switch(action)
		if("select_customizer")
			var/ctype = params["customizer_type"]
			if(!_customizer_path_allowed(P, ctype))
				return FALSE
			active_customizer_type = ctype
			return TRUE

		if("toggle_disabled")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/datum/customizer/customizer = CUSTOMIZER(entry.customizer_type)
			if(!customizer || !customizer.allows_disabling)
				return FALSE
			entry.disabled = !entry.disabled
			dirty = TRUE
			return TRUE

		if("change_accessory")
			// NOTE: mutates prefs entry ONLY. Item-spawning slots
			// (underwear/legwear/chastity) are updated on the live mob
			// elsewhere via apply_customizers_to_character; the editor
			// never calls set_accessory_type on a live mob per-act.
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice || !choice.sprite_accessories)
				return FALSE
			var/new_type = text2path(params["accessory_type"])
			if(!new_type || !(new_type in choice.sprite_accessories))
				return FALSE
			choice.set_accessory_type(P, new_type, entry)
			entry.sync_primary_to_sub()
			dirty = TRUE
			return TRUE

		if("rotate_accessory")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice || !length(choice.sprite_accessories))
				return FALSE
			var/direction = text2num(params["direction"])
			if(!(direction == 1 || direction == -1))
				return FALSE
			var/current_index = 0
			var/i = 0
			for(var/accessory_type in choice.sprite_accessories)
				i++
				if(entry.accessory_type == accessory_type)
					current_index = i
					break
			if(!current_index)
				current_index = 1
			var/target_index = current_index + direction
			if(target_index > length(choice.sprite_accessories))
				target_index = 1
			else if(target_index <= 0)
				target_index = length(choice.sprite_accessories)
			choice.set_accessory_type(P, choice.sprite_accessories[target_index], entry)
			entry.sync_primary_to_sub()
			dirty = TRUE
			return TRUE

		if("set_color")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice || !choice.allows_accessory_color_customization)
				return FALSE
			var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(entry.accessory_type)
			if(!accessory || accessory.color_disabled)
				return FALSE
			var/zero_based = text2num(params["color_index"])
			if(!isnum(zero_based))
				return FALSE
			var/index = zero_based + 1
			if(index < 1 || index > accessory.color_keys)
				return FALSE
			var/sanitized = _sanitize_hex(params["hex"])
			if(!sanitized)
				return FALSE
			var/list/color_list = color_string_to_list(entry.accessory_colors)
			if(!islist(color_list) || color_list.len < accessory.color_keys)
				// Re-derive defaults if the packed string is shorter than
				// expected; avoids a corrupt entry bricking the editor.
				entry.accessory_colors = accessory.get_default_colors(color_key_source_list_from_prefs(P))
				color_list = color_string_to_list(entry.accessory_colors)
			color_list[index] = sanitized
			entry.accessory_colors = color_list_to_string(color_list)
			entry.sync_primary_to_sub()
			dirty = TRUE
			return TRUE

		if("reset_colors")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice || !choice.allows_accessory_color_customization)
				return FALSE
			choice.reset_accessory_colors(P, entry)
			entry.sync_primary_to_sub()
			dirty = TRUE
			return TRUE

		if("set_hair_color")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/sanitized = _sanitize_hex(params["hex"])
			if(!sanitized)
				return FALSE
			entry.hair_color = sanitized
			entry.sync_primary_to_sub()
			dirty = TRUE
			return TRUE

		if("set_natural_gradient")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/gradient_path = text2path(params["gradient_type"])
			if(!gradient_path || !HAIR_GRADIENT(gradient_path))
				return FALSE
			entry.natural_gradient = gradient_path
			dirty = TRUE
			return TRUE

		if("clear_natural_gradient")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			entry.natural_gradient = /datum/hair_gradient/none
			dirty = TRUE
			return TRUE

		if("set_natural_color")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/sanitized = _sanitize_hex(params["hex"])
			if(!sanitized)
				return FALSE
			entry.natural_color = sanitized
			dirty = TRUE
			return TRUE

		if("set_dye_gradient")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/gradient_path = text2path(params["gradient_type"])
			if(!gradient_path || !HAIR_GRADIENT(gradient_path))
				return FALSE
			entry.dye_gradient = gradient_path
			dirty = TRUE
			return TRUE

		if("clear_dye_gradient")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			entry.dye_gradient = /datum/hair_gradient/none
			dirty = TRUE
			return TRUE

		if("set_dye_color")
			var/datum/customizer_entry/hair/entry = _hair_entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/sanitized = _sanitize_hex(params["hex"])
			if(!sanitized)
				return FALSE
			entry.dye_color = sanitized
			dirty = TRUE
			return TRUE

		if("nudge")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/dx = text2num(params["dx"]) || 0
			var/dy = text2num(params["dy"]) || 0
			// Phase 7 hard clamp: mutation-site ceiling so invalid state can
			// never land on the entry. Save gate also rejects out-of-bounds.
			entry.pixel_x = clamp(entry.pixel_x + dx, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			entry.pixel_y = clamp(entry.pixel_y + dy, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			entry.sync_primary_to_sub()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("set_offset")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/px = text2num(params["pixel_x"])
			var/py = text2num(params["pixel_y"])
			// Phase 7 hard clamp on mutation.
			if(isnum(px))
				entry.pixel_x = clamp(px, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			if(isnum(py))
				entry.pixel_y = clamp(py, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			entry.sync_primary_to_sub()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("set_transform")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/rotation = text2num(params["rotation"])
			var/scale = text2num(params["scale"])
			if(!(rotation in FEATURE_ROTATION_CHOICES))
				return FALSE
			if(!(scale in FEATURE_SCALE_CHOICES))
				return FALSE
			entry.rotation = rotation
			entry.scale = scale
			entry.flip_x = params["flip_x"] ? TRUE : FALSE
			entry.flip_y = params["flip_y"] ? TRUE : FALSE
			entry.sync_primary_to_sub()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("reset_transform")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			entry.pixel_x = 0
			entry.pixel_y = 0
			entry.flip_x = FALSE
			entry.flip_y = FALSE
			entry.rotation = 0
			entry.scale = 1
			entry.sync_primary_to_sub()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("save")
			if(dirty)
				if(!_save_gate_allows(P))
					// _save_gate_allows already notified the user.
					return TRUE
				_persist()
				dirty = FALSE
			return TRUE

		if("close")
			SStgui.close_uis(src)
			return TRUE

		// -------------------------------------------------------------
		// Phase 6 — composite sub-entry actions.
		// -------------------------------------------------------------
		if("add_sub_entry")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/datum/customizer_choice/bodypart_feature/bpf_choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!istype(bpf_choice) || !bpf_choice.allow_sub_entries)
				return FALSE
			// Ensure migration has run so sub_entries[1] exists as the
			// mirrored primary before stacking new subs.
			entry.migrate_sub_entries()
			if(LAZYLEN(entry.sub_entries) >= MAX_SUB_ENTRIES)
				return FALSE
			var/datum/customizer_sub_entry/sub = new
			// Default new subs to the same accessory as the primary so
			// they render immediately; players can change it after.
			sub.accessory_type = entry.accessory_type
			sub.accessory_colors = entry.accessory_colors
			if(istype(entry, /datum/customizer_entry/hair))
				var/datum/customizer_entry/hair/hair_entry = entry
				sub.hair_color = hair_entry.hair_color
			sub.recompute_extreme_flags()
			LAZYADD(entry.sub_entries, sub)
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("remove_sub_entry")
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!entry)
				return FALSE
			var/idx = text2num(params["sub_index"])
			if(!isnum(idx) || idx < 1 || idx > LAZYLEN(entry.sub_entries))
				return FALSE
			// Refuse to remove the last remaining sub-entry — that would
			// leave the parent with no primary to mirror. Players who
			// want a fully empty slot should use toggle_disabled.
			if(LAZYLEN(entry.sub_entries) <= 1)
				return FALSE
			entry.sub_entries.Cut(idx, idx + 1)
			// If we nuked the primary, the next sub slides down to
			// index 1; re-mirror parent fields from the new primary.
			if(idx == 1)
				entry.sync_from_primary()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("set_sub_accessory")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice || !choice.sprite_accessories)
				return FALSE
			var/new_type = text2path(params["accessory_type"])
			if(!new_type || !(new_type in choice.sprite_accessories))
				return FALSE
			sub.accessory_type = new_type
			var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(new_type)
			if(accessory)
				sub.accessory_colors = accessory.get_default_colors(color_key_source_list_from_prefs(P))
			sub.recompute_extreme_flags()
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("set_sub_color")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
			if(!choice || !choice.allows_accessory_color_customization)
				return FALSE
			var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(sub.accessory_type)
			if(!accessory || accessory.color_disabled)
				return FALSE
			var/zero_based = text2num(params["color_index"])
			if(!isnum(zero_based))
				return FALSE
			var/index = zero_based + 1
			if(index < 1 || index > accessory.color_keys)
				return FALSE
			var/sanitized = _sanitize_hex(params["hex"])
			if(!sanitized)
				return FALSE
			var/list/color_list = color_string_to_list(sub.accessory_colors)
			if(!islist(color_list) || color_list.len < accessory.color_keys)
				sub.accessory_colors = accessory.get_default_colors(color_key_source_list_from_prefs(P))
				color_list = color_string_to_list(sub.accessory_colors)
			color_list[index] = sanitized
			sub.accessory_colors = color_list_to_string(color_list)
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			dirty = TRUE
			return TRUE

		if("set_sub_hair_color")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			if(!istype(entry, /datum/customizer_entry/hair))
				return FALSE
			var/sanitized = _sanitize_hex(params["hex"])
			if(!sanitized)
				return FALSE
			sub.hair_color = sanitized
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			dirty = TRUE
			return TRUE

		if("sub_nudge")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			var/dx = text2num(params["dx"]) || 0
			var/dy = text2num(params["dy"]) || 0
			// Phase 7 hard clamp on mutation.
			sub.pixel_x = clamp(sub.pixel_x + dx, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			sub.pixel_y = clamp(sub.pixel_y + dy, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			sub.recompute_extreme_flags()
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("set_sub_offset")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			var/px = text2num(params["pixel_x"])
			var/py = text2num(params["pixel_y"])
			// Phase 7 hard clamp on mutation.
			if(isnum(px))
				sub.pixel_x = clamp(px, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			if(isnum(py))
				sub.pixel_y = clamp(py, -EXTREME_OFFSET_CLAMP_PX, EXTREME_OFFSET_CLAMP_PX)
			sub.recompute_extreme_flags()
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("set_sub_transform")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			var/rotation = text2num(params["rotation"])
			var/scale = text2num(params["scale"])
			if(!(rotation in FEATURE_ROTATION_CHOICES))
				return FALSE
			if(!(scale in FEATURE_SCALE_CHOICES))
				return FALSE
			sub.rotation = rotation
			sub.scale = scale
			sub.flip_x = params["flip_x"] ? TRUE : FALSE
			sub.flip_y = params["flip_y"] ? TRUE : FALSE
			sub.recompute_extreme_flags()
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

		if("reset_sub_transform")
			var/datum/customizer_sub_entry/sub = _sub_entry_for_params(P, params)
			if(!sub)
				return FALSE
			var/datum/customizer_entry/entry = _entry_for_params(P, params)
			sub.pixel_x = 0
			sub.pixel_y = 0
			sub.flip_x = FALSE
			sub.flip_y = FALSE
			sub.rotation = 0
			sub.scale = 1
			sub.recompute_extreme_flags()
			if(text2num(params["sub_index"]) == 1)
				entry.sync_from_primary()
			entry.recompute_extreme_flags()
			dirty = TRUE
			return TRUE

	return FALSE

/// Resolves params["customizer_type"] -> /datum/customizer_entry in prefs.
/// Returns null for unknown customizer types or species-disallowed types.
/datum/feature_customizer_editor/proc/_entry_for_params(datum/preferences/P, list/params)
	if(!P || !islist(params))
		return null
	var/customizer_type = text2path(params["customizer_type"])
	if(!customizer_type)
		return null
	if(!_customizer_path_allowed(P, "[customizer_type]"))
		return null
	return P.get_customizer_entry_for_customizer_type(customizer_type)

/// Hair-entry variant used by the hair-only ui_act handlers.
/datum/feature_customizer_editor/proc/_hair_entry_for_params(datum/preferences/P, list/params)
	var/datum/customizer_entry/entry = _entry_for_params(P, params)
	if(!istype(entry, /datum/customizer_entry/hair))
		return null
	return entry

/// Phase 6 — resolve params[sub_index] (1-based) to a sub-entry on the
/// targeted parent entry. Auto-migrates if the parent has no sub-entries
/// yet so index 1 is always a valid primary for existing saves that
/// happened to load without triggering validate_customizer_entries()
/// first (defensive; the post-load path should already have migrated).
/datum/feature_customizer_editor/proc/_sub_entry_for_params(datum/preferences/P, list/params)
	var/datum/customizer_entry/entry = _entry_for_params(P, params)
	if(!entry)
		return null
	entry.migrate_sub_entries()
	var/idx = text2num(params["sub_index"])
	if(!isnum(idx))
		return null
	if(idx < 1 || idx > LAZYLEN(entry.sub_entries))
		return null
	var/datum/customizer_sub_entry/sub = entry.sub_entries[idx]
	if(!istype(sub))
		return null
	return sub

/// TRUE when `type_text` is a known customizer on the current species.
/datum/feature_customizer_editor/proc/_customizer_path_allowed(datum/preferences/P, type_text)
	if(!istext(type_text) || !P?.pref_species)
		return FALSE
	var/as_path = text2path(type_text)
	if(!as_path)
		return FALSE
	return as_path in P.pref_species.customizers

/// Builds the per-entry payload (Phase 3 shape) for ui_data.
/datum/feature_customizer_editor/proc/_entry_payload(datum/customizer_entry/entry)
	var/list/out = list()
	out["accessory_type"] = entry.accessory_type ? "[entry.accessory_type]" : null
	out["accessory_colors"] = entry.accessory_colors
	out["disabled"] = entry.disabled ? 1 : 0
	out["pixel_x"] = entry.pixel_x
	out["pixel_y"] = entry.pixel_y
	out["flip_x"] = entry.flip_x ? 1 : 0
	out["flip_y"] = entry.flip_y ? 1 : 0
	out["rotation"] = entry.rotation
	out["scale"] = entry.scale

	// Phase 3 — extreme-offset caches. Recompute defensively: mutation
	// sites already refresh, but first-render after load is guarded
	// via validate_customizer_entries(); cheap to belt-and-suspenders.
	entry.recompute_extreme_flags()
	out["is_hard_extreme"] = entry.is_hard_extreme ? 1 : 0
	out["is_soft_extreme"] = entry.is_soft_extreme ? 1 : 0
	out["extreme_flags"] = entry.extreme_flags

	var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
	out["customizer_choice_type"] = entry.customizer_choice_type ? "[entry.customizer_choice_type]" : null
	out["customizer_choice_name"] = choice?.name

	var/list/color_keys_out = list()
	if(entry.accessory_type)
		var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(entry.accessory_type)
		if(accessory)
			out["accessory_choice_name"] = accessory.name
			out["accessory_icon"] = "[accessory.icon]"
			out["accessory_icon_state"] = accessory.icon_state
			out["accessory_color_disabled"] = accessory.color_disabled ? 1 : 0
			out["accessory_color_keys"] = accessory.color_keys
			for(var/idx in 1 to accessory.color_keys)
				var/key_name = (accessory.color_keys == 1) ? accessory.color_key_name : accessory.color_key_names?[idx]
				color_keys_out += list(list(
					"key" = idx - 1,
					"name" = key_name,
				))
	out["color_keys"] = color_keys_out

	if(istype(entry, /datum/customizer_entry/hair))
		var/datum/customizer_entry/hair/hair_entry = entry
		out["hair_color"] = hair_entry.hair_color
		out["natural_gradient"] = hair_entry.natural_gradient ? "[hair_entry.natural_gradient]" : null
		out["natural_color"] = hair_entry.natural_color
		out["dye_gradient"] = hair_entry.dye_gradient ? "[hair_entry.dye_gradient]" : null
		out["dye_color"] = hair_entry.dye_color

	// Phase 6 — composite sub-entries. The primary (index 1) mirrors the
	// parent's legacy fields; we still surface it separately so the TSX
	// can render per-sub inputs uniformly. allow_sub_entries is keyed
	// off the bodypart_feature choice subtype; non-bodypart customizers
	// don't advertise the flag and get nothing extra.
	var/is_hair = istype(entry, /datum/customizer_entry/hair)
	var/list/subs_out = list()
	if(LAZYLEN(entry.sub_entries))
		for(var/datum/customizer_sub_entry/sub as anything in entry.sub_entries)
			if(!istype(sub))
				continue
			subs_out += list(_sub_entry_payload(sub, is_hair))
	out["sub_entries"] = subs_out
	out["migrated_v"] = entry.migrated_v
	var/allow_sub = FALSE
	if(istype(choice, /datum/customizer_choice/bodypart_feature))
		var/datum/customizer_choice/bodypart_feature/bpf = choice
		allow_sub = bpf.allow_sub_entries ? TRUE : FALSE
	out["allow_sub_entries"] = allow_sub ? 1 : 0
	out["max_sub_entries"] = MAX_SUB_ENTRIES

	return out

/// Phase 6 — per-sub-entry payload. Narrow subset of the parent payload:
/// only the fields a sub-entry actually owns. Extreme flags are per-sub
/// so the TSX can render badges independently per tab.
/datum/feature_customizer_editor/proc/_sub_entry_payload(datum/customizer_sub_entry/sub, is_hair)
	var/list/out = list()
	out["accessory_type"] = sub.accessory_type ? "[sub.accessory_type]" : null
	out["accessory_colors"] = sub.accessory_colors
	out["pixel_x"] = sub.pixel_x
	out["pixel_y"] = sub.pixel_y
	out["flip_x"] = sub.flip_x ? 1 : 0
	out["flip_y"] = sub.flip_y ? 1 : 0
	out["rotation"] = sub.rotation
	out["scale"] = sub.scale
	out["is_hard_extreme"] = sub.is_hard_extreme ? 1 : 0
	out["is_soft_extreme"] = sub.is_soft_extreme ? 1 : 0
	out["extreme_flags"] = sub.extreme_flags
	if(is_hair)
		out["hair_color"] = sub.hair_color
	// Pull accessory display metadata so the TSX preview can render the
	// sub-entry without extra catalog lookups per index.
	if(sub.accessory_type)
		var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(sub.accessory_type)
		if(accessory)
			out["accessory_icon"] = "[accessory.icon]"
			out["accessory_icon_state"] = accessory.icon_state
			out["accessory_choice_name"] = accessory.name
			out["accessory_color_disabled"] = accessory.color_disabled ? 1 : 0
			out["accessory_color_keys"] = accessory.color_keys
	return out

/// Per-customizer accessory options surfaced to the TSX. Keyed by
/// customizer type text in ui_data.available_accessories.
/datum/feature_customizer_editor/proc/_accessory_catalog(datum/customizer_choice/choice)
	var/list/out = list()
	if(!choice || !length(choice.sprite_accessories))
		return out
	for(var/accessory_type as anything in choice.sprite_accessories)
		var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
		if(!accessory)
			continue
		out += list(list(
			"accessory_type" = "[accessory_type]",
			"name" = accessory.name,
			"icon" = "[accessory.icon]",
			"icon_state" = accessory.icon_state,
			"color_keys" = accessory.color_keys,
			"color_disabled" = accessory.color_disabled ? 1 : 0,
		))
	return out

/// Catalog of hair gradient options for the TSX. Shared across all hair
/// customizers — gating by customizer/choice happens client-side in Phase 4.
/datum/feature_customizer_editor/proc/_hair_gradient_catalog()
	var/list/out = list()
	for(var/path in GLOB.hair_gradients)
		var/datum/hair_gradient/gradient = HAIR_GRADIENT(path)
		if(!gradient)
			continue
		out += list(list(
			"gradient_type" = "[path]",
			"name" = gradient.name,
		))
	return out

/// Sanitize a user-submitted hex string. Accepts with or without a leading
/// `#`; returns a "#RRGGBB" string or null when invalid.
/datum/feature_customizer_editor/proc/_sanitize_hex(raw)
	if(!istext(raw))
		return null
	var/stripped = raw
	if(length(stripped) && copytext(stripped, 1, 2) == "#")
		stripped = copytext(stripped, 2)
	return sanitize_hexcolor(stripped, 6, TRUE, null)

/// Flushes prefs to the main savefile. Phase 3 has no sidecar — the
/// transform vars on /datum/customizer_entry persist via the existing
/// binary serialize used by save_character().
/datum/feature_customizer_editor/proc/_persist()
	if(!owner?.prefs)
		return
	owner.prefs.save_character()

/// Phase 3 save-gate. Returns TRUE when save may proceed. When any
/// owned customizer_entry is hard-extreme OR the aggregate budget is
/// blown, and the player has not pre-acknowledged via ERP Preferences,
/// prompts with a blocking tgui_alert and returns the player's choice.
///
/// Sync variant of tgui_alert (code/modules/tgui_input/alert.dm L14) is
/// used here — the ui_act save path already runs under usr with a
/// client, and blocking keeps the mutation state atomic (no partial
/// commit, no reentry). Async would need to queue `dirty` writes and
/// reconcile with subsequent mutations mid-prompt.
/datum/feature_customizer_editor/proc/_save_gate_allows(datum/preferences/P)
	if(!P)
		return TRUE
	// Phase 7 — absolute ceilings. Saves that exceed EXTREME_OFFSET_CLAMP_PX
	// or EXTREME_OFFSET_CLAMP_SCALE on the parent or any sub-entry are
	// rejected outright (not logged, not flagged — just refused). The
	// mutation handlers already clamp on the way in, so this only fires
	// when a transform landed out-of-bounds via a non-ui_act path.
	for(var/datum/customizer_entry/entry as anything in P.customizer_entries)
		if(!istype(entry))
			continue
		if(!entry.validate())
			var/mob/reject_user = owner?.mob
			if(reject_user)
				to_chat(reject_user, span_warning("Cannot save: one or more customizer transforms exceed the absolute ceiling (scale > [EXTREME_OFFSET_CLAMP_SCALE] or pixel offset > [EXTREME_OFFSET_CLAMP_PX]). Reduce values and try again."))
			return FALSE
	// Recompute aggregate pre-gate so flags reflect current state.
	P.recompute_aggregate_extreme()
	var/any_hard = P.aggregate_extreme
	if(!any_hard)
		for(var/datum/customizer_entry/entry as anything in P.customizer_entries)
			if(!istype(entry))
				continue
			// Entries are recomputed on mutation + on load; refresh
			// defensively in case a code path mutated transform vars
			// without going through ui_act.
			entry.recompute_extreme_flags()
			if(entry.is_hard_extreme)
				any_hard = TRUE
				break
	if(!any_hard)
		return TRUE
	if(P.acknowledge_extreme_offsets)
		return TRUE
	var/mob/user = owner?.mob
	if(!user)
		return TRUE
	var/msg = {"WARNING: 'Avoid making characters that significantly clash with the aesthetic of the setting. We are flexible, but we have limits.'

Characters with extreme offsets are reported to admin logging upon joining a round as a measure to curb abuse.

Saving with extreme offsets? This save will be reported to staff when the character joins a round."}
	var/choice = tgui_alert(user, msg, "Extreme Offsets Detected", list("Save and report", "Cancel"))
	if(choice == "Save and report")
		return TRUE
	to_chat(user, span_warning("Save cancelled. No changes were written to your savefile."))
	return FALSE

/// Entry point used by the preferences Topic router. Creates the singleton
/// if needed and opens (or refocuses) the TGUI window.
/client/proc/open_feature_customizer_editor()
	if(!mob)
		return
	if(feature_customizer_editor_instance && QDELETED(feature_customizer_editor_instance))
		feature_customizer_editor_instance = null
	if(!feature_customizer_editor_instance)
		feature_customizer_editor_instance = new(src)
	feature_customizer_editor_instance.ui_interact(mob)

#undef FEATURE_CUSTOMIZER_EDITOR_MAX_ACTS_PER_SECOND
#undef FEATURE_CUSTOMIZER_EDITOR_RATE_WINDOW_DS
#undef FEATURE_CUSTOMIZER_EDITOR_ABUSE_NOTIFY_COOLDOWN_DS

/**
 * pref_catalog act handler — translate AccessoryPicker clicks into prefs mutations.
 *
 * The TGUI <AccessoryPicker> emits two opaque strings per click:
 *   - `choice_type`   e.g. `/datum/customizer_choice/organ/horns/anthro`
 *   - `entry_key`     e.g. `sprite_accessory__horns__small_demon`
 *                     or  `sprite_accessory__breasts__pair__size3` for sized.
 *
 * This file owns the inverse mapping:
 *   1. Resolve `entry_key` → /datum/sprite_accessory typepath (and a size
 *      integer for breasts/penis/testicles, which are size-driven).
 *   2. Find the customizer_entry that matches the choice's parent
 *      /datum/customizer typepath, swapping its choice if needed.
 *   3. Call `set_accessory_type` on the choice + assign size on the entry.
 *   4. Run `validate_customizer_entries()` so the change passes the same
 *      gates the legacy text-popup path goes through, and trigger a
 *      preview redraw.
 */

/// Reverse of `pref_catalog_typepath_to_safe_name`. Takes a manifest-safe
/// name like `"sprite_accessory__horns__small_demon"` and returns the
/// corresponding typepath text `"/datum/sprite_accessory/horns/small_demon"`.
/// Returns null on empty input.
/proc/pref_catalog_safe_name_to_typepath_text(name)
	if(!istext(name) || !length(name))
		return null
	return "/datum/[replacetext(name, "__", "/")]"

/// Strip a trailing `__sizeN` suffix off an entry key. Returns a list of
/// `(stripped_name, size_int)` when present, or null when there is no size
/// suffix. Size integers are returned as raw text2num output; the caller is
/// responsible for clamping to family-specific ranges.
/proc/pref_catalog_split_size_suffix(entry_key)
	if(!istext(entry_key) || !length(entry_key))
		return null
	var/marker = findlasttext(entry_key, "__size")
	if(!marker)
		return null
	var/tail = copytext(entry_key, marker + length("__size"))
	var/size = text2num(tail)
	if(!isnum(size))
		return null
	var/head = copytext(entry_key, 1, marker)
	if(!length(head))
		return null
	return list(head, size)

/// Look up the customizer_entry whose customizer matches the customizer
/// that owns `choice_type`. Returns the entry datum, or null if the species
/// doesn't actually register that customizer (in which case the picker
/// click is silently rejected — same surface as a row that wouldn't render).
/datum/preferences/proc/_pref_catalog_find_entry_for_choice(datum/customizer_choice/choice_proto)
	if(!choice_proto)
		return null
	for(var/customizer_type as anything in pref_species?.customizers)
		var/datum/customizer/customizer = CUSTOMIZER(customizer_type)
		if(!customizer)
			continue
		if(!(choice_proto.type in customizer.customizer_choices))
			continue
		var/datum/customizer_entry/entry = get_customizer_entry_for_customizer_type(customizer_type)
		if(entry)
			return entry
		// No entry yet — seed via the canonical validate path so the new
		// entry inherits the customizer's default choice / disabled flag.
		validate_customizer_entries()
		return get_customizer_entry_for_customizer_type(customizer_type)
	return null

/// Top-level handler called from `ui_act("pref_catalog_select", …)`. Returns
/// TRUE on a successful mutation (caller should `update_uis`), FALSE on any
/// validation failure (silently rejected — invalid input from a misbehaving
/// or stale client should never crash the prefs UI).
/datum/preferences/proc/act_pref_catalog_select(choice_type_text, entry_key, mob/user)
	if(!istext(choice_type_text) || !istext(entry_key) || !length(choice_type_text) || !length(entry_key))
		return FALSE
	var/choice_type = text2path(choice_type_text)
	if(!ispath(choice_type, /datum/customizer_choice))
		return FALSE
	var/datum/customizer_choice/choice_proto = GLOB.customizer_choices[choice_type]
	if(!choice_proto)
		return FALSE

	// Split off optional `__sizeN` suffix BEFORE typepath resolution; the
	// typepath itself never contains the size token, that's a TGUI-side
	// composite key.
	var/sized_size = null
	var/effective_key = entry_key
	var/list/split = pref_catalog_split_size_suffix(entry_key)
	if(islist(split))
		effective_key = split[1]
		sized_size = split[2]

	var/accessory_path_text = pref_catalog_safe_name_to_typepath_text(effective_key)
	if(!istext(accessory_path_text))
		return FALSE
	var/accessory_type = text2path(accessory_path_text)
	if(!ispath(accessory_type, /datum/sprite_accessory))
		return FALSE
	if(!(accessory_type in choice_proto.sprite_accessories))
		// Either the manifest is stale (sprite_accessory was removed from
		// the choice) or the TGUI client is forging input. Reject quietly
		// and let the UI re-sync from the next update.
		return FALSE

	// Resolve the entry against the live species, swapping the choice
	// subtype if the player picked an accessory under a different
	// customizer_choice for the same parent customizer (e.g. switching
	// horns/anthro -> horns/humanoid via a single picker grid).
	var/datum/customizer_entry/entry = _pref_catalog_find_entry_for_choice(choice_proto)
	if(!entry)
		return FALSE
	if(entry.customizer_choice_type != choice_type)
		// Replace the entry with a new one rooted on the requested choice
		// subtype — this matches the legacy `change_choice` topic path.
		var/datum/customizer/customizer = CUSTOMIZER(entry.customizer_type)
		if(!customizer)
			return FALSE
		customizer_entries -= entry
		entry = customizer.create_customizer_entry(src, choice_type)
		customizer_entries += entry

	var/datum/customizer_choice/live_choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
	if(!live_choice)
		return FALSE
	live_choice.set_accessory_type(src, accessory_type, entry)

	// Apply size for size-driven families. set_accessory_type already
	// recomputed default colors; we only need to clamp the size onto the
	// matching organ-specific entry subtype.
	if(isnum(sized_size))
		_pref_catalog_apply_size(entry, sized_size)

	// Run the canonical validator so the post-mutation state matches what
	// disk save/load would produce. Triggers the preview redraw that
	// normally lives at the bottom of `handle_customizer_topic`.
	validate_customizer_entries()
	if(character_preview_view)
		character_preview_view.update_body(skip_intimate_prefs = TRUE)
	return TRUE

/// Apply a size value onto a size-driven customizer_entry. No-op for any
/// entry type that doesn't carry a numeric size variable. Each branch
/// clamps via the same defines the legacy size-stepper used.
/datum/preferences/proc/_pref_catalog_apply_size(datum/customizer_entry/entry, value)
	if(!entry || !isnum(value))
		return
	if(istype(entry, /datum/customizer_entry/organ/breasts))
		var/datum/customizer_entry/organ/breasts/breasts_entry = entry
		breasts_entry.breast_size = sanitize_integer(value, MIN_BREASTS_SIZE, MAX_BREASTS_SIZE, DEFAULT_BREASTS_SIZE)
		return
	if(istype(entry, /datum/customizer_entry/organ/penis))
		var/datum/customizer_entry/organ/penis/penis_entry = entry
		penis_entry.penis_size = sanitize_integer(value, MIN_PENIS_SIZE, MAX_PENIS_SIZE, DEFAULT_PENIS_SIZE)
		return
	if(istype(entry, /datum/customizer_entry/organ/testicles))
		var/datum/customizer_entry/organ/testicles/testicles_entry = entry
		testicles_entry.ball_size = sanitize_integer(value, MIN_TESTICLES_SIZE, MAX_TESTICLES_SIZE, DEFAULT_TESTICLES_SIZE)
		return

/**
 * Build the pref_catalog_selections map for ui_data. Returns an
 * associative list keyed by /datum/customizer_choice typepath text ->
 * manifest entry_key text (with size suffix when applicable). Entries
 * disabled by the player or rejected by the choice's accessory list
 * surface as null so the TGUI can render a "(none)" tile.
 */
/datum/preferences/proc/build_pref_catalog_selection_map()
	var/list/out = list()
	if(!pref_species)
		return out
	for(var/datum/customizer_entry/entry as anything in customizer_entries)
		if(!entry.customizer_choice_type)
			continue
		var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
		if(!choice)
			continue
		var/key = "[entry.customizer_choice_type]"
		var/accessory_type = entry.accessory_type
		if(entry.disabled || !accessory_type)
			out[key] = null
			continue
		var/safe = pref_catalog_typepath_to_safe_name(accessory_type)
		if(istype(entry, /datum/customizer_entry/organ/breasts))
			var/datum/customizer_entry/organ/breasts/breasts_entry = entry
			safe = "[safe]__size[breasts_entry.breast_size]"
		else if(istype(entry, /datum/customizer_entry/organ/penis))
			var/datum/customizer_entry/organ/penis/penis_entry = entry
			safe = "[safe]__size[penis_entry.penis_size]"
		else if(istype(entry, /datum/customizer_entry/organ/testicles))
			var/datum/customizer_entry/organ/testicles/testicles_entry = entry
			safe = "[safe]__size[testicles_entry.ball_size]"
		out[key] = safe
	return out

/**
 * Build the pref_catalog_colors map for ui_data. Returns an
 * associative list keyed by /datum/customizer_choice typepath text ->
 * list of color hex strings (one per the accessory's color_keys
 * slot). Entries with no accessory, no color customization, or no
 * stored colors emit an empty list so the TGUI surfaces "no color
 * controls" rather than crashing on a missing key.
 */
/datum/preferences/proc/build_pref_catalog_color_map()
	var/list/out = list()
	if(!pref_species)
		return out
	for(var/datum/customizer_entry/entry as anything in customizer_entries)
		if(!entry.customizer_choice_type)
			continue
		var/key = "[entry.customizer_choice_type]"
		var/datum/customizer_choice/choice = CUSTOMIZER_CHOICE(entry.customizer_choice_type)
		if(!choice || !choice.allows_accessory_color_customization)
			out[key] = list()
			continue
		var/accessory_type = entry.accessory_type
		if(!accessory_type)
			out[key] = list()
			continue
		var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
		if(!accessory || accessory.color_disabled || !accessory.color_keys)
			out[key] = list()
			continue
		// color_string_to_list returns a fresh list, safe to surface.
		// validate_customizer_entries() already pads to color_keys
		// length, but we defensively cap below in case a caller
		// invokes us before validation has run (e.g. opening the
		// menu mid-load).
		var/list/colors = color_string_to_list(entry.accessory_colors)
		if(!islist(colors))
			out[key] = list()
			continue
		var/list/normalized = list()
		var/index = 1
		while(index <= accessory.color_keys && index <= length(colors))
			var/raw = colors[index]
			normalized += "#[sanitize_hexcolor(raw, 6, FALSE, "ffffff")]"
			index++
		out[key] = normalized
	return out

/**
 * Apply a single per-slot accessory color override for the customizer
 * entry attached to `choice_type_text`. `color_index` is 1-based to
 * match the DM color_keys convention; the TGUI plumbs the same index
 * through unchanged. Returns TRUE on a successful mutation.
 */
/datum/preferences/proc/act_pref_catalog_set_color(choice_type_text, color_index, hex, mob/user)
	if(!istext(choice_type_text) || !length(choice_type_text))
		return FALSE
	if(!isnum(color_index) && !isnum(text2num("[color_index]")))
		return FALSE
	var/index = isnum(color_index) ? color_index : text2num("[color_index]")
	if(!isnum(index) || index < 1)
		return FALSE
	var/choice_type = text2path(choice_type_text)
	if(!ispath(choice_type, /datum/customizer_choice))
		return FALSE
	var/datum/customizer_choice/choice_proto = GLOB.customizer_choices[choice_type]
	if(!choice_proto || !choice_proto.allows_accessory_color_customization)
		return FALSE

	var/datum/customizer_entry/entry = _pref_catalog_find_entry_for_choice(choice_proto)
	if(!entry || entry.customizer_choice_type != choice_type)
		// Color writes only target the live entry; if the player has
		// the wrong choice subtype selected (or no entry yet), reject.
		return FALSE
	if(!entry.accessory_type)
		return FALSE
	var/datum/sprite_accessory/accessory = SPRITE_ACCESSORY(entry.accessory_type)
	if(!accessory || accessory.color_disabled || !accessory.color_keys)
		return FALSE
	if(index > accessory.color_keys)
		return FALSE

	// Strip an optional leading '#'; sanitize_hexcolor does the actual
	// validation and returns a 6-char no-crunch hex on success.
	var/raw = istext(hex) ? hex : "[hex]"
	if(length(raw) >= 1 && copytext(raw, 1, 2) == "#")
		raw = copytext(raw, 2)
	var/clean = sanitize_hexcolor(raw, 6, FALSE)
	if(!clean)
		return FALSE

	var/list/colors = color_string_to_list(entry.accessory_colors)
	if(!islist(colors))
		colors = list()
	// Pad up to color_keys so the index assignment below is safe even
	// when the entry's stored list is short.
	while(length(colors) < accessory.color_keys)
		colors += "ffffff"
	colors[index] = clean
	entry.accessory_colors = color_list_to_string(colors)

	if(character_preview_view)
		character_preview_view.update_body(skip_intimate_prefs = TRUE)
	return TRUE
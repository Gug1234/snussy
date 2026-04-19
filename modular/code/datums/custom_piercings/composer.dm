/**
 * composer.dm — Turns a sanitized custom_piercings slot config into a list of
 * mutable appearances ready to be added to the wearer's render appearance_list.
 *
 * Safety contract:
 *   - Never renders unless the character has a slot config with enabled = TRUE.
 *   - Never renders unless the slot's underlying intimate accessory (or organ)
 *     is currently present on the wearer.
 *   - Returns an empty list on any failure; never throws.
 *
 * This file defines ONLY the composer. Phase 2 wires the actual invocation
 * into the existing intimate overlay renderers (piercing_breast / piercing_
 * genital / piercing_ear / etc.) via their adjust_appearance_list hooks.
 * Until that wiring lands, calling compose_custom_piercing_slot_appearances()
 * directly is safe but unused in the normal render path.
 */

/// Returns the slot config stored on the mob itself, falling back to the
/// live client prefs when available. Lobby preview mannequins are clientless,
/// so the composer and examine hooks need the copied mob-side state.
/proc/custom_piercing_get_slot_config_source(mob/living/carbon/wearer, slot_key)
	if(!ishuman(wearer) || !istext(slot_key))
		return null
	var/mob/living/carbon/human/H = wearer
	var/list/slot_cfg = islist(H.custom_piercings) ? H.custom_piercings[slot_key] : null
	if(islist(slot_cfg))
		return slot_cfg
	var/client/C = H.client
	if(C?.prefs && islist(C.prefs.custom_piercings))
		slot_cfg = C.prefs.custom_piercings[slot_key]
		if(islist(slot_cfg))
			return slot_cfg
	return null

/// Returns TRUE if the wearer currently has the underlying intimate item /
/// organ that the given slot represents. Slots with no resolvable equipment
/// return FALSE so nothing ever renders in an empty slot.
/proc/custom_piercing_slot_is_equipped(mob/living/carbon/wearer, slot_key)
	if(!ishuman(wearer))
		return FALSE
	if(!(slot_key in GLOB.custom_piercing_slot_keys))
		return FALSE
	// Freeform slots are not tied to any equipped item — they always count
	// as "present" so their stickers render unconditionally. Per-slot
	// examine visibility is enforced separately in the examine hook.
	if(slot_key in GLOB.custom_piercing_freeform_slots)
		return TRUE
	// Lobby preview mannequins are clientless; at that stage the round-start
	// item/organ equip has not happened yet, so trust the copied slot config as
	// the preview-time source of truth.
	if(!wearer.client)
		var/list/slot_cfg = custom_piercing_get_slot_config_source(wearer, slot_key)
		return islist(slot_cfg) ? !!slot_cfg["enabled"] : FALSE
	var/lookup = GLOB.custom_piercing_slot_equip_lookup[slot_key]
	if(!istext(lookup))
		return FALSE
	if(findtextEx(lookup, "organ:") == 1)
		var/organ_slot = copytext(lookup, length("organ:") + 1)
		if(!length(organ_slot))
			return FALSE
		return wearer.getorganslot(organ_slot) ? TRUE : FALSE
	// Plain var name on /mob/living/carbon (e.g. intimate_breast_piercing).
	return wearer.vars[lookup] ? TRUE : FALSE

/// Applies a per-direction prop block to a mutable appearance. Sets the
/// appearance's `dir`, pixel offsets, and a transform matrix that combines
/// shrink, turn, and flip.
/proc/apply_custom_piercing_appearance_props(mutable_appearance/MA, list/props, dir_key)
	if(!MA || !islist(props) || !istext(dir_key))
		return
	// Map the string dir key to the BYOND dir constant so the appearance
	// only renders when the mob faces this direction.
	switch(dir_key)
		if("s")
			MA.dir = SOUTH
		if("n")
			MA.dir = NORTH
		if("e")
			MA.dir = EAST
		if("w")
			MA.dir = WEST
	MA.pixel_x = text2num_safe(props["[dir_key]x"], 0)
	MA.pixel_y = text2num_safe(props["[dir_key]y"], 0)
	var/shrink = text2num_safe(props["[dir_key]shrink"], 1.0)
	if(shrink <= 0)
		shrink = 1.0
	var/turn_deg = text2num_safe(props["[dir_key]turn"], 0)
	var/flipped = props["[dir_key]flip"] ? TRUE : FALSE
	var/matrix/M = matrix()
	if(shrink != 1.0)
		M = M.Scale(shrink, shrink)
	if(flipped)
		M = M.Scale(-1, 1)
	if(turn_deg)
		M = M.Turn(turn_deg)
	MA.transform = M

/// Returns the canonical dir key for a BYOND dir constant.
/proc/custom_piercing_dir_to_key(dir)
	switch(dir)
		if(NORTH)
			return "n"
		if(EAST)
			return "e"
		if(WEST)
			return "w"
	return "s"

/// Applies a slot-level per-direction prop block to every appearance in the list.
/// Used for the normal-slot offset panel so all mask layers stay in lockstep.
/proc/apply_custom_piercing_slot_props(list/appearance_list, mob/living/carbon/owner, slot_key)
	if(!islist(appearance_list) || !length(appearance_list) || !owner || !istext(slot_key))
		return
	var/list/slot_cfg = custom_piercing_get_slot_config_source(owner, slot_key)
	if(!islist(slot_cfg))
		return
	var/list/props = slot_cfg["slot_props"]
	if(!islist(props))
		props = slot_cfg["props"]
	if(!islist(props))
		return
	var/dir_key = custom_piercing_dir_to_key(owner.dir)
	if(props["[dir_key]hide"])
		appearance_list.Cut()
		return
	for(var/mutable_appearance/A as anything in appearance_list)
		apply_custom_piercing_appearance_props(A, props, dir_key)

/// Builds the list of mutable appearances for all stickers the wearer has
/// configured on the given slot. Returns an empty list unless the slot is
/// (a) enabled in the character's custom_piercings config AND (b) backed by
/// a currently-equipped intimate item.
///
/// Returned appearances target CUSTOM_PIERCING_STICKER_ICON and are NOT
/// offset-adjusted against a specific bodypart — callers are expected to feed
/// them through the same appearance-list adjustment pipeline as the legacy
/// intimate overlays (e.g. generic_gender_feature_adjust) so offsets land on
/// the correct body region.
/proc/compose_custom_piercing_slot_appearances(mob/living/carbon/wearer, slot_key)
	var/list/appearances = list()
	if(!ishuman(wearer) || !istext(slot_key))
		return appearances
	var/list/slot_cfg = custom_piercing_get_slot_config_source(wearer, slot_key)
	if(!islist(slot_cfg) || !slot_cfg["enabled"])
		return appearances
	if(!custom_piercing_slot_is_equipped(wearer, slot_key))
		return appearances
	var/list/entries = slot_cfg["entries"]
	if(!islist(entries) || !length(entries))
		return appearances
	var/dir_key = "s"
	switch(wearer.dir)
		if(NORTH)
			dir_key = "n"
		if(EAST)
			dir_key = "e"
		if(WEST)
			dir_key = "w"

	for(var/list/entry in entries)
		var/datum/piercing_sticker/sticker = get_custom_piercing_sticker(entry["sticker"])
		if(!sticker)
			continue
		// Per-entry clothing gate: if the entry pins to a specific body
		// zone and that zone is currently covered, skip its appearances.
		// Empty zone = always visible. Checked here so the gate applies
		// uniformly to both freeform and item-anchored slots.
		var/entry_zone = entry["zone"]
		if(istext(entry_zone) && length(entry_zone))
			if(!get_location_accessible(wearer, entry_zone))
				continue
		var/metal_state = "[sticker.id]_metal"
		// Skip entirely if the metal state is missing from the DMI — prevents
		// an invisible-but-consuming appearance from being added.
		if(!icon_exists(CUSTOM_PIERCING_STICKER_ICON, metal_state))
			continue

		var/list/props = entry["props"]
		if(!islist(props))
			props = default_custom_piercing_props()

		var/metal_color = entry["metal_color"] || CUSTOM_PIERCING_DEFAULT_METAL_COLOR
		var/gem_state = null
		var/gem_color = null
		if(sticker.has_gem && entry["gem_color"])
			gem_state = "[sticker.id]_gem"
			if(icon_exists(CUSTOM_PIERCING_STICKER_ICON, gem_state))
				gem_color = entry["gem_color"]
			else
				gem_state = null

		if(props["[dir_key]hide"])
			continue

		var/mutable_appearance/metal_MA = mutable_appearance(
			CUSTOM_PIERCING_STICKER_ICON,
			metal_state,
			FLOAT_LAYER,
		)
		metal_MA.color = metal_color
		apply_custom_piercing_appearance_props(metal_MA, props, dir_key)
		appearances += metal_MA

		if(gem_state)
			var/mutable_appearance/gem_MA = mutable_appearance(
				CUSTOM_PIERCING_STICKER_ICON,
				gem_state,
				FLOAT_LAYER,
			)
			gem_MA.color = gem_color
			apply_custom_piercing_appearance_props(gem_MA, props, dir_key)
			appearances += gem_MA

	return appearances

/// Returns TRUE if the wearer has a non-empty custom config for the given
/// slot that additionally requests suppression of the legacy overlay.
/// Legacy render paths can consult this before building the hand-fitted
/// overlay and skip it when stickers are set to replace it.
/proc/custom_piercing_slot_suppresses_legacy(mob/living/carbon/wearer, slot_key)
	if(!ishuman(wearer) || !istext(slot_key))
		return FALSE
	var/list/slot_cfg = custom_piercing_get_slot_config_source(wearer, slot_key)
	if(!islist(slot_cfg))
		return FALSE
	return (slot_cfg["enabled"] && slot_cfg["suppress_legacy"]) ? TRUE : FALSE

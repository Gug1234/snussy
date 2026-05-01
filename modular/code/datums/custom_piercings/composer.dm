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
	var/pixel_offset_x = props["[dir_key]x"]
	if(!isnum(pixel_offset_x))
		pixel_offset_x = 0
	var/pixel_offset_y = props["[dir_key]y"]
	if(!isnum(pixel_offset_y))
		pixel_offset_y = 0
	MA.pixel_x = pixel_offset_x
	MA.pixel_y = pixel_offset_y
	var/shrink = props["[dir_key]shrink"]
	if(!isnum(shrink) || shrink <= 0)
		shrink = 1.0
	var/turn_deg = props["[dir_key]turn"]
	if(!isnum(turn_deg))
		turn_deg = 0
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
	return appearance_preview_dir_to_key(dir)

/**
 * Builds hybrid-overlay guide layers for a whitelisted sticker datum.
 *
 * Arguments:
 *   sticker        - /datum/piercing_sticker from GLOB.custom_piercing_stickers.
 *   metal_color    - optional sanitized/unsanitized metal color.
 *   gem_color      - optional sanitized/unsanitized gem color.
 *   include_colors - when TRUE, attach sanitized color hints to the guide
 *                    layers. Registry prototype metadata passes FALSE so the
 *                    client can apply draft colors locally without accepting
 *                    arbitrary icon states from TGUI.
 *
 * Returns a list of hybrid descriptor layer lists. The metal layer is required;
 * if the source DMI lacks the metal state the result is empty. The gem layer is
 * included only when the sticker says it supports gems and the DMI contains the
 * server-resolved gem state.
 */
/proc/custom_piercing_build_sticker_hybrid_guide_layers(datum/piercing_sticker/sticker, metal_color = null, gem_color = null, include_colors = TRUE)
	var/list/layers = list()
	if(!istype(sticker))
		return layers

	var/metal_state = sticker.get_preview_manifest_metal_icon_state_key()
	if(!metal_state || !icon_exists(CUSTOM_PIERCING_STICKER_ICON, metal_state))
		return layers
	var/list/metal_layer = list(
		HYBRID_OFFSET_LAYER_KEY_ICON_STATE = metal_state,
		HYBRID_OFFSET_LAYER_KEY_ROLE = HYBRID_OFFSET_LAYER_ROLE_METAL,
	)
	if(include_colors)
		metal_layer[HYBRID_OFFSET_LAYER_KEY_COLOR] = sanitize_hexcolor(metal_color, 6, TRUE, CUSTOM_PIERCING_DEFAULT_METAL_COLOR)
	layers += list(metal_layer)

	var/gem_state = sticker.get_preview_manifest_gem_icon_state_key()
	if(gem_state && icon_exists(CUSTOM_PIERCING_STICKER_ICON, gem_state))
		var/list/gem_layer = list(
			HYBRID_OFFSET_LAYER_KEY_ICON_STATE = gem_state,
			HYBRID_OFFSET_LAYER_KEY_ROLE = HYBRID_OFFSET_LAYER_ROLE_GEM,
		)
		if(include_colors)
			gem_layer[HYBRID_OFFSET_LAYER_KEY_COLOR] = sanitize_hexcolor(gem_color, 6, TRUE, CUSTOM_PIERCING_DEFAULT_GEM_COLOR)
		layers += list(gem_layer)

	return layers

/**
 * Builds hybrid-overlay guide layers from a stored custom piercing entry.
 *
 * The entry is re-sanitized before layer generation, which means forged or
 * stale sidecar data must still pass through the registry whitelist before any
 * icon_state can be emitted to TGUI.
 */
/proc/custom_piercing_build_entry_hybrid_guide_layers(list/entry)
	var/list/cleaned = sanitize_custom_piercing_entry(entry)
	if(!islist(cleaned))
		return list()
	var/datum/piercing_sticker/sticker = get_custom_piercing_sticker(cleaned["sticker"])
	if(!sticker)
		return list()
	return custom_piercing_build_sticker_hybrid_guide_layers(sticker, cleaned["metal_color"], cleaned["gem_color"])

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

/**
 * Returns TRUE when a preview dummy should omit one selected custom-piercing
 * entry from its normal DM-rendered custom-piercing overlays.
 *
 * Live mobs leave `custom_piercing_preview_suppressed_target_key` null, so this
 * helper is inert outside the appearance-preview dummy path. The target key is
 * parsed through the same whitelist-aware `slot:index` contract used by hybrid
 * guide descriptors, preventing arbitrary TGUI strings from hiding unrelated
 * entries.
 */
/proc/custom_piercing_entry_is_preview_suppressed(mob/living/carbon/wearer, slot_key, entry_index)
	if(!ishuman(wearer) || !istext(slot_key) || !isnum(entry_index))
		return FALSE
	if(entry_index != round(entry_index))
		return FALSE
	var/mob/living/carbon/human/H = wearer
	var/list/target = custom_piercing_parse_hybrid_target_key(H.custom_piercing_preview_suppressed_target_key)
	if(!islist(target))
		return FALSE
	return target["slot_key"] == slot_key && target["entry_index"] == round(entry_index)

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

	for(var/i in 1 to entries.len)
		if(custom_piercing_entry_is_preview_suppressed(wearer, slot_key, i))
			continue
		var/list/entry = entries[i]
		if(!islist(entry))
			continue
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
		var/metal_state = sticker.get_preview_manifest_metal_icon_state_key()
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
			gem_state = sticker.get_preview_manifest_gem_icon_state_key()
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

/// Canonical cardinal directions used by the taur genital props schema.
/// Keep order stable — TGUI tabs iterate this list.
GLOBAL_LIST_INIT(taur_genital_dir_keys, list("s", "n", "e", "w"))
/// Canonical per-part keys. Used by the editor and savefile migration.
GLOBAL_LIST_INIT(taur_genital_part_keys, list("penis", "testicles", "vagina"))
/// Per-direction field keys inside a taur-genital props list.
/// Schema matches /obj/item/proc/getonmobprop — plus per-part/per-dir `hide`.
///   x/y      : pixel_x / pixel_y offset, -64..64
///   turn     : rotation degrees, signed -359..359
///   flip     : horizontal mirror (scale -1), 0 or 1
///   above    : layer override — 0 = BODY_BEHIND, 1 = BODY_FRONT
///   hide     : omit the overlay entirely for this direction, 0 or 1
///   shrink   : scale factor, 0.1..4.0 (1.0 = native size)
GLOBAL_LIST_INIT(taur_genital_field_keys, list("x", "y", "turn", "flip", "above", "hide", "shrink"))
/// Penis-only arousal states. Order must stay stable for the editor tabs.
GLOBAL_LIST_INIT(taur_genital_erect_state_keys, list(ERECT_STATE_NONE, ERECT_STATE_PARTIAL, ERECT_STATE_HARD))
GLOBAL_LIST_INIT(taur_genital_erect_state_labels, list(
	"[ERECT_STATE_NONE]" = "Flaccid",
	"[ERECT_STATE_PARTIAL]" = "Partial",
	"[ERECT_STATE_HARD]" = "Hard",
))

/// Per-part default `above` (whether the sprite draws over the body).
/// Vaginas default to FRONT so they overlay the rear properly; penises and testicles
/// default to BEHIND so they tuck under the taur body from the front view.
/proc/default_taur_genital_above_for(part)
	switch(part)
		if("vagina")
			return 1
	return 0

/// Returns a freshly allocated default props list for the given part.
/// Callers MUST NOT share the returned list across multiple parts — each call
/// returns an independent list so edits to one part don't bleed into another.
/proc/default_taur_genital_props(part = "")
	var/above = default_taur_genital_above_for(part)
	. = list()
	for(var/dir_key in GLOB.taur_genital_dir_keys)
		.["[dir_key]x"] = 0
		.["[dir_key]y"] = 0
		.["[dir_key]turn"] = 0
		.["[dir_key]flip"] = 0
		.["[dir_key]above"] = above
		.["[dir_key]hide"] = 0
		.["[dir_key]shrink"] = 1.0

/// Sanitizes a loaded props list in-place: ensures all schema keys exist with correct
/// defaults, clamps numeric ranges, and drops unknown keys. Safe to call with null.
/proc/sanitize_taur_genital_props(list/props, part = "")
	var/list/defaults = default_taur_genital_props(part)
	if(!islist(props))
		return defaults
	var/list/out = list()
	for(var/dir_key in GLOB.taur_genital_dir_keys)
		var/xk = "[dir_key]x"
		var/yk = "[dir_key]y"
		var/tk = "[dir_key]turn"
		var/fk = "[dir_key]flip"
		var/ak = "[dir_key]above"
		var/hk = "[dir_key]hide"
		var/sk = "[dir_key]shrink"
		out[xk] = clamp(round(text2num_safe(props[xk], defaults[xk])), TAUR_GENITAL_OFFSET_MIN, TAUR_GENITAL_OFFSET_MAX)
		out[yk] = clamp(round(text2num_safe(props[yk], defaults[yk])), TAUR_GENITAL_OFFSET_MIN, TAUR_GENITAL_OFFSET_MAX)
		out[tk] = clamp(round(text2num_safe(props[tk], defaults[tk])), -359, 359)
		out[fk] = text2num_safe(props[fk], defaults[fk]) ? 1 : 0
		out[ak] = text2num_safe(props[ak], defaults[ak]) ? 1 : 0
		out[hk] = text2num_safe(props[hk], defaults[hk]) ? 1 : 0
		var/shrink = text2num_safe(props[sk], defaults[sk])
		if(!isnum(shrink))
			shrink = 1.0
		out[sk] = clamp(shrink, 0.1, 4.0)
	return out

/// Returns the default per-arousal-state penis offset map.
/proc/default_taur_penis_erect_state_props()
	. = list()
	for(var/erect_state in GLOB.taur_genital_erect_state_keys)
		.["[erect_state]"] = default_taur_genital_props("penis")

/// Sanitizes the penis arousal-state map. Legacy flat penis props are used as the
/// fallback for any missing state, so old saves migrate cleanly.
/proc/sanitize_taur_penis_erect_state_props(list/state_props, list/fallback_props = null)
	var/list/fallback = sanitize_taur_genital_props(fallback_props, "penis")
	if(!islist(state_props))
		. = list()
		for(var/erect_state in GLOB.taur_genital_erect_state_keys)
			.["[erect_state]"] = fallback.Copy()
		return
	. = list()
	for(var/erect_state in GLOB.taur_genital_erect_state_keys)
		var/state_key = "[erect_state]"
		var/list/state_entry = state_props[state_key]
		if(!islist(state_entry))
			state_entry = fallback
		.[state_key] = sanitize_taur_genital_props(state_entry, "penis")

/// Returns the penis props for a specific arousal state, falling back to the
/// legacy flat penis props if a nested state list is missing.
/proc/get_taur_penis_props_for_state(mob/living/carbon/human/H, erect_state = ERECT_STATE_NONE)
	if(!istype(H))
		return null
	H.taur_penis_props = sanitize_taur_genital_props(H.taur_penis_props, "penis")
	H.taur_penis_erect_state_props = sanitize_taur_penis_erect_state_props(H.taur_penis_erect_state_props, H.taur_penis_props)
	var/state_num = clamp(round(text2num_safe(erect_state, ERECT_STATE_NONE)), ERECT_STATE_NONE, ERECT_STATE_HARD)
	var/list/props = H.taur_penis_erect_state_props["[state_num]"]
	if(islist(props))
		return props
	return H.taur_penis_props

/// Returns the default global-hide list (one entry per cardinal direction, all zero).
/proc/default_taur_genital_global_hide()
	. = list()
	for(var/dir_key in GLOB.taur_genital_dir_keys)
		.[dir_key] = 0

/// Sanitizes the global-hide list in place. Safe to call with null.
/proc/sanitize_taur_genital_global_hide(list/hides)
	var/list/out = default_taur_genital_global_hide()
	if(islist(hides))
		for(var/dir_key in GLOB.taur_genital_dir_keys)
			out[dir_key] = text2num_safe(hides[dir_key], 0) ? 1 : 0
	return out

/// Safe text2num that falls back to a default when the value is null or unparseable.
/proc/text2num_safe(val, default_val = 0)
	if(isnum(val))
		return val
	if(istext(val))
		var/n = text2num(val)
		if(!isnull(n))
			return n
	return default_val

/// Returns the canonical dir key ("n"/"s"/"e"/"w") for a BYOND dir constant.
/proc/taur_dir_to_key(dir)
	switch(dir)
		if(NORTH)
			return "n"
		if(EAST)
			return "e"
		if(WEST)
			return "w"
	return "s"

/**
 * Applies per-genital-type pixel offsets, layering, rotation, mirroring, hiding, and
 * scaling to any appearance list. Uses the per-direction props-list schema that matches
 * /obj/item/proc/getonmobprop: every field is keyed by direction so players can tune
 * each cardinal facing independently.
 *
 * Called by vagina, penis, and testicles adjust_appearance_list overrides when the owner
 * has a taur bodypart AND use_taur_genital_sprites is enabled.
 *
 * If the part is hidden for the current direction (per-part hide OR global per-dir hide),
 * the appearance_list is CLEARED in place and the proc returns early.
 *
 * Reads props from mob vars first (set by copy_to), falling back to client prefs so
 * clientless mannequins (lobby preview) use the correct values.
 *
 * @param appearance_list  The list of mutable_appearance overlays to adjust in place.
 * @param owner            The carbon mob whose prefs/vars are consulted.
 * @param genital_type     One of "vagina", "penis", or "testicles".
 * @param organ            Optional organ used to read the penis erect state.
 */
/proc/apply_taur_genital_offsets(list/appearance_list, mob/living/carbon/owner, genital_type = "", obj/item/organ/organ = null)
	if(!islist(appearance_list) || !length(appearance_list) || !owner)
		return
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return

	var/dir_key = taur_dir_to_key(owner.dir)

	// Global per-dir hide: wipe every taur genital overlay for this direction.
	var/list/global_hide = sanitize_taur_genital_global_hide(H.taur_genital_global_hide)
	if(global_hide[dir_key])
		appearance_list.Cut()
		return

	// Pull the part's props list (lazily sanitized so legacy/null data still works).
	var/list/props
	switch(genital_type)
		if("penis")
			var/obj/item/organ/penis/penis_organ = organ
			props = get_taur_penis_props_for_state(H, penis_organ?.erect_state)
		if("testicles")
			props = H.taur_testicles_props
		if("vagina")
			props = H.taur_vagina_props
	props = sanitize_taur_genital_props(props, genital_type)

	// Per-part per-dir hide.
	if(props["[dir_key]hide"])
		appearance_list.Cut()
		return

	var/ox = props["[dir_key]x"]
	var/oy = props["[dir_key]y"]
	var/rot = props["[dir_key]turn"]
	var/flip = props["[dir_key]flip"]
	var/above = props["[dir_key]above"]
	var/shrink = props["[dir_key]shrink"]

	var/matrix/xform = null
	if(flip || rot || (shrink != 1.0))
		xform = matrix()
		if(shrink != 1.0)
			xform.Scale(shrink, shrink)
		if(flip)
			xform.Scale(-1, 1)
		if(rot)
			xform.Turn(rot)

	var/target_layer = above ? -BODY_FRONT_LAYER : -BODY_BEHIND_LAYER

	for(var/mutable_appearance/A as anything in appearance_list)
		A.pixel_x += ox
		A.pixel_y += oy
		if(xform)
			A.transform = xform
		A.layer = target_layer

/**
 * Generates genital overlays using a taur-specific DMI icon file.
 *
 * Mirrors the logic of /datum/sprite_accessory/get_overlay but uses the provided taur icon
 * file instead of the accessory's default `icon` var. Cached under a "taur-" prefixed key
 * so taur and non-taur versions coexist without collision.
 *
 * @param accessory        The sprite accessory datum whose settings (layers, pixel offsets,
 *                         color_keys, extra_state) are used for generation.
 * @param taur_icon_file   The taur-specific DMI file to use (e.g. 'icons/mob/sprite_accessory/genitals/taur_pintle.dmi').
 * @param overlay_icon_state  The computed icon state (from get_icon_state).
 * @param color_string     The pipe-delimited color string for colorisation.
 * @return                 A list of mutable_appearance overlays, or null.
 */
/proc/generate_taur_genital_overlay(datum/sprite_accessory/accessory, taur_icon_file, overlay_icon_state, color_string)
	color_string = accessory.sanitize_color_string(color_string)
	var/key = "taur-[accessory.type]-[overlay_icon_state]-[color_string]"
	if(!accessory.accessory_icon_cache[key])
		// Temporarily swap icon to taur file for generate_icon_states
		var/saved_icon = accessory.icon
		accessory.icon = taur_icon_file
		var/list/icon_states = accessory.generate_icon_states(overlay_icon_state, color_string)
		accessory.icon = saved_icon
		var/icon/icon_bundle = icon('icons/Testing/greyscale_error.dmi')
		for(var/state in icon_states)
			icon_bundle.Insert(icon_states[state], state)
		accessory.accessory_icon_cache[key] = icon_bundle

	var/icon/cached_icon = icon(accessory.accessory_icon_cache[key])
	var/list/appearance_list = list()
	if(accessory.relevant_layers)
		for(var/iterated_layer in accessory.relevant_layers)
			var/mutable_appearance/appearance = mutable_appearance(cached_icon, "[overlay_icon_state]_[accessory.get_layer_suffix(iterated_layer)]", layer = -iterated_layer)
			appearance.pixel_x = accessory.pixel_x
			appearance.pixel_y = accessory.pixel_y
			appearance_list += appearance
	else
		var/mutable_appearance/appearance = mutable_appearance(cached_icon, overlay_icon_state, layer = -accessory.layer)
		appearance.pixel_x = accessory.pixel_x
		appearance.pixel_y = accessory.pixel_y
		appearance_list += appearance
	return appearance_list

/// Returns TRUE if the given mob has the taur genital sprites toggle enabled.
/// Falls back to mob vars when the owner has no client (e.g. lobby preview mannequin).
/proc/owner_uses_taur_sprites(mob/living/carbon/owner)
	if(!owner?.get_taur_tail())
		return FALSE
	// Try client prefs first (live gameplay)
	var/datum/preferences/prefs = owner.client?.prefs
	if(prefs)
		return prefs.use_taur_genital_sprites
	// Clientless fallback (mannequin preview) — check mob var
	var/mob/living/carbon/human/H = owner
	if(istype(H))
		return H.use_taur_genital_sprites
	return FALSE

/// Hides the penis sprite while a chastity device is blocking front access.
/// Covers all penis morphologies — normal cock, sheaths (SHEATH_TYPE_NORMAL), and genital slits
/// (SHEATH_TYPE_SLIT) — all blocked by the same cage/full/penis-blocked traits since they are all
/// penis-type anatomy. Cursed modes 1 and 3 expose front access regardless.
/// Falls through to the upstream visibility check (underwear, HIDEJUMPSUIT, HIDECROTCH) if not blocked.
/datum/sprite_accessory/penis/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/chastity/device = owner?.chastity_device
	if(device)
		if(device.chastity_cursed)
			// Cursed modes 1 and 3 expose penis/sheath/slit access.
			if(!(device.cursed_front_mode == 1 || device.cursed_front_mode == 3))
				return FALSE
		else
			if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(owner, TRAIT_CHASTITY_PENIS_BLOCKED))
				return FALSE
	else
		if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(owner, TRAIT_CHASTITY_PENIS_BLOCKED))
			return FALSE
	if(owner.sexcon && owner.sexcon.bottom_exposed == TRUE)
		return TRUE
	if(owner.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDEJUMPSUIT|HIDECROTCH)

/// When taur genital sprites are enabled, swaps the icon file to taur_gonads.dmi.
/datum/sprite_accessory/testicles/get_appearance(obj/item/organ/organ, obj/item/bodypart/bodypart, color_string)
	var/mob/living/carbon/owner = organ?.owner || bodypart?.owner
	if(owner_uses_taur_sprites(owner))
		if(!is_visible(organ, bodypart, owner))
			return
		var/icon_state_to_use = get_icon_state(organ, bodypart, owner)
		if(!icon_state_to_use)
			return null
		var/list/appearance_list = generate_taur_genital_overlay(src, file("modular/icons/obj/lewd/taur_gonads.dmi"), icon_state_to_use, color_string)
		adjust_appearance_list(appearance_list, organ, bodypart, owner)
		return appearance_list
	return ..()

/// Reorders testicle layers when a cage-type device is worn so they sit beneath the cage overlay.
/// Also applies taur-body pixel offsets when the owner has taur sprites enabled.
/datum/sprite_accessory/testicles/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)
	if(owner_uses_taur_sprites(owner))
		apply_taur_genital_offsets(appearance_list, owner, "testicles")
	if(!chastity_shows_testicles(owner))
		return

	// Keep exposed testicles under cage/flat-cage overlays while still above body base.
	for(var/mutable_appearance/appearance as anything in appearance_list)
		appearance.layer = min(appearance.layer, -44.6)

/// Returns TRUE if the wearer's chastity device has a cage or flat-cage sprite that renders the sack visible.
/// Used to gate both layer reordering in adjust_appearance_list and the is_visible cage-blocked exception.
/datum/sprite_accessory/testicles/proc/chastity_shows_testicles(mob/living/carbon/owner)
	var/obj/item/chastity/device = owner?.chastity_device
	if(!device)
		return FALSE
	return (device.sprite_acc == /datum/sprite_accessory/chastity/cage) || (device.sprite_acc == /datum/sprite_accessory/chastity/flat)

/datum/sprite_accessory/testicles/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/organ/penis/pp = owner.getorganslot(ORGAN_SLOT_PENIS)
	if(pp && pp.sheath_type == SHEATH_TYPE_SLIT)
		return FALSE
	if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL))
		return FALSE
	if((HAS_TRAIT(owner, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(owner, TRAIT_CHASTITY_PENIS_BLOCKED)) && !chastity_shows_testicles(owner))
		return FALSE
	if(owner.sexcon && owner.sexcon.bottom_exposed == TRUE)
		return TRUE
	if(owner.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDEJUMPSUIT|HIDECROTCH)

/// Hides the vagina sprite while a chastity device is blocking front access.
/// Respects cursed mode: modes 2 and 3 expose the vagina regardless of the device being worn.
/// Falls through to the upstream visibility check (underwear, HIDECROTCH, HIDEJUMPSUIT) if not blocked.
/datum/sprite_accessory/vagina/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/chastity/device = owner?.chastity_device
	if(device)
		if(device.chastity_cursed)
			// Cursed mode 2 and 3 expose vagina access.
			if(!(device.cursed_front_mode == 2 || device.cursed_front_mode == 3))
				return FALSE
		else
			if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_VAGINA_BLOCKED))
				return FALSE
	else
		if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_VAGINA_BLOCKED))
			return FALSE
	if(owner.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDECROTCH|HIDEJUMPSUIT)

/datum/sprite_accessory/penis
	icon = 'icons/mob/sprite_accessory/genitals/pintle.dmi'
	color_keys = 2
	color_key_names = list("Member", "Skin")
	relevant_layers = list(BODY_BEHIND_LAYER, BODY_FRONT_LAYER) //Vrell - Yes I know this is hacky but it works for now
	var/uses_size_sprites = TRUE

/// When taur genital sprites are enabled, swaps the icon file to taur_pintle.dmi before
/// generating overlays — uses a separate cache key so both versions coexist.
/datum/sprite_accessory/penis/get_appearance(obj/item/organ/organ, obj/item/bodypart/bodypart, color_string)
	var/mob/living/carbon/owner = organ?.owner || bodypart?.owner
	if(owner_uses_taur_sprites(owner))
		if(!is_visible(organ, bodypart, owner))
			return
		var/icon_state_to_use = get_icon_state(organ, bodypart, owner)
		if(!icon_state_to_use)
			return null
		var/list/appearance_list = generate_taur_genital_overlay(src, file("modular/icons/obj/lewd/taur_pintle.dmi"), icon_state_to_use, color_string)
		adjust_appearance_list(appearance_list, organ, bodypart, owner)
		return appearance_list
	return ..()

/// Applies species belt offsets and, when the owner has a taur body with taur sprites,
/// adds player-configured pixel offsets and automatic behind-body layering for the penis sprite.
/datum/sprite_accessory/penis/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)
	if(owner_uses_taur_sprites(owner))
		apply_taur_genital_offsets(appearance_list, owner, "penis", organ)

/datum/sprite_accessory/penis/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/organ/penis/pp = organ
	if(pp.sheath_type != SHEATH_TYPE_NONE && pp.erect_state != ERECT_STATE_HARD)
		switch(pp.sheath_type)
			if(SHEATH_TYPE_NORMAL)
				if(pp.erect_state == ERECT_STATE_NONE)
					return "sheath_1"
				else
					return "sheath_2"
			if(SHEATH_TYPE_SLIT)
				if(pp.erect_state == ERECT_STATE_NONE)
					return "slit_1"
				else
					return "slit_2"

	if(uses_size_sprites)
		if(pp.erect_state == ERECT_STATE_HARD)
			return "[icon_state]_2_[min(pp.penis_size, 2)]"
		else
			return "[icon_state]_1_[min(pp.penis_size, 2)]"
	else
		if(pp.erect_state == ERECT_STATE_HARD)
			return "[icon_state]_2"
		else
			return "[icon_state]_1"

/datum/sprite_accessory/penis/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/chastity/device = owner?.chastity_device
	if(device)
		if(device.chastity_cursed)
			// Cursed mode 1 and 3 expose penis access.
			if(!(device.cursed_front_mode == 1 || device.cursed_front_mode == 3))
				return FALSE
		else
			if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(owner, TRAIT_CHASTITY_PENIS_BLOCKED))
				return FALSE
	else
		if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(owner, TRAIT_CHASTITY_PENIS_BLOCKED))
			return FALSE
	if(owner.sexcon && owner.sexcon.bottom_exposed == TRUE)
		return TRUE
	if(owner.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDEJUMPSUIT|HIDECROTCH)

/datum/sprite_accessory/penis/human
	icon_state = "human"
	name = "Plain"
	color_key_defaults = list(KEY_CHEST_COLOR, KEY_CHEST_COLOR)

/datum/sprite_accessory/penis/knotted
	icon_state = "knotted"
	name = "Knotted"
	color_key_defaults = list(null, KEY_CHEST_COLOR)
	default_colors = list("C52828", null)

/datum/sprite_accessory/penis/flared
	icon_state = "flared"
	name = "Flared"
	color_key_defaults = list(KEY_CHEST_COLOR, KEY_CHEST_COLOR)

/datum/sprite_accessory/penis/flared_knotted
	icon_state = "flared"
	name = "Flared, Knotted"
	color_key_defaults = list(KEY_CHEST_COLOR, KEY_CHEST_COLOR)

/datum/sprite_accessory/penis/barbknot
	icon_state = "barbknot"
	name = "Barbed, Knotted"
	color_key_defaults = list(null, KEY_CHEST_COLOR)
	default_colors = list("C52828", null)

/datum/sprite_accessory/penis/tapered
	icon_state = "tapered"
	name = "Tapered"
	default_colors = list("C52828", "C52828")

/datum/sprite_accessory/penis/taperedknot
	icon_state = "tapered"
	name = "Tapered, Knotted"
	default_colors = list("C52828", "C52828")

/datum/sprite_accessory/penis/taperedknot_mammal
	icon_state = "taperedknot"
	name = "Tapered, Knotted"
	color_key_defaults = list(null, KEY_CHEST_COLOR)
	default_colors = list("C52828", null)

/datum/sprite_accessory/penis/tapered_mammal
	icon_state = "tapered"
	name = "Tapered"
	color_key_defaults = list(null, KEY_CHEST_COLOR)
	default_colors = list("C52828", null)

/datum/sprite_accessory/penis/tentacle
	icon_state = "tentacle"
	name = "Tentacled"
	default_colors = list("C52828", "C52828")

/datum/sprite_accessory/penis/hemi
	icon_state = "hemi"
	name = "Hemi"
	default_colors = list("C52828", "C52828")

/datum/sprite_accessory/penis/hemi_mammal
	icon_state = "hemi"
	name = "Hemi"
	color_key_defaults = list(null, KEY_CHEST_COLOR)
	default_colors = list("C52828", null)

/datum/sprite_accessory/penis/hemiknot
	icon_state = "hemiknot"
	name = "Knotted Hemi"
	default_colors = list("C52828", "C52828")

/datum/sprite_accessory/testicles
	icon = 'icons/mob/sprite_accessory/genitals/gonads.dmi'
	color_key_name = "Sack"
	relevant_layers = list(BODY_ADJ_LAYER, BODY_BEHIND_LAYER)

/datum/sprite_accessory/testicles/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)
	if(owner_uses_taur_sprites(owner))
		apply_taur_genital_offsets(appearance_list, owner, "testicles")
	if(!chastity_shows_testicles(owner))
		return

	// Keep exposed testicles under cage/flat-cage overlays while still above body base.
	for(var/mutable_appearance/appearance as anything in appearance_list)
		appearance.layer = min(appearance.layer, -44.6)

/datum/sprite_accessory/testicles/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/organ/testicles/testes = organ
	return "[icon_state]_[testes.ball_size]"

/datum/sprite_accessory/testicles/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/organ/penis/pp = owner.getorganslot(ORGAN_SLOT_PENIS)
	if(pp && pp.sheath_type == SHEATH_TYPE_SLIT)
		return FALSE
	if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL))
		return FALSE
	if((HAS_TRAIT(owner, TRAIT_CHASTITY_CAGE) || HAS_TRAIT(owner, TRAIT_CHASTITY_PENIS_BLOCKED)) && !chastity_shows_testicles(owner))
		return FALSE
	if(owner.sexcon && owner.sexcon.bottom_exposed == TRUE)
		return TRUE
	if(owner.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDEJUMPSUIT|HIDECROTCH)

/datum/sprite_accessory/testicles/pair
	name = "Pair"
	icon_state = "pair"
	color_key_defaults = list(KEY_SKIN_COLOR)

/datum/sprite_accessory/breasts
	icon = 'icons/mob/sprite_accessory/genitals/breasts.dmi'
	color_key_name = "Breasts"
	relevant_layers = list(BODY_ADJ_LAYER, BODY_BEHIND_LAYER)

/datum/sprite_accessory/breasts/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/organ/breasts/badonkers = organ
	return "[icon_state]_[badonkers.breast_size]"

/datum/sprite_accessory/breasts/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BREASTS, OFFSET_BREASTS_F)

/datum/sprite_accessory/breasts/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(owner.underwear && owner.underwear.covers_breasts)
		return FALSE
	return is_human_part_visible(owner, HIDEBOOB|HIDEJUMPSUIT)

/datum/sprite_accessory/breasts/pair
	icon_state = "pair"
	name = "Pair"
	color_key_defaults = list(KEY_CHEST_COLOR)

/datum/sprite_accessory/breasts/quad
	icon_state = "quad"
	name = "Quad"
	color_key_defaults = list(KEY_CHEST_COLOR)

/datum/sprite_accessory/breasts/sextuple
	icon_state = "sextuple"
	name = "Sextuple"
	color_key_defaults = list(KEY_CHEST_COLOR)

/datum/sprite_accessory/vagina
	icon = 'icons/mob/sprite_accessory/genitals/nethers.dmi'
	color_key_name = "Nethers"
	relevant_layers = list(BODY_FRONT_LAYER)

/// When taur genital sprites are enabled, swaps the icon file to taur_nethers.dmi.
/datum/sprite_accessory/vagina/get_appearance(obj/item/organ/organ, obj/item/bodypart/bodypart, color_string)
	var/mob/living/carbon/owner = organ?.owner || bodypart?.owner
	if(owner_uses_taur_sprites(owner))
		if(!is_visible(organ, bodypart, owner))
			return
		var/icon_state_to_use = get_icon_state(organ, bodypart, owner)
		if(!icon_state_to_use)
			return null
		var/list/appearance_list = generate_taur_genital_overlay(src, file("modular/icons/obj/lewd/taur_nethers.dmi"), icon_state_to_use, color_string)
		adjust_appearance_list(appearance_list, organ, bodypart, owner)
		return appearance_list
	return ..()

/// Applies species belt offsets and, when the owner has a taur body with taur sprites,
/// adds player-configured pixel offsets and automatic front-layer placement for the vagina sprite.
/datum/sprite_accessory/vagina/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)
	if(owner_uses_taur_sprites(owner))
		apply_taur_genital_offsets(appearance_list, owner, "vagina")

/datum/sprite_accessory/vagina/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/obj/item/chastity/device = owner?.chastity_device
	if(device)
		if(device.chastity_cursed)
			// Cursed mode 2 and 3 expose vagina access.
			if(!(device.cursed_front_mode == 2 || device.cursed_front_mode == 3))
				return FALSE
		else
			if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_VAGINA_BLOCKED))
				return FALSE
	else
		if(HAS_TRAIT(owner, TRAIT_CHASTITY_FULL) || HAS_TRAIT(owner, TRAIT_CHASTITY_VAGINA_BLOCKED))
			return FALSE
	if(owner.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDECROTCH|HIDEJUMPSUIT)

/datum/sprite_accessory/vagina/human
	icon_state = "human"
	name = "Plain"
	default_colors = list("ea6767")

/datum/sprite_accessory/vagina/hairy
	icon_state = "hairy"
	name = "Hairy"
	color_key_defaults = list(KEY_HAIR_COLOR)

/datum/sprite_accessory/vagina/spade
	icon_state = "spade"
	name = "Spade"
	default_colors = list("C52828")

/datum/sprite_accessory/vagina/furred
	icon_state = "furred"
	name = "Furred"
	color_key_defaults = list(KEY_MUT_COLOR_ONE)

/datum/sprite_accessory/vagina/gaping
	icon_state = "gaping"
	name = "Gaping"
	default_colors = list("f99696")

/datum/sprite_accessory/vagina/cloaca
	icon_state = "cloaca"
	name = "Cloaca"
	default_colors = list("f99696")

/datum/sprite_accessory/vagina/trimmed
	icon_state = "trimmed"
	name = "Trimmed"
	default_colors = list("f99696")

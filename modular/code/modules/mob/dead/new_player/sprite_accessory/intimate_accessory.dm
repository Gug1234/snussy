/datum/sprite_accessory/intimate_accessory
	abstract_type = /datum/sprite_accessory/intimate_overlays
	icon = 'modular/icons/obj/lewd/intimate_overlays.dmi'
	color_keys = 2
	color_key_names = list("Metal", "Gem")
	default_colors = list("#9BADB7", "#55D6FF")
	var/intimate_type = /obj/item/intimate_accessory
	var/list/short_anthro_size_zero_species = list(
		/datum/species/anthromorphsmall,
		/datum/species/kobold,
		/datum/species/dwarf,
		/datum/species/dwarf/gnome,
		/datum/species/goblinp,
		/datum/species/goblin,
	)

/datum/sprite_accessory/intimate_overlays
	parent_type = /datum/sprite_accessory/intimate_accessory
	abstract_type = /datum/sprite_accessory/intimate_overlays

/datum/sprite_accessory/intimate_accessory/proc/get_body_suffix(mob/living/carbon/owner)
	var/datum/species/species = owner?.dna?.species
	if(species?.clothes_id == "dwarf")
		return owner.gender == FEMALE ? "d_f" : "d_m"
	if(is_species(owner, /datum/species/elf) && owner.gender == MALE)
		return "e_m"
	return owner.gender == FEMALE ? "h_f" : "h_m"

/datum/sprite_accessory/intimate_accessory/proc/get_breast_piercing_icon_state(mob/living/carbon/owner)
	var/amount_tag = "pair"
	var/breast_size = 0
	var/obj/item/organ/breasts/breasts = owner?.getorganslot(ORGAN_SLOT_BREASTS)
	if(breasts)
		breast_size = breasts.breast_size
		if(ispath(breasts.accessory_type, /datum/sprite_accessory/breasts/quad))
			amount_tag = "quad"
		else if(ispath(breasts.accessory_type, /datum/sprite_accessory/breasts/sextuple))
			amount_tag = "sextuple"

	if(amount_tag == "pair")
		breast_size = clamp(breast_size, 0, 12)
		if(breast_size == 0)
			if(is_species(owner, /datum/species/goblinp))
				return owner.gender == FEMALE ? "breast_pierce_pair_0gf" : "breast_pierce_pair_0g"
			if(owner.gender == FEMALE && is_species(owner, /datum/species/dwarf))
				return "breast_pierce_pair_0df"
			for(var/species_type in short_anthro_size_zero_species)
				if(is_species(owner, species_type))
					return "breast_pierce_pair_0sf"
			return "breast_pierce_pair_0"
	else
		breast_size = clamp(breast_size, 0, 5)

	return "breast_pierce_[amount_tag]_[breast_size]"

/datum/sprite_accessory/intimate_accessory/proc/get_genital_piercing_overlay(overlay_icon_state, color_string, passed_layer)
	color_string = sanitize_color_string(color_string)
	var/cache_key = "[type]-genital-[overlay_icon_state]-[color_string]"
	if(!accessory_icon_cache[cache_key])
		var/list/color_list = color_string_to_list(color_string)
		accessory_icon_cache[cache_key] = generate_genital_piercing_icon_state(overlay_icon_state, color_list)

	var/icon/cached_icon = icon(accessory_icon_cache[cache_key])
	var/mutable_appearance/appearance = mutable_appearance(cached_icon, overlay_icon_state, layer = -passed_layer)
	appearance.pixel_x = pixel_x
	appearance.pixel_y = pixel_y
	return appearance

/datum/sprite_accessory/intimate_accessory/proc/generate_genital_piercing_icon_state(overlay_icon_state, color_list)
	var/metal_color = color_list[1]
	if(!metal_color)
		metal_color = "#FFFFFF"

	var/gem_color = color_list[2]
	if(!gem_color)
		gem_color = metal_color

	var/icon/result_icon = icon(icon, overlay_icon_state)
	result_icon.Blend(metal_color, ICON_MULTIPLY)

	if(icon_exists(icon, "[overlay_icon_state]_gem"))
		var/icon/gem_mask_icon = icon(icon, "[overlay_icon_state]_gem")
		gem_mask_icon.Blend(gem_color, ICON_MULTIPLY)
		result_icon.Blend(gem_mask_icon, ICON_OVERLAY)

	if(extra_state && icon_exists(icon, "[overlay_icon_state]_extra"))
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

/datum/sprite_accessory/intimate_accessory/proc/generate_untinted_icon_state(overlay_icon_state, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"
	if(!icon_exists(icon, overlay_icon_state))
		return null

	var/icon/result_icon = icon(icon, overlay_icon_state)
	if(extra_state && icon_exists(icon, "[overlay_icon_state]_extra"))
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

/datum/sprite_accessory/intimate_accessory/proc/get_special_genital_overlay_state(mob/living/carbon/owner, overlay_prefix, base_icon_state, layer_suffix)
	var/overlay_icon_state = "[overlay_prefix]_[base_icon_state]_[layer_suffix]"
	if(overlay_prefix != "vagina_pierce" || !ishuman(owner))
		return overlay_icon_state

	var/mob/living/carbon/human/H = owner
	if(istype(H.intimate_genital, /obj/item/intimate_accessory/piercing/genital/psydonic))
		var/psydonic_state = "[overlay_icon_state]_psy"
		if(icon_exists(icon, psydonic_state))
			return psydonic_state

	if(istype(H.intimate_genital, /obj/item/intimate_accessory/piercing/genital/zizite))
		var/zizite_state = "[overlay_icon_state]_zizo"
		if(icon_exists(icon, zizite_state))
			return zizite_state

	return overlay_icon_state

/datum/sprite_accessory/intimate_accessory/proc/build_genital_piercing_appearances(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner, color_string, overlay_prefix)
	if(!organ?.accessory_type)
		return null

	var/datum/sprite_accessory/organ_accessory = SPRITE_ACCESSORY(organ.accessory_type)
	if(!organ_accessory?.is_visible(organ, bodypart, owner))
		return null

	var/base_icon_state = organ_accessory.get_icon_state(organ, bodypart, owner)
	if(!base_icon_state)
		return null

	var/list/organ_layers = organ_accessory.relevant_layers
	if(!organ_layers?.len)
		organ_layers = list(organ_accessory.layer)

	var/list/appearance_list = list()
	for(var/passed_layer in organ_layers)
		var/layer_suffix = organ_accessory.get_layer_suffix(passed_layer)
		var/overlay_icon_state = get_special_genital_overlay_state(owner, overlay_prefix, base_icon_state, layer_suffix)
		var/mutable_appearance/appearance = get_genital_piercing_overlay(overlay_icon_state, color_string, passed_layer)
		if(appearance)
			appearance_list += appearance

	return appearance_list

/datum/sprite_accessory/intimate_accessory/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_breast))
		return get_breast_piercing_icon_state(owner)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/rear_plug))
		return "[icon_state]_[get_body_suffix(owner)]"
	return icon_state

/datum/sprite_accessory/intimate_accessory/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(istype(src, /datum/sprite_accessory/intimate_accessory/slime_boobs))
		if(H.underwear?.covers_breasts)
			return FALSE
		return is_human_part_visible(owner, HIDEBOOB)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/slime_genitals))
		if(H.underwear)
			return FALSE
		return is_human_part_visible(owner, HIDECROTCH|HIDEJUMPSUIT)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/slime_tendril_overlay))
		var/mouth_visible = is_human_part_visible(owner, HIDEMASK)
		var/groin_visible = FALSE
		if(!H.underwear)
			groin_visible = is_human_part_visible(owner, HIDECROTCH|HIDEJUMPSUIT)
		return mouth_visible || groin_visible
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_breast))
		if(H.underwear?.covers_breasts)
			return FALSE
		return is_human_part_visible(owner, HIDEBOOB)
	if(H.underwear)
		return FALSE
	return is_human_part_visible(owner, HIDECROTCH)

/datum/sprite_accessory/intimate_accessory/piercing_breast
	name = "Breast Piercing"
	icon_state = "breast_pierce_pair"
	layer = BODY_FRONT_FRONT_LAYER
	color_keys = 2
	color_key_names = list("Metal", "Gem")
	default_colors = list("#9BADB7", "#9BADB7")
	intimate_type = /obj/item/intimate_accessory/piercing/breast

/datum/sprite_accessory/intimate_accessory/piercing_breast/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

	var/metal_color = color_list[1]
	if(!metal_color)
		metal_color = "#FFFFFF"

	var/gem_color = color_list[2]
	if(!gem_color)
		gem_color = metal_color

	var/is_large_pair = FALSE
	if(findtext(overlay_icon_state, "breast_pierce_pair_") == 1)
		var/suffix_text = copytext(overlay_icon_state, length("breast_pierce_pair_") + 1)
		var/size_number = text2num(suffix_text)
		if(size_number >= 6 && size_number <= 12)
			is_large_pair = TRUE

	var/icon/result_icon
	if(is_large_pair)
		// New sprites for pair sizes 6-12 separate gem areas into *_gem masks.
		result_icon = icon(icon, overlay_icon_state)
		result_icon.Blend(metal_color, ICON_MULTIPLY)

		var/icon/gem_mask_icon = icon(icon, "[overlay_icon_state]_gem")
		gem_mask_icon.Blend(gem_color, ICON_MULTIPLY)
		result_icon.Blend(gem_mask_icon, ICON_OVERLAY)
	else
		// For all other piercing shapes/sizes, tint the whole overlay to the gem color.
		result_icon = icon(icon, overlay_icon_state)
		result_icon.Blend(gem_color, ICON_MULTIPLY)

	if(extra_state)
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

/datum/sprite_accessory/intimate_accessory/piercing_breast/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	// Keep piercing overlays aligned to the same chest offsets as breast sprites.
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BREASTS, OFFSET_BREASTS_F)

/datum/sprite_accessory/intimate_accessory/piercing_genital
	name = "Genital Piercing"
	icon_state = "genital_pierce"
	intimate_type = /obj/item/intimate_accessory/piercing/genital

/datum/sprite_accessory/intimate_accessory/piercing_genital/get_appearance(obj/item/organ/organ, obj/item/bodypart/bodypart, color_string)
	var/mob/living/carbon/owner = organ?.owner || bodypart?.owner
	if(!ishuman(owner))
		return null

	var/mob/living/carbon/human/H = owner
	var/list/appearance_list = list()

	var/obj/item/organ/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	var/list/penis_appearances = build_genital_piercing_appearances(penis, bodypart, H, color_string, "penis_pierce")
	if(penis_appearances)
		appearance_list += penis_appearances

	var/obj/item/organ/vagina/vagina = H.getorganslot(ORGAN_SLOT_VAGINA)
	var/list/vagina_appearances = build_genital_piercing_appearances(vagina, bodypart, H, color_string, "vagina_pierce")
	if(vagina_appearances)
		appearance_list += vagina_appearances

	if(!appearance_list.len)
		return null

	adjust_appearance_list(appearance_list, organ, bodypart, owner)
	return appearance_list

/datum/sprite_accessory/intimate_accessory/piercing_genital/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	// Keep genital piercing overlays aligned to the same belt offsets as genital organ sprites.
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)

/datum/sprite_accessory/intimate_accessory/rear_plug
	name = "Rear Plug"
	icon_state = "rear_plug"
	intimate_type = /obj/item/intimate_accessory/rear/plug

/datum/sprite_accessory/intimate_accessory/rear_plug/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

	// Rear-plug masks are authored as rear_plug_<color-index>_<body-suffix>.
	var/body_suffix = copytext(overlay_icon_state, length("rear_plug_") + 1)
	var/icon/result_icon
	for(var/color_index in 1 to color_keys)
		var/color_to_use = color_list[color_index]
		var/lookup_state = "rear_plug_[color_index]_[body_suffix]"
		var/icon/color_key_icon = icon(icon, lookup_state)
		color_key_icon.Blend(color_to_use, ICON_MULTIPLY)
		if(!result_icon)
			result_icon = color_key_icon
		else
			result_icon.Blend(color_key_icon, ICON_OVERLAY)

	if(extra_state)
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

/datum/sprite_accessory/intimate_accessory/rear_beads
	name = "Rear Beads"
	icon_state = "rear_beads"
	intimate_type = /obj/item/intimate_accessory/rear/plug/analbeads

/datum/sprite_accessory/intimate_accessory/rear_beads/get_icon_state(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	var/bead_count = "short"
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(istype(H.intimate_rear, /obj/item/intimate_accessory/rear/plug/analbeads))
			var/obj/item/intimate_accessory/rear/plug/analbeads/beads = H.intimate_rear
			if(beads.bead_count == "medium" || beads.bead_count == "long")
				bead_count = beads.bead_count
	return "[icon_state]_[bead_count]_[get_body_suffix(owner)]"

/datum/sprite_accessory/intimate_accessory/rear_beads/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

	var/body_suffix = copytext(overlay_icon_state, length("rear_beads_") + 1)
	var/icon/result_icon
	for(var/color_index in 1 to color_keys)
		var/color_to_use = color_list[color_index]
		var/lookup_state = "rear_beads_[color_index]_[body_suffix]"
		var/icon/color_key_icon = icon(icon, lookup_state)
		color_key_icon.Blend(color_to_use, ICON_MULTIPLY)
		if(!result_icon)
			result_icon = color_key_icon
		else
			result_icon.Blend(color_key_icon, ICON_OVERLAY)

	if(extra_state)
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

/datum/sprite_accessory/intimate_accessory/slime_genitals
	name = "Slime Genitals"
	icon = 'modular/icons/obj/lewd/intimate_slime_overlays.dmi'
	icon_state = "slime_genitals"
	layer = BODY_FRONT_FRONT_LAYER
	intimate_type = /obj/item/intimate_accessory/jelly/eora
	color_keys = 0
	default_colors = null

/datum/sprite_accessory/intimate_accessory/slime_genitals/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	return generate_untinted_icon_state(overlay_icon_state, suffix)

/**
 * Guard against missing DMI states. generate_icon_state() delegates to generate_untinted_icon_state()
 * which returns null when the icon state does not exist in the DMI. The base get_overlay() passes that
 * null into icon_bundle.Insert(), causing a "bad icon operation" runtime. Early-returning null here
 * lets the caller (get_appearance) silently skip the overlay instead of crashing.
 */
/datum/sprite_accessory/intimate_accessory/slime_genitals/get_overlay(overlay_icon_state, color_string)
	if(!icon_exists(icon, overlay_icon_state))
		return null
	return ..()

/datum/sprite_accessory/intimate_accessory/slime_genitals/strange
	icon_state = "slime_genitals_strange"
	intimate_type = /obj/item/intimate_accessory/jelly/eora/strange

/datum/sprite_accessory/intimate_accessory/slime_boobs
	name = "Slime Breasts"
	icon = 'modular/icons/obj/lewd/intimate_slime_overlays.dmi'
	icon_state = "slime_boobs"
	layer = BODY_FRONT_FRONT_LAYER
	intimate_type = /obj/item/intimate_accessory/jelly/eora
	color_keys = 0
	default_colors = null

/datum/sprite_accessory/intimate_accessory/slime_boobs/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	return generate_untinted_icon_state(overlay_icon_state, suffix)

/// See slime_genitals/get_overlay for rationale — same null-state guard.
/datum/sprite_accessory/intimate_accessory/slime_boobs/get_overlay(overlay_icon_state, color_string)
	if(!icon_exists(icon, overlay_icon_state))
		return null
	return ..()

/datum/sprite_accessory/intimate_accessory/slime_boobs/strange
	icon_state = "slime_boobs_strange"
	intimate_type = /obj/item/intimate_accessory/jelly/eora/strange

/datum/sprite_accessory/intimate_accessory/slime_genitals_rear
	name = "Slime Genitals (Rear)"
	icon = 'modular/icons/obj/lewd/intimate_slime_overlays.dmi'
	icon_state = "slime_genitals_rear"
	layer = BODY_FRONT_FRONT_LAYER
	intimate_type = /obj/item/intimate_accessory/jelly/eora
	color_keys = 0
	default_colors = null

/datum/sprite_accessory/intimate_accessory/slime_genitals_rear/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	return generate_untinted_icon_state(overlay_icon_state, suffix)

/// See slime_genitals/get_overlay for rationale — same null-state guard.
/datum/sprite_accessory/intimate_accessory/slime_genitals_rear/get_overlay(overlay_icon_state, color_string)
	if(!icon_exists(icon, overlay_icon_state))
		return null
	return ..()

/datum/sprite_accessory/intimate_accessory/slime_genitals_rear/strange
	icon_state = "slime_genitals_rear_strange"
	intimate_type = /obj/item/intimate_accessory/jelly/eora/strange

/datum/sprite_accessory/intimate_accessory/slime_tendril_overlay
	name = "Slime Tendrils"
	icon = 'modular/icons/obj/lewd/intimate_slime_overlays.dmi'
	icon_state = "slime_tendril_overlay"
	layer = BODY_FRONT_FRONT_LAYER
	intimate_type = /obj/item/intimate_accessory/jelly/eora
	color_keys = 0
	default_colors = null

/datum/sprite_accessory/intimate_accessory/slime_tendril_overlay/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	return generate_untinted_icon_state(overlay_icon_state, suffix)

/// See slime_genitals/get_overlay for rationale — same null-state guard.
/datum/sprite_accessory/intimate_accessory/slime_tendril_overlay/get_overlay(overlay_icon_state, color_string)
	if(!icon_exists(icon, overlay_icon_state))
		return null
	return ..()

/datum/sprite_accessory/intimate_accessory/slime_tendril_overlay/strange
	icon_state = "slime_tendril_overlay_strange"
	intimate_type = /obj/item/intimate_accessory/jelly/eora/strange

/datum/sprite_accessory/intimate_overlays/piercing_breast
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_breast

/datum/sprite_accessory/intimate_overlays/piercing_genital
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_genital

/datum/sprite_accessory/intimate_overlays/rear_plug
	parent_type = /datum/sprite_accessory/intimate_accessory/rear_plug

/datum/sprite_accessory/intimate_overlays/rear_beads
	parent_type = /datum/sprite_accessory/intimate_accessory/rear_beads

/datum/sprite_accessory/intimate_overlays/slime_genitals
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_genitals

/datum/sprite_accessory/intimate_overlays/slime_genitals/strange
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_genitals/strange

/datum/sprite_accessory/intimate_overlays/slime_boobs
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_boobs

/datum/sprite_accessory/intimate_overlays/slime_boobs/strange
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_boobs/strange

/datum/sprite_accessory/intimate_overlays/slime_genitals_rear
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_genitals_rear

/datum/sprite_accessory/intimate_overlays/slime_genitals_rear/strange
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_genitals_rear/strange

/datum/sprite_accessory/intimate_overlays/slime_tendril_overlay
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_tendril_overlay

/datum/sprite_accessory/intimate_overlays/slime_tendril_overlay/strange
	parent_type = /datum/sprite_accessory/intimate_accessory/slime_tendril_overlay/strange

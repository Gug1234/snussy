/datum/sprite_accessory/intimate_accessory
	abstract_type = /datum/sprite_accessory/intimate_accessory
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

	var/cross_suffix = ""
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(istype(H.intimate_breast_piercing, /obj/item/intimate_accessory/piercing/breast/psydonic))
			cross_suffix = "_psy"
		else if(istype(H.intimate_breast_piercing, /obj/item/intimate_accessory/piercing/breast/zizite))
			cross_suffix = "_zizo"

	if(amount_tag == "pair")
		breast_size = clamp(breast_size, 0, 12)
		if(breast_size == 0)
			if(is_species(owner, /datum/species/goblinp))
				var/base_state = owner.gender == FEMALE ? "breast_pierce_pair_0gf" : "breast_pierce_pair_0g"
				if(cross_suffix && icon_exists(icon, "[base_state][cross_suffix]"))
					return "[base_state][cross_suffix]"
				return base_state
			if(owner.gender == FEMALE && is_species(owner, /datum/species/dwarf))
				if(cross_suffix && icon_exists(icon, "breast_pierce_pair_0df[cross_suffix]"))
					return "breast_pierce_pair_0df[cross_suffix]"
				return "breast_pierce_pair_0df"
			for(var/species_type in short_anthro_size_zero_species)
				if(is_species(owner, species_type))
					if(cross_suffix && icon_exists(icon, "breast_pierce_pair_0sf[cross_suffix]"))
						return "breast_pierce_pair_0sf[cross_suffix]"
					return "breast_pierce_pair_0sf"
			if(cross_suffix && icon_exists(icon, "breast_pierce_pair_0[cross_suffix]"))
				return "breast_pierce_pair_0[cross_suffix]"
			return "breast_pierce_pair_0"
	else
		breast_size = clamp(breast_size, 0, 5)

	var/base_state = "breast_pierce_[amount_tag]_[breast_size]"
	if(cross_suffix && icon_exists(icon, "[base_state][cross_suffix]"))
		return "[base_state][cross_suffix]"
	return base_state

/datum/sprite_accessory/intimate_accessory/proc/get_ear_piercing_icon_state(mob/living/carbon/owner)
	var/cross_suffix = ""
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(istype(H.intimate_ear_piercing, /obj/item/intimate_accessory/piercing/ear/psydonic))
			cross_suffix = "_psy"
		else if(istype(H.intimate_ear_piercing, /obj/item/intimate_accessory/piercing/ear/zizite))
			cross_suffix = "_zizo"
	if(cross_suffix && icon_exists(icon, "ear_pierce[cross_suffix]"))
		return "ear_pierce[cross_suffix]"
	return "ear_pierce"

/datum/sprite_accessory/intimate_accessory/proc/get_nose_piercing_icon_state(mob/living/carbon/owner)
	return "nose_pierce"

/datum/sprite_accessory/intimate_accessory/proc/get_belly_piercing_icon_state(mob/living/carbon/owner)
	var/cross_suffix = ""
	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(istype(H.intimate_belly_piercing, /obj/item/intimate_accessory/piercing/belly/psydonic))
			cross_suffix = "_psy"
		else if(istype(H.intimate_belly_piercing, /obj/item/intimate_accessory/piercing/belly/zizite))
			cross_suffix = "_zizo"
	if(cross_suffix && icon_exists(icon, "belly_pierce[cross_suffix]"))
		return "belly_pierce[cross_suffix]"
	return "belly_pierce"

/datum/sprite_accessory/intimate_accessory/proc/resolve_genital_piercing_icon_state(overlay_icon_state)
	if(icon_exists(icon, overlay_icon_state))
		return overlay_icon_state
	var/layer_index_state = "[overlay_icon_state]_1"
	if(icon_exists(icon, layer_index_state))
		return layer_index_state
	return null

/datum/sprite_accessory/intimate_accessory/proc/get_genital_piercing_gem_icon_state(overlay_icon_state)
	var/suffixed_gem_state = "[overlay_icon_state]_gem"
	if(icon_exists(icon, suffixed_gem_state))
		return suffixed_gem_state
	if(findtext(overlay_icon_state, "vagina_pierce_") == 1)
		var/vagina_state = copytext(overlay_icon_state, length("vagina_pierce_") + 1)
		var/prefixed_gem_state = "vagina_pierce_gem_[vagina_state]"
		if(icon_exists(icon, prefixed_gem_state))
			return prefixed_gem_state
	return null

/datum/sprite_accessory/intimate_accessory/proc/get_genital_piercing_overlay(overlay_icon_state, color_string, passed_layer)
	var/resolved_icon_state = resolve_genital_piercing_icon_state(overlay_icon_state)
	if(!resolved_icon_state)
		return null

	color_string = sanitize_color_string(color_string)
	var/cache_key = "[type]-genital-[resolved_icon_state]-[color_string]"
	if(!accessory_icon_cache[cache_key])
		var/list/color_list = color_string_to_list(color_string)
		var/icon/icon_bundle = icon('icons/Testing/greyscale_error.dmi')
		icon_bundle.Insert(generate_genital_piercing_icon_state(resolved_icon_state, color_list), resolved_icon_state)
		accessory_icon_cache[cache_key] = icon_bundle

	var/icon/cached_icon = icon(accessory_icon_cache[cache_key])
	var/mutable_appearance/appearance = mutable_appearance(cached_icon, resolved_icon_state, layer = -passed_layer)
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

	var/gem_icon_state = get_genital_piercing_gem_icon_state(overlay_icon_state)
	if(gem_icon_state)
		var/icon/gem_mask_icon = icon(icon, gem_icon_state)
		gem_mask_icon.Blend(gem_color, ICON_MULTIPLY)
		result_icon.Blend(gem_mask_icon, ICON_OVERLAY)

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
	if(istype(H.intimate_genital_piercing, /obj/item/intimate_accessory/piercing/genital/psydonic))
		var/psydonic_state = "[overlay_icon_state]_psy"
		if(icon_exists(icon, psydonic_state))
			return psydonic_state

	if(istype(H.intimate_genital_piercing, /obj/item/intimate_accessory/piercing/genital/zizite))
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
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_ear))
		return get_ear_piercing_icon_state(owner)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_nose))
		return get_nose_piercing_icon_state(owner)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_belly))
		return get_belly_piercing_icon_state(owner)
	return icon_state

/datum/sprite_accessory/intimate_accessory/is_visible(obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_breast))
		if(!H.has_visible_genital_organ(ORGAN_SLOT_BREASTS))
			return FALSE
		if(H.underwear?.covers_breasts)
			return FALSE
		return is_human_part_visible(owner, HIDEBOOB)
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_ear))
		return TRUE
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_nose))
		return TRUE
	if(istype(src, /datum/sprite_accessory/intimate_accessory/piercing_belly))
		return is_human_part_visible(owner, HIDEJUMPSUIT)
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

/datum/sprite_accessory/intimate_accessory/piercing_breast/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BREASTS, OFFSET_BREASTS_F)

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
		result_icon = icon(icon, overlay_icon_state)
		result_icon.Blend(metal_color, ICON_MULTIPLY)

		var/icon/gem_mask_icon = icon(icon, "[overlay_icon_state]_gem")
		gem_mask_icon.Blend(gem_color, ICON_MULTIPLY)
		result_icon.Blend(gem_mask_icon, ICON_OVERLAY)
	else
		result_icon = icon(icon, overlay_icon_state)
		result_icon.Blend(gem_color, ICON_MULTIPLY)

	if(extra_state)
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

/datum/sprite_accessory/intimate_accessory/piercing_ear
	name = "Ear Piercing"
	icon_state = "ear_pierce"
	layer = BODY_FRONT_FRONT_LAYER
	color_keys = 2
	color_key_names = list("Metal", "Gem")
	default_colors = list("#9BADB7", "#9BADB7")
	intimate_type = /obj/item/intimate_accessory/piercing/ear

/datum/sprite_accessory/intimate_accessory/piercing_ear/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

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

/datum/sprite_accessory/intimate_accessory/piercing_nose
	name = "Nose Piercing"
	icon_state = "nose_pierce"
	layer = BODY_FRONT_FRONT_LAYER
	color_keys = 2
	color_key_names = list("Metal", "Gem")
	default_colors = list("#9BADB7", "#9BADB7")
	intimate_type = /obj/item/intimate_accessory/piercing/nose

/datum/sprite_accessory/intimate_accessory/piercing_nose/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

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

/datum/sprite_accessory/intimate_accessory/piercing_belly
	name = "Belly Piercing"
	icon_state = "belly_pierce"
	layer = BODY_FRONT_FRONT_LAYER
	color_keys = 2
	color_key_names = list("Metal", "Gem")
	default_colors = list("#9BADB7", "#9BADB7")
	intimate_type = /obj/item/intimate_accessory/piercing/belly

/datum/sprite_accessory/intimate_accessory/piercing_belly/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

	var/metal_color = color_list[1]
	if(!metal_color)
		metal_color = "#FFFFFF"

	var/gem_color = color_list[2]
	if(!gem_color)
		gem_color = metal_color

	var/is_variant = findtext(overlay_icon_state, "_psy") || findtext(overlay_icon_state, "_zizo")

	var/icon/result_icon = icon(icon, overlay_icon_state)
	result_icon.Blend(metal_color, ICON_MULTIPLY)

	if(!is_variant && icon_exists(icon, "[overlay_icon_state]_gem"))
		var/icon/gem_mask_icon = icon(icon, "[overlay_icon_state]_gem")
		gem_mask_icon.Blend(gem_color, ICON_MULTIPLY)
		result_icon.Blend(gem_mask_icon, ICON_OVERLAY)

	if(extra_state && icon_exists(icon, "[overlay_icon_state]_extra"))
		var/icon/extra_icon = icon(icon, "[overlay_icon_state]_extra")
		result_icon.Blend(extra_icon, ICON_OVERLAY)

	result_icon.GetPixel(1, 1)
	return result_icon

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
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)

/datum/sprite_accessory/intimate_accessory/rear_plug
	name = "Rear Plug"
	icon_state = "rear_plug"
	intimate_type = /obj/item/intimate_accessory/rear/plug

/datum/sprite_accessory/intimate_accessory/rear_plug/generate_icon_state(overlay_icon_state, color_list, passed_layer, suffix)
	if(suffix)
		overlay_icon_state += "_[suffix]"

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
		if(istype(H.intimate_rear_insertable, /obj/item/intimate_accessory/rear/plug/analbeads))
			var/obj/item/intimate_accessory/rear/plug/analbeads/beads = H.intimate_rear_insertable
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

/datum/sprite_accessory/intimate_overlays/piercing_breast
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_breast

/datum/sprite_accessory/intimate_overlays/piercing_ear
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_ear

/datum/sprite_accessory/intimate_overlays/piercing_nose
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_nose

/datum/sprite_accessory/intimate_overlays/piercing_belly
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_belly

/datum/sprite_accessory/intimate_overlays/piercing_genital
	parent_type = /datum/sprite_accessory/intimate_accessory/piercing_genital

/datum/sprite_accessory/intimate_overlays/rear_plug
	parent_type = /datum/sprite_accessory/intimate_accessory/rear_plug

/datum/sprite_accessory/intimate_overlays/rear_beads
	parent_type = /datum/sprite_accessory/intimate_accessory/rear_beads

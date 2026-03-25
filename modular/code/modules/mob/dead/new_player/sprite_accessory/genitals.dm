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

/// Reorders testicle layers when a cage-type device is worn so they sit beneath the cage overlay.
/// Upstream adjust_appearance_list handles the generic offset; this fires after and only adjusts layers
/// when the wearer's device has a cage sprite that intentionally shows the sack through the bars.
/datum/sprite_accessory/testicles/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)
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

/datum/sprite_accessory/penis/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)

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

/datum/sprite_accessory/vagina/adjust_appearance_list(list/appearance_list, obj/item/organ/organ, obj/item/bodypart/bodypart, mob/living/carbon/owner)
	generic_gender_feature_adjust(appearance_list, organ, bodypart, owner, OFFSET_BELT, OFFSET_BELT_F)

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

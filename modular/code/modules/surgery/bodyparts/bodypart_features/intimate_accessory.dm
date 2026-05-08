/datum/bodypart_feature/intimate_accessory
	name = "Intimate Accessory"
	feature_slot = BODYPART_FEATURE_INTIMATE_ACCESSORY
	body_zone = BODY_ZONE_CHEST
	var/obj/item/intimate_accessory/accessory_item

/datum/bodypart_feature/intimate_accessory/proc/get_feature_slot_for_item(obj/item/intimate_accessory/item)
	if(!item)
		return BODYPART_FEATURE_INTIMATE_ACCESSORY
	return "[BODYPART_FEATURE_INTIMATE_ACCESSORY]_[item.get_effective_intimate_slot()]"

/datum/bodypart_feature/intimate_accessory/set_accessory_type(new_accessory_type, colors, mob/living/carbon/owner)
	accessory_type = new_accessory_type
	var/datum/sprite_accessory/intimate_accessory/accessory = SPRITE_ACCESSORY(accessory_type)
	if(!isnull(colors))
		accessory_colors = colors
	else
		accessory_colors = accessory.get_default_colors(color_key_source_list_from_carbon(owner))
	accessory_colors = accessory.validate_color_keys_for_owner(owner, colors)
	accessory_item = new accessory.intimate_type(owner)
	accessory_item.intimate_feature = src
	accessory_item.color = accessory_colors

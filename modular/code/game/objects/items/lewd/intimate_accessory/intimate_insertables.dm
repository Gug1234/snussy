// Genital plug variants.
/obj/item/intimate_accessory/genital/plug
	name = "steel vaginal plug"
	desc = "A smooth, tapered plug meant to sit snugly in the cunt. It holds what is pressed into it and leaves behind a quiet, needy pressure."
	icon_state = "rear_plug_item_1"
	item_state = "rear_plug_item_1"
	mob_overlay_icon = "rear_plug_1"
	intimate_slot = INTIMATE_SLOT_GENITAL
	intimate_flags = INTIMATE_FLAG_INSERTABLE
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	intimate_retains_internal_creampie = TRUE
	intimate_passive_insertable_effect = TRUE
	sprite_acc = null
	sellprice = 10
	var/passive_arousal_amount = 0.2

/obj/item/intimate_accessory/genital/plug/Initialize()
	. = ..()
	apply_intimate_item_tint()
	// Attach the insertable reaction component for passive shift messages and sex-action flavor text.
	AddComponent(/datum/component/intimate_reaction/insertable)

/obj/item/intimate_accessory/genital/plug/can_attach_target(mob/living/carbon/human/H, mob/user)
	. = ..()
	if(!.)
		return FALSE
	if(!H.getorganslot(ORGAN_SLOT_VAGINA))
		to_chat(user, span_warning("[H] lacks the anatomy to wear [src]."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/genital/plug/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	if(H)
		playsound(H, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)
	var/datum/component/intimate_reaction/insertable/reaction = GetComponent(/datum/component/intimate_reaction/insertable)
	if(reaction)
		reaction.bind_to_wearer(H)

/obj/item/intimate_accessory/genital/plug/remove_intimate_accessory(mob/living/carbon/human/H)
	var/datum/component/intimate_reaction/insertable/reaction = GetComponent(/datum/component/intimate_reaction/insertable)
	if(reaction)
		reaction.unbind_from_wearer(H)
	if(H && H.intimate_genital == src)
		if(!H.sexcon?.release_retained_internal_creampie(H))
			playsound(H, 'sound/items/uncork.ogg', 45, TRUE, ignore_walls = FALSE)
	return ..()

/obj/item/intimate_accessory/genital/plug/handle_passive_insertable_effect(mob/living/carbon/human/H)
	if(!H || H.intimate_genital != src)
		return FALSE
	if(H.stat == DEAD || !H.sexcon)
		return FALSE
	if(H.sexcon.arousal_frozen)
		return FALSE
	if(H.sexcon.arousal >= ACTIVE_EJAC_THRESHOLD)
		return FALSE
	H.sexcon.adjust_arousal(passive_arousal_amount)
	return TRUE

/obj/item/intimate_accessory/genital/plug/iron
	name = "iron vaginal plug"
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/genital/plug/copper
	name = "copper vaginal plug"
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/genital/plug/steel
	name = "steel vaginal plug"
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/genital/plug/bronze
	name = "bronze vaginal plug"
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/genital/plug/silver
	name = "silver vaginal plug"
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/genital/plug/gold
	name = "gold vaginal plug"
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/genital/plug/blacksteel
	name = "blacksteel vaginal plug"
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

// Rear plug variants.
/obj/item/intimate_accessory/rear/plug
	name = "intimate plug"
	desc = "A rear-worn plug with a socket for a gem accent. Claimed by knights to 'improve one's squat form'; most know better."
	icon_state = "rear_plug_item_1"
	item_state = "rear_plug_item_1"
	mob_overlay_icon = "rear_plug_1"
	lefthand_file = 'modular/icons/mob/inhands/lewd/items_lefthand.dmi'
	righthand_file = 'modular/icons/mob/inhands/lewd/items_righthand.dmi'
	intimate_slot = INTIMATE_SLOT_REAR
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	intimate_gem_color = "#9BADB7"
	intimate_flags = INTIMATE_FLAG_INSERTABLE | INTIMATE_FLAG_BERIDDLEABLE
	sprite_acc = /datum/sprite_accessory/intimate_overlays/rear_plug
	sellprice = 10
	var/beriddleed = FALSE
	var/blue_pearled = FALSE
	var/base_sellprice = 10
	var/default_desc = "A rear-worn plug with a socket for a gem accent. Claimed by knights to 'improve one's squat form'; most know better."
	var/rear_accessory_noun = "buttplug"
	var/beriddled_desc = "A buttplug infused with a riddle of steel. What a horrid waste."
	var/psydonic_desc = "A buttplug reshaped around a fixed psycross. Its quiet blue sheen makes it look more like star-and-clay than smithwork."
	var/zizite_desc = "A buttplug reshaped around a fixed zcross and grim beadwork. The Dame of Progress would likely call it an improvement."
	var/blue_pearled_desc = "A buttplug with a blue pearl embedded in it. Seems sturdy enough to plug a whirlpool."
	var/blue_pearled_name = null
	var/bead_count = null
	var/psydonic_socketed = FALSE
	var/zizite_socketed = FALSE

/obj/item/intimate_accessory/rear/plug/proc/is_worn_in_rear_slot(mob/living/carbon/human/H)
	return !!(H && H.intimate_rear == src)

/obj/item/intimate_accessory/rear/plug/proc/play_plug_sound(mob/living/carbon/human/H, sound_file)
	if(H)
		playsound(H, sound_file, 45, TRUE, ignore_walls = FALSE)

/obj/item/intimate_accessory/rear/plug/proc/refresh_rear_plug_state()
	update_sellprice()
	update_description()
	update_dynamic_name()
	update_item_visuals()
	update_beriddleed_glow()

/obj/item/intimate_accessory/rear/plug/Initialize()
	. = ..()
	base_sellprice = initial(sellprice)
	refresh_rear_plug_state()
	// Attach the insertable reaction component for passive shift messages and sex-action flavor text.
	AddComponent(/datum/component/intimate_reaction/insertable)

/obj/item/intimate_accessory/rear/plug/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	play_plug_sound(H, 'sound/misc/mat/pop.ogg')
	var/datum/component/intimate_reaction/insertable/reaction = GetComponent(/datum/component/intimate_reaction/insertable)
	if(reaction)
		reaction.bind_to_wearer(H)

/obj/item/intimate_accessory/rear/plug/remove_intimate_accessory(mob/living/carbon/human/H)
	var/datum/component/intimate_reaction/insertable/reaction = GetComponent(/datum/component/intimate_reaction/insertable)
	if(reaction)
		reaction.unbind_from_wearer(H)
	if(is_worn_in_rear_slot(H))
		play_plug_sound(H, 'sound/items/uncork.ogg')
	return ..()

/obj/item/intimate_accessory/rear/plug/proc/update_sellprice()
	sellprice = max(1, base_sellprice + gem_value_bonus)

/obj/item/intimate_accessory/rear/plug/proc/update_item_visuals()
	cut_overlays()

	var/special_state = get_special_rear_item_state("rear_plug_item")
	if(special_state)
		color = initial(color)
		item_state = special_state
		icon_state = special_state
		update_icon()
		return

	apply_intimate_item_tint()

	item_state = "rear_plug_item_1"
	icon_state = "rear_plug_item_1"

	if(has_socketed_insert())
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, "rear_plug_item_2")
		if(intimate_gem_color)
			gem_overlay.color = intimate_gem_color
		add_overlay(gem_overlay)
	update_icon()

/obj/item/intimate_accessory/rear/plug/proc/get_metal_descriptor()
	if(!intimate_metal_name)
		return "metal"
	return lowertext(intimate_metal_name)

/obj/item/intimate_accessory/rear/plug/proc/get_gem_descriptor_from_item(obj/item/roguegem/gem)
	if(!gem)
		return null
	return lowertext(gem.name)

/obj/item/intimate_accessory/rear/plug/proc/is_zizite_socket_type(socket_type)
	if(!socket_type)
		return FALSE

	return ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/zcross/iron)

/obj/item/intimate_accessory/rear/plug/proc/is_psydonic_socket_type(socket_type)
	if(!socket_type)
		return FALSE

	if(is_zizite_socket_type(socket_type))
		return FALSE

	return ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/aalloy) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/silver) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/g)

/obj/item/intimate_accessory/rear/plug/proc/is_zizite_socket_item(obj/item/I)
	return !!(I && is_zizite_socket_type(I.type))

/obj/item/intimate_accessory/rear/plug/proc/is_psydonic_socket_item(obj/item/I)
	return !!(I && is_psydonic_socket_type(I.type))

/obj/item/intimate_accessory/rear/plug/proc/get_zizite_socket_descriptor(obj/item/cross)
	if(!cross)
		return "zcross"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy))
		return "ancient zcross"
	return "iron zcross"

/obj/item/intimate_accessory/rear/plug/proc/get_zizite_socket_color(obj/item/cross)
	if(!cross)
		return "#9EA48E"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/aalloy))
		return "#BB9696"
	return "#9EA48E"

/obj/item/intimate_accessory/rear/plug/proc/get_psydonic_socket_descriptor(obj/item/clothing/neck/roguetown/psicross/cross)
	if(!cross)
		return "psycross"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/silver))
		return "silver psycross"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/g))
		return "golden psycross"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/aalloy))
		return "ancient psycross"
	return "stone psycross"

/obj/item/intimate_accessory/rear/plug/proc/get_psydonic_socket_color(obj/item/clothing/neck/roguetown/psicross/cross)
	if(!cross)
		return "#9BADB7"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/silver))
		return "#C6D5E1"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/g))
		return "#C4B651"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/aalloy))
		return "#BB9696"
	return "#9BADB7"

/obj/item/intimate_accessory/rear/plug/proc/get_special_rear_socket_style()
	if(zizite_socketed)
		return "zizo"
	if(psydonic_socketed)
		return "psy"
	return null

/obj/item/intimate_accessory/rear/plug/proc/get_special_rear_item_state(state_prefix, state_suffix = null)
	var/style = get_special_rear_socket_style()
	if(!style || !state_prefix)
		return null
	if(state_suffix)
		return "[state_prefix]_[state_suffix]_[style]"
	return "[state_prefix]_[style]"

/obj/item/intimate_accessory/rear/plug/proc/update_description()
	if(is_beriddled())
		desc = beriddled_desc
		return

	if(blue_pearled)
		desc = blue_pearled_desc
		return

	if(zizite_socketed && zizite_desc)
		desc = zizite_desc
		return

	if(psydonic_socketed && psydonic_desc)
		desc = psydonic_desc
		return

	desc = default_desc

/obj/item/intimate_accessory/rear/plug/proc/update_dynamic_name()
	var/metal_descriptor = get_metal_descriptor()
	if(is_beriddled())
		name = "beriddleed [metal_descriptor] [rear_accessory_noun]"
		return

	if(blue_pearled && blue_pearled_name)
		name = blue_pearled_name
		return

	if(zizite_socketed)
		name = "zizite [rear_accessory_noun]"
		return

	if(psydonic_socketed)
		name = "psydonic [rear_accessory_noun]"
		return

	if(current_gem_descriptor)
		name = "[current_gem_descriptor]-set [metal_descriptor] [rear_accessory_noun]"
	else
		name = "[metal_descriptor] [rear_accessory_noun]"

/obj/item/intimate_accessory/rear/plug/proc/update_beriddleed_state(new_state)
	if(!!new_state)
		apply_beriddle_state(null)
		return
	reset_socketed_state()

/obj/item/intimate_accessory/rear/plug/proc/refresh_socket_flags()
	beriddleed = ispath(socketed_item_type, /obj/item/riddleofsteel)
	blue_pearled = istype(src, /obj/item/intimate_accessory/rear/plug/analbeads/abyssor) || ispath(socketed_item_type, /obj/item/pearl/blue)
	psydonic_socketed = is_psydonic_socket_type(socketed_item_type)
	zizite_socketed = is_zizite_socket_type(socketed_item_type)

/obj/item/intimate_accessory/rear/plug/has_custom_socket_state()
	return beriddleed || blue_pearled

/obj/item/intimate_accessory/rear/plug/clear_custom_socket_state()
	beriddleed = FALSE
	blue_pearled = FALSE
	psydonic_socketed = FALSE
	zizite_socketed = FALSE
	desc = default_desc
	update_beriddleed_glow()

/obj/item/intimate_accessory/rear/plug/is_beriddled()
	return beriddleed || ispath(socketed_item_type, /obj/item/riddleofsteel)

/obj/item/intimate_accessory/rear/plug/on_beriddle_state_changed(new_state)
	if(!!new_state)
		desc = beriddled_desc
		beriddleed = TRUE
	else
		beriddleed = FALSE
		if(!blue_pearled)
			desc = default_desc
	update_beriddleed_glow()

/obj/item/intimate_accessory/rear/plug/proc/update_beriddleed_glow()
	if(is_beriddled())
		set_light(2, 2, 1, l_color = "#ff0d0d")
	else
		set_light(0)

/obj/item/intimate_accessory/rear/plug/proc/try_socket_blue_pearl(obj/item/pearl/blue/pearl, mob/living/user)
	if(!pearl || !user)
		return FALSE
	if(has_socketed_insert())
		to_chat(user, span_warning("[src] already has something socketed in it."))
		return TRUE

	if(!socket_item(pearl, socket_descriptor = "blue pearl", socket_color = "#60C9FF", reason = "pearl_changed"))
		to_chat(user, span_warning("I can't socket [pearl] into [src]."))
		return TRUE

	to_chat(user, span_notice("I set [pearl] into [src], stick the Great Tide's abyss inside your abyss."))
	playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)
	qdel(pearl)
	return TRUE

/obj/item/intimate_accessory/rear/plug/proc/try_socket_special_cross(obj/item/cross, mob/living/user)
	if(!cross || !user)
		return FALSE
	if(has_socketed_insert())
		to_chat(user, span_warning("[src] already has something socketed in it."))
		return TRUE

	var/socket_descriptor = null
	var/socket_color = null
	var/reason = null
	var/notice_message = null

	if(is_zizite_socket_item(cross))
		socket_descriptor = get_zizite_socket_descriptor(cross)
		socket_color = get_zizite_socket_color(cross)
		reason = "zizite_socketed"
		notice_message = "I set [cross] into [src], the Dame of Progress reshaping it in HER image."
	else if(is_psydonic_socket_item(cross))
		socket_descriptor = get_psydonic_socket_descriptor(cross)
		socket_color = get_psydonic_socket_color(cross)
		reason = "psydonic_socketed"
		notice_message = "I set [cross] into [src], reshaping it as if wrought from star-and-clay. It is deemed good."
	else
		return FALSE

	if(!socket_item(cross, socket_descriptor = socket_descriptor, socket_color = socket_color, reason = reason))
		to_chat(user, span_warning("I can't socket [cross] into [src]."))
		return TRUE

	to_chat(user, span_notice(notice_message))
	playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)
	qdel(cross)
	return TRUE

/obj/item/intimate_accessory/rear/plug/attackby(obj/item/I, mob/living/user, params)
	if(is_psydonic_socket_item(I) || is_zizite_socket_item(I))
		return try_socket_special_cross(I, user)

	if(istype(I, /obj/item/pearl/blue))
		return try_socket_blue_pearl(I, user)

	return ..()

/obj/item/intimate_accessory/rear/plug/on_socket_state_changed(reason = "")
	refresh_socket_flags()
	on_beriddle_state_changed(is_beriddled())
	refresh_rear_plug_state()
	return ..()

/obj/item/intimate_accessory/rear/plug/clear_intimate_mood_effects(mob/living/carbon/human/H)
	if(!H)
		return
	H.remove_stress(/datum/stressevent/beriddleed_plug)
	H.remove_stress(/datum/stressevent/abyssor_blue_pearled_plug)

/obj/item/intimate_accessory/rear/plug/refresh_intimate_mood_effects(mob/living/carbon/human/H)
	if(!H)
		return
	clear_intimate_mood_effects(H)
	if(is_worn_in_rear_slot(H) && beriddleed)
		H.add_stress(/datum/stressevent/beriddleed_plug)
	if(is_worn_in_rear_slot(H) && blue_pearled && H.patron?.type == /datum/patron/divine/abyssor)
		H.add_stress(/datum/stressevent/abyssor_blue_pearled_plug)

/obj/item/intimate_accessory/rear/plug/buttplug
	name = "buttplug"
	desc = "A rear-worn plug with a socket for a gem accent. Claimed by knights to 'improve one's squat form'; most know better."
	intimate_slot = INTIMATE_SLOT_REAR
	intimate_flags = INTIMATE_FLAG_INSERTABLE | INTIMATE_FLAG_BERIDDLEABLE
	sprite_acc = /datum/sprite_accessory/intimate_overlays/rear_plug
	default_desc = "A rear-worn plug with a socket for a gem accent. Claimed by knights to 'improve one's squat form'; most know better."

/obj/item/intimate_accessory/rear/plug/analbeads
	name = "anal beads"
	desc = "A set of four anal beads designed for the rear. They have a ring of sockets around each bead."
	icon_state = "rear_beads_item_short"
	item_state = "rear_beads_item_short"
	mob_overlay_icon = "rear_beads_short"
	intimate_slot = INTIMATE_SLOT_REAR
	intimate_flags = INTIMATE_FLAG_INSERTABLE | INTIMATE_FLAG_BERIDDLEABLE
	sprite_acc = /datum/sprite_accessory/intimate_overlays/rear_beads
	default_desc = "A set of four anal beads designed for the rear. They have a ring of sockets around each bead."
	rear_accessory_noun = "anal beads"
	beriddled_desc = "A set of anal beads infused with a riddle of steel. What a horrid waste."
	psydonic_desc = "A string of anal beads threaded with fixed psycross beadwork. Their quiet blue gleam makes the whole toy look half-wrought from star-and-clay."
	zizite_desc = "A string of anal beads threaded with fixed zcross beadwork and morbid accents. It carries the Dame of Progress's spite bead by bead."
	blue_pearled_desc = "A string of living dreamfiend eyes where once there were anal beads, warped by a blue pearl. Ahh, Abyssor, or some say Great Tide... Do you hear our dreams? As you once did for the everlurking Leviathan, Grant us eyes, grant us eyes. Shove eyes in our stomachs, to purify our rotfested lux..."
	bead_count = "short"

/obj/item/intimate_accessory/rear/plug/analbeads/proc/get_bead_length()
	if(bead_count == "medium" || bead_count == "long")
		return bead_count
	return "short"

/obj/item/intimate_accessory/rear/plug/analbeads/update_item_visuals()
	cut_overlays()
	if(src.blue_pearled)
		color = initial(color)
		item_state = "rear_beads_item_abyssor"
		icon_state = "rear_beads_item_abyssor"
		update_icon()
		return

	apply_intimate_item_tint()

	var/length = get_bead_length()
	var/lookup_state = "rear_beads_item_[length]"
	item_state = lookup_state
	icon_state = lookup_state

	var/special_overlay_state = get_special_rear_item_state("rear_beads_item", length)
	if(special_overlay_state)
		add_overlay(mutable_appearance(icon, special_overlay_state))
	else if(has_socketed_insert())
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, "rear_beads_item_[length]_gem")
		if(intimate_gem_color)
			gem_overlay.color = intimate_gem_color
		add_overlay(gem_overlay)
	update_icon()

/obj/item/intimate_accessory/rear/plug/analbeads/try_socket_blue_pearl(obj/item/pearl/blue/pearl, mob/living/user)
	if(!pearl || !user)
		return FALSE
	if(has_socketed_insert())
		to_chat(user, span_warning("[src] already has something socketed in it."))
		return TRUE
	if(wearer)
		to_chat(user, span_warning("I need to remove [src] before socketing a blue pearl into it."))
		return TRUE

	var/obj/item/intimate_accessory/rear/plug/analbeads/abyssor/new_beads = new /obj/item/intimate_accessory/rear/plug/analbeads/abyssor(get_turf(src))
	new_beads.bead_count = bead_count
	new_beads.intimate_metal_name = intimate_metal_name
	new_beads.intimate_metal_color = intimate_metal_color
	new_beads.is_silver = is_silver
	new_beads.base_sellprice = base_sellprice
	new_beads.gem_value_bonus = max(0, pearl.sellprice)
	new_beads.current_gem_descriptor = "blue pearl"
	new_beads.intimate_gem_color = "#60C9FF"
	new_beads.refresh_socket_flags()
	new_beads.refresh_rear_plug_state()

	to_chat(user, span_notice("I set [pearl] into [src], and the whole string warps into Abyssor's watching eyes."))
	playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)

	qdel(pearl)
	if(!user.put_in_hands(new_beads))
		new_beads.forceMove(get_turf(user))
	qdel(src)
	return TRUE

/obj/item/intimate_accessory/rear/plug/analbeads/fivebeads
	bead_count = "medium"
	desc = "A set of five anal beads designed for the rear. They have a ring of sockets around each bead."
	default_desc = "A set of five anal beads designed for the rear. They have a ring of sockets around each bead."

/obj/item/intimate_accessory/rear/plug/analbeads/sixbeads
	bead_count = "long"
	desc = "A set of six anal beads designed for the rear. This is gonna be a tight fit. They have a ring of sockets around each bead."
	default_desc = "A set of six anal beads designed for the rear. This is gonna be a tight fit They have a ring of sockets around each bead."

/obj/item/intimate_accessory/rear/plug/analbeads/abyssor
	name = "String of Eyes"
	desc = "A string of dreamfiend eyes where once there were anal beads, warped by a blue pearl. Ahh, Abyssor, or some say Great Tide... Do you hear our dreams? As you once did for the everlurking Leviathan, Grant us eyes, grant us eyes. Shove eyes in our stomachs, to purify our rotfested lux..."
	blue_pearled = TRUE
	blue_pearled_name = "String of Eyes"

/obj/item/intimate_accessory/rear/plug/analbeads/abyssor/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("This transformation is permanent; the blue pearl cannot be removed."))
	return TRUE

/obj/item/intimate_accessory/rear/plug/analbeads/abyssor/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel) || istype(I, /obj/item/pearl/blue) || istype(I, /obj/item/roguegem) || is_psydonic_socket_item(I) || is_zizite_socket_item(I))
		return try_extract_socketed_item(user)
	return ..()

/obj/item/intimate_accessory/rear/plug/analbeads/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/rear/plug/analbeads/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/rear/plug/analbeads/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/rear/plug/analbeads/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/rear/plug/analbeads/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/rear/plug/analbeads/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/rear/plug/analbeads/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

/obj/item/intimate_accessory/rear/plug/iron
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/rear/plug/copper
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/rear/plug/steel
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/rear/plug/bronze
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/rear/plug/silver
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/rear/plug/gold
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/rear/plug/blacksteel
	intimate_metal_name = "blacksteel"
	intimate_metal_color = "#A2CBE3"
	sellprice = 150

/obj/item/intimate_accessory/rear/plug/wood
	intimate_metal_name = "wooden"
	intimate_metal_color = "#7D4033"
	resistance_flags = FLAMMABLE
	sellprice = 1

/obj/item/intimate_accessory/rear/plug/stone
	intimate_metal_name = "stone"
	intimate_metal_color = "#6E6E6E"
	sellprice = 3

// Compatibility aliases for older rear plug paths.
/obj/item/intimate_accessory/plug/rear
	parent_type = /obj/item/intimate_accessory/rear/plug

/obj/item/intimate_accessory/plug/rear/plug
	parent_type = /obj/item/intimate_accessory/rear/plug

/obj/item/intimate_accessory/plug/rear/analbeads
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads

/obj/item/intimate_accessory/plug/rear/analbeads/abyssor
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/abyssor

/obj/item/intimate_accessory/plug/rear/analbeads/iron
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/iron

/obj/item/intimate_accessory/plug/rear/analbeads/copper
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/copper

/obj/item/intimate_accessory/plug/rear/analbeads/steel
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/steel

/obj/item/intimate_accessory/plug/rear/analbeads/bronze
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/bronze

/obj/item/intimate_accessory/plug/rear/analbeads/silver
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/silver

/obj/item/intimate_accessory/plug/rear/analbeads/gold
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/gold

/obj/item/intimate_accessory/plug/rear/analbeads/blacksteel
	parent_type = /obj/item/intimate_accessory/rear/plug/analbeads/blacksteel

/obj/item/intimate_accessory/plug/rear/buttplug
	parent_type = /obj/item/intimate_accessory/rear/plug/buttplug

/obj/item/intimate_accessory/plug/rear/iron
	parent_type = /obj/item/intimate_accessory/rear/plug/iron

/obj/item/intimate_accessory/plug/rear/copper
	parent_type = /obj/item/intimate_accessory/rear/plug/copper

/obj/item/intimate_accessory/plug/rear/steel
	parent_type = /obj/item/intimate_accessory/rear/plug/steel

/obj/item/intimate_accessory/plug/rear/bronze
	parent_type = /obj/item/intimate_accessory/rear/plug/bronze

/obj/item/intimate_accessory/plug/rear/silver
	parent_type = /obj/item/intimate_accessory/rear/plug/silver

/obj/item/intimate_accessory/plug/rear/gold
	parent_type = /obj/item/intimate_accessory/rear/plug/gold

/obj/item/intimate_accessory/plug/rear/blacksteel
	parent_type = /obj/item/intimate_accessory/rear/plug/blacksteel

/obj/item/intimate_accessory/plug/rear/wood
	parent_type = /obj/item/intimate_accessory/rear/plug/wood

/obj/item/intimate_accessory/plug/rear/stone
	parent_type = /obj/item/intimate_accessory/rear/plug/stone

// Genital plug variants.
/obj/item/intimate_accessory/genital/plug
	name = "steel vaginal plug"
	desc = "A smooth, tapered plug meant to sit snugly in the cunt. It holds what is pressed into it and leaves behind a quiet, needy pressure."
	icon_state = "genital_plug_item_1"
	item_state = "genital_plug_item_1"
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
	var/genital_insertable_noun = "vaginal plug"

/obj/item/intimate_accessory/genital/plug/Initialize()
	. = ..()
	update_dynamic_name()
	update_item_visuals()
	// Attach the insertable reaction component for passive shift messages and sex-action flavor text.
	AddComponent(/datum/component/intimate_reaction/insertable)

/obj/item/intimate_accessory/genital/plug/proc/get_metal_descriptor()
	if(!intimate_metal_name)
		return "metal"
	return lowertext(intimate_metal_name)

/obj/item/intimate_accessory/genital/plug/proc/update_dynamic_name()
	var/metal_descriptor = get_metal_descriptor()
	if(current_gem_descriptor)
		name = "[current_gem_descriptor]-set [metal_descriptor] [genital_insertable_noun]"
	else
		name = "[metal_descriptor] [genital_insertable_noun]"

/obj/item/intimate_accessory/genital/plug/proc/update_item_visuals()
	cut_overlays()
	apply_intimate_item_tint()
	icon_state = "genital_plug_item_1"
	item_state = "genital_plug_item_1"
	if(has_socketed_insert())
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, "genital_plug_item_2")
		if(intimate_gem_color)
			gem_overlay.color = intimate_gem_color
		add_overlay(gem_overlay)
	update_icon()

/obj/item/intimate_accessory/genital/plug/can_attach_target(mob/living/carbon/human/H, mob/user)
	. = ..()
	if(!.)
		return FALSE
	if(!check_genital_anatomy(H, user))
		return FALSE
	return TRUE

/// Checks whether the target has the required anatomy for this genital plug.
/// Base genital plugs require a vagina; sounding rods override to require a penis.
/obj/item/intimate_accessory/genital/plug/proc/check_genital_anatomy(mob/living/carbon/human/H, mob/user)
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
	if(H && H.intimate_genital_insertable == src)
		if(!H.sexcon?.release_retained_internal_creampie(H))
			playsound(H, 'sound/items/uncork.ogg', 45, TRUE, ignore_walls = FALSE)
	return ..()

/obj/item/intimate_accessory/genital/plug/on_socket_state_changed(reason = "")
	update_dynamic_name()
	update_item_visuals()
	return ..()

/obj/item/intimate_accessory/genital/plug/handle_passive_insertable_effect(mob/living/carbon/human/H)
	if(!H || H.intimate_genital_insertable != src)
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

// ── Sounding Rod — penis-slot genital plug ───────────────────────────────────
// A thin, smooth rod designed to be inserted into the urethra.
// Uses the GENITAL slot but requires a penis instead of a vagina.

/obj/item/intimate_accessory/genital/plug/sounding_rod
	name = "steel sounding rod"
	desc = "A thin, smooth steel rod with a gentle curve and a jewel cap. Designed for urethral insertion — a deeply intimate, deeply invasive form of stimulation that borders on the clinical."
	genital_insertable_noun = "sounding rod"

	icon_state = "sounding_plug_item_1"
	item_state = "sounding_plug_item_1"

/// Sounding rods require a penis instead of a vagina.
/// Calls grandparent (intimate_accessory) checks via ..(), then substitutes our own anatomy requirement.
/// Sounding rods require a penis instead of a vagina.
/obj/item/intimate_accessory/genital/plug/sounding_rod/check_genital_anatomy(mob/living/carbon/human/H, mob/user)
	if(!H.getorganslot(ORGAN_SLOT_PENIS))
		to_chat(user, span_warning("[H] lacks the anatomy to wear [src]."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/genital/plug/sounding_rod/update_item_visuals()
	cut_overlays()
	apply_intimate_item_tint()
	icon_state = "sounding_plug_item_1"
	item_state = "sounding_plug_item_1"
	if(has_socketed_insert())
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, "sounding_plug_item_2")
		if(intimate_gem_color)
			gem_overlay.color = intimate_gem_color
		add_overlay(gem_overlay)
	update_icon()

/obj/item/intimate_accessory/genital/plug/sounding_rod/iron
	name = "iron sounding rod"
	intimate_metal_name = "iron"
	intimate_metal_color = "#9EA48E"
	sellprice = 5

/obj/item/intimate_accessory/genital/plug/sounding_rod/copper
	name = "copper sounding rod"
	intimate_metal_name = "copper"
	intimate_metal_color = "#8C4734"
	sellprice = 5

/obj/item/intimate_accessory/genital/plug/sounding_rod/steel
	name = "steel sounding rod"
	intimate_metal_name = "steel"
	intimate_metal_color = "#9BADB7"
	sellprice = 10

/obj/item/intimate_accessory/genital/plug/sounding_rod/bronze
	name = "bronze sounding rod"
	intimate_metal_name = "bronze"
	intimate_metal_color = "#CBBF9A"
	sellprice = 12

/obj/item/intimate_accessory/genital/plug/sounding_rod/silver
	name = "silver sounding rod"
	intimate_metal_name = "silver"
	intimate_metal_color = "#C6D5E1"
	sellprice = 30
	is_silver = TRUE

/obj/item/intimate_accessory/genital/plug/sounding_rod/gold
	name = "gold sounding rod"
	intimate_metal_name = "gold"
	intimate_metal_color = "#C4B651"
	sellprice = 50

/obj/item/intimate_accessory/genital/plug/sounding_rod/blacksteel
	name = "blacksteel sounding rod"
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
	intimate_invisibility_icon_state = "plug"
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
	var/tailplug_socketed = FALSE
	var/tailplug_tail_accessory_type = null
	var/tailplug_tail_colors = null
	var/tailplug_item_icon_base = null
	var/datum/bodypart_feature/intimate_tailplug/tailplug_tail_feature

/obj/item/intimate_accessory/rear/plug/proc/is_worn_in_rear_slot(mob/living/carbon/human/H)
	return !!(H && H.intimate_rear_insertable == src)

/obj/item/intimate_accessory/rear/plug/proc/play_plug_sound(mob/living/carbon/human/H, sound_file)
	if(H)
		playsound(H, sound_file, 45, TRUE, ignore_walls = FALSE)

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_tail_accessory_choices()
	var/static/list/tailplug_tail_accessory_choices
	if(!tailplug_tail_accessory_choices)
		tailplug_tail_accessory_choices = list()
		var/datum/customizer_choice/organ/tail/anthro/tail_choice = new
		for(var/accessory_type in tail_choice.sprite_accessories)
			var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(accessory_type)
			if(!accessory)
				continue
			tailplug_tail_accessory_choices[accessory.name] = accessory_type
		qdel(tail_choice)
	return tailplug_tail_accessory_choices.Copy()

/obj/item/intimate_accessory/rear/plug/proc/is_tailplug_tail_accessory_type(accessory_type)
	if(!ispath(accessory_type, /datum/sprite_accessory/tail))
		return FALSE
	var/list/tail_choices = get_tailplug_tail_accessory_choices()
	return !!find_key_by_value(tail_choices, accessory_type)

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_item_icon_choices()
	return list(
		"Dog tail" = "dogplug",
		"Cat tail" = "catplug",
		"Rat tail" = "ratplug",
		"Lizard tail" = "lizardplug",
		"Bunny tail" = "rabbitplug",
	)

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_item_icon_base(item_icon_choice)
	var/static/list/valid_icon_bases = list("dogplug", "catplug", "ratplug", "lizardplug", "rabbitplug")
	if(item_icon_choice in valid_icon_bases)
		return item_icon_choice
	var/list/icon_choices = get_tailplug_item_icon_choices()
	return icon_choices[item_icon_choice]

/obj/item/intimate_accessory/rear/plug/proc/prompt_tailplug_tail_colors(mob/living/user, tail_accessory_type)
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_accessory_type)
	if(!user || !accessory)
		return null
	var/color_string = accessory.get_default_colors(color_key_source_list_from_carbon(user))
	var/list/color_list = color_string_to_list(color_string)
	if(!color_list)
		color_list = list()
	while(length(color_list) < accessory.color_keys)
		color_list += "#FFFFFF"
	for(var/color_index in 1 to accessory.color_keys)
		var/color_name = accessory.color_key_name
		if(accessory.color_keys > 1 && length(accessory.color_key_names) >= color_index)
			color_name = accessory.color_key_names[color_index]
		var/new_color = color_pick_sanitized(user, "Choose the [color_name] color:", "Tailplug Tail", color_list[color_index])
		if(!new_color)
			return null
		color_list[color_index] = sanitize_hexcolor(new_color, 6, TRUE)
	return accessory.sanitize_color_string(color_list_to_string(color_list))

/obj/item/intimate_accessory/rear/plug/proc/try_socket_tail_fur(obj/item/natural/fur/fur, mob/living/user)
	if(!fur || !user)
		return FALSE
	if(has_socketed_insert())
		to_chat(user, span_warning("[src] already has something socketed in it."))
		return TRUE

	var/list/tail_choices = get_tailplug_tail_accessory_choices()
	var/chosen_tail_name = tgui_input_list(user, "Choose the tail sprite this will show while worn.", "Tailplug Tail", tail_choices)
	if(!chosen_tail_name || QDELETED(src) || QDELETED(fur) || user.incapacitated() || !in_range(user, src))
		return TRUE
	var/chosen_tail_type = tail_choices[chosen_tail_name]
	var/chosen_tail_colors = prompt_tailplug_tail_colors(user, chosen_tail_type)
	if(!chosen_tail_colors || QDELETED(src) || QDELETED(fur) || user.incapacitated() || !in_range(user, src))
		return TRUE

	var/list/icon_choices = get_tailplug_item_icon_choices()
	var/chosen_icon_name = tgui_input_list(user, "Choose the unequipped item tail shape.", "Tailplug Item", icon_choices)
	if(!chosen_icon_name || QDELETED(src) || QDELETED(fur) || user.incapacitated() || !in_range(user, src))
		return TRUE
	var/chosen_icon_base = icon_choices[chosen_icon_name]
	var/fur_name = fur.name
	if(!socket_tail_fur(fur, chosen_tail_type, chosen_tail_colors, chosen_icon_base))
		to_chat(user, span_warning("I can't socket [fur_name] into [src]."))
		return TRUE

	to_chat(user, span_notice("I socket [fur_name] into [src], setting the fake tail in place."))
	playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)
	return TRUE

/obj/item/intimate_accessory/rear/plug/proc/socket_tail_fur(obj/item/natural/fur/fur, tail_accessory_type, tail_color_string, item_icon_choice)
	if(fur && !istype(fur, /obj/item/natural/fur))
		return FALSE
	if(has_socketed_insert())
		return FALSE
	if(!is_tailplug_tail_accessory_type(tail_accessory_type))
		return FALSE
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tail_accessory_type)
	if(!accessory)
		return FALSE
	var/item_icon_base = get_tailplug_item_icon_base(item_icon_choice)
	if(!item_icon_base)
		return FALSE

	tailplug_socketed = TRUE
	tailplug_tail_accessory_type = tail_accessory_type
	tailplug_tail_colors = accessory.sanitize_color_string(tail_color_string)
	tailplug_item_icon_base = item_icon_base
	socketed_item_type = fur ? fur.type : /obj/item/natural/fur
	current_gem_descriptor = accessory.name
	intimate_gem_color = get_tailplug_primary_color()
	gem_value_bonus = 0
	if(fur)
		qdel(fur)
	on_socket_state_changed("tail_socketed")
	return TRUE

/obj/item/intimate_accessory/rear/plug/proc/apply_roundstart_tail_socket(tail_accessory_type, tail_color_string, item_icon_choice)
	if(!socket_tail_fur(null, tail_accessory_type, tail_color_string, item_icon_choice))
		return FALSE
	roundstart_socket_breaks_on_extract = FALSE
	return TRUE

/obj/item/intimate_accessory/rear/plug/proc/is_tailplug()
	return tailplug_socketed && tailplug_tail_accessory_type && tailplug_item_icon_base

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_primary_color()
	var/list/color_list = color_string_to_list(tailplug_tail_colors)
	if(length(color_list) >= 1)
		return color_list[1]
	return "#FFFFFF"

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_tail_name()
	var/datum/sprite_accessory/tail/accessory = SPRITE_ACCESSORY(tailplug_tail_accessory_type)
	if(accessory?.name)
		return accessory.name
	return "fake tail"

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_noun()
	return "tailplug"

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_examine_plain_name()
	var/metal_descriptor = get_metal_descriptor()
	if(metal_descriptor)
		return "[get_tailplug_tail_name()] [metal_descriptor] [get_tailplug_noun()]"
	return "[get_tailplug_tail_name()] [get_tailplug_noun()]"

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_examine_colored_name()
	var/display_name = html_encode(get_tailplug_examine_plain_name())
	display_name = color_intimate_examine_token(display_name, html_encode(get_tailplug_tail_name()), get_tailplug_primary_color())
	if(intimate_metal_name && intimate_metal_color)
		display_name = color_intimate_examine_token(display_name, html_encode(lowertext(intimate_metal_name)), intimate_metal_color)
	return display_name

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_pull_observer_message(mob/living/carbon/human/target, mob/living/puller)
	if(!target || !is_tailplug())
		return null
	var/puller_name = puller ? "[puller]" : "Someone"
	return span_love("[puller_name] yanks [target]'s [get_tailplug_examine_plain_name()] by the tail, and the toy pops free with a slick tug.")

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_pull_self_message(mob/living/carbon/human/target, mob/living/puller)
	if(!target || !is_tailplug())
		return null
	var/puller_name = puller ? "[puller]" : "Someone"
	return span_love("[puller_name] yanks my [get_tailplug_examine_plain_name()] by the tail, and the toy pops free with a slick tug.")

/obj/item/intimate_accessory/rear/plug/proc/show_tailplug_pull_message(mob/living/carbon/human/target, mob/living/puller)
	var/observer_message = get_tailplug_pull_observer_message(target, puller)
	if(!observer_message)
		return
	target.visible_message(observer_message, get_tailplug_pull_self_message(target, puller))

/obj/item/intimate_accessory/rear/plug/proc/can_user_identify_tailplug(mob/user)
	if(isobserver(user))
		return TRUE
	if(!isliving(user))
		return FALSE
	var/mob/living/L = user
	return L.STAPER >= 10

/obj/item/intimate_accessory/rear/plug/proc/get_tailplug_examine_line(mob/living/carbon/human/examined, mob/user)
	if(!examined || !is_tailplug() || !can_user_identify_tailplug(user))
		return null
	var/accessory_name = examined.get_examine_item_name_with_hover(user, src, get_tailplug_examine_colored_name())
	var/accessory_article = get_intimate_examine_article()
	return "[examined.p_they(TRUE)] [examined.p_have()] [accessory_article] [accessory_name] up [examined.p_their()] rear."

/obj/item/intimate_accessory/rear/plug/get_intimate_examine_line(mob/living/carbon/human/examined, mob/user, part, part_plural = FALSE)
	if(is_tailplug())
		return get_tailplug_examine_line(examined, user)
	return ..()

/obj/item/intimate_accessory/rear/plug/get_intimate_examine_plain_name()
	if(is_tailplug())
		return get_tailplug_examine_plain_name()
	return ..()

/obj/item/intimate_accessory/rear/plug/get_intimate_examine_colored_name()
	if(is_tailplug())
		return get_tailplug_examine_colored_name()
	return ..()

/obj/item/intimate_accessory/rear/plug/proc/update_tailplug_item_visuals(layer_index)
	cut_overlays()
	apply_intimate_item_tint()
	var/base_state = "[tailplug_item_icon_base][layer_index]"
	item_state = base_state
	icon_state = base_state
	var/tail_state = "[tailplug_item_icon_base]3"
	if(icon_exists(icon, tail_state))
		var/mutable_appearance/tail_overlay = mutable_appearance(icon, tail_state)
		tail_overlay.color = get_tailplug_primary_color()
		add_overlay(tail_overlay)
	update_icon()

/obj/item/intimate_accessory/rear/plug/proc/remove_tailplug_tail_feature(mob/living/carbon/human/H)
	if(!tailplug_tail_feature)
		return
	if(H)
		var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
		if(chest)
			chest.remove_bodypart_feature(tailplug_tail_feature)
	tailplug_tail_feature = null

/obj/item/intimate_accessory/rear/plug/proc/yank_tailplug_from(mob/living/carbon/human/target, mob/living/puller)
	if(!target || !is_tailplug())
		return FALSE
	if(istype(src, /obj/item/intimate_accessory/rear/plug/analbeads))
		var/obj/item/intimate_accessory/rear/plug/analbeads/beads = src
		if(beads.beads_inserted > 0)
			var/mob/pull_actor = puller ? puller : target
			var/message = beads.get_ripcord_message(pull_actor, target, FALSE)
			if(message)
				target.visible_message(span_warning(message))
			beads.on_ripcord(pull_actor, target, FALSE)
			beads.beads_inserted = 0
	else
		show_tailplug_pull_message(target, puller)
		if(target.sexcon && !target.sexcon.arousal_frozen)
			target.sexcon.adjust_arousal(80)
	remove_intimate_accessory(target)
	if(QDELETED(src))
		return TRUE
	if(puller)
		if(!puller.put_in_hands(src))
			forceMove(get_turf(puller))
	else
		forceMove(get_turf(target))
	return TRUE

/mob/living/proc/can_pulltail_with_free_hand()
	var/list/empty_hands = get_empty_held_indexes()
	if(!length(empty_hands))
		return FALSE
	for(var/hand_index in empty_hands)
		if(has_hand_for_held_index(hand_index, TRUE))
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/get_fake_tailplug()
	var/obj/item/intimate_accessory/rear/plug/rear_insertable = intimate_rear_insertable
	if(istype(rear_insertable) && rear_insertable.is_tailplug())
		return rear_insertable
	return null

/mob/living/carbon/human/proc/has_pulltail_target()
	if(getorganslot(ORGAN_SLOT_TAIL))
		return TRUE
	return !!get_fake_tailplug()

/mob/living/carbon/human/proc/try_pull_fake_tail(mob/living/puller, force_remove = FALSE)
	var/obj/item/intimate_accessory/rear/plug/fake_tail = get_fake_tailplug()
	if(!fake_tail)
		return FALSE
	if(!force_remove && !prob(10))
		return FALSE
	return fake_tail.yank_tailplug_from(src, puller)

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
	remove_tailplug_tail_feature(H)
	return ..()

/obj/item/intimate_accessory/rear/plug/proc/update_sellprice()
	var/effective_base = roundstart_equipped ? 0 : base_sellprice
	sellprice = max(1, effective_base + gem_value_bonus)

/obj/item/intimate_accessory/rear/plug/proc/update_item_visuals()
	cut_overlays()

	if(is_tailplug())
		update_tailplug_item_visuals(1)
		return

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

/obj/item/intimate_accessory/rear/plug/has_visual_intimate_feature()
	if(is_tailplug())
		return TRUE
	return ..()

/obj/item/intimate_accessory/rear/plug/ensure_intimate_feature(mob/living/carbon/human/H)
	if(!is_tailplug())
		return ..()
	if(tailplug_tail_feature)
		return TRUE
	var/datum/bodypart_feature/intimate_tailplug/new_feature = new
	new_feature.feature_slot = "intimate_tailplug_tail_[get_effective_intimate_slot()]"
	new_feature.set_accessory_type(tailplug_tail_accessory_type, tailplug_tail_colors, H)
	new_feature.accessory_item = src
	tailplug_tail_feature = new_feature
	return TRUE

/obj/item/intimate_accessory/rear/plug/attach_intimate_feature(mob/living/carbon/human/H)
	if(!is_tailplug())
		return ..()
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	if(!chest)
		return FALSE
	if(!tailplug_tail_feature)
		ensure_intimate_feature(H)
	return chest.add_bodypart_feature(tailplug_tail_feature)

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

	return ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/inhumen/ancient) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/inhumen)

/obj/item/intimate_accessory/rear/plug/proc/is_psydonic_socket_type(socket_type)
	if(!socket_type)
		return FALSE

	if(is_zizite_socket_type(socket_type))
		return FALSE

	return ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/decrepit) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/silver) \
		|| ispath(socket_type, /obj/item/clothing/neck/roguetown/psicross/g)

/obj/item/intimate_accessory/rear/plug/proc/is_zizite_socket_item(obj/item/I)
	return !!(I && is_zizite_socket_type(I.type))

/obj/item/intimate_accessory/rear/plug/proc/is_psydonic_socket_item(obj/item/I)
	return !!(I && is_psydonic_socket_type(I.type))

/obj/item/intimate_accessory/rear/plug/proc/get_zizite_socket_descriptor(obj/item/cross)
	if(!cross)
		return "zcross"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/ancient))
		return "ancient zcross"
	return "iron zcross"

/obj/item/intimate_accessory/rear/plug/proc/get_zizite_socket_color(obj/item/cross)
	if(!cross)
		return "#9EA48E"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/inhumen/ancient))
		return "#BB9696"
	return "#9EA48E"

/obj/item/intimate_accessory/rear/plug/proc/get_psydonic_socket_descriptor(obj/item/clothing/neck/roguetown/psicross/cross)
	if(!cross)
		return "psycross"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/silver))
		return "silver psycross"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/g))
		return "golden psycross"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/decrepit))
		return "ancient psycross"
	return "stone psycross"

/obj/item/intimate_accessory/rear/plug/proc/get_psydonic_socket_color(obj/item/clothing/neck/roguetown/psicross/cross)
	if(!cross)
		return "#9BADB7"

	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/silver))
		return "#C6D5E1"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/g))
		return "#C4B651"
	if(istype(cross, /obj/item/clothing/neck/roguetown/psicross/decrepit))
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
	var/base_desc = default_desc
	if(is_beriddled())
		base_desc = beriddled_desc

	else if(blue_pearled)
		base_desc = blue_pearled_desc

	else if(zizite_socketed && zizite_desc)
		base_desc = zizite_desc

	else if(psydonic_socketed && psydonic_desc)
		base_desc = psydonic_desc

	desc = get_lubricated_description(base_desc)

/obj/item/intimate_accessory/rear/plug/on_lubrication_changed()
	update_description()
	if(wearer)
		notify_intimate_state_change(wearer, "lubricated")

/obj/item/intimate_accessory/rear/plug/proc/update_dynamic_name()
	var/metal_descriptor = get_metal_descriptor()
	if(is_tailplug())
		name = "[get_tailplug_tail_name()] [metal_descriptor] [get_tailplug_noun()]"
		return

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
	tailplug_socketed = ispath(socketed_item_type, /obj/item/natural/fur) && !!tailplug_tail_accessory_type && !!tailplug_item_icon_base

/obj/item/intimate_accessory/rear/plug/has_custom_socket_state()
	return beriddleed || blue_pearled || tailplug_socketed

/obj/item/intimate_accessory/rear/plug/clear_custom_socket_state()
	beriddleed = FALSE
	blue_pearled = FALSE
	psydonic_socketed = FALSE
	zizite_socketed = FALSE
	tailplug_socketed = FALSE
	tailplug_tail_accessory_type = null
	tailplug_tail_colors = null
	tailplug_item_icon_base = null
	remove_tailplug_tail_feature(wearer)
	desc = get_lubricated_description(default_desc)
	update_beriddleed_glow()

/obj/item/intimate_accessory/rear/plug/is_beriddled()
	return beriddleed || ispath(socketed_item_type, /obj/item/riddleofsteel)

/obj/item/intimate_accessory/rear/plug/on_beriddle_state_changed(new_state)
	if(!!new_state)
		beriddleed = TRUE
	else
		beriddleed = FALSE
	update_description()
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
	if(istype(I, /obj/item/natural/fur))
		return try_socket_tail_fur(I, user)

	if(is_psydonic_socket_item(I) || is_zizite_socket_item(I))
		return try_socket_special_cross(I, user)

	if(istype(I, /obj/item/pearl/blue))
		return try_socket_blue_pearl(I, user)

	return ..()

/obj/item/intimate_accessory/rear/plug/on_socket_state_changed(reason = "")
	refresh_socket_flags()
	on_beriddle_state_changed(is_beriddled())
	if(wearer)
		if(is_tailplug())
			remove_tailplug_tail_feature(wearer)
			attach_intimate_feature(wearer)
		else
			remove_tailplug_tail_feature(wearer)
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
	intimate_invisibility_icon_state = "beads"
	default_desc = "A set of four anal beads designed for the rear. They have a ring of sockets around each bead."
	rear_accessory_noun = "anal beads"
	intimate_metal_name = null
	intimate_metal_color = null
	beriddled_desc = "A set of anal beads infused with a riddle of steel. What a horrid waste."
	psydonic_desc = "A string of anal beads threaded with fixed psycross beadwork. Their quiet blue gleam makes the whole toy look half-wrought from star-and-clay."
	zizite_desc = "A string of anal beads threaded with fixed zcross beadwork and morbid accents. It carries the Dame of Progress's spite bead by bead."
	blue_pearled_desc = "A string of living dreamfiend eyes where once there were anal beads, warped by a blue pearl. Ahh, Abyssor, or some say Great Tide... Do you hear our dreams? As you once did for the everlurking Leviathan, Grant us eyes, grant us eyes. Shove eyes in our stomachs, to purify our rotfested lux..."
	bead_count = "short"
	/// How many individual beads are currently inserted. 0 = none inserted (not worn or just equipped).
	var/beads_inserted = 0
	var/mob/living/carbon/violent_rear_ejection_snared_owner

/obj/item/intimate_accessory/rear/plug/analbeads/proc/get_bead_length()
	if(bead_count == "medium" || bead_count == "long")
		return bead_count
	return "short"

/// Returns the maximum number of individual beads on this set. Short = 4, medium = 5, long = 6.
/obj/item/intimate_accessory/rear/plug/analbeads/proc/get_max_beads()
	switch(bead_count)
		if("long")
			return 6
		if("medium")
			return 5
	return 4

/obj/item/intimate_accessory/rear/plug/analbeads/get_tailplug_noun()
	return "tailbeads"

/obj/item/intimate_accessory/rear/plug/analbeads/get_tailplug_examine_plain_name()
	var/metal_descriptor = intimate_metal_name ? lowertext(intimate_metal_name) : null
	if(metal_descriptor)
		return "[get_tailplug_tail_name()] [metal_descriptor] [get_tailplug_noun()]"
	return "[get_tailplug_tail_name()] [get_tailplug_noun()]"

/obj/item/intimate_accessory/rear/plug/analbeads/get_tailplug_examine_line(mob/living/carbon/human/examined, mob/user)
	if(!examined || !is_tailplug() || !can_user_identify_tailplug(user))
		return null
	var/accessory_name = examined.get_examine_item_name_with_hover(user, src, get_tailplug_examine_colored_name())
	return "[examined.p_they(TRUE)] [examined.p_are()] wearing a set of [accessory_name] stuffed [intimate_accessory_count_word(beads_inserted)] beads deep."

/// Returns a custom visible_message for pushing a bead in. Override for bespoke insertion text.
/// Return null to use the default message.
/obj/item/intimate_accessory/rear/plug/analbeads/proc/get_push_bead_message(mob/user, mob/living/carbon/human/target)
	return null

/// Returns a custom visible_message for pulling a bead out. Override for bespoke removal text.
/// Return null to use the default message.
/obj/item/intimate_accessory/rear/plug/analbeads/proc/get_pull_bead_message(mob/user, mob/living/carbon/human/target)
	return null

/// Returns a visible_message for ripcording all beads out at once. Override for bespoke text.
/// `violent` is TRUE when the user is on strong intent.
/obj/item/intimate_accessory/rear/plug/analbeads/proc/get_ripcord_message(mob/user, mob/living/carbon/human/target, violent = FALSE)
	var/who = (user == target) ? "[user]" : "[target]"
	var/count = beads_inserted
	if(violent)
		return "[user] grabs the pull ring and rips all [count] beads out of [who] in one savage yank!"
	return "[user] grips the pull ring and steadily draws all [count] beads out of [who] in one long, continuous pull."

/// Called after ripcording. Override to apply bead-specific consequences.
/// `violent` is TRUE when the user was on strong intent.
/obj/item/intimate_accessory/rear/plug/analbeads/proc/on_ripcord(mob/user, mob/living/carbon/human/target, violent = FALSE)
	if(!target?.sexcon)
		return
	// Default: arousal spike and emote proportional to how many beads were yanked
	target.sexcon.set_arousal(MAX_AROUSAL)
	target.emote("sexmoanhvy", forced = TRUE)
	playsound(target, 'sound/misc/mat/pop.ogg', 60, TRUE, ignore_walls = FALSE)

/obj/item/intimate_accessory/rear/plug/analbeads/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/was_violent_rear_ejection = violent_rear_ejection_active
	. = ..()
	if(. || !was_violent_rear_ejection || !iscarbon(hit_atom))
		return
	var/mob/living/carbon/C = hit_atom
	ensnare_violent_rear_ejection(C)

/obj/item/intimate_accessory/rear/plug/analbeads/proc/ensnare_violent_rear_ejection(mob/living/carbon/C)
	if(!C || C.legcuffed || C.get_num_legs(FALSE) < 2)
		return FALSE
	visible_message(span_danger("\The [src] tangles around [C]'s legs!"))
	C.legcuffed = src
	violent_rear_ejection_snared_owner = C
	forceMove(C)
	C.update_inv_legcuffed()
	C.add_movespeed_modifier(MOVESPEED_ID_NET_SLOWDOWN, multiplicative_slowdown = 3)
	C.apply_status_effect(/datum/status_effect/debuff/netted)
	C.Knockdown(20)
	to_chat(C, span_danger("\The [src] tangles around my legs!"))
	addtimer(CALLBACK(src, PROC_REF(clear_violent_rear_ejection_snare)), 10 SECONDS, TIMER_OVERRIDE|TIMER_UNIQUE)
	return TRUE

/obj/item/intimate_accessory/rear/plug/analbeads/proc/clear_violent_rear_ejection_snare()
	var/mob/living/carbon/C = violent_rear_ejection_snared_owner
	violent_rear_ejection_snared_owner = null
	if(!C || QDELETED(C))
		return
	if(C.legcuffed == src)
		C.legcuffed = null
		C.update_inv_legcuffed()
	C.remove_movespeed_modifier(MOVESPEED_ID_NET_SLOWDOWN)
	if(C.has_status_effect(/datum/status_effect/debuff/netted))
		C.remove_status_effect(/datum/status_effect/debuff/netted)
	if(loc == C)
		forceMove(get_turf(C))

/obj/item/intimate_accessory/rear/plug/analbeads/dropped(mob/user, silent)
	clear_violent_rear_ejection_snare()
	return ..()

/obj/item/intimate_accessory/rear/plug/analbeads/Destroy()
	clear_violent_rear_ejection_snare()
	return ..()

/obj/item/intimate_accessory/rear/plug/analbeads/finalize_intimate_equip(mob/living/carbon/human/H)
	. = ..()
	// Start with one bead inserted when first equipped.
	if(beads_inserted <= 0)
		beads_inserted = 1

/// Applies arousal gain proportional to beads_inserted when removed, then resets count.
/// Plays a staggered pop sound for each bead pulled out.
/obj/item/intimate_accessory/rear/plug/analbeads/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && beads_inserted > 0)
		// Staggered pop sounds — one per bead, 3ds apart.
		for(var/i in 1 to beads_inserted)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(playsound), H, 'sound/misc/mat/pop.ogg', 45, TRUE, 0, null, null, null, FALSE, FALSE), (i - 1) * 3)
		// Arousal gain scales with how many beads were inside.
		if(H.sexcon && !H.sexcon.arousal_frozen)
			var/arousal_gain = beads_inserted * 3
			H.sexcon.adjust_arousal(arousal_gain)
	beads_inserted = 0
	return ..(H)

/// Override dynamic name: use the metal descriptor only when intimate_metal_name is set.
/// Shape subtypes without a metal set will use just their rear_accessory_noun.
/obj/item/intimate_accessory/rear/plug/analbeads/update_dynamic_name()
	var/metal_descriptor = intimate_metal_name ? lowertext(intimate_metal_name) : null

	if(is_tailplug())
		if(metal_descriptor)
			name = "[get_tailplug_tail_name()] [metal_descriptor] [get_tailplug_noun()]"
		else
			name = "[get_tailplug_tail_name()] [get_tailplug_noun()]"
		return

	if(is_beriddled())
		if(metal_descriptor)
			name = "beriddleed [metal_descriptor] [rear_accessory_noun]"
		else
			name = "beriddleed [rear_accessory_noun]"
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
		if(metal_descriptor)
			name = "[current_gem_descriptor]-set [metal_descriptor] [rear_accessory_noun]"
		else
			name = "[current_gem_descriptor]-set [rear_accessory_noun]"
	else
		if(metal_descriptor)
			name = "[metal_descriptor] [rear_accessory_noun]"
		else
			name = "[rear_accessory_noun]"

/obj/item/intimate_accessory/rear/plug/analbeads/update_item_visuals()
	cut_overlays()
	if(is_tailplug())
		update_tailplug_item_visuals(2)
		return

	if(src.blue_pearled)
		color = initial(color)
		item_state = "rear_bead_item_abyssor"
		icon_state = "rear_bead_item_abyssor"
		update_icon()
		return

	apply_intimate_item_tint()

	var/length = get_bead_length()
	// DMI uses "rear_beads_item_short" (plural) for the short variant only;
	// all other lengths use "rear_bead_item_[length]" (singular).
	var/lookup_state
	if(length == "short")
		lookup_state = "rear_beads_item_short"
	else
		lookup_state = "rear_bead_item_[length]"
	item_state = lookup_state
	icon_state = lookup_state

	var/special_prefix = (length == "short") ? "rear_beads_item" : "rear_bead_item"
	var/special_overlay_state = get_special_rear_item_state(special_prefix, length)
	if(special_overlay_state)
		add_overlay(mutable_appearance(icon, special_overlay_state))
	else if(has_socketed_insert())
		var/mutable_appearance/gem_overlay = mutable_appearance(icon, "[lookup_state]_gem")
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
	new_beads.socketed_item_type = pearl.type
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
	default_desc = "A set of six anal beads designed for the rear. This is gonna be a tight fit. They have a ring of sockets around each bead."

/obj/item/intimate_accessory/rear/plug/analbeads/abyssor
	name = "String of Eyes"
	desc = "A string of dreamfiend eyes where once there were anal beads, warped by a blue pearl. Ahh, Abyssor, or some say Great Tide... Do you hear our dreams? As you once did for the everlurking Leviathan, Grant us eyes, grant us eyes. Shove eyes in our stomachs, to purify our rotfested lux..."
	blue_pearled = TRUE
	blue_pearled_name = "String of Eyes"

/obj/item/intimate_accessory/rear/plug/analbeads/abyssor/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("You can't un-eyeball the string of eyes, dullard."))
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

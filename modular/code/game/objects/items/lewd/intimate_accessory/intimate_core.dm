// Base item data and shared slot/access helpers.
/obj/item/intimate_accessory
	name = "intimate accessory"
	desc = "A personal accessory meant for intimate wear. If you're seeing this report it as a bug."
	icon = 'modular/icons/obj/lewd/intimate_accessories.dmi'
	icon_state = "rear_plug"
	mob_overlay_icon = "rear_plug"
	lefthand_file = 'modular/icons/mob/inhands/lewd/items_lefthand.dmi'
	righthand_file = 'modular/icons/mob/inhands/lewd/items_righthand.dmi'
	w_class = WEIGHT_CLASS_TINY
	grid_height = 32
	grid_width = 32
	throw_speed = 0.5
	var/intimate_slot = INTIMATE_SLOT_MISC
	var/intimate_flags = 0
	var/intimate_metal_name = "steel"
	var/intimate_metal_color = "#9BADB7"
	var/intimate_gem_color = "#55D6FF"
	var/socketed_item_type = null
	var/current_gem_descriptor = null
	var/gem_value_bonus = 0
	var/intimate_retains_internal_creampie = FALSE
	var/intimate_passive_insertable_effect = FALSE
	var/list/supported_intimate_slots = null
	var/current_intimate_slot = null
	var/sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_genital 
	var/datum/bodypart_feature/intimate_accessory/intimate_feature
	var/mob/living/carbon/human/wearer
	// nudist_approved = TRUE // prep for nudist PR being made by another person.

/obj/item/intimate_accessory/proc/get_intimate_color_string()
	var/metal_color = intimate_metal_color
	if(!metal_color)
		metal_color = color
	if(!metal_color)
		metal_color = "#FFFFFF"

	var/list/colors = list(metal_color)
	var/datum/sprite_accessory/intimate_overlays/accessory = SPRITE_ACCESSORY(sprite_acc)
	if(accessory?.color_keys >= 2)
		var/gem_color = intimate_gem_color
		if(!gem_color)
			gem_color = metal_color
		colors += gem_color

	return color_list_to_string(colors)


/obj/item/intimate_accessory/proc/get_supported_intimate_slots()
	if(length(supported_intimate_slots))
		return supported_intimate_slots.Copy()
	return list(intimate_slot)

/obj/item/intimate_accessory/proc/is_multi_slot_accessory()
	return length(get_supported_intimate_slots()) > 1

/obj/item/intimate_accessory/proc/supports_intimate_slot(slot)
	return slot in get_supported_intimate_slots()

/obj/item/intimate_accessory/proc/get_effective_intimate_slot(slot_override = null)
	if(!isnull(slot_override))
		return slot_override
	if(!isnull(current_intimate_slot))
		return current_intimate_slot
	return intimate_slot

/obj/item/intimate_accessory/proc/set_current_intimate_slot(slot)
	if(isnull(slot))
		current_intimate_slot = null
		return TRUE
	if(!supports_intimate_slot(slot))
		return FALSE
	current_intimate_slot = slot
	return TRUE

/obj/item/intimate_accessory/proc/get_intimate_slot_display_name(slot_override = null)
	switch(get_effective_intimate_slot(slot_override))
		if(INTIMATE_SLOT_GENITAL)
			return "Genital"
		if(INTIMATE_SLOT_REAR)
			return "Rear"
		if(INTIMATE_SLOT_BREAST)
			return "Breast"
		if(INTIMATE_SLOT_MOUTH)
			return "Mouth"
		else
			return "Misc"

/obj/item/intimate_accessory/proc/get_intimate_slot_name_map()
	var/list/name_map = list()
	for(var/slot in get_supported_intimate_slots())
		name_map["[slot]"] = get_intimate_slot_display_name(slot)
	return name_map

/obj/item/intimate_accessory/proc/get_intimate_ui_data()
	var/list/data = list()
	data["current_slot"] = get_effective_intimate_slot()
	data["current_slot_name"] = get_intimate_slot_display_name()
	data["supported_slots"] = get_supported_intimate_slots()
	data["supported_slot_names"] = get_intimate_slot_name_map()
	data["multi_slot"] = is_multi_slot_accessory()
	return data

/obj/item/intimate_accessory/proc/can_attach_target(mob/living/carbon/human/H, mob/user)
	if(!H)
		return FALSE
	if(!H.mind)
		to_chat(user, span_warning("[H] cannot be fitted with [src] right now."))
		return FALSE
	if(istype(H, /mob/living/carbon/human/species/werewolf))
		to_chat(user, span_warning("[H]'s transformed body cannot be fitted with [src]."))
		return FALSE
	if(is_silver && HAS_TRAIT(H, TRAIT_SILVER_WEAK))
		to_chat(user, span_warning("[H] recoils from silver; [src] cannot be worn."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/proc/get_slot_var_name(slot_override = null)
	switch(get_effective_intimate_slot(slot_override))
		if(INTIMATE_SLOT_GENITAL)
			return "intimate_genital"
		if(INTIMATE_SLOT_REAR)
			return "intimate_rear"
		if(INTIMATE_SLOT_BREAST)
			return "intimate_breast"
		if(INTIMATE_SLOT_MOUTH)
			return "intimate_mouth"
		else
			return "intimate_misc"

/obj/item/intimate_accessory/proc/get_worn_in_slot(mob/living/carbon/human/H, slot_override = null)
	if(!H)
		return null
	if(get_effective_intimate_slot(slot_override) == INTIMATE_SLOT_MOUTH)
		return H.intimate_mouth ? H.intimate_mouth : H.intimate_misc
	return H.vars[get_slot_var_name(slot_override)]

/obj/item/intimate_accessory/proc/set_worn_in_slot(mob/living/carbon/human/H, obj/item/intimate_accessory/new_value, slot_override = null)
	if(!H)
		return
	if(get_effective_intimate_slot(slot_override) == INTIMATE_SLOT_MOUTH)
		H.intimate_mouth = new_value
		H.intimate_misc = new_value
		return
	H.vars[get_slot_var_name(slot_override)] = new_value

/obj/item/intimate_accessory/proc/clear_worn_slot_refs(mob/living/carbon/human/H)
	if(!H)
		return
	if(H.intimate_genital == src)
		H.intimate_genital = null
	if(H.intimate_rear == src)
		H.intimate_rear = null
	if(H.intimate_breast == src)
		H.intimate_breast = null
	if(H.intimate_mouth == src)
		H.intimate_mouth = null
	if(H.intimate_misc == src)
		H.intimate_misc = null

/obj/item/intimate_accessory/proc/is_slot_available(mob/living/carbon/human/H, slot_override = null)
	return !get_worn_in_slot(H, slot_override)

/obj/item/intimate_accessory/proc/get_slot_unavailable_message(mob/living/carbon/human/H, mob/user, slot_override = null)
	var/slot_name = lowertext(get_intimate_slot_display_name(slot_override))
	if(H == user)
		return "That [slot_name] intimate slot is already occupied."
	return "That [slot_name] intimate slot on [H] is already occupied."

/obj/item/intimate_accessory/proc/bypasses_chastity_blockers(mob/living/carbon/human/H, slot_override = null)
	return FALSE

/obj/item/intimate_accessory/proc/can_attach_to_intimate_slot(mob/living/carbon/human/H, mob/user, slot, silent = FALSE, require_open_slot = TRUE)
	if(!supports_intimate_slot(slot))
		return FALSE
	if(require_open_slot && !is_slot_available(H, slot))
		if(!silent)
			to_chat(user, span_warning(get_slot_unavailable_message(H, user, slot)))
		return FALSE
	if(!passes_access_checks(H, user, slot, silent))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/proc/get_available_intimate_slots(mob/living/carbon/human/H, mob/user, require_open_slot = TRUE)
	var/list/available_slots = list()
	for(var/slot in get_supported_intimate_slots())
		if(can_attach_to_intimate_slot(H, user, slot, TRUE, require_open_slot))
			available_slots += slot
	return available_slots

/obj/item/intimate_accessory/proc/resolve_intimate_slot(mob/living/carbon/human/H, mob/user)
	var/list/supported_slots = get_supported_intimate_slots()
	if(!length(supported_slots))
		return intimate_slot

	var/list/available_slots = get_available_intimate_slots(H, user)
	if(!length(available_slots))
		for(var/slot in supported_slots)
			if(can_attach_to_intimate_slot(H, user, slot, FALSE))
				return slot
		return null

	if(length(available_slots) == 1)
		return available_slots[1]

	var/list/slot_labels = list()
	var/list/slot_by_label = list()
	for(var/slot in available_slots)
		var/slot_label = get_intimate_slot_display_name(slot)
		slot_labels += slot_label
		slot_by_label[slot_label] = slot

	var/default_label = slot_labels[1]
	var/current_label = get_intimate_slot_display_name()
	if(slot_by_label[current_label])
		default_label = current_label

	var/chosen_label = tgui_input_list(user, "Where should [src] be fitted?", "[src]", slot_labels, default_label)
	if(!chosen_label)
		return null
	return slot_by_label[chosen_label]

/obj/item/intimate_accessory/proc/has_visual_intimate_feature()
	return !isnull(sprite_acc)

/obj/item/intimate_accessory/proc/passes_access_checks(mob/living/carbon/human/H, mob/user, slot_override = null, silent = FALSE)
	if(H?.client?.prefs && !H.client.prefs.chastenable)
		if(!silent)
			to_chat(user, span_warning("[H] has chastity/intimate content disabled."))
		return FALSE
	if(user?.client?.prefs && !user.client.prefs.chastenable)
		if(!silent)
			to_chat(user, span_warning("I have chastity/intimate content disabled."))
		return FALSE

	var/effective_slot = get_effective_intimate_slot(slot_override)
	var/front_block_reason = front_access_block_reason(H, effective_slot)
	if(front_block_reason)
		if(!silent)
			to_chat(user, span_warning(front_block_reason))
		return FALSE
	var/rear_block_reason = rear_access_block_reason(H, effective_slot)
	if(rear_block_reason)
		if(!silent)
			to_chat(user, span_warning(rear_block_reason))
		return FALSE

	if(effective_slot == INTIMATE_SLOT_BREAST)
		if(!get_location_accessible(H, BODY_ZONE_CHEST))
			if(!silent)
				to_chat(user, span_warning("I cannot access [H]'s chest."))
			return FALSE
		return TRUE
	if(effective_slot == INTIMATE_SLOT_MOUTH)
		if(!get_location_accessible(H, BODY_ZONE_PRECISE_MOUTH))
			if(!silent)
				to_chat(user, span_warning("I cannot access [H]'s mouth."))
			return FALSE
		return TRUE
	if(!get_location_accessible(H, BODY_ZONE_PRECISE_GROIN))
		if(!silent)
			to_chat(user, span_warning("I cannot access [H]'s groin."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/proc/ensure_intimate_feature(mob/living/carbon/human/H)
	if(!has_visual_intimate_feature())
		return TRUE
	if(intimate_feature)
		return TRUE
	var/datum/bodypart_feature/intimate_accessory/new_feature = new
	new_feature.feature_slot = new_feature.get_feature_slot_for_item(src)
	call(new_feature, /datum/bodypart_feature/proc/set_accessory_type)(sprite_acc, get_intimate_color_string(), H)
	new_feature.accessory_item = src
	intimate_feature = new_feature
	return TRUE

/obj/item/intimate_accessory/proc/attach_intimate_feature(mob/living/carbon/human/H)
	if(!has_visual_intimate_feature())
		return TRUE
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	if(!chest)
		return FALSE
	if(!intimate_feature)
		ensure_intimate_feature(H)
	chest.add_bodypart_feature(intimate_feature)
	return TRUE

/mob/living/carbon/human/proc/has_passive_insertable_accessory()
	for(var/obj/item/intimate_accessory/accessory as anything in intimate_accessories)
		if(accessory?.can_emit_passive_insertable_effect())
			return TRUE
	return FALSE

/mob/living/carbon/human/proc/process_passive_insertable_effects()
	for(var/obj/item/intimate_accessory/accessory as anything in intimate_accessories)
		if(accessory?.can_emit_passive_insertable_effect())
			accessory.handle_passive_insertable_effect(src)

/mob/living/carbon/human/proc/resync_passive_insertable_effect_controller()
	if(has_passive_insertable_accessory())
		apply_status_effect(/datum/status_effect/passive_insertable_intimate_effects)
		return TRUE
	remove_status_effect(/datum/status_effect/passive_insertable_intimate_effects)
	return FALSE

/datum/status_effect/passive_insertable_intimate_effects
	id = "passive_insertable_intimate_effects"
	duration = -1
	tick_interval = 30 SECONDS
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null

/datum/status_effect/passive_insertable_intimate_effects/on_apply()
	if(!ishuman(owner))
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!H.has_passive_insertable_accessory())
		return FALSE
	return ..()

/datum/status_effect/passive_insertable_intimate_effects/tick()
	if(!ishuman(owner))
		qdel(src)
		return
	var/mob/living/carbon/human/H = owner
	if(!H.has_passive_insertable_accessory())
		qdel(src)
		return
	H.process_passive_insertable_effects()

// Equip/remove lifecycle.
/obj/item/intimate_accessory/proc/finalize_intimate_equip(mob/living/carbon/human/H)
	forceMove(H)
	clear_worn_slot_refs(H)
	set_worn_in_slot(H, src)
	wearer = H
	if(!(src in H.intimate_accessories))
		H.intimate_accessories += src
	do_silver_check(H) 
	register_wearer_intimate_signal(H)
	refresh_intimate_mood_effects(H)
	notify_intimate_state_change(H, "attached")

/obj/item/intimate_accessory/proc/do_silver_check(mob/living/victim)
	if(!is_silver || !HAS_TRAIT(victim, TRAIT_SILVER_WEAK))
		return
	SEND_SIGNAL(victim, COMSIG_FORCE_UNDISGUISE)
	var/datum/component/silverbless/blesscomp = GetComponent(/datum/component/silverbless)
	if(blesscomp?.is_blessed)
		if(!victim.has_status_effect(/datum/status_effect/fire_handler/fire_stacks/sunder))
			to_chat(victim, span_danger("Silver rebukes my presence! My vitae smolders, and my powers wane!"))
		victim.adjust_fire_stacks(3, /datum/status_effect/fire_handler/fire_stacks/sunder/blessed)
	else
		if(!victim.has_status_effect(/datum/status_effect/fire_handler/fire_stacks/sunder/blessed))
			to_chat(victim, span_danger("Blessed silver rebukes my presence! These fires are lashing at my very soul!"))
		victim.adjust_fire_stacks(3, /datum/status_effect/fire_handler/fire_stacks/sunder)
	victim.ignite_mob()

/obj/item/intimate_accessory/proc/notify_intimate_state_change(mob/living/carbon/human/H, reason = "")
	if(!H)
		return
	H.resync_passive_insertable_effect_controller()
	SEND_SIGNAL(H, COMSIG_CARBON_INTIMATE_STATE_CHANGED, src, reason)

/mob/living/carbon/human/proc/get_intimate_accessory_ui_data()
	var/list/data = list()
	for(var/obj/item/intimate_accessory/accessory as anything in intimate_accessories)
		if(!accessory)
			continue
		data["[REF(accessory)]"] = accessory.get_intimate_ui_data()
	return data

/obj/item/intimate_accessory/proc/remove_intimate_accessory(mob/living/carbon/human/H)
	if(!H)
		return
	clear_intimate_mood_effects(H)
	UnregisterSignal(H, COMSIG_CARBON_INTIMATE_STATE_CHANGED)
	clear_worn_slot_refs(H)
	if(src in H.intimate_accessories)
		H.intimate_accessories -= src
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	if(chest && intimate_feature) 
		chest.remove_bodypart_feature(intimate_feature)
	intimate_feature = null
	wearer = null
	set_current_intimate_slot(null)
	notify_intimate_state_change(H, "removed")

// Signal plumbing and mood hooks.
/obj/item/intimate_accessory/proc/register_wearer_intimate_signal(mob/living/carbon/human/H)
	if(!H)
		return
	UnregisterSignal(H, COMSIG_CARBON_INTIMATE_STATE_CHANGED)
	RegisterSignal(H, COMSIG_CARBON_INTIMATE_STATE_CHANGED, PROC_REF(on_intimate_state_changed))

/obj/item/intimate_accessory/proc/on_intimate_state_changed(datum/source, obj/item/intimate_accessory/accessory, reason)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	if(accessory != src)
		return
	refresh_intimate_mood_effects(wearer)

	// Refresh body overlays when this accessory changes state so visuals stay in sync.
	wearer.update_body()
	wearer.update_body_parts(TRUE)

/obj/item/intimate_accessory/proc/clear_intimate_mood_effects(mob/living/carbon/human/H)
	return

/obj/item/intimate_accessory/proc/refresh_intimate_mood_effects(mob/living/carbon/human/H)
	return

// Shared retention/passive capability hooks for insertable intimate items.
/obj/item/intimate_accessory/proc/retains_internal_creampie()
	return intimate_retains_internal_creampie

/obj/item/intimate_accessory/proc/can_emit_passive_insertable_effect()
	if(!(intimate_flags & INTIMATE_FLAG_INSERTABLE))
		return FALSE
	return intimate_passive_insertable_effect

/obj/item/intimate_accessory/proc/handle_passive_insertable_effect(mob/living/carbon/human/H)
	return FALSE

// Extension hooks for subtype-specific socket state that doesn't live in the shared socket vars.
/obj/item/intimate_accessory/proc/has_custom_socket_state()
	return FALSE

/obj/item/intimate_accessory/proc/clear_custom_socket_state()
	return

/obj/item/intimate_accessory/proc/can_be_beriddled()
	return !!(intimate_flags & INTIMATE_FLAG_BERIDDLEABLE)

/obj/item/intimate_accessory/proc/get_beriddle_socket_descriptor()
	return "riddle"

/obj/item/intimate_accessory/proc/get_beriddle_socket_color()
	return "#FF0D0D"

/obj/item/intimate_accessory/proc/get_beriddle_socket_type()
	return /obj/item/riddleofsteel

/obj/item/intimate_accessory/proc/get_beriddle_socket_value_bonus()
	return 0

/obj/item/intimate_accessory/proc/is_beriddled()
	return ispath(socketed_item_type, /obj/item/riddleofsteel)

/obj/item/intimate_accessory/proc/on_beriddle_state_changed(new_state)
	return

/obj/item/intimate_accessory/proc/apply_beriddle_state(obj/item/riddleofsteel/riddle)
	if(!can_be_beriddled())
		return FALSE
	if(has_socketed_insert())
		return FALSE

	if(!socket_item_by_type(
		get_beriddle_socket_type(),
		socket_descriptor = get_beriddle_socket_descriptor(),
		socket_color = get_beriddle_socket_color(),
		socket_value_bonus = get_beriddle_socket_value_bonus(),
		reason = "beriddle_changed"
	))
		return FALSE

	on_beriddle_state_changed(TRUE)
	return TRUE

// Generic socket metadata and color helpers.
/obj/item/intimate_accessory/proc/get_socket_descriptor_from_item(obj/item/I)
	if(!I)
		return null
	return lowertext(I.name)

/obj/item/intimate_accessory/proc/get_socket_color_from_item(obj/item/I)
	if(!I)
		return null
	if(istype(I, /obj/item/roguegem))
		var/obj/item/roguegem/gem = I
		var/static/list/gem_color_by_type = list(
			/obj/item/roguegem/ruby = "#B4142C",
			/obj/item/roguegem/green = "#2FAE5A",
			/obj/item/roguegem/jade = "#2FAE5A",
			/obj/item/roguegem/blue = "#60C9FF",
			/obj/item/roguegem/yellow = "#F0BE38",
			/obj/item/roguegem/amber = "#F0BE38",
			/obj/item/roguegem/violet = "#9A5CFF",
			/obj/item/roguegem/amethyst = "#9A5CFF",
			/obj/item/roguegem/diamond = "#EAF3FF",
			/obj/item/roguegem/opal = "#EAF3FF",
			/obj/item/roguegem/oyster = "#EAF3FF",
			/obj/item/roguegem/onyxa = "#1D2130",
			/obj/item/roguegem/coral = "#FF6E66",
			/obj/item/roguegem/turq = "#2CC6C8",
		)
		var/exact_color = gem_color_by_type[gem.type]
		if(exact_color)
			return exact_color

		for(var/gem_type in gem_color_by_type)
			if(istype(gem, gem_type))
				return gem_color_by_type[gem_type]

	if(I.color)
		return sanitize_hexcolor(I.color, 6, TRUE)

	return "#FFFFFF"

/obj/item/intimate_accessory/proc/has_socketed_insert()
	if(socketed_item_type)
		return TRUE
	if(has_custom_socket_state())
		return TRUE
	return FALSE

// Socket state transitions.
/obj/item/intimate_accessory/proc/on_socket_state_changed(reason = "")
	if(intimate_feature)
		intimate_feature.accessory_colors = get_intimate_color_string()

	if(wearer)
		notify_intimate_state_change(wearer, reason)

/obj/item/intimate_accessory/proc/reset_socketed_state()
	clear_custom_socket_state()

	socketed_item_type = null
	current_gem_descriptor = null
	intimate_gem_color = initial(intimate_gem_color)
	gem_value_bonus = 0
	on_beriddle_state_changed(FALSE)
	on_socket_state_changed("socket_reset")

// Socket operations.
/obj/item/intimate_accessory/proc/socket_item(obj/item/I, socket_descriptor = null, socket_color = null, socket_value_bonus = null, reason = "gem_changed")
	if(!I)
		return FALSE
	if(has_socketed_insert())
		return FALSE

	socketed_item_type = I.type
	current_gem_descriptor = socket_descriptor ? socket_descriptor : get_socket_descriptor_from_item(I)
	intimate_gem_color = socket_color ? socket_color : get_socket_color_from_item(I)
	if(isnull(socket_value_bonus))
		gem_value_bonus = max(0, I.sellprice)
	else
		gem_value_bonus = max(0, socket_value_bonus)

	on_socket_state_changed(reason)
	return TRUE

/obj/item/intimate_accessory/proc/socket_item_by_type(socket_type, socket_descriptor = null, socket_color = null, socket_value_bonus = 0, reason = "gem_changed")
	if(!socket_type || has_socketed_insert())
		return FALSE
	socketed_item_type = socket_type
	current_gem_descriptor = socket_descriptor
	intimate_gem_color = socket_color
	gem_value_bonus = max(0, socket_value_bonus)
	on_socket_state_changed(reason)
	return TRUE

/obj/item/intimate_accessory/proc/try_socket_gem(obj/item/roguegem/gem, mob/living/user)
	if(!gem || !user)
		return FALSE
	if(has_socketed_insert())
		to_chat(user, span_warning("[src] already has something socketed in it."))
		return TRUE

	if(!socket_item(gem, reason = "gem_changed"))
		to_chat(user, span_warning("I can't socket [gem] into [src]."))
		return TRUE

	to_chat(user, span_notice("I set [gem] into [src], changing its accent color."))
	playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)
	qdel(gem)
	return TRUE

/obj/item/intimate_accessory/proc/try_extract_socketed_item(mob/living/user)
	if(!user)
		return FALSE
	if(!has_socketed_insert())
		to_chat(user, span_warning("[src] has no socketed item to remove."))
		return TRUE
	if(wearer)
		to_chat(user, span_warning("I need to remove [src] before I can chisel out its socketed item."))
		return TRUE

	var/has_hammer = FALSE
	var/has_chisel = FALSE
	for(var/obj/item/held as anything in user.held_items)
		if(istype(held, /obj/item/rogueweapon/hammer))
			has_hammer = TRUE
		if(istype(held, /obj/item/rogueweapon/chisel))
			has_chisel = TRUE
	if(!has_hammer || !has_chisel)
		to_chat(user, span_warning("I need both a hammer and a chisel in hand to remove the socketed item."))
		return TRUE

	user.visible_message(span_warning("[user] braces a chisel against [src]'s socket and starts hammering!"), span_warning("I brace a chisel against [src]'s socket and start hammering!"))
	if(!do_after(user, 120, needhand = 1, target = src))
		return TRUE

	if(!has_socketed_insert())
		to_chat(user, span_warning("The socket is already empty."))
		return TRUE

	var/socket_path = socketed_item_type
	if(!socket_path)
		to_chat(user, span_warning("I can't recover what was in the socket."))
		reset_socketed_state()
		return TRUE

	playsound(get_turf(src), 'sound/items/indexer_open.ogg', 45, TRUE)
	var/obj/item/recovered_item = new socket_path(get_turf(src))
	user.visible_message(span_notice("[user] finally pries [recovered_item] out of [src]."), span_notice("I finally pry [recovered_item] out of [src]."))

	reset_socketed_state()
	if(!user.put_in_hands(recovered_item))
		recovered_item.forceMove(get_turf(src))
	return TRUE

// Item interactions.
/obj/item/intimate_accessory/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel))
		if(has_socketed_insert())
			return try_extract_socketed_item(user)
		return ..()

	if(istype(I, /obj/item/riddleofsteel))
		if(!can_be_beriddled())
			return ..()
		if(has_socketed_insert())
			to_chat(user, span_warning("[src] already has something socketed in it."))
			return TRUE
		if(!apply_beriddle_state(I))
			to_chat(user, span_warning("I can't socket [I] into [src]."))
			return TRUE

		to_chat(user, span_notice("I wastefully set [I] into [src], turning it into a beriddleed accessory."))
		playsound(get_turf(src), 'sound/items/gem.ogg', 50, TRUE)
		qdel(I)
		return TRUE

	if(istype(I, /obj/item/roguegem))
		return try_socket_gem(I, user)

	return ..()

/obj/item/intimate_accessory/Destroy()
	if(wearer)
		remove_intimate_accessory(wearer)
	return ..()

// Forced global removal helper.
/mob/living/carbon/human/proc/remove_all_intimate_accessories()
	if(!length(intimate_accessories))
		return 0

	var/removed_count = 0
	var/list/current_accessories = intimate_accessories.Copy()
	for(var/obj/item/intimate_accessory/accessory as anything in current_accessories)
		if(!accessory)
			continue
		accessory.remove_intimate_accessory(src)
		if(!QDELETED(accessory))
			accessory.forceMove(get_turf(src))
		removed_count++

	return removed_count

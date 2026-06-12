/proc/get_cursed_piercing_metal_options()
	return list(
		list("key" = "cursed", "label" = "Cursed Metal", "name" = "cursed", "color" = "#363636", "silver" = FALSE),
		list("key" = "iron", "label" = "Iron", "name" = "iron", "color" = "#9EA48E", "silver" = FALSE),
		list("key" = "copper", "label" = "Copper", "name" = "copper", "color" = "#8C4734", "silver" = FALSE),
		list("key" = "steel", "label" = "Steel", "name" = "steel", "color" = "#9BADB7", "silver" = FALSE),
		list("key" = "bronze", "label" = "Bronze", "name" = "bronze", "color" = "#CBBF9A", "silver" = FALSE),
		list("key" = "silver", "label" = "Silver", "name" = "silver", "color" = "#C6D5E1", "silver" = TRUE),
		list("key" = "gold", "label" = "Gold", "name" = "gold", "color" = "#C4B651", "silver" = FALSE),
		list("key" = "blacksteel", "label" = "Blacksteel", "name" = "blacksteel", "color" = "#A2CBE3", "silver" = FALSE),
		list("key" = "stone", "label" = "Stone", "name" = "stone", "color" = "#9BADB7", "silver" = FALSE),
		list("key" = "golden", "label" = "Golden", "name" = "golden", "color" = "#C4B651", "silver" = FALSE),
		list("key" = "ancient", "label" = "Ancient", "name" = "ancient", "color" = "#BB9696", "silver" = FALSE)
	)

/proc/get_cursed_piercing_gem_options()
	return list(
		list("key" = "cursed", "label" = "Cursed Rontz", "descriptor" = "cursed rontz", "color" = "#990033", "type" = /obj/item/roguegem/ruby),
		list("key" = "ruby", "label" = "Rontz", "descriptor" = "rontz", "color" = "#B4142C", "type" = /obj/item/roguegem/ruby),
		list("key" = "green", "label" = "Gemerald", "descriptor" = "gemerald", "color" = "#2FAE5A", "type" = /obj/item/roguegem/green),
		list("key" = "jade", "label" = "Jade", "descriptor" = "jade", "color" = "#2FAE5A", "type" = /obj/item/roguegem/jade),
		list("key" = "blue", "label" = "Blortz", "descriptor" = "blortz", "color" = "#60C9FF", "type" = /obj/item/roguegem/blue),
		list("key" = "yellow", "label" = "Toper", "descriptor" = "toper", "color" = "#F0BE38", "type" = /obj/item/roguegem/yellow),
		list("key" = "amber", "label" = "Amber", "descriptor" = "amber", "color" = "#F0BE38", "type" = /obj/item/roguegem/amber),
		list("key" = "violet", "label" = "Saffira", "descriptor" = "saffira", "color" = "#9A5CFF", "type" = /obj/item/roguegem/violet),
		list("key" = "amethyst", "label" = "Amythortz", "descriptor" = "amythortz", "color" = "#9A5CFF", "type" = /obj/item/roguegem/amethyst),
		list("key" = "diamond", "label" = "Dorpel", "descriptor" = "dorpel", "color" = "#EAF3FF", "type" = /obj/item/roguegem/diamond),
		list("key" = "opal", "label" = "Opal", "descriptor" = "opal", "color" = "#EAF3FF", "type" = /obj/item/roguegem/opal),
		list("key" = "oyster", "label" = "Fossilized Clam", "descriptor" = "fossilized clam", "color" = "#EAF3FF", "type" = /obj/item/roguegem/oyster),
		list("key" = "onyxa", "label" = "Onyxa", "descriptor" = "onyxa", "color" = "#1D2130", "type" = /obj/item/roguegem/onyxa),
		list("key" = "coral", "label" = "Heartstone", "descriptor" = "heartstone", "color" = "#FF6E66", "type" = /obj/item/roguegem/coral),
		list("key" = "turq", "label" = "Cerulite", "descriptor" = "cerulite", "color" = "#2CC6C8", "type" = /obj/item/roguegem/turq)
	)

/proc/find_cursed_piercing_option(list/options, key)
	if(!key)
		return null
	for(var/list/option as anything in options)
		if(option["key"] == key)
			return option
	return null

/obj/item/intimate_accessory/piercing/cursed
	name = "cursed piercing"
	desc = "A cursed gem-set piercing that answers to its master no matter where it is worn."
	icon_state = "genital_pierce_item"
	item_state = "genital_pierce_item"
	item_base_state = "genital_pierce_item"
	item_gem_state = "genital_pierce_item_gem"
	piercing_region_name = "piercing"
	intimate_slot = INTIMATE_SLOT_GENITAL
	intimate_metal_name = "cursed"
	intimate_metal_color = "#363636"
	intimate_gem_color = "#990033"
	intimate_flags = INTIMATE_FLAG_PIERCING
	sellprice = 0
	var/datum/mind/cursed_piercing_master
	var/roundstart_self_master_binding = FALSE
	var/applying = FALSE
	var/selected_metal_key = "cursed"
	var/selected_gem_key = "cursed"

/obj/item/intimate_accessory/piercing/cursed/Initialize()
	. = ..()
	set_cursed_gem(selected_gem_key, FALSE)
	sync_cursed_piercing_form()
	refresh_piercing_state()

/obj/item/intimate_accessory/piercing/cursed/get_supported_intimate_slots()
	return list(
		INTIMATE_SLOT_GENITAL,
		INTIMATE_SLOT_REAR,
		INTIMATE_SLOT_BREAST,
		INTIMATE_SLOT_MOUTH,
		INTIMATE_SLOT_EAR,
		INTIMATE_SLOT_NOSE,
		INTIMATE_SLOT_BELLY
	)

/obj/item/intimate_accessory/piercing/cursed/set_current_intimate_slot(slot)
	. = ..()
	if(.)
		sync_cursed_piercing_form()

/obj/item/intimate_accessory/piercing/cursed/proc/sync_cursed_piercing_form()
	switch(get_effective_intimate_slot())
		if(INTIMATE_SLOT_BREAST)
			item_base_state = "breast_pierce_item"
			item_gem_state = "breast_pierce_item_gem"
			piercing_region_name = "nipple"
			sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_breast
		if(INTIMATE_SLOT_REAR)
			item_base_state = "rear_pierce_item"
			item_gem_state = "rear_pierce_item_gem"
			piercing_region_name = "rear"
			sprite_acc = null
		if(INTIMATE_SLOT_MOUTH)
			item_base_state = "tongue_pierce_item"
			item_gem_state = "tongue_pierce_item_gem"
			piercing_region_name = "tongue"
			sprite_acc = null
		if(INTIMATE_SLOT_EAR)
			item_base_state = "ear_pierce_item"
			item_gem_state = "ear_pierce_item_gem"
			piercing_region_name = "ear"
			sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_ear
		if(INTIMATE_SLOT_NOSE)
			item_base_state = "nose_pierce_item"
			item_gem_state = "nose_pierce_item_gem"
			piercing_region_name = "nose"
			sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_nose
		if(INTIMATE_SLOT_BELLY)
			item_base_state = "belly_pierce_item"
			item_gem_state = "belly_pierce_item_gem"
			piercing_region_name = "belly button"
			sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_belly
		else
			item_base_state = "genital_pierce_item"
			item_gem_state = "genital_pierce_item_gem"
			piercing_region_name = "genital"
			sprite_acc = /datum/sprite_accessory/intimate_overlays/piercing_genital
	refresh_piercing_state()

/obj/item/intimate_accessory/piercing/cursed/attach_intimate_feature(mob/living/carbon/human/H)
	sync_cursed_piercing_form()
	return ..()

/obj/item/intimate_accessory/piercing/cursed/finalize_intimate_equip(mob/living/carbon/human/H)
	sync_cursed_piercing_form()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	play_piercing_sound(H, 'sound/foley/pierce.ogg')

/obj/item/intimate_accessory/piercing/cursed/remove_intimate_accessory(mob/living/carbon/human/H)
	cleanup_cursed_piercing_binding(H)
	if(H && get_worn_in_slot(H) == src)
		play_piercing_sound(H, 'sound/foley/equip/chain_equip.ogg')
	return ..()

/obj/item/intimate_accessory/piercing/cursed/passes_access_checks(mob/living/carbon/human/H, mob/user, slot_override = null, silent = FALSE)
	if(wearer == H && !applying)
		if(!silent)
			to_chat(user, span_warning("[src] is held fast by its curse."))
		return FALSE
	return ..()

/obj/item/intimate_accessory/piercing/cursed/proc/get_cursed_master_component()
	if(!cursed_piercing_master)
		return null
	return cursed_piercing_master.GetComponent(/datum/component/collar_master)

/obj/item/intimate_accessory/piercing/cursed/proc/format_cursed_piercing_message(string_key, list/replacements)
	var/message = pick_cursed_piercing_string("cursed_piercing_messages.json", string_key)
	if(!istext(message))
		return null
	if(islist(replacements))
		for(var/token in replacements)
			message = replacetext(message, token, replacements[token])
	return message

/obj/item/intimate_accessory/piercing/cursed/proc/send_cursed_piercing_message(mob/living/carbon/human/H, string_key, list/replacements, severity = "notice")
	if(!H)
		return FALSE
	var/message = format_cursed_piercing_message(string_key, replacements)
	if(!message)
		return FALSE
	switch(severity)
		if("danger")
			to_chat(H, span_userdanger(message))
		if("warning")
			to_chat(H, span_warning(message))
		else
			to_chat(H, span_notice(message))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/cleanup_cursed_piercing_binding(mob/living/carbon/human/H)
	REMOVE_TRAIT(src, TRAIT_NODROP, CURSED_ITEM_TRAIT)
	if(H)
		REMOVE_TRAIT(H, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE)

/obj/item/intimate_accessory/piercing/cursed/Destroy()
	if(wearer)
		cleanup_cursed_piercing_binding(wearer)
	return ..()

/obj/item/intimate_accessory/piercing/cursed/update_sellprice()
	sellprice = 0

/obj/item/intimate_accessory/piercing/cursed/try_extract_socketed_item(mob/living/user)
	if(user)
		to_chat(user, span_warning("The gem in [src] is part of the curse and cannot be pried free."))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/try_socket_gem(obj/item/roguegem/gem, mob/living/user)
	if(user)
		to_chat(user, span_warning("[src] rejects ordinary socketing; its appearance is controlled by its master."))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/roguegem) || istype(I, /obj/item/riddleofsteel) || istype(I, /obj/item/rogueweapon/hammer) || istype(I, /obj/item/rogueweapon/chisel))
		to_chat(user, span_warning("[src]'s cursed setting cannot be changed by hand."))
		return TRUE
	return ..()

/obj/item/intimate_accessory/piercing/cursed/attack_self(mob/user)
	if(!user?.mind)
		return
	if(wearer == user)
		to_chat(user, span_warning("[src] answers to its curse and will not loosen for me."))
		return
	cursed_piercing_master = user.mind
	if(!user.mind.GetComponent(/datum/component/collar_master))
		user.mind.AddComponent(/datum/component/collar_master)
	to_chat(user, span_notice("[src] grows warm as it learns my will."))

/obj/item/intimate_accessory/piercing/cursed/attack(mob/M, mob/user, def_zone)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(!can_apply_cursed_piercing(H, user))
		return

	var/slot = resolve_intimate_slot(H, user)
	if(isnull(slot))
		return
	if(!set_current_intimate_slot(slot))
		return
	if(!can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return

	applying = TRUE
	var/accepted = alert(H, "[user] is fitting [src] to me. Submit to the cursed piercing?", "Cursed Piercing", "Submit", "Resist")
	applying = FALSE
	if(accepted != "Submit" || QDELETED(src) || !H || !user)
		set_current_intimate_slot(null)
		return
	if(!can_apply_cursed_piercing(H, user) || !can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return

	user.visible_message(span_warning("[user] starts fitting [src] on [H]."), span_notice("I start fitting [src] on [H]..."))
	if(!do_after(user, 40, needhand = 1, target = H))
		set_current_intimate_slot(null)
		return
	if(!can_apply_cursed_piercing(H, user) || !can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return
	if(!attach_intimate_feature(H))
		to_chat(user, span_warning("[src] cannot be attached right now."))
		set_current_intimate_slot(null)
		return

	finalize_intimate_equip(H)
	var/datum/component/collar_master/CM = cursed_piercing_master.GetComponent(/datum/component/collar_master)
	if(!CM)
		CM = cursed_piercing_master.AddComponent(/datum/component/collar_master)
	CM.add_pet(H)
	SEND_SIGNAL(H, COMSIG_CARBON_COLLAR_BOUND, cursed_piercing_master, src)
	send_cursed_piercing_message(H, "cursed_piercing_bound", list("%SLOT%" = lowertext(get_intimate_slot_display_name())), "danger")
	to_chat(user, span_notice("[src] binds to [H]."))

/obj/item/intimate_accessory/piercing/cursed/proc/can_apply_cursed_piercing(mob/living/carbon/human/H, mob/user)
	if(!H || !user)
		return FALSE
	if(user == H && !roundstart_self_master_binding)
		to_chat(user, span_warning("I cannot fasten a cursed piercing on myself."))
		return FALSE
	if(H?.client?.prefs)
		if(!H.client.prefs.cursed_enabled)
			to_chat(user, span_warning("[H] has cursed content disabled."))
			return FALSE
		if(!H.client.prefs.intimate_enabled)
			to_chat(user, span_warning("[H] has intimate accessories disabled."))
			return FALSE
	if(user?.client?.prefs)
		if(!user.client.prefs.cursed_enabled)
			to_chat(user, span_warning("I have cursed content disabled."))
			return FALSE
		if(!user.client.prefs.intimate_enabled)
			to_chat(user, span_warning("I have intimate accessories disabled."))
			return FALSE
	if(!can_attach_target(H, user))
		return FALSE
	var/obj/item/clothing/neck/roguetown/cursed_collar/existing_collar = H.get_item_by_slot(SLOT_NECK)
	if(istype(existing_collar))
		to_chat(user, span_warning("[H] is already bound by a cursed collar."))
		return FALSE
	if(H.chastity_device?.chastity_cursed)
		to_chat(user, span_warning("[H] is already bound by cursed chastity."))
		return FALSE
	if(H.get_cursed_piercing())
		to_chat(user, span_warning("[H] is already bound by a cursed piercing."))
		return FALSE
	if(!cursed_piercing_master)
		if(!user.mind)
			to_chat(user, span_warning("I need a mind to imprint [src]."))
			return FALSE
		cursed_piercing_master = user.mind
	if(!cursed_piercing_master)
		to_chat(user, span_warning("[src] has no master to obey."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/adjust_organ_size(mob/living/carbon/human/H, organ_key, delta)
	if(!H || !delta)
		return FALSE
	var/changed = FALSE
	var/organ_label
	var/new_size
	switch(organ_key)
		if(CURSED_PIERCING_ORGAN_PENIS)
			var/obj/item/organ/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
			if(!penis)
				return FALSE
			var/new_penis_size = clamp(penis.penis_size + delta, MIN_PENIS_SIZE, MAX_PENIS_SIZE)
			if(new_penis_size == penis.penis_size)
				return FALSE
			penis.penis_size = new_penis_size
			organ_label = "penis"
			new_size = new_penis_size
			changed = TRUE
			H.sexcon?.update_erect_state()
		if(CURSED_PIERCING_ORGAN_TESTICLES)
			var/obj/item/organ/testicles/testicles = H.getorganslot(ORGAN_SLOT_TESTICLES)
			if(!testicles)
				return FALSE
			var/new_testicle_size = clamp(testicles.ball_size + delta, MIN_TESTICLES_SIZE, MAX_TESTICLES_SIZE)
			if(new_testicle_size == testicles.ball_size)
				return FALSE
			testicles.ball_size = new_testicle_size
			organ_label = "testicles"
			new_size = new_testicle_size
			changed = TRUE
		if(CURSED_PIERCING_ORGAN_BREASTS)
			var/obj/item/organ/breasts/breasts = H.getorganslot(ORGAN_SLOT_BREASTS)
			if(!breasts)
				return FALSE
			var/new_breast_size = clamp(breasts.breast_size + delta, MIN_BREASTS_SIZE, MAX_BREASTS_SIZE)
			if(new_breast_size == breasts.breast_size)
				return FALSE
			breasts.breast_size = new_breast_size
			breasts.milk_max = max(75, breasts.breast_size * 100)
			organ_label = "breasts"
			new_size = new_breast_size
			changed = TRUE
	if(changed)
		H.update_body_parts(TRUE)
		playsound(H, 'sound/misc/vampirespell.ogg', 40, TRUE)
		send_cursed_piercing_message(H, "cursed_piercing_organ_size_changed", list(
			"%ORGAN%" = organ_label,
			"%DIRECTION%" = delta > 0 ? "larger" : "smaller",
			"%SIZE%" = "[new_size]"
		))
	return changed

/obj/item/intimate_accessory/piercing/cursed/proc/set_lactation(mob/living/carbon/human/H, enabled)
	if(!H)
		return FALSE
	var/obj/item/organ/breasts/breasts = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		return FALSE
	var/new_state = !!enabled
	if(breasts.lactating == new_state)
		return FALSE
	breasts.lactating = new_state
	if(new_state)
		breasts.milk_max = max(75, breasts.breast_size * 100)
	playsound(H, 'sound/misc/vampirespell.ogg', 40, TRUE)
	send_cursed_piercing_message(H, new_state ? "cursed_piercing_lactation_start" : "cursed_piercing_lactation_stop")
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/set_impotence(mob/living/carbon/human/H, enabled)
	if(!H)
		return FALSE
	var/new_state = !!enabled
	if(new_state)
		if(HAS_TRAIT_FROM(H, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE))
			return FALSE
		ADD_TRAIT(H, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE)
	else
		if(!HAS_TRAIT_FROM(H, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE))
			return FALSE
		REMOVE_TRAIT(H, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE)
	H.sexcon?.update_erect_state()
	playsound(H, 'sound/misc/vampirespell.ogg', 40, TRUE)
	send_cursed_piercing_message(H, new_state ? "cursed_piercing_impotence_start" : "cursed_piercing_impotence_stop")
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/restore_worn_intimate_slot(mob/living/carbon/human/H, old_slot, datum/bodypart_feature/intimate_accessory/old_feature)
	if(!H)
		return
	set_current_intimate_slot(old_slot)
	set_worn_in_slot(H, src)
	intimate_feature = old_feature
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	if(chest && old_feature)
		chest.add_bodypart_feature(old_feature)

/obj/item/intimate_accessory/piercing/cursed/proc/set_worn_intimate_slot(mob/living/carbon/human/H, slot)
	if(istext(slot))
		slot = text2num(slot)
	if(!H || wearer != H)
		return FALSE
	if(!is_valid_cursed_piercing_slot(slot) || !supports_intimate_slot(slot))
		return FALSE
	var/old_slot = get_effective_intimate_slot()
	if(slot == old_slot)
		return FALSE
	var/obj/item/intimate_accessory/existing_accessory = get_worn_in_slot(H, slot)
	if(existing_accessory && existing_accessory != src)
		return FALSE

	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	var/datum/bodypart_feature/intimate_accessory/old_feature = intimate_feature
	if(chest && old_feature)
		chest.remove_bodypart_feature(old_feature)
	intimate_feature = null
	clear_worn_slot_refs(H)
	if(!set_current_intimate_slot(slot))
		restore_worn_intimate_slot(H, old_slot, old_feature)
		return FALSE
	if(has_visual_intimate_feature() && !attach_intimate_feature(H))
		restore_worn_intimate_slot(H, old_slot, old_feature)
		return FALSE

	finalize_intimate_equip(H)
	notify_intimate_state_change(H, "cursed_slot_changed")
	send_cursed_piercing_message(H, "cursed_piercing_slot_changed", list("%SLOT%" = lowertext(get_intimate_slot_display_name())))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/set_cursed_metal(metal_key)
	var/list/option = find_cursed_piercing_option(get_cursed_piercing_metal_options(), metal_key)
	if(!option)
		return FALSE
	selected_metal_key = option["key"]
	intimate_metal_name = option["name"]
	intimate_metal_color = option["color"]
	is_silver = !!option["silver"]
	refresh_piercing_state()
	on_socket_state_changed("cursed_metal_changed")
	if(wearer)
		send_cursed_piercing_message(wearer, "cursed_piercing_metal_changed", list("%METAL%" = option["name"]))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/set_cursed_gem(gem_key, refresh = TRUE)
	var/list/option = find_cursed_piercing_option(get_cursed_piercing_gem_options(), gem_key)
	if(!option)
		return FALSE
	selected_gem_key = option["key"]
	current_gem_descriptor = option["descriptor"]
	intimate_gem_color = option["color"]
	socketed_item_type = option["type"]
	gem_value_bonus = 0
	if(refresh)
		refresh_piercing_state()
		on_socket_state_changed("cursed_gem_changed")
		if(wearer)
			send_cursed_piercing_message(wearer, "cursed_piercing_gem_changed", list("%GEM%" = current_gem_descriptor))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/set_cursed_descriptor(descriptor)
	var/old_descriptor = custom_piercing_descriptor
	set_custom_piercing_descriptor(descriptor)
	if(custom_piercing_descriptor == old_descriptor)
		return FALSE
	if(wearer)
		send_cursed_piercing_message(wearer, "cursed_piercing_descriptor_changed", list(
			"%NAME%" = custom_piercing_descriptor || "its original name"
		))
	return TRUE

/obj/item/intimate_accessory/piercing/cursed/proc/get_cursed_piercing_ui_data(mob/living/carbon/human/H)
	var/obj/item/organ/penis/penis = H?.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/organ/testicles/testicles = H?.getorganslot(ORGAN_SLOT_TESTICLES)
	var/obj/item/organ/breasts/breasts = H?.getorganslot(ORGAN_SLOT_BREASTS)
	return list(
		"current_slot" = get_effective_intimate_slot(),
		"slot_name" = get_intimate_slot_display_name(),
		"supported_slots" = get_supported_intimate_slots(),
		"custom_descriptor" = custom_piercing_descriptor || "",
		"metal_key" = selected_metal_key,
		"metal_color" = intimate_metal_color,
		"gem_key" = selected_gem_key,
		"gem_color" = intimate_gem_color,
		"has_penis" = !!penis,
		"penis_size" = penis ? penis.penis_size : null,
		"has_testicles" = !!testicles,
		"testicles_size" = testicles ? testicles.ball_size : null,
		"has_breasts" = !!breasts,
		"breasts_size" = breasts ? breasts.breast_size : null,
		"lactating" = breasts ? breasts.lactating : FALSE,
		"impotent" = HAS_TRAIT_FROM(H, TRAIT_LIMPDICK, CURSED_PIERCING_TRAIT_SOURCE)
	)

/mob/living/carbon/human/proc/get_cursed_piercing()
	for(var/obj/item/intimate_accessory/piercing/cursed/piercing as anything in intimate_accessories)
		if(istype(piercing))
			return piercing
	return null

/mob/living/carbon/human/proc/remove_cursed_piercings(delete_removed = FALSE)
	var/removed_count = 0
	var/list/current_accessories = intimate_accessories.Copy()
	for(var/obj/item/intimate_accessory/piercing/cursed/piercing as anything in current_accessories)
		if(!istype(piercing))
			continue
		var/datum/component/collar_master/CM = piercing.get_cursed_master_component()
		if(CM && (src in CM.my_pets))
			CM.remove_pet(src)
		else
			piercing.remove_intimate_accessory(src)
		if(delete_removed)
			qdel(piercing)
		else if(!QDELETED(piercing))
			piercing.forceMove(get_turf(src))
		removed_count++
	return removed_count

// Self-equip intimate accessory.
/obj/item/intimate_accessory/attack_self(mob/user)
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/H = user
	if(get_worn_in_slot(H) == src)
		if(!passes_access_checks(H, user))
			return
		remove_intimate_accessory(H)
		forceMove(get_turf(H))
		to_chat(user, span_notice("I remove [src]."))
		return
	if(!can_attach_target(H, user))
		return
	var/slot = resolve_intimate_slot(H, user)
	if(isnull(slot))
		return
	if(!set_current_intimate_slot(slot))
		return
	if(!can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return

	user.visible_message(span_notice("[user] starts fitting [src]."))
	if(!do_after(user, get_intimate_action_delay(30), needhand = 1, target = H))
		set_current_intimate_slot(null)
		return

	if(!can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return

	if(!attach_intimate_feature(H))
		to_chat(user, span_warning("[src] cannot be attached right now."))
		set_current_intimate_slot(null)
		return
	finalize_intimate_equip(H)
	to_chat(user, span_notice("I fit [src]."))

// Equip intimate accessory on another player.
/obj/item/intimate_accessory/attack(mob/M, mob/user, def_zone)
	if(!ishuman(M))
		return
	var/mob/living/carbon/human/H = M
	if(!can_attach_target(H, user))
		return
	var/slot = resolve_intimate_slot(H, user)
	if(isnull(slot))
		return
	if(!set_current_intimate_slot(slot))
		return
	if(!can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return

	user.visible_message(span_notice("[user] starts fitting [src] on [H]."))
	if(!do_after(user, get_intimate_action_delay(40), needhand = 1, target = H))
		set_current_intimate_slot(null)
		return

	if(!can_attach_to_intimate_slot(H, user, slot))
		set_current_intimate_slot(null)
		return

	if(!attach_intimate_feature(H))
		to_chat(user, span_warning("[src] cannot be attached right now."))
		set_current_intimate_slot(null)
		return
	finalize_intimate_equip(H)
	to_chat(user, span_notice("I fit [src] on [H]."))

// Returns a list of the intimate accessories currently worn by this human, for use in the remove_intimate_accessory verb's list of options for which accessory to remove.
/mob/living/carbon/proc/get_intimate_accessory_options()
	var/list/options = list()
	if(intimate_genital_piercing)
		options += intimate_genital_piercing
	if(intimate_genital_insertable)
		options += intimate_genital_insertable
	if(intimate_rear_piercing)
		options += intimate_rear_piercing
	if(intimate_rear_insertable)
		options += intimate_rear_insertable
	if(intimate_breast_piercing)
		options += intimate_breast_piercing
	if(intimate_breast_insertable)
		options += intimate_breast_insertable
	if(intimate_mouth_piercing)
		options += intimate_mouth_piercing
	if(intimate_mouth_insertable)
		options += intimate_mouth_insertable
	if(intimate_ear_piercing)
		options += intimate_ear_piercing
	if(intimate_nose_piercing)
		options += intimate_nose_piercing
	if(intimate_belly_piercing)
		options += intimate_belly_piercing
	return options

// Returns the accessory currently worn in the specified slot, or null if no accessory is currently worn in that slot. This is used in the remove_intimate_accessory verb to check that the accessory the player is trying to remove is still being worn in that slot before allowing them to remove it, to prevent issues with players trying to remove accessories that are no longer worn due to changes in state during the removal process such as moving or being moved by another player, which could cause desync issues if we allowed them to continue removing an accessory that's no longer worn.
/// Returns the first accessory found in the given region slot (piercing or insertable).
/mob/living/carbon/proc/get_worn_in_slot(intimate_slot)
	switch(intimate_slot)
		if(INTIMATE_SLOT_GENITAL)
			return intimate_genital_piercing || intimate_genital_insertable
		if(INTIMATE_SLOT_REAR)
			return intimate_rear_piercing || intimate_rear_insertable
		if(INTIMATE_SLOT_BREAST)
			return intimate_breast_piercing || intimate_breast_insertable
		if(INTIMATE_SLOT_MOUTH)
			return intimate_mouth_piercing || intimate_mouth_insertable
		if(INTIMATE_SLOT_EAR)
			return intimate_ear_piercing
		if(INTIMATE_SLOT_NOSE)
			return intimate_nose_piercing
		if(INTIMATE_SLOT_BELLY)
			return intimate_belly_piercing
	return null

/mob/living/carbon/human/verb/remove_intimate_accessory()
	set name = "Remove Intimate Accessory"
	set category = "IC"

	var/list/target_options = list(src)
	for(var/mob/living/carbon/human/H in oview(1, src))
		target_options += H

	var/mob/living/carbon/human/target = src
	if(length(target_options) > 1)
		target = tgui_input_list(src, "Remove accessory from whom?", "Intimate Accessory", target_options)
	if(!target)
		return
	if(target != src && !src.Adjacent(target))
		return

	var/list/options = target.get_intimate_accessory_options()
	if(!length(options))
		if(target == src)
			to_chat(src, span_warning("I am not wearing any intimate accessories."))
		else
			to_chat(src, span_warning("[target] is not wearing any intimate accessories."))
		return

	var/prompt = (target == src) ? "Remove which accessory?" : "Remove which accessory from [target]?"
	var/obj/item/intimate_accessory/choice = tgui_input_list(src, prompt, "Intimate Accessory", options)
	if(!choice)
		return
	if(choice.get_worn_in_slot(target) != choice)
		to_chat(src, span_warning("That accessory is no longer worn."))
		return
	if(!choice.passes_access_checks(target, src))
		return

	if(target == src)
		visible_message(span_notice("[src] starts removing [choice]..."))
	else
		visible_message(span_notice("[src] starts removing [choice] from [target]..."))

	var/remove_delay = (target == src) ? 25 : 35
	if(!do_after(src, choice.get_intimate_action_delay(remove_delay), needhand = 1, target = target))
		return

	if(choice.get_worn_in_slot(target) != choice)
		to_chat(src, span_warning("That accessory is no longer worn."))
		return

	choice.remove_intimate_accessory(target)
	if(!QDELETED(choice))
		choice.forceMove(get_turf(target))

	if(target == src)
		to_chat(src, span_notice("I remove [choice]."))
	else
		to_chat(src, span_notice("I remove [choice] from [target]."))

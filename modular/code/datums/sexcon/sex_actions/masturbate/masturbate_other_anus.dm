/datum/sex_action/masturbate_other_anus
	name = "Finger their butt"
	check_same_tile = FALSE
	category = SEX_CATEGORY_HANDS
	target_sex_part = SEX_PART_ANUS
	subtle_supported = TRUE

/datum/sex_action/masturbate_other_anus/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(target.sexcon.has_chastity_anal())
		return FALSE
	if(anal_blocked_by_rear_plug(user, target))
		return FALSE
	return TRUE

/datum/sex_action/masturbate_other_anus/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(target.sexcon.has_chastity_anal())
		return FALSE
	if(anal_blocked_by_rear_plug(user, target, TRUE))
		return FALSE
	return TRUE

/datum/sex_action/masturbate_other_anus/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] starts fingering [target]'s butt..."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))
	user.sexcon.show_progress = 0

/datum/sex_action/masturbate_other_anus/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	user.sexcon.suppress_moan = target.sexcon.suppress_moan = do_subtle
	apply_silver_intimate_contact("rear", target, user)

	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective(is_stealth = do_subtle)] fingers [target]'s butt..."), vision_distance = (do_subtle ? 1 : DEFAULT_MESSAGE_RANGE))
	if(!do_subtle)
		user.sexcon.generic_sex_noise()

	user.sexcon.perform_sex_action(target, 2, 6, TRUE)
	target.sexcon.handle_passive_ejaculation()

	user.sexcon.suppress_moan = target.sexcon.suppress_moan = FALSE

/datum/sex_action/masturbate_other_anus/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] stops fingering [target]'s butt."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))

/datum/sex_action/masturbate_other_anus/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE

/datum/sex_action/tease_other_plug
	name = "Tease their butt plug"
	check_same_tile = FALSE
	category = SEX_CATEGORY_HANDS
	target_sex_part = SEX_PART_ANUS
	subtle_supported = TRUE

/datum/sex_action/tease_other_plug/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return can_target_other_rear_plug(user, target)

/datum/sex_action/tease_other_plug/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return can_access_other_rear_plug(user, target)

/datum/sex_action/tease_other_plug/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/plug/rear/plug = get_rear_plug(target)
	user.visible_message(span_warning("[user] takes hold of [target]'s \the [plug] and starts teasing it..."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))
	playsound(target, 'sound/items/uncork.ogg', 40, TRUE, ignore_walls = FALSE)
	user.sexcon.show_progress = 0

/datum/sex_action/tease_other_plug/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/plug/rear/plug = get_rear_plug(target)
	if(!plug)
		return
	apply_silver_intimate_contact("rear", target, user)

	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	user.sexcon.suppress_moan = target.sexcon.suppress_moan = do_subtle

	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective(is_stealth = do_subtle)] toys with [target]'s \the [plug]..."), vision_distance = (do_subtle ? 1 : DEFAULT_MESSAGE_RANGE))
	playsound(target, 'sound/misc/mat/pop.ogg', 25, TRUE, ignore_walls = FALSE)
	if(!do_subtle)
		user.sexcon.outercourse_noise(target)

	user.sexcon.perform_sex_action(target, 2, 7, TRUE)
	target.sexcon.handle_passive_ejaculation()
	plug.do_silver_check(target)

	user.sexcon.suppress_moan = target.sexcon.suppress_moan = FALSE

/datum/sex_action/tease_other_plug/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] lets go of [target]'s butt plug."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))

/datum/sex_action/tease_other_plug/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE

/datum/sex_action/fuck_other_plug
	name = "Plug-fuck them"
	check_same_tile = FALSE
	stamina_cost = 1.0
	category = SEX_CATEGORY_PENETRATE
	target_sex_part = SEX_PART_ANUS

/datum/sex_action/fuck_other_plug/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return can_target_other_rear_plug(user, target)

/datum/sex_action/fuck_other_plug/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return can_access_other_rear_plug(user, target)

/datum/sex_action/fuck_other_plug/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/plug/rear/plug = get_rear_plug(target)
	var/static/list/plug_insert_sounds = list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg')
	user.visible_message(span_warning("[user] yanks [target]'s \the [plug] free, then shoves it back in with a wet thrust!"))
	playsound(target, 'sound/items/uncork.ogg', 60, TRUE, ignore_walls = FALSE)
	playsound(target, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)
	playsound(target, plug_insert_sounds, 20, TRUE, ignore_walls = FALSE)

/datum/sex_action/fuck_other_plug/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/plug/rear/plug = get_rear_plug(target)
	if(!plug)
		return
	apply_silver_intimate_contact("rear", target, user)

	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] plug-fucks [target], repeatedly pulling out and slamming \the [plug] back into [target.p_their()] ass."))
	playsound(target, 'sound/items/uncork.ogg', 35, TRUE, ignore_walls = FALSE)
	playsound(target, 'sound/misc/mat/pop.ogg', 30, TRUE, ignore_walls = FALSE)
	user.sexcon.intercourse_noise(target)
	user.sexcon.do_thrust_animate(target)

	user.sexcon.perform_sex_action(target, 2.4, 8, TRUE)
	target.sexcon.handle_passive_ejaculation()
	plug.do_silver_check(target)

/datum/sex_action/fuck_other_plug/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] leaves [target]'s butt plug buried deep and lets [target] catch [target.p_their()] breath."))

/datum/sex_action/fuck_other_plug/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(target.sexcon.finished_check())
		return TRUE
	return FALSE

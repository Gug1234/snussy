/datum/sex_action/masturbate_anus
	name = "Finger butt"
	category = SEX_CATEGORY_HANDS
	user_sex_part = SEX_PART_ANUS
	target_sex_part = SEX_PART_ANUS
	subtle_supported = TRUE

/datum/sex_action/masturbate_anus/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(anal_blocked_by_rear_plug(user, user))
		return FALSE
	return TRUE

/datum/sex_action/masturbate_anus/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(anal_blocked_by_rear_plug(user, user, TRUE))
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	return TRUE

/datum/sex_action/masturbate_anus/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] starts fingering [user.p_their()] butt..."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))
	user.sexcon.show_progress = 0

/datum/sex_action/masturbate_anus/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	user.sexcon.suppress_moan = do_subtle

	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective(is_stealth = do_subtle)] fingers [user.p_their()] butt..."), vision_distance = (do_subtle ? 1 : DEFAULT_MESSAGE_RANGE))
	if(!do_subtle)
		user.sexcon.generic_sex_noise()

	user.sexcon.perform_sex_action(user, 2, 6, TRUE)
	user.sexcon.handle_passive_ejaculation()

	user.sexcon.suppress_moan = FALSE

/datum/sex_action/masturbate_anus/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] stops fingering [user.p_their()] butt."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))

/datum/sex_action/masturbate_anus/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE


/// Self-masturbation action for teasing a worn butt plug — shown only when the user already has one inserted.
/datum/sex_action/tease_plug
	name = "Tease butt plug"
	category = SEX_CATEGORY_HANDS
	target_sex_part = SEX_PART_ANUS
	subtle_supported = TRUE

/datum/sex_action/tease_plug/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!get_rear_plug(user))
		return FALSE
	return TRUE

/datum/sex_action/tease_plug/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user != target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!get_rear_plug(user))
		return FALSE
	return TRUE

/datum/sex_action/tease_plug/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/plug/rear/plug = get_rear_plug(user)
	user.visible_message(span_warning("[user] hooks [user.p_their()] fingers around \the [plug] and starts to toy with it..."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))
	playsound(user, 'sound/items/uncork.ogg', 40, TRUE, ignore_walls = FALSE)
	user.sexcon.show_progress = 0

/datum/sex_action/tease_plug/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/plug/rear/plug = get_rear_plug(user)
	if(!plug)
		return

	var/do_subtle = user.sexcon.do_subtle_action
	user.sexcon.show_progress = !do_subtle
	user.sexcon.suppress_moan = do_subtle

	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective(is_stealth = do_subtle)] works \the [plug] in [user.p_their()] butt..."), vision_distance = (do_subtle ? 1 : DEFAULT_MESSAGE_RANGE))
	playsound(user, 'sound/misc/mat/pop.ogg', 25, TRUE, ignore_walls = FALSE)
	if(!do_subtle)
		user.sexcon.outercourse_noise(user)

	user.sexcon.perform_sex_action(user, 2, 7, TRUE)
	user.sexcon.handle_passive_ejaculation()
	plug.do_silver_check(user)

	user.sexcon.suppress_moan = FALSE

/datum/sex_action/tease_plug/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] lets [user.p_their()] butt plug settle back in place."), vision_distance = (user.sexcon.do_subtle_action ? 1 : DEFAULT_MESSAGE_RANGE))

/datum/sex_action/tease_plug/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE

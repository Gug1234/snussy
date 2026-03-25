/datum/sex_action/force_slime_nursing
	name = "Force them to nurse the slime"
	require_grab = TRUE
	stamina_cost = 1.0
	target_sex_part = SEX_PART_JAWS

/datum/sex_action/force_slime_nursing/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		if(isdullahan(user))
			var/datum/species/dullahan/dullahan = user.dna.species
			if(dullahan.headless && !user.is_holding(dullahan.my_head))
				return FALSE
		else
			return FALSE
	if(!user.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(user)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/force_slime_nursing/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		if(isdullahan(user))
			var/datum/species/dullahan/dullahan = user.dna.species
			if(dullahan.headless && !user.is_holding(dullahan.my_head))
				return FALSE
		else
			return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_CHEST, TRUE))
		return FALSE
	if(!check_location_accessible(user, target, BODY_ZONE_PRECISE_MOUTH))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_BREASTS))
		return FALSE
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(user)
	if(!jelly?.can_nurse_breasts())
		return FALSE
	return TRUE

/datum/sex_action/force_slime_nursing/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] presses [target]'s face into the slime wrapped around [user.p_their()] breasts!"))
	playsound(target, list('sound/misc/mat/insert (1).ogg','sound/misc/mat/insert (2).ogg'), 20, TRUE, ignore_walls = FALSE)

/datum/sex_action/force_slime_nursing/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/obj/item/intimate_accessory/jelly/eora/jelly = get_breast_jelly(user)
	if(!jelly)
		return
	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] makes [target] nurse at [user.p_their()] breasts while the slime suckles and milks them both."))
	user.sexcon.oralcourse_noise(target)
	apply_silver_intimate_contact("mouth", target, user)

	user.sexcon.perform_sex_action(user, 2, 4, TRUE)
	user.sexcon.perform_sex_action(target, 0, 6, FALSE)
	if(!user.sexcon.considered_limp())
		user.sexcon.perform_deepthroat_oxyloss(target, 0.4)
	target.sexcon.handle_passive_ejaculation()

	var/show_nursing_messages = prob(35)
	jelly.handle_breast_nursing(user, target, show_nursing_messages)

/datum/sex_action/force_slime_nursing/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] pulls [target]'s mouth away from the slime wrapped around [user.p_their()] breasts."))

/datum/sex_action/force_slime_nursing/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE
/proc/is_selectable_genital_visibility_preference(visibility_preference)
	switch(visibility_preference)
		if(GENITAL_NEVER_SHOW)
			return TRUE
		if(GENITAL_HIDDEN_BY_CLOTHES)
			return TRUE
		if(GENITAL_ALWAYS_SHOW)
			return TRUE
	return FALSE

/obj/item/organ/proc/is_genital_visibility_toggleable()
	return genital_visibility_preference != GENITAL_SKIP_VISIBILITY

/obj/item/organ/proc/is_hidden_by_genital_visibility_preference()
	return genital_visibility_preference == GENITAL_NEVER_SHOW

/obj/item/organ/proc/apply_genital_visibility_preference(default_visibility)
	switch(genital_visibility_preference)
		if(GENITAL_NEVER_SHOW)
			return FALSE
		if(GENITAL_ALWAYS_SHOW)
			return TRUE
	return default_visibility

/mob/living/proc/get_visible_genital_organ(organ_slot)
	if(!hascall(src, "getorganslot"))
		return null
	var/obj/item/organ/organ = call(src, "getorganslot")(organ_slot)
	if(organ?.is_hidden_by_genital_visibility_preference())
		return null
	return organ

/mob/living/carbon/human/get_visible_genital_organ(organ_slot)
	var/obj/item/organ/organ = getorganslot(organ_slot)
	if(organ?.is_hidden_by_genital_visibility_preference())
		return null
	return organ

/mob/living/proc/has_visible_genital_organ(organ_slot)
	return !!get_visible_genital_organ(organ_slot)

/mob/living/proc/has_visible_front_genital_organ()
	return has_visible_genital_organ(ORGAN_SLOT_PENIS) || has_visible_genital_organ(ORGAN_SLOT_VAGINA)

/mob/living/proc/has_visible_genital_for_sex_parts(sex_parts)
	if((sex_parts & SEX_PART_COCK) && !has_visible_genital_organ(ORGAN_SLOT_PENIS))
		return FALSE
	if((sex_parts & SEX_PART_SLIT_SHEATH) && !has_visible_genital_organ(ORGAN_SLOT_PENIS))
		return FALSE
	if((sex_parts & SEX_PART_CUNT) && !has_visible_genital_organ(ORGAN_SLOT_VAGINA))
		return FALSE
	return TRUE

/mob/living/carbon/human/proc/get_toggleable_genital_organs()
	var/list/genital_organs = list()
	for(var/obj/item/organ/organ as anything in internal_organs)
		if(organ.is_genital_visibility_toggleable())
			genital_organs += organ
	return genital_organs

/mob/living/carbon/human/proc/set_genital_visibility_preference(obj/item/organ/target_organ, new_visibility, apply_to_all = FALSE)
	if(!is_selectable_genital_visibility_preference(new_visibility))
		return FALSE

	var/changed = FALSE
	var/applied = FALSE
	if(apply_to_all)
		for(var/obj/item/organ/genital_organ as anything in get_toggleable_genital_organs())
			applied = TRUE
			if(genital_organ.genital_visibility_preference == new_visibility)
				continue
			genital_organ.genital_visibility_preference = new_visibility
			changed = TRUE
	else
		if(!(target_organ in internal_organs))
			return FALSE
		if(!target_organ.is_genital_visibility_toggleable())
			return FALSE
		applied = TRUE
		if(target_organ.genital_visibility_preference != new_visibility)
			target_organ.genital_visibility_preference = new_visibility
			changed = TRUE

	if(!applied)
		return FALSE
	if(changed)
		update_body()
		SEND_SIGNAL(src, COMSIG_HUMAN_TOGGLE_GENITALS)
	return TRUE

/mob/living/carbon/human/verb/toggle_genitals()
	set category = "IC"
	set name = "Expose/Hide genitals"
	set desc = "Allows you to toggle which genitals should show through clothes or not."

	if(stat != CONSCIOUS)
		to_chat(src, span_warning("You can't toggle genitals visibility right now... you should wake up, wake up, WAKE UP, WAKE UP."))
		return

	var/list/genital_options = list("all")
	genital_options += get_toggleable_genital_organs()
	if(length(genital_options) == 1)
		return

	var/picked_organ = tgui_input_list(src, "Choose which genitalia to expose/hide.", "Expose/Hide genitals", genital_options)
	if(!picked_organ)
		return
	if(picked_organ != "all" && !(picked_organ in internal_organs))
		return

	var/list/genital_visibility_options = list(
		"Never show" = GENITAL_NEVER_SHOW,
		"Hidden by clothes" = GENITAL_HIDDEN_BY_CLOTHES,
		"Always show" = GENITAL_ALWAYS_SHOW,
	)
	var/picked_visibility = tgui_input_list(src, "Choose visibility setting.", "Expose/Hide genitals", genital_visibility_options)
	if(!picked_visibility)
		return

	var/new_visibility = genital_visibility_options[picked_visibility]
	if(picked_organ == "all")
		set_genital_visibility_preference(null, new_visibility, TRUE)
	else
		var/obj/item/organ/target_organ = picked_organ
		set_genital_visibility_preference(target_organ, new_visibility)

/datum/sex_controller/proc/action_blocked_by_genital_visibility(datum/sex_action/action)
	if(!action || !user)
		return FALSE
	if(!user.has_visible_genital_for_sex_parts(action.user_sex_part))
		return TRUE
	if(target && !target.has_visible_genital_for_sex_parts(action.target_sex_part))
		return TRUE
	return FALSE

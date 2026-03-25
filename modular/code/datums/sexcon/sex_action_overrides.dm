// Unified silver check for intimate regions (mouth, breast, genital, etc.)
/datum/sex_action/proc/get_tongue_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/piercing/tongue/tongue_piercing = owner.intimate_mouth
	if(!istype(tongue_piercing))
		return null
	return tongue_piercing

/datum/sex_action/proc/get_genital_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/piercing/genital/genital_piercing = owner.intimate_genital
	if(!istype(genital_piercing))
		return null
	return genital_piercing

/datum/sex_action/proc/get_genital_plug(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/genital/plug/genital_plug = owner.intimate_genital
	if(!istype(genital_plug))
		return null
	return genital_plug

/datum/sex_action/proc/get_mouth_jelly(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly = owner.intimate_mouth
	if(!istype(jelly))
		return null
	return jelly

/datum/sex_action/proc/get_breast_jelly(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly = owner.intimate_breast
	if(!istype(jelly))
		return null
	return jelly

/datum/sex_action/proc/get_genital_jelly(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly = owner.intimate_genital
	if(!istype(jelly))
		return null
	return jelly

/datum/sex_action/proc/get_rear_jelly(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly = owner.intimate_rear
	if(!istype(jelly))
		return null
	return jelly

/datum/sex_action/proc/get_rear_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/rear_item = owner.intimate_rear
	if(!istype(rear_item, /obj/item/intimate_accessory))
		return null
	return rear_item

/datum/sex_action/proc/get_front_piercing(mob/living/carbon/human/owner)
	return get_breast_piercing(owner)


/datum/sex_action/proc/apply_silver_intimate_contact(region, owner, contact_target)
	if(!owner || !contact_target)
		return FALSE
	var/obj/item/intimate_accessory/piercing
	switch(region)
		if("mouth")
			piercing = get_tongue_piercing(owner)
		if("breast")
			piercing = get_breast_piercing(owner)
		if("genital")
			piercing = get_genital_piercing(owner)
		if("rear")
			piercing = get_rear_piercing(owner)
		// Add more regions as needed
	if(!piercing || !piercing.is_silver)
		return FALSE
	piercing.do_silver_check(contact_target)
	return TRUE

/datum/sex_action/proc/uses_genital_piercing_part(sex_part)
	return !!(sex_part & (SEX_PART_COCK | SEX_PART_CUNT))

/datum/sex_action/proc/uses_genital_plug_part(sex_part)
	return !!(sex_part & SEX_PART_CUNT)

/datum/sex_action/proc/get_genital_piercing_region_name(sex_part)
	if(sex_part & SEX_PART_COCK)
		return "cock"
	if(sex_part & SEX_PART_CUNT)
		return "cunt"
	return null

/datum/sex_action/proc/get_genital_piercing_action_flavor(mob/living/carbon/human/owner, obj/item/intimate_accessory/piercing/genital/genital_piercing, sex_part)
	if(!genital_piercing)
		return null

	var/region_name = get_genital_piercing_region_name(sex_part)
	if(!region_name)
		return null

	var/owner_their = owner ? owner.p_their() : "their"
	var/owner_Their = "[uppertext(copytext(owner_their, 1, 2))][copytext(owner_their, 2)]"

	if(genital_piercing.is_beriddled())
		return pick(
			"A riddle-red gleam flashes from [owner_their] genital piercing with each movement.",
			"[owner_Their] beriddled genital piercing throws off a hot crimson glint.",
			"A sinful red shimmer pulses from [owner_their] pierced [region_name].",
		)

	if(istype(genital_piercing, /obj/item/intimate_accessory/piercing/genital/psydonic))
		if(region_name == "cock")
			return pick(
				"[owner_Their] psydonic cock ring catches the light in calm, pale flashes.",
				"A serene psydonic glimmer runs along [owner_their] pierced cock.",
				"[owner_Their] psydonic genital piercing gleams softly around [owner_their] cock.",
			)
		return pick(
			"[owner_Their] psydonic genital jewelry glimmers with quiet devotion at [owner_their] cunt.",
			"A gentle psydonic shine flickers from [owner_their] pierced cunt.",
			"[owner_Their] psydonic piercing flashes softly against [owner_their] cunt.",
		)

	if(istype(genital_piercing, /obj/item/intimate_accessory/piercing/genital/zizite))
		if(region_name == "cock")
			return pick(
				"[owner_Their] zizite cock ring clicks with a grim little scrape.",
				"A morbid zcross glint flashes from [owner_their] pierced cock.",
				"[owner_Their] zizite genital piercing scrapes in a harsh little rhythm.",
			)
		return pick(
			"[owner_Their] zizite genital piercing glints with morbid spite at [owner_their] cunt.",
			"A cruel metallic flicker dances from [owner_their] pierced cunt.",
			"[owner_Their] zizite jewelry catches the light with a grim, grave-bright flash.",
		)

	if(region_name == "cock")
		return pick(
			"[owner_Their] cock ring clicks softly in a bright metallic rhythm.",
			"A small flash runs along [owner_their] pierced cock.",
			"[owner_Their] genital piercing glints wetly around [owner_their] cock.",
		)
	return pick(
		"[owner_Their] genital piercing glints wetly at [owner_their] cunt.",
		"A small metallic flash flickers from [owner_their] pierced cunt.",
		"[owner_Their] genital jewelry catches the light in a quick, lewd shimmer.",
	)

/datum/sex_action/proc/get_genital_plug_action_flavor(mob/living/carbon/human/owner, obj/item/intimate_accessory/genital/plug/genital_plug)
	if(!genital_plug)
		return null

	var/owner_their = owner ? owner.p_their() : "their"
	var/owner_Their = "[uppertext(copytext(owner_their, 1, 2))][copytext(owner_their, 2)]"

	return pick(
		"[owner_Their] vaginal plug shifts with a wet little press inside [owner_their] cunt.",
		"A needy metallic fullness keeps [owner_their] cunt stretched around the plug.",
		"[owner_Their] plugged cunt clenches in small, needy little pulses.",
	)

/datum/sex_action/proc/append_genital_plug_flavor(list/flavor_messages, mob/living/carbon/human/owner, sex_part)
	if(!uses_genital_plug_part(sex_part))
		return

	var/obj/item/intimate_accessory/genital/plug/genital_plug = get_genital_plug(owner)
	if(!genital_plug)
		return

	var/flavor_message = get_genital_plug_action_flavor(owner, genital_plug)
	if(flavor_message)
		flavor_messages += flavor_message

/datum/sex_action/proc/append_genital_piercing_flavor(list/flavor_messages, mob/living/carbon/human/owner, sex_part)
	if(!uses_genital_piercing_part(sex_part))
		return

	var/obj/item/intimate_accessory/piercing/genital/genital_piercing = get_genital_piercing(owner)
	if(!genital_piercing)
		return

	var/flavor_message = get_genital_piercing_action_flavor(owner, genital_piercing, sex_part)
	if(flavor_message)
		flavor_messages += flavor_message

// Usage example:
// apply_silver_intimate_contact("mouth", mouth_owner, contact_target)
// apply_silver_intimate_contact("breast", breast_owner, contact_target)
// apply_silver_intimate_contact("genital", groin_owner, contact_target)
// apply_silver_intimate_contact("rear", rear_owner, contact_target)
// and vice versa for the contact_target if they also have piercings that need to be checked against the owner's silver piercing.
// most sex actions should have this called twice for both parties unless it's a select few outercourse actions. 
/datum/sex_action/proc/modular_on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target)
		return
	if(!prob(20))
		return

	var/list/flavor_messages = list()
	append_genital_plug_flavor(flavor_messages, user, user_sex_part)
	append_genital_piercing_flavor(flavor_messages, user, user_sex_part)
	if(target != user || target_sex_part != user_sex_part)
		append_genital_plug_flavor(flavor_messages, target, target_sex_part)
		append_genital_piercing_flavor(flavor_messages, target, target_sex_part)

	if(flavor_messages.len)
		user.visible_message(span_notice(pick(flavor_messages)))
	return

/datum/sex_action/chastityplay/proc/modular_get_chastity_device_name(mob/living/carbon/human/owner)
	if(owner?.sexcon?.has_chastity_flat())
		return "flat cage"
	if(owner?.sexcon?.has_chastity_cage())
		return "cage"
	return "chastity device"

/datum/sex_action/chastityplay/proc/modular_requires_other_target(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return !!(user && target && user != target)

/datum/sex_action/chastityplay/proc/modular_target_has_cage(mob/living/carbon/human/target)
	return !!target?.sexcon?.has_chastity_cage()

/datum/sex_action/chastityplay/proc/modular_target_has_front_chastity(mob/living/carbon/human/target)
	return !!(target?.sexcon?.has_chastity_cage() || target?.sexcon?.has_chastity_vagina())

/datum/sex_action/chastityplay/proc/modular_can_reach_target_groin(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target)
		return FALSE
	return check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE)

/datum/sex_action/chastityplay/proc/modular_play_chastity_impact_sound(mob/living/carbon/human/target, sound_to_play, volume = 40, chance = 100, vary = TRUE, frequency = -1)
	if(!target || !sound_to_play)
		return FALSE
	if(chance < 100 && !prob(chance))
		return FALSE
	if(islist(sound_to_play))
		if(!length(sound_to_play))
			return FALSE
		playsound(get_turf(target), pick(sound_to_play), volume, vary, frequency)
		return TRUE
	playsound(get_turf(target), sound_to_play, volume, vary, frequency)
	return TRUE

/mob/living/carbon/human/proc/modular_handle_werewolf_transform_chastity()
	if(!istype(chastity_device, /obj/item/chastity))
		return FALSE
	var/obj/item/chastity/chastity = chastity_device
	chastity.break_on_werewolf_transform(src)
	return TRUE

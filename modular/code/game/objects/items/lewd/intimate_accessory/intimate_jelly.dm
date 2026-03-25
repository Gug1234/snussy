/obj/item/intimate_accessory/jelly/eora
	name = "Eora's Jelly"
	desc = "A warm, living lump of slime. It can be pressed into almost any intimate hollow. While some consider them parasites, others find the companionate squirming of the slime irresistible, not to mention the hygiene benefits."
	icon_state = "rear_plug_item_slime"
	item_state = "rear_plug_item_1"
	intimate_slot = INTIMATE_SLOT_GENITAL
	supported_intimate_slots = list(INTIMATE_SLOT_MOUTH, INTIMATE_SLOT_BREAST, INTIMATE_SLOT_GENITAL, INTIMATE_SLOT_REAR)
	intimate_flags = INTIMATE_FLAG_INSERTABLE
	intimate_passive_insertable_effect = TRUE
	sprite_acc = null
	sellprice = 15
	var/passive_arousal_amount = 0.15
	var/internal_cleanup_amount = 1
	var/strange_reagent_amount = 1
	var/lactation_progress = 0
	var/max_lactation_progress = 6
	var/lactation_progress_per_nursing = 1
	var/nursing_milk_drain = 2

/obj/item/intimate_accessory/jelly/eora/Initialize()
	. = ..()
	color = null
	refresh_item_icon_state()
	update_visual_accessory_type()

/obj/item/intimate_accessory/jelly/eora/proc/is_strange_jelly()
	return FALSE

/obj/item/intimate_accessory/jelly/eora/proc/get_item_icon_state()
	return "rear_plug_item_slime"

/obj/item/intimate_accessory/jelly/eora/proc/refresh_item_icon_state()
	icon_state = get_item_icon_state()
	update_icon()
	return icon_state

/obj/item/intimate_accessory/jelly/eora/set_current_intimate_slot(slot)
	. = ..()
	if(.)
		update_visual_accessory_type(slot)
	return .

/obj/item/intimate_accessory/jelly/eora/proc/get_visual_sprite_accessory(slot_override = null)
	switch(get_effective_intimate_slot(slot_override))
		if(INTIMATE_SLOT_BREAST)
			return is_strange_jelly() ? /datum/sprite_accessory/intimate_overlays/slime_boobs/strange : /datum/sprite_accessory/intimate_overlays/slime_boobs
		if(INTIMATE_SLOT_GENITAL)
			return is_strange_jelly() ? /datum/sprite_accessory/intimate_overlays/slime_genitals/strange : /datum/sprite_accessory/intimate_overlays/slime_genitals
		if(INTIMATE_SLOT_MOUTH, INTIMATE_SLOT_REAR)
			return is_strange_jelly() ? /datum/sprite_accessory/intimate_overlays/slime_tendril_overlay/strange : /datum/sprite_accessory/intimate_overlays/slime_tendril_overlay
	return null

/obj/item/intimate_accessory/jelly/eora/proc/update_visual_accessory_type(slot_override = null)
	var/new_sprite_acc = get_visual_sprite_accessory(slot_override)
	var/did_change = (sprite_acc != new_sprite_acc)
	sprite_acc = new_sprite_acc
	if(intimate_feature && sprite_acc)
		intimate_feature.feature_slot = intimate_feature.get_feature_slot_for_item(src)
		call(intimate_feature, /datum/bodypart_feature/proc/set_accessory_type)(sprite_acc, get_intimate_color_string(), wearer)
		intimate_feature.accessory_item = src
		did_change = TRUE
	return did_change

/obj/item/intimate_accessory/jelly/eora/proc/can_nurse_breasts()
	return FALSE

/obj/item/intimate_accessory/jelly/eora/proc/can_milk_penis()
	return FALSE

/obj/item/intimate_accessory/jelly/eora/proc/can_induce_lactation()
	return FALSE

/obj/item/intimate_accessory/jelly/eora/proc/get_lactation_state()
	if(lactation_progress <= 0)
		return "dormant"
	if(lactation_progress < max_lactation_progress)
		return "building"
	return "primed"

/obj/item/intimate_accessory/jelly/eora/proc/get_cocoon_cum_stage()
	return 0

/obj/item/intimate_accessory/jelly/eora/proc/get_cocoon_base_icon_state()
	return "rear_plug_slime_cocoon"

/obj/item/intimate_accessory/jelly/eora/proc/handle_breast_nursing(mob/living/carbon/human/H, mob/living/carbon/human/nursing_partner = null, allow_messages = FALSE)
	if(!H || !can_nurse_breasts() || get_effective_intimate_slot() != INTIMATE_SLOT_BREAST)
		return FALSE

	var/obj/item/organ/breasts/breasts = H.getorganslot(ORGAN_SLOT_BREASTS)
	if(!breasts)
		return FALSE

	var/did_anything = FALSE
	if(can_induce_lactation() && !breasts.lactating)
		var/new_progress = clamp(lactation_progress + max(lactation_progress_per_nursing, 1), 0, max_lactation_progress)
		if(new_progress != lactation_progress)
			lactation_progress = new_progress
			did_anything = TRUE

		if(lactation_progress >= max_lactation_progress)
			breasts.lactating = TRUE
			breasts.milk_stored = max(breasts.milk_stored, min(breasts.milk_max, max(breasts.breast_size * 4, 10)))
			to_chat(H, allow_messages ? span_love("[src] kneads and suckles at my breasts until a hot, milky ache answers it.") : span_notice("[src] leaves my breasts feeling hot, heavy, and ready to leak milk."))

	if(breasts.lactating && breasts.milk_stored > 0)
		var/milk_to_take = min(max(breasts.breast_size, 1), max(nursing_milk_drain, 1), breasts.milk_stored)
		if(milk_to_take > 0)
			breasts.milk_stored -= milk_to_take
			if(nursing_partner?.reagents)
				nursing_partner.reagents.add_reagent(/datum/reagent/consumable/milk, milk_to_take)
			if(allow_messages)
				to_chat(H, span_notice("[src] greedily nurses at my breasts."))
				if(nursing_partner)
					to_chat(nursing_partner, span_notice("I taste warm milk through the slime."))
			did_anything = TRUE

	if(did_anything && H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(1)

	return did_anything

/obj/item/intimate_accessory/jelly/eora/proc/handle_penis_milking(mob/living/carbon/human/H, mob/living/carbon/human/milking_partner = null, allow_messages = FALSE, soothe_needs = FALSE)
	if(!H || !can_milk_penis() || get_effective_intimate_slot() != INTIMATE_SLOT_GENITAL)
		return FALSE
	if(!H.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!H.sexcon?.can_use_penis())
		return FALSE

	var/did_anything = FALSE
	if(!H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(1)
		did_anything = TRUE

	if(soothe_needs && istype(src, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly = src
		if(strange_jelly.try_soothe_needs(H))
			did_anything = TRUE

	if(allow_messages && did_anything)
		to_chat(H, span_notice("[src] ripples snugly around my cock, milking it with hungry little squeezes."))
		if(milking_partner)
			to_chat(milking_partner, span_notice("The slime cinches around [H]'s cock and greedily milks it against my mouth."))

	return did_anything

/obj/item/intimate_accessory/jelly/eora/proc/has_emberwine_feed(obj/item/I)
	if(!I?.reagents)
		return FALSE
	return !!I.reagents.has_reagent(/datum/reagent/consumable/ethanol/beer/emberwine, strange_reagent_amount)

/obj/item/intimate_accessory/jelly/eora/attackby(obj/item/I, mob/living/user, params)
	if(has_emberwine_feed(I))
		if(is_strange_jelly())
			to_chat(user, span_warning("[src] has already been twisted by emberwine."))
			return TRUE
		return feed_emberwine(I, user)
	return ..()

/obj/item/intimate_accessory/jelly/eora/proc/feed_emberwine(obj/item/I, mob/living/user)
	if(!I || !user)
		return FALSE

	if(wearer)
		to_chat(user, span_warning("I need to remove [src] before feeding it emberwine."))
		return TRUE

	if(!has_emberwine_feed(I))
		return FALSE

	I.reagents.remove_reagent(/datum/reagent/consumable/ethanol/beer/emberwine, strange_reagent_amount, TRUE)
	return convert_to_strange(I, user)

/obj/item/intimate_accessory/jelly/eora/proc/convert_to_strange(obj/item/I, mob/living/user)
	if(!user)
		return FALSE

	var/obj/item/intimate_accessory/jelly/eora/strange/new_jelly = new /obj/item/intimate_accessory/jelly/eora/strange(get_turf(src))

	to_chat(user, span_notice("I feed [src] a draught of emberwine. It shivers, darkens, and turns strangely needy."))
	playsound(get_turf(src), 'sound/misc/mat/pop.ogg', 50, TRUE)

	if(!user.put_in_hands(new_jelly))
		new_jelly.forceMove(get_turf(user))
	qdel(src)
	return TRUE

/obj/structure/eora_jelly_cocoon
	name = "living cocoon"
	desc = "A slick cocoon with a semi-transparent mucousal exterior. Something inside is writhing in the sludgey murk."
	icon = 'modular/icons/obj/lewd/intimate_accessories.dmi'
	icon_state = "rear_plug_slime_cocoon"
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	max_integrity = 50
	density = FALSE
	var/mob/living/carbon/human/inhabitant = null
	var/obj/item/intimate_accessory/jelly/eora/strange/source_jelly = null
	var/breakout_time = 60 SECONDS

/obj/structure/eora_jelly_cocoon/proc/refresh_icon_state()
	if(source_jelly)
		icon_state = source_jelly.get_cocoon_icon_state()
	return icon_state

/obj/structure/eora_jelly_cocoon/proc/register_inhabitant_access()
	if(inhabitant)
		RegisterSignal(inhabitant, COMSIG_ERP_LOCATION_ACCESSIBLE, PROC_REF(on_erp_location_accessible))

/obj/structure/eora_jelly_cocoon/proc/unregister_inhabitant_access(mob/living/carbon/human/target = inhabitant)
	if(target)
		UnregisterSignal(target, COMSIG_ERP_LOCATION_ACCESSIBLE)

/obj/structure/eora_jelly_cocoon/proc/on_erp_location_accessible(datum/source, list/check_args)
	SIGNAL_HANDLER
	if(source != inhabitant || !inhabitant || !check_args)
		return 0

	if(check_args[ERP_TARGET] != inhabitant)
		return 0

	if(!check_args[ERP_BODYPART])
		check_args[ERP_BODYPART] = inhabitant.get_bodypart(check_args[ERP_LOCATION])
	if(!check_args[ERP_BODYPART])
		return SIG_CHECK_FAIL

	return SKIP_ADJACENCY_CHECK | SKIP_TILE_CHECK

/obj/structure/eora_jelly_cocoon/proc/insert_target(mob/living/carbon/human/target, obj/item/intimate_accessory/jelly/eora/strange/jelly)
	if(!target || inhabitant)
		return FALSE

	if(target.buckled)
		target.buckled.unbuckle_mob(target, force = TRUE)

	source_jelly = jelly
	inhabitant = target
	register_inhabitant_access()
	refresh_icon_state()
	target.forceMove(src)
	return TRUE

/obj/structure/eora_jelly_cocoon/proc/dump_inhabitant(destroy_after = TRUE, escaped = FALSE)
	var/turf/release_turf = get_turf(src)
	var/mob/living/carbon/human/released = inhabitant
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = source_jelly

	unregister_inhabitant_access(released)
	inhabitant = null
	source_jelly = null

	if(released && release_turf)
		released.forceMove(release_turf)
		playsound(release_turf, 'sound/items/uncork.ogg', 50, TRUE)
		released.Paralyze(10)
		released.visible_message(span_warning("[released] falls out of [src]!"), span_notice("I fall out of [src]."))

	if(jelly)
		jelly.on_cocoon_released(released, src, escaped)

	if(destroy_after)
		qdel(src)

	return !!released

/obj/structure/eora_jelly_cocoon/container_resist(mob/living/user)
	if(user != inhabitant)
		return ..()

	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	to_chat(user, span_notice("I start tearing my way out of [src]. (This will take about [DisplayTimeText(breakout_time)].)"))
	var/resist_message = source_jelly?.get_cocoon_resist_flavor(user)
	visible_message(resist_message ? span_warning(resist_message) : span_notice("Something writhes inside [src]!"))

	if(!do_after(user, breakout_time, target = src))
		return FALSE
	if(!user || user.stat != CONSCIOUS || user.loc != src)
		if(user)
			to_chat(user, span_notice("I fail to tear my way free for now."))
		return FALSE

	dump_inhabitant(TRUE, TRUE)
	return TRUE

/obj/structure/eora_jelly_cocoon/Destroy()
	unregister_inhabitant_access()
	if(inhabitant || source_jelly)
		dump_inhabitant(FALSE, FALSE)
	return ..()

/obj/item/intimate_accessory/jelly/eora/get_intimate_ui_data()
	. = ..()
	.["is_eora_jelly"] = TRUE
	.["jelly_variant"] = "standard"
	.["cleans_internal_cum"] = TRUE
	.["supports_breast_nursing"] = can_nurse_breasts()
	.["supports_penis_milking"] = can_milk_penis()
	.["can_induce_lactation"] = can_induce_lactation()
	.["lactation_progress"] = lactation_progress
	.["max_lactation_progress"] = max_lactation_progress
	.["lactation_state"] = get_lactation_state()
	.["is_cocooned"] = FALSE
	.["cocoon_cum_stage"] = get_cocoon_cum_stage()
	.["cocoon_icon_state"] = get_cocoon_icon_state()
	.["has_bonded_wearer"] = FALSE
	.["bonded_wearer_name"] = null
	.["bonded_wearer_ckey"] = null
	.["bonded_wearer_ref"] = null
	.["obsession_level"] = 0
	.["bond_escalation_level"] = 0

/obj/item/intimate_accessory/jelly/eora/proc/get_cocoon_icon_state()
	var/base_state = get_cocoon_base_icon_state()
	var/cum_stage = clamp(get_cocoon_cum_stage(), 0, 3)
	if(cum_stage <= 0)
		return base_state
	return "[base_state]_cum[cum_stage]"

/obj/item/intimate_accessory/jelly/eora/proc/is_internal_jelly_slot(slot_override = null)
	var/slot = get_effective_intimate_slot(slot_override)
	return slot == INTIMATE_SLOT_GENITAL || slot == INTIMATE_SLOT_REAR

/obj/item/intimate_accessory/jelly/eora/proc/has_slot_anatomy(mob/living/carbon/human/H, slot_override = null)
	if(!H)
		return FALSE

	switch(get_effective_intimate_slot(slot_override))
		if(INTIMATE_SLOT_MOUTH)
			return !!H.getorganslot(ORGAN_SLOT_TONGUE)
		if(INTIMATE_SLOT_BREAST)
			return !!H.getorganslot(ORGAN_SLOT_BREASTS)
		if(INTIMATE_SLOT_GENITAL)
			return !!(H.getorganslot(ORGAN_SLOT_VAGINA) || H.getorganslot(ORGAN_SLOT_PENIS))
		if(INTIMATE_SLOT_REAR)
			return TRUE

	return FALSE

/obj/item/intimate_accessory/jelly/eora/proc/get_slot_anatomy_failure_message(mob/living/carbon/human/H, mob/user, slot_override = null)
	var/slot_name = lowertext(get_intimate_slot_display_name(slot_override))
	if(H == user)
		return "I lack the anatomy to wear [src] in my [slot_name]."
	return "[H] lacks the anatomy to wear [src] in [H.p_their()] [slot_name]."

/obj/item/intimate_accessory/jelly/eora/can_attach_to_intimate_slot(mob/living/carbon/human/H, mob/user, slot, silent = FALSE, require_open_slot = TRUE)
	if(!..())
		return FALSE
	if(has_slot_anatomy(H, slot))
		return TRUE
	if(!silent)
		to_chat(user, span_warning(get_slot_anatomy_failure_message(H, user, slot)))
	return FALSE

/obj/item/intimate_accessory/jelly/eora/bypasses_chastity_blockers(mob/living/carbon/human/H, slot_override = null)
	return TRUE

/obj/item/intimate_accessory/jelly/eora/retains_internal_creampie()
	return is_internal_jelly_slot()

/obj/item/intimate_accessory/jelly/eora/finalize_intimate_equip(mob/living/carbon/human/H)
	update_visual_accessory_type()
	. = ..()
	if(H)
		playsound(H, 'sound/misc/mat/pop.ogg', 45, TRUE, ignore_walls = FALSE)

/obj/item/intimate_accessory/jelly/eora/remove_intimate_accessory(mob/living/carbon/human/H)
	if(H && get_worn_in_slot(H) == src)
		if(is_internal_jelly_slot() && !H.sexcon?.release_retained_internal_creampie(H))
			playsound(H, 'sound/items/uncork.ogg', 45, TRUE, ignore_walls = FALSE)
		else if(!is_internal_jelly_slot())
			playsound(H, 'sound/items/uncork.ogg', 45, TRUE, ignore_walls = FALSE)
	return ..()

/obj/item/intimate_accessory/jelly/eora/handle_passive_insertable_effect(mob/living/carbon/human/H)
	if(!H || get_worn_in_slot(H) != src)
		return FALSE
	if(H.stat == DEAD || !H.sexcon)
		return FALSE

	var/did_anything = FALSE
	if(is_internal_jelly_slot())
		if(H.sexcon.consume_internal_creampie(H, internal_cleanup_amount))
			did_anything = TRUE
		if(get_effective_intimate_slot() == INTIMATE_SLOT_GENITAL && handle_penis_milking(H))
			did_anything = TRUE
	else if(handle_breast_nursing(H))
		did_anything = TRUE

	if(!H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(passive_arousal_amount)
		did_anything = TRUE

	return did_anything

/obj/item/intimate_accessory/jelly/eora/strange
	name = "Strange Eora's Jelly"
	desc = "A living slime turned a strange pinkish violet by emberwine. It yearns for attention, and seems to remember whoever first wore it. Wearing this might be... interesting..."
	icon_state = "rear_plug_item_slime_egg_strange"
	sellprice = 25
	var/mob/living/carbon/human/bonded_wearer = null
	var/bonded_ckey = null
	var/bonded_name = null
	var/need_level = 0
	var/max_need_level = 6
	var/neglect_level = 0
	var/max_neglect_level = 6
	var/last_need_update = 0
	var/need_tick_interval = 5 MINUTES
	var/need_growth_per_tick = 1
	var/last_need_soothe = 0
	var/need_soothe_interval = 2 MINUTES
	var/need_soothe_amount = 1
	var/last_neglect_punishment = 0
	var/neglect_punishment_interval = 3 MINUTES
	var/last_force_strip = 0
	var/force_strip_interval = 10 MINUTES
	var/neglect_punishment_threshold = 3
	var/force_strip_neglect_threshold = 4
	var/cocoon_neglect_threshold = 5
	var/max_obsession_level = 6
	var/max_bond_escalation_level = 4
	var/obsession_level = 0
	var/bond_escalation_level = 0
	var/cocoon_cum_level = 0
	var/cocooned = FALSE
	var/mob/living/carbon/human/cocooned_wearer = null
	var/obj/structure/eora_jelly_cocoon/active_cocoon = null
	var/static/list/cocoon_resist_templates = list(
		"1" = "The tendrils %FORCE% writhe around %USER% as %THEIR% fists drum uselessly against the cocoon.",
		"2" = "%USER% %FORCE% bangs %THEIR% head against the cocoon, only for the tendrils to surge deeper down %THEIR% throat.",
		"3" = "%THEIR_CAP% head rings as the tendrils %FORCE% worm their way into %THEIR% ears.",
		"4" = "Despite %FORCE% biting down on the tendril, the slime keeps violating %USER%'s throat.",
	)
	var/static/list/cocoon_action_templates = list(
		"1" = "The cocoon turns milky as the tendrils %FORCE% pump seed into %TARGET%'s guts.",
		"2" = "The cocoon's outer walls buckle and bulge as the slime %FORCE% slams through %TARGET%'s insides.",
		"3" = "A muffled cry spills from within as the tendrils %FORCE% slither deeper into %TARGET%'s body.",
		"4" = "%TARGET%'s cocoon jerks and ripples as the tendrils %FORCE% work from one end of %THEIR% body to the other.",
	)

/obj/item/intimate_accessory/jelly/eora/strange/Initialize()
	. = ..()
	last_need_update = world.time
	last_need_soothe = world.time

/obj/item/intimate_accessory/jelly/eora/strange/is_strange_jelly()
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_formatted_cocoon_flavor(list/template_bank, mob/living/carbon/human/H, datum/sex_controller/acting_sexcon = null)
	if(!H || !length(template_bank))
		return null

	var/template = template_bank["[rand(1, length(template_bank))]"]
	if(!template)
		return null

	var/force_adjective = acting_sexcon ? acting_sexcon.get_generic_force_adjective() : "roughly"
	var/their = H.p_their()
	var/their_cap = "[uppertext(copytext(their, 1, 2))][copytext(their, 2)]"

	template = replacetext(template, "%FORCE%", force_adjective)
	template = replacetext(template, "%USER%", "[H]")
	template = replacetext(template, "%TARGET%", "[H]")
	template = replacetext(template, "%THEIR%", their)
	template = replacetext(template, "%THEIR_CAP%", their_cap)
	return template

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_resist_flavor(mob/living/carbon/human/H)
	return get_formatted_cocoon_flavor(cocoon_resist_templates, H, H?.sexcon)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_action_flavor(mob/living/carbon/human/H, datum/sex_controller/acting_sexcon = null)
	return get_formatted_cocoon_flavor(cocoon_action_templates, H, acting_sexcon)

/obj/item/intimate_accessory/jelly/eora/strange/get_item_icon_state()
	if(has_bonded_wearer())
		return "rear_plug_item_slime_strange"
	return "rear_plug_item_slime_egg_strange"

/obj/item/intimate_accessory/jelly/eora/strange/get_cocoon_base_icon_state()
	return "rear_plug_slime_cocoon_strange"

/obj/item/intimate_accessory/jelly/eora/strange/can_nurse_breasts()
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/can_milk_penis()
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/can_induce_lactation()
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/get_cocoon_cum_stage()
	return clamp(cocoon_cum_level, 0, 3)

/obj/item/intimate_accessory/jelly/eora/strange/proc/add_cocoon_cum(amount = 1)
	var/new_level = clamp(cocoon_cum_level + max(round(amount), 0), 0, 3)
	if(new_level == cocoon_cum_level)
		return FALSE
	cocoon_cum_level = new_level
	active_cocoon?.refresh_icon_state()
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_true_name()
	return "Baothan Ooze"

/obj/item/intimate_accessory/jelly/eora/strange/proc/can_reveal_true_name_to(mob/user)
	if(!isliving(user))
		return FALSE
	var/mob/living/living_user = user
	return istype(living_user.patron, /datum/patron/inhumen)

/obj/item/intimate_accessory/jelly/eora/strange/get_examine_name(mob/user)
	if(can_reveal_true_name_to(user))
		return "\a [get_true_name()]"
	return ..()

/obj/item/intimate_accessory/jelly/eora/strange/proc/has_bonded_wearer()
	return !!(bonded_ckey || bonded_name)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_need_state()
	if(need_level <= 0)
		return "sated"
	if(need_level <= 2)
		return "restless"
	if(need_level <= 4)
		return "hungry"
	return "aching for attention"

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_neglect_state()
	if(neglect_level <= 0)
		return "well-attended"
	if(neglect_level <= 2)
		return "slightly neglected"
	if(neglect_level <= 4)
		return "resentful"
	return "dangerously possessive"

/obj/item/intimate_accessory/jelly/eora/strange/proc/refresh_need_tension()
	if(!has_bonded_wearer())
		obsession_level = 0
		bond_escalation_level = 0
		return FALSE

	var/new_obsession_level = clamp(1 + round(need_level / 2) + neglect_level, 1, max_obsession_level)
	var/new_bond_escalation_level = clamp(neglect_level - 2, 0, max_bond_escalation_level)
	var/did_change = FALSE

	if(obsession_level != new_obsession_level)
		obsession_level = new_obsession_level
		did_change = TRUE
	if(bond_escalation_level != new_bond_escalation_level)
		bond_escalation_level = new_bond_escalation_level
		did_change = TRUE

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/update_needs_state()
	if(!has_bonded_wearer())
		last_need_update = world.time
		return FALSE

	if(!last_need_update)
		last_need_update = world.time
		return FALSE

	var/did_change = FALSE
	while(last_need_update + need_tick_interval <= world.time)
		last_need_update += need_tick_interval

		var/new_need_level = clamp(need_level + need_growth_per_tick, 0, max_need_level)
		if(new_need_level != need_level)
			need_level = new_need_level
			did_change = TRUE

		if((!wearer || !matches_bonded_wearer(wearer)) && need_level >= max_need_level)
			var/new_neglect_level = clamp(neglect_level + 1, 0, max_neglect_level)
			if(new_neglect_level != neglect_level)
				neglect_level = new_neglect_level
				did_change = TRUE

	if(refresh_need_tension())
		did_change = TRUE

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/soothe_needs(amount = need_soothe_amount, reduce_neglect = TRUE)
	var/new_need_level = clamp(need_level - amount, 0, max_need_level)
	var/new_neglect_level = neglect_level
	var/did_change = FALSE

	if(new_need_level != need_level)
		need_level = new_need_level
		did_change = TRUE

	if(reduce_neglect && !need_level)
		new_neglect_level = clamp(neglect_level - 1, 0, max_neglect_level)
		if(new_neglect_level != neglect_level)
			neglect_level = new_neglect_level
			did_change = TRUE

	if(refresh_need_tension())
		did_change = TRUE

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/try_soothe_needs(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(last_need_soothe && world.time < last_need_soothe + need_soothe_interval)
		return FALSE
	last_need_soothe = world.time
	var/did_change = soothe_needs()
	if(ensure_bonded_wearer_lovefiend(H, TRUE))
		did_change = TRUE
	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/ensure_bonded_wearer_lovefiend(mob/living/carbon/human/H, sate = FALSE)
	if(!H || !matches_bonded_wearer(H))
		return FALSE

	var/did_change = FALSE
	var/datum/charflaw/addiction/lovefiend/L = H.get_flaw(/datum/charflaw/addiction/lovefiend)
	if(!L)
		L = new
		L.time = 45
		if(!islist(H.vices))
			H.vices = list()
		H.vices += L
		L.on_mob_creation(H)
		did_change = TRUE

	if(sate)
		var/was_sated = L.sated
		H.sate_addiction(/datum/charflaw/addiction/lovefiend)
		if(!was_sated && L.sated)
			did_change = TRUE

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/should_cocoon_wearer(mob/living/carbon/human/H)
	if(!H || get_worn_in_slot(H) != src)
		return FALSE
	if(H.stat == DEAD)
		return FALSE
	if(!matches_bonded_wearer(H))
		return FALSE
	return neglect_level >= cocoon_neglect_threshold

/obj/item/intimate_accessory/jelly/eora/strange/proc/on_cocoon_released(mob/living/carbon/human/H, obj/structure/eora_jelly_cocoon/cocoon, escaped = FALSE)
	var/did_change = cocooned || cocooned_wearer || active_cocoon

	if(active_cocoon == cocoon || !cocoon)
		active_cocoon = null
	if(cocoon_cum_level)
		cocoon_cum_level = 0
		did_change = TRUE
	cocooned = FALSE
	if(cocooned_wearer == H || !H)
		cocooned_wearer = null

	if(escaped)
		var/new_neglect_level = min(neglect_level, max(cocoon_neglect_threshold - 1, 0))
		if(new_neglect_level != neglect_level)
			neglect_level = new_neglect_level
			did_change = TRUE
		last_need_soothe = world.time
		if(refresh_need_tension())
			did_change = TRUE

	if(H && did_change && get_worn_in_slot(H) == src)
		notify_intimate_state_change(H, "jelly_cocoon_released")

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/apply_cocoon_to_wearer(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	if(active_cocoon)
		if(QDELETED(active_cocoon))
			active_cocoon = null
		else if(active_cocoon.inhabitant == H)
			cocooned = TRUE
			cocooned_wearer = H
			return FALSE
		else
			qdel(active_cocoon)
			active_cocoon = null

	var/turf/T = get_turf(H)
	if(!T)
		return FALSE

	cocoon_cum_level = 0
	var/obj/structure/eora_jelly_cocoon/new_cocoon = new(T)
	if(!new_cocoon.insert_target(H, src))
		qdel(new_cocoon)
		return FALSE

	active_cocoon = new_cocoon
	cocooned = TRUE
	cocooned_wearer = H
	to_chat(H, span_userdanger("[src] floods over me, sealing me inside a slick, possessive cocoon."))
	H.visible_message(span_warning("A slick cocoon of living jelly flows over [H], swallowing [H.p_them()] from view!"))
	playsound(T, 'sound/misc/mat/pop.ogg', 50, TRUE)
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/remove_cocoon_from_wearer(mob/living/carbon/human/H = cocooned_wearer)
	if(active_cocoon)
		if(QDELETED(active_cocoon))
			active_cocoon = null
		else
			return active_cocoon.dump_inhabitant(TRUE, FALSE)

	return on_cocoon_released(H, null, FALSE)

/obj/item/intimate_accessory/jelly/eora/strange/proc/update_cocoon_state(mob/living/carbon/human/H)
	if(active_cocoon && QDELETED(active_cocoon))
		active_cocoon = null
	if(should_cocoon_wearer(H))
		return apply_cocoon_to_wearer(H)
	if(cocooned || active_cocoon)
		return remove_cocoon_from_wearer(H)
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/try_force_strip_bonded_wearer(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(last_force_strip && world.time < last_force_strip + force_strip_interval)
		return FALSE

	var/has_strippable_item = FALSE
	for(var/obj/item/I in H.get_equipped_items())
		if(istype(I, /obj/item/chastity))
			continue
		if(I.slot_flags & ITEM_SLOT_NECK)
			continue
		has_strippable_item = TRUE
		break
	if(!has_strippable_item)
		return FALSE

	last_force_strip = world.time
	H.drop_all_held_items()
	for(var/obj/item/I in H.get_equipped_items())
		if(istype(I, /obj/item/chastity))
			continue
		if(I.slot_flags & ITEM_SLOT_NECK)
			continue
		H.dropItemToGround(I, TRUE)

	to_chat(H, span_userdanger("[src] writhes possessively, the tendrils lashing out to strip away my clothing."))
	H.visible_message(span_warning("[H] shudders as [src] writhes possessively and strips away [H.p_their()] clothing!"))
	playsound(H, 'sound/misc/vampirespell.ogg', 50, TRUE)
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/try_apply_neglect_punishment(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(H.stat != CONSCIOUS)
		return FALSE
	if(neglect_level < neglect_punishment_threshold)
		return FALSE
	if(last_neglect_punishment && world.time < last_neglect_punishment + neglect_punishment_interval)
		return FALSE

	last_neglect_punishment = world.time
	var/did_anything = FALSE
	to_chat(H, span_userdanger("[src] kneads against me with needy, punishing insistence."))
	H.add_stress(/datum/stressevent/vice/nympho)
	H.play_stress_indicator()
	did_anything = TRUE

	if(H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(clamp(neglect_level + 1, 3, 7))
		did_anything = TRUE

	if(neglect_level >= force_strip_neglect_threshold)
		if(try_force_strip_bonded_wearer(H))
			did_anything = TRUE

	return did_anything

/obj/item/intimate_accessory/jelly/eora/strange/proc/matches_bonded_wearer(mob/living/carbon/human/H)
	if(!H || !has_bonded_wearer())
		return FALSE
	if(bonded_ckey && H.ckey)
		return bonded_ckey == H.ckey
	return bonded_name == H.real_name || bonded_name == H.name

/obj/item/intimate_accessory/jelly/eora/strange/proc/update_bond_to_wearer(mob/living/carbon/human/H)
	if(!H)
		return FALSE

	if(!has_bonded_wearer())
		bonded_wearer = H
		bonded_ckey = H.ckey
		bonded_name = H.real_name
		need_level = 0
		neglect_level = 0
		last_need_update = world.time
		last_need_soothe = world.time
		refresh_need_tension()
		refresh_item_icon_state()
		to_chat(H, span_notice("[src] quivers against me, as if it has chosen me."))
		return TRUE

	if(!matches_bonded_wearer(H))
		return FALSE

	var/did_change = FALSE
	if(bonded_wearer != H)
		bonded_wearer = H
		did_change = TRUE
	if(H.ckey && bonded_ckey != H.ckey)
		bonded_ckey = H.ckey
		did_change = TRUE
	if(H.real_name && bonded_name != H.real_name)
		bonded_name = H.real_name
		did_change = TRUE
	refresh_item_icon_state()
	if(ensure_bonded_wearer_lovefiend(H))
		did_change = TRUE
	if(refresh_need_tension())
		did_change = TRUE
	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/get_intimate_ui_data()
	update_needs_state()
	. = ..()
	.["jelly_variant"] = "strange"
	.["has_bonded_wearer"] = has_bonded_wearer()
	.["bonded_wearer_name"] = bonded_name
	.["bonded_wearer_ckey"] = bonded_ckey
	.["bonded_wearer_ref"] = bonded_wearer ? REF(bonded_wearer) : null
	.["need_level"] = need_level
	.["max_need_level"] = max_need_level
	.["need_state"] = get_need_state()
	.["neglect_level"] = neglect_level
	.["max_neglect_level"] = max_neglect_level
	.["neglect_state"] = get_neglect_state()
	.["is_cocooned"] = cocooned
	.["cocoon_cum_stage"] = get_cocoon_cum_stage()
	.["cocoon_neglect_threshold"] = cocoon_neglect_threshold
	.["cocoon_icon_state"] = get_cocoon_icon_state()
	.["maintains_lovefiend"] = TRUE
	.["punishes_neglect"] = TRUE
	.["can_force_strip_for_neglect"] = neglect_level >= force_strip_neglect_threshold
	.["obsession_level"] = obsession_level
	.["bond_escalation_level"] = bond_escalation_level

/obj/item/intimate_accessory/jelly/eora/strange/examine(mob/user)
	update_needs_state()
	. = ..()
	. += span_info("It seems [get_need_state()] and [get_neglect_state()].")
	if(has_bonded_wearer())
		. += span_info("It feels devoted to a remembered wearer.")
	if(cocooned)
		. += span_warning("It has swaddled its chosen wearer in a possessive cocoon.")
	if(neglect_level >= neglect_punishment_threshold)
		. += span_warning("It seems poised to punish any further neglect.")
	if(can_reveal_true_name_to(user))
		. += span_notice("To my heretical senses, its true name is [get_true_name()].")

/obj/item/intimate_accessory/jelly/eora/strange/finalize_intimate_equip(mob/living/carbon/human/H)
	update_needs_state()
	. = ..()
	var/did_change_state = FALSE
	if(H && update_bond_to_wearer(H))
		did_change_state = TRUE
	if(H && ensure_bonded_wearer_lovefiend(H, TRUE))
		did_change_state = TRUE
	if(H && try_apply_neglect_punishment(H))
		. = TRUE
	if(did_change_state)
		notify_intimate_state_change(H, "jelly_bonded")
	if(H && try_soothe_needs(H))
		did_change_state = TRUE
	if(H && update_cocoon_state(H))
		did_change_state = TRUE
	if(H && did_change_state)
		notify_intimate_state_change(H, "jelly_needs_soothed")

/obj/item/intimate_accessory/jelly/eora/strange/handle_passive_insertable_effect(mob/living/carbon/human/H)
	var/did_change_state = FALSE
	if(update_needs_state())
		did_change_state = TRUE
	. = ..()
	if(H && ensure_bonded_wearer_lovefiend(H))
		did_change_state = TRUE
	if(H && try_apply_neglect_punishment(H))
		. = TRUE
	if(H && try_soothe_needs(H))
		did_change_state = TRUE
		. = TRUE
	if(H && update_cocoon_state(H))
		did_change_state = TRUE
		. = TRUE
	if(H && did_change_state)
		notify_intimate_state_change(H, "jelly_passive_state")

/obj/item/intimate_accessory/jelly/eora/strange/remove_intimate_accessory(mob/living/carbon/human/H)
	update_needs_state()
	if(cocooned)
		remove_cocoon_from_wearer()
	if(H && bonded_wearer == H)
		bonded_wearer = null
	refresh_item_icon_state()
	return ..()

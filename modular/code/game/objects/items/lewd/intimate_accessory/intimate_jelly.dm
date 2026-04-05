/obj/item/intimate_accessory/jelly/eora
	name = "Eora's Jelly"
	desc = "A warm, living lump of slime. It can be pressed into almost any intimate hollow. While some consider them parasites, others find the companionate squirming of the slime irresistible, not to mention the hygiene benefits."
	icon_state = "rear_plug_item_slime"
	item_state = "rear_plug_item_1"
	intimate_slot = INTIMATE_SLOT_JELLY
	/// Supported BODY REGIONS — the jelly can functionally cover any of these.
	/// Storage is always via INTIMATE_SLOT_JELLY; these control behavior dispatch.
	supported_intimate_slots = list(INTIMATE_SLOT_MOUTH, INTIMATE_SLOT_BREAST, INTIMATE_SLOT_GENITAL, INTIMATE_SLOT_REAR)
	intimate_flags = INTIMATE_FLAG_INSERTABLE | INTIMATE_FLAG_JELLY
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
	/// Timestamp of the last manual stimulation command; 0 = never used.
	var/last_jelly_stimulate = 0
	/// Minimum delay between manual stimulation commands (default 2 minutes).
	var/jelly_stimulate_interval = 2 MINUTES
	/// The active slime doppelganger, if any. Only one at a time.
	var/mob/living/carbon/human/slime_doppelganger/active_doppelganger = null

/obj/item/intimate_accessory/jelly/eora/Initialize()
	. = ..()
	// Default to genital region for behavior dispatch — storage is always INTIMATE_SLOT_JELLY.
	if(isnull(current_intimate_slot))
		current_intimate_slot = INTIMATE_SLOT_GENITAL
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
		if(INTIMATE_SLOT_REAR)
			return is_strange_jelly() ? /datum/sprite_accessory/intimate_overlays/slime_genitals_rear/strange : /datum/sprite_accessory/intimate_overlays/slime_genitals_rear
		if(INTIMATE_SLOT_MOUTH)
			return null // mouth slot intentionally has no visual overlay
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
	/// How many active-tick cycles have fired since the last inhabitant was inserted.
	var/tick_count = 0
	/// Interval between active-tick pulses while an inhabitant is sealed inside (30 s).
	var/active_tick_interval = 30 SECONDS
	/// Small arousal bump applied to the inhabitant each active tick.
	var/cocoon_tick_arousal = 4

/obj/structure/eora_jelly_cocoon/proc/refresh_icon_state()
	if(source_jelly)
		icon_state = source_jelly.get_cocoon_icon_state()
	return icon_state

/**
 * Launches the cocoon's active-tick loop in a non-blocking spawned context.
 * The loop fires every active_tick_interval while an inhabitant remains sealed inside.
 * Called from insert_target() after the inhabitant has been moved into the cocoon.
 */
/obj/structure/eora_jelly_cocoon/proc/start_active_tick()
	tick_count = 0
	spawn(active_tick_interval)
		active_tick()

/**
 * Fires one pulse of cocoon activity, then re-queues itself if an inhabitant is still present.
 * Each pulse:
 *   - Broadcasts a flavor message from source_jelly.get_cocoon_action_flavor().
 *   - Applies a small arousal boost to the inhabitant.
 *   - Every 2 ticks advances the cocoon cum-stage icon via source_jelly.add_cocoon_cum(1).
 * Guards against QDELETED source or null/displaced inhabitant before proceeding.
 */
/obj/structure/eora_jelly_cocoon/proc/active_tick()
	// Stop the loop if the cocoon or its data is gone.
	if(QDELETED(src) || !inhabitant || inhabitant.loc != src || !source_jelly || QDELETED(source_jelly))
		return

	var/mob/living/carbon/human/H = inhabitant
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = source_jelly
	tick_count++

	// Pick a random action type for the autonomous cocoon pulse.
	var/static/list/cocoon_tick_actions = list("anal", "throat", "through", "ear", "asphyxiation", "multi")
	var/action_key = pick(cocoon_tick_actions)

	// Emit flavor text from the strange jelly's per-action cocoon template bank.
	var/action_flavor = jelly.get_cocoon_action_flavor(action_key, H)
	if(action_flavor)
		visible_message(span_love(action_flavor))

	// Play a wet slime sound for the cocoon pulse.
	playsound(src, 'sound/misc/mat/insert (1).ogg', 40, TRUE, ignore_walls = FALSE)

	// Apply a small arousal bump to the sealed inhabitant.
	if(H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(cocoon_tick_arousal)

	// Advance the cum-stage visual every 2 ticks.
	if(!(tick_count % 2))
		jelly.add_cocoon_cum(1)

	// Re-queue the next tick.
	spawn(active_tick_interval)
		active_tick()

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
	start_active_tick()
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

	// Autonomous jelly behavior — bead interaction, ambient flavor text, etc.
	if(try_autonomous_behavior(H))
		did_anything = TRUE

	return did_anything

/**
 * Commands the jelly to aggressively consume retained internal fluids (3× passive rate).
 * Only works when the jelly is in an internal slot (genital or rear).
 * Plays a sound and prints flavor text; silently fails if nothing is available to consume.
 * Returns TRUE when fluid was actually consumed.
 */
/obj/item/intimate_accessory/jelly/eora/proc/jelly_eat_internal_cum(mob/living/carbon/human/H)
	if(!H || wearer != H || !is_internal_jelly_slot())
		return FALSE
	if(!H.sexcon)
		return FALSE
	var/amount = internal_cleanup_amount * 3
	if(!H.sexcon.consume_internal_creampie(H, amount))
		to_chat(H, span_notice("[src] probes eagerly inside me but finds nothing to consume."))
		return FALSE
	to_chat(H, span_love("[src] eagerly drinks down what has been left inside me, each pull sending a faint shiver through my core."))
	playsound(H, 'sound/misc/mat/pop.ogg', 30, TRUE, ignore_walls = FALSE)
	return TRUE

/**
 * Triggers an active stimulation burst from the jelly.
 * Applies 3× the passive arousal amount and sends slot-appropriate flavor text.
 * Subject to jelly_stimulate_interval cooldown to prevent spam.
 * Returns TRUE when stimulation fires successfully.
 */
/obj/item/intimate_accessory/jelly/eora/proc/jelly_stimulate_wearer(mob/living/carbon/human/H)
	if(!H || wearer != H || !H.sexcon)
		return FALSE
	if(last_jelly_stimulate && world.time < last_jelly_stimulate + jelly_stimulate_interval)
		to_chat(H, span_notice("[src] is still settling — give it another moment."))
		return FALSE
	last_jelly_stimulate = world.time
	var/slot = get_effective_intimate_slot()
	var/flavor_msg
	switch(slot)
		if(INTIMATE_SLOT_GENITAL)
			flavor_msg = "[src] clenches inward with a sudden, muscular contraction — the slime forcing itself deeper, pressing against bruised walls until the ache blooms into something wet and molten."
		if(INTIMATE_SLOT_REAR)
			flavor_msg = "[src] worms a thick tendril deeper into my guts, the blunt tip grinding against the inner rim until my legs tremble and my stomach clenches."
		if(INTIMATE_SLOT_BREAST)
			flavor_msg = "[src] squeezes tight around my chest, the slime kneading into swollen flesh with a rhythmic, suckling pressure that makes my nipples ache and my breath come short."
		if(INTIMATE_SLOT_MOUTH)
			flavor_msg = "[src] forces itself deeper across my tongue, the thick gel pressing against the back of my throat until I gag, saliva pooling hot around the intrusion."
		else
			flavor_msg = "[src] shifts against me with a disturbingly precise pressure, the slime finding nerves I didn't know I had."
	to_chat(H, span_love(flavor_msg))
	if(!H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(passive_arousal_amount * 3)
	return TRUE

/**
 * Repositions the jelly to a different intimate slot without a full remove/re-equip cycle.
 * Validates anatomy availability and slot vacancy before committing.
 * Releases any retained internal creampie before leaving an internal slot.
 * Detaches and reattaches the bodypart feature so overlays update correctly.
 * Fires notify_intimate_state_change with reason "jelly_swapped" on success.
 * Returns TRUE if the swap completed.
 */
/obj/item/intimate_accessory/jelly/eora/proc/jelly_swap_to_slot(new_slot, mob/living/carbon/human/H)
	if(!H || wearer != H)
		return FALSE
	var/current_slot = get_effective_intimate_slot()
	if(current_slot == new_slot)
		to_chat(H, span_notice("[src] is already positioned there."))
		return FALSE
	if(!supports_intimate_slot(new_slot))
		to_chat(H, span_warning("[src] cannot be placed in that slot."))
		return FALSE
	if(!has_slot_anatomy(H, new_slot))
		to_chat(H, span_warning(get_slot_anatomy_failure_message(H, H, new_slot)))
		return FALSE

	// Release retained internal content before leaving the current internal slot.
	if(is_internal_jelly_slot() && H.sexcon)
		H.sexcon.release_retained_internal_creampie(H)

	// Detach the old bodypart feature so it can be rebuilt under the new slot.
	var/obj/item/bodypart/chest = H.get_bodypart(BODY_ZONE_CHEST)
	if(chest && intimate_feature)
		chest.remove_bodypart_feature(intimate_feature)
	intimate_feature = null

	// Update the jelly's active REGION — storage remains in intimate_jelly.
	// set_current_intimate_slot on the eora subtype also calls update_visual_accessory_type.
	set_current_intimate_slot(new_slot)

	// Reattach the visual overlay feature in the new region position.
	attach_intimate_feature(H)

	var/new_slot_name = lowertext(get_intimate_slot_display_name())
	to_chat(H, span_notice("[src] wriggles and shifts, nestling itself into my [new_slot_name]."))
	H.visible_message(span_notice("[H]'s [src] ripples, repositioning itself."))
	playsound(H, 'sound/misc/mat/pop.ogg', 40, TRUE, ignore_walls = FALSE)
	notify_intimate_state_change(H, "jelly_swapped")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange
	name = "Strange Eora's Jelly"
	desc = "A living slime turned a strange pinkish violet by emberwine. It yearns for attention, and seems to remember whoever first wore it. Wearing this might be... interesting..."
	icon_state = "rear_plug_item_slime_egg_strange"
	sellprice = 25
	var/mob/living/carbon/human/bonded_wearer = null
	var/bonded_ckey = null
	var/bonded_name = null
	/// Player-assigned custom name for the jelly. Null = default name.
	var/custom_jelly_name = null
	/// Accumulated bond progress from consensual sex. Resets on each bond level-up.
	var/bond_progress = 0
	/// How many sex action ticks are needed per bond level increase.
	var/bond_progress_threshold = 8
	var/need_level = 0
	var/max_need_level = 6
	var/neglect_level = 0
	var/max_neglect_level = 6
	var/last_need_update = 0
	var/need_tick_interval = 2 MINUTES       // was 5 min — needs grow faster
	var/need_growth_per_tick = 2             // was 1 — two need levels per tick
	var/last_need_soothe = 0
	var/need_soothe_interval = 1 MINUTES     // was 2 min — can be soothed faster to match
	var/need_soothe_amount = 2               // was 1 — soothing is proportionally stronger
	var/last_neglect_punishment = 0
	var/neglect_punishment_interval = 1.5 MINUTES // was 3 min — punishes faster
	var/last_force_strip = 0
	var/force_strip_interval = 5 MINUTES     // was 10 min — escalates faster
	var/neglect_punishment_threshold = 3
	var/force_strip_neglect_threshold = 4
	var/cocoon_neglect_threshold = 5
	/// Need level at or above which the jelly will cocoon its bonded wearer.
	/// This fires while the jelly IS worn, unlike neglect which grows only off-body.
	var/cocoon_need_threshold = 5
	var/max_obsession_level = 6
	var/max_bond_escalation_level = 4
	var/obsession_level = 0
	var/bond_escalation_level = 0
	var/cocoon_cum_level = 0
	var/cocooned = FALSE
	var/mob/living/carbon/human/cocooned_wearer = null
	var/obj/structure/eora_jelly_cocoon/active_cocoon = null
	var/static/list/cocoon_resist_templates = list(
		"1" = "The tendrils %FORCE% writhe around %USER% as %THEIR% fists drum uselessly against the inner wall, the slime tightening in response — squeezing the air from %THEIR% lungs.",
		"2" = "%USER% %FORCE% slams %THEIR% skull against the cocoon wall, but the impact only drives the tendril deeper down %THEIR% throat, the thick gel filling %THEIR% mouth until %THEIR% jaw aches.",
		"3" = "%THEIR_CAP% head snaps sideways as tendrils %FORCE% bore into %THEIR% ear canals, the wet, invasive pressure making %THEIR% vision swim and %THEIR% stomach heave.",
		"4" = "Despite %FORCE% clamping %THEIR% jaw shut, the tendril oozes between %USER%'s teeth and forces %THEIR% throat open — the slime pumping rhythmically, gagging %THEIR% into a drooling, retching mess.",
	)
	// ── Cocoon flavor text keyed by action type ──
	// Each action gets contextually appropriate cocoon-themed messages.
	var/static/list/cocoon_action_templates = list(
		"anal" = list(
			"1" = "The cocoon goes cloudy with a thick, milky discharge as tendrils %FORCE% pump load after load of viscous seed into %TARGET%'s guts — the belly distending visibly through the translucent walls.",
			"2" = "The cocoon's outer walls buckle and bulge obscenely as the slime %FORCE% rams through %TARGET%'s rear, the shape of the tendril visible through the membrane as it churns.",
			"3" = "A wet, muffled moan spills from within as the cocoon's tendril %FORCE% bores deeper into %TARGET%'s rear — the cocoon shuddering with each convulsion.",
			"4" = "The cocoon clenches around %TARGET% as a fat tendril %FORCE% drives into %THEIR% ass, the translucent walls rippling with each thrust.",
		),
		"throat" = list(
			"1" = "The cocoon pulses as a thick tendril %FORCE% snakes past %TARGET%'s lips, filling %THEIR% throat — %THEIR% jaw distends visibly through the membrane.",
			"2" = "A muffled gag echoes inside the cocoon as the slime %FORCE% drives a tendril deeper into %TARGET%'s throat, the bulge visible through the translucent walls.",
			"3" = "The cocoon shudders as tendrils %FORCE% pour into %TARGET%'s mouth, %THEIR% throat bulging grotesquely behind the membrane.",
			"4" = "Slime %FORCE% floods %TARGET%'s throat from within the cocoon — %THEIR% cheeks balloon outward as the tendril pushes deeper than breath allows.",
		),
		"through" = list(
			"1" = "The cocoon jerks and ripples as the tendril %FORCE% threads from %TARGET%'s rear to %THEIR% throat in one continuous motion — the shape of it visible the entire way through the translucent walls.",
			"2" = "A long, sinuous bulge traces from the base of the cocoon upward as the tendril %FORCE% drives through %TARGET%'s gut, emerging slick from %THEIR% lips.",
			"3" = "The cocoon convulses as the slime %FORCE% completes its path through %TARGET% — rear to mouth, every inch of %THEIR% insides filled and writhing.",
			"4" = "Both ends of the cocoon bulge simultaneously as the tendril %FORCE% works through %TARGET%'s body, the membrane going opaque with thick, milky discharge.",
		),
		"ear" = list(
			"1" = "A thin tendril %FORCE% threads through the cocoon wall beside %TARGET%'s head, worming into %THEIR% ear canal — %TARGET%'s whole body twitches inside the membrane.",
			"2" = "The cocoon hums with a low vibration as a filament %FORCE% probes into %TARGET%'s ear — %THEIR% eyes roll behind the translucent walls.",
			"3" = "A delicate tendril %FORCE% finds %TARGET%'s ear through the cocoon, pulsing against %THEIR% eardrum — the membrane trembles with each muffled whimper.",
			"4" = "The cocoon tightens around %TARGET%'s head as tendrils %FORCE% worm into both ears simultaneously, %THEIR% body going rigid inside the membrane.",
		),
		"asphyxiation" = list(
			"1" = "The cocoon constricts around %TARGET%'s neck as a tendril %FORCE% cinches tight — %THEIR% breath fogs the translucent walls in thin, desperate gasps.",
			"2" = "Slime %FORCE% tightens around %TARGET%'s throat inside the cocoon — %THEIR% face darkens behind the membrane, mouth working silently.",
			"3" = "The cocoon pulses rhythmically as the tendril %FORCE% squeezes %TARGET%'s airway shut, each pulse stealing another breath through the membrane.",
			"4" = "A coil of gel %FORCE% wraps around %TARGET%'s neck within the cocoon, the translucent walls fogging over as %THEIR% oxygen runs thin.",
		),
		"sounding" = list(
			"1" = "A needle-thin tendril %FORCE% threads through the cocoon wall and into %TARGET%'s urethra — %THEIR% whole body arches inside the membrane.",
			"2" = "The cocoon shudders as a gossamer tendril %FORCE% probes into %TARGET%'s slit, the invasive sensation making %THEIR% legs twitch behind the translucent walls.",
			"3" = "A burning, intimate pressure as the tendril %FORCE% bores into %TARGET%'s urethra through the cocoon — %THEIR% muffled cries vibrate through the membrane.",
			"4" = "The cocoon trembles as the thinnest tendril %FORCE% squirms into %TARGET%'s cock from the tip down, exploring every ridge and curve behind the translucent walls.",
		),
		"multi" = list(
			"1" = "%TARGET%'s cocoon jerks and ripples as the tendrils %FORCE% work from both ends simultaneously, the slime filling every cavity until the body inside stops struggling and starts twitching.",
			"2" = "The cocoon bloats and contracts as tendrils %FORCE% fill %TARGET% from every angle at once — throat, rear, and more, the membrane straining around the writhing mass inside.",
			"3" = "Every orifice is %FORCE% claimed simultaneously within the cocoon — %TARGET%'s muffled screams vibrate through the walls as tendrils stuff %THEIR% body full.",
			"4" = "The cocoon goes opaque with discharge as tendrils %FORCE% erupt from every surface inside, filling %TARGET%'s throat, rear, and every gap between — the membrane bulging obscenely.",
		),
	)

	// ── Tendril flavor text for when no cocoon is active ──
	// Keyed by action type. Each entry is an assoc list of numbered templates
	// using the same %TOKEN% system as cocoon templates.
	var/static/list/tendril_action_templates = list(
		"anal" = list(
			"1" = "The jelly %FORCE% splits a thick tendril from its mass and drives it into %TARGET%'s rear — the slime writhing deeper with every pulse.",
			"2" = "A glistening tendril coils and %FORCE% forces its way into %TARGET%'s ass, the slime pulsing with a wet, rhythmic hunger.",
			"3" = "The jelly shivers and extrudes a fat tendril that %FORCE% bores into %TARGET%'s rear, stretching %THEIR% rim around its girth.",
			"4" = "Slick and insistent, the tendril %FORCE% pushes past %TARGET%'s resistance, filling %THEIR% rear with a churning, living warmth.",
		),
		"throat" = list(
			"1" = "The jelly %FORCE% sends a tendril snaking past %TARGET%'s lips and down %THEIR% throat — the thick gel filling %THEIR% mouth with a pulsing warmth.",
			"2" = "A slick tendril %FORCE% worms between %TARGET%'s teeth, oozing down %THEIR% throat until %THEIR% jaw aches around its girth.",
			"3" = "The jelly shudders and %FORCE% drives a tendril into %TARGET%'s mouth — %THEIR% throat bulges visibly as it squirms deeper.",
			"4" = "Tendrils of living slime %FORCE% pour past %TARGET%'s lips, filling %THEIR% throat with rhythmic, gagging pulses.",
		),
		"through" = list(
			"1" = "The tendril %FORCE% pushes through %TARGET%'s gut in one continuous, relentless motion — %TARGET% can feel every inch of it squirming from rear to throat.",
			"2" = "A long, sinuous tendril %FORCE% threads through %TARGET%'s insides, pressing against every wall as it traces a path from rear to mouth.",
			"3" = "The jelly %FORCE% drives its tendril the entire length of %TARGET%'s body — the tip emerging past %THEIR% lips, slick with gel and bile.",
			"4" = "From rear to throat, the tendril %FORCE% fills %TARGET% completely — every twitch of the slime sends shuddering waves through %THEIR% whole body.",
		),
		"ear" = list(
			"1" = "A thin tendril %FORCE% worms into %TARGET%'s ear canal, the wet pressure behind %THEIR% eyes immediate and disorienting.",
			"2" = "The jelly %FORCE% threads a delicate tendril into %TARGET%'s ear — the sensation is invasive, intimate, utterly wrong.",
			"3" = "A slick filament %FORCE% squirms past %TARGET%'s eardrum, pulsing against %THEIR% brain in slow, maddening waves.",
			"4" = "The tendril %FORCE% probes deeper into %TARGET%'s skull through %THEIR% ear canal, each pulse clouding %THEIR% thoughts further.",
		),
		"asphyxiation" = list(
			"1" = "The jelly %FORCE% cinches a thick tendril around %TARGET%'s throat — %THEIR% breath comes in thin, desperate sips.",
			"2" = "Living slime %FORCE% tightens around %TARGET%'s neck, the tendril pulsing in time with %THEIR% fading heartbeat.",
			"3" = "A coil of gel %FORCE% constricts %TARGET%'s airway — %THEIR% face darkens as the jelly squeezes tighter.",
			"4" = "The tendril %FORCE% wraps and rewraps around %TARGET%'s throat, each loop tighter than the last, stealing %THEIR% air in rhythmic pulses.",
		),
		"sounding" = list(
			"1" = "The jelly %FORCE% thins a tendril to a needle-fine point and threads it into %TARGET%'s urethra — the sensation is white-hot and inescapable.",
			"2" = "A gossamer-thin tendril %FORCE% probes into %TARGET%'s urethral slit, the slime pulsing as it pushes deeper with agonizing precision.",
			"3" = "The tendril %FORCE% squirms into %TARGET%'s cock from the tip down, the living probe exploring every ridge and curve of %THEIR% urethra.",
			"4" = "A burning, intimate pressure as the tendril %FORCE% bores into %TARGET%'s slit — the slime filling %THEIR% urethra with a pulsing, invasive fullness.",
		),
		"multi" = list(
			"1" = "The jelly %FORCE% splits into multiple tendrils at once — %TARGET%'s throat, rear, and every gap between are filled simultaneously with squirming slime.",
			"2" = "Tendrils %FORCE% erupt from the jelly in every direction, stuffing %TARGET%'s openings simultaneously — there is no part of %THEIR% body the slime hasn't claimed.",
			"3" = "The jelly %FORCE% surges, filling %TARGET% from every angle at once — throat and rear stuffed full, tendrils writhing in concert inside %THEIR% body.",
			"4" = "Every orifice is %FORCE% claimed at once as the jelly splits and drives — %TARGET% can do nothing but take it as tendrils fill %THEIR% throat, rear, and more.",
		),
	)
	/// Timestamp of the last time an observer used try_comfort_jelly(); 0 = never tended.
	var/last_tended = 0
	/// Minimum delay between observer tend actions.
	var/tend_interval = 1.5 MINUTES         // was 3 min
	/// Timestamp of the last sated-state healing reward; 0 = never fired.
	var/last_sated_reward = 0
	/// Minimum gap between sated rewards to prevent spam.
	var/sated_reward_interval = 3 MINUTES   // was 5 min
	/// Timestamp of the last level-1 ambient insistence message emitted to the bonded wearer.
	var/last_ambient_message = 0
	/// Gap between ambient insistence messages at bond level 1+.
	var/ambient_message_interval = 1 MINUTES // was 2 min
	/// Ambient messages emitted when bond_escalation_level >= 1 during passive tick.
	var/static/list/ambient_insistence_templates = list(
		"1" = "grinds against me from the inside with a slow, kneading pressure — hungry, insistent, like something alive that hasn't been fed.",
		"2" = "rolls a thick, pulsing wave through my gut that makes my knees soften — it wants something and it's not asking politely.",
		"3" = "wriggles deeper with a wet, needful persistence, tendrils probing at raw tissue until I can't think about anything else.",
		"4" = "nudges me from the inside with a warm, throbbing desperation — pressing against bruised walls like it's trying to crawl further in.",
	)
	/// Flavor messages shown when the bonded wearer tries to remove a highly-bonded jelly.
	var/static/list/removal_resist_templates = list(
		"1" = "clenches down hard, tendrils boring deeper in protest — the slime threading itself into raw flesh until the pain of pulling it free outweighs the want.",
		"2" = "surges inward with a possessive, crushing grip, flooding heat through every nerve it can reach, refusing to let go.",
		"3" = "floods my body with a vicious pulse of sensation that makes my vision white out — a last, desperate bid to make me stop reaching for it.",
		"4" = "drives a ring of clinging tendrils deeper, the slime knotting itself inside me with a wet, determined finality — it has no intention of leaving.",
	)

/obj/item/intimate_accessory/jelly/eora/strange/Initialize()
	. = ..()
	last_need_update = world.time
	last_need_soothe = world.time

/obj/item/intimate_accessory/jelly/eora/strange/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/// SSobj processing tick — runs even when the jelly is not worn.
/// Allows need growth and neglect escalation to continue off-body.
/obj/item/intimate_accessory/jelly/eora/strange/process()
	if(!has_bonded_wearer())
		STOP_PROCESSING(SSobj, src)
		return
	// Only tick if we're NOT being worn — the passive insertable effect
	// already handles need growth while worn.
	if(wearer && matches_bonded_wearer(wearer))
		return
	update_needs_state()

/obj/item/intimate_accessory/jelly/eora/strange/is_strange_jelly()
	return TRUE

/// Returns a bond-tinted color string. Higher bond = deeper, more vivid hue.
/// Bond 0: pale pinkish (#C89AC0), Bond 1: warm rose (#D479B8),
/// Bond 2: vivid magenta (#E050B0), Bond 3: deep fuchsia (#E030A8),
/// Bond 4: hot pulsing violet (#F010A0).
/obj/item/intimate_accessory/jelly/eora/strange/get_intimate_color_string()
	var/static/list/bond_colors = list(
		"#C89AC0",  // bond 0 — pale, muted
		"#D479B8",  // bond 1 — warmer
		"#E050B0",  // bond 2 — vivid
		"#E030A8",  // bond 3 — deep
		"#F010A0",  // bond 4 — intense, pulsing
	)
	var/bond_index = clamp(bond_escalation_level + 1, 1, length(bond_colors))
	var/base_color = bond_colors[bond_index]
	return base_color

/// Adds bond level to examine text as a visual descriptor.
/obj/item/intimate_accessory/jelly/eora/strange/examine(mob/user)
	. = ..()
	switch(bond_escalation_level)
		if(0)
			. += span_notice("Its surface is a pale, muted pink — docile and unattached.")
		if(1)
			. += span_notice("A warmer hue pulses through its membrane — it has begun to bond.")
		if(2)
			. += span_warning("Its color has deepened to a vivid magenta. The jelly thrums with possessive energy.")
		if(3)
			. += span_boldwarning("A deep fuchsia saturates its flesh. The bond is strong — almost oppressive.")
		if(4)
			. += span_boldwarning("The jelly blazes with an intense, hot violet. It radiates hunger. The bond is absolute.")

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

/**
 * Returns a random cocoon flavor string for a specific action type.
 *
 * @param action_key  One of: "anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi"
 * @param H           The target mob for pronoun resolution.
 * @param acting_sexcon  Optional sex controller for force adjective.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_action_flavor(action_key, mob/living/carbon/human/H, datum/sex_controller/acting_sexcon = null)
	var/list/action_bank = cocoon_action_templates[action_key]
	if(!length(action_bank))
		return null
	return get_formatted_cocoon_flavor(action_bank, H, acting_sexcon)

/**
 * Returns a random tendril-action flavor string for a specific action type
 * when no cocoon is active. Falls back to null if the action_key has no templates.
 *
 * @param action_key  One of: "anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi"
 * @param H           The target mob for pronoun resolution.
 * @param acting_sexcon  Optional sex controller for force adjective.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_tendril_action_flavor(action_key, mob/living/carbon/human/H, datum/sex_controller/acting_sexcon = null)
	var/list/action_bank = tendril_action_templates[action_key]
	if(!length(action_bank))
		return null
	return get_formatted_cocoon_flavor(action_bank, H, acting_sexcon)

/**
 * Returns a random removal-resistance flavor string for use when the jelly fights removal.
 * The string is prefixed with "[src] " by the caller for readability.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_removal_resist_flavor()
	if(!length(removal_resist_templates))
		return null
	return "[src] [removal_resist_templates["[rand(1, length(removal_resist_templates))]"]]"

/**
 * Emits a mild ambient insistence message to the bonded wearer at bond_escalation_level >= 1.
 * Gated by ambient_message_interval (2 minutes) to avoid spam.
 * Returns TRUE when a message was emitted.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_emit_ambient_insistence(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(bond_escalation_level < 1)
		return FALSE
	if(last_ambient_message && world.time < last_ambient_message + ambient_message_interval)
		return FALSE
	if(!length(ambient_insistence_templates))
		return FALSE
	last_ambient_message = world.time
	to_chat(H, span_notice("[src] [ambient_insistence_templates["[rand(1, length(ambient_insistence_templates))]"]]"))
	return TRUE

/**
 * Rewards the bonded wearer with a small brute heal when the jelly is fully sated (need=0, neglect=0).
 * Fires at most once per sated_reward_interval (5 minutes) to prevent spam.
 * Returns TRUE when a reward was applied.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_apply_sated_reward(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(need_level || neglect_level)
		return FALSE
	if(last_sated_reward && world.time < last_sated_reward + sated_reward_interval)
		return FALSE
	last_sated_reward = world.time
	H.adjustBruteLoss(-1)
	to_chat(H, span_notice("[src] nestles contentedly, its warmth spreading through me like a quiet balm."))
	return TRUE

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


/**
 * Called during consensual sex actions to advance the bond through positive interaction.
 * Each call adds `amount` to `bond_progress`. When progress crosses the threshold,
 * `bond_escalation_level` permanently increases by 1 and progress resets.
 *
 * This ensures bond grows through intimacy, not just neglect/need pressure.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/advance_bond_from_sex(amount = 1)
	if(bond_escalation_level >= max_bond_escalation_level)
		return FALSE
	bond_progress += amount
	if(bond_progress >= bond_progress_threshold)
		bond_progress = 0
		bond_escalation_level = min(bond_escalation_level + 1, max_bond_escalation_level)
		if(wearer)
			to_chat(wearer, span_love("[src] pulses warmly — I can feel its bond deepening."))
			update_visual_accessory_type()
			refresh_item_icon_state()
		return TRUE
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_neglect_state()
	if(neglect_level <= 0)
		return "well-attended"
	if(neglect_level <= 2)
		return "slightly neglected"
	if(neglect_level <= 4)
		return "resentful"
	return "dangerously possessive"


/// Returns a human-readable bond state descriptor for the UI.
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_bond_state()
	switch(bond_escalation_level)
		if(0)
			return "unattached"
		if(1)
			return "curious"
		if(2)
			return "possessive"
		if(3)
			return "devoted"
		if(4)
			return "absolute"
	return "unknown"

/obj/item/intimate_accessory/jelly/eora/strange/proc/refresh_need_tension()
	if(!has_bonded_wearer())
		obsession_level = 0
		// Do NOT zero bond — it's a permanent high-water mark.
		return FALSE

	var/new_obsession_level = clamp(1 + round(need_level / 2) + neglect_level, 1, max_obsession_level)
	var/did_change = FALSE

	if(obsession_level != new_obsession_level)
		obsession_level = new_obsession_level
		did_change = TRUE

	// Bond is a HIGH-WATER MARK — it can only be pushed UP by need/neglect
	// pressure, never pulled down. Soothing/satisfying the jelly does not
	// reduce bond. Bond represents accumulated affection & attachment.
	// The pressure formula can temporarily elevate bond above the permanent
	// floor set by advance_bond_from_sex(), but it can never lower it.
	var/pressure_bond = clamp(round((need_level + neglect_level) / 2) - 1, 0, max_bond_escalation_level)
	var/effective_bond = max(bond_escalation_level, pressure_bond)
	if(bond_escalation_level != effective_bond)
		var/old_bond = bond_escalation_level
		bond_escalation_level = effective_bond
		did_change = TRUE
		// Refresh the mob overlay color when bond level changes
		if(old_bond != effective_bond && wearer)
			update_visual_accessory_type()
			refresh_item_icon_state()

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

/**
 * Allows an observer (non-bonded player) to partially ease the jelly's needs.
 * Applies half-strength soothe_needs with reduce_neglect = FALSE — only the bonded
 * wearer earns neglect reduction. Tracked by last_tended / tend_interval (3 min).
 * Emits a shared visible message to both the comforter and the bonded wearer.
 * Returns TRUE when comfort was applied.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_comfort_jelly(mob/living/carbon/human/comforter)
	if(!comforter)
		return FALSE
	if(!has_bonded_wearer())
		return FALSE
	if(last_tended && world.time < last_tended + tend_interval)
		to_chat(comforter, span_notice("[src] seems content for now — give it a moment before tending again."))
		return FALSE
	last_tended = world.time
	soothe_needs(need_soothe_amount * 0.5, FALSE)
	to_chat(comforter, span_notice("I gently tend to [src], easing its restlessness a little."))
	if(bonded_wearer && !QDELETED(bonded_wearer))
		to_chat(bonded_wearer, span_notice("Someone nearby tends to [src], and it calms slightly at their touch."))
	comforter.visible_message(span_notice("[comforter] reaches out and gently tends to [src]."))
	return TRUE

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
	// Cocoon triggers from high neglect (off-body escalation) OR high need (on-body escalation).
	// Need grows while worn, neglect grows while not worn — both paths can reach the cocoon.
	if(neglect_level >= cocoon_neglect_threshold)
		return TRUE
	if(need_level >= cocoon_need_threshold)
		return TRUE
	return FALSE

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
		// Also reduce need below cocoon threshold so it doesn't immediately re-cocoon
		var/new_need_level = min(need_level, max(cocoon_need_threshold - 1, 0))
		if(new_need_level != need_level)
			need_level = new_need_level
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
		START_PROCESSING(SSobj, src) // Tick even when not worn for neglect growth
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
	// Note: needs are NOT auto-soothed here — soothing requires player action
	// (sex actions, soothe button, or observer comfort).
	if(H && update_cocoon_state(H))
		did_change_state = TRUE
	if(H && did_change_state)
		notify_intimate_state_change(H, "jelly_equipped")

/obj/item/intimate_accessory/jelly/eora/strange/handle_passive_insertable_effect(mob/living/carbon/human/H)
	var/did_change_state = FALSE
	if(update_needs_state())
		did_change_state = TRUE
	. = ..()
	if(H && ensure_bonded_wearer_lovefiend(H))
		did_change_state = TRUE
	if(H && try_apply_neglect_punishment(H))
		. = TRUE

	// Bond level 1+: emit occasional ambient insistence messages.
	if(H && bond_escalation_level >= 1 && try_emit_ambient_insistence(H))
		. = TRUE

	// Bond level 2+: apply a second burst of arousal (doubled passive arousal).
	if(H && bond_escalation_level >= 2 && H.sexcon && !H.sexcon.arousal_frozen)
		if(H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
			H.sexcon.adjust_arousal(passive_arousal_amount)
			. = TRUE

	// Note: needs are NOT auto-soothed during passive ticks — soothing requires
	// player action (sex actions, soothe button, or observer comfort).

	// Sated reward: heal a point of brute when need and neglect are both zero.
	if(H && try_apply_sated_reward(H))
		. = TRUE

	if(H && update_cocoon_state(H))
		did_change_state = TRUE
		. = TRUE
	if(H && did_change_state)
		notify_intimate_state_change(H, "jelly_passive_state")

/**
 * Overrides removal to resist when the bonded wearer tries to remove a high-escalation jelly.
 * At bond level >= 3 and the bonded wearer is conscious, a do_after gate is inserted:
 *   - Level 3: 10-second delay.
 *   - Level 4: 20-second delay + nympho stress event on success.
 * If the do_after fails the proc returns early, aborting removal entirely.
 * Non-bonded wearers and unconscious/NPC removals bypass resistance entirely.
 */
/obj/item/intimate_accessory/jelly/eora/strange/remove_intimate_accessory(mob/living/carbon/human/H)
	update_needs_state()

	// Resistance only applies to a conscious bonded wearer with an active client.
	if(H && H.client && H.stat == CONSCIOUS && has_bonded_wearer() && matches_bonded_wearer(H) && bond_escalation_level >= 3)
		var/resist_flavor = get_removal_resist_flavor()
		if(resist_flavor)
			to_chat(H, span_userdanger(resist_flavor))

		var/resist_delay = (bond_escalation_level >= 4) ? 20 SECONDS : 10 SECONDS
		if(!do_after(H, resist_delay, target = H))
			to_chat(H, span_notice("[src] clings tightly — I cannot bring myself to pull it free right now."))
			return  // Abort; the item stays equipped.

		// Re-validate state after sleeping; another proc may have removed it already.
		if(QDELETED(src) || !H || get_worn_in_slot(H) != src)
			return

		if(bond_escalation_level >= 4)
			H.add_stress(/datum/stressevent/vice/nympho)

	if(cocooned)
		remove_cocoon_from_wearer()
	// Dismiss any active doppelganger
	dismiss_doppelganger()
	if(H && bonded_wearer == H)
		bonded_wearer = null
	refresh_item_icon_state()
	return ..()

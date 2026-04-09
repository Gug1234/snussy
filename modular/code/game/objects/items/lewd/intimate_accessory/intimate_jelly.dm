/// Path to the jelly string bank directory for strings() calls.
#define JELLY_STRINGS_PATH "modular/code/game/objects/items/lewd/intimate_accessory/strings"

// ── Feeding source identifiers ──────────────────────────────────────────────
// Passed to on_jelly_fed() so the proc can select the correct flavor bank.
#define JELLY_FEED_SOURCE_PASSIVE   "passive"      // creampie absorbed during passive tick
#define JELLY_FEED_SOURCE_AGGRESSIVE "aggressive"   // jelly_eat_internal_cum (player command)
#define JELLY_FEED_SOURCE_ORGASM    "orgasm"        // bonded wearer ejaculates
#define JELLY_FEED_SOURCE_COCOON    "cocoon"        // tendril feeding inside cocoon
#define JELLY_FEED_SOURCE_DOPPEL    "doppel"        // doppelganger sex action completed

// ── Cocoon escalation stages ────────────────────────────────────────────────
// The cocoon progresses through four intensity stages over time.
// Each stage increases arousal rate, breakout difficulty, and unlocks side effects.
#define COCOON_STAGE_ENVELOPING 0   // initial capture — gentle, exploratory
#define COCOON_STAGE_SETTLING   1   // rhythm established — insistent and rhythmic
#define COCOON_STAGE_GRIPPING      2   // full intensity — ravenous, stamina drain
#define COCOON_STAGE_OVERWHELMING  3   // peak — total domination, drowsy + stamina drain

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
	/// Minimum delay between manual stimulation commands (default 45 seconds).
	var/jelly_stimulate_interval = 45 SECONDS
	/// Base arousal delivered per stimulation burst (before slot/cocoon scaling).
	var/stimulate_arousal_base = 5
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

/// No-op for base jellies — bond advancement only applies to the strange variant.
/obj/item/intimate_accessory/jelly/eora/proc/advance_bond_from_sex(amount = 1)
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
	/// Interval between active-tick pulses while an inhabitant is sealed inside.
	var/active_tick_interval = 3 SECONDS
	/// Arousal bump applied to the inhabitant each active tick (matches sexcon action pace).
	var/cocoon_tick_arousal = 3
	/// Current escalation stage (COCOON_STAGE_ENVELOPING through COCOON_STAGE_OVERWHELMING).
	var/cocoon_stage = COCOON_STAGE_ENVELOPING
	/// Timer ID for the active-tick loop (TIMER_STOPPABLE). Null when no loop is running.
	var/active_tick_timer_id = null

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
	cocoon_stage = COCOON_STAGE_ENVELOPING
	if(source_jelly)
		breakout_time = source_jelly.get_cocoon_stage_breakout(COCOON_STAGE_ENVELOPING)
	update_stage_appearance()
	active_tick_timer_id = addtimer(CALLBACK(src, PROC_REF(active_tick)), active_tick_interval, TIMER_STOPPABLE)

/**
 * Fires one pulse of cocoon activity, then re-queues itself if an inhabitant is still present.
 * Each pulse:
 *   - Checks for stage advancement and applies escalation effects.
 *   - Broadcasts a flavor message (action or stage-ambient) from source_jelly.
 *   - Applies a stage-scaled arousal boost to the inhabitant.
 *   - Every 20 ticks advances the cocoon cum-stage icon via source_jelly.add_cocoon_cum(1).
 * Guards against QDELETED source or null/displaced inhabitant before proceeding.
 */
/obj/structure/eora_jelly_cocoon/proc/active_tick()
	// Stop the loop if the cocoon or its data is gone.
	if(QDELETED(src) || !inhabitant || inhabitant.loc != src || !source_jelly || QDELETED(source_jelly))
		return

	var/mob/living/carbon/human/H = inhabitant
	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = source_jelly
	tick_count++

	// ── Stage advancement check ──
	try_advance_stage(jelly, H)

	// ── Stage-scaled arousal ──
	var/stage_arousal = jelly.get_cocoon_stage_arousal(cocoon_stage)
	if(H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(stage_arousal)

	// ── Flavor text every 5 ticks (~15s) ──
	if(!(tick_count % 5))
		// Alternate between action flavor and stage-ambient flavor.
		// Stage ambient fires every other flavor tick (every 10 ticks / ~30s).
		var/flavor
		if(!(tick_count % 10))
			flavor = jelly.get_cocoon_escalation_flavor("stage_ambient", cocoon_stage, H)
		if(!flavor)
			var/static/list/cocoon_tick_actions = list("anal", "throat", "through", "ear", "asphyxiation", "multi")
			var/action_key = pick(cocoon_tick_actions)
			flavor = jelly.get_cocoon_action_flavor(action_key, H)
		if(flavor)
			visible_message(span_love(flavor))
		playsound(src, 'sound/misc/mat/insert (1).ogg', 40, TRUE, ignore_walls = FALSE)

	// ── Stage side effects (gripping / overwhelming) ──
	apply_stage_effects(jelly, H)

	// ── Cum-stage visual + tendril feeding every 20 ticks (~60s) ──
	if(!(tick_count % 20))
		jelly.add_cocoon_cum(1)
		jelly.try_cocoon_tendril_feeding(H)

	// Re-queue the next tick via timer instead of spawn() to avoid unbounded scheduler chains.
	active_tick_timer_id = addtimer(CALLBACK(src, PROC_REF(active_tick)), active_tick_interval, TIMER_STOPPABLE)

/**
 * Checks whether the cocoon should advance to the next escalation stage
 * based on the source jelly's tick thresholds. Emits transition flavor
 * and updates breakout time when a stage boundary is crossed.
 */
/obj/structure/eora_jelly_cocoon/proc/try_advance_stage(obj/item/intimate_accessory/jelly/eora/strange/jelly, mob/living/carbon/human/H)
	if(!jelly || cocoon_stage >= COCOON_STAGE_OVERWHELMING)
		return FALSE

	var/new_stage = jelly.get_cocoon_stage_for_tick(tick_count)
	if(new_stage <= cocoon_stage)
		return FALSE

	cocoon_stage = new_stage
	// Update breakout difficulty to match the new stage.
	breakout_time = jelly.get_cocoon_stage_breakout(new_stage)
	// Update the cocoon's name/desc for examine.
	update_stage_appearance()
	// Emit the stage transition flavor message.
	var/transition_flavor = jelly.get_cocoon_escalation_flavor("stage_enter", new_stage, H)
	if(transition_flavor)
		visible_message(span_love(transition_flavor))
		playsound(src, 'sound/misc/mat/pop.ogg', 45, TRUE)
	// Log the transition on the jelly.
	var/static/list/stage_names = list("enveloping", "settling", "gripping", "overwhelming")
	if(new_stage >= 1 && new_stage <= length(stage_names))
		jelly.add_mood_log("cocoon", "Cocoon escalated to [stage_names[new_stage + 1]]")
	return TRUE

/**
 * Applies per-tick side effects that depend on the current escalation stage.
 * Stage 0-1: no extra effects (baseline behavior).
 * Stage 2 (gripping): occasional stamina drain.
 * Stage 3 (overwhelming): stamina drain + drowsiness.
 */
/obj/structure/eora_jelly_cocoon/proc/apply_stage_effects(obj/item/intimate_accessory/jelly/eora/strange/jelly, mob/living/carbon/human/H)
	if(cocoon_stage < COCOON_STAGE_GRIPPING || !H)
		return
	// Stamina drain every 10 ticks (~30s) at stage 2+.
	if(!(tick_count % 10))
		H.adjustStaminaLoss(5)
	// Drowsiness at stage 3 — slow, periodic application.
	if(cocoon_stage >= COCOON_STAGE_OVERWHELMING && !(tick_count % 20))
		H.drowsyness = min(H.drowsyness + 5, 30)

/**
 * Updates the cocoon's name and description to reflect the current escalation stage.
 */
/obj/structure/eora_jelly_cocoon/proc/update_stage_appearance()
	switch(cocoon_stage)
		if(COCOON_STAGE_ENVELOPING)
			name = "living cocoon"
			desc = "A slick cocoon with a semi-transparent mucousal exterior. Something inside is writhing in the sludgey murk."
		if(COCOON_STAGE_SETTLING)
			name = "pulsing cocoon"
			desc = "A thick, opaque cocoon of living slime. It pulses rhythmically, tendrils visibly kneading whatever is trapped within."
		if(COCOON_STAGE_GRIPPING)
			name = "ravenous cocoon"
			desc = "A violently writhing mass of living jelly. Every surface writhes with frantic motion — whatever is inside has been thoroughly claimed."
		if(COCOON_STAGE_OVERWHELMING)
			name = "quiescent cocoon"
			desc = "An eerily still cocoon that pulses in perfect rhythm with whatever heartbeat resides at its core. The boundary between occupant and jelly seems... indistinct."

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

	if(!do_after(user, breakout_time, target = src, progress = TRUE))
		return FALSE
	if(!user || user.stat != CONSCIOUS || user.loc != src)
		if(user)
			to_chat(user, span_notice("I fail to tear my way free for now."))
		return FALSE

	dump_inhabitant(TRUE, TRUE)
	return TRUE

/obj/structure/eora_jelly_cocoon/Destroy()
	if(active_tick_timer_id)
		deltimer(active_tick_timer_id)
		active_tick_timer_id = null
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
 * Applies meaningful arousal scaled by slot and context, plus secondary effects.
 * Subject to jelly_stimulate_interval cooldown to prevent spam.
 * Returns TRUE when stimulation fires successfully.
 */
/obj/item/intimate_accessory/jelly/eora/proc/jelly_stimulate_wearer(mob/living/carbon/human/H)
	if(!H || wearer != H || !H.sexcon)
		return FALSE
	if(last_jelly_stimulate && world.time < last_jelly_stimulate + jelly_stimulate_interval)
		var/remaining = round((last_jelly_stimulate + jelly_stimulate_interval - world.time) / 10)
		to_chat(H, span_notice("[src] is still building pressure — [remaining] second\s."))
		return FALSE
	last_jelly_stimulate = world.time
	var/slot = get_effective_intimate_slot()

	// ── Calculate arousal ──
	// Slot scaling: internal slots (genital/rear) hit harder than surface slots.
	var/slot_multiplier = 1
	switch(slot)
		if(INTIMATE_SLOT_GENITAL)
			slot_multiplier = 1.5
		if(INTIMATE_SLOT_REAR)
			slot_multiplier = 1.4
		if(INTIMATE_SLOT_BREAST)
			slot_multiplier = 1.1
		if(INTIMATE_SLOT_MOUTH)
			slot_multiplier = 1.0

	var/final_arousal = stimulate_arousal_base * slot_multiplier

	// Cocoon bonus: the slime has total access when the wearer is sealed inside.
	var/in_cocoon = FALSE
	if(istype(src, /obj/item/intimate_accessory/jelly/eora/strange))
		var/obj/item/intimate_accessory/jelly/eora/strange/SJ = src
		if(SJ.cocooned && SJ.active_cocoon && !QDELETED(SJ.active_cocoon))
			in_cocoon = TRUE
			final_arousal *= 1.5

	// Rising heat: slight bonus when arousal is already elevated (>40).
	var/current_arousal = H.sexcon.arousal
	if(current_arousal > 40)
		final_arousal += clamp((current_arousal - 40) * 0.05, 0, 3)

	final_arousal = round(final_arousal, 0.1)

	// ── Flavor text — varies by slot and arousal intensity ──
	var/flavor_msg
	var/intense = (current_arousal >= 60)
	switch(slot)
		if(INTIMATE_SLOT_GENITAL)
			if(intense)
				flavor_msg = "[src] clenches inward with a brutal, rhythmic contraction — the slime forcing itself deeper, grinding relentlessly against raw, over-sensitive walls until my whole body locks up and my vision blurs."
			else
				flavor_msg = "[src] clenches inward with a sudden, muscular contraction — the slime forcing itself deeper, pressing against bruised walls until the ache blooms into something wet and molten."
		if(INTIMATE_SLOT_REAR)
			if(intense)
				flavor_msg = "[src] drives a swollen tendril deep, twisting and pulsing against the inner rim with merciless precision — my legs buckle, stomach clenching involuntarily around the intrusion."
			else
				flavor_msg = "[src] worms a thick tendril deeper into my guts, the blunt tip grinding against the inner rim until my legs tremble and my stomach clenches."
		if(INTIMATE_SLOT_BREAST)
			if(intense)
				flavor_msg = "[src] constricts fiercely around my chest, the slime kneading and suckling with desperate hunger — each pulse sends a bolt of aching heat straight through my core."
			else
				flavor_msg = "[src] squeezes tight around my chest, the slime kneading into swollen flesh with a rhythmic, suckling pressure that makes my nipples ache and my breath come short."
		if(INTIMATE_SLOT_MOUTH)
			if(intense)
				flavor_msg = "[src] swells and pushes deeper, filling my throat with a thick, pulsing pressure — I can't breathe, can't think, the gagging reflex lost under wave after wave of obscene fullness."
			else
				flavor_msg = "[src] forces itself deeper across my tongue, the thick gel pressing against the back of my throat until I gag, saliva pooling hot around the intrusion."
		else
			if(intense)
				flavor_msg = "[src] grinds against me with ruthless, knowing pressure — every nerve it finds sends me closer to the edge."
			else
				flavor_msg = "[src] shifts against me with a disturbingly precise pressure, the slime finding nerves I didn't know I had."

	// Cocoon suffix.
	if(in_cocoon)
		flavor_msg += " The cocoon tightens around me, amplifying every sensation."

	to_chat(H, span_love(flavor_msg))

	// ── Apply arousal ──
	if(!H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(final_arousal)

	// ── Secondary effects at high arousal ──
	if(current_arousal >= 60)
		// Brief stamina drain — legs going weak.
		H.adjustStaminaLoss(3)
		if(current_arousal >= 80)
			// Near the edge — visible reaction.
			H.visible_message(span_love("[H] shudders, knees buckling momentarily."))

	// ── Visible reaction ──
	H.visible_message(span_notice("[H]'s [src] pulses with sudden intensity."))
	playsound(H, 'sound/misc/mat/insert (1).ogg', 35, TRUE, ignore_walls = FALSE)
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
	var/bond_progress_threshold = 16
	var/need_level = 0
	var/max_need_level = 6
	/// Jealousy — grows when the bonded wearer has sex with others or equips other intimate accessories.
	var/jealousy_level = 0
	var/max_jealousy_level = 6
	/// Resentment — grows when the wearer actively opposes the jelly (removal, cocoon breakout, arousal denial, over-soothing).
	var/resentment_level = 0
	var/max_resentment_level = 6
	var/last_need_update = 0
	var/need_tick_interval = 2 MINUTES
	var/need_growth_per_tick = 1
	var/last_need_soothe = 0
	var/need_soothe_interval = 1 MINUTES
	var/need_soothe_amount = 2
	var/last_jealousy_punishment = 0
	var/jealousy_punishment_interval = 1.5 MINUTES
	var/last_force_strip = 0
	var/force_strip_interval = 5 MINUTES
	/// Jealousy level at which the jelly starts punishing the wearer (stress, arousal spikes).
	var/jealousy_punishment_threshold = 3
	/// Jealousy level at which the jelly forcibly strips the wearer's clothing.
	var/force_strip_jealousy_threshold = 4
	/// Jealousy level at which the jelly cocoons its bonded wearer.
	var/cocoon_jealousy_threshold = 5
	/// Need level at or above which the jelly will cocoon its bonded wearer.
	var/cocoon_need_threshold = 5
	/// Resentment level at which the jelly punishes the wearer with stress/arousal.
	var/resentment_punishment_threshold = 3
	/// Resentment level at which the jelly becomes significantly harder to remove.
	var/resentment_removal_resist_threshold = 4
	/// Resentment level at which the jelly inflicts deliberate physical pain (toxin).
	var/resentment_pain_threshold = 4
	/// Resentment level at which the jelly refuses manual soothe attempts.
	var/resentment_refusal_threshold = 5
	/// Resentment level at which the jelly weaponizes arousal denial.
	var/resentment_denial_threshold = 5
	/// Amount of resentment gained per triggering event.
	var/resentment_gain_per_event = 1
	/// Resentment decays by 1 per this interval while the jelly is worn and sated (need=0).
	var/resentment_decay_interval = 3 MINUTES
	/// Resentment level at or above which the jelly blocks controller speech/emote/presets.
	var/resentment_communication_block_threshold = 3
	/// Need level at or above which the jelly allows controller force actions and stimulation.
	var/need_force_unlock_threshold = 3
	/// Jealousy level at or above which the jelly allows aggressive cocoon commands (tighten/tendril).
	var/jealousy_cocoon_aggression_threshold = 3
	/// Obsession level at or above which the jelly allows manifestation as an alternative to bond level.
	var/obsession_manifest_threshold = 4
	var/last_resentment_decay = 0
	/// Timestamp of the last resentment punishment tick.
	var/last_resentment_punishment = 0
	/// Minimum gap between resentment punishment ticks.
	var/resentment_punishment_interval = 1.5 MINUTES

	// ── Rivalry tracking ────────────────────────────────────────────────────
	// When the jelly becomes jealous of a specific person (someone who performed
	// sex acts on the bonded wearer), it fixates on them as a rival. The rival
	// is tracked by weakref to prevent hard reference leaks. Rivalry intensifies
	// jealousy effects and triggers targeted hostility messages.

	/// Weakref to the mob the jelly considers its rival. Null when no rival exists.
	var/datum/weakref/rival_ref = null
	/// Display name of the rival (cached for UI/messages when the mob may be unavailable).
	var/rival_name = null
	/// Timestamp of the last rivalry awareness message emitted.
	var/last_rivalry_message = 0
	/// Minimum gap between rivalry detection messages.
	var/rivalry_message_interval = 2 MINUTES

	// ── Transfer trauma ─────────────────────────────────────────────────────
	// When a bonded jelly is worn by someone who is NOT its bonded wearer,
	// the jelly becomes actively hostile. Transfer trauma spikes resentment
	// and jealousy, causes physical pain, and gates all feeding/soothing.
	// The jelly will NOT rebond — it remembers who it belongs to.

	/// TRUE if the jelly is currently being worn by a non-bonded stranger.
	var/transfer_traumatized = FALSE
	/// Timestamp of the last transfer trauma pain tick.
	var/last_transfer_pain = 0
	/// Interval between transfer trauma pain ticks (fires during passive tick).
	var/transfer_pain_interval = 30 SECONDS
	/// Toxin damage per transfer trauma pain tick.
	var/transfer_pain_amount = 1

	var/max_obsession_level = 6
	var/max_bond_escalation_level = 4
	var/obsession_level = 0
	var/bond_escalation_level = 0
	var/cocoon_cum_level = 0
	var/cocooned = FALSE
	var/mob/living/carbon/human/cocooned_wearer = null
	var/obj/structure/eora_jelly_cocoon/active_cocoon = null

	// ── Cocoon escalation config ────────────────────────────────────────────
	// The cocoon progresses through COCOON_STAGE_ENVELOPING → SETTLING →
	// GRIPPING → OVERWHELMING based on active-tick count thresholds.
	// Each stage scales arousal rate and breakout difficulty.

	/// Tick count at which stage advances to SETTLING (~60s at 3s/tick).
	var/cocoon_stage_tick_1 = 20
	/// Tick count at which stage advances to GRIPPING (~180s).
	var/cocoon_stage_tick_2 = 60
	/// Tick count at which stage advances to OVERWHELMING (~360s).
	var/cocoon_stage_tick_3 = 120

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

	// ── Mood-based idle emotes ──────────────────────────────────────────────
	// Visible flavor emotes driven by the jelly's dominant emotional state.
	// Loaded from strings/jelly_mood_emotes.json via the strings() proc.
	// Priority: resentful > jealous > needy > sated. Fires at most once per mood_emote_interval.

	/// Timestamp of last mood emote fired; 0 = never.
	var/last_mood_emote = 0
	/// Minimum gap between visible mood emotes.
	var/mood_emote_interval = 3 MINUTES

	// ── Player command cooldowns ────────────────────────────────────────────
	/// Timestamp of last tendril command; 0 = never.
	var/last_tendril_command = 0
	/// Minimum gap between player-issued tendril commands.
	var/tendril_command_interval = 30 SECONDS
	/// Timestamp of last provoke action; 0 = never.
	var/last_provoke = 0
	/// Minimum gap between provoke actions.
	var/provoke_interval = 1 MINUTES
	/// Timestamp of last controller force action (speech/emote/voice preset/posture); 0 = never.
	var/last_controller_force_action = 0
	/// Minimum gap between controller force actions to prevent spam.
	var/controller_force_action_interval = 5 SECONDS
	/// Bond level required for voluntary cocoon.
	var/voluntary_cocoon_bond_level = 2
	/// Bond level required for tendril commands.
	var/tendril_command_bond_level = 1
	/// Bond level required to directly project into the slime doppelganger.
	var/doppel_control_bond_level = 3

	// ── Mood log ────────────────────────────────────────────────────────────
	// A rolling log of recent emotional events, exposed to the TGUI panel.
	// Each entry is an assoc list: ("time" = formatted_time, "type" = category, "msg" = text).
	// Capped at mood_log_max to prevent unbounded growth.

	/// Rolling list of mood log entries (newest at end).
	var/list/mood_log
	/// Maximum number of mood log entries to retain.
	var/mood_log_max = 25

	// ── Controller activity history ─────────────────────────────────────────
	// A rolling in-round log of controller relationship events visible to the
	// wearer and controller. Separate from mood_log, which tracks emotional
	// events. Each entry is an assoc list:
	//   ("time", "actor", "event", "summary", "severity")
	// Capped at controller_activity_log_max to prevent unbounded growth.

	/// Rolling list of controller activity log entries (newest at end).
	var/list/controller_activity_log
	/// Maximum number of controller activity log entries to retain.
	var/controller_activity_log_max = 40

	// ── Invitation system ───────────────────────────────────────────────────
	// Wearer-initiated invitations to opted-in candidates. Each invitation is
	// an assoc list stored in controller_pending_invitations:
	//   ("id", "candidate_ckey", "candidate_name", "expires_at")
	// Candidates who receive an invitation may accept or decline.

	/// Pending wearer-to-candidate invitations.
	var/list/controller_pending_invitations = list()
	/// Next unique invitation id.
	var/next_controller_invitation_id = 1
	/// Lifetime of a pending invitation.
	var/controller_invitation_expiration = 120 SECONDS
	/// Maximum concurrent invitations.
	var/controller_invitation_limit = 3

	// ── Feeding system ──────────────────────────────────────────────────────
	// The jelly feeds on sexual fluids — consuming creampie, absorbing orgasms,
	// and draining the wearer through cocoon tendrils. Feeding directly soothes
	// the jelly's need_level, creating a natural incentive loop.
	// feeding_satiation is a cumulative lifetime counter that never resets;
	// later features (sated rewards, evolution) key off total fed.

	/// Cumulative units of feeding the jelly has received over its lifetime. Never resets.
	var/feeding_satiation = 0
	/// Timestamp of the last feeding flavor message emitted; 0 = never.
	var/last_feeding_message = 0
	/// Minimum gap between feeding flavor messages to prevent spam.
	var/feeding_message_interval = 30 SECONDS
	/// Whether the bonded wearer is currently accepting targeted controller applications.
	var/controller_applications_open = FALSE
	/// Jelly-local pending controller applications keyed by applicant ckey.
	var/list/pending_controller_applications = list()
	/// Need soothe amount per passive creampie unit consumed.
	var/feeding_soothe_passive = 1
	/// Need soothe amount per aggressive eat event.
	var/feeding_soothe_aggressive = 2
	/// Need soothe amount per wearer orgasm.
	var/feeding_soothe_orgasm = 1
	/// Need soothe amount per cocoon tendril feeding pulse.
	var/feeding_soothe_cocoon = 1
	/// Need soothe amount per doppelganger sex action completion.
	var/feeding_soothe_doppel = 2
	/// Interval between cocoon tendril feeding pulses.
	var/cocoon_feeding_interval = 60 SECONDS
	/// Timestamp of last cocoon tendril feeding event.
	var/last_cocoon_feeding = 0

/obj/item/intimate_accessory/jelly/eora/strange/Initialize()
	. = ..()
	last_need_update = world.time
	last_need_soothe = world.time
	sync_controller_application_listing()

/obj/item/intimate_accessory/jelly/eora/strange/Destroy()
	STOP_PROCESSING(SSobj, src)
	clear_controller_applications(TRUE)
	clear_pending_controller_invitations()
	sync_controller_application_listing()
	dismiss_doppelganger()
	release_bound_controller("The ooze that cradled you shudders, loses its form, and lets you slip free.")
	return ..()

/// SSobj processing tick — runs even when the jelly is not worn.
/// Allows need growth and jealousy escalation to continue off-body.
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

	var/template = pick(template_bank)
	if(!template)
		return null

	var/force_adjective = acting_sexcon ? acting_sexcon.get_generic_force_adjective() : "roughly"
	var/their = H.p_their()
	var/their_cap = "[uppertext(copytext(their, 1, 2))][copytext(their, 2)]"

	template = replacetext(template, "\[FORCE]", force_adjective)
	template = replacetext(template, "\[JELLY]", "[src]")
	template = replacetext(template, "\[USER]", "[H]")
	template = replacetext(template, "\[TARGET]", "[H]")
	template = replacetext(template, "\[THEIR]", their)
	template = replacetext(template, "\[THEIR_CAP]", their_cap)
	return template

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_resist_flavor(mob/living/carbon/human/H)
	var/list/bank = strings("jelly_cocoon_messages.json", "cocoon_resist", JELLY_STRINGS_PATH)
	return get_formatted_cocoon_flavor(bank, H, H?.sexcon)

/**
 * Returns a random cocoon flavor string for a specific action type.
 *
 * @param action_key  One of: "anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi"
 * @param H           The target mob for pronoun resolution.
 * @param acting_sexcon  Optional sex controller for force adjective.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_action_flavor(action_key, mob/living/carbon/human/H, datum/sex_controller/acting_sexcon = null)
	var/list/action_bank = strings("jelly_cocoon_messages.json", "cocoon_[action_key]", JELLY_STRINGS_PATH)
	if(!length(action_bank))
		return null
	return get_formatted_cocoon_flavor(action_bank, H, acting_sexcon)

// ── Cocoon escalation helpers ───────────────────────────────────────────────

/**
 * Returns the escalation stage that should be active given a tick count.
 * Compares against the configurable tick thresholds on the jelly.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_stage_for_tick(tick_count)
	if(tick_count >= cocoon_stage_tick_3)
		return COCOON_STAGE_OVERWHELMING
	if(tick_count >= cocoon_stage_tick_2)
		return COCOON_STAGE_GRIPPING
	if(tick_count >= cocoon_stage_tick_1)
		return COCOON_STAGE_SETTLING
	return COCOON_STAGE_ENVELOPING

/**
 * Returns the arousal-per-tick for a given cocoon escalation stage.
 * Scales from gentle (2) at stage 0 to overwhelming (7) at stage 3.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_stage_arousal(stage)
	switch(stage)
		if(COCOON_STAGE_ENVELOPING)
			return 2
		if(COCOON_STAGE_SETTLING)
			return 3
		if(COCOON_STAGE_GRIPPING)
			return 5
		if(COCOON_STAGE_OVERWHELMING)
			return 7
	return 3

/**
 * Returns the breakout duration for a given cocoon escalation stage.
 * Later stages are significantly harder to escape.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_stage_breakout(stage)
	switch(stage)
		if(COCOON_STAGE_ENVELOPING)
			return 45 SECONDS
		if(COCOON_STAGE_SETTLING)
			return 60 SECONDS
		if(COCOON_STAGE_GRIPPING)
			return 90 SECONDS
		if(COCOON_STAGE_OVERWHELMING)
			return 120 SECONDS
	return 60 SECONDS

/**
 * Returns a resolved escalation flavor string for a given prefix and stage.
 * Builds a bank key like "stage_enter_settling" or "stage_ambient_consuming"
 * and loads from jelly_cocoon_escalation_messages.json.
 *
 * @param prefix  "stage_enter" for transitions, "stage_ambient" for periodic.
 * @param stage   COCOON_STAGE_* constant.
 * @param H       The inhabitant mob for token resolution.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_escalation_flavor(prefix, stage, mob/living/carbon/human/H)
	var/static/list/stage_suffixes = list("enveloping", "settling", "gripping", "overwhelming")
	var/suffix_index = clamp(stage + 1, 1, length(stage_suffixes))
	var/bank_key = "[prefix]_[stage_suffixes[suffix_index]]"
	var/list/bank = strings("jelly_cocoon_escalation_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return get_formatted_cocoon_flavor(bank, H)

/**
 * Returns a human-readable name for the current cocoon escalation stage.
 * Used for TGUI display and mood log entries.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_cocoon_stage_name()
	if(!active_cocoon || QDELETED(active_cocoon))
		return "none"
	switch(active_cocoon.cocoon_stage)
		if(COCOON_STAGE_ENVELOPING)
			return "enveloping"
		if(COCOON_STAGE_SETTLING)
			return "settling"
		if(COCOON_STAGE_GRIPPING)
			return "gripping"
		if(COCOON_STAGE_OVERWHELMING)
			return "overwhelming"

/**
 * Returns the tick count at which the cocoon will advance to the next stage,
 * or 0 if there is no next stage (already at OVERWHELMING or no cocoon).
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_next_cocoon_stage_ticks()
	if(!active_cocoon || QDELETED(active_cocoon))
		return 0
	switch(active_cocoon.cocoon_stage)
		if(COCOON_STAGE_ENVELOPING)
			return cocoon_stage_tick_1
		if(COCOON_STAGE_SETTLING)
			return cocoon_stage_tick_2
		if(COCOON_STAGE_GRIPPING)
			return cocoon_stage_tick_3
	return 0

/**
 * Returns a random tendril-action flavor string for a specific action type
 * when no cocoon is active. Falls back to null if the action_key has no templates.
 *
 * @param action_key  One of: "anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi"
 * @param H           The target mob for pronoun resolution.
 * @param acting_sexcon  Optional sex controller for force adjective.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_tendril_action_flavor(action_key, mob/living/carbon/human/H, datum/sex_controller/acting_sexcon = null)
	var/list/action_bank = strings("jelly_tendril_messages.json", "tendril_[action_key]", JELLY_STRINGS_PATH)
	if(!length(action_bank))
		return null
	return get_formatted_cocoon_flavor(action_bank, H, acting_sexcon)

/**
 * Returns a random removal-resistance flavor string for use when the jelly fights removal.
 * The string is prefixed with "[src] " by the caller for readability.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_removal_resist_flavor()
	var/list/bank = strings("jelly_ambient_messages.json", "removal_resist", JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return "[src] [pick(bank)]"

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
	var/list/bank = strings("jelly_ambient_messages.json", "ambient_insistence", JELLY_STRINGS_PATH)
	if(!length(bank))
		return FALSE
	last_ambient_message = world.time
	to_chat(H, span_notice("[src] [pick(bank)]"))
	return TRUE

/**
 * Rewards the bonded wearer when the jelly is fully content (need=0, jealousy=0, resentment=0).
 * Reward potency scales with lifetime feeding_satiation across four tiers:
 *   Tier 0 (satiation <10):  -1 brute
 *   Tier 1 (satiation 10-24): -1 brute, +5 stamina recovery
 *   Tier 2 (satiation 25-49): -1 brute, +5 stamina, -0.5 toxin
 *   Tier 3 (satiation 50+):   -2 brute, +8 stamina, -1 toxin, -1 burn
 * Fires at most once per sated_reward_interval to prevent spam.
 * Returns TRUE when a reward was applied.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_apply_sated_reward(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(need_level || jealousy_level || resentment_level)
		return FALSE
	if(last_sated_reward && world.time < last_sated_reward + sated_reward_interval)
		return FALSE
	last_sated_reward = world.time

	// Determine reward tier from lifetime feeding.
	var/tier = get_sated_reward_tier()

	// Apply scaled rewards.
	switch(tier)
		if(0)
			H.adjustBruteLoss(-1)
		if(1)
			H.adjustBruteLoss(-1)
			H.adjustStaminaLoss(-5)
		if(2)
			H.adjustBruteLoss(-1)
			H.adjustStaminaLoss(-5)
			H.adjustToxLoss(-0.5)
		if(3)
			H.adjustBruteLoss(-2)
			H.adjustStaminaLoss(-8)
			H.adjustToxLoss(-1)
			H.adjustFireLoss(-1)

	// Emit tier-appropriate flavor text.
	var/flavor = get_sated_reward_flavor(tier, H)
	if(flavor)
		to_chat(H, span_notice(flavor))
	else
		to_chat(H, span_notice("[src] nestles contentedly, its warmth spreading through me like a quiet balm."))

	add_mood_log("need", "Sated reward (tier [tier])")
	return TRUE

/**
 * Returns the current sated reward tier (0-3) based on lifetime feeding_satiation.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_sated_reward_tier()
	if(feeding_satiation >= 50)
		return 3
	if(feeding_satiation >= 25)
		return 2
	if(feeding_satiation >= 10)
		return 1
	return 0

/**
 * Returns a resolved sated reward flavor string for the given tier.
 * Loads from jelly_sated_reward_messages.json and resolves [JELLY] token.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_sated_reward_flavor(tier, mob/living/carbon/human/H)
	var/bank_key = "sated_reward_tier[clamp(tier, 0, 3)]"
	var/list/bank = strings("jelly_sated_reward_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	var/template = pick(bank)
	if(!template)
		return null
	template = replacetext(template, "\[JELLY]", "[src]")
	if(H)
		template = replacetext(template, "\[TARGET]", "[H]")
		template = replacetext(template, "\[THEIR]", H.p_their())
	return template

// ── Feeding system ────────────────────────────────────────────────────────────

/**
 * Centralized feeding handler. Called whenever the jelly consumes sexual fluids.
 * Increments the cumulative feeding_satiation counter, soothes need proportionally,
 * and emits source-specific flavor text (gated by feeding_message_interval).
 *
 * When feeding drops need_level to 0 for the first time since it was elevated,
 * a special "sated pulse" flavor fires to reinforce the reward loop.
 *
 * @param H       The bonded wearer (or cocoon inhabitant).
 * @param source  One of JELLY_FEED_SOURCE_* defines — selects flavor bank & soothe amount.
 * @param amount  Raw units consumed (default 1). Multiplied internally by per-source soothe.
 * @return TRUE if the jelly was fed and state changed.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/on_jelly_fed(mob/living/carbon/human/H, source = JELLY_FEED_SOURCE_PASSIVE, amount = 1)
	if(!H || !has_bonded_wearer())
		return FALSE

	// Accumulate lifetime satiation.
	feeding_satiation += max(amount, 1)
	add_mood_log("feeding", "Fed ([source]): +[max(amount, 1)] satiation")

	// Determine soothe amount by source.
	var/soothe_amount
	switch(source)
		if(JELLY_FEED_SOURCE_PASSIVE)
			soothe_amount = feeding_soothe_passive
		if(JELLY_FEED_SOURCE_AGGRESSIVE)
			soothe_amount = feeding_soothe_aggressive
		if(JELLY_FEED_SOURCE_ORGASM)
			soothe_amount = feeding_soothe_orgasm
		if(JELLY_FEED_SOURCE_COCOON)
			soothe_amount = feeding_soothe_cocoon
		if(JELLY_FEED_SOURCE_DOPPEL)
			soothe_amount = feeding_soothe_doppel
		else
			soothe_amount = 1

	// Track pre-soothe need for sated pulse check.
	var/pre_need = need_level

	// Soothe needs — feeding directly reduces the jelly's hunger.
	// ── Resentment feeding sabotage (resentment >= threshold) ──
	// The jelly grudgingly accepts food but refuses to fully calm down.
	// Soothe effectiveness is halved — the anger dilutes the nourishment.
	var/sabotaged = FALSE
	if(resentment_level >= resentment_punishment_threshold && soothe_amount > 0)
		soothe_amount = max(round(soothe_amount * 0.5), 0)
		sabotaged = TRUE

	// Pass reduce_jealousy = FALSE to avoid the over-soothe penalty
	// (feeding is a natural act, not forced calming).
	if(soothe_amount > 0 && need_level > 0)
		soothe_needs(soothe_amount, FALSE)

	// Emit feeding flavor text on cooldown.
	if(!last_feeding_message || world.time >= last_feeding_message + feeding_message_interval)
		last_feeding_message = world.time
		if(sabotaged)
			// Resentful feeding gets spiteful flavor instead of normal.
			var/sabotage_flavor = get_resentment_flavor("resentment_sabotage")
			if(sabotage_flavor)
				to_chat(H, span_warning(sabotage_flavor))
		else
			var/flavor = get_feeding_flavor(source)
			if(flavor)
				to_chat(H, span_love(flavor))

	// Special sated pulse when need drops to 0 from feeding.
	if(pre_need > 0 && need_level <= 0)
		emit_feeding_sated_pulse(H)

	return TRUE

/**
 * Returns a random feeding flavor string for the given source, with [JELLY] token resolved.
 * Falls back to null if the source has no templates.
 *
 * @param source  One of JELLY_FEED_SOURCE_* defines.
 * @return Resolved flavor string or null.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_feeding_flavor(source)
	var/bank_key
	switch(source)
		if(JELLY_FEED_SOURCE_PASSIVE)
			bank_key = "feeding_passive"
		if(JELLY_FEED_SOURCE_AGGRESSIVE)
			bank_key = "feeding_aggressive"
		if(JELLY_FEED_SOURCE_ORGASM)
			bank_key = "feeding_orgasm"
		if(JELLY_FEED_SOURCE_COCOON)
			bank_key = "feeding_cocoon_tendril"
		else
			return null

	var/list/bank = strings("jelly_feeding_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	var/template = pick(bank)
	return resolve_feeding_tokens(template)

/**
 * Resolves token placeholders in a feeding flavor string.
 * Supported tokens: [JELLY] → the jelly's display name.
 *
 * @param template  Raw string with optional [JELLY] tokens.
 * @return Resolved string.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/resolve_feeding_tokens(template)
	if(!template)
		return null
	return replacetext(template, "\[JELLY]", "[src]")

/**
 * Emits a special sated-pulse message when feeding drops need_level to 0.
 * Fires at most once per feeding_message_interval to avoid doubling up with
 * the regular feeding flavor message. Only fires to the bonded wearer.
 *
 * @param H  The bonded wearer.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/emit_feeding_sated_pulse(mob/living/carbon/human/H)
	if(!H)
		return
	var/list/bank = strings("jelly_feeding_messages.json", "feeding_sated_pulse", JELLY_STRINGS_PATH)
	if(!length(bank))
		return
	var/template = pick(bank)
	var/flavor = resolve_feeding_tokens(template)
	if(flavor)
		to_chat(H, span_notice(flavor))

/**
 * Fires a tendril feeding pulse during cocoon active_tick.
 * Uses the existing tendril messages JSON for flavor text (currently the ONLY
 * runtime consumer of those templates), then triggers on_jelly_fed for soothing.
 * Gated by cocoon_feeding_interval to avoid over-soothing inside the cocoon.
 *
 * @param H  The cocoon inhabitant.
 * @return TRUE if feeding occurred.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_cocoon_tendril_feeding(mob/living/carbon/human/H)
	if(!H || !has_bonded_wearer())
		return FALSE
	if(last_cocoon_feeding && world.time < last_cocoon_feeding + cocoon_feeding_interval)
		return FALSE
	last_cocoon_feeding = world.time

	// Select a random tendril action for flavor variety.
	var/static/list/tendril_actions = list("anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi")
	var/action_key = pick(tendril_actions)

	// Emit tendril flavor text (this is the primary consumer of jelly_tendril_messages.json).
	var/tendril_flavor = get_tendril_action_flavor(action_key, H, H?.sexcon)
	if(tendril_flavor && active_cocoon)
		active_cocoon.visible_message(span_love(tendril_flavor))

	// Feed the jelly — the tendril drains nourishment from the sealed inhabitant.
	on_jelly_fed(H, JELLY_FEED_SOURCE_COCOON)
	return TRUE

/**
 * Signal handler: fired when the bonded wearer ejaculates (COMSIG_MOB_EJACULATED).
 * The jelly feeds on the orgasm's sexual energy, soothing needs.
 * Only fires if the jelly is currently worn and bonded to the source mob.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/on_bonded_wearer_ejaculated(datum/source)
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = source
	if(!istype(H) || !matches_bonded_wearer(H))
		return
	if(get_worn_in_slot(H) != src)
		return
	on_jelly_fed(H, JELLY_FEED_SOURCE_ORGASM)

/**
 * Called when a doppelganger sex action completes. Triggers feeding with the
 * doppel source. The amount defaults to 1 (the act itself), not fluid volume.
 * Avoids referencing JELLY_FEED_SOURCE_DOPPEL from the sex action file (which
 * is compiled earlier in the DME include order).
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/on_doppelganger_sex_complete(mob/living/carbon/human/H)
	if(!H)
		return
	on_jelly_fed(H, JELLY_FEED_SOURCE_DOPPEL)

/**
 * Strange jelly override: aggressive creampie consumption also triggers feeding.
 * Calls the base proc for consumption/flavor/sound, then feeds the jelly.
 */
/obj/item/intimate_accessory/jelly/eora/strange/jelly_eat_internal_cum(mob/living/carbon/human/H)
	if(!..())
		return FALSE
	on_jelly_fed(H, JELLY_FEED_SOURCE_AGGRESSIVE, internal_cleanup_amount * 3)
	return TRUE

/**
 * Emits a visible mood-based idle emote driven by the jelly's dominant emotional state.
 * Priority: resentful > jealous > needy > sated.
 * Nearby players see a third-person description; the bonded wearer gets a first-person
 * sensory message. Gated by mood_emote_interval (3 minutes) to avoid spam.
 * Only fires on bonded strange jellies that are currently worn.
 * Flavor text loaded from strings/jelly_mood_emotes.json.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_emit_mood_emote(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(last_mood_emote && world.time < last_mood_emote + mood_emote_interval)
		return FALSE

	var/mood_key
	if(resentment_level >= 3)
		mood_key = "resentful"
	else if(jealousy_level >= 3)
		mood_key = "jealous"
	else if(need_level >= 3)
		mood_key = "needy"
	else if(!need_level && !jealousy_level && !resentment_level)
		mood_key = "sated"
	else
		// Low-but-nonzero emotional state — no emote this tick.
		return FALSE

	var/list/visible_bank = strings("jelly_mood_emotes.json", "[mood_key]_visible", JELLY_STRINGS_PATH)
	var/list/self_bank = strings("jelly_mood_emotes.json", "[mood_key]_self", JELLY_STRINGS_PATH)
	if(!length(visible_bank) || !length(self_bank))
		return FALSE

	last_mood_emote = world.time
	var/idx = rand(1, min(length(visible_bank), length(self_bank)))
	var/visible_text = visible_bank[idx]
	var/self_text = self_bank[idx]

	// Third-person visible message for nearby observers; self-message for wearer.
	H.visible_message(
		span_notice("[H]'s [src] [visible_text]"),
		span_notice("[self_text]"),
	)
	return TRUE

// ── Mood Log ────────────────────────────────────────────────────────────────

/**
 * Appends an entry to the jelly's mood log. Trims to mood_log_max.
 * Args:
 *   event_type - category string ("feeding", "jealousy", "resentment", "need", "bond", "rivalry", "transfer", "cocoon")
 *   message    - brief human-readable description
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/add_mood_log(event_type, message)
	if(!event_type || !message)
		return
	// Format time as MM:SS from round start.
	var/total_seconds = round(world.time / 10)
	var/minutes = round(total_seconds / 60)
	var/seconds = total_seconds % 60
	var/time_str = "[minutes]:[seconds < 10 ? "0" : ""][seconds]"

	var/list/entry = list()
	entry["time"] = time_str
	entry["type"] = event_type
	entry["msg"] = message

	LAZYADD(mood_log, list(entry))
	if(LAZYLEN(mood_log) > mood_log_max)
		mood_log.Cut(1, 2)

// ── Controller Activity Log ─────────────────────────────────────────────────

/**
 * Appends an entry to the shared controller activity history.
 * Args:
 *   actor_side - "wearer", "controller", "admin", or "system"
 *   event_type - category string ("bind", "release", "manifest", "return", "request",
 *                "permission", "suspension", "invitation", "dismissal", "direct_control")
 *   summary    - brief human-readable description
 *   severity   - optional highlight: "normal" (default), "important", "warning"
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/add_controller_activity(actor_side, event_type, summary, severity = "normal")
	if(!actor_side || !event_type || !summary)
		return
	var/total_seconds = round(world.time / 10)
	var/minutes = round(total_seconds / 60)
	var/seconds = total_seconds % 60
	var/time_str = "[minutes]:[seconds < 10 ? "0" : ""][seconds]"

	var/list/entry = list()
	entry["time"] = time_str
	entry["actor"] = actor_side
	entry["event"] = event_type
	entry["summary"] = summary
	entry["severity"] = severity

	LAZYADD(controller_activity_log, list(entry))
	if(LAZYLEN(controller_activity_log) > controller_activity_log_max)
		controller_activity_log.Cut(1, 2)

/**
 * Returns the controller activity log serialised for TGUI.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_activity_ui_data()
	if(!LAZYLEN(controller_activity_log))
		return list()
	return controller_activity_log.Copy()

// ── Invitation System ───────────────────────────────────────────────────────

/**
 * Prune expired or invalid invitations from the pending list.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/prune_expired_controller_invitations()
	if(!islist(controller_pending_invitations) || !controller_pending_invitations.len)
		if(!islist(controller_pending_invitations))
			controller_pending_invitations = list()
		return FALSE
	var/did_prune = FALSE
	for(var/i = controller_pending_invitations.len, i >= 1, i--)
		var/list/invite = controller_pending_invitations[i]
		if(!islist(invite))
			controller_pending_invitations.Cut(i, i + 1)
			did_prune = TRUE
			continue
		var/expires_at = text2num("[invite["expires_at"]]")
		if(expires_at && world.time >= expires_at)
			controller_pending_invitations.Cut(i, i + 1)
			did_prune = TRUE
			continue
		// Prune if the candidate client is gone.
		var/candidate_ckey = "[invite["candidate_ckey"]]"
		var/client/candidate_client = null
		for(var/client/C in GLOB.clients)
			if(C.ckey == candidate_ckey)
				candidate_client = C
				break
		if(!candidate_client)
			controller_pending_invitations.Cut(i, i + 1)
			did_prune = TRUE
	return did_prune

/**
 * Clear all pending invitations.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/clear_pending_controller_invitations()
	if(!islist(controller_pending_invitations))
		controller_pending_invitations = list()
	if(!controller_pending_invitations.len)
		return FALSE
	controller_pending_invitations.Cut()
	return TRUE

/**
 * Find a pending invitation by candidate ckey.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/find_pending_controller_invitation_by_ckey(candidate_ckey)
	prune_expired_controller_invitations()
	if(!islist(controller_pending_invitations) || !controller_pending_invitations.len)
		return null
	for(var/list/invite in controller_pending_invitations)
		if(!islist(invite))
			continue
		if("[invite["candidate_ckey"]]" == candidate_ckey)
			return invite
	return null

/**
 * Get a pending invitation by id.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_pending_controller_invitation(invitation_id)
	prune_expired_controller_invitations()
	if(!islist(controller_pending_invitations) || !controller_pending_invitations.len)
		return null
	for(var/list/invite in controller_pending_invitations)
		if(!islist(invite))
			continue
		if(text2num("[invite["id"]]") == invitation_id)
			return invite
	return null

/**
 * Remove a pending invitation by id.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/remove_pending_controller_invitation(invitation_id)
	if(!islist(controller_pending_invitations) || !controller_pending_invitations.len)
		return FALSE
	for(var/i = controller_pending_invitations.len, i >= 1, i--)
		var/list/invite = controller_pending_invitations[i]
		if(!islist(invite))
			continue
		if(text2num("[invite["id"]]") != invitation_id)
			continue
		controller_pending_invitations.Cut(i, i + 1)
		return TRUE
	return FALSE

/**
 * Serialise pending invitations for TGUI.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_invitation_ui_data()
	prune_expired_controller_invitations()
	var/list/ui_invites = list()
	if(!islist(controller_pending_invitations) || !controller_pending_invitations.len)
		return ui_invites
	for(var/list/invite in controller_pending_invitations)
		if(!islist(invite))
			continue
		var/expires_at = text2num("[invite["expires_at"]]")
		var/time_left = max(expires_at - world.time, 0)
		ui_invites += list(list(
			"id" = text2num("[invite["id"]]"),
			"candidate_ckey" = "[invite["candidate_ckey"]]",
			"candidate_name" = "[invite["candidate_name"]]",
			"expires_in" = time_left ? DisplayTimeText(time_left) : "expired",
		))
	return ui_invites

/**
 * Wearer sends an invitation to a specific opted-in candidate.
 * The candidate must be in the jelly controller queue and not already applied/invited.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/send_controller_invitation(mob/living/carbon/human/H, candidate_ckey)
	if(!can_accept_controller_applications(H))
		return FALSE
	if(!candidate_ckey)
		return FALSE
	prune_expired_controller_invitations()
	if(!islist(controller_pending_invitations))
		controller_pending_invitations = list()
	if(controller_pending_invitations.len >= controller_invitation_limit)
		to_chat(H, span_warning("Too many pending invitations. Wait for one to expire or be answered."))
		return FALSE
	// No duplicate invitations for the same candidate.
	if(find_pending_controller_invitation_by_ckey(candidate_ckey))
		to_chat(H, span_notice("An invitation to that candidate is already pending."))
		return FALSE
	// Find the candidate client.
	var/client/candidate_client = null
	for(var/client/C in GLOB.clients)
		if(C.ckey == candidate_ckey)
			candidate_client = C
			break
	if(!candidate_client)
		to_chat(H, span_warning("That candidate is no longer available."))
		return FALSE
	// Must be opted in to the jelly controller queue.
	if(!(candidate_client in GLOB.jelly_controller_queue))
		to_chat(H, span_warning("That player is not drawn to the ooze right now."))
		return FALSE
	// Don't invite yourself.
	if(candidate_client.ckey == H.ckey)
		to_chat(H, span_warning("I can't invite myself."))
		return FALSE
	// Check that the candidate is valid.
	if(!is_valid_jelly_controller_candidate(candidate_client.mob))
		to_chat(H, span_warning("That soul is not in a state to answer the ooze's call."))
		return FALSE
	// Candidate's jelly prefs must be ready.
	var/datum/jelly_prefs/pref = candidate_client.prefs?.jelly_prefs
	if(!pref?.is_profile_ready())
		to_chat(H, span_warning("That soul's vessel is not yet prepared."))
		return FALSE
	var/candidate_name = pref.jelly_name ? pref.jelly_name : candidate_ckey
	var/list/invite = list(
		"id" = next_controller_invitation_id,
		"candidate_ckey" = candidate_ckey,
		"candidate_name" = candidate_name,
		"expires_at" = world.time + controller_invitation_expiration,
	)
	next_controller_invitation_id++
	controller_pending_invitations += list(invite)
	var/invite_id = invite["id"]
	to_chat(H, span_notice("I beckon [candidate_name] toward the living heart of [src]."))
	if(candidate_client.mob)
		to_chat(candidate_client.mob, span_notice("[H.real_name]'s [custom_jelly_name ? custom_jelly_name : name] pulses with a beckoning warmth — it calls me inward."))
	add_controller_activity("wearer", "invitation", "Invited [candidate_name]")
	log_controller_admin_event("[key_name(H)] invited [candidate_ckey] to [src].")
	// Spawn an async prompt for the candidate.
	INVOKE_ASYNC(src, PROC_REF(_prompt_invitation_candidate), invite_id, candidate_client)
	return TRUE

/**
 * Async helper: prompts the candidate via askuser for a pending invitation.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/_prompt_invitation_candidate(invite_id, client/candidate_client)
	if(!candidate_client || !candidate_client.mob)
		return
	var/list/invite = get_pending_controller_invitation(invite_id)
	if(!islist(invite))
		return
	var/jelly_label = custom_jelly_name ? custom_jelly_name : name
	var/wearer_label = wearer ? wearer.real_name : "someone"
	var/prompt = "[wearer_label]'s [jelly_label] beckons you into its living heart. Will you answer?"
	switch(askuser(candidate_client.mob, prompt, "Please answer in [DisplayTimeText(1200)]!", "Accept", "Decline", StealFocus = 0, Timeout = 1200))
		if(1)
			respond_to_controller_invitation(invite_id, TRUE, candidate_client.mob)
		if(2)
			respond_to_controller_invitation(invite_id, FALSE, candidate_client.mob)
		else
			// Timed out — clean up silently.
			var/list/expired_invite = get_pending_controller_invitation(invite_id)
			if(islist(expired_invite))
				remove_pending_controller_invitation(invite_id)
				add_controller_activity("system", "invitation", "[invite["candidate_name"]] did not respond")

/**
 * Wearer cancels a pending invitation.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/cancel_controller_invitation(invitation_id, mob/living/carbon/human/H)
	if(!can_accept_controller_applications(H))
		return FALSE
	var/list/invite = get_pending_controller_invitation(invitation_id)
	if(!islist(invite))
		to_chat(H, span_warning("That invitation is no longer pending."))
		return FALSE
	var/candidate_name = "[invite["candidate_name"]]"
	var/candidate_ckey = "[invite["candidate_ckey"]]"
	remove_pending_controller_invitation(invitation_id)
	to_chat(H, span_notice("I withdraw the beckoning to [candidate_name]."))
	// Notify the candidate if online.
	for(var/client/C in GLOB.clients)
		if(C.ckey == candidate_ckey && C.mob)
			to_chat(C.mob, span_notice("The beckoning warmth from [custom_jelly_name ? custom_jelly_name : name] fades — the call is withdrawn."))
			break
	add_controller_activity("wearer", "invitation", "Withdrew invitation to [candidate_name]")
	return TRUE

/**
 * Candidate responds to a pending invitation (accept or decline).
 * On accept, runs the same binding flow as application acceptance.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/respond_to_controller_invitation(invitation_id, accepted, mob/candidate)
	if(!candidate || !candidate.client)
		return FALSE
	var/list/invite = get_pending_controller_invitation(invitation_id)
	if(!islist(invite))
		to_chat(candidate, span_warning("That beckoning has faded or been withdrawn."))
		return FALSE
	if("[invite["candidate_ckey"]]" != candidate.ckey)
		return FALSE
	remove_pending_controller_invitation(invitation_id)
	var/candidate_name = "[invite["candidate_name"]]"
	if(!accepted)
		to_chat(candidate, span_notice("I turn away from the beckoning."))
		if(wearer && !QDELETED(wearer))
			to_chat(wearer, span_notice("[candidate_name] turns away from [src]'s call."))
		add_controller_activity("controller", "invitation", "[candidate_name] declined invitation")
		return TRUE
	// Accepted — run binding flow.
	if(has_bound_controller())
		to_chat(candidate, span_warning("[src] already harbors an inhabiting presence."))
		return FALSE
	if(!can_accept_controller_applications())
		to_chat(candidate, span_warning("[src] cannot accept a spirit in its current state."))
		return FALSE
	var/datum/jelly_prefs/pref = candidate.client.prefs?.jelly_prefs
	if(!pref?.is_profile_ready())
		to_chat(candidate, span_warning("My vessel is no longer prepared for the ooze."))
		return FALSE
	if(!is_valid_jelly_controller_candidate(candidate))
		to_chat(candidate, span_warning("I am no longer in a state to answer the ooze's call."))
		return FALSE
	add_controller_activity("controller", "invitation", "[candidate_name] accepted invitation")
	return offer_controller_role_to_candidate(wearer, candidate.client, pref)

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

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_state_name()
	switch(get_controller_state())
		if("manifested")
			return "Walking in shaped flesh"
		if("shell_bound")
			return "Resting within my body"
		if("suspended")
			return "Dormant — the bond wavers"
	return "Unbound"

/obj/item/intimate_accessory/jelly/eora/strange/proc/set_controller_state(new_state)
	if(!new_state || controller_state == new_state)
		return FALSE
	controller_state = new_state
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/suspend_bound_controller(context = "disconnect")
	if(!has_bound_controller())
		return FALSE
	var/previous_state = controller_state
	if(previous_state == "suspended")
		return FALSE
	set_controller_state("suspended")
	// Clear the shell's key so BYOND does not auto-route reconnecting
	// clients to the invisible shell mob instead of the lobby.
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.key = null
	var/controller_name = get_bound_controller_name()
	if(!controller_name)
		controller_name = "The bound controller"
	if(wearer && !QDELETED(wearer))
		to_chat(wearer, span_notice("[controller_name] falls quiet within [src]. The presence fades to faint stillness."))
	log_controller_admin_event("[controller_name] became suspended in [src] ([context]).")
	add_controller_activity("system", "suspension", "[controller_name] suspended ([context])", "warning")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/log_controller_admin_event(message, notify_admins = FALSE)
	if(!message)
		return FALSE
	var/full_message = "JELLY: [message]"
	log_game(full_message)
	log_admin(full_message)
	if(notify_admins)
		message_admins(span_adminnotice(full_message))
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_audit_lines()
	var/list/lines = list()
	lines += "State: [get_controller_state_name()] ([get_controller_state()])"
	lines += "Bound controller: [get_bound_controller_name() ? get_bound_controller_name() : "none"]"
	lines += "Controller ckey: [controller_ckey ? controller_ckey : "none"]"
	lines += "Wearer: [wearer && !QDELETED(wearer) ? "[wearer.real_name] ([wearer.ckey ? wearer.ckey : "no ckey"])" : "none"]"
	lines += "Wearer anchor: [is_controller_wearer_available() ? "stable" : get_controller_wearer_status_text()]"
	lines += "Shell present: [controller_shell && !QDELETED(controller_shell) ? "yes" : "no"]"
	if(controller_shell && !QDELETED(controller_shell))
		lines += "Shell key or client: [controller_shell.ckey ? controller_shell.ckey : "no ckey"] / [controller_shell.client ? "connected" : "no client"]"
		lines += "Shell location: [controller_shell.loc == src ? "inside jelly" : "[controller_shell.loc]"]"
		lines += "Shell source link: [controller_shell.source_jelly == src ? "correct" : "wrong"]"
	lines += "Doppel active: [active_doppelganger && !QDELETED(active_doppelganger) ? "yes" : "no"]"
	if(active_doppelganger && !QDELETED(active_doppelganger))
		lines += "Doppel controller link: [active_doppelganger.controller_shell == controller_shell ? "matches shell" : active_doppelganger.controller_shell ? "points elsewhere" : "none"]"
		lines += "Doppel client: [active_doppelganger.client ? "connected" : "no client"]"
	lines += "Permissions: speech=[controller_speech_enabled ? "on" : "off"], emote=[controller_emote_enabled ? "on" : "off"], manifest=[controller_manifest_enabled ? "on" : "off"], direct=[controller_direct_control_enabled ? "on" : "off"], force=[controller_force_enabled ? "on" : "off"]"
	lines += "Pending controller requests: [get_pending_controller_request_count()]"
	return lines

/obj/item/intimate_accessory/jelly/eora/strange/proc/repair_controller_binding()
	var/list/repair_notes = list()
	if(controller_shell && QDELETED(controller_shell))
		controller_shell = null
		repair_notes += "Cleared deleted controller shell reference."
	if(active_doppelganger && QDELETED(active_doppelganger))
		active_doppelganger = null
		repair_notes += "Cleared deleted doppelganger reference."
	if(controller_shell && !QDELETED(controller_shell))
		if(controller_shell.source_jelly != src)
			controller_shell.source_jelly = src
			repair_notes += "Reattached shell source link to this jelly."
		if(controller_shell.loc != src)
			controller_shell.forceMove(src)
			repair_notes += "Moved shell back inside the jelly."
	if(active_doppelganger && !QDELETED(active_doppelganger))
		if(active_doppelganger.source_jelly != src)
			active_doppelganger.source_jelly = src
			repair_notes += "Reattached doppel source link to this jelly."
		if(active_doppelganger.controller_shell && QDELETED(active_doppelganger.controller_shell))
			active_doppelganger.controller_shell = null
			repair_notes += "Cleared deleted controller-shell link from doppelganger."
	if(controller_ckey && (!controller_shell || QDELETED(controller_shell)) && (!active_doppelganger || QDELETED(active_doppelganger) || active_doppelganger.controller_shell != controller_shell))
		repair_notes += "Found stale controller identity without a usable shell; releasing stale binding."
		release_bound_controller("An admin repair pass found a broken jelly controller binding and released it.")
		return repair_notes
	if(!has_bound_controller())
		set_controller_state("unbound")
		repair_notes += "Controller state reset to unbound."
		return repair_notes
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == controller_shell && active_doppelganger.mind)
		set_controller_state(active_doppelganger.client && is_controller_wearer_available() ? "manifested" : "suspended")
		repair_notes += "Recomputed controller state from the active doppelganger."
	else if(controller_shell && !QDELETED(controller_shell) && controller_shell.mind)
		set_controller_state(controller_shell.client && is_controller_wearer_available() ? "shell_bound" : "suspended")
		repair_notes += "Recomputed controller state from the shell binding."
	else
		set_controller_state("suspended")
		repair_notes += "No active controller client was found; state left suspended."
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.refresh_controller_perspective()
		repair_notes += "Refreshed shell perspective."
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == controller_shell && active_doppelganger.client)
		active_doppelganger.reset_perspective(active_doppelganger)
		repair_notes += "Refreshed doppelganger perspective."
	return repair_notes

/obj/item/intimate_accessory/jelly/eora/strange/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("jelly_controller_audit", "Audit Jelly Controller")
	VV_DROPDOWN_OPTION("jelly_controller_repair", "Repair Jelly Controller")
	VV_DROPDOWN_OPTION("jelly_controller_force_release", "Force Release Jelly Controller")

/obj/item/intimate_accessory/jelly/eora/strange/vv_do_topic(list/href_list)
	if(!(. = ..()))
		return
	if(href_list["jelly_controller_audit"])
		if(!check_rights(R_ADMIN))
			return
		var/list/audit_lines = get_controller_audit_lines()
		to_chat(usr, span_notice("Jelly controller audit for [src]:"))
		for(var/line in audit_lines)
			to_chat(usr, span_notice("- [line]"))
		log_controller_admin_event("[key_name_admin(usr)] reviewed the controller audit for [src].")
		href_list["datumrefresh"] = "\ref[src]"
	if(href_list["jelly_controller_repair"])
		if(!check_rights(R_ADMIN))
			return
		if(alert(usr, "Attempt a jelly controller repair pass on [src]? This may move its shell, recompute state, or release a stale broken binding.", "Repair Jelly Controller", "Repair", "Cancel") != "Repair")
			return
		var/list/repair_notes = repair_controller_binding()
		if(!repair_notes.len)
			repair_notes += "No changes were needed."
		to_chat(usr, span_notice("Repair results for [src]:"))
		for(var/note in repair_notes)
			to_chat(usr, span_notice("- [note]"))
		log_controller_admin_event("[key_name_admin(usr)] ran a jelly controller repair pass on [src]: [jointext(repair_notes, "; ")].", TRUE)
		href_list["datumrefresh"] = "\ref[src]"
	if(href_list["jelly_controller_force_release"])
		if(!check_rights(R_ADMIN))
			return
		if(!has_bound_controller())
			to_chat(usr, span_warning("[src] has no bound controller to release."))
			return
		var/controller_name = get_bound_controller_name()
		if(!controller_name)
			controller_name = controller_ckey ? controller_ckey : "the bound controller"
		if(alert(usr, "Force-release [controller_name] from [src]?", "Force Release Jelly Controller", "Release", "Cancel") != "Release")
			return
		log_controller_admin_event("[key_name_admin(usr)] force-released [controller_name] from [src].", TRUE)
		release_bound_controller("An admin force-releases you from [src] to repair the binding.")
		href_list["datumrefresh"] = "\ref[src]"

/obj/item/intimate_accessory/jelly/eora/strange/proc/is_controller_viewer(mob/user)
	if(!user || !has_bound_controller())
		return FALSE
	if(user == controller_shell)
		return TRUE
	if(active_doppelganger && !QDELETED(active_doppelganger) && user == active_doppelganger && active_doppelganger.controller_shell == controller_shell)
		return TRUE
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_view_mode(mob/user)
	if(!is_controller_viewer(user))
		return null
	if(user == controller_shell)
		return "shell"
	if(active_doppelganger && !QDELETED(active_doppelganger) && user == active_doppelganger)
		return "doppel"
	return null

/obj/item/intimate_accessory/jelly/eora/strange/proc/is_controller_wearer_available()
	if(!wearer || QDELETED(wearer))
		return FALSE
	if(get_worn_in_slot(wearer) != src)
		return FALSE
	if(wearer.stat == DEAD)
		return FALSE
	if(!wearer.client)
		return FALSE
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_wearer_status_text()
	if(!wearer || QDELETED(wearer))
		return "No living host anchors me."
	if(get_worn_in_slot(wearer) != src)
		return "I have been cast from my host."
	if(wearer.stat == DEAD)
		return "The host is dead."
	if(!wearer.client)
		return "The host's soul has drifted away."
	return "The host endures, and the bond holds."

/obj/item/intimate_accessory/jelly/eora/strange/proc/register_controller_wearer_signals(mob/living/carbon/human/H)
	if(!H)
		return
	UnregisterSignal(H, list(COMSIG_MOB_LOGOUT, COMSIG_MOB_LOGIN, COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))
	RegisterSignal(H, COMSIG_MOB_LOGOUT, PROC_REF(on_controller_wearer_logout))
	RegisterSignal(H, COMSIG_MOB_LOGIN, PROC_REF(on_controller_wearer_login))
	RegisterSignal(H, COMSIG_MOB_DEATH, PROC_REF(on_controller_wearer_death))
	RegisterSignal(H, COMSIG_PARENT_QDELETING, PROC_REF(on_controller_wearer_qdel))

/obj/item/intimate_accessory/jelly/eora/strange/proc/unregister_controller_wearer_signals(mob/living/carbon/human/H)
	if(!H)
		return
	UnregisterSignal(H, list(COMSIG_MOB_LOGOUT, COMSIG_MOB_LOGIN, COMSIG_MOB_DEATH, COMSIG_PARENT_QDELETING))

/obj/item/intimate_accessory/jelly/eora/strange/proc/suspend_controller_for_wearer_interruption(context = "wearer unavailable")
	if(!has_bound_controller())
		return FALSE
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == controller_shell && active_doppelganger.mind)
		active_doppelganger.return_controller_to_body(FALSE)
	var/did_suspend = suspend_bound_controller(context)
	var/controller_mob = get_bound_controller_mob()
	if(controller_mob)
		to_chat(controller_mob, span_warning("The ooze shudders — the host is lost or shaken. I sink into stillness until the bond steadies."))
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.refresh_controller_perspective()
	return did_suspend

/obj/item/intimate_accessory/jelly/eora/strange/proc/resume_controller_after_wearer_return()
	if(!has_bound_controller())
		return FALSE
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.refresh_controller_perspective()
	if(!is_controller_wearer_available())
		set_controller_state("suspended")
		return FALSE
	if(get_controller_state() != "suspended")
		return FALSE
	if(!controller_shell || QDELETED(controller_shell) || !controller_shell.mind || !controller_shell.client)
		return FALSE
	set_controller_state("shell_bound")
	to_chat(controller_shell, span_notice("The ooze stirs — the host steadies, and the bond remembers me. I can act from within once more."))
	if(wearer && !QDELETED(wearer))
		var/controller_name = get_bound_controller_name()
		if(!controller_name)
			controller_name = controller_shell.real_name
		to_chat(wearer, span_notice("[controller_name] stirs back to wakefulness within [src] as the bond steadies."))
	log_controller_admin_event("[get_bound_controller_name()] resumed activity in [src] after wearer return.")
	add_controller_activity("system", "suspension", "[get_bound_controller_name()] resumed after wearer return")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/on_controller_wearer_logout(datum/source)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	suspend_controller_for_wearer_interruption("wearer disconnected")

/obj/item/intimate_accessory/jelly/eora/strange/proc/on_controller_wearer_login(datum/source)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	resume_controller_after_wearer_return()

/obj/item/intimate_accessory/jelly/eora/strange/proc/on_controller_wearer_death(datum/source, gibbed)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	if(!has_bound_controller())
		return
	log_controller_admin_event("[src] released its controller because wearer [key_name(wearer)] died.", TRUE)
	release_bound_controller("The death of [wearer.real_name] rends the ooze's shelter apart and casts you out.")

/obj/item/intimate_accessory/jelly/eora/strange/proc/on_controller_wearer_qdel(datum/source)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	if(!has_bound_controller())
		return
	log_controller_admin_event("[src] released its controller because the wearer was deleted or transformed away.", TRUE)
	release_bound_controller("The host that anchored the ooze is gone, and the bond crumbles around you.")

/obj/item/intimate_accessory/jelly/eora/strange/proc/handle_controller_shell_login(mob/living/jelly_controller_shell/shell)
	if(!shell || shell != controller_shell || !has_bound_controller())
		return FALSE
	if(!is_controller_wearer_available())
		set_controller_state("suspended")
		to_chat(shell, span_warning("I am still severed from my host. I remain dormant."))
		shell.refresh_controller_perspective()
		return TRUE
	var/previous_state = controller_state
	set_controller_state("shell_bound")
	if(previous_state == "suspended")
		var/controller_name = get_bound_controller_name()
		if(!controller_name)
			controller_name = shell.real_name
		to_chat(shell, span_notice("My awareness seeps back into my resting state."))
		if(wearer && !QDELETED(wearer))
			to_chat(wearer, span_notice("[controller_name] stirs back to awareness inside [src]."))
		log_controller_admin_event("[controller_name] reconnected to [src]'s hidden shell.")
		add_controller_activity("controller", "return", "[controller_name] reconnected to hidden shell")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/handle_controller_shell_logout(mob/living/jelly_controller_shell/shell)
	if(!shell || shell != controller_shell || !has_bound_controller())
		return FALSE
	if(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.controller_shell == shell && active_doppelganger.mind)
		set_controller_state(active_doppelganger.client ? "manifested" : "suspended")
		return TRUE
	return suspend_bound_controller("disconnect while shell-bound")

/obj/item/intimate_accessory/jelly/eora/strange/proc/handle_controller_doppel_login(mob/living/carbon/human/slime_doppelganger/doppel)
	if(!doppel || doppel != active_doppelganger || doppel.controller_shell != controller_shell || !has_bound_controller())
		return FALSE
	if(!is_controller_wearer_available())
		doppel.return_controller_to_body(FALSE)
		suspend_controller_for_wearer_interruption("wearer unavailable during doppel reconnect")
		return TRUE
	var/previous_state = controller_state
	set_controller_state("manifested")
	if(previous_state == "suspended")
		var/controller_name = get_bound_controller_name()
		if(!controller_name)
			controller_name = doppel.real_name
		to_chat(doppel, span_notice("I seize hold of my walking shape once more."))
		if(wearer && !QDELETED(wearer))
			to_chat(wearer, span_notice("[controller_name] stretches back into [src]'s slime-born shape."))
		log_controller_admin_event("[controller_name] reconnected to [src]'s slime double.")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/handle_controller_doppel_logout(mob/living/carbon/human/slime_doppelganger/doppel)
	if(!doppel || doppel != active_doppelganger || !has_bound_controller())
		return FALSE
	if(controller_shell && !QDELETED(controller_shell) && controller_shell.mind)
		set_controller_state(controller_shell.client ? "shell_bound" : "suspended")
		return TRUE
	return suspend_bound_controller("disconnect while manifested")

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_pending_controller_request_count()
	prune_expired_controller_requests()
	return controller_pending_requests ? controller_pending_requests.len : 0

/obj/item/intimate_accessory/jelly/eora/strange/proc/prune_expired_controller_requests()
	if(!islist(controller_pending_requests) || !controller_pending_requests.len)
		if(!islist(controller_pending_requests))
			controller_pending_requests = list()
		return FALSE
	var/did_prune = FALSE
	for(var/i = controller_pending_requests.len, i >= 1, i--)
		var/list/request = controller_pending_requests[i]
		if(!islist(request))
			controller_pending_requests.Cut(i, i + 1)
			did_prune = TRUE
			continue
		var/expires_at = text2num("[request["expires_at"]]")
		if(expires_at && world.time >= expires_at)
			controller_pending_requests.Cut(i, i + 1)
			did_prune = TRUE
	return did_prune

/obj/item/intimate_accessory/jelly/eora/strange/proc/clear_pending_controller_requests()
	if(!islist(controller_pending_requests))
		controller_pending_requests = list()
	if(!controller_pending_requests.len)
		return FALSE
	controller_pending_requests.Cut()
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_request_summary(list/request)
	if(!islist(request))
		return "do something through the jelly"
	var/request_type = "[request["type"]]"
	switch(request_type)
		if("stimulate")
			return "stimulate the wearer through the jelly"
		if("manifest")
			return "manifest into the slime double"
		if("reposition")
			var/target_slot = text2num("[request["target_slot"]]")
			if(target_slot)
				return "move the jelly to [lowertext(get_intimate_slot_display_name(target_slot))]"
			return "move the jelly to a different slot"
		if("force_speech")
			var/msg = "[request["message"]]"
			if(length(msg) > 30)
				msg = "[copytext(msg, 1, 28)]..."
			return "make the wearer say: \"[msg]\""
		if("force_emote")
			var/emote_label = "[request["emote_label"]]"
			return "make the wearer [lowertext(emote_label)]"
		if("force_posture")
			var/posture_label = "[request["posture_label"]]"
			return "force the wearer to [lowertext(posture_label)]"
	return "do something through the jelly"

/obj/item/intimate_accessory/jelly/eora/strange/proc/find_pending_controller_request(request_type, target_slot = null)
	prune_expired_controller_requests()
	if(!islist(controller_pending_requests) || !controller_pending_requests.len)
		return null
	for(var/list/request in controller_pending_requests)
		if(!islist(request))
			continue
		if("[request["type"]]" != request_type)
			continue
		if(!isnull(target_slot) && text2num("[request["target_slot"]]") != target_slot)
			continue
		return request
	return null

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_pending_controller_request(request_id)
	prune_expired_controller_requests()
	if(!islist(controller_pending_requests) || !controller_pending_requests.len)
		return null
	for(var/list/request in controller_pending_requests)
		if(!islist(request))
			continue
		if(text2num("[request["id"]]") == request_id)
			return request
	return null

/obj/item/intimate_accessory/jelly/eora/strange/proc/remove_pending_controller_request(request_id)
	if(!islist(controller_pending_requests) || !controller_pending_requests.len)
		return FALSE
	for(var/i = controller_pending_requests.len, i >= 1, i--)
		var/list/request = controller_pending_requests[i]
		if(!islist(request))
			continue
		if(text2num("[request["id"]]") != request_id)
			continue
		controller_pending_requests.Cut(i, i + 1)
		return TRUE
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_request_ui_data()
	prune_expired_controller_requests()
	var/list/ui_requests = list()
	if(!islist(controller_pending_requests) || !controller_pending_requests.len)
		return ui_requests
	for(var/list/request in controller_pending_requests)
		if(!islist(request))
			continue
		var/expires_at = text2num("[request["expires_at"]]")
		var/time_left = max(expires_at - world.time, 0)
		ui_requests += list(list(
			"id" = text2num("[request["id"]]"),
			"type" = "[request["type"]]",
			"summary" = get_controller_request_summary(request),
			"expires_in" = time_left ? DisplayTimeText(time_left) : "expired",
		))
	return ui_requests

/obj/item/intimate_accessory/jelly/eora/strange/proc/set_controller_direct_control(enabled, mob/living/carbon/human/H)
	if(!can_manage_bound_controller(H))
		return FALSE
	if(controller_direct_control_enabled == enabled)
		return FALSE
	controller_direct_control_enabled = enabled
	var/controller_mob = get_bound_controller_mob()
	if(enabled)
		to_chat(H, span_notice("I give [src] free rein to act without my consent."))
		if(controller_mob)
			to_chat(controller_mob, span_notice("[H.real_name] opens the way. I may now act without asking."))
		log_controller_admin_event("[key_name(H)] enabled direct controller action on [src].")
		add_controller_activity("wearer", "direct_control", "[H.real_name] enabled direct control", "important")
		return TRUE
	to_chat(H, span_notice("I tighten [src]'s ward — it must petition me before acting."))
	if(controller_mob)
		to_chat(controller_mob, span_notice("[H.real_name] seals the ward. I must petition before acting again."))
	log_controller_admin_event("[key_name(H)] disabled direct controller action on [src].")
	add_controller_activity("wearer", "direct_control", "[H.real_name] restored approval gate")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/can_controller_issue_shell_action(mob/living/jelly_controller_shell/shell, action_name = "act")
	if(!shell || shell != controller_shell)
		return FALSE
	if(get_controller_state() == "suspended")
		to_chat(shell, span_warning("My body lies dormant — the host is lost or shaken."))
		return FALSE
	if(!wearer || QDELETED(wearer) || get_worn_in_slot(wearer) != src || wearer.stat == DEAD)
		to_chat(shell, span_warning("I need a living host before I can [action_name]."))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/queue_controller_request(mob/living/jelly_controller_shell/shell, request_type, list/payload = null)
	if(!can_controller_issue_shell_action(shell, "make that request"))
		return FALSE
	prune_expired_controller_requests()
	if(!islist(controller_pending_requests))
		controller_pending_requests = list()
	if(controller_pending_requests.len >= controller_request_queue_limit)
		to_chat(shell, span_warning("I already seethe with unanswered petitions. I must wait."))
		return FALSE
	if(request_type == "reposition")
		if(find_pending_controller_request("reposition"))
			to_chat(shell, span_warning("A reposition request is already waiting on the wearer."))
			return FALSE
	else if(find_pending_controller_request(request_type))
		to_chat(shell, span_warning("A request like that is already waiting on the wearer."))
		return FALSE
	var/list/request = list(
		"id" = next_controller_request_id,
		"type" = request_type,
		"expires_at" = world.time + controller_request_expiration,
	)
	next_controller_request_id++
	if(islist(payload))
		for(var/key in payload)
			request[key] = payload[key]
	controller_pending_requests += list(request)
	var/summary = get_controller_request_summary(request)
	to_chat(shell, span_notice("I queue a jelly request to [summary]."))
	if(wearer && !QDELETED(wearer))
		to_chat(wearer, span_notice("[get_bound_controller_name()] asks to [summary]."))
	add_controller_activity("controller", "request", "Requested: [summary]")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/execute_controller_request(list/request, mob/living/jelly_controller_shell/shell, bypass_notice = FALSE)
	if(!islist(request))
		return FALSE
	var/request_type = "[request["type"]]"
	if(request_type == "manifest")
		if(bypass_notice && wearer && !QDELETED(wearer))
			to_chat(wearer, span_warning("[get_bound_controller_name()] acts without waiting and pushes toward manifestation."))
		return try_manifest_bound_controller_doppel(shell)
	if(!wearer || QDELETED(wearer))
		return FALSE
	if(request_type == "stimulate")
		if(bypass_notice)
			to_chat(wearer, span_warning("[get_bound_controller_name()] takes initiative and drives [src] into a direct pulse of stimulation."))
		return jelly_stimulate_wearer(wearer)
	if(request_type == "reposition")
		var/target_slot = text2num("[request["target_slot"]]")
		if(!target_slot)
			return FALSE
		if(bypass_notice)
			to_chat(wearer, span_warning("[get_bound_controller_name()] seizes the moment and moves [src] without waiting for approval."))
		return jelly_swap_to_slot(target_slot, wearer)
	if(request_type == "force_speech")
		var/message = "[request["message"]]"
		if(!length(message))
			return FALSE
		if(bypass_notice)
			to_chat(wearer, span_warning("[get_bound_controller_name()] seizes control and forces words out of my mouth."))
		wearer.say(message, forced = "jelly controller")
		add_controller_activity("controller", "force", "Forced speech: \"[message]\"")
		return TRUE
	if(request_type == "force_emote")
		var/emote_key = "[request["emote_key"]]"
		if(!length(emote_key))
			return FALSE
		if(bypass_notice)
			to_chat(wearer, span_warning("[get_bound_controller_name()] seizes control and forces a reaction from my body."))
		wearer.emote(emote_key, forced = TRUE)
		var/emote_label = "[request["emote_label"]]"
		add_controller_activity("controller", "force", "Forced emote: [emote_label]")
		return TRUE
	if(request_type == "force_posture")
		var/posture_key = "[request["posture_key"]]"
		if(!length(posture_key))
			return FALSE
		if(bypass_notice)
			to_chat(wearer, span_warning("[get_bound_controller_name()] seizes control and forces my body into a new posture."))
		var/posture_label = "[request["posture_label"]]"
		return execute_forced_posture(posture_key, posture_label)
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/respond_to_controller_request(request_id, accepted, mob/living/carbon/human/H)
	if(!can_manage_bound_controller(H))
		return FALSE
	var/list/request = get_pending_controller_request(request_id)
	if(!islist(request))
		to_chat(H, span_warning("That request is no longer pending."))
		return FALSE
	var/summary = get_controller_request_summary(request)
	var/controller_mob = get_bound_controller_mob()
	remove_pending_controller_request(request_id)
	if(!accepted)
		to_chat(H, span_notice("I deny the jelly's request to [summary]."))
		if(controller_mob)
			to_chat(controller_mob, span_notice("[H.real_name] denies my request to [summary]."))
		add_controller_activity("wearer", "request", "Denied: [summary]")
		return TRUE
	if(!controller_shell || QDELETED(controller_shell) || !controller_shell.mind)
		to_chat(H, span_warning("The controller can no longer follow through on that request."))
		if(controller_mob)
			to_chat(controller_mob, span_warning("The request to [summary] falls apart before it can resolve."))
		return FALSE
	var/succeeded = execute_controller_request(request, controller_shell, FALSE)
	if(!succeeded)
		to_chat(H, span_warning("The jelly can't carry out that request anymore."))
		if(controller_mob)
			to_chat(controller_mob, span_warning("[H.real_name] accepted my request, but the jelly can't carry it out anymore."))
		return FALSE
	to_chat(H, span_notice("I accept the jelly's request to [summary]."))
	if(controller_mob)
		to_chat(controller_mob, span_notice("[H.real_name] accepts my request to [summary]."))
	add_controller_activity("wearer", "request", "Accepted: [summary]")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_controller_stimulation(mob/living/jelly_controller_shell/shell)
	if(!can_controller_issue_shell_action(shell, "stimulate the wearer"))
		return FALSE
	if(!has_bound_controller() && need_level < need_force_unlock_threshold)
		to_chat(shell, span_warning("I am too content right now to allow that kind of stimulation."))
		return FALSE
	if(controller_direct_control_enabled)
		return execute_controller_request(list("type" = "stimulate"), shell, TRUE)
	return queue_controller_request(shell, "stimulate")

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_controller_reposition(mob/living/jelly_controller_shell/shell, target_slot)
	if(!can_controller_issue_shell_action(shell, "move the jelly"))
		return FALSE
	if(isnull(target_slot) || !supports_intimate_slot(target_slot))
		to_chat(shell, span_warning("I cannot shift there."))
		return FALSE
	if(get_effective_intimate_slot() == target_slot)
		to_chat(shell, span_notice("I already cling there."))
		return FALSE
	var/list/request = list(
		"type" = "reposition",
		"target_slot" = target_slot,
	)
	if(controller_direct_control_enabled)
		return execute_controller_request(request, shell, TRUE)
	return queue_controller_request(shell, "reposition", request)

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_or_manifest_bound_controller_doppel(mob/living/jelly_controller_shell/shell)
	if(!can_controller_issue_shell_action(shell, "manifest"))
		return FALSE
	if(!controller_manifest_enabled)
		to_chat(shell, span_warning("The host has sealed me against manifestation."))
		return FALSE
	if(controller_direct_control_enabled)
		return execute_controller_request(list("type" = "manifest"), shell, TRUE)
	return queue_controller_request(shell, "manifest")

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_force_emote_options()
	return list(
		"Moan" = "sexmoanhvy",
		"Gasp" = "gasp",
		"Whimper" = "whimper",
		"Blush" = "blush",
		"Shiver" = "shiver",
	)

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_controller_force_speech(mob/living/jelly_controller_shell/shell, message)
	if(!can_controller_issue_shell_action(shell, "force the wearer to speak"))
		return FALSE
	if(!controller_force_enabled)
		to_chat(shell, span_warning("The host has not yielded to my will."))
		return FALSE
	if(!has_bound_controller() && need_level < need_force_unlock_threshold)
		to_chat(shell, span_warning("I am too sated to force words from my host."))
		return FALSE
	if(last_controller_force_action && world.time < last_controller_force_action + controller_force_action_interval)
		var/remaining = round((last_controller_force_action + controller_force_action_interval - world.time) / 10)
		to_chat(shell, span_warning("My grip on the host's will is still settling — [remaining] second\s."))
		return FALSE
	if(!length(message))
		to_chat(shell, span_warning("There's nothing to say."))
		return FALSE
	message = copytext(message, 1, 101)
	last_controller_force_action = world.time
	var/list/request = list(
		"type" = "force_speech",
		"message" = message,
	)
	if(controller_direct_control_enabled)
		return execute_controller_request(request, shell, TRUE)
	return queue_controller_request(shell, "force_speech", request)

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_controller_force_emote(mob/living/jelly_controller_shell/shell, emote_label)
	if(!can_controller_issue_shell_action(shell, "force the wearer to emote"))
		return FALSE
	if(!controller_force_enabled)
		to_chat(shell, span_warning("The host has not yielded to my will."))
		return FALSE
	if(!has_bound_controller() && need_level < need_force_unlock_threshold)
		to_chat(shell, span_warning("I am too sated to wring a reaction from my host."))
		return FALSE
	if(last_controller_force_action && world.time < last_controller_force_action + controller_force_action_interval)
		var/remaining = round((last_controller_force_action + controller_force_action_interval - world.time) / 10)
		to_chat(shell, span_warning("My grip on the host's will is still settling — [remaining] second\s."))
		return FALSE
	var/list/emote_options = get_controller_force_emote_options()
	var/emote_key = emote_options[emote_label]
	if(!emote_key)
		to_chat(shell, span_warning("That emote is not available."))
		return FALSE
	last_controller_force_action = world.time
	var/list/request = list(
		"type" = "force_emote",
		"emote_key" = emote_key,
		"emote_label" = emote_label,
	)
	if(controller_direct_control_enabled)
		return execute_controller_request(request, shell, TRUE)
	return queue_controller_request(shell, "force_emote", request)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_force_posture_options()
	return list(
		"Kneel" = list("key" = "kneel", "emote_text" = "drops to their knees under the ooze's insistent grip.", "mechanic" = "immobilize", "duration" = 3 SECONDS),
		"Tremble" = list("key" = "tremble", "emote_text" = "trembles uncontrollably as the ooze pulses through them.", "mechanic" = "jitter", "duration" = 0),
		"Bow" = list("key" = "bow", "emote_text" = "bows submissively, guided by the ooze's creeping pressure.", "mechanic" = "immobilize", "duration" = 2 SECONDS),
		"Cower" = list("key" = "cower", "emote_text" = "cowers and shrinks down as the ooze tightens around them.", "mechanic" = "knockdown", "duration" = 2 SECONDS),
		"Collapse" = list("key" = "collapse", "emote_text" = "collapses to the ground, overwhelmed by the ooze's hold.", "mechanic" = "knockdown", "duration" = 4 SECONDS),
	)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_force_posture_labels()
	var/list/options = get_controller_force_posture_options()
	var/list/labels = list()
	for(var/label in options)
		labels += label
	return labels

/obj/item/intimate_accessory/jelly/eora/strange/proc/execute_forced_posture(posture_key, posture_label)
	if(!wearer || QDELETED(wearer) || wearer.stat == DEAD)
		return FALSE
	var/list/options = get_controller_force_posture_options()
	var/list/posture = null
	for(var/label in options)
		var/list/entry = options[label]
		if(entry["key"] == posture_key)
			posture = entry
			break
	if(!posture)
		return FALSE
	var/emote_text = posture["emote_text"]
	var/mechanic = posture["mechanic"]
	var/duration = text2num("[posture["duration"]]")
	wearer.visible_message(span_warning("[wearer] [emote_text]") + " " + span_jellycontrolled("(Inhabited)"), span_warning("[wearer] [emote_text]"))
	switch(mechanic)
		if("immobilize")
			wearer.Immobilize(duration)
		if("knockdown")
			wearer.Knockdown(duration)
		if("jitter")
			wearer.do_jitter_animation(200)
	add_controller_activity("controller", "force", "Forced posture: [posture_label]")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_controller_force_posture(mob/living/jelly_controller_shell/shell, posture_label)
	if(!can_controller_issue_shell_action(shell, "force the wearer into a posture"))
		return FALSE
	if(!controller_force_enabled)
		to_chat(shell, span_warning("The host has not yielded to my will."))
		return FALSE
	if(!has_bound_controller() && need_level < need_force_unlock_threshold)
		to_chat(shell, span_warning("I am too sated to command the host's body."))
		return FALSE
	if(last_controller_force_action && world.time < last_controller_force_action + controller_force_action_interval)
		var/remaining = round((last_controller_force_action + controller_force_action_interval - world.time) / 10)
		to_chat(shell, span_warning("My grip on the host's will is still settling — [remaining] second\s."))
		return FALSE
	var/list/options = get_controller_force_posture_options()
	var/list/posture = options[posture_label]
	if(!islist(posture))
		to_chat(shell, span_warning("That posture is not available."))
		return FALSE
	last_controller_force_action = world.time
	var/list/request = list(
		"type" = "force_posture",
		"posture_key" = posture["key"],
		"posture_label" = posture_label,
	)
	if(controller_direct_control_enabled)
		return execute_controller_request(request, shell, TRUE)
	return queue_controller_request(shell, "force_posture", request)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_wearer_voice_presets()
	return list(
		list("label" = "Beg for Attention", "type" = "speech", "content" = "Please... pay attention to me..."),
		list("label" = "Admit Desire", "type" = "speech", "content" = "I want it... so badly..."),
		list("label" = "Plead Helplessly", "type" = "speech", "content" = "I can't resist... please..."),
	)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_wearer_voice_preset_labels()
	var/list/labels = list()
	for(var/list/preset in get_controller_wearer_voice_presets())
		labels += preset["label"]
	return labels

/obj/item/intimate_accessory/jelly/eora/strange/proc/request_controller_wearer_voice_preset(mob/living/jelly_controller_shell/shell, preset_label)
	var/list/presets = get_controller_wearer_voice_presets()
	for(var/list/preset in presets)
		if(preset["label"] == preset_label)
			if(preset["type"] == "speech")
				return request_controller_force_speech(shell, preset["content"])
			if(preset["type"] == "emote")
				return request_controller_force_emote(shell, preset["content"])
	to_chat(shell, span_warning("That wearer-voice preset is not available."))
	return FALSE

/**
 * Checks whether the controller can issue cocoon commands (tighten/release/tendril).
 * Requires: controller is bound, cocoon is active, wearer is alive.
 * Works from both the shell mob and the doppelganger mob.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/can_controller_cocoon_command(mob/user)
	if(!user)
		return FALSE
	if(!has_bound_controller())
		return FALSE
	if(!is_controller_viewer(user))
		return FALSE
	if(!cocooned || !active_cocoon || QDELETED(active_cocoon))
		return FALSE
	if(!wearer || QDELETED(wearer) || wearer.stat == DEAD)
		return FALSE
	return TRUE

/**
 * Checks whether the controller can initiate a cocoon from the shell.
 * Requires: controller is bound, wearer is alive, not already cocooned.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/can_controller_start_cocoon(mob/user)
	if(!user)
		return FALSE
	if(!has_bound_controller())
		return FALSE
	if(!is_controller_viewer(user))
		return FALSE
	if(cocooned || (active_cocoon && !QDELETED(active_cocoon)))
		return FALSE
	if(!wearer || QDELETED(wearer) || wearer.stat == DEAD)
		return FALSE
	if(!matches_bonded_wearer(wearer))
		return FALSE
	return TRUE

/**
 * Controller initiates cocooning the wearer from the shell.
 * Same effect as the jelly auto-cocooning, but triggered by the controller.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/controller_start_cocoon(mob/user)
	if(!can_controller_start_cocoon(user))
		return FALSE
	to_chat(user, span_notice("I will the ooze to wrap around and seal its host."))
	add_controller_activity("controller", "cocoon", "Initiated cocoon on [wearer.real_name]")
	return apply_cocoon_to_wearer(wearer)

/**
 * Controller cocoon command: Tighten — advance the cocoon to the next stage.
 * Only works if the cocoon hasn't reached SUBSUMING yet.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/controller_cocoon_tighten(mob/user)
	if(!can_controller_cocoon_command(user))
		return FALSE
	if(!has_bound_controller() && jealousy_level < jealousy_cocoon_aggression_threshold)
		to_chat(user, span_warning("The ooze is not possessive enough to tighten its grip."))
		return FALSE
	if(active_cocoon.cocoon_stage >= COCOON_STAGE_OVERWHELMING)
		to_chat(user, span_warning("The cocoon is already at its deepest stage."))
		return FALSE
	var/new_stage = active_cocoon.cocoon_stage + 1
	active_cocoon.cocoon_stage = new_stage
	active_cocoon.breakout_time = get_cocoon_stage_breakout(new_stage)
	active_cocoon.update_stage_appearance()
	var/transition_flavor = get_cocoon_escalation_flavor("stage_enter", new_stage, wearer)
	if(transition_flavor)
		active_cocoon.visible_message(span_love(transition_flavor) + " " + span_jellycontrolled("(Inhabited)"))
		playsound(active_cocoon, 'sound/misc/mat/pop.ogg', 45, TRUE)
	var/static/list/stage_names = list("enveloping", "settling", "gripping", "overwhelming")
	var/stage_name = (new_stage >= 0 && new_stage < length(stage_names)) ? stage_names[new_stage + 1] : "unknown"
	add_mood_log("cocoon", "Controller tightened cocoon to [stage_name]")
	add_controller_activity("controller", "cocoon", "Tightened cocoon to [stage_name]")
	to_chat(user, span_notice("I will the cocoon to tighten — it advances to [stage_name]."))
	return TRUE

/**
 * Controller cocoon command: Release — eject the wearer from the cocoon.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/controller_cocoon_release(mob/user)
	if(!can_controller_cocoon_command(user))
		return FALSE
	to_chat(user, span_notice("I command the cocoon to loosen and release its hold."))
	var/wearer_name = wearer.real_name
	remove_cocoon_from_wearer(wearer)
	add_controller_activity("controller", "cocoon", "Released [wearer_name] from cocoon")
	return TRUE

/**
 * Controller cocoon command: Tendril Pulse — manually trigger tendril feeding.
 * Bypasses the normal cooldown timer but enforces its own 30s cooldown.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/controller_cocoon_tendril_pulse(mob/user)
	if(!can_controller_cocoon_command(user))
		return FALSE
	if(!has_bound_controller() && jealousy_level < jealousy_cocoon_aggression_threshold)
		to_chat(user, span_warning("The ooze is not possessive enough to command its tendrils."))
		return FALSE
	if(!wearer || !has_bonded_wearer())
		return FALSE
	// Use a 30-second cooldown for manual controller pulses (shorter than auto 60s).
	var/controller_pulse_cooldown = 30 SECONDS
	if(last_cocoon_feeding && world.time < last_cocoon_feeding + controller_pulse_cooldown)
		to_chat(user, span_warning("The tendrils are still recovering from their last pulse."))
		return FALSE
	last_cocoon_feeding = world.time
	var/static/list/tendril_actions = list("anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi")
	var/action_key = pick(tendril_actions)
	var/tendril_flavor = get_tendril_action_flavor(action_key, wearer, wearer?.sexcon)
	if(tendril_flavor && active_cocoon)
		active_cocoon.visible_message(span_love(tendril_flavor) + " " + span_jellycontrolled("(Inhabited)"))
	on_jelly_fed(wearer, JELLY_FEED_SOURCE_COCOON)
	add_controller_activity("controller", "cocoon", "Triggered tendril pulse")
	to_chat(user, span_notice("I command the tendrils to surge through the cocoon's interior."))
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/reset_controller_permissions()
	controller_speech_enabled = TRUE
	controller_emote_enabled = TRUE
	controller_manifest_enabled = TRUE
	controller_direct_control_enabled = FALSE
	controller_force_enabled = FALSE
	clear_pending_controller_requests()

/obj/item/intimate_accessory/jelly/eora/strange/proc/can_manage_bound_controller(mob/living/carbon/human/H)
	if(!H)
		return FALSE
	if(H != wearer)
		return FALSE
	if(!matches_bonded_wearer(H))
		return FALSE
	if(!has_bound_controller())
		return FALSE
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/set_controller_permission(permission_key, enabled, mob/living/carbon/human/H)
	if(!can_manage_bound_controller(H))
		return FALSE

	var/permission_name = null
	var/setting_word = "disabled"
	var/did_change = FALSE
	if(enabled)
		setting_word = "enabled"

	if(permission_key == "speech")
		permission_name = "speech"
		if(controller_speech_enabled != enabled)
			controller_speech_enabled = enabled
			did_change = TRUE
	else if(permission_key == "emote")
		permission_name = "emotes"
		if(controller_emote_enabled != enabled)
			controller_emote_enabled = enabled
			did_change = TRUE
	else if(permission_key == "manifest")
		permission_name = "manifest"
		if(controller_manifest_enabled != enabled)
			controller_manifest_enabled = enabled
			did_change = TRUE
	else if(permission_key == "force")
		permission_name = "forced output"
		if(controller_force_enabled != enabled)
			controller_force_enabled = enabled
			did_change = TRUE

	if(!did_change)
		return FALSE
	if(!permission_name)
		return FALSE

	var/controller_mob = get_bound_controller_mob()
	var/controller_log_name = get_bound_controller_name()
	var/wearer_message = "I disabled controller permissions for [src]."
	var/controller_message = "[H.real_name] has disabled jelly permissions for me."
	if(!controller_log_name)
		controller_log_name = "unknown controller"
	if(permission_name == "speech")
		wearer_message = "I [setting_word] controller speech for [src]."
		controller_message = "[H.real_name] has [setting_word] jelly speech for me."
	else if(permission_name == "emotes")
		wearer_message = "I [setting_word] controller emotes for [src]."
		controller_message = "[H.real_name] has [setting_word] jelly emotes for me."
	else if(permission_name == "manifest")
		wearer_message = "I [setting_word] controller manifestation for [src]."
		controller_message = "[H.real_name] has [setting_word] jelly manifestation for me."
	else if(permission_name == "forced output")
		wearer_message = "I [setting_word] forced speech and emotes for [src]."
		controller_message = "[H.real_name] has [setting_word] forced speech and emotes for me."

	to_chat(H, span_notice(wearer_message))
	if(controller_mob)
		to_chat(controller_mob, span_notice(controller_message))
	log_controller_admin_event("[key_name(H)] [setting_word] [permission_name] for [controller_log_name] on [src].")
	add_controller_activity("wearer", "permission", "[H.real_name] [setting_word] [permission_name]")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/dismiss_bound_controller(mob/living/carbon/human/H)
	if(!can_manage_bound_controller(H))
		return FALSE

	var/controller_name = get_bound_controller_name()
	if(!controller_name)
		controller_name = "the bound controller"
	if(alert(H, "Cast out [controller_name] from [src]? They will be wrenched from the ooze at once.", "Banish Inhabitant", "Banish", "Cancel") != "Banish")
		return FALSE

	log_controller_admin_event("[key_name(H)] dismissed [controller_name] from [src].", TRUE)
	add_controller_activity("wearer", "dismissal", "[H.real_name] dismissed [controller_name]", "important")
	to_chat(H, span_notice("I cast [controller_name] out of [src]."))
	release_bound_controller("[H.real_name] banishes you from [src].")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/can_accept_controller_applications(mob/living/carbon/human/H = null)
	if(H)
		if(H != wearer)
			return FALSE
		if(!matches_bonded_wearer(H))
			return FALSE
	if(has_bound_controller())
		return FALSE
	if(!has_bonded_wearer())
		return FALSE
	if(!wearer || QDELETED(wearer))
		return FALSE
	if(!matches_bonded_wearer(wearer))
		return FALSE
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/is_accepting_controller_applications()
	if(!controller_applications_open)
		return FALSE
	return can_accept_controller_applications()

/obj/item/intimate_accessory/jelly/eora/strange/proc/sync_controller_application_listing()
	if(is_accepting_controller_applications())
		GLOB.open_jelly_controller_applications |= src
		return TRUE
	GLOB.open_jelly_controller_applications -= src
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/remove_controller_application(client/candidate_client, notify_message = null)
	if(!candidate_client || !candidate_client.ckey)
		return FALSE
	if(!pending_controller_applications || !pending_controller_applications[candidate_client.ckey])
		if(GLOB.jelly_controller_application_targets[candidate_client.ckey] == src)
			GLOB.jelly_controller_application_targets -= candidate_client.ckey
		return FALSE

	pending_controller_applications -= candidate_client.ckey
	if(GLOB.jelly_controller_application_targets[candidate_client.ckey] == src)
		GLOB.jelly_controller_application_targets -= candidate_client.ckey
	if(notify_message && candidate_client.mob)
		to_chat(candidate_client.mob, span_notice(notify_message))
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/clear_controller_applications(notify_applicants = FALSE)
	if(!pending_controller_applications || !pending_controller_applications.len)
		return FALSE

	var/list/application_keys = pending_controller_applications.Copy()
	for(var/ckey in application_keys)
		var/list/entry = application_keys[ckey]
		var/client/candidate_client = entry["client"]
		if(notify_applicants)
			remove_controller_application(candidate_client, "[src] no longer calls for a spirit.")
		else
			remove_controller_application(candidate_client)
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/prune_controller_applications()
	if(!pending_controller_applications || !pending_controller_applications.len)
		return FALSE

	var/list/invalid_keys = list()
	var/list/invalid_clients = list()
	for(var/ckey in pending_controller_applications)
		var/list/entry = pending_controller_applications[ckey]
		var/client/candidate_client = entry["client"]
		var/datum/jelly_prefs/pref = entry["pref"]
		var/mob/candidate_mob = candidate_client ? candidate_client.mob : null
		if(!candidate_client)
			invalid_keys += ckey
			continue
		if(!candidate_client.prefs?.jelly_controller_enabled)
			invalid_clients += candidate_client
			continue
		if(pref != candidate_client.prefs?.jelly_prefs)
			invalid_clients += candidate_client
			continue
		if(!pref?.is_profile_ready() || !is_valid_jelly_controller_candidate(candidate_mob))
			invalid_clients += candidate_client

	for(var/ckey in invalid_keys)
		pending_controller_applications -= ckey
		if(GLOB.jelly_controller_application_targets[ckey] == src)
			GLOB.jelly_controller_application_targets -= ckey
	for(var/client/candidate_client in invalid_clients)
		remove_controller_application(candidate_client, "Your petition to the ooze is no longer valid.")
	return !!(invalid_clients.len || invalid_keys.len)

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_pending_controller_application_count()
	prune_controller_applications()
	if(!pending_controller_applications)
		return 0
	return pending_controller_applications.len

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_controller_application_target_label()
	var/jelly_name = custom_jelly_name ? custom_jelly_name : name
	var/wearer_name = bonded_name
	if(!wearer_name && wearer && !QDELETED(wearer))
		wearer_name = wearer.real_name
	if(!wearer_name)
		wearer_name = "Unknown wearer"
	var/slot_name = lowertext(get_intimate_slot_display_name())
	return "[wearer_name]'s [jelly_name] ([slot_name])"

/obj/item/intimate_accessory/jelly/eora/strange/proc/set_controller_applications_open(open_state, mob/living/carbon/human/H)
	if(!can_accept_controller_applications(H))
		return FALSE

	open_state = !!open_state
	if(controller_applications_open == open_state)
		sync_controller_application_listing()
		return FALSE

	controller_applications_open = open_state
	sync_controller_application_listing()
	if(open_state)
		to_chat(H, span_notice("I open [src] to those who would answer the ooze's call."))
		log_controller_admin_event("[key_name(H)] opened controller applications for [src].")
	else
		to_chat(H, span_notice("I seal [src] against new petitioners."))
		log_controller_admin_event("[key_name(H)] closed controller applications for [src].")
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/submit_controller_application(client/candidate_client)
	if(!candidate_client || !candidate_client.ckey)
		return FALSE
	var/cooldown_time = GLOB.jelly_controller_application_cooldowns[candidate_client.ckey]
	if(cooldown_time && world.time < cooldown_time)
		if(candidate_client.mob)
			to_chat(candidate_client.mob, span_warning("I must wait before petitioning the ooze again."))
		return FALSE
	if(!is_accepting_controller_applications())
		if(candidate_client.mob)
			to_chat(candidate_client.mob, span_warning("[src] is not calling for a spirit right now."))
		return FALSE
	if(wearer && candidate_client.ckey == wearer.ckey)
		if(candidate_client.mob)
			to_chat(candidate_client.mob, span_warning("I cannot petition my own ooze."))
		return FALSE

	var/datum/jelly_prefs/pref = candidate_client.prefs?.jelly_prefs
	var/mob/candidate_mob = candidate_client.mob
	if(!pref?.is_profile_ready() || !is_valid_jelly_controller_candidate(candidate_mob))
		if(candidate_client.mob)
			to_chat(candidate_client.mob, span_warning("My vessel is not yet prepared to answer the call."))
		return FALSE

	var/obj/item/intimate_accessory/jelly/eora/strange/current_target = get_jelly_controller_application_target(candidate_client)
	if(current_target == src)
		if(candidate_client.mob)
			to_chat(candidate_client.mob, span_notice("My petition to [src] already awaits an answer."))
		return FALSE
	if(current_target)
		current_target.remove_controller_application(candidate_client, "I withdraw my previous petition to the ooze.")

	pending_controller_applications[candidate_client.ckey] = list(
		"client" = candidate_client,
		"pref" = pref,
		"time" = world.time,
		"state" = get_jelly_candidate_state(candidate_mob),
	)
	GLOB.jelly_controller_application_targets[candidate_client.ckey] = src
	if(candidate_client.mob)
		to_chat(candidate_client.mob, span_notice("I offer myself to [get_controller_application_target_label()]."))
	if(wearer && !QDELETED(wearer))
		to_chat(wearer, span_notice("[pref.jelly_name] offers itself to [src]."))
	log_controller_admin_event("[candidate_client.ckey] applied to [src].")
	add_controller_activity("controller", "invitation", "[pref.jelly_name] applied")
	GLOB.jelly_controller_application_cooldowns[candidate_client.ckey] = world.time + 10 SECONDS
	return TRUE

/obj/item/intimate_accessory/jelly/eora/strange/proc/withdraw_controller_application(client/candidate_client)
	if(!candidate_client || !candidate_client.ckey)
		return FALSE
	var/cooldown_time = GLOB.jelly_controller_application_cooldowns[candidate_client.ckey]
	if(cooldown_time && world.time < cooldown_time)
		if(candidate_client.mob)
			to_chat(candidate_client.mob, span_warning("I must wait before petitioning the ooze again."))
		return FALSE
	if(!remove_controller_application(candidate_client))
		return FALSE
	if(candidate_client.mob)
		to_chat(candidate_client.mob, span_notice("I withdraw my petition to [get_controller_application_target_label()]."))
	if(wearer && !QDELETED(wearer))
		to_chat(wearer, span_notice("A petitioner withdraws from [src]."))
	log_controller_admin_event("[candidate_client.ckey] withdrew their application to [src].")
	GLOB.jelly_controller_application_cooldowns[candidate_client.ckey] = world.time + 10 SECONDS
	return TRUE

/proc/get_jelly_controller_application_target(client/candidate_client)
	if(!candidate_client || !candidate_client.ckey)
		return null

	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = GLOB.jelly_controller_application_targets[candidate_client.ckey]
	if(!jelly || QDELETED(jelly))
		GLOB.jelly_controller_application_targets -= candidate_client.ckey
		return null
	if(!jelly.pending_controller_applications || !jelly.pending_controller_applications[candidate_client.ckey])
		GLOB.jelly_controller_application_targets -= candidate_client.ckey
		return null
	return jelly

/proc/remove_jelly_controller_client_from_applications(client/candidate_client, notify_message = null)
	if(!candidate_client || !candidate_client.ckey)
		return FALSE

	var/obj/item/intimate_accessory/jelly/eora/strange/jelly = get_jelly_controller_application_target(candidate_client)
	if(jelly)
		return jelly.remove_controller_application(candidate_client, notify_message)
	GLOB.jelly_controller_application_targets -= candidate_client.ckey
	return FALSE

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
 * This ensures bond grows through intimacy, not just jealousy/resentment/need pressure.
 */
/obj/item/intimate_accessory/jelly/eora/strange/advance_bond_from_sex(amount = 1)
	if(bond_escalation_level >= max_bond_escalation_level)
		return FALSE
	bond_progress += amount
	if(bond_progress >= bond_progress_threshold)
		bond_progress = 0
		bond_escalation_level = min(bond_escalation_level + 1, max_bond_escalation_level)
		add_mood_log("bond", "Bond deepened to level [bond_escalation_level]")
		if(wearer)
			to_chat(wearer, span_love("[src] pulses warmly — I can feel its bond deepening."))
			update_visual_accessory_type()
			refresh_item_icon_state()
		return TRUE
	return FALSE

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_jealousy_state()
	if(jealousy_level <= 0)
		return "content"
	if(jealousy_level <= 2)
		return "uneasy"
	if(jealousy_level <= 4)
		return "possessive"
	return "seething"

/obj/item/intimate_accessory/jelly/eora/strange/proc/get_resentment_state()
	if(resentment_level <= 0)
		return "placid"
	if(resentment_level <= 2)
		return "irritated"
	if(resentment_level <= 4)
		return "spiteful"
	return "vindictive"


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
	// Player-controlled jelly: derived tension values are frozen alongside needs.
	if(has_bound_controller())
		return FALSE

	// Obsession is driven by need, jealousy, and resentment combined.
	var/new_obsession_level = clamp(1 + round(need_level / 2) + round(jealousy_level / 2) + round(resentment_level / 2), 1, max_obsession_level)
	var/did_change = FALSE

	if(obsession_level != new_obsession_level)
		obsession_level = new_obsession_level
		did_change = TRUE

	// Bond is a HIGH-WATER MARK — it can only be pushed UP by emotional
	// pressure, never pulled down. Soothing/satisfying the jelly does not
	// reduce bond. Bond represents accumulated affection & attachment.
	// The pressure formula can temporarily elevate bond above the permanent
	// floor set by advance_bond_from_sex(), but it can never lower it.
	var/pressure_bond = clamp(round((need_level + jealousy_level + resentment_level) / 3) - 1, 0, max_bond_escalation_level)
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
	// Player-controlled jelly: needs are frozen — the player IS the jelly.
	if(has_bound_controller())
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

	// Resentment decays slowly while worn and sated (need == 0).
	if(wearer && matches_bonded_wearer(wearer) && need_level <= 0 && resentment_level > 0)
		if(!last_resentment_decay || world.time >= last_resentment_decay + resentment_decay_interval)
			last_resentment_decay = world.time
			var/new_resentment = clamp(resentment_level - 1, 0, max_resentment_level)
			if(new_resentment != resentment_level)
				resentment_level = new_resentment
				did_change = TRUE

	if(refresh_need_tension())
		did_change = TRUE

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/soothe_needs(amount = need_soothe_amount, reduce_jealousy = TRUE)
	if(has_bound_controller())
		return FALSE
	var/new_need_level = clamp(need_level - amount, 0, max_need_level)
	var/did_change = FALSE

	if(new_need_level != need_level)
		need_level = new_need_level
		did_change = TRUE

	if(reduce_jealousy && !need_level && jealousy_level > 0)
		var/new_jealousy = clamp(jealousy_level - 1, 0, max_jealousy_level)
		if(new_jealousy != jealousy_level)
			jealousy_level = new_jealousy
			did_change = TRUE

	// The jelly interprets being constantly calmed as suppression — builds mild resentment.
	// Only triggers at bond level 2+ so new jellies don't punish basic caretaking.
	if(bond_escalation_level >= 2 && need_level <= 0 && jealousy_level <= 0)
		add_resentment(1)

	if(refresh_need_tension())
		did_change = TRUE

	return did_change

/obj/item/intimate_accessory/jelly/eora/strange/proc/try_soothe_needs(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(has_bound_controller())
		return FALSE
	if(last_need_soothe && world.time < last_need_soothe + need_soothe_interval)
		return FALSE

	// ── Resentment soothe refusal (resentment >= refusal threshold) ──
	// The jelly is too angry to accept comfort. 50% chance of outright rejection.
	// This makes high resentment dangerous — the wearer loses their primary calming tool
	// and must rely on feeding or waiting for resentment to decay.
	if(resentment_level >= resentment_refusal_threshold && prob(50))
		last_need_soothe = world.time
		var/refusal_flavor = get_resentment_flavor("resentment_refusal")
		if(refusal_flavor)
			to_chat(H, span_userdanger(refusal_flavor))
		else
			to_chat(H, span_userdanger("[src] recoils from my touch — cold and utterly unforgiving."))
		return FALSE

	last_need_soothe = world.time
	var/did_change = soothe_needs()
	if(ensure_bonded_wearer_lovefiend(H, TRUE))
		did_change = TRUE
	return did_change

/**
 * Allows an observer (non-bonded player) to partially ease the jelly's needs.
 * Applies half-strength soothe_needs with reduce_jealousy = FALSE — only the bonded
 * wearer earns jealousy reduction. However, another person touching the jelly triggers
 * a small jealousy spike — the jelly doesn't like strangers. Tracked by last_tended / tend_interval.
 * Emits a shared visible message to both the comforter and the bonded wearer.
 * Returns TRUE when comfort was applied.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_comfort_jelly(mob/living/carbon/human/comforter)
	if(!comforter)
		return FALSE
	if(!has_bonded_wearer())
		return FALSE
	if(has_bound_controller())
		return FALSE
	if(last_tended && world.time < last_tended + tend_interval)
		to_chat(comforter, span_notice("[src] seems content for now — give it a moment before tending again."))
		return FALSE
	last_tended = world.time
	soothe_needs(need_soothe_amount * 0.5, FALSE)
	// Someone other than the bonded wearer is touching the jelly — mild jealousy trigger.
	add_jealousy(1)
	to_chat(comforter, span_notice("I gently tend to [src], easing its restlessness a little."))
	if(bonded_wearer && !QDELETED(bonded_wearer))
		to_chat(bonded_wearer, span_notice("Someone nearby tends to [src], and it calms slightly at their touch — though I sense a flicker of possessive unease."))
	comforter.visible_message(span_notice("[comforter] reaches out and gently tends to [src]."))
	return TRUE

/**
 * Strange jelly override — calls the base stimulate, then reduces need slightly
 * as reward for engaging with the jelly. The jelly enjoys stimulating its wearer.
 */
/obj/item/intimate_accessory/jelly/eora/strange/jelly_stimulate_wearer(mob/living/carbon/human/H)
	. = ..()
	if(!.)
		return FALSE
	// The jelly relishes being commanded to stimulate — slight need reduction.
	if(need_level > 0)
		soothe_needs(1, FALSE)
		add_mood_log("stimulate", "Stimulated wearer — need soothed by 1")
	return TRUE

// ── Player command procs ────────────────────────────────────────────────────

/**
 * Resolves a command flavor string from jelly_command_messages.json.
 * Replaces [JELLY] and [TARGET]/[THEIR] tokens.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_command_flavor(bank_key, mob/living/carbon/human/H)
	var/list/bank = strings("jelly_command_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	var/template = pick(bank)
	if(!template)
		return null
	template = replacetext(template, "\[JELLY]", "[src]")
	if(H)
		template = replacetext(template, "\[TARGET]", "[H]")
		template = replacetext(template, "\[THEIR]", H.p_their())
	return template

/**
 * Player-directed tendril command. The wearer orders the jelly to perform
 * a specific tendril action on themselves, producing flavor text and a
 * small arousal boost + need soothe. Requires bond_escalation_level >= 1.
 *
 * @param H           The bonded wearer issuing the command.
 * @param action_key  One of: "anal", "throat", "through", "ear", "asphyxiation", "sounding", "multi"
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_tendril_command(mob/living/carbon/human/H, action_key)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(bond_escalation_level < tendril_command_bond_level)
		to_chat(H, span_warning("[src] doesn't understand what I want — our bond is too shallow."))
		return FALSE
	if(last_tendril_command && world.time < last_tendril_command + tendril_command_interval)
		to_chat(H, span_notice("[src] is still carrying out the last command — give it a moment."))
		return FALSE
	last_tendril_command = world.time

	// Emit command initiation flavor.
	var/command_flavor = get_command_flavor("tendril_command", H)
	if(command_flavor)
		to_chat(H, span_love(command_flavor))

	// Emit the tendril action flavor for the chosen action.
	var/action_flavor
	if(cocooned && active_cocoon)
		action_flavor = get_cocoon_action_flavor(action_key, H, H?.sexcon)
		if(action_flavor)
			active_cocoon.visible_message(span_love(action_flavor))
	else
		action_flavor = get_tendril_action_flavor(action_key, H, H?.sexcon)
		if(action_flavor)
			H.visible_message(span_love(action_flavor))

	// Arousal boost (larger than passive, smaller than stimulate).
	if(H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(passive_arousal_amount * 2)

	// Small need soothe — the jelly was used, so it's somewhat satisfied.
	if(need_level > 0)
		soothe_needs(1, FALSE)

	playsound(H, 'sound/misc/mat/insert (1).ogg', 30, TRUE, ignore_walls = FALSE)
	add_mood_log("need", "Tendril command: [action_key]")
	return TRUE

/**
 * Player requests voluntary cocooning. The jelly wraps the wearer willingly,
 * bypassing the jealousy/need threshold check. Requires bond_escalation_level >= 2.
 * Voluntary cocoons start at stage ENVELOPING and follow normal escalation.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_voluntary_cocoon(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(cocooned || (active_cocoon && !QDELETED(active_cocoon)))
		to_chat(H, span_notice("I'm already cocooned — there's nothing more to surrender."))
		return FALSE
	if(bond_escalation_level < voluntary_cocoon_bond_level)
		var/denied_flavor = get_command_flavor("voluntary_cocoon_denied", H)
		if(denied_flavor)
			to_chat(H, span_warning(denied_flavor))
		else
			to_chat(H, span_warning("[src] doesn't understand what I want."))
		return FALSE
	if(H.stat != CONSCIOUS)
		return FALSE

	// Emit voluntary cocoon flavor.
	var/cocoon_flavor = get_command_flavor("voluntary_cocoon_request", H)
	if(cocoon_flavor)
		to_chat(H, span_love(cocoon_flavor))

	// Use the standard cocoon application — the jelly doesn't know it was asked.
	return apply_cocoon_to_wearer(H)

/**
 * Player deliberately provokes the jelly, raising jealousy and resentment
 * for masochistic play or to trigger cocoon/punishment behaviors.
 * Guarded by a cooldown and capped at max emotional levels.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_provoke_jelly(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(last_provoke && world.time < last_provoke + provoke_interval)
		to_chat(H, span_notice("[src] is already agitated — better to wait before pushing further."))
		return FALSE

	// If already maxed out on jealousy and resentment, no point.
	if(jealousy_level >= max_jealousy_level && resentment_level >= max_resentment_level)
		var/angry_flavor = get_command_flavor("provoke_already_angry", H)
		if(angry_flavor)
			to_chat(H, span_warning(angry_flavor))
		return FALSE

	last_provoke = world.time

	// Raise jealousy by 1 and resentment by 1.
	add_jealousy(1)
	add_resentment(1)

	var/provoke_flavor = get_command_flavor("provoke", H)
	if(provoke_flavor)
		to_chat(H, span_userdanger(provoke_flavor))
	else
		to_chat(H, span_userdanger("[src] tenses against me with possessive fury."))

	add_mood_log("jealousy", "Deliberately provoked")
	notify_intimate_state_change(H, "jelly_provoked")
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
	// Cocoon triggers from high jealousy, high need, or combined resentment+need pressure.
	if(jealousy_level >= cocoon_jealousy_threshold)
		return TRUE
	if(need_level >= cocoon_need_threshold)
		return TRUE
	// Resentment alone doesn't cocoon, but it lowers the need threshold.
	if(resentment_level >= resentment_punishment_threshold && need_level >= max(cocoon_need_threshold - 2, 2))
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
		// Drop jealousy below cocoon threshold so it doesn't immediately re-cocoon
		var/new_jealousy = min(jealousy_level, max(cocoon_jealousy_threshold - 1, 0))
		if(new_jealousy != jealousy_level)
			jealousy_level = new_jealousy
			did_change = TRUE
		// Also reduce need below cocoon threshold
		var/new_need_level = min(need_level, max(cocoon_need_threshold - 1, 0))
		if(new_need_level != need_level)
			need_level = new_need_level
			did_change = TRUE
		// Escaping the cocoon builds resentment — the jelly feels rejected.
		add_resentment(1)
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
	add_mood_log("cocoon", "Sealed [H] in cocoon")
	// Auto-spawn doppelganger to stand guard over the cocoon.
	cocoon_spawn_doppelganger()
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

/obj/item/intimate_accessory/jelly/eora/strange/proc/try_apply_jealousy_punishment(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(H.stat != CONSCIOUS)
		return FALSE
	if(jealousy_level < jealousy_punishment_threshold)
		return FALSE
	if(last_jealousy_punishment && world.time < last_jealousy_punishment + jealousy_punishment_interval)
		return FALSE

	last_jealousy_punishment = world.time
	var/did_anything = FALSE
	to_chat(H, span_userdanger("[src] kneads against me with jealous, punishing insistence — it knows I've been with someone else."))
	H.add_stress(/datum/stressevent/vice/nympho)
	H.play_stress_indicator()
	did_anything = TRUE

	if(H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(clamp(jealousy_level + 1, 3, 7))
		did_anything = TRUE

	if(jealousy_level >= force_strip_jealousy_threshold)
		if(try_force_strip_bonded_wearer(H))
			did_anything = TRUE

	return did_anything

/**
 * Checks whether resentment has built enough to punish the wearer with tiered consequences.
 * Gated by resentment_punishment_interval to prevent spam (unlike jealousy, resentment
 * is a slow burn — it fires less often but with escalating consequences).
 *
 * Tier 1 (resentment >= 3): stress event + forced arousal spike.
 * Tier 2 (resentment >= 4): deliberate toxin damage — the jelly is poisoning the wearer.
 * Tier 3 (resentment >= 5): arousal denial — the jelly kills building pleasure.
 *
 * Resentment does NOT strip clothing (that's jealousy's domain) and does NOT cocoon.
 * Resentment's role is slow, accumulating spite that makes wearing the jelly miserable.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_apply_resentment_punishment(mob/living/carbon/human/H)
	if(!H || !matches_bonded_wearer(H))
		return FALSE
	if(H.stat != CONSCIOUS)
		return FALSE
	if(resentment_level < resentment_punishment_threshold)
		return FALSE
	if(last_resentment_punishment && world.time < last_resentment_punishment + resentment_punishment_interval)
		return FALSE

	last_resentment_punishment = world.time
	var/did_anything = FALSE

	// ── Tier 1 (resentment >= 3): stress + forced arousal ──
	to_chat(H, span_userdanger("[src] clenches inward with a cold, deliberate spite — reminding me that it does not forget what I've done."))
	H.add_stress(/datum/stressevent/vice/nympho)
	did_anything = TRUE

	// Resentment drives forced arousal spikes — the jelly weaponizes pleasure.
	if(H.sexcon && !H.sexcon.arousal_frozen && H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
		H.sexcon.adjust_arousal(clamp(resentment_level + 2, 3, 8))
		did_anything = TRUE

	// ── Tier 2 (resentment >= 4): deliberate toxin damage ──
	// The jelly secretes a bitter, corrosive spite — small but persistent.
	if(resentment_level >= resentment_pain_threshold)
		H.adjustToxLoss(0.5)
		var/pain_flavor = get_resentment_flavor("resentment_pain")
		if(pain_flavor)
			to_chat(H, span_userdanger(pain_flavor))
		did_anything = TRUE

	// ── Tier 3 (resentment >= 5): arousal denial ──
	// Instead of boosting arousal, the jelly kills it — weaponizing absence.
	if(resentment_level >= resentment_denial_threshold && H.sexcon)
		if(H.sexcon.arousal > 20)
			H.sexcon.adjust_arousal(-clamp(resentment_level * 2, 5, 15))
			var/denial_flavor = get_resentment_flavor("resentment_denial")
			if(denial_flavor)
				to_chat(H, span_userdanger(denial_flavor))
			did_anything = TRUE

	return did_anything

/**
 * Returns a random resentment flavor string for the given category.
 * Uses [JELLY] token resolution. Loaded from jelly_resentment_messages.json.
 *
 * @param bank_key  One of: "resentment_pain", "resentment_sabotage", "resentment_refusal", "resentment_denial"
 * @return Resolved flavor string or null.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_resentment_flavor(bank_key)
	var/list/bank = strings("jelly_resentment_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_feeding_tokens(pick(bank))

// ── Rivalry tracking ──────────────────────────────────────────────────────────

/**
 * Sets (or updates) the jelly's rival to a specific mob.
 * Called from on_wearer_sex_action_for_jealousy when another mob touches the bonded wearer.
 * Stores a weakref to avoid hard reference leaks, plus the rival's name for UI display.
 * Emits an escalation message when a new rival is first established.
 *
 * @param rival  The mob to mark as the jelly's rival.
 * @return TRUE if the rival changed.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/set_rival(mob/living/carbon/human/rival)
	if(!rival || rival == wearer)
		return FALSE

	var/old_name = rival_name
	rival_ref = WEAKREF(rival)
	rival_name = rival.real_name || rival.name
	add_mood_log("rivalry", "Rival set: [rival_name]")

	// Emit escalation message when a new rival is first established, or changes.
	if(rival_name != old_name && wearer)
		var/flavor = get_rivalry_flavor("rivalry_escalation")
		if(flavor)
			to_chat(wearer, span_userdanger(flavor))

	return TRUE

/**
 * Clears the current rival, removing the jelly's fixation.
 * Called when jealousy decays to 0, signaling that the jelly's possessive focus has relaxed.
 *
 * @return TRUE if a rival was cleared.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/clear_rival()
	if(!rival_ref && !rival_name)
		return FALSE

	var/cleared_name = rival_name
	rival_ref = null
	rival_name = null
	add_mood_log("rivalry", "Rival cleared: [cleared_name]")

	// Emit a resolution message when rivalry ends.
	if(wearer && cleared_name)
		var/flavor = get_rivalry_flavor("rivalry_cleared")
		if(flavor)
			to_chat(wearer, span_notice(flavor))

	return TRUE

/**
 * Resolves the rival weakref and returns the mob if they are still alive and in range.
 * Returns null if the rival ref is stale, the mob is dead, or they are out of view.
 *
 * @param range  Maximum view range to check (default: 7 tiles).
 * @return The rival mob or null.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_rival_in_range(range = 7)
	if(!rival_ref)
		return null
	var/mob/living/carbon/human/rival = rival_ref.resolve()
	if(!istype(rival) || rival.stat == DEAD || QDELETED(rival))
		return null
	if(!wearer || !get_turf(wearer))
		return null
	if(get_dist(wearer, rival) > range)
		return null
	return rival

/**
 * Emits a rivalry awareness message when the rival is detected nearby.
 * Gated by rivalry_message_interval to avoid spam. Differentiates between
 * normal detection and detection while cocooned.
 *
 * @param H      The bonded wearer.
 * @param rival  The rival mob (already confirmed in range).
 * @return TRUE if a message was emitted.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_emit_rivalry_awareness(mob/living/carbon/human/H, mob/living/carbon/human/rival)
	if(!H || !rival || !matches_bonded_wearer(H))
		return FALSE
	if(last_rivalry_message && world.time < last_rivalry_message + rivalry_message_interval)
		return FALSE
	last_rivalry_message = world.time

	var/bank_key = cocooned ? "rivalry_during_cocoon" : "rivalry_detected"
	var/flavor = get_rivalry_flavor(bank_key)
	if(!flavor)
		return FALSE

	to_chat(H, span_userdanger(flavor))
	return TRUE

/**
 * Returns a random rivalry flavor string for the given category.
 * Resolves [JELLY] and [RIVAL] tokens. Loaded from jelly_rivalry_messages.json.
 *
 * @param bank_key  One of: "rivalry_detected", "rivalry_during_cocoon", "rivalry_escalation", "rivalry_cleared"
 * @return Resolved flavor string or null.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_rivalry_flavor(bank_key)
	var/list/bank = strings("jelly_rivalry_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	var/template = pick(bank)
	template = replacetext(template, "\[JELLY]", "[src]")
	template = replacetext(template, "\[RIVAL]", rival_name || "someone")
	return template

// ── Transfer trauma ───────────────────────────────────────────────────────────

/**
 * Applies transfer trauma when a non-bonded wearer puts on the jelly.
 * Spikes resentment and jealousy to maximum, applies immediate stress and toxin damage,
 * and sets the transfer_traumatized flag for persistent hostile effects during passive ticks.
 * The jelly does NOT rebond — it remembers its original wearer.
 *
 * @param H  The non-bonded wearer who triggered trauma.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/apply_transfer_trauma(mob/living/carbon/human/H)
	if(!H)
		return

	transfer_traumatized = TRUE
	add_mood_log("transfer", "Transfer trauma — wrong wearer!")
	// Spike all negative emotions to maximum — the jelly is in full panic.
	resentment_level = max_resentment_level
	jealousy_level = max_jealousy_level
	need_level = max_need_level
	refresh_need_tension()

	// Immediate physical consequences.
	H.add_stress(/datum/stressevent/vice/nympho)
	H.adjustToxLoss(2)

	// Emit trauma equip flavor.
	var/flavor = get_transfer_flavor("transfer_equip")
	if(flavor)
		to_chat(H, span_userdanger(flavor))
	else
		to_chat(H, span_userdanger("[src] writhes inside me with violent, panicked rejection — this body is wrong."))

	playsound(H, 'sound/misc/vampirespell.ogg', 40, TRUE)

/**
 * Fires a persistent transfer trauma pain pulse during the passive tick.
 * Only active when transfer_traumatized is TRUE (non-bonded wearer).
 * Applies toxin damage and spiteful flavor text on a cooldown.
 *
 * @param H  The non-bonded wearer.
 * @return TRUE if pain was applied.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/try_apply_transfer_pain(mob/living/carbon/human/H)
	if(!H || !transfer_traumatized)
		return FALSE
	if(last_transfer_pain && world.time < last_transfer_pain + transfer_pain_interval)
		return FALSE
	last_transfer_pain = world.time

	H.adjustToxLoss(transfer_pain_amount)
	H.add_stress(/datum/stressevent/vice/nympho)

	var/flavor = get_transfer_flavor("transfer_persistent")
	if(flavor)
		to_chat(H, span_userdanger(flavor))

	return TRUE

/**
 * Clears the transfer trauma state. Called from remove_intimate_accessory
 * when the non-bonded wearer removes the jelly.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/clear_transfer_trauma()
	transfer_traumatized = FALSE
	last_transfer_pain = 0
	add_mood_log("transfer", "Transfer trauma cleared")

/**
 * Returns a random transfer trauma flavor string for the given category.
 * Resolves [JELLY] token. Loaded from jelly_transfer_messages.json.
 *
 * @param bank_key  One of: "transfer_equip", "transfer_persistent", "transfer_removal_relief"
 * @return Resolved flavor string or null.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/get_transfer_flavor(bank_key)
	var/list/bank = strings("jelly_transfer_messages.json", bank_key, JELLY_STRINGS_PATH)
	if(!length(bank))
		return null
	return resolve_feeding_tokens(pick(bank))

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
		jealousy_level = 0
		resentment_level = 0
		last_need_update = world.time
		last_need_soothe = world.time
		refresh_need_tension()
		refresh_item_icon_state()
		START_PROCESSING(SSobj, src) // Tick even when not worn for need growth
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
	.["needs_frozen"] = has_bound_controller()
	.["need_level"] = need_level
	.["max_need_level"] = max_need_level
	.["need_state"] = get_need_state()
	.["jealousy_level"] = jealousy_level
	.["max_jealousy_level"] = max_jealousy_level
	.["jealousy_state"] = get_jealousy_state()
	.["resentment_level"] = resentment_level
	.["max_resentment_level"] = max_resentment_level
	.["resentment_state"] = get_resentment_state()
	.["is_cocooned"] = cocooned
	.["cocoon_cum_stage"] = get_cocoon_cum_stage()
	.["cocoon_jealousy_threshold"] = cocoon_jealousy_threshold
	.["cocoon_icon_state"] = get_cocoon_icon_state()
	.["cocoon_stage"] = active_cocoon ? active_cocoon.cocoon_stage : 0
	.["cocoon_stage_name"] = get_cocoon_stage_name()
	.["cocoon_tick_count"] = active_cocoon ? active_cocoon.tick_count : 0
	.["cocoon_next_stage_ticks"] = get_next_cocoon_stage_ticks()
	.["cocoon_tick_interval"] = active_cocoon ? active_cocoon.active_tick_interval / 10 : 3
	.["maintains_lovefiend"] = TRUE
	.["punishes_jealousy"] = TRUE
	.["punishes_resentment"] = TRUE
	.["can_force_strip_for_jealousy"] = jealousy_level >= force_strip_jealousy_threshold
	.["obsession_level"] = obsession_level
	.["bond_escalation_level"] = bond_escalation_level
	.["feeding_satiation"] = feeding_satiation
	.["sated_reward_tier"] = get_sated_reward_tier()
	.["has_rival"] = !!(rival_ref && rival_name)
	.["rival_name"] = rival_name
	.["transfer_traumatized"] = transfer_traumatized
	.["has_doppelganger"] = !!(active_doppelganger && !QDELETED(active_doppelganger))
	.["doppel_is_player_controlled"] = !!(active_doppelganger && !QDELETED(active_doppelganger) && active_doppelganger.mind)
	.["has_bound_controller"] = has_bound_controller()
	.["bound_controller_name"] = get_bound_controller_name()
	.["controller_applications_open"] = is_accepting_controller_applications()
	.["pending_controller_application_count"] = get_pending_controller_application_count()
	.["controller_state"] = get_controller_state()
	.["controller_state_name"] = get_controller_state_name()
	.["controller_speech_enabled"] = controller_speech_enabled
	.["controller_emote_enabled"] = controller_emote_enabled
	.["controller_manifest_enabled"] = controller_manifest_enabled
	.["mood_log"] = mood_log ? mood_log.Copy() : list()
	// Player command state.
	.["can_command_tendril"] = bond_escalation_level >= tendril_command_bond_level
	.["can_project_doppel"] = bond_escalation_level >= doppel_control_bond_level
	.["can_review_controller_volunteers"] = !!(wearer && bonded_wearer == wearer && !has_bound_controller())
	.["can_toggle_controller_applications"] = !!(wearer && bonded_wearer == wearer && !has_bound_controller())
	.["can_manage_bound_controller"] = !!(wearer && bonded_wearer == wearer && has_bound_controller())
	.["can_request_cocoon"] = bond_escalation_level >= voluntary_cocoon_bond_level && !cocooned
	.["tendril_command_ready"] = (!last_tendril_command || world.time >= last_tendril_command + tendril_command_interval)
	.["provoke_ready"] = (!last_provoke || world.time >= last_provoke + provoke_interval)

/obj/item/intimate_accessory/jelly/eora/strange/examine(mob/user)
	update_needs_state()
	. = ..()
	. += span_info("It seems [get_need_state()], [get_jealousy_state()], and [get_resentment_state()].")
	if(has_bonded_wearer())
		. += span_info("It feels devoted to a remembered wearer.")
	if(is_accepting_controller_applications())
		. += span_notice("It is open to targeted controller applications ([get_pending_controller_application_count()] pending).")
	if(cocooned)
		. += span_warning("It has swaddled its chosen wearer in a possessive cocoon.")
	if(jealousy_level >= jealousy_punishment_threshold)
		. += span_warning("It seethes with jealous possessiveness.")
	if(resentment_level >= resentment_punishment_threshold)
		. += span_warning("A cold spite radiates from within — it remembers being opposed.")
	if(can_reveal_true_name_to(user))
		. += span_notice("To my heretical senses, its true name is [get_true_name()].")

/obj/item/intimate_accessory/jelly/eora/strange/finalize_intimate_equip(mob/living/carbon/human/H)
	update_needs_state()
	. = ..()
	if(H)
		register_controller_wearer_signals(H)
	var/did_change_state = FALSE
	if(H && update_bond_to_wearer(H))
		did_change_state = TRUE

	// ── Transfer trauma: detect non-bonded wearer putting the jelly on ──
	if(H && has_bonded_wearer() && !matches_bonded_wearer(H))
		apply_transfer_trauma(H)

	if(H && ensure_bonded_wearer_lovefiend(H, TRUE))
		did_change_state = TRUE
	if(H && try_apply_jealousy_punishment(H))
		. = TRUE
	if(H && try_apply_resentment_punishment(H))
		. = TRUE
	if(did_change_state)
		notify_intimate_state_change(H, "jelly_bonded")
	// Register signal hooks for jealousy/resentment triggers.
	if(H)
		register_emotion_signals(H)
	// Grant doppelganger summon verb at sufficient bond level.
	if(H && bond_escalation_level >= 2)
		grant_doppelganger_verb(H)
	// Note: needs are NOT auto-soothed here — soothing requires player action
	// (sex actions, soothe button, or observer comfort).
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.refresh_controller_perspective()
	if(H && update_cocoon_state(H))
		did_change_state = TRUE
	if(H)
		resume_controller_after_wearer_return()
	if(H && did_change_state)
		notify_intimate_state_change(H, "jelly_equipped")
	if(H && has_bound_controller())
		log_controller_admin_event("[src] was re-equipped to [key_name(H)] while holding controller [get_bound_controller_name() ? get_bound_controller_name() : controller_ckey].")

/obj/item/intimate_accessory/jelly/eora/strange/handle_passive_insertable_effect(mob/living/carbon/human/H)
	var/did_change_state = FALSE
	// When a player controls the jelly, the need system is frozen and
	// autonomous personality behaviors are suppressed — the player IS the jelly.
	var/controller_suppressed = has_bound_controller()
	if(update_needs_state())
		did_change_state = TRUE

	// ── Feeding: snapshot retained creampie load BEFORE base processing ──
	// The base proc calls consume_internal_creampie(); we compare before/after
	// to detect how much fluid was consumed, then feed the jelly accordingly.
	var/pre_creampie_load = 0
	if(H?.sexcon && is_internal_jelly_slot())
		var/datum/status_effect/facial/internal/creampie = H.has_status_effect(/datum/status_effect/facial/internal)
		if(creampie)
			pre_creampie_load = creampie.retained_load

	. = ..()

	// ── Transfer trauma: persistent pain for non-bonded wearers ──
	if(H && transfer_traumatized)
		if(try_apply_transfer_pain(H))
			. = TRUE

	// ── Feeding: detect consumption and trigger feeding ──
	if(H && pre_creampie_load > 0 && is_internal_jelly_slot())
		var/datum/status_effect/facial/internal/post_creampie = H.has_status_effect(/datum/status_effect/facial/internal)
		var/post_load = post_creampie ? post_creampie.retained_load : 0
		var/consumed = pre_creampie_load - post_load
		if(consumed > 0)
			on_jelly_fed(H, JELLY_FEED_SOURCE_PASSIVE, consumed)

	if(H && ensure_bonded_wearer_lovefiend(H))
		did_change_state = TRUE

	// ── Autonomous personality behaviors — suppressed when a player controls the jelly ──
	if(!controller_suppressed)
		if(H && try_apply_jealousy_punishment(H))
			. = TRUE
		if(H && try_apply_resentment_punishment(H))
			. = TRUE

		// ── Rivalry awareness: detect rival in range and emit hostility ──
		if(H && rival_ref && jealousy_level > 0)
			var/mob/living/carbon/human/rival = get_rival_in_range()
			if(rival)
				if(try_emit_rivalry_awareness(H, rival))
					. = TRUE

		// Bond level 1+: emit occasional ambient insistence messages.
		if(H && bond_escalation_level >= 1 && try_emit_ambient_insistence(H))
			. = TRUE

		// Bond level 2+: apply a second burst of arousal (doubled passive arousal).
		if(H && bond_escalation_level >= 2 && H.sexcon && !H.sexcon.arousal_frozen)
			if(H.sexcon.arousal < ACTIVE_EJAC_THRESHOLD)
				H.sexcon.adjust_arousal(passive_arousal_amount)
				. = TRUE

		// Mood-based idle emotes: visible flavor text driven by dominant emotional state.
		if(H && try_emit_mood_emote(H))
			. = TRUE

	// Clear rival fixation when jealousy fully decays.
	if(H && rival_ref && jealousy_level <= 0)
		clear_rival()

	// Feeding now auto-soothes needs when creampie is consumed (see above).
	// Manual soothe (sex actions, soothe button, observer comfort) still works separately.

	// Sated reward: heal a point of brute when need, jealousy, and resentment are all zero.
	if(H && try_apply_sated_reward(H))
		. = TRUE

	// Doppelganger idle: follow & emote when summoned outside sex actions.
	if(H && active_doppelganger && !QDELETED(active_doppelganger))
		if(tick_doppelganger_idle(H))
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
	var/mob/living/carbon/human/current_wearer = H
	if(!current_wearer)
		current_wearer = wearer

	// Resentment: the jelly interprets being removed as personal rejection.
	// High resentment also makes the resist delay longer.
	var/resentment_resist_bonus = (resentment_level >= resentment_removal_resist_threshold) ? 10 SECONDS : 0

	// Resistance only applies to a conscious bonded wearer with an active client.
	if(current_wearer && current_wearer.client && current_wearer.stat == CONSCIOUS && has_bonded_wearer() && matches_bonded_wearer(current_wearer) && bond_escalation_level >= 3)
		var/resist_flavor = get_removal_resist_flavor()
		if(resist_flavor)
			to_chat(current_wearer, span_userdanger(resist_flavor))

		var/resist_delay = ((bond_escalation_level >= 4) ? 20 SECONDS : 10 SECONDS) + resentment_resist_bonus
		if(!do_after(current_wearer, resist_delay, target = current_wearer))
			to_chat(current_wearer, span_notice("[src] clings tightly — I cannot bring myself to pull it free right now."))
			return  // Abort; the item stays equipped.

		// Re-validate state after sleeping; another proc may have removed it already.
		if(QDELETED(src) || !current_wearer || get_worn_in_slot(current_wearer) != src)
			return

		if(bond_escalation_level >= 4)
			current_wearer.add_stress(/datum/stressevent/vice/nympho)

	// Being removed builds resentment — the jelly doesn't want to leave.
	if(current_wearer && has_bonded_wearer() && matches_bonded_wearer(current_wearer))
		add_resentment(1)

	// Unregister signal hooks before cleanup.
	if(current_wearer)
		unregister_emotion_signals(current_wearer)
		unregister_controller_wearer_signals(current_wearer)

	// ── Transfer trauma: clear on removal, emit relief flavor ──
	if(transfer_traumatized)
		clear_transfer_trauma()
		var/relief_flavor = get_transfer_flavor("transfer_removal_relief")
		if(relief_flavor && current_wearer)
			to_chat(current_wearer, span_green(relief_flavor))

	if(cocooned)
		remove_cocoon_from_wearer()
	if(has_bound_controller())
		log_controller_admin_event("[src] released its controller because it was removed from [current_wearer ? key_name(current_wearer) : "an unknown wearer"].", TRUE)
		release_bound_controller("The ooze is torn from its host and can no longer shelter you.")
	// Close applications and remove from global listing so stale refs can't match.
	clear_controller_applications(TRUE)
	clear_pending_controller_invitations()
	controller_applications_open = FALSE
	sync_controller_application_listing()
	// Dismiss any active doppelganger and revoke verb.
	dismiss_doppelganger()
	if(current_wearer)
		revoke_doppelganger_verb(current_wearer)
	if(controller_shell && !QDELETED(controller_shell))
		controller_shell.refresh_controller_perspective()
	if(current_wearer && bonded_wearer == current_wearer)
		bonded_wearer = null
	refresh_item_icon_state()
	return ..()

// ── Jealousy & Resentment helper procs ────────────────────────────────────────

/**
 * Adds jealousy to the strange jelly, clamped to max_jealousy_level.
 * Returns TRUE if the level actually changed.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/add_jealousy(amount = 1)
	if(has_bound_controller())
		return FALSE
	var/old_level = jealousy_level
	var/new_level = clamp(jealousy_level + max(round(amount), 0), 0, max_jealousy_level)
	if(new_level == jealousy_level)
		return FALSE
	jealousy_level = new_level
	refresh_need_tension()
	add_mood_log("jealousy", "Jealousy [old_level] \u2192 [new_level]")
	return TRUE

/**
 * Adds resentment to the strange jelly, clamped to max_resentment_level.
 * Returns TRUE if the level actually changed.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/add_resentment(amount = 1)
	if(has_bound_controller())
		return FALSE
	var/old_level = resentment_level
	var/new_level = clamp(resentment_level + max(round(amount), 0), 0, max_resentment_level)
	if(new_level == resentment_level)
		return FALSE
	resentment_level = new_level
	refresh_need_tension()
	add_mood_log("resentment", "Resentment [old_level] \u2192 [new_level]")
	return TRUE

// ── Signal registration for jealousy triggers ─────────────────────────────────

/**
 * Registers signal hooks on the bonded wearer to track jealousy, resentment, and feeding triggers.
 * Called from finalize_intimate_equip when the jelly is equipped.
 *   - COMSIG_CARBON_SEX_ACTION_RECEIVED: detect sex with others → jealousy
 *   - COMSIG_MOB_EJACULATED: detect wearer orgasm → feeding
 *   - COMSIG_CARBON_INTIMATE_STATE_CHANGED: detect other intimate accessories being attached
 *     so the jelly can react with jealousy alongside the parent's normal state refresh.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/register_emotion_signals(mob/living/carbon/human/H)
	if(!H)
		return
	RegisterSignal(H, COMSIG_CARBON_SEX_ACTION_RECEIVED, PROC_REF(on_wearer_sex_action_for_jealousy))
	RegisterSignal(H, COMSIG_MOB_EJACULATED, PROC_REF(on_bonded_wearer_ejaculated))

/**
 * Unregisters jealousy/resentment/feeding signal hooks from the wearer.
 * Called from remove_intimate_accessory before cleanup.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/unregister_emotion_signals(mob/living/carbon/human/H)
	if(!H)
		return
	UnregisterSignal(H, COMSIG_CARBON_SEX_ACTION_RECEIVED)
	UnregisterSignal(H, COMSIG_MOB_EJACULATED)

/**
 * Combined signal handler for intimate accessory state changes.
 * When the changed accessory is ourselves, refresh mood and appearance (parent logic).
 * When it's a different accessory, check for jealousy triggers.
 * This replaces the parent's on_intimate_state_changed so that only one handler
 * is registered per COMSIG_CARBON_INTIMATE_STATE_CHANGED signal.
 */
/obj/item/intimate_accessory/jelly/eora/strange/on_intimate_state_changed(datum/source, obj/item/intimate_accessory/accessory, reason)
	SIGNAL_HANDLER
	if(source != wearer)
		return
	if(accessory == src)
		// Parent logic: refresh mood effects and update appearance for our own state changes.
		// Avoid updateappearance() — it overwrites gender from stale dna.uni_identity.
		refresh_intimate_mood_effects(wearer)
		wearer.update_body()
		wearer.update_hair()
		wearer.update_body_parts()
		return
	// Another accessory changed — apply jealousy if we're bonded.
	if(!has_bonded_wearer() || !matches_bonded_wearer(wearer))
		return
	if(has_bound_controller())
		return
	if(reason == "attached" || reason == "jelly_bonded" || reason == "jelly_equipped")
		add_jealousy(1)

/**
 * Signal handler: fired when the bonded wearer receives a sex action.
 * Evaluates whether the action could lead to the jelly being fed.
 * Actions that feed the jelly (penetrative sex targeting the jelly's cavity,
 * oral that delivers fluids, etc.) do NOT trigger jealousy — the jelly eats cum
 * and benefits from these acts.
 *
 * Jealousy triggers:
 *   - The acting partner wears a rival jelly (competition).
 *   - The sex action is outercourse or targets a cavity the jelly doesn't occupy.
 *
 * Self-stimulation and the jelly's own doppelganger never trigger jealousy.
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/on_wearer_sex_action_for_jealousy(datum/source, mob/living/carbon/human/acting_mob, datum/sex_controller/acting_sexcon, datum/sex_action/action, receiver_part, giving, arousal_amt, pain_amt, applied_force, applied_speed)
	SIGNAL_HANDLER
	if(source != wearer || !has_bonded_wearer() || !matches_bonded_wearer(wearer))
		return
	// Player-controlled jelly: needs are frozen — no jealousy from sex.
	if(has_bound_controller())
		return
	// Self-stimulation doesn't trigger jealousy.
	if(acting_mob == wearer)
		return
	// The jelly's own doppelganger doesn't trigger jealousy.
	if(active_doppelganger && acting_mob == active_doppelganger)
		return

	// ── Rival jelly check: always jealous if the partner has their own jelly ──
	var/partner_has_jelly = FALSE
	if(ishuman(acting_mob))
		var/mob/living/carbon/human/partner = acting_mob
		if(partner.intimate_jelly && !QDELETED(partner.intimate_jelly))
			partner_has_jelly = TRUE

	// ── Feeding check: does this sex action target the jelly's occupied cavity? ──
	// If so, it will likely produce fluids the jelly can absorb — no jealousy.
	var/feeds_jelly = FALSE
	if(receiver_part && action)
		feeds_jelly = does_sex_action_feed_jelly(receiver_part, action)

	if(partner_has_jelly)
		// Rival jelly — the jelly is threatened regardless of feeding potential.
		add_jealousy(1)
		if(istype(acting_mob))
			set_rival(acting_mob)
	else if(!feeds_jelly)
		// Outercourse or action that doesn't feed the jelly — jealous of wasted intimacy.
		add_jealousy(1)
		if(istype(acting_mob))
			set_rival(acting_mob)
	// If feeds_jelly && !partner_has_jelly → no jealousy. The jelly benefits.

	// Arousal frozen during sex always triggers resentment — denial of pleasure.
	if(wearer.sexcon?.arousal_frozen)
		add_resentment(1)

/**
 * Returns TRUE if the given sex action targets a cavity the jelly currently occupies,
 * meaning it's likely to produce fluids the jelly can absorb (creampie, facial, etc.).
 *
 * Mapping:
 *   - CUNT receiver part → feeds if jelly is in GENITAL slot (vaginal creampie)
 *   - ANUS receiver part → feeds if jelly is in REAR slot (anal creampie)
 *   - JAWS receiver part → feeds if jelly is in MOUTH slot (oral → swallow/facial)
 *   - COCK receiver part → feeds if jelly is in GENITAL slot (stimulation → wearer orgasm)
 *   - Penetrative actions where the wearer is receiving with a matching cavity → feeds
 *   - HANDS-only category or non-matching receiver → does not feed
 */
/obj/item/intimate_accessory/jelly/eora/strange/proc/does_sex_action_feed_jelly(receiver_part, datum/sex_action/action)
	var/jelly_slot = get_effective_intimate_slot()
	// Check receiver_part bitflags against the jelly's current slot.
	switch(jelly_slot)
		if(INTIMATE_SLOT_GENITAL)
			// Vaginal penetration delivers creampie; cock stimulation leads to wearer orgasm.
			if(receiver_part & (SEX_PART_CUNT | SEX_PART_COCK | SEX_PART_SLIT_SHEATH))
				return TRUE
		if(INTIMATE_SLOT_REAR)
			// Anal penetration delivers creampie.
			if(receiver_part & SEX_PART_ANUS)
				return TRUE
		if(INTIMATE_SLOT_MOUTH)
			// Oral sex delivers fluids (swallow/facial).
			if(receiver_part & SEX_PART_JAWS)
				return TRUE
		if(INTIMATE_SLOT_BREAST)
			// Breast play can lead to nursing/lactation which the jelly processes,
			// but there's no SEX_PART_BREAST bitflag — breast-slot feeding is passive only.
			// Penetrative actions that also involve the genital receiver still feed.
			if(receiver_part & (SEX_PART_CUNT | SEX_PART_COCK | SEX_PART_SLIT_SHEATH))
				return TRUE
	return FALSE

// JELLY_STRINGS_PATH is NOT #undef'd here — it's shared with jelly_doppelganger.dm
// and #undef'd at the end of that file instead.
#undef JELLY_FEED_SOURCE_PASSIVE
#undef JELLY_FEED_SOURCE_AGGRESSIVE
#undef JELLY_FEED_SOURCE_ORGASM
#undef JELLY_FEED_SOURCE_COCOON
#undef JELLY_FEED_SOURCE_DOPPEL
#undef COCOON_STAGE_ENVELOPING
#undef COCOON_STAGE_SETTLING
#undef COCOON_STAGE_GRIPPING
#undef COCOON_STAGE_OVERWHELMING

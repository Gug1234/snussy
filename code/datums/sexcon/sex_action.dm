/datum/sex_action
	abstract_type = /datum/sex_action
	var/name = "Zodomize"
	/// Time to do the act, modified by up to 2.5x speed by the speed toggle
	var/do_time = 3.3 SECONDS
	/// Whether the act is continous and will be done on repeat
	var/continous = TRUE
	/// Stamina cost per action, modified by up to 2.5x cost by the force toggle
	var/stamina_cost = 0.5
	/// Whether the action requires both participants to be on the same tile
	var/check_same_tile = TRUE
	/// Whether the same tile check can be bypassed by an aggro grab on the person
	var/aggro_grab_instead_same_tile = TRUE
	/// Whether the action is forbidden from being done while incapacitated (stun, handcuffed)
	var/check_incapacitated = TRUE
	/// Whether the action requires an aggressive grab on the victim
	var/require_grab = FALSE
	/// If a grab is required, this is the required state of it
	var/required_grab_state = GRAB_AGGRESSIVE
	/// Set the menu category for the action
	var/category = SEX_CATEGORY_MISC
	/// Set which part/oriface the user will be using
	var/user_sex_part = SEX_PART_NULL
	/// Set which part/oriface the target will be using
	var/target_sex_part = SEX_PART_NULL
	/// Only allow select actions to be done subtly
	var/subtle_supported = FALSE
	/// Only allow select actions to end with a knot-tie
	var/knot_on_finish = FALSE
	/// Central intimate-state validation participation. Generic actions default to both roles; chastityplay keeps bespoke checks.
	var/intimate_check_flags = SEX_ACTION_INTIMATE_CHECK_BOTH

/datum/sex_action/proc/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return TRUE

/datum/sex_action/proc/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action/proc/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action/proc/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action/proc/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return FALSE

/// Returns the display name for the action, optionally player-specific.
/// Override in custom action slots to pull the name from player preferences.
/datum/sex_action/proc/get_display_name(mob/living/carbon/human/user)
	return name

/datum/sex_action/proc/get_runtime_category(mob/living/carbon/human/user)
	return category

/datum/sex_action/proc/get_runtime_stamina_cost(mob/living/carbon/human/user)
	return stamina_cost

/datum/sex_action/proc/should_suppress_default(mob/living/carbon/human/user, phase)
	return FALSE

/datum/sex_action/proc/modular_on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action/proc/modular_on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action/proc/modular_on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return

/datum/sex_action/proc/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return TRUE

// chastity play abstract action, contains shared code for actions that interact with chastity devices
/datum/sex_action/chastityplay 
	abstract_type = /datum/sex_action/chastityplay
	intimate_check_flags = SEX_ACTION_INTIMATE_CHECK_NONE

/datum/sex_action/chastityplay/proc/get_chastity_device_name(mob/living/carbon/human/owner)
	if(owner?.chastity_device)
		return owner.chastity_device.name
	return "chastity device"

// Shared guard for actions that must be performed on someone else.
/datum/sex_action/chastityplay/proc/requires_other_target(mob/living/carbon/human/user, mob/living/carbon/human/target)
	return !!(user && target && user != target)

// Centralized cage presence check to keep action-gating logic consistent.
/datum/sex_action/chastityplay/proc/target_has_cage(mob/living/carbon/human/target)
	return !!target?.sexcon?.has_chastity_cage()

// Matches any front chastity lockout (cage or belt) for actions that work on either.
/datum/sex_action/chastityplay/proc/target_has_front_chastity(mob/living/carbon/human/target)
	return !!target?.sexcon?.has_chastity_cage()

// Standard groin reach check used across chastityplay actions.
/datum/sex_action/chastityplay/proc/can_reach_target_groin(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target)
		return FALSE
	return check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE)

// Unified sound helper: supports single sound or list input with optional chance gating.
/datum/sex_action/chastityplay/proc/play_chastity_impact_sound(mob/living/carbon/human/target, sound_to_play, volume = 40, chance = 100, vary = TRUE, frequency = -1)
	if(!target || !sound_to_play)
		return FALSE
	if(chance < 100 && !prob(chance))
		return FALSE
	var/selected_sound = islist(sound_to_play) ? pick(sound_to_play) : sound_to_play
	playsound(target, selected_sound, volume, vary, frequency, ignore_walls = FALSE)
	return TRUE

/datum/sex_action/proc/get_rear_plug(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/rear/plug/rear_plug = owner.intimate_rear_insertable
	if(!istype(rear_plug))
		return null
	return rear_plug

/datum/sex_action/proc/get_breast_piercing(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/piercing/breast/breast_piercing = owner.intimate_breast_piercing
	if(!istype(breast_piercing))
		return null
	return breast_piercing

/datum/sex_action/proc/anal_blocked_by_rear_plug(mob/living/carbon/human/user, mob/living/carbon/human/owner, display_message = FALSE)
	if(!get_rear_plug(owner))
		return FALSE
	if(display_message && user && owner)
		if(user == owner)
			to_chat(user, span_warning("My butt plug blocks access to my ass."))
		else
			to_chat(user, span_warning("[owner]'s butt plug blocks access to [owner.p_their()] ass."))
	return TRUE

/datum/sex_action/proc/can_target_other_rear_plug(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target || user == target)
		return FALSE
	return !!get_rear_plug(target)

/datum/sex_action/proc/can_access_other_rear_plug(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!can_target_other_rear_plug(user, target))
		return FALSE
	return check_location_accessible(user, target, BODY_ZONE_PRECISE_GROIN, TRUE)

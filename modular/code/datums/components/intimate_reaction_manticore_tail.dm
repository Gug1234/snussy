// Component subtype for manticore tail orifice reactions.
// Produces private movement flavor (tail maw flexing, feelers shifting, fluid dripping)
// and private sex-received flavor when the tail is involved in sex actions.
// Attaches to a tail organ; binds/unbinds via organ insertion/removal signals.
// See /datum/component/intimate_reaction for the base framework and authoring guide.

/// Local path to this module's string bank directory.
#define MANTICORE_TAIL_STRINGS_PATH "modular/code/datums/components/strings"

/**
 * Reaction component for manticore tail orifice.
 *
 * Fires movement flavor (to_chat) when the host walks — the tail maw shifting,
 * feelers writhing, fluids dripping. Fires sex-received flavor (to_chat) when
 * the tail is involved in intimate actions (penetration, wrapping, oral contact).
 *
 * Unlike piercings/chastity which produce visible_messages, the tail reactions
 * are purely private to_chat — they describe internal sensations the manticore feels.
 */
/datum/component/intimate_reaction/manticore_tail
	dupe_mode = COMPONENT_DUPE_UNIQUE
	movement_message_cooldown = 30 SECONDS
	/// Cooldown for sex-received flavor messages.
	var/last_receive_flavor_time = 0
	var/receive_flavor_cooldown = 20 SECONDS

/datum/component/intimate_reaction/manticore_tail/Initialize()
	if(!istype(parent, /obj/item/organ/tail))
		return COMPONENT_INCOMPATIBLE

/// Binds the component to the wearer when the tail organ is inserted.
/// Registers both movement and sex-action signals.
/datum/component/intimate_reaction/manticore_tail/bind_to_wearer(mob/living/carbon/human/H)
	var/already_bound = (wearer == H)
	. = ..()
	if(!.)
		return FALSE
	if(already_bound)
		return TRUE
	register_movement_reaction(H)
	return TRUE

/datum/component/intimate_reaction/manticore_tail/unbind_from_wearer(mob/living/carbon/human/H)
	if(!H)
		H = wearer
	if(!H)
		return FALSE
	unregister_movement_reaction(H)
	return ..()

/// Validates that the parent tail organ is still inserted in the source mob.
/datum/component/intimate_reaction/manticore_tail/is_valid_wearer_source(mob/living/carbon/human/source)
	if(!..())
		return FALSE
	var/obj/item/organ/tail/T = parent
	return T.owner == source

/// Movement handler: sends a private sensation message about the tail maw's idle behavior.
/// Arousal-aware — uses the aroused bank when the wearer's arousal is elevated.
/datum/component/intimate_reaction/manticore_tail/try_handle_wearer_moved(mob/living/carbon/human/source)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_movement_message_time + movement_message_cooldown >= world.time)
		return FALSE
	if(!can_fire_reaction(source, "movement"))
		return FALSE
	if(!prob(18))
		return FALSE
	var/datum/sex_controller/sexcon = source.sexcon
	if(!sexcon || !sexcon.modular_chastity_content_enabled_for(source))
		return FALSE
	// Pick arousal-aware string key
	var/string_key = "manticore_tail_idle"
	if(sexcon.arousal > 50)
		string_key = "manticore_tail_aroused"
	var/message = pick_string_bank("manticore_tail_movement_messages.json", string_key, MANTICORE_TAIL_STRINGS_PATH, source)
	if(!message)
		return FALSE
	var/source_message = resolve_intimate_reaction_tokens_for_viewer(message, source, null, source)
	var/viewer_message = resolve_intimate_reaction_tokens_for_viewer(message, source, null, null)
	last_movement_message_time = world.time
	mark_reaction_fired(source, "movement")
	emit_intimate_reaction_message(source, span_warning(viewer_message), string_key, INTIMATE_AUDIENCE_SELF, require_intimate_accessories = TRUE, self_message = span_warning(source_message))
	return TRUE

/// Sex-action handler: sends a private flavor message about the tail's sensations during sex.
/// Routes to different string banks based on the receiver_part and action context.
/datum/component/intimate_reaction/manticore_tail/try_handle_wearer_sex_action_received(mob/living/carbon/human/source, mob/living/carbon/human/acting_mob, datum/sex_controller/acting_sexcon, datum/sex_action/action, receiver_part, giving, arousal_amt, pain_amt, applied_force, applied_speed)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_receive_flavor_time + receive_flavor_cooldown >= world.time)
		return FALSE
	if(!can_fire_reaction(source, "sex_received"))
		return FALSE
	if(!prob(15 + (applied_force * 4) + (applied_speed * 4)))
		return FALSE
	var/datum/sex_controller/sexcon = source.sexcon
	if(!sexcon || !sexcon.modular_chastity_content_enabled_for(source))
		return FALSE
	var/string_key = get_receive_flavor_key(receiver_part, action, sexcon)
	var/message = pick_string_bank("manticore_tail_receive_flavor.json", string_key, MANTICORE_TAIL_STRINGS_PATH, source)
	if(!message)
		return FALSE
	// Resolve [USER], [TARGET] etc. tokens — acting_mob is the "target" from our perspective
	var/source_message = resolve_intimate_reaction_tokens_for_viewer(message, source, acting_mob, source)
	var/viewer_message = resolve_intimate_reaction_tokens_for_viewer(message, source, acting_mob, null)
	var/partner_resolved_message = acting_mob ? resolve_intimate_reaction_tokens_for_viewer(message, source, acting_mob, acting_mob) : null
	last_receive_flavor_time = world.time
	mark_reaction_fired(source, "sex_received")
	emit_intimate_reaction_message(source, span_warning(viewer_message), string_key, INTIMATE_AUDIENCE_SELF, require_intimate_accessories = TRUE, partner = acting_mob, self_message = span_warning(source_message), partner_message = partner_resolved_message ? span_warning(partner_resolved_message) : null)
	return TRUE

/// Maps the receiver body part and action context to a JSON string key.
/// Falls back to "manticore_tail_penetrated" as the generic tail-involved key.
/datum/component/intimate_reaction/manticore_tail/proc/get_receive_flavor_key(receiver_part, datum/sex_action/action, datum/sex_controller/sexcon)
	// Tail-specific sex actions (tailjob, tailpegging) → wrapping
	if(istype(action, /datum/sex_action/tailjob) || istype(action, /datum/sex_action/chastityplay/tailprod_cage))
		return "manticore_tail_wrapping"
	// Tailpegging (tail inserted into someone) — the manticore feels penetration from their tail's perspective
	if(istype(action, /datum/sex_action/tailpegging_anal))
		return "manticore_tail_penetrated"
	// Oral contact with the tail
	if(istype(action, /datum/sex_action/cunnilingus) || istype(action, /datum/sex_action/facesitting))
		return "manticore_tail_oral"
	// Near climax — check arousal
	if(sexcon && sexcon.arousal > 85)
		return "manticore_tail_climax"
	// Default: generic penetration sensation
	return "manticore_tail_penetrated"

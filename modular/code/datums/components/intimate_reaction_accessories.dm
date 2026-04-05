// Component subtypes for intimate accessory reactions — piercings and insertable toys.
// See /datum/component/intimate_reaction for the base framework and authoring guide.

/// Local path to this module's string bank directory, passed to pick_string_bank() as the strings_path argument.
#define INTIMATE_ACCESSORY_STRINGS_PATH "modular/code/game/objects/items/lewd/intimate_accessory/strings"

/**
 * Reaction component for piercings.
 *
 * Produces coverage-aware jingle emotes on movement and private flavor text during sex actions.
 * Multiple piercing components may coexist on the same wearer simultaneously — see COMPONENT_DUPE_ALLOW_ALL.
 * Movement reactions only fire when the parent piercing has emits_movement_sound = TRUE (i.e. bell variants).
 * Plain bars, studs, hoops, and tongue piercings are silent during movement and never register a movement signal.
 */
/datum/component/intimate_reaction/piercing
	dupe_mode = COMPONENT_DUPE_ALLOWED
	movement_message_cooldown = 24 SECONDS
	/// Cooldown state for receive-flavor channel, separate from movement cooldown.
	var/last_receive_flavor_time = 0
	var/receive_flavor_cooldown = 20 SECONDS

/datum/component/intimate_reaction/piercing/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return .
	if(!istype(parent, /obj/item/intimate_accessory/piercing))
		return COMPONENT_INCOMPATIBLE

/// Binds the component to the wearer, registering movement reactions only for bell-style piercings.
/datum/component/intimate_reaction/piercing/bind_to_wearer(mob/living/carbon/human/H)
	var/already_bound = (wearer == H)
	. = ..()
	if(!.)
		return FALSE
	if(already_bound)
		return TRUE
	var/obj/item/intimate_accessory/piercing/piercing = parent
	// Only bell piercings (emits_movement_sound = TRUE) produce an audible visible_message jingle.
	// Plain bars, studs, hoops, and tongue bars are always silent during movement.
	if(piercing.emits_movement_sound)
		register_movement_reaction(H)
	return TRUE

/datum/component/intimate_reaction/piercing/unbind_from_wearer(mob/living/carbon/human/H)
	if(!H)
		H = wearer
	if(!H)
		return FALSE
	var/obj/item/intimate_accessory/piercing/piercing = parent
	if(piercing.emits_movement_sound)
		unregister_movement_reaction(H)
	return ..(H)

/// Extends base validity to confirm the parent piercing is still worn in its slot on the wearer.
/datum/component/intimate_reaction/piercing/is_valid_wearer_source(mob/living/carbon/human/source)
	if(!..())
		return FALSE
	var/obj/item/intimate_accessory/piercing/piercing = parent
	return piercing.get_worn_in_slot(source) == piercing

/// Returns the body zone constant for coverage checks based on the piercing's intimate slot.
/datum/component/intimate_reaction/piercing/proc/get_body_zone()
	var/obj/item/intimate_accessory/piercing/piercing = parent
	switch(piercing.get_effective_intimate_slot())
		if(INTIMATE_SLOT_BREAST)
			return BODY_ZONE_CHEST
		if(INTIMATE_SLOT_GENITAL, INTIMATE_SLOT_REAR)
			return BODY_ZONE_PRECISE_GROIN
	return null

/// Returns the movement string bank key for this piercing's slot and armor coverage tier.
/// Medium and heavy armor fully suppress the sound — returns null so no message fires.
/datum/component/intimate_reaction/piercing/proc/get_movement_string_key(mob/living/carbon/human/source)
	var/obj/item/intimate_accessory/piercing/piercing = parent
	var/slot = piercing.get_effective_intimate_slot()
	var/slot_name = null
	switch(slot)
		if(INTIMATE_SLOT_BREAST)
			slot_name = "breast"
		if(INTIMATE_SLOT_GENITAL)
			slot_name = "genital"
		if(INTIMATE_SLOT_REAR)
			slot_name = "rear"
		else
			return null // Mouth piercings produce no movement jingle.
	var/body_zone = get_body_zone()
	var/cover_tier = get_cover_tier_for_zone(source, body_zone)
	if(isnull(cover_tier))
		return "piercing_[slot_name]_bare"
	switch(cover_tier)
		if(ARMOR_CLASS_NONE)
			return "piercing_[slot_name]_cloth"
		if(ARMOR_CLASS_LIGHT)
			return "piercing_[slot_name]_light_armor"
	return null // Medium/heavy armor fully muffles the piercing jingle.

/// Returns the receive-flavor string bank key for this piercing's slot and action receiver_part bitfield.
/datum/component/intimate_reaction/piercing/proc/get_receive_flavor_key(mob/living/carbon/human/source, receiver_part)
	var/obj/item/intimate_accessory/piercing/piercing = parent
	switch(piercing.get_effective_intimate_slot())
		if(INTIMATE_SLOT_BREAST)
			return "piercing_breast_receive"
		if(INTIMATE_SLOT_GENITAL)
			if(receiver_part & SEX_PART_COCK)
				return "piercing_genital_cock_receive"
			if(receiver_part & (SEX_PART_CUNT | SEX_PART_SLIT_SHEATH))
				return "piercing_genital_cunt_receive"
			return "piercing_genital_general_receive"
		if(INTIMATE_SLOT_REAR)
			if(!(receiver_part & SEX_PART_ANUS))
				return null
			return "piercing_rear_receive"
		if(INTIMATE_SLOT_MOUTH)
			if(!(receiver_part & SEX_PART_JAWS))
				return null
			return "piercing_mouth_receive"
	return null

/// Movement handler: emits a coverage-graded jingle visible_message to nearby players.
/// Consults the mob-level reaction coordinator to prevent spam when multiple accessories are worn.
/datum/component/intimate_reaction/piercing/try_handle_wearer_moved(mob/living/carbon/human/source)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_movement_message_time + movement_message_cooldown >= world.time)
		return FALSE
	if(!can_fire_reaction(source, "movement"))
		return FALSE
	if(!prob(20))
		return FALSE
	var/datum/sex_controller/sexcon = source.sexcon
	if(!sexcon || !sexcon.modular_chastity_content_enabled_for(source))
		return FALSE
	var/string_key = get_movement_string_key(source)
	var/message = pick_string_bank("piercing_movement_messages.json", string_key, INTIMATE_ACCESSORY_STRINGS_PATH)
	if(!message)
		return FALSE
	last_movement_message_time = world.time
	mark_reaction_fired(source, "movement")
	// Jingle messages begin with "'s" and concatenate directly onto the name without a separating space.
	if(copytext(message, 1, 3) == "'s")
		source.visible_message(span_notice("[source][message]"))
	else
		source.visible_message(span_notice("[source] [message]"))
	return TRUE

/// Sex-action handler: sends a private flavor message to the wearer.
/// Consults the mob-level reaction coordinator to prevent spam when multiple accessories are worn.
/datum/component/intimate_reaction/piercing/try_handle_wearer_sex_action_received(mob/living/carbon/human/source, mob/living/carbon/human/acting_mob, datum/sex_controller/acting_sexcon, datum/sex_action/action, receiver_part, giving, arousal_amt, pain_amt, applied_force, applied_speed)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_receive_flavor_time + receive_flavor_cooldown >= world.time)
		return FALSE
	if(!can_fire_reaction(source, "sex_received"))
		return FALSE
	var/datum/sex_controller/sexcon = source.sexcon
	if(!sexcon || !sexcon.modular_chastity_content_enabled_for(source))
		return FALSE
	if(!prob(10 + (applied_force * 5) + (applied_speed * 5)))
		return FALSE
	var/string_key = get_receive_flavor_key(source, receiver_part)
	var/message = pick_string_bank("piercing_receive_flavor.json", string_key, INTIMATE_ACCESSORY_STRINGS_PATH)
	if(!message)
		return FALSE
	last_receive_flavor_time = world.time
	mark_reaction_fired(source, "sex_received")
	to_chat(source, span_warning(message))
	return TRUE

/**
 * Reaction component for insertable intimate accessories (vaginal plugs, rear plugs, anal beads).
 *
 * Sends private shift-sensation messages to the wearer on movement and private flavor text during
 * relevant sex actions. All messages are private — insertable sensations are interior and inaudible.
 */
/datum/component/intimate_reaction/insertable
	movement_message_cooldown = 30 SECONDS
	/// Cooldown state for receive-flavor channel.
	var/last_receive_flavor_time = 0
	var/receive_flavor_cooldown = 20 SECONDS

/datum/component/intimate_reaction/insertable/Initialize()
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE)
		return .
	if(!istype(parent, /obj/item/intimate_accessory))
		return COMPONENT_INCOMPATIBLE
	var/obj/item/intimate_accessory/accessory = parent
	if(!(accessory.intimate_flags & INTIMATE_FLAG_INSERTABLE))
		return COMPONENT_INCOMPATIBLE

/datum/component/intimate_reaction/insertable/bind_to_wearer(mob/living/carbon/human/H)
	var/already_bound = (wearer == H)
	. = ..()
	if(!.)
		return FALSE
	if(!already_bound)
		register_movement_reaction(H)
	return TRUE

/datum/component/intimate_reaction/insertable/unbind_from_wearer(mob/living/carbon/human/H)
	if(!H)
		H = wearer
	if(!H)
		return FALSE
	unregister_movement_reaction(H)
	return ..(H)

/// Extends base validity to confirm the insertable is still worn in its slot on the wearer.
/datum/component/intimate_reaction/insertable/is_valid_wearer_source(mob/living/carbon/human/source)
	if(!..())
		return FALSE
	var/obj/item/intimate_accessory/accessory = parent
	return accessory.get_worn_in_slot(source) == accessory

/// Returns the movement string bank key based on the insertable's intimate slot.
/datum/component/intimate_reaction/insertable/proc/get_movement_string_key()
	var/obj/item/intimate_accessory/accessory = parent
	switch(accessory.get_effective_intimate_slot())
		if(INTIMATE_SLOT_GENITAL)
			return "insertable_genital_shift"
		if(INTIMATE_SLOT_REAR)
			return "insertable_rear_shift"
	return null

/// Returns the receive-flavor string key for the current slot and receiver_part bitfield.
/datum/component/intimate_reaction/insertable/proc/get_receive_flavor_key(receiver_part)
	var/obj/item/intimate_accessory/accessory = parent
	switch(accessory.get_effective_intimate_slot())
		if(INTIMATE_SLOT_GENITAL)
			if(!(receiver_part & (SEX_PART_CUNT | SEX_PART_SLIT_SHEATH | SEX_PART_COCK)))
				return null
			return "insertable_genital_receive"
		if(INTIMATE_SLOT_REAR)
			if(!(receiver_part & SEX_PART_ANUS))
				return null
			return "insertable_rear_receive"
	return null

/// Movement handler: sends a private shift-sensation message to the wearer.
/// Consults the mob-level reaction coordinator to prevent spam when multiple accessories are worn.
/datum/component/intimate_reaction/insertable/try_handle_wearer_moved(mob/living/carbon/human/source)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_movement_message_time + movement_message_cooldown >= world.time)
		return FALSE
	if(!can_fire_reaction(source, "movement"))
		return FALSE
	if(!prob(15))
		return FALSE
	var/datum/sex_controller/sexcon = source.sexcon
	if(!sexcon || !sexcon.modular_chastity_content_enabled_for(source))
		return FALSE
	var/string_key = get_movement_string_key()
	var/message = pick_string_bank("insertable_movement_messages.json", string_key, INTIMATE_ACCESSORY_STRINGS_PATH)
	if(!message)
		return FALSE
	last_movement_message_time = world.time
	mark_reaction_fired(source, "movement")
	to_chat(source, span_warning(message))
	return TRUE

/// Sex-action handler: sends a private flavor message to the wearer.
/// Consults the mob-level reaction coordinator to prevent spam when multiple accessories are worn.
/datum/component/intimate_reaction/insertable/try_handle_wearer_sex_action_received(mob/living/carbon/human/source, mob/living/carbon/human/acting_mob, datum/sex_controller/acting_sexcon, datum/sex_action/action, receiver_part, giving, arousal_amt, pain_amt, applied_force, applied_speed)
	if(!is_valid_wearer_source(source))
		return FALSE
	if(source.stat != CONSCIOUS)
		return FALSE
	if(last_receive_flavor_time + receive_flavor_cooldown >= world.time)
		return FALSE
	if(!can_fire_reaction(source, "sex_received"))
		return FALSE
	var/datum/sex_controller/sexcon = source.sexcon
	if(!sexcon || !sexcon.modular_chastity_content_enabled_for(source))
		return FALSE
	if(!prob(12 + (applied_force * 4) + (applied_speed * 4)))
		return FALSE
	var/string_key = get_receive_flavor_key(receiver_part)
	var/message = pick_string_bank("insertable_receive_flavor.json", string_key, INTIMATE_ACCESSORY_STRINGS_PATH)
	if(!message)
		return FALSE
	last_receive_flavor_time = world.time
	mark_reaction_fired(source, "sex_received")
	to_chat(source, span_warning(message))
	return TRUE

#undef INTIMATE_ACCESSORY_STRINGS_PATH


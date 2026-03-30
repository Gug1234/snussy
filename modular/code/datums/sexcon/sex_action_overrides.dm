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

/**
 * Returns the first Eoran Jelly found on owner across all intimate slots.
 * Prioritises rear → genital → mouth → breast, then falls back to any strange jelly.
 * Used by asphyxiation, ear-fuck, oroboros, and other multi-slot tendril actions.
 */
/datum/sex_action/proc/get_any_eora_jelly(mob/living/carbon/human/owner)
	if(!owner)
		return null
	var/obj/item/intimate_accessory/jelly/eora/jelly
	jelly = get_rear_jelly(owner)
	if(jelly)
		return jelly
	jelly = get_genital_jelly(owner)
	if(jelly)
		return jelly
	jelly = get_mouth_jelly(owner)
	if(jelly)
		return jelly
	jelly = get_breast_jelly(owner)
	if(jelly)
		return jelly
	// Fallback: any strange jelly can sprout tendrils from wherever it sits.
	for(var/obj/item/intimate_accessory/jelly/eora/strange/strange_jelly as anything in owner.intimate_accessories)
		return strange_jelly
	return null

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
/**
 * Reads the player's stored suppress flag for this action+phase and returns
 * TRUE if the default game text should be skipped.
 *
 * Suppress flags are stored under:
 *   custom_sex_flavors["[type]"]["suppress"]["on_start"|"on_perform"|"on_finish"]
 *
 * A missing key is treated as FALSE (never suppress) so vanilla behaviour is
 * preserved for players who have never touched the editor.
 */
/datum/sex_action/proc/should_suppress_default(mob/living/carbon/human/user, phase)
	if(!user?.client?.prefs)
		return FALSE
	var/list/all_flavors = user.client.prefs.custom_sex_flavors
	if(!islist(all_flavors))
		return FALSE
	var/list/action_data = all_flavors["[type]"]
	if(!islist(action_data))
		return FALSE
	var/list/suppress_data = action_data["suppress"]
	if(!islist(suppress_data))
		return FALSE
	return !!suppress_data[phase]

/**
 * Modular start hook — fires immediately after on_start.
 * Emits a random custom flavor string to the user if they have one configured.
 */
/datum/sex_action/proc/modular_on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	try_emit_custom_sex_flavor(user, target, "on_start")

/**
 * Modular finish hook — fires immediately after on_finish.
 * Emits a random custom flavor string to the user if they have one configured.
 */
/datum/sex_action/proc/modular_on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	try_emit_custom_sex_flavor(user, target, "on_finish")

/**
 * Performs flavor text for modular_on_perform — mixed with the existing accessory flavor logic.
 * Custom string fires at 25% chance per cycle to prevent spam; accessory flavor at 20%.
 */
/datum/sex_action/proc/modular_on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!user || !target)
		return
	if(prob(25))
		try_emit_custom_sex_flavor(user, target, "on_perform")
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

/**
 * Reciprocal flavor text emission — players write text for EACH OTHER.
 *
 * Flow:
 *   1. Performer's "As Performer" strings → sent to the TARGET.
 *   2. Target's "As Target" strings → sent to the PERFORMER.
 *   3. Performer's "As Observer" strings → sent to nearby BYSTANDERS
 *      (only when the performer has suppress_defaults enabled for this phase).
 *
 * [USER] always resolves to the performer; [TARGET] always resolves to the target,
 * regardless of who is reading the message.
 *
 * Silently no-ops per-mob when:
 *   - the mob has no client/prefs
 *   - custom_sex_flavors is null or has no entries for this action+phase
 *
 * @param user   The performer mob.
 * @param target The target mob.
 * @param phase  One of "on_start", "on_perform", "on_finish".
 */
/datum/sex_action/proc/try_emit_custom_sex_flavor(mob/living/carbon/human/user, mob/living/carbon/human/target, phase)
	var/action_key = "[type]"
	// ── Performer's "As Performer" text → shown to the TARGET ──
	if(target && target != user)
		_emit_flavor_cross(user, target, user, target, action_key, phase, "performer")
	// ── Target's "As Target" text → shown to the PERFORMER ──
	if(target && target != user)
		_emit_flavor_cross(target, user, user, target, action_key, phase, "target")
	// ── Performer's "As Observer" text → shown to nearby BYSTANDERS ──
	// Only fires when the performer has suppression enabled (so vanilla
	// visible_message is muted and bystanders would otherwise see nothing).
	if(should_suppress_default(user, phase))
		_emit_observer_flavor(user, target, action_key, phase)

/**
 * Internal helper — picks a random string from `source`'s prefs under the
 * given `perspective` key, resolves tokens, and sends it to `recipient`.
 *
 * @param source      The mob whose prefs are read (the author of the text).
 * @param recipient   The mob who actually sees the chat message.
 * @param performer   The action performer (maps to [USER]).
 * @param target      The action target (maps to [TARGET]).
 * @param action_key  The action type path as text.
 * @param phase       "on_start", "on_perform", or "on_finish".
 * @param perspective "performer" or "target" — which sub-key in the prefs to read.
 */
/datum/sex_action/proc/_emit_flavor_cross(mob/living/carbon/human/source, mob/living/carbon/human/recipient, mob/living/carbon/human/performer, mob/living/carbon/human/target, action_key, phase, perspective)
	var/chosen = _pick_flavor_string(source, action_key, phase, perspective)
	if(!chosen)
		return
	chosen = resolve_sex_flavor_tokens(chosen, performer, target)
	_send_formatted(recipient, chosen, phase)

/**
 * Emits the performer's "observer" flavor text to all nearby mobs that are
 * NOT the performer or target (i.e. bystanders within view range).
 */
/datum/sex_action/proc/_emit_observer_flavor(mob/living/carbon/human/performer, mob/living/carbon/human/target, action_key, phase)
	var/chosen = _pick_flavor_string(performer, action_key, phase, "observer")
	if(!chosen)
		return
	chosen = resolve_sex_flavor_tokens(chosen, performer, target)
	// Send to all mobs in view that aren't the two participants.
	for(var/mob/M in viewers(performer))
		if(M == performer || M == target)
			continue
		if(!M.client)
			continue
		_send_formatted(M, chosen, phase)

/**
 * Picks a random weighted flavor string from `source`'s prefs.
 * Returns null if no eligible string is found.
 *
 * @param source      Mob whose prefs to read.
 * @param action_key  Action type path as string.
 * @param phase       "on_start" / "on_perform" / "on_finish".
 * @param perspective "performer", "target", or "observer".
 */
/datum/sex_action/proc/_pick_flavor_string(mob/living/carbon/human/source, action_key, phase, perspective)
	if(!source?.client?.prefs)
		return null
	var/list/all_flavors = source.client.prefs.custom_sex_flavors
	if(!islist(all_flavors))
		return null
	var/list/action_data = all_flavors[action_key]
	if(!islist(action_data))
		return null
	// Perspective-aware key: "performer_on_start", "target_on_perform", "observer_on_finish", etc.
	var/persp_phase = "[perspective]_[phase]"
	var/list/phase_strings = action_data[persp_phase]
	// Fallback to legacy un-prefixed key for backwards compatibility.
	if(!islist(phase_strings) || !phase_strings.len)
		phase_strings = action_data[phase]
	if(!islist(phase_strings) || !phase_strings.len)
		return null
	// Filter by per-string weight (parallel list, default 100%).
	var/weight_key = "weight_[persp_phase]"
	var/list/phase_weights = islist(action_data[weight_key]) ? action_data[weight_key] : null
	// Fallback to legacy un-prefixed weight key.
	if(!phase_weights)
		var/legacy_weight_key = "weight_[phase]"
		phase_weights = islist(action_data[legacy_weight_key]) ? action_data[legacy_weight_key] : null
	var/list/eligible = list()
	for(var/i in 1 to phase_strings.len)
		var/w = (phase_weights && i <= phase_weights.len) ? phase_weights[i] : 100
		if(prob(w))
			eligible += phase_strings[i]
	if(!eligible.len)
		return null
	return pick(eligible)

/**
 * Formats and sends a flavor string to a mob, matching vanilla sex action styling.
 */
/datum/sex_action/proc/_send_formatted(mob/recipient, chosen_text, phase)
	if(!recipient)
		return
	var/formatted
	if(phase == "on_perform")
		var/mob/living/carbon/human/H = ishuman(recipient) ? recipient : null
		formatted = H?.sexcon ? H.sexcon.spanify_force("<i>[chosen_text]</i>") : span_love("<i>[chosen_text]</i>")
	else
		formatted = span_warning("<i>[chosen_text]</i>")
	to_chat(recipient, formatted)

/**
 * Replaces player-written token placeholders in `text` with runtime values.
 *
 * Token table:
 *   \[USER\]    → user's real_name
 *   \[TARGET\]  → target's name (or "them" if null)
 *   \[THEY\]    → user's p_they()
 *   \[THEM\]    → user's p_them()
 *   \[THEIR\]   → user's p_their()
 *   \[TTHEY\]   → target's p_they() (or "they" if null)
 *   \[TTHEM\]   → target's p_them() (or "them" if null)
 *   \[TTHEIR\]  → target's p_their() (or "their" if null)
 *   \[FORCE\]   → force adjective derived from the user's sexcon.force level
 *   \[UCOCK\]   → user's penis type as descriptive phrase ("knotted cock", "cock", etc)
 *   \[TCOCK\]   → target's penis type phrase
 *   \[USHAFT\]  → user's penis type as shaft variant ("knotted shaft", "shaft", etc)
 *   \[TSHAFT\]  → target's penis type as shaft variant
 *
 * @param text   Raw string from the player's custom flavor pool.
 * @param user   The performer mob.
 * @param target The receiving mob (may be null).
 * @return       Resolved string safe to pass to to_chat/visible_message.
 */
/datum/sex_action/proc/resolve_sex_flavor_tokens(text, mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(!istext(text) || !user)
		return text

	// Derive force adjective from the sexcon's current force level.
	var/force_adj = "gently"
	var/datum/sex_controller/sexcon = user.sexcon
	if(sexcon)
		switch(sexcon.force)
			if(SEX_FORCE_MID)     force_adj = "firmly"
			if(SEX_FORCE_HIGH)    force_adj = "roughly"
			if(SEX_FORCE_EXTREME) force_adj = "savagely"

	// Bracket tokens must be escaped in DM string literals to prevent embed evaluation.
	text = replacetext(text, "\[USER\]",   user.real_name)
	text = replacetext(text, "\[TARGET\]", target ? target.real_name : "them")
	text = replacetext(text, "\[THEY\]",   user.p_they())
	text = replacetext(text, "\[THEM\]",   user.p_them())
	text = replacetext(text, "\[THEIR\]",  user.p_their())
	text = replacetext(text, "\[TTHEY\]",  target ? target.p_they()  : "they")
	text = replacetext(text, "\[TTHEM\]",  target ? target.p_them()  : "them")
	text = replacetext(text, "\[TTHEIR\]", target ? target.p_their() : "their")
	text = replacetext(text, "\[FORCE\]",  force_adj)

	// --- Anatomy-aware genital tokens ---
	// Uses the existing get_penis_type_label() proc from intimate reactions.
	// "cock" / "shaft" variants: "knotted cock", "barbed shaft", or just "cock" for plain.
	text = replacetext(text, "\[UCOCK\]",  _genital_descriptor(user, "cock"))
	text = replacetext(text, "\[TCOCK\]",  _genital_descriptor(target, "cock"))
	text = replacetext(text, "\[USHAFT\]", _genital_descriptor(user, "shaft"))
	text = replacetext(text, "\[TSHAFT\]", _genital_descriptor(target, "shaft"))

	// --- Penis size descriptor tokens ---
	// [USIZE] / [TSIZE] → visceral size descriptor (shaming for small, lusting for large).
	var/obj/item/organ/penis/u_penis = user.getorganslot(ORGAN_SLOT_PENIS)
	var/obj/item/organ/penis/t_penis = target ? target.getorganslot(ORGAN_SLOT_PENIS) : null
	text = replacetext(text, "\[USIZE\]", u_penis ? _penis_size_descriptor(u_penis.penis_size) : "unremarkable")
	text = replacetext(text, "\[TSIZE\]", t_penis ? _penis_size_descriptor(t_penis.penis_size) : "unremarkable")

	// --- Vagina type descriptor tokens ---
	// [UVAG] / [TVAG] → visceral vagina type descriptor based on sprite accessory.
	var/obj/item/organ/vagina/u_vagina = user.getorganslot(ORGAN_SLOT_VAGINA)
	var/obj/item/organ/vagina/t_vagina = target ? target.getorganslot(ORGAN_SLOT_VAGINA) : null
	text = replacetext(text, "\[UVAG\]", u_vagina ? _vagina_type_descriptor(u_vagina.accessory_type) : "a nondescript slit")
	text = replacetext(text, "\[TVAG\]", t_vagina ? _vagina_type_descriptor(t_vagina.accessory_type) : "a nondescript slit")

	// --- Breast descriptor tokens ---
	// [UCUPSIZE] / [TCUPSIZE] → fantasy-object size comparisons.
	// [UBREASTTYPE] / [TBREASTTYPE] → pair/quad/sextuple-aware full descriptors.
	var/obj/item/organ/breasts/u_breasts = user.getorganslot(ORGAN_SLOT_BREASTS)
	var/obj/item/organ/breasts/t_breasts = target ? target.getorganslot(ORGAN_SLOT_BREASTS) : null
	text = replacetext(text, "\[UCUPSIZE\]", u_breasts ? _breast_size_descriptor(u_breasts.breast_size) : "flat")
	text = replacetext(text, "\[TCUPSIZE\]", t_breasts ? _breast_size_descriptor(t_breasts.breast_size) : "flat")
	text = replacetext(text, "\[UBREASTTYPE\]", u_breasts ? _breast_type_descriptor(u_breasts.accessory_type, u_breasts.breast_size) : "a flat chest")
	text = replacetext(text, "\[TBREASTTYPE\]", t_breasts ? _breast_type_descriptor(t_breasts.accessory_type, t_breasts.breast_size) : "a flat chest")

	return text

/**
 * Builds a natural-language genital descriptor for a mob's penis type.
 * Combines the penis type label with the given noun ("cock", "shaft", etc).
 * Returns just the noun for plain-type or missing penises.
 *
 * Examples: "knotted cock", "tapered shaft", "barbed cock", "tentacle cock", "cock"
 */
/datum/sex_action/proc/_genital_descriptor(mob/living/carbon/human/H, noun = "cock")
	if(!H)
		return noun
	var/obj/item/organ/penis/penis = H.getorganslot(ORGAN_SLOT_PENIS)
	if(!penis)
		return noun
	var/label = get_penis_type_label(penis.penis_type)
	if(!label || label == "plain")
		return noun
	return "[label] [noun]"


// ═══════════════════════════════════════════════════════════════════════════
// Custom Action Slots — 5 generic datums that read config from player prefs
// at runtime, allowing players to define entirely new sex actions.
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Base type for custom action slots.
 * Each slot reads its configuration (name, flavor texts, stats) from the
 * user's `client.prefs.custom_sex_actions` list at runtime.
 *
 * These are registered in GLOB.sex_actions like any other action.
 * They appear in the menu only when the player has configured the slot.
 */
/datum/sex_action/custom
	abstract_type = /datum/sex_action/custom
	name = "Custom Action"
	do_time = 3.3 SECONDS
	stamina_cost = 1.0
	category = SEX_CATEGORY_MISC
	/// Which slot number this datum represents (1-5).
	var/slot_number = 0

/// Returns the config list for this slot from the user's preferences, or null.
/datum/sex_action/custom/proc/get_slot_config(mob/living/carbon/human/user)
	if(!user?.client?.prefs)
		return null
	var/list/actions = user.client.prefs.custom_sex_actions
	if(!islist(actions))
		return null
	for(var/list/entry in actions)
		if(entry["slot"] == slot_number)
			return entry
	return null

/datum/sex_action/custom/get_display_name(mob/living/carbon/human/user)
	var/list/config = get_slot_config(user)
	if(config)
		return config["name"]
	return name

/**
 * Validates unique requirement checks (chastity, toy, piercings, plugs) against
 * the current state of user and target. Called by both shows_on_menu and can_perform.
 * Returns FALSE if any configured requirement is not met.
 */
/datum/sex_action/custom/proc/check_requirements(list/config, mob/living/carbon/human/user, mob/living/carbon/human/target)
	// ── Chastity requirements ──
	var/req_uc = config["req_user_chastity"]
	if(req_uc == 1 && !user.chastity_device)
		return FALSE
	if(req_uc == 2 && user.chastity_device)
		return FALSE
	var/req_tc = config["req_target_chastity"]
	if(req_tc == 1 && !target.chastity_device)
		return FALSE
	if(req_tc == 2 && target.chastity_device)
		return FALSE

	// ── Toy requirement (user only) ──
	var/req_toy = config["req_toy"]
	if(req_toy == 1) // held dildo
		if(!get_dildo_in_either_hand(user))
			return FALSE
	else if(req_toy == 2) // mounted dildo (belt or chastity)
		if(!get_mounted_dildo(user))
			return FALSE
	else if(req_toy == 3) // any dildo
		if(!get_dildo_in_either_hand(user) && !get_mounted_dildo(user))
			return FALSE

	// ── User intimate accessory requirements ──
	if(config["req_user_piercing"])
		if(!istype(user.intimate_breast, /obj/item/intimate_accessory/piercing) \
			&& !istype(user.intimate_genital, /obj/item/intimate_accessory/piercing) \
			&& !istype(user.intimate_mouth, /obj/item/intimate_accessory/piercing))
			return FALSE
	if(config["req_user_plug"])
		if(!istype(user.intimate_rear, /obj/item/intimate_accessory/rear/plug) \
			&& !istype(user.intimate_genital, /obj/item/intimate_accessory/genital/plug))
			return FALSE

	// ── Target intimate accessory requirements ──
	if(config["req_target_piercing"])
		if(!istype(target.intimate_breast, /obj/item/intimate_accessory/piercing) \
			&& !istype(target.intimate_genital, /obj/item/intimate_accessory/piercing) \
			&& !istype(target.intimate_mouth, /obj/item/intimate_accessory/piercing))
			return FALSE
	if(config["req_target_plug"])
		if(!istype(target.intimate_rear, /obj/item/intimate_accessory/rear/plug) \
			&& !istype(target.intimate_genital, /obj/item/intimate_accessory/genital/plug))
			return FALSE

	// ── Rear plug block check ──
	if(config["req_no_rear_plug"])
		if(anal_blocked_by_rear_plug(user, target))
			return FALSE

	return TRUE

/datum/sex_action/custom/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return FALSE
	if(config["requires_other"] && user == target)
		return FALSE
	// Check user anatomy against configured user_sex_part.
	var/upart = config["user_sex_part"]
	if(upart & SEX_PART_COCK)
		if(!user.getorganslot(ORGAN_SLOT_PENIS))
			return FALSE
	if(upart & SEX_PART_CUNT)
		if(!user.getorganslot(ORGAN_SLOT_VAGINA))
			return FALSE
	// Check target anatomy against configured target_sex_part.
	var/tpart = config["target_sex_part"]
	if(tpart & SEX_PART_COCK)
		if(!target.getorganslot(ORGAN_SLOT_PENIS))
			return FALSE
	if(tpart & SEX_PART_CUNT)
		if(!target.getorganslot(ORGAN_SLOT_VAGINA))
			return FALSE
	// Validate unique requirement checks.
	if(!check_requirements(config, user, target))
		return FALSE
	return TRUE

/datum/sex_action/custom/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return FALSE
	if(config["requires_other"] && user == target)
		return FALSE
	if(!user.sexcon.Adjacent_Or_Closet(target))
		return FALSE
	// Re-validate requirements at perform time (equipment may change mid-act).
	if(!check_requirements(config, user, target))
		return FALSE
	return TRUE

/datum/sex_action/custom/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return
	log_game("CUSTOM_SEX_ACTION: [key_name(user)] used custom action '[config["name"]]' (slot [slot_number]) on [key_name(target)] at [AREACOORD(user)]")
	var/text = config["on_start_text"]
	if(istext(text) && length(text))
		text = resolve_sex_flavor_tokens(text, user, target)
		user.visible_message(span_warning(text))
	else
		user.visible_message(span_warning("[user] begins a custom act with [target]..."))

/datum/sex_action/custom/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return
	var/text = config["on_perform_text"]
	if(istext(text) && length(text))
		text = resolve_sex_flavor_tokens(text, user, target)
		user.visible_message(user.sexcon.spanify_force(text))
	else
		user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] continues the act with [target]."))
	// Apply configured stats.
	var/user_arousal = config["user_arousal"]
	var/target_arousal = config["target_arousal"]
	var/user_pain = config["user_pain"]
	var/target_pain = config["target_pain"]
	user.sexcon.perform_sex_action(user, user_arousal, user_pain, TRUE)
	user.sexcon.perform_sex_action(target, target_arousal, target_pain, FALSE)
	target.sexcon.handle_passive_ejaculation()

/datum/sex_action/custom/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return
	var/text = config["on_finish_text"]
	if(istext(text) && length(text))
		text = resolve_sex_flavor_tokens(text, user, target)
		user.visible_message(span_warning(text))
	else
		user.visible_message(span_warning("[user] stops the custom act with [target]."))

/datum/sex_action/custom/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/list/config = get_slot_config(user)
	if(!config)
		return TRUE
	if(!config["continuous"])
		return TRUE
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE

// ── Concrete slot subtypes (not abstract, so they register in GLOB.sex_actions)
/datum/sex_action/custom/slot_1
	name = "Custom Action 1"
	slot_number = 1

/datum/sex_action/custom/slot_2
	name = "Custom Action 2"
	slot_number = 2

/datum/sex_action/custom/slot_3
	name = "Custom Action 3"
	slot_number = 3

/datum/sex_action/custom/slot_4
	name = "Custom Action 4"
	slot_number = 4

/datum/sex_action/custom/slot_5
	name = "Custom Action 5"
	slot_number = 5

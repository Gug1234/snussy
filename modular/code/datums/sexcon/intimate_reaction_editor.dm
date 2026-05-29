/**
 * intimate_reaction_editor.dm — TGUI backend for the Intimate Reaction Text editor.
 *
 * Allows players to write per-character, per-category flavor strings for
 * movement descriptions, body exposure, and sex-action reactions. These
 * strings are displayed via the character_flavor component (see
 * intimate_reaction_character_flavor.dm) even without intimate accessories.
 *
 * Data is stored in datum/preferences.custom_intimate_reactions (see
 * preferences_intimate_reactions.dm) and persisted as JSON in the character savefile.
 *
 * Token placeholders resolved at runtime (see resolve_intimate_reaction_tokens):
 *   [USER]   [TARGET]  [THEY]  [THEM]  [THEIR]  [THEIR_CAP]
 *   [TTHEY]  [TTHEM]   [TTHEIR]
 *   [PENIS_TYPE]  [SHEATH]  [SIZEADJ]  [COCKSIZE]
 *   [VAGADJ]  [VAGTYPE]  [CUPADJ]  [CUPSIZE]  [BREASTTYPE]
 *   [TAUR]  [GENITAL_DESC]
 *
 * Categories:
 *   "movement"     — walk/move flavor (fires on COMSIG_MOVABLE_MOVED)
 *   "sex_received" — reaction text when receiving a sex action
 */

/// Root directory for character flavor fallback JSON banks (mirrors the component define).
#define INTIMATE_EDITOR_STRINGS_PATH "modular/code/datums/components/strings"
/// Root directory for piercing and insertable JSON banks.
#define INTIMATE_EDITOR_ACCESSORY_PATH "modular/code/game/objects/items/lewd/intimate_accessory/strings"
/// Root directory for chastity JSON banks.
#define INTIMATE_EDITOR_CHASTITY_PATH "modular/code/game/objects/items/lewd/chastity/strings"

/// Valid string bank IDs.
#define INTIMATE_REACTION_BANK_IDS list("character", "piercing", "insertable", "chastity", "manticore_tail")

/// IC verb available to any player with intimate reactions enabled.
/mob/living/carbon/human/verb/open_intimate_reaction_editor()
	set name = "Edit Intimate Reaction Text"
	set category = "IC"

	if(!client?.prefs)
		to_chat(src, span_warning("No preferences available."))
		return
	if(!client.prefs.intimate_reaction_enabled)
		to_chat(src, span_warning("Intimate reaction text is disabled in your ERP preferences."))
		return

	var/datum/intimate_reaction_editor/editor = new(src)
	editor.ui_interact(src)

// ---------------------------------------------------------------------------

/datum/intimate_reaction_editor
	/// The human who opened the editor.
	var/mob/living/carbon/human/owner
	/// Currently selected category key.
	var/selected_category = "movement"
	/// Currently selected string bank ID (one of INTIMATE_REACTION_BANK_IDS).
	var/selected_bank = "character"
	/// TRUE when in-memory data has changed since the last save.
	var/dirty = FALSE
	/// Session-local export/import panel state.
	var/datum/erp_chunked_export_panel_state/transfer_state

/datum/intimate_reaction_editor/New(mob/living/carbon/human/H)
	if(!istype(H))
		qdel(src)
		return
	owner = H
	transfer_state = new
	..()

/datum/intimate_reaction_editor/Destroy()
	if(dirty)
		var/datum/preferences/prefs = get_prefs()
		prefs?.save_character()
		dirty = FALSE
	QDEL_NULL(transfer_state)
	owner = null
	return ..()

/// Returns the preferences datum for the character being edited.
/// Overridden by the lobby subtype to return prefs directly.
/datum/intimate_reaction_editor/proc/get_prefs()
	if(owner?.client?.prefs)
		return owner.client.prefs
	return null

/// Returns TRUE if the editor session is still valid.
/datum/intimate_reaction_editor/proc/is_valid()
	return owner && !QDELETED(owner) && owner.client

/datum/intimate_reaction_editor/proc/get_transfer_state()
	if(!transfer_state)
		transfer_state = new
	return transfer_state

/**
 * Returns the full string bank definitions for the editor.
 * Banks are gated behind ERP toggles on the player's preferences.
 * Each bank contains a list of category definitions with JSON source info.
 */
/datum/intimate_reaction_editor/proc/get_bank_definitions(datum/preferences/prefs)
	var/static/list/banks
	if(!banks)
		banks = _build_bank_structure()
	// Apply per-call availability flags — the only dynamic part.
	banks["character"]["available"] = TRUE
	var/pierce_avail = !!(prefs?.intimate_enabled)
	banks["piercing"]["available"] = pierce_avail
	banks["insertable"]["available"] = pierce_avail
	banks["chastity"]["available"] = !!(prefs?.chastenable)
	banks["manticore_tail"]["available"] = pierce_avail
	return banks

/// Builds the static bank/category structure once. Called lazily by get_bank_definitions().
/datum/intimate_reaction_editor/proc/_build_bank_structure()
	var/list/banks = list()

	// ── Character bank ─────────────────────────────────────────────────
	// Tier-aware categories: each arousal tier gets its own movement + sex_received slots.
	var/list/character_categories = list()
	// Build tier-aware categories dynamically.
	var/static/list/tier_labels = list(
		INTIMATE_TIER_NEUTRAL     = "Neutral",
		INTIMATE_TIER_LUSTY       = "Lusty",
		INTIMATE_TIER_BUILDING    = "Building",
		INTIMATE_TIER_OVERWHELMED = "Overwhelmed",
		INTIMATE_TIER_AFTERGLOW   = "Afterglow",
		INTIMATE_TIER_WITHDRAWAL  = "Withdrawal",
		INTIMATE_TIER_ROUGHUSE    = "Rough-Use",
		INTIMATE_TIER_BROKEN      = "Broken",
	)
	var/static/list/tier_descs = list(
		INTIMATE_TIER_NEUTRAL     = "Default state — no arousal. Fires during normal movement and non-sexual touch.",
		INTIMATE_TIER_LUSTY       = "Low-to-moderate arousal. Fires when lust is present but hasn't peaked.",
		INTIMATE_TIER_BUILDING    = "High arousal, actively building toward climax.",
		INTIMATE_TIER_OVERWHELMED = "At or near climax. Peak arousal and orgasm.",
		INTIMATE_TIER_AFTERGLOW   = "Post-climax cooldown. Lust is dropping after orgasm.",
		INTIMATE_TIER_WITHDRAWAL  = "Frustrated arousal that was denied or interrupted — aroused with no outlet.",
		INTIMATE_TIER_ROUGHUSE    = "Being used roughly or forcefully during aggressive sex.",
		INTIMATE_TIER_BROKEN      = "Past the point of coherent reaction — extreme or repeated overstimulation.",
	)
	var/static/list/context_defs = list(
		list("suffix" = INTIMATE_CONTEXT_MOVEMENT, "label" = "Movement", "desc" = "Fires passively as you walk around; visibility follows this bank's audience setting.", "file" = "character_movement_messages.json", "json_key" = "character_movement"),
		list("suffix" = INTIMATE_CONTEXT_SEX_RECEIVED, "label" = "Sex Received", "desc" = "Fires when someone performs a sex action on you; visibility follows this bank's audience setting.", "file" = "character_sex_received_messages.json", "json_key" = "character_sex_received"),
		list("suffix" = INTIMATE_CONTEXT_ANAL_SEX_RECEIVED, "label" = "Anal Received", "desc" = "Fires when someone performs an anal action on you; visibility follows this bank's audience setting.", "file" = "character_sex_received_messages.json", "json_key" = "character_sex_received"),
	)
	for(var/tier in tier_labels)
		var/tier_label = tier_labels[tier]
		var/tier_desc = tier_descs[tier]
		for(var/list/ctx in context_defs)
			var/cat_key = "[tier]_[ctx["suffix"]]"
			character_categories += list(list(
				"key" = cat_key,
				"label" = "[tier_label] — [ctx["label"]]",
				"desc" = "[tier_desc] [ctx["desc"]]",
				"file" = ctx["file"],
				"json_key" = ctx["json_key"],
				"path" = INTIMATE_EDITOR_STRINGS_PATH,
			))

	banks["character"] = list(
		"label" = "Character",
		"desc" = "Your body's reactions to arousal and sex, organized by arousal stage and context (movement vs. receiving).",
		"available" = FALSE,
		"categories" = character_categories,
	)

	// ── Piercing bank ──────────────────────────────────────────────────
	banks["piercing"] = list(
		"label" = "Piercings",
		"desc" = "Reactions to piercing jewelry shifting against or stimulating your body during movement and sex.",
		"available" = FALSE,
		"categories" = list(
			list("key" = "piercing_breast_bare", "label" = "Breast Move (Bare)", "desc" = "Breast piercing shifting while exposed.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_breast_bare", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_breast_cloth", "label" = "Breast Move (Clothed)", "desc" = "Breast piercing rubbing under clothing.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_breast_cloth", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_breast_light_armor", "label" = "Breast Move (Lt. Armor)", "desc" = "Breast piercing pressing against light armor.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_breast_light_armor", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_bare", "label" = "Genital Move (Bare)", "desc" = "Genital piercing swinging freely while exposed.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_genital_bare", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_cloth", "label" = "Genital Move (Clothed)", "desc" = "Genital piercing catching on fabric.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_genital_cloth", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_light_armor", "label" = "Genital Move (Lt. Armor)", "desc" = "Genital piercing grinding against armor.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_genital_light_armor", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_bare", "label" = "Rear Move (Bare)", "desc" = "Rear piercing shifting while exposed.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_rear_bare", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_cloth", "label" = "Rear Move (Clothed)", "desc" = "Rear piercing rubbing under clothing.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_rear_cloth", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_light_armor", "label" = "Rear Move (Lt. Armor)", "desc" = "Rear piercing pressing against light armor.", "file" = "piercing_movement_messages.json", "json_key" = "piercing_rear_light_armor", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_breast_receive", "label" = "Breast Receive", "desc" = "Someone interacts with your breast piercing.", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_breast_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_cock_receive", "label" = "Genital Receive (Cock)", "desc" = "Someone interacts with your genital piercing (cock-specific).", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_genital_cock_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_cunt_receive", "label" = "Genital Receive (Cunt)", "desc" = "Someone interacts with your genital piercing (cunt-specific).", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_genital_cunt_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_general_receive", "label" = "Genital Receive (Gen.)", "desc" = "Someone interacts with your genital piercing (general).", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_genital_general_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_receive", "label" = "Rear Receive", "desc" = "Someone interacts with your rear piercing.", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_rear_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_mouth_receive", "label" = "Mouth Receive", "desc" = "Someone interacts with your mouth piercing.", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_mouth_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_gentle", "label" = "Tongue Oral (Gentle)", "desc" = "Visible tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_rough", "label" = "Tongue Oral (Rough)", "desc" = "Visible tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_silver_gentle", "label" = "Silver Tongue Oral (Gentle)", "desc" = "Visible silver tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_silver_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_silver_rough", "label" = "Silver Tongue Oral (Rough)", "desc" = "Visible silver tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_silver_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_psydonic_gentle", "label" = "Psydonic Tongue Oral (Gentle)", "desc" = "Visible psydonic tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_psydonic_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_psydonic_rough", "label" = "Psydonic Tongue Oral (Rough)", "desc" = "Visible psydonic tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_psydonic_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_psydonic_silver_gentle", "label" = "Silver Psydonic Tongue Oral (Gentle)", "desc" = "Visible silver-cross psydonic tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_psydonic_silver_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_psydonic_silver_rough", "label" = "Silver Psydonic Tongue Oral (Rough)", "desc" = "Visible silver-cross psydonic tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_psydonic_silver_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_psydonic_gold_gentle", "label" = "Gold Psydonic Tongue Oral (Gentle)", "desc" = "Visible golden-cross psydonic tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_psydonic_gold_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_psydonic_gold_rough", "label" = "Gold Psydonic Tongue Oral (Rough)", "desc" = "Visible golden-cross psydonic tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_psydonic_gold_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_zizite_gentle", "label" = "Zizite Tongue Oral (Gentle)", "desc" = "Visible zizite tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_zizite_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_zizite_rough", "label" = "Zizite Tongue Oral (Rough)", "desc" = "Visible zizite tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_zizite_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_zizite_ancient_gentle", "label" = "Ancient Zizite Tongue Oral (Gentle)", "desc" = "Visible ancient zizite tongue-piercing sound flavor during gentler oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_zizite_ancient_gentle", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "tongue_piercing_oral_zizite_ancient_rough", "label" = "Ancient Zizite Tongue Oral (Rough)", "desc" = "Visible ancient zizite tongue-piercing sound flavor during rougher oral actions.", "file" = "tongue_piercing_oral_messages.json", "json_key" = "tongue_piercing_oral_zizite_ancient_rough", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
		),
	)

	// ── Insertable (Plug) bank ─────────────────────────────────────────
	banks["insertable"] = list(
		"label" = "Plugs",
		"desc" = "Reactions to insertable toys (plugs) shifting during movement or being interacted with.",
		"available" = FALSE,
		"categories" = list(
			list("key" = "insertable_genital_shift", "label" = "Genital Plug Move", "desc" = "A plug in your genitals shifts as you walk.", "file" = "insertable_movement_messages.json", "json_key" = "insertable_genital_shift", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_rear_shift", "label" = "Rear Plug Move", "desc" = "A plug in your rear shifts as you walk.", "file" = "insertable_movement_messages.json", "json_key" = "insertable_rear_shift", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_sounding_shift", "label" = "Sounding Rod Move", "desc" = "A sounding rod in your urethra shifts as you walk.", "file" = "insertable_sounding_movement_messages.json", "json_key" = "insertable_sounding_shift", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_genital_receive", "label" = "Genital Plug Receive", "desc" = "Someone interacts with the plug in your genitals.", "file" = "insertable_receive_flavor.json", "json_key" = "insertable_genital_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_rear_receive", "label" = "Rear Plug Receive", "desc" = "Someone interacts with the plug in your rear.", "file" = "insertable_receive_flavor.json", "json_key" = "insertable_rear_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_sounding_receive", "label" = "Sounding Rod Receive", "desc" = "Someone interacts with the sounding rod in your urethra.", "file" = "insertable_sounding_receive_flavor.json", "json_key" = "insertable_sounding_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
		),
	)

	// ── Chastity bank ──────────────────────────────────────────────────
	banks["chastity"] = list(
		"label" = "Chastity",
		"desc" = "Reactions while wearing a chastity device — movement discomfort, frustrated arousal, and device interaction.",
		"available" = FALSE,
		"categories" = list(
			list("key" = "chastity_jingle_emotes", "label" = "Jingle (Bare)", "desc" = "The chastity device jingles audibly while you're exposed.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_emotes", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_movement_pain", "label" = "Move Pain", "desc" = "The device causes pain as you move.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_movement_pain", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_movement_struggle", "label" = "Move Struggle", "desc" = "You struggle against the device as you move.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_movement_struggle", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_cloth", "label" = "Jingle (Clothed)", "desc" = "The device jingles under clothing.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_cloth", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_light_armor", "label" = "Jingle (Lt. Armor)", "desc" = "The device jingles under light armor.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_light_armor", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_medium_armor", "label" = "Jingle (Med. Armor)", "desc" = "The device jingles under medium armor.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_medium_armor", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_heavy_armor", "label" = "Jingle (Hvy. Armor)", "desc" = "The device jingles under heavy armor.", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_heavy_armor", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_anal_receive", "label" = "Cock Anal", "desc" = "Anal sex while caged (cock).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_anal_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_general_receive", "label" = "Cock General", "desc" = "General sex while caged (cock).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_general_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_anal_receive", "label" = "Vagina Anal", "desc" = "Anal sex while belted (vagina).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_anal_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_anal_receive", "label" = "Intersex Anal", "desc" = "Anal sex while caged and belted (intersex).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_anal_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_general_receive", "label" = "Vagina General", "desc" = "General sex while belted (vagina).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_general_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_receive_devout", "label" = "Devout Receive", "desc" = "Sex/contact while devoutly wearing chastity.", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_receive_devout", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_general_receive", "label" = "Intersex General", "desc" = "General sex while caged and belted (intersex).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_general_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_masturbation", "label" = "Cock Masturbation", "desc" = "Attempting to masturbate while caged (cock).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_masturbation", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_masturbation", "label" = "Vagina Masturbation", "desc" = "Attempting to masturbate while belted (vagina).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_masturbation", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_masturbation", "label" = "Intersex Masturbation", "desc" = "Attempting to masturbate while caged and belted (intersex).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_masturbation", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_outercourse", "label" = "Cock Outercourse", "desc" = "Outercourse while caged (cock).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_outercourse", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_outercourse", "label" = "Vagina Outercourse", "desc" = "Outercourse while belted (vagina).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_outercourse", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_outercourse", "label" = "Intersex Outercourse", "desc" = "Outercourse while caged and belted (intersex).", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_outercourse", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_masturbation_devout", "label" = "Masturbation (Devout)", "desc" = "Attempting to masturbate while devoutly wearing chastity.", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_masturbation_devout", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_outercourse_devout", "label" = "Outercourse (Devout)", "desc" = "Outercourse while devoutly wearing chastity.", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_outercourse_devout", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
		),
	)

	// ── Manticore Tail bank ────────────────────────────────────────────
	banks["manticore_tail"] = list(
		"label" = "Manticore Tail",
		"desc" = "Reactions from your manticore stinger tail — idle fidgeting, aroused behavior, and sexual use.",
		"available" = FALSE,
		"categories" = list(
			list("key" = "manticore_tail_idle", "label" = "Tail Move (Idle)", "desc" = "The tail shifts and fidgets while you're unaroused.", "file" = "manticore_tail_movement_messages.json", "json_key" = "manticore_tail_idle", "path" = INTIMATE_EDITOR_STRINGS_PATH),
			list("key" = "manticore_tail_aroused", "label" = "Tail Move (Aroused)", "desc" = "The tail reacts while you're aroused.", "file" = "manticore_tail_movement_messages.json", "json_key" = "manticore_tail_aroused", "path" = INTIMATE_EDITOR_STRINGS_PATH),
			list("key" = "manticore_tail_penetrated", "label" = "Tail Penetrated", "desc" = "Something enters or stimulates the tail's opening.", "file" = "manticore_tail_receive_flavor.json", "json_key" = "manticore_tail_penetrated", "path" = INTIMATE_EDITOR_STRINGS_PATH),
			list("key" = "manticore_tail_wrapping", "label" = "Tail Wrapping", "desc" = "The tail wraps around someone or something.", "file" = "manticore_tail_receive_flavor.json", "json_key" = "manticore_tail_wrapping", "path" = INTIMATE_EDITOR_STRINGS_PATH),
			list("key" = "manticore_tail_oral", "label" = "Tail Oral", "desc" = "Oral contact with the tail.", "file" = "manticore_tail_receive_flavor.json", "json_key" = "manticore_tail_oral", "path" = INTIMATE_EDITOR_STRINGS_PATH),
			list("key" = "manticore_tail_climax", "label" = "Tail Climax", "desc" = "The tail's reaction during orgasm.", "file" = "manticore_tail_receive_flavor.json", "json_key" = "manticore_tail_climax", "path" = INTIMATE_EDITOR_STRINGS_PATH),
		),
	)

	return banks

/**
 * Returns the category definitions for the currently selected bank.
 */
/datum/intimate_reaction_editor/proc/get_current_bank_categories()
	var/datum/preferences/prefs = get_prefs()
	var/list/banks = get_bank_definitions(prefs)
	var/list/bank = banks[selected_bank]
	if(!bank)
		return list()
	return bank["categories"]

/// Returns the runtime default audience for a category when no user override exists.
/datum/intimate_reaction_editor/proc/get_default_audience_for_category(category)
	if(!istext(category))
		return INTIMATE_AUDIENCE_SELF
	if(selected_bank == "character" || selected_bank == "insertable" || selected_bank == "manticore_tail")
		return INTIMATE_AUDIENCE_SELF
	if(selected_bank == "chastity")
		if(findtext(category, "jingle_") || findtext(category, "_movement_"))
			return INTIMATE_AUDIENCE_VIEW
		return INTIMATE_AUDIENCE_SELF
	if(selected_bank == "piercing")
		if(findtext(category, "_receive"))
			return INTIMATE_AUDIENCE_SELF
		return INTIMATE_AUDIENCE_VIEW
	return INTIMATE_AUDIENCE_SELF

/**
 * Returns a flat list of all valid category keys across all banks.
 * Used for validation — accepts any category from any bank regardless of toggles.
 */
/datum/intimate_reaction_editor/proc/get_all_valid_categories()
	return get_all_intimate_reaction_categories()

/**
 * Global proc returning a cached flat list of every valid intimate reaction
 * category key across all banks. Safe to call from the validator without
 * needing an editor instance — builds the list lazily on first call by
 * instantiating a temporary editor datum to access the static bank cache.
 */
/proc/get_all_intimate_reaction_categories()
	var/static/list/all_categories
	if(!all_categories)
		all_categories = list()
		// Temporarily bypass the istype check by creating a bare datum.
		// get_bank_definitions() only needs the static cache, not an owner.
		var/datum/intimate_reaction_editor/tmp_editor = new /datum/intimate_reaction_editor()
		var/list/banks = tmp_editor?.get_bank_definitions(null)
		for(var/bank_id in banks)
			var/list/bank = banks[bank_id]
			var/list/cats = bank["categories"]
			for(var/list/cat_def in cats)
				all_categories += cat_def["key"]
		qdel(tmp_editor)
	return all_categories

/datum/intimate_reaction_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntimateReactionEditor", "Intimate Reaction Editor", 720, 620)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/intimate_reaction_editor/ui_static_data(mob/user)
	var/list/data = list()

	data["max_strings"] = INTIMATE_REACTION_MAX_STRINGS
	data["max_length"]  = INTIMATE_REACTION_MAX_LENGTH

	// Token reference for the frontend help panel.
	data["tokens"] = list(
		"\[USER]", "\[TARGET]", "\[THEY]", "\[THEM]", "\[THEIR]", "\[THEIR_CAP]",
		"\[TTHEY]", "\[TTHEM]", "\[TTHEIR]",
		"\[PENIS_TYPE]", "\[SHEATH]", "\[SIZEADJ]", "\[COCKSIZE]",
		"\[VAGADJ]", "\[VAGTYPE]", "\[CUPADJ]", "\[CUPSIZE]", "\[BREASTTYPE]",
		"\[TAUR]", "\[GENITAL_DESC]",
		"\[FORCE]", "\[PLUG]",
	)

	data["audience_options"] = list(
		list("id" = INTIMATE_AUDIENCE_SELF, "label" = "Self", "desc" = "Only you see this reaction."),
		list("id" = INTIMATE_AUDIENCE_PARTNER, "label" = "Partner", "desc" = "You and the active sex partner see this reaction. Movement has no partner and stays self-only."),
		list("id" = INTIMATE_AUDIENCE_NEARBY, "label" = "Nearby", "desc" = "Shown in the immediate 3x3 around you."),
		list("id" = INTIMATE_AUDIENCE_VIEW, "label" = "View", "desc" = "Shown to anyone in normal visible-message range."),
	)

	return data

/datum/intimate_reaction_editor/ui_data(mob/user)
	var/list/data = list()

	if(!is_valid())
		data["invalid"] = TRUE
		return data

	var/datum/preferences/prefs = get_prefs()
	if(!prefs)
		data["invalid"] = TRUE
		return data

	data["selected_category"] = selected_category
	data["selected_bank"]     = selected_bank
	data["dirty"]             = dirty
	data["preview_tokens"]    = prefs.get_erp_preview_tokens()
	var/datum/erp_chunked_export_panel_state/transfer = get_transfer_state()
	data["export_text"] = transfer.export_text
	data["export_chunk_count"] = transfer.export_chunk_count
	data["export_payload_bytes"] = transfer.export_payload_bytes
	data["status_text"] = transfer.status_text
	data["status_kind"] = transfer.status_kind
	data["max_import_text_bytes"] = ERP_EXPORT_MAX_IMPORT_TEXT_LENGTH

	// ── Build bank list for the dropdown ──────────────────────────────
	var/list/bank_defs = get_bank_definitions(prefs)
	var/list/banks_out = list()
	for(var/bank_id in bank_defs)
		var/list/bdef = bank_defs[bank_id]
		var/list/bank_entry = list(
			"id"        = bank_id,
			"label"     = bdef["label"],
			"available" = bdef["available"],
		)
		if(bdef["desc"])
			bank_entry["desc"] = bdef["desc"]
		banks_out += list(bank_entry)
	data["banks"] = banks_out

	// ── Build category list for the selected bank ─────────────────────
	var/list/cat_defs = get_current_bank_categories()
	var/list/all_reactions = islist(prefs.custom_intimate_reactions) ? prefs.custom_intimate_reactions : list()
	var/list/categories = list()
	for(var/list/cdef in cat_defs)
		var/cat_key = cdef["key"]
		var/list/cat_strings = all_reactions[cat_key]
		var/count = islist(cat_strings) ? cat_strings.len : 0
		var/default_audience = get_default_audience_for_category(cat_key)
		var/list/cat_entry = list(
			"key"   = cat_key,
			"label" = cdef["label"],
			"count" = count,
			"default_audience" = default_audience,
			"audience" = prefs.get_intimate_reaction_audience(cat_key, default_audience),
		)
		if(cdef["desc"])
			cat_entry["desc"] = cdef["desc"]
		if(cdef["hidden"])
			cat_entry["hidden"] = TRUE
		if(cdef["group"])
			cat_entry["group"] = cdef["group"]
		categories += list(cat_entry)
	data["categories"] = categories

	// ── Current strings for the selected category ─────────────────────
	var/list/current_strings = list()
	if(islist(all_reactions[selected_category]))
		current_strings = all_reactions[selected_category]
	data["current_strings"] = current_strings

	// ── Current weights for the selected category ─────────────────────
	var/list/current_weights = list()
	var/weight_key = "weight_[selected_category]"
	if(islist(all_reactions[weight_key]))
		current_weights = all_reactions[weight_key]
	// Pad weights to match string count, defaulting to 100.
	while(current_weights.len < current_strings.len)
		current_weights += 100
	data["current_weights"] = current_weights
	var/current_default_audience = get_default_audience_for_category(selected_category)
	data["current_audience_default"] = current_default_audience
	data["current_audience"] = prefs.get_intimate_reaction_audience(selected_category, current_default_audience)

	// ── Default strings from JSON bank ────────────────────────────────
	var/list/default_strings = list()
	// Find current category definition to get JSON source info
	for(var/list/cdef in cat_defs)
		if(cdef["key"] == selected_category && cdef["file"] && cdef["path"])
			// Load the file into the global cache (no-op if already cached),
			// then look up the key directly. This avoids strings() which
			// CRASH()s on missing keys — and BYOND's try/catch does not
			// reliably catch CRASH().
			load_strings_file(cdef["file"], cdef["path"])
			if((cdef["file"] in GLOB.string_cache) && (cdef["json_key"] in GLOB.string_cache[cdef["file"]]))
				var/list/loaded = GLOB.string_cache[cdef["file"]][cdef["json_key"]]
				if(islist(loaded))
					default_strings = loaded
			break
	data["default_strings"] = default_strings

	return data

/datum/intimate_reaction_editor/proc/apply_import_payload_text(raw, mob/user)
	var/datum/erp_chunked_export_panel_state/transfer = get_transfer_state()
	if(!istext(raw) || !length(trim(raw)))
		transfer.set_status("Import failed: empty payload.", "danger")
		return FALSE

	var/list/chunk_result = parse_chunked_export_chunks(trim(raw), ERP_EXPORT_KIND_REACTIONS)
	if(!chunk_result["ok"])
		transfer.set_status(chunk_result["message"], "danger")
		return FALSE

	var/decoded_str = chunk_result["payload"]
	var/list/payload
	try
		payload = json_decode(decoded_str)
	catch
		transfer.set_status("Import failed: invalid JSON data.", "danger")
		return FALSE
	if(!islist(payload) || !islist(payload["reactions"]))
		transfer.set_status("Import failed: unexpected data format.", "danger")
		return FALSE

	var/datum/preferences/prefs = get_prefs()
	if(!prefs)
		transfer.set_status("Import failed: preferences are unavailable.", "danger")
		return FALSE

	var/before_count = islist(prefs.custom_intimate_reactions) ? prefs.custom_intimate_reactions.len : 0
	prefs.custom_intimate_reactions = payload["reactions"]
	prefs.validate_custom_intimate_reactions()
	var/after_count = islist(prefs.custom_intimate_reactions) ? prefs.custom_intimate_reactions.len : 0
	prefs.save_character()
	dirty = FALSE
	transfer.clear_export()
	transfer.set_status("Import successful: intimate reaction strings updated ([before_count] -> [after_count] categories).", "success")
	var/mob/log_user = user
	if(!log_user)
		log_user = usr
	log_game("INTIMATE_EDITOR: [key_name(log_user)] imported payload bytes=[length(decoded_str)] before=[before_count] after=[after_count] hash=[md5(decoded_str)]")
	return TRUE

/datum/intimate_reaction_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(!is_valid())
		return FALSE

	var/datum/preferences/prefs = get_prefs()
	if(!prefs)
		return FALSE

	switch(action)
		if("change_bank")
			var/bank_id = params["bank"]
			if(!(bank_id in INTIMATE_REACTION_BANK_IDS))
				return FALSE
			selected_bank = bank_id
			// Reset category to the first in this bank.
			var/list/cat_defs = get_current_bank_categories()
			if(length(cat_defs))
				var/list/first = cat_defs[1]
				selected_category = first["key"]
			return TRUE

		if("select_category")
			var/cat = params["category"]
			// Validate against the current bank's categories.
			var/list/cat_defs = get_current_bank_categories()
			var/valid = FALSE
			for(var/list/cdef in cat_defs)
				if(cdef["key"] == cat)
					valid = TRUE
					break
			if(!valid)
				return FALSE
			selected_category = cat
			return TRUE

		if("set_audience")
			var/audience = params["audience"]
			var/default_audience = get_default_audience_for_category(selected_category)
			if(!prefs.set_intimate_reaction_audience(selected_category, audience, default_audience))
				return FALSE
			dirty = TRUE
			return TRUE

		if("refresh_preview_tokens")
			if(!prefs.refresh_erp_preview_tokens_from_preferences())
				return FALSE
			dirty = TRUE
			return TRUE

		if("set_preview_target_preset")
			if(!prefs.set_erp_preview_token("target_preset", params["preset"]))
				return FALSE
			dirty = TRUE
			return TRUE

		if("set_preview_token")
			if(!prefs.set_erp_preview_token(params["key"], params["value"]))
				return FALSE
			dirty = TRUE
			return TRUE

		if("add_string")
			var/new_str = strip_html_simple(sanitize_simple(params["text"]))
			if(!istext(new_str) || !length(new_str))
				return FALSE
			new_str = copytext(new_str, 1, INTIMATE_REACTION_MAX_LENGTH + 1)
			// Initialize list structure on demand.
			if(!islist(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = list()
			if(!islist(prefs.custom_intimate_reactions[selected_category]))
				prefs.custom_intimate_reactions[selected_category] = list()
			var/list/cat_list = prefs.custom_intimate_reactions[selected_category]
			if(cat_list.len >= INTIMATE_REACTION_MAX_STRINGS)
				return FALSE
			cat_list += new_str
			dirty = TRUE
			return TRUE

		if("remove_string")
			var/idx = text2num(params["index"])
			if(!idx || idx < 1)
				return FALSE
			if(!islist(prefs.custom_intimate_reactions))
				return FALSE
			var/list/cat_list = prefs.custom_intimate_reactions[selected_category]
			if(!islist(cat_list) || idx > cat_list.len)
				return FALSE
			cat_list.Cut(idx, idx + 1)
			// Also remove the corresponding weight entry.
			var/weight_key = "weight_[selected_category]"
			var/list/weight_list = prefs.custom_intimate_reactions[weight_key]
			if(islist(weight_list) && idx <= weight_list.len)
				weight_list.Cut(idx, idx + 1)
				if(!weight_list.len)
					prefs.custom_intimate_reactions.Remove(weight_key)
			// Clean up empty category.
			if(!cat_list.len)
				prefs.custom_intimate_reactions.Remove(selected_category)
			if(!length(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = null
			dirty = TRUE
			return TRUE

		if("update_string")
			// Replace an existing custom string at a given index (1-based).
			var/idx = text2num(params["index"])
			if(!idx || idx < 1)
				return FALSE
			var/new_str = strip_html_simple(sanitize_simple(params["text"]))
			if(!istext(new_str) || !length(new_str))
				return FALSE
			new_str = copytext(new_str, 1, INTIMATE_REACTION_MAX_LENGTH + 1)
			if(!islist(prefs.custom_intimate_reactions))
				return FALSE
			var/list/cat_list = prefs.custom_intimate_reactions[selected_category]
			if(!islist(cat_list) || idx > cat_list.len)
				return FALSE
			cat_list[idx] = new_str
			dirty = TRUE
			return TRUE

		if("clear_category")
			if(!islist(prefs.custom_intimate_reactions))
				return FALSE
			var/list/cleared_cat = prefs.custom_intimate_reactions[selected_category]
			var/cleared_count = islist(cleared_cat) ? cleared_cat.len : 0
			prefs.custom_intimate_reactions.Remove(selected_category)
			prefs.custom_intimate_reactions.Remove("weight_[selected_category]")
			if(!length(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = null
			dirty = TRUE
			log_game("INTIMATE_EDITOR: [key_name(usr)] cleared category=[selected_category] ([cleared_count] strings removed)")
			return TRUE

		// ── Export / Import ──────────────────────────────────────────────
		/**
		 * Export and Import allow players to share their custom intimate
		 * reaction strings as a chunked portable export.
		 *
		 * ## Format
		 * The chunk payload reassembles to a JSON object with one key:
		 *   { "reactions": { "movement": [...], "sex_received": [...], ... } }
		 *
		 * ## How to use
		 * 1. Click **Export** to copy your data string to the BYOND output.
		 * 2. Copy the string and send it to another player.
		 * 3. The receiving player clicks **Import**, pastes the string, and
		 *    confirms. Their existing data is **replaced** — not merged.
		 *
		 * The string is not human-readable; editing by hand will corrupt it.
		 */
		if("generate_export", "export_data")
			var/datum/erp_chunked_export_panel_state/transfer = get_transfer_state()
			if(!islist(prefs.custom_intimate_reactions) || !length(prefs.custom_intimate_reactions))
				transfer.clear_export()
				transfer.set_status("Nothing to export: no custom intimate reaction strings configured.", "danger")
				return TRUE
			var/json_str = json_encode(list("reactions" = prefs.custom_intimate_reactions))
			transfer.set_export_from_payload(ERP_EXPORT_KIND_REACTIONS, json_str, "Intimate reaction")
			return TRUE

		if("clear_export")
			var/datum/erp_chunked_export_panel_state/transfer = get_transfer_state()
			transfer.clear_export()
			transfer.set_status("Export text cleared.", "info")
			return TRUE

		if("import_data")
			return apply_import_payload_text(params["payload"], ui?.user || usr)

		if("begin_import_payload")
			var/datum/erp_chunked_export_panel_state/transfer = get_transfer_state()
			transfer.begin_import_payload(params["chunk_count"], params["text_length"])
			return TRUE

		if("append_import_payload_chunk")
			var/datum/erp_chunked_export_panel_state/transfer = get_transfer_state()
			var/list/import_result = transfer.append_import_payload_chunk(params["chunk_index"], params["chunk_count"], params["chunk"])
			if(import_result["complete"])
				apply_import_payload_text(import_result["payload"], ui?.user || usr)
			return TRUE

		// ── Weight adjustment ────────────────────────────────────────────
		if("set_weight")
			var/idx = text2num(params["index"])
			if(!idx || idx < 1)
				return FALSE
			var/weight = clamp(text2num(params["weight"]), 0, 100)
			if(!islist(prefs.custom_intimate_reactions))
				return FALSE
			var/list/cat_list = prefs.custom_intimate_reactions[selected_category]
			if(!islist(cat_list) || idx > cat_list.len)
				return FALSE
			var/weight_key = "weight_[selected_category]"
			if(!islist(prefs.custom_intimate_reactions[weight_key]))
				prefs.custom_intimate_reactions[weight_key] = list()
			var/list/weight_list = prefs.custom_intimate_reactions[weight_key]
			// Pad weight list to match string count.
			while(weight_list.len < cat_list.len)
				weight_list += 100
			weight_list[idx] = weight
			dirty = TRUE
			return TRUE

		if("save")
			if(dirty)
				prefs.save_character()
				dirty = FALSE
			return TRUE

	return FALSE

// ── Lobby subtype ────────────────────────────────────────────────────────────
/**
 * Lobby-side intimate reaction editor that operates purely on preference data.
 * No spawned mob is needed — used during character creation.
 */
/datum/intimate_reaction_editor/lobby
	/// Direct reference to the character's preferences datum.
	var/datum/preferences/prefs

/datum/intimate_reaction_editor/lobby/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P
	// Skip parent New() — it expects a human mob.

/datum/intimate_reaction_editor/lobby/Destroy()
	prefs = null
	return ..()

/datum/intimate_reaction_editor/lobby/get_prefs()
	return prefs

/datum/intimate_reaction_editor/lobby/is_valid()
	return !!prefs

/datum/intimate_reaction_editor/lobby/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntimateReactionEditor", "Intimate Reaction Editor", 720, 620)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/intimate_reaction_editor/lobby/ui_state(mob/user)
	return GLOB.always_state

#undef INTIMATE_EDITOR_STRINGS_PATH
#undef INTIMATE_EDITOR_ACCESSORY_PATH
#undef INTIMATE_EDITOR_CHASTITY_PATH
#undef INTIMATE_REACTION_BANK_IDS

/datum/intimate_reaction_editor/ui_close(mob/user)
	var/client/C = user?.client
	if(C)
		addtimer(CALLBACK(C, TYPE_PROC_REF(/client, prefs_resume_after_singleton)), 1)
	return ..()

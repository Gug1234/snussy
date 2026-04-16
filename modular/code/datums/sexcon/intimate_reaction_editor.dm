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
/// Root directory for jelly JSON banks.
#define INTIMATE_EDITOR_JELLY_PATH "modular/code/game/objects/items/lewd/intimate_accessory/strings"
/// Root directory for preset template JSON files.
#define INTIMATE_EDITOR_PRESETS_PATH "modular/code/datums/sexcon/strings"

/// Valid string bank IDs.
#define INTIMATE_REACTION_BANK_IDS list("character", "piercing", "insertable", "chastity", "manticore_tail", "jelly")

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
	/// Feedback message from the last preset load attempt (cleared on next ui_data).
	var/preset_result
	/// Whether the last preset result was a success (TRUE) or failure (FALSE).
	var/preset_result_success = FALSE
	/// The last resolved preview text (cleared when a new preview is requested).
	var/resolved_preview_text
	/// TRUE when in-memory data has changed since the last save.
	var/dirty = FALSE

/datum/intimate_reaction_editor/New(mob/living/carbon/human/H)
	if(!istype(H))
		qdel(src)
		return
	owner = H
	..()

/datum/intimate_reaction_editor/Destroy()
	if(dirty)
		var/datum/preferences/prefs = get_prefs()
		prefs?.save_character()
		dirty = FALSE
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
	banks["jelly"]["available"] = pierce_avail
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
		list("suffix" = INTIMATE_CONTEXT_MOVEMENT, "label" = "Movement", "desc" = "Fires passively as you walk around. Only you see these."),
		list("suffix" = INTIMATE_CONTEXT_SEX_RECEIVED, "label" = "Sex Received", "desc" = "Fires when someone performs a sex action on you. Only you see these."),
		list("suffix" = INTIMATE_CONTEXT_ANAL_SEX_RECEIVED, "label" = "Anal Received", "desc" = "Fires when someone performs an anal action on you. Only you see these."),
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
				"file" = "intimate_reaction_presets.json",
				"json_key" = cat_key,
				"path" = INTIMATE_EDITOR_PRESETS_PATH,
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

	// ── Jelly bank ─────────────────────────────────────────────────────
	banks["jelly"] = list(
		"label" = "Eora Jelly",
		"desc" = "Reactions from your bonded Eora jelly parasite — moods, feeding, autonomy, cocoon events, and more.",
		"available" = FALSE,
		"categories" = list(
			// ── Mood emotes (visible + self pairs) ──
			list("key" = "sated_visible", "label" = "Sated (Visible)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "sated_visible", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "sated_self", "label" = "Sated (Self)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "sated_self", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "needy_visible", "label" = "Needy (Visible)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "needy_visible", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "needy_self", "label" = "Needy (Self)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "needy_self", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "jealous_visible", "label" = "Jealous (Visible)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "jealous_visible", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "jealous_self", "label" = "Jealous (Self)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "jealous_self", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "resentful_visible", "label" = "Resentful (Visible)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "resentful_visible", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "resentful_self", "label" = "Resentful (Self)", "group" = "Mood", "file" = "jelly_mood_emotes.json", "json_key" = "resentful_self", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Ambient messages ──
			list("key" = "ambient_insistence", "label" = "Insistence", "group" = "Ambient", "file" = "jelly_ambient_messages.json", "json_key" = "ambient_insistence", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "removal_resist", "label" = "Removal Resist", "group" = "Ambient", "file" = "jelly_ambient_messages.json", "json_key" = "removal_resist", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Feeding flavor templates ──
			list("key" = "feeding_passive", "label" = "Passive", "group" = "Feeding", "file" = "jelly_feeding_messages.json", "json_key" = "feeding_passive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "feeding_aggressive", "label" = "Aggressive", "group" = "Feeding", "file" = "jelly_feeding_messages.json", "json_key" = "feeding_aggressive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "feeding_orgasm", "label" = "Orgasm", "group" = "Feeding", "file" = "jelly_feeding_messages.json", "json_key" = "feeding_orgasm", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "feeding_cocoon_tendril", "label" = "Cocoon Tendril", "group" = "Feeding", "file" = "jelly_feeding_messages.json", "json_key" = "feeding_cocoon_tendril", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "feeding_sated_pulse", "label" = "Sated Pulse", "group" = "Feeding", "file" = "jelly_feeding_messages.json", "json_key" = "feeding_sated_pulse", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Sated reward flavor templates ──
			list("key" = "sated_reward_tier0", "label" = "Tier 0", "group" = "Sated Rewards", "file" = "jelly_sated_reward_messages.json", "json_key" = "sated_reward_tier0", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "sated_reward_tier1", "label" = "Tier 1", "group" = "Sated Rewards", "file" = "jelly_sated_reward_messages.json", "json_key" = "sated_reward_tier1", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "sated_reward_tier2", "label" = "Tier 2", "group" = "Sated Rewards", "file" = "jelly_sated_reward_messages.json", "json_key" = "sated_reward_tier2", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "sated_reward_tier3", "label" = "Tier 3", "group" = "Sated Rewards", "file" = "jelly_sated_reward_messages.json", "json_key" = "sated_reward_tier3", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Resentment flavor templates ──
			list("key" = "resentment_pain", "label" = "Pain", "group" = "Resentment", "file" = "jelly_resentment_messages.json", "json_key" = "resentment_pain", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "resentment_sabotage", "label" = "Sabotage", "group" = "Resentment", "file" = "jelly_resentment_messages.json", "json_key" = "resentment_sabotage", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "resentment_refusal", "label" = "Refusal", "group" = "Resentment", "file" = "jelly_resentment_messages.json", "json_key" = "resentment_refusal", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "resentment_denial", "label" = "Denial", "group" = "Resentment", "file" = "jelly_resentment_messages.json", "json_key" = "resentment_denial", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Rivalry flavor templates ──
			list("key" = "rivalry_detected", "label" = "Detected", "group" = "Rivalry", "file" = "jelly_rivalry_messages.json", "json_key" = "rivalry_detected", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "rivalry_during_cocoon", "label" = "Cocoon", "group" = "Rivalry", "file" = "jelly_rivalry_messages.json", "json_key" = "rivalry_during_cocoon", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "rivalry_escalation", "label" = "Escalation", "group" = "Rivalry", "file" = "jelly_rivalry_messages.json", "json_key" = "rivalry_escalation", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "rivalry_cleared", "label" = "Cleared", "group" = "Rivalry", "file" = "jelly_rivalry_messages.json", "json_key" = "rivalry_cleared", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Transfer trauma flavor templates ──
			list("key" = "transfer_equip", "label" = "Equip", "group" = "Transfer", "file" = "jelly_transfer_messages.json", "json_key" = "transfer_equip", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "transfer_persistent", "label" = "Persistent", "group" = "Transfer", "file" = "jelly_transfer_messages.json", "json_key" = "transfer_persistent", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "transfer_removal_relief", "label" = "Removal Relief", "group" = "Transfer", "file" = "jelly_transfer_messages.json", "json_key" = "transfer_removal_relief", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Doppelganger flavor templates ──
			list("key" = "doppel_summon", "label" = "Summon", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_summon", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_dismiss", "label" = "Dismiss", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_dismiss", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_idle", "label" = "Idle", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_idle", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_project", "label" = "Project", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_project", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_return", "label" = "Return", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_return", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_vaginal_start", "label" = "Vaginal Start", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_vaginal_start", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_vaginal_perform", "label" = "Vaginal Perform", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_vaginal_perform", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_vaginal_finish", "label" = "Vaginal Finish", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_vaginal_finish", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_anal_start", "label" = "Anal Start", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_anal_start", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_anal_perform", "label" = "Anal Perform", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_anal_perform", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_anal_finish", "label" = "Anal Finish", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_anal_finish", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_oral_start", "label" = "Oral Start", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_oral_start", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_oral_perform", "label" = "Oral Perform", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_oral_perform", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_self_oral_finish", "label" = "Oral Finish", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_self_oral_finish", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_gangbang_dp_start", "label" = "DP Start", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_gangbang_dp_start", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_gangbang_dp_perform", "label" = "DP Perform", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_gangbang_dp_perform", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_gangbang_dp_finish", "label" = "DP Finish", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_gangbang_dp_finish", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_gangbang_spit_start", "label" = "Spit Start", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_gangbang_spit_start", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_gangbang_spit_perform", "label" = "Spit Perform", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_gangbang_spit_perform", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "doppel_gangbang_spit_finish", "label" = "Spit Finish", "group" = "Doppelganger", "file" = "jelly_doppelganger_messages.json", "json_key" = "doppel_gangbang_spit_finish", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Cocoon action templates ──
			list("key" = "cocoon_resist", "label" = "Resist", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_resist", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_anal", "label" = "Anal", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_anal", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_throat", "label" = "Throat", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_throat", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_through", "label" = "Through", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_through", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_ear", "label" = "Ear", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_ear", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_asphyxiation", "label" = "Asphyxiation", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_asphyxiation", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_sounding", "label" = "Sounding", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_sounding", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "cocoon_multi", "label" = "Multi", "group" = "Cocoon Actions", "file" = "jelly_cocoon_messages.json", "json_key" = "cocoon_multi", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Cocoon escalation stage templates ──
			list("key" = "stage_enter_enveloping", "label" = "Enter Enveloping", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_enter_enveloping", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_enter_settling", "label" = "Enter Settling", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_enter_settling", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_enter_gripping", "label" = "Enter Gripping", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_enter_gripping", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_enter_overwhelming", "label" = "Enter Overwhelming", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_enter_overwhelming", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_ambient_enveloping", "label" = "Ambient Enveloping", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_ambient_enveloping", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_ambient_settling", "label" = "Ambient Settling", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_ambient_settling", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_ambient_gripping", "label" = "Ambient Gripping", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_ambient_gripping", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "stage_ambient_overwhelming", "label" = "Ambient Overwhelming", "group" = "Cocoon Stages", "file" = "jelly_cocoon_escalation_messages.json", "json_key" = "stage_ambient_overwhelming", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Player command flavor templates ──
			list("key" = "tendril_command", "label" = "Tendril", "group" = "Commands", "file" = "jelly_command_messages.json", "json_key" = "tendril_command", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "voluntary_cocoon_request", "label" = "Cocoon Request", "group" = "Commands", "file" = "jelly_command_messages.json", "json_key" = "voluntary_cocoon_request", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "voluntary_cocoon_denied", "label" = "Cocoon Denied", "group" = "Commands", "file" = "jelly_command_messages.json", "json_key" = "voluntary_cocoon_denied", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "provoke", "label" = "Provoke", "group" = "Commands", "file" = "jelly_command_messages.json", "json_key" = "provoke", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "provoke_already_angry", "label" = "Provoke (Already Angry)", "group" = "Commands", "file" = "jelly_command_messages.json", "json_key" = "provoke_already_angry", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Tendril action templates ──
			list("key" = "tendril_anal", "label" = "Anal", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_anal", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "tendril_throat", "label" = "Throat", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_throat", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "tendril_through", "label" = "Through", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_through", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "tendril_ear", "label" = "Ear", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_ear", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "tendril_asphyxiation", "label" = "Asphyxiation", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_asphyxiation", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "tendril_sounding", "label" = "Sounding", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_sounding", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "tendril_multi", "label" = "Multi", "group" = "Tendrils", "file" = "jelly_tendril_messages.json", "json_key" = "tendril_multi", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Autonomy flavor (base jelly) ──
			list("key" = "bead_push", "label" = "Bead Push", "group" = "Autonomy", "file" = "jelly_autonomy_flavor.json", "json_key" = "bead_push", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "bead_pull", "label" = "Bead Pull", "group" = "Autonomy", "file" = "jelly_autonomy_flavor.json", "json_key" = "bead_pull", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "aroused", "label" = "Aroused", "group" = "Autonomy", "file" = "jelly_autonomy_flavor.json", "json_key" = "aroused", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "restless", "label" = "Restless", "group" = "Autonomy", "file" = "jelly_autonomy_flavor.json", "json_key" = "restless", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "idle", "label" = "Idle", "group" = "Autonomy", "file" = "jelly_autonomy_flavor.json", "json_key" = "idle", "path" = INTIMATE_EDITOR_JELLY_PATH),
			// ── Autonomy flavor (strange jelly bond overrides) ──
			list("key" = "bead_push_possessive", "label" = "Bead Push (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "bead_push_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "bead_push_bonded", "label" = "Bead Push (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "bead_push_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "bead_pull_possessive", "label" = "Bead Pull (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "bead_pull_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "bead_pull_bonded", "label" = "Bead Pull (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "bead_pull_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "aroused_possessive", "label" = "Aroused (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "aroused_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "aroused_bonded", "label" = "Aroused (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "aroused_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "idle_possessive", "label" = "Idle (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "idle_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "idle_bonded", "label" = "Idle (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "idle_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "combat_possessive", "label" = "Combat (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "combat_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "combat_bonded", "label" = "Combat (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "combat_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "combat_base", "label" = "Combat (Base)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "combat_base", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "plug_possessive", "label" = "Plug React (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "plug_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "plug_bonded", "label" = "Plug React (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "plug_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "plug_base", "label" = "Plug React (Base)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "plug_base", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "restless_bonded", "label" = "Restless (Bonded)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "restless_bonded", "path" = INTIMATE_EDITOR_JELLY_PATH),
			list("key" = "restless_possessive", "label" = "Restless (Possessive)", "group" = "Autonomy (Bond)", "file" = "jelly_autonomy_flavor.json", "json_key" = "restless_possessive", "path" = INTIMATE_EDITOR_JELLY_PATH),
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
		"\[FORCE]", "\[JELLY]", "\[PLUG]",
	)

	// Preset dropdown options (hardcoded, never change).
	data["preset_species"] = list(
		list("id" = "humanoid",  "label" = "Humanoid"),
		list("id" = "tauric",    "label" = "Tauric"),
		list("id" = "lamia",     "label" = "Lamia"),
		list("id" = "anthro",    "label" = "Anthro"),
		list("id" = "moth",      "label" = "Moth"),
		list("id" = "lizard",    "label" = "Lizard"),
		list("id" = "insectoid", "label" = "Insectoid"),
		list("id" = "avian",     "label" = "Avian"),
		list("id" = "aquatic",   "label" = "Aquatic"),
		list("id" = "demonic",   "label" = "Demonic"),
	)
	data["preset_stages"] = list(
		list("id" = INTIMATE_TIER_NEUTRAL,     "label" = "Neutral",     "has_genital" = FALSE, "desc" = "Default state — no arousal. Fires during normal movement and non-sexual touch."),
		list("id" = INTIMATE_TIER_LUSTY,       "label" = "Lusty",       "has_genital" = TRUE,  "desc" = "Low-to-moderate arousal. Fires when lust is present but hasn't peaked."),
		list("id" = INTIMATE_TIER_BUILDING,    "label" = "Building",    "has_genital" = TRUE,  "desc" = "High arousal, actively building toward climax."),
		list("id" = INTIMATE_TIER_OVERWHELMED, "label" = "Overwhelmed", "has_genital" = TRUE,  "desc" = "At or near climax. Peak arousal and orgasm."),
		list("id" = INTIMATE_TIER_AFTERGLOW,   "label" = "Afterglow",   "has_genital" = TRUE,  "desc" = "Post-climax cooldown. Lust is dropping after orgasm."),
		list("id" = INTIMATE_TIER_WITHDRAWAL,  "label" = "Withdrawal",  "has_genital" = TRUE,  "desc" = "Frustrated arousal that was denied or interrupted — aroused with no outlet."),
		list("id" = INTIMATE_TIER_ROUGHUSE,    "label" = "Rough-Use",   "has_genital" = TRUE,  "desc" = "Being used roughly or forcefully during aggressive sex."),
		list("id" = INTIMATE_TIER_BROKEN,      "label" = "Broken",      "has_genital" = FALSE, "desc" = "Past the point of coherent reaction — extreme or repeated overstimulation."),
	)
	data["preset_genitals"] = list(
		list("id" = "penis",  "label" = "Penis"),
		list("id" = "vagina", "label" = "Vagina"),
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
		var/list/cat_entry = list(
			"key"   = cat_key,
			"label" = cdef["label"],
			"count" = count,
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

	// ── Preset result feedback ────────────────────────────────────────
	if(preset_result)
		data["preset_result"] = preset_result
		data["preset_result_success"] = preset_result_success
		preset_result = null

	// ── Resolved preview text ─────────────────────────────────────────
	if(resolved_preview_text)
		data["resolved_preview"] = resolved_preview_text

	return data

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
			prefs.custom_intimate_reactions.Remove(selected_category)
			prefs.custom_intimate_reactions.Remove("weight_[selected_category]")
			if(!length(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = null
			dirty = TRUE
			return TRUE

		// ── Export / Import ──────────────────────────────────────────────
		/**
		 * Export and Import allow players to share their custom intimate
		 * reaction strings as a single portable string.
		 *
		 * ## Format
		 * The payload is a **base64-encoded JSON object** with one key:
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
		if("export_data")
			if(!islist(prefs.custom_intimate_reactions) || !length(prefs.custom_intimate_reactions))
				to_chat(usr, span_warning("Nothing to export — no custom intimate reaction strings configured."))
				return FALSE
			var/json_str = json_encode(list("reactions" = prefs.custom_intimate_reactions))
			var/encoded = rustg_encode_base64(json_str)
			to_chat(usr, span_notice("Copy the string below to share your intimate reaction text:"))
			to_chat(usr, "<span class='notice' style='word-break:break-all;'>[encoded]</span>")
			return TRUE

		if("import_data")
			var/raw = params["payload"]
			if(!istext(raw) || !length(raw))
				to_chat(usr, span_warning("Import failed: empty payload."))
				return FALSE
			raw = trim(raw)
			var/decoded_str = rustg_decode_base64(raw)
			if(!istext(decoded_str) || !length(decoded_str))
				to_chat(usr, span_warning("Import failed: could not decode the string. Make sure you copied it exactly."))
				return FALSE
			var/list/payload
			try
				payload = json_decode(decoded_str)
			catch
				to_chat(usr, span_warning("Import failed: invalid JSON data."))
				return FALSE
			if(!islist(payload) || !islist(payload["reactions"]))
				to_chat(usr, span_warning("Import failed: unexpected data format."))
				return FALSE
			prefs.custom_intimate_reactions = payload["reactions"]
			prefs.validate_custom_intimate_reactions()
			prefs.save_character()
			dirty = FALSE
			to_chat(usr, span_notice("Import successful! Your intimate reaction strings have been updated."))
			return TRUE

		// ── Preview resolution ──────────────────────────────────────────
		if("preview_string")
			var/preview_text = params["text"]
			if(!istext(preview_text) || !length(preview_text))
				resolved_preview_text = null
				return TRUE
			resolved_preview_text = resolve_preview(preview_text)
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

		// ── Preset loading ──────────────────────────────────────────────
		if("load_preset")
			if(selected_bank != "character")
				return FALSE
			var/species = params["species"]
			var/stage = params["stage"]
			var/genital = params["genital"]
			if(!istext(species) || !istext(stage))
				return FALSE
			// Validate species against known list.
			var/static/list/valid_species = list("humanoid", "tauric", "lamia", "anthro", "moth", "lizard", "insectoid", "avian", "aquatic", "demonic")
			if(!(species in valid_species))
				return FALSE
			// Validate stage against known tiers.
			var/static/list/valid_stages = INTIMATE_TIER_LIST
			if(!(stage in valid_stages))
				return FALSE
			// Stages with genital split require a genital selection.
			var/static/list/genital_stages = list(INTIMATE_TIER_LUSTY, INTIMATE_TIER_BUILDING, INTIMATE_TIER_OVERWHELMED, INTIMATE_TIER_AFTERGLOW, INTIMATE_TIER_WITHDRAWAL, INTIMATE_TIER_ROUGHUSE)
			var/has_genital = (stage in genital_stages)
			// Build the preset ID for JSON lookup.
			var/preset_id
			if(has_genital)
				if(!istext(genital) || !(genital in list("penis", "vagina")))
					return FALSE
				preset_id = "[species]_[stage]_[genital]"
			else
				preset_id = "[species]_[stage]"
			// Load from the presets JSON.
			var/move_key = "[preset_id]_movement"
			var/sex_key = "[preset_id]_sex_received"
			load_strings_file("intimate_reaction_presets.json", INTIMATE_EDITOR_PRESETS_PATH)
			var/list/file_data = GLOB.string_cache?["intimate_reaction_presets.json"]
			var/list/move_strings = islist(file_data) ? file_data[move_key] : null
			var/list/sex_strings = islist(file_data) ? file_data[sex_key] : null
			if(!islist(move_strings) && !islist(sex_strings))
				to_chat(usr, span_warning("Preset not found: [preset_id]"))
				return FALSE
			// Build anal preset key — "anal" sits between stage and genital in JSON keys.
			var/anal_preset_id
			if(has_genital)
				anal_preset_id = "[species]_[stage]_anal_[genital]"
			else
				anal_preset_id = "[species]_[stage]_anal"
			var/anal_key = "[anal_preset_id]_sex_received"
			var/list/anal_strings = islist(file_data) ? file_data[anal_key] : null
			// Initialize reactions list if needed.
			if(!islist(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = list()
			// Store into tier-specific category keys.
			var/move_cat = "[stage]_[INTIMATE_CONTEXT_MOVEMENT]"
			var/sex_cat = "[stage]_[INTIMATE_CONTEXT_SEX_RECEIVED]"
			var/anal_cat = "[stage]_[INTIMATE_CONTEXT_ANAL_SEX_RECEIVED]"
			var/list/loaded_cats = list()
			if(islist(move_strings) && length(move_strings))
				prefs.custom_intimate_reactions[move_cat] = move_strings.Copy()
				loaded_cats += "Movement ([length(move_strings)])"
			if(islist(sex_strings) && length(sex_strings))
				prefs.custom_intimate_reactions[sex_cat] = sex_strings.Copy()
				loaded_cats += "Sex Received ([length(sex_strings)])"
			if(islist(anal_strings) && length(anal_strings))
				prefs.custom_intimate_reactions[anal_cat] = anal_strings.Copy()
				loaded_cats += "Anal Received ([length(anal_strings)])"
			dirty = TRUE
			// Navigate to the first affected category so the user sees the result.
			selected_category = move_cat
			// Set feedback for the TGUI.
			var/summary = "Loaded [jointext(loaded_cats, ", ")] for [capitalize(stage)]."
			preset_result = summary
			preset_result_success = TRUE
			to_chat(usr, span_notice(summary))
			return TRUE

		// ── Load ALL presets for a species ───────────────────────────────
		if("load_all_presets")
			if(selected_bank != "character")
				return FALSE
			var/species = params["species"]
			if(!istext(species))
				return FALSE
			var/static/list/valid_species_all = list("humanoid", "tauric", "lamia", "anthro", "moth", "lizard", "insectoid", "avian", "aquatic", "demonic")
			if(!(species in valid_species_all))
				return FALSE

			load_strings_file("intimate_reaction_presets.json", INTIMATE_EDITOR_PRESETS_PATH)
			var/list/file_data = GLOB.string_cache?["intimate_reaction_presets.json"]
			if(!islist(file_data))
				preset_result = "Could not load preset data."
				preset_result_success = FALSE
				return FALSE

			// Determine genital type: prefer explicit param, fall back to auto-detect.
			var/genital_type = "penis"
			var/explicit_genital = params["genital"]
			if(istext(explicit_genital) && (explicit_genital in list("penis", "vagina")))
				genital_type = explicit_genital
			else if(istype(owner))
				var/has_penis = !!owner.getorganslot(ORGAN_SLOT_PENIS)
				var/has_vagina = !!owner.getorganslot(ORGAN_SLOT_VAGINA)
				if(has_vagina && !has_penis)
					genital_type = "vagina"
			var/genital_label = genital_type == "penis" ? "penis" : "vagina"

			if(!islist(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = list()

			var/total_cats = 0
			var/static/list/all_stages = INTIMATE_TIER_LIST
			var/static/list/genital_stages_all = list(INTIMATE_TIER_LUSTY, INTIMATE_TIER_BUILDING, INTIMATE_TIER_OVERWHELMED, INTIMATE_TIER_AFTERGLOW, INTIMATE_TIER_WITHDRAWAL, INTIMATE_TIER_ROUGHUSE)

			for(var/stage in all_stages)
				var/has_genital = (stage in genital_stages_all)
				var/preset_id = has_genital ? "[species]_[stage]_[genital_type]" : "[species]_[stage]"
				// Movement
				var/move_key = "[preset_id]_movement"
				var/list/move_strings = file_data[move_key]
				if(islist(move_strings) && length(move_strings))
					var/move_cat = "[stage]_[INTIMATE_CONTEXT_MOVEMENT]"
					prefs.custom_intimate_reactions[move_cat] = move_strings.Copy()
					total_cats++
				// Sex received
				var/sex_key = "[preset_id]_sex_received"
				var/list/sex_strings = file_data[sex_key]
				if(islist(sex_strings) && length(sex_strings))
					var/sex_cat = "[stage]_[INTIMATE_CONTEXT_SEX_RECEIVED]"
					prefs.custom_intimate_reactions[sex_cat] = sex_strings.Copy()
					total_cats++
				// Anal received
				var/anal_preset_id = has_genital ? "[species]_[stage]_anal_[genital_type]" : "[species]_[stage]_anal"
				var/anal_key = "[anal_preset_id]_sex_received"
				var/list/anal_strings = file_data[anal_key]
				if(islist(anal_strings) && length(anal_strings))
					var/anal_cat = "[stage]_[INTIMATE_CONTEXT_ANAL_SEX_RECEIVED]"
					prefs.custom_intimate_reactions[anal_cat] = anal_strings.Copy()
					total_cats++

			dirty = TRUE
			selected_category = "[INTIMATE_TIER_NEUTRAL]_[INTIMATE_CONTEXT_MOVEMENT]"
			var/summary = "Applied all [capitalize(species)] presets ([total_cats] categories, [genital_label] variant)."
			preset_result = summary
			preset_result_success = TRUE
			to_chat(usr, span_notice(summary))
			return TRUE

		if("save")
			if(dirty)
				prefs.save_character()
				dirty = FALSE
			return TRUE

	return FALSE

/**
 * Resolves token placeholders in a preview string. Base version uses the
 * owner mob; the lobby subtype overrides to resolve from preferences.
 */
/datum/intimate_reaction_editor/proc/resolve_preview(text)
	if(istype(owner))
		return resolve_intimate_reaction_tokens(text, owner)
	return text


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

/**
 * Lobby-side token resolution: pulls character data entirely from preferences
 * and customizer entries so the preview works without a spawned mob.
 */
/datum/intimate_reaction_editor/lobby/resolve_preview(text)
	if(!prefs)
		return text

	// --- Name ---
	text = replacetext(text, "\[USER]", prefs.real_name || "Unknown")
	text = replacetext(text, "\[TARGET]", "someone")

	// --- Pronouns from prefs ---
	var/p_they = "they"
	var/p_them = "them"
	var/p_their = "their"
	switch(prefs.pronouns)
		if(HE_HIM, HE_HIM_F)
			p_they = "he"
			p_them = "him"
			p_their = "his"
		if(SHE_HER, SHE_HER_M)
			p_they = "she"
			p_them = "her"
			p_their = "her"
		if(IT_ITS)
			p_they = "it"
			p_them = "it"
			p_their = "its"

	text = replacetext(text, "\[THEY]", p_they)
	text = replacetext(text, "\[THEM]", p_them)
	text = replacetext(text, "\[THEIR_CAP]", capitalize(p_their))
	text = replacetext(text, "\[THEIR]", p_their)
	text = replacetext(text, "\[TTHEY]", "they")
	text = replacetext(text, "\[TTHEM]", "them")
	text = replacetext(text, "\[TTHEIR]", "their")

	// --- Penis data from customizer ---
	var/penis_type_label = "none"
	var/cocksize_label = "none"
	var/sizeadj_label = "none"
	var/sheath_label = "none"
	var/datum/customizer_entry/organ/penis/pe = prefs.get_customizer_entry_of_type(/datum/customizer_entry/organ/penis)
	if(pe && !pe.disabled && pe.customizer_choice_type)
		var/datum/customizer_choice/organ/penis/choice = CUSTOMIZER_CHOICE(pe.customizer_choice_type)
		if(choice)
			var/organ_path = choice.organ_type
			var/ptype = initial(organ_path:penis_type)
			var/stype = initial(organ_path:sheath_type)
			penis_type_label = get_penis_type_label(ptype)
			cocksize_label = _penis_size_descriptor(pe.penis_size)
			sizeadj_label = _penis_size_adjective(pe.penis_size)
			switch(stype)
				if(SHEATH_TYPE_NORMAL)
					sheath_label = "sheath"
				if(SHEATH_TYPE_SLIT)
					sheath_label = "genital slit"
	text = replacetext(text, "\[PENIS_TYPE]", penis_type_label)
	text = replacetext(text, "\[COCKSIZE]", cocksize_label)
	text = replacetext(text, "\[SIZEADJ]", sizeadj_label)
	text = replacetext(text, "\[SHEATH]", sheath_label)

	// --- Breast data from customizer ---
	var/cup_label = "none"
	var/cup_short_label = "none"
	var/cupadj_label = "none"
	var/breast_type_label = "none"
	var/datum/customizer_entry/organ/breasts/be = prefs.get_customizer_entry_of_type(/datum/customizer_entry/organ/breasts)
	if(be && !be.disabled)
		cup_label = _breast_size_descriptor(be.breast_size)
		cup_short_label = find_key_by_value(GLOB.named_breast_sizes, be.breast_size) || "unknown"
		cupadj_label = _breast_size_adjective(be.breast_size)
		breast_type_label = _breast_type_descriptor(be.accessory_type, be.breast_size)
	text = replacetext(text, "\[CUPSIZE]", cup_label)
	text = replacetext(text, "\[CUPADJ]", cupadj_label)
	text = replacetext(text, "\[BREASTTYPE]", breast_type_label)

	// --- Vagina data from customizer ---
	var/vagtype_label = "none"
	var/vagadj_label = "none"
	var/datum/customizer_entry/organ/vagina/ve = prefs.get_customizer_entry_of_type(/datum/customizer_entry/organ/vagina)
	if(ve && !ve.disabled)
		vagtype_label = _vagina_type_descriptor(ve.accessory_type)
		vagadj_label = _vagina_type_adjective(ve.accessory_type)
	text = replacetext(text, "\[VAGTYPE]", vagtype_label)
	text = replacetext(text, "\[VAGADJ]", vagadj_label)

	// --- Taur ---
	var/taur_label = "none"
	if(prefs.taur_type)
		taur_label = initial(prefs.taur_type:name)
	text = replacetext(text, "\[TAUR]", taur_label)

	// --- Genital descriptor ---
	var/genital_desc = "smooth groin"
	if(pe && !pe.disabled && be && !be.disabled)
		genital_desc = "[penis_type_label] cock and [cup_short_label] chest"
	else if(pe && !pe.disabled)
		genital_desc = "[penis_type_label] cock"
	else if(ve && !ve.disabled)
		if(be && !be.disabled)
			genital_desc = "slit and [cup_short_label] chest"
		else
			genital_desc = "slit"
	else if(be && !be.disabled)
		genital_desc = "[cup_short_label] chest"
	text = replacetext(text, "\[GENITAL_DESC]", genital_desc)

	return text

#undef INTIMATE_EDITOR_STRINGS_PATH
#undef INTIMATE_EDITOR_ACCESSORY_PATH
#undef INTIMATE_EDITOR_CHASTITY_PATH
#undef INTIMATE_EDITOR_JELLY_PATH
#undef INTIMATE_EDITOR_PRESETS_PATH
#undef INTIMATE_REACTION_BANK_IDS

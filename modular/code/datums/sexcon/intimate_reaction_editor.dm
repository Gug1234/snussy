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
 *   [USER]   [TARGET]  [THEY]  [THEM]  [THEIR]
 *   [TTHEY]  [TTHEM]   [TTHEIR]
 *   [PENIS_TYPE]  [CUPSIZE]  [TAUR]  [SHEATH]  [GENITAL_DESC]
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
/// Root directory for preset template JSON files.
#define INTIMATE_EDITOR_PRESETS_PATH "modular/code/datums/sexcon/strings"

/// Valid string bank IDs.
#define INTIMATE_REACTION_BANK_IDS list("character", "piercing", "insertable", "chastity")

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

/datum/intimate_reaction_editor/New(mob/living/carbon/human/H)
	if(!istype(H))
		qdel(src)
		return
	owner = H
	..()

/datum/intimate_reaction_editor/Destroy()
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
	var/list/banks = list()

	// ── Character bank — always available ──────────────────────────────
	banks["character"] = list(
		"label" = "Character",
		"available" = TRUE,
		"categories" = list(
			list("key" = "movement", "label" = "Movement", "file" = "character_movement_messages.json", "json_key" = "character_movement", "path" = INTIMATE_EDITOR_STRINGS_PATH),
			list("key" = "sex_received", "label" = "Sex Received", "file" = "character_sex_received_messages.json", "json_key" = "character_sex_received", "path" = INTIMATE_EDITOR_STRINGS_PATH),

		),
	)

	// ── Piercing bank — gated behind intimate_enabled ──────────────────
	var/pierce_avail = !!(prefs?.intimate_enabled)
	banks["piercing"] = list(
		"label" = "Piercings",
		"available" = pierce_avail,
		"categories" = list(
			list("key" = "piercing_breast_bare", "label" = "Breast Move (Bare)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_breast_bare", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_breast_cloth", "label" = "Breast Move (Clothed)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_breast_cloth", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_breast_light_armor", "label" = "Breast Move (Lt. Armor)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_breast_light_armor", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_bare", "label" = "Genital Move (Bare)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_genital_bare", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_cloth", "label" = "Genital Move (Clothed)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_genital_cloth", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_light_armor", "label" = "Genital Move (Lt. Armor)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_genital_light_armor", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_bare", "label" = "Rear Move (Bare)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_rear_bare", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_cloth", "label" = "Rear Move (Clothed)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_rear_cloth", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_light_armor", "label" = "Rear Move (Lt. Armor)", "file" = "piercing_movement_messages.json", "json_key" = "piercing_rear_light_armor", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_breast_receive", "label" = "Breast Receive", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_breast_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_cock_receive", "label" = "Genital Receive (Cock)", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_genital_cock_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_cunt_receive", "label" = "Genital Receive (Cunt)", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_genital_cunt_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_genital_general_receive", "label" = "Genital Receive (Gen.)", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_genital_general_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_rear_receive", "label" = "Rear Receive", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_rear_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "piercing_mouth_receive", "label" = "Mouth Receive", "file" = "piercing_receive_flavor.json", "json_key" = "piercing_mouth_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
		),
	)

	// ── Insertable (Plug) bank — gated behind intimate_enabled ─────────
	banks["insertable"] = list(
		"label" = "Plugs",
		"available" = pierce_avail,
		"categories" = list(
			list("key" = "insertable_genital_shift", "label" = "Genital Plug Move", "file" = "insertable_movement_messages.json", "json_key" = "insertable_genital_shift", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_rear_shift", "label" = "Rear Plug Move", "file" = "insertable_movement_messages.json", "json_key" = "insertable_rear_shift", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_genital_receive", "label" = "Genital Plug Receive", "file" = "insertable_receive_flavor.json", "json_key" = "insertable_genital_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
			list("key" = "insertable_rear_receive", "label" = "Rear Plug Receive", "file" = "insertable_receive_flavor.json", "json_key" = "insertable_rear_receive", "path" = INTIMATE_EDITOR_ACCESSORY_PATH),
		),
	)

	// ── Chastity bank — gated behind chastenable ───────────────────────
	var/chaste_avail = !!(prefs?.chastenable)
	banks["chastity"] = list(
		"label" = "Chastity",
		"available" = chaste_avail,
		"categories" = list(
			list("key" = "chastity_jingle_emotes", "label" = "Jingle (Bare)", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_emotes", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_movement_pain", "label" = "Move Pain", "file" = "chastity_movement_messages.json", "json_key" = "chastity_movement_pain", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_movement_struggle", "label" = "Move Struggle", "file" = "chastity_movement_messages.json", "json_key" = "chastity_movement_struggle", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_cloth", "label" = "Jingle (Clothed)", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_cloth", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_light_armor", "label" = "Jingle (Lt. Armor)", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_light_armor", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_medium_armor", "label" = "Jingle (Med. Armor)", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_medium_armor", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_jingle_heavy_armor", "label" = "Jingle (Hvy. Armor)", "file" = "chastity_movement_messages.json", "json_key" = "chastity_jingle_heavy_armor", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_anal_recieve", "label" = "Cock Anal", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_anal_recieve", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_general_receive", "label" = "Cock General", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_general_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_anal_recieve", "label" = "Vagina Anal", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_anal_recieve", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_anal_recieve", "label" = "Intersex Anal", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_anal_recieve", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_general_receive", "label" = "Vagina General", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_general_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_receive_devout", "label" = "Devout Receive", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_receive_devout", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_general_receive", "label" = "Intersex General", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_general_receive", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_masturbation", "label" = "Cock Masturbation", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_masturbation", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_masturbation", "label" = "Vagina Masturbation", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_masturbation", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_masturbation", "label" = "Intersex Masturbation", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_masturbation", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_cock_outercourse", "label" = "Cock Outercourse", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_cock_outercourse", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_vagina_outercourse", "label" = "Vagina Outercourse", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_vagina_outercourse", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_intersex_outercourse", "label" = "Intersex Outercourse", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_intersex_outercourse", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_masturbation_devout", "label" = "Masturbation (Devout)", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_masturbation_devout", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
			list("key" = "chastity_outercourse_devout", "label" = "Outercourse (Devout)", "file" = "chastity_receive_flavor.json", "json_key" = "chastity_outercourse_devout", "path" = INTIMATE_EDITOR_CHASTITY_PATH),
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
	var/list/valid = list()
	var/list/banks = get_bank_definitions(null)
	for(var/bank_id in banks)
		var/list/bank = banks[bank_id]
		var/list/cats = bank["categories"]
		for(var/list/cat_def in cats)
			valid += cat_def["key"]
	return valid

/datum/intimate_reaction_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IntimateReactionEditor", "Intimate Reaction Editor", 720, 620)
		ui.set_state(GLOB.always_state)
		ui.open()

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
	data["max_strings"]       = INTIMATE_REACTION_MAX_STRINGS
	data["max_length"]        = INTIMATE_REACTION_MAX_LENGTH

	// ── Build bank list for the dropdown ──────────────────────────────
	var/list/bank_defs = get_bank_definitions(prefs)
	var/list/banks_out = list()
	for(var/bank_id in bank_defs)
		var/list/bdef = bank_defs[bank_id]
		banks_out += list(list(
			"id"        = bank_id,
			"label"     = bdef["label"],
			"available" = bdef["available"],
		))
	data["banks"] = banks_out

	// ── Build category list for the selected bank ─────────────────────
	var/list/cat_defs = get_current_bank_categories()
	var/list/all_reactions = islist(prefs.custom_intimate_reactions) ? prefs.custom_intimate_reactions : list()
	var/list/categories = list()
	for(var/list/cdef in cat_defs)
		var/cat_key = cdef["key"]
		var/list/cat_strings = all_reactions[cat_key]
		var/count = islist(cat_strings) ? cat_strings.len : 0
		categories += list(list(
			"key"   = cat_key,
			"label" = cdef["label"],
			"count" = count,
		))
	data["categories"] = categories

	// ── Current strings for the selected category ─────────────────────
	var/list/current_strings = list()
	if(islist(all_reactions[selected_category]))
		current_strings = all_reactions[selected_category]
	data["current_strings"] = current_strings

	// ── Default strings from JSON bank ────────────────────────────────
	var/list/default_strings = list()
	// Find current category definition to get JSON source info
	for(var/list/cdef in cat_defs)
		if(cdef["key"] == selected_category && cdef["file"] && cdef["path"])
			var/loaded = strings(cdef["file"], cdef["json_key"], cdef["path"])
			if(islist(loaded))
				default_strings = loaded
			break
	data["default_strings"] = default_strings

	// ── Presets (only for character bank) ─────────────────────────────
	if(selected_bank == "character")
		data["presets"] = list(
			list("id" = "humanoid_neutral",       "label" = "Humanoid — Neutral"),
			list("id" = "humanoid_lusty_penis",    "label" = "Humanoid — Lusty Penis"),
			list("id" = "humanoid_lusty_vagina",   "label" = "Humanoid — Lusty Vagina"),
			list("id" = "tauric_neutral",          "label" = "Tauric — Neutral"),
			list("id" = "tauric_lusty_penis",      "label" = "Tauric — Lusty Penis"),
			list("id" = "tauric_lusty_vagina",     "label" = "Tauric — Lusty Vagina"),
			list("id" = "lamia_neutral",            "label" = "Lamia — Neutral"),
			list("id" = "lamia_lusty_penis",        "label" = "Lamia — Lusty Penis"),
			list("id" = "lamia_lusty_vagina",       "label" = "Lamia — Lusty Vagina"),
			list("id" = "anthro_neutral",           "label" = "Anthro — Neutral"),
			list("id" = "anthro_lusty_penis",       "label" = "Anthro — Lusty Penis"),
			list("id" = "anthro_lusty_vagina",      "label" = "Anthro — Lusty Vagina"),
			list("id" = "moth_neutral",             "label" = "Moth — Neutral"),
			list("id" = "moth_lusty_penis",         "label" = "Moth — Lusty Penis"),
			list("id" = "moth_lusty_vagina",        "label" = "Moth — Lusty Vagina"),
			list("id" = "lizard_neutral",           "label" = "Lizard — Neutral"),
			list("id" = "lizard_lusty_penis",       "label" = "Lizard — Lusty Penis"),
			list("id" = "lizard_lusty_vagina",      "label" = "Lizard — Lusty Vagina"),
		)

	// Token reference for the frontend help panel.
	data["tokens"] = list(
		"\[USER]", "\[TARGET]", "\[THEY]", "\[THEM]", "\[THEIR]",
		"\[TTHEY]", "\[TTHEM]", "\[TTHEIR]",
		"\[PENIS_TYPE]", "\[CUPSIZE]", "\[TAUR]", "\[SHEATH]", "\[GENITAL_DESC]",
	)

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
			var/new_str = sanitize(params["text"])
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
			prefs.save_character()
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
			// Clean up empty category.
			if(!cat_list.len)
				prefs.custom_intimate_reactions.Remove(selected_category)
			if(!length(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = null
			prefs.save_character()
			return TRUE

		if("update_string")
			// Replace an existing custom string at a given index (1-based).
			var/idx = text2num(params["index"])
			if(!idx || idx < 1)
				return FALSE
			var/new_str = sanitize(params["text"])
			if(!istext(new_str) || !length(new_str))
				return FALSE
			new_str = copytext(new_str, 1, INTIMATE_REACTION_MAX_LENGTH + 1)
			if(!islist(prefs.custom_intimate_reactions))
				return FALSE
			var/list/cat_list = prefs.custom_intimate_reactions[selected_category]
			if(!islist(cat_list) || idx > cat_list.len)
				return FALSE
			cat_list[idx] = new_str
			prefs.save_character()
			return TRUE

		if("clear_category")
			if(!islist(prefs.custom_intimate_reactions))
				return FALSE
			prefs.custom_intimate_reactions.Remove(selected_category)
			if(!length(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = null
			prefs.save_character()
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
			var/encoded = url_encode(json_str)
			to_chat(usr, span_notice("Copy the string below to share your intimate reaction text:"))
			to_chat(usr, "<tt>[encoded]</tt>")
			return TRUE

		if("import_data")
			var/raw = params["payload"]
			if(!istext(raw) || !length(raw))
				to_chat(usr, span_warning("Import failed: empty payload."))
				return FALSE
			var/decoded_str = url_decode(raw)
			if(!decoded_str)
				to_chat(usr, span_warning("Import failed: could not decode payload."))
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
			to_chat(usr, span_notice("Import successful! Your intimate reaction strings have been updated."))
			return TRUE

		// ── Preview resolution ──────────────────────────────────────────
		if("preview_string")
			var/preview_text = params["text"]
			if(!istext(preview_text) || !length(preview_text))
				return FALSE
			var/mob/living/carbon/human/H = null
			if(istype(owner))
				H = owner
			if(H)
				preview_text = resolve_intimate_reaction_tokens(preview_text, H)
			to_chat(usr, span_notice("<b>Preview:</b> [preview_text]"))
			return TRUE

		// ── Preset loading ──────────────────────────────────────────────
		if("load_preset")
			if(selected_bank != "character")
				return FALSE
			var/preset_id = params["preset"]
			if(!istext(preset_id))
				return FALSE
			// Load from the presets JSON. Movement key = "<id>_movement", sex received key = "<id>_sex_received".
			var/move_key = "[preset_id]_movement"
			var/sex_key = "[preset_id]_sex_received"
			var/list/move_strings = strings("intimate_reaction_presets.json", move_key, INTIMATE_EDITOR_PRESETS_PATH)
			var/list/sex_strings = strings("intimate_reaction_presets.json", sex_key, INTIMATE_EDITOR_PRESETS_PATH)
			if(!islist(move_strings) && !islist(sex_strings))
				to_chat(usr, span_warning("Preset not found: [preset_id]"))
				return FALSE
			// Initialize reactions list if needed
			if(!islist(prefs.custom_intimate_reactions))
				prefs.custom_intimate_reactions = list()
			// Replace movement and sex_received with the preset strings
			if(islist(move_strings) && length(move_strings))
				prefs.custom_intimate_reactions["movement"] = move_strings.Copy()
			if(islist(sex_strings) && length(sex_strings))
				prefs.custom_intimate_reactions["sex_received"] = sex_strings.Copy()
			prefs.save_character()
			to_chat(usr, span_notice("Preset loaded: [preset_id]. Movement and Sex Received strings have been replaced."))
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
#undef INTIMATE_EDITOR_PRESETS_PATH
#undef INTIMATE_REACTION_BANK_IDS

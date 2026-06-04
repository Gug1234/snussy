/**
 * preferences_sex_flavors.dm — Modular extension to /datum/preferences.
 *
 * Adds per-character custom sex action flavor text storage and validation.
 * Data is serialized as JSON and stored in a sidecar file per character slot
 * (sex_flavors_[slot].json) to avoid the BYOND savefile ~64 KB per-entry
 * limit.
 *
 * Shared constants live in modular/code/__DEFINES/roguetown/sexcon_modular.dm
 * so they are available to all consumers regardless of DME include order.
 */

// Preference vars are full-path declarations so static analysis resolves them before modular procs use them.
	/**
	 * Per-character custom sex action flavor text pool.
	 *
	 * Structure (associative list):
	 *   "[/datum/sex_action/example]" → list(
	 *     "on_start"   = list("string1", "string2", ...),
	 *     "on_perform" = list(...),
	 *     "on_finish"  = list(...),
	 *   )
	 *
	 * Null when the player has not configured any custom strings.
	 * Serialized to JSON in the per-slot sidecar file sex_flavors_[slot].json.
	 */
/datum/preferences/var/list/custom_sex_flavors = null

	/**
	 * Per-character custom sex action definitions.
	 *
	 * Structure: list of associative lists, each containing:
	 *   "slot"            — integer 1-5 (which slot datum this maps to)
	 *   "name"            — display name of the action
	 *   "template"        — template key it was created from ("penetration", "oral", etc.)
	 *   "on_start_text"   — flavor text shown on start (supports tokens)
	 *   "on_perform_text" — flavor text shown each cycle
	 *   "on_finish_text"  — flavor text shown on finish
	 *   "user_arousal"    — arousal given to user per cycle (0-5)
	 *   "target_arousal"  — arousal given to target per cycle (0-5)
	 *   "user_pain"       — pain applied to user per cycle (0-15)
	 *   "target_pain"     — pain applied to target per cycle (0-15)
	 *   "stamina_cost"    — stamina cost per cycle (0-3)
	 *   "category"        — SEX_CATEGORY bitflag
	 *   "user_sex_part"   — SEX_PART bitflag for user
	 *   "target_sex_part" — SEX_PART bitflag for target
	 *   "requires_other"  — TRUE if cannot self-target
	 *   "continuous"      — TRUE if repeats
	 *
	 * Null when no custom actions are defined.
	 * Serialized to JSON in the per-slot sidecar file sex_actions_[slot].json.
	 */
/datum/preferences/var/list/custom_sex_actions = null

/**
 * Validates and sanitizes custom_sex_flavors after loading from the savefile.
 *
 * Enforces:
 *   - Action paths must resolve to a type in GLOB.sex_actions.
 *   - Phase keys must be one of SEX_FLAVOR_PHASES.
 *   - String lists are trimmed to SEX_FLAVOR_MAX_STRINGS entries.
 *   - Individual strings are clamped to SEX_FLAVOR_MAX_LENGTH characters.
 *
 * Sets custom_sex_flavors to null if nothing valid remains after cleaning.
 */
/datum/preferences/proc/validate_custom_sex_flavors()
	if(!islist(custom_sex_flavors))
		custom_sex_flavors = null
		return

	var/list/validated = list()
	for(var/action_path in custom_sex_flavors)
		if(!istext(action_path))
			continue
		var/path = text2path(action_path)
		if(!path || !(path in GLOB.sex_actions))
			continue

		var/list/action_data = custom_sex_flavors[action_path]
		if(!islist(action_data))
			continue

		var/list/valid_action = list()
		// Validate both legacy bare phase keys and perspective-prefixed keys.
		var/static/list/all_perspectives = list("performer", "target", "observer")
		var/list/all_phase_keys = list()
		for(var/phase in SEX_FLAVOR_PHASES)
			all_phase_keys += phase
			for(var/persp in all_perspectives)
				all_phase_keys += "[persp]_[phase]"

		for(var/phase_key in all_phase_keys)
			var/list/phase_strings = action_data[phase_key]
			if(!islist(phase_strings) || !phase_strings.len)
				continue

			var/list/valid_strings = list()
			for(var/str in phase_strings)
				if(!istext(str) || !length(str))
					continue
				// html_decode() repairs legacy double-encoded entities;
				// strip_html_simple() prevents HTML injection without
				// encoding entities that TGUI would render literally.
				valid_strings += strip_html_simple(sanitize_simple(html_decode(copytext(str, 1, SEX_FLAVOR_MAX_LENGTH + 1))))
				if(valid_strings.len >= SEX_FLAVOR_MAX_STRINGS)
					break

			if(valid_strings.len)
				valid_action[phase_key] = valid_strings

			// Validate parallel weight list for this phase key.
			var/weight_key = "weight_[phase_key]"
			var/list/phase_weights = action_data[weight_key]
			if(islist(phase_weights) && phase_weights.len)
				var/list/valid_weights = list()
				for(var/w in phase_weights)
					valid_weights += clamp(round(w), 1, 1000)
					if(valid_weights.len >= valid_strings.len)
						break
				if(valid_weights.len)
					valid_action[weight_key] = valid_weights

		// Preserve the suppress sub-map — only carry forward TRUE entries for valid phases.
		var/list/raw_suppress = action_data["suppress"]
		if(islist(raw_suppress) && raw_suppress.len)
			var/list/valid_suppress = list()
			for(var/phase in SEX_FLAVOR_PHASES)
				if(raw_suppress[phase])
					valid_suppress[phase] = TRUE
			if(valid_suppress.len)
				valid_action["suppress"] = valid_suppress

		if(valid_action.len)
			validated[action_path] = valid_action

	custom_sex_flavors = validated.len ? validated : null

/proc/sanitize_custom_sex_sound_course(sound_course)
	if(!istext(sound_course))
		return CUSTOM_SEX_SOUND_NONE
	if(sound_course in CUSTOM_SEX_SOUND_COURSES)
		return sound_course
	return CUSTOM_SEX_SOUND_NONE

/proc/sanitize_custom_sex_animation_type(animation_type)
	if(!istext(animation_type))
		return CUSTOM_SEX_ANIMATION_NONE
	if(animation_type in CUSTOM_SEX_ANIMATION_TYPES)
		return animation_type
	return CUSTOM_SEX_ANIMATION_NONE


/**
 * Validates and sanitizes custom_sex_actions after loading from the savefile.
 *
 * Enforces:
 *   - Maximum of MAX_CUSTOM_SEX_ACTIONS entries.
 *   - Slot numbers must be 1-5 and unique.
 *   - Numeric stats clamped to safe ranges.
 *   - Text fields clamped to SEX_FLAVOR_MAX_LENGTH.
 *
 * Sets custom_sex_actions to null if nothing valid remains.
 */
/datum/preferences/proc/validate_custom_sex_actions()
	if(!islist(custom_sex_actions))
		custom_sex_actions = null
		return

	var/list/validated = list()
	var/list/used_slots = list()
	for(var/list/entry in custom_sex_actions)
		if(validated.len >= MAX_CUSTOM_SEX_ACTIONS)
			break
		if(!islist(entry))
			continue
		var/slot = text2num("[entry["slot"]]")
		if(!slot || slot < 1 || slot > MAX_CUSTOM_SEX_ACTIONS)
			continue
		if("[slot]" in used_slots)
			continue
		used_slots += "[slot]"

		var/list/clean = list()
		clean["slot"] = slot
		clean["template"] = strip_html_simple(sanitize_simple(html_decode(copytext("[entry["template"]]", 1, 64))))
		clean["name"] = strip_html_simple(sanitize_simple(html_decode(copytext("[entry["name"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))))
		if(!length(clean["name"]))
			clean["name"] = "Custom Action [slot]"
		clean["on_start_text"] = strip_html_simple(sanitize_simple(html_decode(copytext("[entry["on_start_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))))
		clean["on_perform_text"] = strip_html_simple(sanitize_simple(html_decode(copytext("[entry["on_perform_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))))
		clean["on_finish_text"] = strip_html_simple(sanitize_simple(html_decode(copytext("[entry["on_finish_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))))
		clean["user_arousal"] = clamp(text2num("[entry["user_arousal"]]"), 0, 5)
		clean["target_arousal"] = clamp(text2num("[entry["target_arousal"]]"), 0, 5)
		clean["user_pain"] = clamp(text2num("[entry["user_pain"]]"), 0, 15)
		clean["target_pain"] = clamp(text2num("[entry["target_pain"]]"), 0, 15)
		clean["stamina_cost"] = clamp(text2num("[entry["stamina_cost"]]"), 0, 3)
		clean["category"] = clamp(text2num("[entry["category"]]"), 0, 7)
		clean["user_sex_part"] = clamp(text2num("[entry["user_sex_part"]]"), 0, 31)
		clean["target_sex_part"] = clamp(text2num("[entry["target_sex_part"]]"), 0, 31)
		clean["requires_other"] = !!entry["requires_other"]
		clean["continuous"] = !!entry["continuous"]
		clean["sound_course"] = sanitize_custom_sex_sound_course(entry["sound_course"])
		clean["animation_type"] = sanitize_custom_sex_animation_type(entry["animation_type"])
		clean["req_user_chastity"] = clamp(text2num("[entry["req_user_chastity"]]"), 0, 2)
		clean["req_target_chastity"] = clamp(text2num("[entry["req_target_chastity"]]"), 0, 2)
		clean["req_toy"] = clamp(text2num("[entry["req_toy"]]"), 0, 3)
		clean["req_user_piercing"] = !!entry["req_user_piercing"]
		clean["req_user_plug"] = clamp(text2num("[entry["req_user_plug"]]"), 0, 5)
		clean["req_target_piercing"] = !!entry["req_target_piercing"]
		clean["req_target_plug"] = clamp(text2num("[entry["req_target_plug"]]"), 0, 5)
		clean["req_no_rear_plug"] = !!entry["req_no_rear_plug"]
		clean["req_user_manticore_tail"] = !!entry["req_user_manticore_tail"]
		clean["req_target_manticore_tail"] = !!entry["req_target_manticore_tail"]
		validated += list(clean)

	custom_sex_actions = validated.len ? validated : null

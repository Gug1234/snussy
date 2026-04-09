/**
 * sex_flavor_editor.dm — TGUI backend for the Custom Sex Flavor Text editor.
 *
 * Allows players to write per-character, per-action, per-phase flavor strings
 * that are privately displayed to them during sex actions.  By default these
 * are additive; players may also toggle per-phase suppression to replace the
 * standard visible_message output entirely with their own strings.
 *
 * Data is stored in datum/preferences.custom_sex_flavors (see
 * preferences_sex_flavors.dm) and persisted as JSON in the character savefile.
 *
 * Token placeholders resolved at runtime (see resolve_sex_flavor_tokens):
 *   [USER]   [TARGET]  [THEY]  [THEM]  [THEIR]
 *   [TTHEY]  [TTHEM]   [TTHEIR]        [FORCE]
 */

/// Global cache for all sex action flavor text presets (loaded from JSON).
/// Structure: list("humanoid" = list(action_path = list(phase = text)), "tauric" = ..., ...)
GLOBAL_LIST(sex_action_preset_texts)

/// Ordered list of preset keys for display in the UI.
GLOBAL_LIST_INIT(sex_action_preset_keys, list(
	"humanoid", "anthro", "tauric", "lamia", "drider",
	"harpy", "moth", "lizard", "kobold",
	"tiefling", "half_orc", "goblin", "dwarf", "elf",
	"revenant", "construct"
))

/// Human-readable labels for each preset key.
GLOBAL_LIST_INIT(sex_action_preset_labels, list(
	"humanoid"  = "Humanoid",
	"anthro"    = "Anthro",
	"tauric"    = "Tauric",
	"lamia"     = "Lamia",
	"drider"    = "Drider / Arachnid",
	"harpy"     = "Harpy",
	"moth"      = "Moth",
	"lizard"    = "Lizard",
	"kobold"    = "Kobold",
	"tiefling"  = "Tiefling",
	"half_orc"  = "Half-Orc",
	"goblin"    = "Goblin",
	"dwarf"     = "Dwarf",
	"elf"       = "Elf",
	"revenant"  = "Revenant / Dullahan",
	"construct" = "Metal Construct"
))

/// Lazily loads and returns all sex action preset text banks from JSON.
/proc/get_sex_action_presets()
	if(!GLOB.sex_action_preset_texts)
		var/json_path = "modular/code/datums/sexcon/strings/sex_action_defaults.json"
		if(fexists(json_path))
			GLOB.sex_action_preset_texts = json_load(json_path)
		if(!islist(GLOB.sex_action_preset_texts))
			GLOB.sex_action_preset_texts = list()
	return GLOB.sex_action_preset_texts

/// Returns the default text for a given action path, preset, perspective, and phase.
/// Falls back to humanoid if the selected preset doesn't define that action.
/// @param preset_key  The race preset key (e.g. "humanoid", "anthro").
/// @param action_path The action type path string.
/// @param perspective "performer" or "target".
/// @param phase       "on_start", "on_perform", or "on_finish".
/proc/get_preset_action_text(preset_key, action_path, perspective, phase)
	var/list/all_presets = get_sex_action_presets()
	// Try the selected preset first.
	var/list/preset_data = all_presets[preset_key]
	if(islist(preset_data))
		var/list/action_data = preset_data[action_path]
		if(islist(action_data))
			var/list/persp_data = action_data[perspective]
			if(islist(persp_data) && persp_data[phase])
				return persp_data[phase]
	// Fallback to humanoid.
	if(preset_key != "humanoid")
		var/list/humanoid = all_presets["humanoid"]
		if(islist(humanoid))
			var/list/action_data = humanoid[action_path]
			if(islist(action_data))
				var/list/persp_data = action_data[perspective]
				if(islist(persp_data))
					return persp_data[phase]
	return null

/// IC verb available to any chastenable player. Opens their own flavor editor.
/mob/living/carbon/human/verb/open_sex_flavor_editor()
	set name = "Edit Sex Flavor Text"
	set category = "IC"

	if(!client?.prefs || !client.prefs.chastenable)
		to_chat(src, span_warning("I have intimate content disabled."))
		return

	var/datum/sex_flavor_editor/editor = new(src)
	editor.ui_interact(src)

// ---------------------------------------------------------------------------

/datum/sex_flavor_editor
	/// The human who opened the editor; their prefs hold custom_sex_flavors.
	var/mob/living/carbon/human/owner
	/// Currently selected action type path (text key into custom_sex_flavors).
	var/selected_action_path = null
	/// Currently selected phase key: "on_start", "on_perform", or "on_finish".
	var/selected_phase = "on_perform"
	/// When FALSE (default), only show actions the character can potentially use.
	/// When TRUE, show every registered sex action regardless of anatomy.
	var/show_all_actions = FALSE
	/// Currently selected custom action slot for editing (1-5), or 0 for none.
	var/selected_custom_slot = 0
	/// Currently selected flavor text preset (race/species bank).
	var/selected_preset = "humanoid"
	/// Currently selected perspective: "performer", "target", or "observer".
	var/selected_perspective = "performer"

/datum/sex_flavor_editor/New(mob/living/carbon/human/H)
	if(!istype(H))
		qdel(src)
		return
	owner = H
	..()

/datum/sex_flavor_editor/Destroy()
	owner = null
	return ..()

/// Returns the preferences datum for the character being edited.
/// Overridden by the lobby subtype to return prefs directly.
/datum/sex_flavor_editor/proc/get_prefs()
	if(owner?.client?.prefs)
		return owner.client.prefs
	return null

/// Returns TRUE if the character can anatomically use a sex action.
/// Overridden by the lobby subtype (no mob available → always TRUE).
/datum/sex_flavor_editor/proc/check_anatomy(datum/sex_action/A)
	if(!owner)
		return TRUE
	if(A.user_sex_part & SEX_PART_COCK)
		if(!owner.getorganslot(ORGAN_SLOT_PENIS))
			return FALSE
	if(A.user_sex_part & SEX_PART_CUNT)
		if(!owner.getorganslot(ORGAN_SLOT_VAGINA))
			return FALSE
	if(A.user_sex_part & SEX_PART_SLIT_SHEATH)
		if(!owner.getorganslot(ORGAN_SLOT_PENIS))
			return FALSE
	return TRUE

/// Returns TRUE if the editor session is still valid.
/datum/sex_flavor_editor/proc/is_valid()
	return owner && !QDELETED(owner) && owner.client

/// Always allow interaction — this editor is opened from prefs/verbs, not a physical object.
/datum/sex_flavor_editor/ui_state(mob/user)
	return GLOB.always_state

/datum/sex_flavor_editor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SexFlavorEditor", "Sex Flavor Text Editor", 960, 760)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/sex_flavor_editor/ui_data(mob/user)
	var/list/data = list()

	if(!is_valid())
		data["invalid"] = TRUE
		return data

	var/datum/preferences/prefs = get_prefs()
	if(!prefs)
		data["invalid"] = TRUE
		return data

	// Build the flat action list — name, path, category for grouping in TSX.
	// Each entry includes `has_custom` (whether the player has written custom text
	// for this action) and `can_use` (whether the character's anatomy supports it).
	var/list/action_list = list()
	var/list/all_flavors = islist(prefs.custom_sex_flavors) ? prefs.custom_sex_flavors : list()
	for(var/path in GLOB.sex_actions)
		var/datum/sex_action/A = GLOB.sex_actions[path]
		if(!A || A.category == SEX_CATEGORY_NULL)
			continue
		var/path_text = "[path]"

		// --- has_custom: TRUE if any perspective+phase has at least one string ---
		var/has_custom = FALSE
		var/list/action_data = all_flavors[path_text]
		if(islist(action_data))
			for(var/phase in list("on_start", "on_perform", "on_finish"))
				for(var/persp in list("performer", "target", "observer"))
					var/list/pstrings = action_data["[persp]_[phase]"]
					if(islist(pstrings) && pstrings.len)
						has_custom = TRUE
						break
				if(has_custom)
					break
				// Also check legacy un-prefixed keys.
				var/list/legacy = action_data[phase]
				if(islist(legacy) && legacy.len)
					has_custom = TRUE
					break

		// --- can_use: anatomy check via helper proc ---
		var/can_use = check_anatomy(A)

		var/list/entry = list(
			"path"       = path_text,
			"name"       = A.name,
			"category"   = A.category,
			"has_custom" = has_custom,
			"can_use"    = can_use,
		)
		action_list += list(entry)
	data["actions"] = action_list
	data["show_all_actions"] = show_all_actions

	// Selected state.
	data["selected_action"] = selected_action_path
	data["selected_phase"]  = selected_phase

	// Current strings + weights for the selected slot.
	// Keys are perspective-prefixed: "performer_on_start", "target_on_perform", etc.
	var/persp_phase_key = "[selected_perspective]_[selected_phase]"
	var/list/current_strings = list()
	var/list/current_weights = list()
	if(selected_action_path && islist(prefs.custom_sex_flavors))
		all_flavors = prefs.custom_sex_flavors
		var/list/action_data = all_flavors[selected_action_path]
		if(islist(action_data))
			var/list/phase_strings = action_data[persp_phase_key]
			// Fallback to legacy un-prefixed key for backwards compat.
			if(!islist(phase_strings) || !phase_strings.len)
				phase_strings = action_data[selected_phase]
			if(islist(phase_strings))
				current_strings = phase_strings.Copy()
			// Parallel weight list.
			var/weight_key = "weight_[persp_phase_key]"
			var/list/phase_weights = action_data[weight_key]
			if(!islist(phase_weights))
				phase_weights = action_data["weight_[selected_phase]"]
			if(islist(phase_weights))
				current_weights = phase_weights.Copy()

	// Pad weights to match string count, defaulting to 100.
	while(current_weights.len < current_strings.len)
		current_weights += 100

	data["current_strings"] = current_strings
	data["current_weights"] = current_weights
	data["max_strings"]     = SEX_FLAVOR_MAX_STRINGS
	data["max_length"]      = SEX_FLAVOR_MAX_LENGTH
	data["phases"]          = list("on_start", "on_perform", "on_finish")

	// Build suppress_defaults map — one boolean per phase for the selected action.
	var/list/suppress_defaults = list(
		"on_start"   = FALSE,
		"on_perform" = FALSE,
		"on_finish"  = FALSE,
	)
	if(selected_action_path && islist(prefs.custom_sex_flavors))
		all_flavors = prefs.custom_sex_flavors
		var/list/action_data = all_flavors[selected_action_path]
		if(islist(action_data))
			var/list/suppress_data = action_data["suppress"]
			if(islist(suppress_data))
				for(var/phase in suppress_defaults)
					suppress_defaults[phase] = !!suppress_data[phase]
	data["suppress_defaults"] = suppress_defaults

	// ── Preset selector + perspective data ──────────────────────────────────
	data["selected_preset"] = selected_preset
	data["selected_perspective"] = selected_perspective
	var/list/preset_list = list()
	for(var/key in GLOB.sex_action_preset_keys)
		preset_list += list(list("key" = key, "label" = GLOB.sex_action_preset_labels[key]))
	data["presets"] = preset_list

	// ── Default text from JSON bank for the selected action + preset + perspective ─
	// Use empty strings instead of null so json_encode always includes the keys.
	// This prevents the frontend's shallow merge from preserving stale values
	// when switching between presets (BYOND removes null-valued keys from lists).
	data["default_on_start"]   = ""
	data["default_on_perform"] = ""
	data["default_on_finish"]  = ""
	if(selected_action_path)
		var/start_text = get_preset_action_text(selected_preset, selected_action_path, selected_perspective, "on_start")
		var/perform_text = get_preset_action_text(selected_preset, selected_action_path, selected_perspective, "on_perform")
		var/finish_text = get_preset_action_text(selected_preset, selected_action_path, selected_perspective, "on_finish")
		if(start_text)
			data["default_on_start"] = start_text
		if(perform_text)
			data["default_on_perform"] = perform_text
		if(finish_text)
			data["default_on_finish"] = finish_text

	// ── Custom Actions tab data ──────────────────────────────────────────────
	// Templates — preset archetypes for creating new custom actions.
	data["custom_templates"] = list(
		list("key" = "penetration", "name" = "Penetration",
			"category" = SEX_CATEGORY_PENETRATE,
			"user_sex_part" = SEX_PART_COCK, "target_sex_part" = SEX_PART_CUNT,
			"user_arousal" = 2, "target_arousal" = 3, "user_pain" = 0, "target_pain" = 4,
			"stamina_cost" = 1, "requires_other" = TRUE, "continuous" = TRUE),
		list("key" = "anal", "name" = "Anal",
			"category" = SEX_CATEGORY_PENETRATE,
			"user_sex_part" = SEX_PART_COCK, "target_sex_part" = SEX_PART_ANUS,
			"user_arousal" = 2, "target_arousal" = 2, "user_pain" = 0, "target_pain" = 6,
			"stamina_cost" = 1, "requires_other" = TRUE, "continuous" = TRUE),
		list("key" = "oral", "name" = "Oral",
			"category" = SEX_CATEGORY_MISC,
			"user_sex_part" = SEX_PART_JAWS, "target_sex_part" = SEX_PART_COCK,
			"user_arousal" = 1, "target_arousal" = 3, "user_pain" = 0, "target_pain" = 0,
			"stamina_cost" = 1, "requires_other" = TRUE, "continuous" = TRUE),
		list("key" = "manual", "name" = "Manual / Hands",
			"category" = SEX_CATEGORY_HANDS,
			"user_sex_part" = SEX_PART_NULL, "target_sex_part" = SEX_PART_NULL,
			"user_arousal" = 1, "target_arousal" = 2, "user_pain" = 0, "target_pain" = 0,
			"stamina_cost" = 1, "requires_other" = TRUE, "continuous" = TRUE),
		list("key" = "ride", "name" = "Ride",
			"category" = SEX_CATEGORY_PENETRATE,
			"user_sex_part" = SEX_PART_CUNT, "target_sex_part" = SEX_PART_COCK,
			"user_arousal" = 3, "target_arousal" = 2, "user_pain" = 2, "target_pain" = 0,
			"stamina_cost" = 2, "requires_other" = TRUE, "continuous" = TRUE),
		list("key" = "self", "name" = "Self / Solo",
			"category" = SEX_CATEGORY_MISC,
			"user_sex_part" = SEX_PART_NULL, "target_sex_part" = SEX_PART_NULL,
			"user_arousal" = 2, "target_arousal" = 0, "user_pain" = 0, "target_pain" = 0,
			"stamina_cost" = 1, "requires_other" = FALSE, "continuous" = TRUE),
	)

	// Current custom actions list.
	var/list/custom_actions_out = list()
	if(islist(prefs.custom_sex_actions))
		for(var/list/ca in prefs.custom_sex_actions)
			custom_actions_out += list(list(
				"slot"            = ca["slot"],
				"name"            = ca["name"],
				"template"        = ca["template"],
				"on_start_text"   = ca["on_start_text"],
				"on_perform_text" = ca["on_perform_text"],
				"on_finish_text"  = ca["on_finish_text"],
				"user_arousal"    = ca["user_arousal"],
				"target_arousal"  = ca["target_arousal"],
				"user_pain"       = ca["user_pain"],
				"target_pain"     = ca["target_pain"],
				"stamina_cost"    = ca["stamina_cost"],
				"category"        = ca["category"],
				"user_sex_part"   = ca["user_sex_part"],
				"target_sex_part" = ca["target_sex_part"],
				"requires_other"  = ca["requires_other"],
				"continuous"      = ca["continuous"],
				"req_user_chastity"   = ca["req_user_chastity"],
				"req_target_chastity" = ca["req_target_chastity"],
				"req_toy"             = ca["req_toy"],
				"req_user_piercing"   = ca["req_user_piercing"],
				"req_user_plug"       = ca["req_user_plug"],
				"req_target_piercing" = ca["req_target_piercing"],
				"req_target_plug"     = ca["req_target_plug"],
				"req_no_rear_plug"    = ca["req_no_rear_plug"],
				"req_user_manticore_tail"  = ca["req_user_manticore_tail"],
				"req_target_manticore_tail" = ca["req_target_manticore_tail"],
				"req_user_jelly"      = ca["req_user_jelly"],
				"req_target_jelly"    = ca["req_target_jelly"],
			))
	data["custom_actions"] = custom_actions_out
	data["max_custom_actions"] = MAX_CUSTOM_SEX_ACTIONS
	data["selected_custom_slot"] = selected_custom_slot

	return data

/datum/sex_flavor_editor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return TRUE
	if(!is_valid())
		return FALSE

	var/datum/preferences/prefs = get_prefs()
	if(!prefs)
		return FALSE

	switch(action)
		if("select_action")
			var/path_text = params["path"]
			if(!istext(path_text))
				return FALSE
			var/path = text2path(path_text)
			if(!path || !(path in GLOB.sex_actions))
				return FALSE
			selected_action_path = path_text
			return TRUE

		if("select_phase")
			var/phase = params["phase"]
			if(!(phase in list("on_start", "on_perform", "on_finish")))
				return FALSE
			selected_phase = phase
			return TRUE

		if("select_preset")
			var/key = params["key"]
			if(!istext(key) || !(key in GLOB.sex_action_preset_keys))
				return FALSE
			selected_preset = key
			return TRUE

		if("select_perspective")
			var/persp = params["perspective"]
			if(!(persp in list("performer", "target", "observer")))
				return FALSE
			selected_perspective = persp
			return TRUE

		if("apply_preset_all")
			// Apply the selected preset's text to ALL registered sex actions at once.
			// This overwrites every action's custom_sex_flavors entry with the preset text.
			var/preset_key = params["key"]
			if(!istext(preset_key) || !(preset_key in GLOB.sex_action_preset_keys))
				return FALSE
			var/list/all_presets = get_sex_action_presets()
			var/list/preset_data = all_presets[preset_key]
			if(!islist(preset_data))
				// Fallback to humanoid if preset has no data at all.
				preset_data = all_presets["humanoid"]
			if(!islist(preset_data))
				to_chat(usr, span_warning("No preset data found for '[preset_key]'."))
				return FALSE
			// Build fresh custom_sex_flavors from the preset.
			var/list/new_flavors = list()
			for(var/path in GLOB.sex_actions)
				var/datum/sex_action/A = GLOB.sex_actions[path]
				if(!A || A.category == SEX_CATEGORY_NULL)
					continue
				var/path_text = "[path]"
				var/list/action_entry = list()
				var/has_any = FALSE
				// Iterate over all perspective+phase combinations.
				for(var/persp in list("performer", "target", "observer"))
					for(var/phase in list("on_start", "on_perform", "on_finish"))
						var/text = get_preset_action_text(preset_key, path_text, persp, phase)
						if(text)
							var/persp_phase_key = "[persp]_[phase]"
							action_entry[persp_phase_key] = list(text)
							action_entry["weight_[persp_phase_key]"] = list(100)
							has_any = TRUE
				if(has_any)
					new_flavors[path_text] = action_entry
			prefs.custom_sex_flavors = new_flavors
			prefs.save_character()
			to_chat(usr, span_notice("Applied '[GLOB.sex_action_preset_labels[preset_key]]' preset to all actions."))
			return TRUE

		if("add_string")
			if(!selected_action_path)
				return FALSE
			var/new_str = sanitize(params["text"])
			if(!istext(new_str) || !length(new_str))
				return FALSE
			new_str = copytext(new_str, 1, SEX_FLAVOR_MAX_LENGTH + 1)
			// Initialize list structure on demand.
			if(!islist(prefs.custom_sex_flavors))
				prefs.custom_sex_flavors = list()
			if(!islist(prefs.custom_sex_flavors[selected_action_path]))
				prefs.custom_sex_flavors[selected_action_path] = list()
			var/list/action_data = prefs.custom_sex_flavors[selected_action_path]
			// Perspective-prefixed key: "performer_on_start", "target_on_perform", etc.
			var/persp_key = "[selected_perspective]_[selected_phase]"
			if(!islist(action_data[persp_key]))
				action_data[persp_key] = list()
			var/list/phase_list = action_data[persp_key]
			if(phase_list.len >= SEX_FLAVOR_MAX_STRINGS)
				return FALSE
			phase_list += new_str
			// Also append default weight for the new string.
			var/weight_key = "weight_[persp_key]"
			if(islist(action_data[weight_key]))
				var/list/weight_list = action_data[weight_key]
				weight_list += 100
			prefs.save_character()
			return TRUE

		if("remove_string")
			if(!selected_action_path || !islist(prefs.custom_sex_flavors))
				return FALSE
			var/idx = text2num(params["index"])
			if(!idx || idx < 1)
				return FALSE
			var/list/action_data = prefs.custom_sex_flavors[selected_action_path]
			if(!islist(action_data))
				return FALSE
			var/persp_key = "[selected_perspective]_[selected_phase]"
			var/list/phase_list = action_data[persp_key]
			// Fallback to legacy un-prefixed key.
			if(!islist(phase_list))
				phase_list = action_data[selected_phase]
			if(!islist(phase_list) || idx > phase_list.len)
				return FALSE
			phase_list.Cut(idx, idx + 1)
			// Also remove the parallel weight entry if it exists.
			var/weight_key = "weight_[persp_key]"
			if(islist(action_data[weight_key]))
				var/list/weight_list = action_data[weight_key]
				if(idx <= weight_list.len)
					weight_list.Cut(idx, idx + 1)
			prefs.save_character()
			return TRUE

		if("update_string")
			// Replace an existing custom string at a given index (1-based).
			if(!selected_action_path || !islist(prefs.custom_sex_flavors))
				return FALSE
			var/idx = text2num(params["index"])
			if(!idx || idx < 1)
				return FALSE
			var/new_str = sanitize(params["text"])
			if(!istext(new_str) || !length(new_str))
				return FALSE
			new_str = copytext(new_str, 1, SEX_FLAVOR_MAX_LENGTH + 1)
			var/list/action_data = prefs.custom_sex_flavors[selected_action_path]
			if(!islist(action_data))
				return FALSE
			var/persp_key = "[selected_perspective]_[selected_phase]"
			var/list/phase_list = action_data[persp_key]
			if(!islist(phase_list))
				phase_list = action_data[selected_phase]
			if(!islist(phase_list) || idx > phase_list.len)
				return FALSE
			phase_list[idx] = new_str
			prefs.save_character()
			return TRUE

		if("toggle_suppress")
			// Flip the suppression flag for the given phase on the selected action.
			var/phase = params["phase"]
			if(!(phase in list("on_start", "on_perform", "on_finish")))
				return FALSE
			if(!selected_action_path)
				return FALSE
			if(!islist(prefs.custom_sex_flavors))
				prefs.custom_sex_flavors = list()
			if(!islist(prefs.custom_sex_flavors[selected_action_path]))
				prefs.custom_sex_flavors[selected_action_path] = list()
			var/list/action_data = prefs.custom_sex_flavors[selected_action_path]
			if(!islist(action_data["suppress"]))
				action_data["suppress"] = list()
			var/list/suppress_data = action_data["suppress"]
			// Toggle: TRUE → remove key (FALSE is the implicit default); FALSE → set TRUE.
			if(suppress_data[phase])
				suppress_data.Remove(phase)
			else
				suppress_data[phase] = TRUE
			// If the suppress block and strings are all empty, clean up the action entry.
			if(!suppress_data.len)
				action_data.Remove("suppress")
			prefs.save_character()
			return TRUE

		if("set_weight")
			// Set the weight (0-100) for a specific string index.
			if(!selected_action_path || !islist(prefs.custom_sex_flavors))
				return FALSE
			var/idx = text2num(params["index"])
			var/weight = clamp(text2num(params["weight"]), 0, 100)
			if(!idx || idx < 1)
				return FALSE
			var/list/action_data = prefs.custom_sex_flavors[selected_action_path]
			if(!islist(action_data))
				return FALSE
			var/persp_key = "[selected_perspective]_[selected_phase]"
			var/list/phase_list = action_data[persp_key]
			if(!islist(phase_list))
				phase_list = action_data[selected_phase]
			if(!islist(phase_list) || idx > phase_list.len)
				return FALSE
			// Initialize weight list on demand, padded to match strings.
			var/weight_key = "weight_[persp_key]"
			if(!islist(action_data[weight_key]))
				action_data[weight_key] = list()
			var/list/weight_list = action_data[weight_key]
			while(weight_list.len < phase_list.len)
				weight_list += 100
			weight_list[idx] = weight
			prefs.save_character()
			return TRUE

		if("clear_action")
			if(!selected_action_path || !islist(prefs.custom_sex_flavors))
				return FALSE
			// Remove the entire action entry, including any suppress flags.
			prefs.custom_sex_flavors.Remove(selected_action_path)
			if(!prefs.custom_sex_flavors.len)
				prefs.custom_sex_flavors = null
			prefs.save_character()
			return TRUE

		if("toggle_show_all")
			show_all_actions = !show_all_actions
			return TRUE

		// ── Custom action CRUD ───────────────────────────────────────────
		if("select_custom_slot")
			selected_custom_slot = clamp(text2num("[params["slot"]]"), 0, MAX_CUSTOM_SEX_ACTIONS)
			return TRUE

		if("create_action")
			// Create a new custom action from a template.
			if(!islist(prefs.custom_sex_actions))
				prefs.custom_sex_actions = list()
			if(prefs.custom_sex_actions.len >= MAX_CUSTOM_SEX_ACTIONS)
				return FALSE
			// Find next free slot (1-5).
			var/list/used_slots = list()
			for(var/list/existing in prefs.custom_sex_actions)
				used_slots += existing["slot"]
			var/free_slot = 0
			for(var/i in 1 to MAX_CUSTOM_SEX_ACTIONS)
				if(!(i in used_slots))
					free_slot = i
					break
			if(!free_slot)
				return FALSE
			var/action_name = sanitize(copytext("[params["name"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))
			if(!length(action_name))
				action_name = "Custom Action [free_slot]"
			var/list/new_action = list(
				"slot"            = free_slot,
				"name"            = action_name,
				"template"        = sanitize(copytext("[params["template"]]", 1, 64)),
				"on_start_text"   = sanitize(copytext("[params["on_start_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1)),
				"on_perform_text" = sanitize(copytext("[params["on_perform_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1)),
				"on_finish_text"  = sanitize(copytext("[params["on_finish_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1)),
				"user_arousal"    = clamp(text2num("[params["user_arousal"]]"), 0, 5),
				"target_arousal"  = clamp(text2num("[params["target_arousal"]]"), 0, 5),
				"user_pain"       = clamp(text2num("[params["user_pain"]]"), 0, 15),
				"target_pain"     = clamp(text2num("[params["target_pain"]]"), 0, 15),
				"stamina_cost"    = clamp(text2num("[params["stamina_cost"]]"), 0, 3),
				"category"        = clamp(text2num("[params["category"]]"), 0, 7),
				"user_sex_part"   = clamp(text2num("[params["user_sex_part"]]"), 0, 31),
				"target_sex_part" = clamp(text2num("[params["target_sex_part"]]"), 0, 31),
				"requires_other"  = !!params["requires_other"],
				"continuous"      = !!params["continuous"],
				"req_user_chastity"   = clamp(text2num("[params["req_user_chastity"]]"), 0, 2),
				"req_target_chastity" = clamp(text2num("[params["req_target_chastity"]]"), 0, 2),
				"req_toy"             = clamp(text2num("[params["req_toy"]]"), 0, 3),
				"req_user_piercing"   = !!params["req_user_piercing"],
				"req_user_plug"       = !!params["req_user_plug"],
				"req_target_piercing" = !!params["req_target_piercing"],
				"req_target_plug"     = !!params["req_target_plug"],
				"req_no_rear_plug"    = !!params["req_no_rear_plug"],
				"req_user_manticore_tail"  = !!params["req_user_manticore_tail"],
				"req_target_manticore_tail" = !!params["req_target_manticore_tail"],
				"req_user_jelly"      = !!params["req_user_jelly"],
				"req_target_jelly"    = !!params["req_target_jelly"],
			)
			prefs.custom_sex_actions += list(new_action)
			selected_custom_slot = free_slot
			prefs.save_character()
			log_game("CUSTOM_SEX_ACTION: [key_name(usr)] created custom action '[action_name]' (slot [free_slot], template '[new_action["template"]]', category [new_action["category"]])")
			return TRUE

		if("update_action")
			// Update an existing custom action by slot number.
			var/slot = text2num("[params["slot"]]")
			if(!slot || slot < 1 || slot > MAX_CUSTOM_SEX_ACTIONS)
				return FALSE
			if(!islist(prefs.custom_sex_actions))
				return FALSE
			for(var/i in 1 to prefs.custom_sex_actions.len)
				var/list/entry = prefs.custom_sex_actions[i]
				if(entry["slot"] != slot)
					continue
				// Update only supplied fields.
				if(params["name"])
					entry["name"] = sanitize(copytext("[params["name"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))
				if("on_start_text" in params)
					entry["on_start_text"] = sanitize(copytext("[params["on_start_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))
				if("on_perform_text" in params)
					entry["on_perform_text"] = sanitize(copytext("[params["on_perform_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))
				if("on_finish_text" in params)
					entry["on_finish_text"] = sanitize(copytext("[params["on_finish_text"]]", 1, SEX_FLAVOR_MAX_LENGTH + 1))
				if("user_arousal" in params)
					entry["user_arousal"] = clamp(text2num("[params["user_arousal"]]"), 0, 5)
				if("target_arousal" in params)
					entry["target_arousal"] = clamp(text2num("[params["target_arousal"]]"), 0, 5)
				if("user_pain" in params)
					entry["user_pain"] = clamp(text2num("[params["user_pain"]]"), 0, 15)
				if("target_pain" in params)
					entry["target_pain"] = clamp(text2num("[params["target_pain"]]"), 0, 15)
				if("stamina_cost" in params)
					entry["stamina_cost"] = clamp(text2num("[params["stamina_cost"]]"), 0, 3)
				if("category" in params)
					entry["category"] = clamp(text2num("[params["category"]]"), 0, 7)
				if("user_sex_part" in params)
					entry["user_sex_part"] = clamp(text2num("[params["user_sex_part"]]"), 0, 31)
				if("target_sex_part" in params)
					entry["target_sex_part"] = clamp(text2num("[params["target_sex_part"]]"), 0, 31)
				if("requires_other" in params)
					entry["requires_other"] = !!params["requires_other"]
				if("continuous" in params)
					entry["continuous"] = !!params["continuous"]
				if("req_user_chastity" in params)
					entry["req_user_chastity"] = clamp(text2num("[params["req_user_chastity"]]"), 0, 2)
				if("req_target_chastity" in params)
					entry["req_target_chastity"] = clamp(text2num("[params["req_target_chastity"]]"), 0, 2)
				if("req_toy" in params)
					entry["req_toy"] = clamp(text2num("[params["req_toy"]]"), 0, 3)
				if("req_user_piercing" in params)
					entry["req_user_piercing"] = !!params["req_user_piercing"]
				if("req_user_plug" in params)
					entry["req_user_plug"] = !!params["req_user_plug"]
				if("req_target_piercing" in params)
					entry["req_target_piercing"] = !!params["req_target_piercing"]
				if("req_target_plug" in params)
					entry["req_target_plug"] = !!params["req_target_plug"]
				if("req_no_rear_plug" in params)
					entry["req_no_rear_plug"] = !!params["req_no_rear_plug"]
				if("req_user_manticore_tail" in params)
					entry["req_user_manticore_tail"] = !!params["req_user_manticore_tail"]
				if("req_target_manticore_tail" in params)
					entry["req_target_manticore_tail"] = !!params["req_target_manticore_tail"]
				if("req_user_jelly" in params)
					entry["req_user_jelly"] = !!params["req_user_jelly"]
				if("req_target_jelly" in params)
					entry["req_target_jelly"] = !!params["req_target_jelly"]
				prefs.save_character()
				return TRUE
			return FALSE

		if("delete_action")
			var/slot = text2num("[params["slot"]]")
			if(!slot || slot < 1 || slot > MAX_CUSTOM_SEX_ACTIONS)
				return FALSE
			if(!islist(prefs.custom_sex_actions))
				return FALSE
			for(var/i in 1 to prefs.custom_sex_actions.len)
				var/list/entry = prefs.custom_sex_actions[i]
				if(entry["slot"] != slot)
					continue
				var/deleted_name = entry["name"]
				prefs.custom_sex_actions.Cut(i, i + 1)
				if(!prefs.custom_sex_actions.len)
					prefs.custom_sex_actions = null
				if(selected_custom_slot == slot)
					selected_custom_slot = 0
				prefs.save_character()
				log_game("CUSTOM_SEX_ACTION: [key_name(usr)] deleted custom action '[deleted_name]' (slot [slot])")
				return TRUE
			return FALSE

		// ── Export / Import ──────────────────────────────────────────────
		/**
		 * Export and Import allow players to share their custom sex flavor
		 * text and custom action definitions as a single portable string.
		 *
		 * ## Format
		 * The payload is a **base64-encoded JSON object** with two optional keys:
		 *
		 *   {
		 *     "flavors": { ... },   // custom_sex_flavors — per-action, per-phase string pools
		 *     "actions": [ ... ]    // custom_sex_actions — list of action config objects
		 *   }
		 *
		 * Either key may be null/absent if the player has no data of that type.
		 *
		 * ## How to use
		 * 1. Click **Export** in the Sex Flavor Text Editor to copy your data
		 *    string to the BYOND output window.
		 * 2. Copy the string and send it to another player (Discord, notepad, etc.).
		 * 3. The receiving player clicks **Import**, pastes the string into the
		 *    input box, and confirms. Their existing data is **replaced** — not
		 *    merged — so they should export first if they want a backup.
		 *
		 * The string is not human-readable by design; editing it by hand will
		 * almost certainly corrupt it. Use the in-game editor instead.
		 */
		if("export_data")
			var/list/export_payload = list()
			if(islist(prefs.custom_sex_flavors) && prefs.custom_sex_flavors.len)
				export_payload["flavors"] = prefs.custom_sex_flavors
			if(islist(prefs.custom_sex_actions) && prefs.custom_sex_actions.len)
				export_payload["actions"] = prefs.custom_sex_actions
			if(!export_payload.len)
				to_chat(usr, span_warning("Nothing to export — no custom flavor text or actions configured."))
				return FALSE
			var/json_str = json_encode(export_payload)
			var/encoded = rustg_encode_base64(json_str)
			to_chat(usr, span_notice("<b>Sex Flavor Export</b> — copy the string below and share it:"))
			to_chat(usr, "<span class='notice' style='word-break:break-all;'>[encoded]</span>")
			return TRUE

		if("import_data")
			var/raw_input = params["payload"]
			if(!istext(raw_input) || !length(raw_input))
				to_chat(usr, span_warning("Import failed: no data provided."))
				return FALSE
			// Strip whitespace that might have been copied along with the string.
			raw_input = trim(raw_input)
			var/decoded = rustg_decode_base64(raw_input)
			if(!istext(decoded) || !length(decoded))
				to_chat(usr, span_warning("Import failed: could not decode the string. Make sure you copied it exactly."))
				return FALSE
			var/list/payload
			try
				payload = json_decode(decoded)
			catch
				to_chat(usr, span_warning("Import failed: corrupt data. The string may have been truncated or edited."))
				return FALSE
			if(!islist(payload))
				to_chat(usr, span_warning("Import failed: unexpected data format."))
				return FALSE
			// Apply flavors.
			if(islist(payload["flavors"]))
				prefs.custom_sex_flavors = payload["flavors"]
			else
				prefs.custom_sex_flavors = null
			// Apply actions (cap at MAX_CUSTOM_SEX_ACTIONS).
			if(islist(payload["actions"]))
				var/list/imported_actions = payload["actions"]
				if(imported_actions.len > MAX_CUSTOM_SEX_ACTIONS)
					imported_actions.Cut(MAX_CUSTOM_SEX_ACTIONS + 1)
				prefs.custom_sex_actions = imported_actions
			else
				prefs.custom_sex_actions = null
			// Sanitize imported data through the same validators used on savefile load.
			prefs.validate_custom_sex_flavors()
			prefs.validate_custom_sex_actions()
			prefs.save_character()
			to_chat(usr, span_notice("Import successful! Your custom sex flavors and actions have been updated."))
			return TRUE

	return FALSE


// ── Lobby subtype ────────────────────────────────────────────────────────────
/**
 * Lobby-side sex flavor editor that operates purely on preference data.
 * No spawned mob is needed — anatomy checks default to TRUE (show all actions)
 * since the character hasn't been created yet.
 *
 * Custom sex actions are per-character: stored in the character's savefile
 * via `datum/preferences` and loaded when the character slot is selected.
 */
/datum/sex_flavor_editor/lobby
	/// Direct reference to the character's preferences datum.
	var/datum/preferences/prefs

/datum/sex_flavor_editor/lobby/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P
	// Skip parent New() — it expects a human mob.

/datum/sex_flavor_editor/lobby/Destroy()
	prefs = null
	return ..()

/datum/sex_flavor_editor/lobby/get_prefs()
	return prefs

/datum/sex_flavor_editor/lobby/check_anatomy(datum/sex_action/A)
	// No mob in lobby — show all actions so players can configure freely.
	return TRUE

/datum/sex_flavor_editor/lobby/is_valid()
	return !!prefs

/datum/sex_flavor_editor/lobby/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "SexFlavorEditor", "Sex Flavor Text Editor", 960, 760)
		ui.set_state(GLOB.always_state)
		ui.open()

/datum/sex_flavor_editor/lobby/ui_state(mob/user)
	return GLOB.always_state

/*
 * body.dm — TGUI Preferences Menu, Body category (Step 11 part A).
 *
 * Registers Body-row pref setters into GLOB.prefs_setter_table and
 * implements the matching `set_pref_*` procs on /datum/preferences.
 * Mirrors the shape of identity.dm — see that file for the rationale
 * behind the validator + setter split. Step 11 covers the structural
 * appearance fields (race, body model, coloration, hair, head accents);
 * markings/genitals/taur live in Step 12 part B.
 *
 * Performance: registration is one-shot and idempotent. All setters
 * are O(1) field writes; the species setter is the only one that
 * allocates (a single new species datum) and is the only stat-matrix
 * invalidator in this file (declared via the fourth arg to
 * register_prefs_setter).
 */

#define PREF_KEY_SPECIES               "species"
#define PREF_KEY_BODY_TYPE             "body_type"
#define PREF_KEY_SKIN_TONE             "skin_tone"
#define PREF_KEY_EYE_COLOR             "eye_color"
#define PREF_KEY_HAIRSTYLE             "hairstyle"
#define PREF_KEY_HAIR_COLOR            "hair_color"
#define PREF_KEY_FACIAL_HAIRSTYLE      "facial_hairstyle"
#define PREF_KEY_FACIAL_HAIR_COLOR     "facial_hair_color"
#define PREF_KEY_DETAIL                "detail"
#define PREF_KEY_DETAIL_COLOR          "detail_color"
#define PREF_KEY_ACCESSORY             "accessory"
#define PREF_KEY_BODY_SIZE_X100        "body_size_x100"

// --- Step 12 part B: Extremities / Markings / Genitals / Taur ----------
// Extremities — mutant colour scalars stored under the features assoc.
#define PREF_KEY_MUTANT_COLOR_1        "mutant_color_1"
#define PREF_KEY_MUTANT_COLOR_2        "mutant_color_2"
#define PREF_KEY_MUTANT_COLOR_3        "mutant_color_3"
#define PREF_KEY_ETHEREAL_COLOR        "ethereal_color"
// Taur sprite + colour scalars on /datum/preferences. The detail editor
// (taur_genital_offset_editor) owns per-direction props; these scalars
// drive the base mannequin look.
#define PREF_KEY_TAUR_TYPE             "taur_type"
#define PREF_KEY_TAUR_COLOR            "taur_color"
#define PREF_KEY_TAUR_MARKINGS_COLOR   "taur_markings_color"
#define PREF_KEY_TAUR_TERTIARY_COLOR   "taur_tertiary_color"
#define PREF_KEY_USE_TAUR_GENITAL_SPRITES "use_taur_genital_sprites"
// PREF_KEY_TAUR_CONSISTENT_AROUSAL / TAUR_MIRROR_EW / TESTICLE_MIRROR_EW
// are declared in code/__DEFINES/preferences_tgui.dm (predates this file).

// Length caps for the free-form string fields. Hairstyle / accessory
// names are sourced from globals at runtime; the cap is purely a
// payload bound, not a semantic check.
#define BODY_MAX_NAME_LEN              64

/*
 * Hook called by register_prefs_setters() in prefs_set_pref_dispatch.dm.
 * register_prefs_setter() rejects duplicate keys via stack_trace, so a
 * collision with identity.dm or a future category surfaces immediately
 * during compile-test.
 */
/proc/register_prefs_body_setters()
	// Race/species — stat-affecting (statpack derived from species).
	register_prefs_setter(PREF_KEY_SPECIES, GLOBAL_PROC_REF(prefs_validate_species_name), "set_pref_species", TRUE, TRUE)
	// Mannequin body model. Reuses the gender enum because that is the
	// var the appearance pipeline reads. Identity also exposes gender,
	// but BodyType is the geometry-affecting surface; both write the
	// same /datum/preferences var by design.
	register_prefs_setter(PREF_KEY_BODY_TYPE, prefs_validate_enum(list(MALE, FEMALE)), "set_pref_body_type", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_SKIN_TONE, GLOBAL_PROC_REF(prefs_validate_skin_tone), "set_pref_skin_tone", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_EYE_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_eye_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_HAIRSTYLE, prefs_validate_string(BODY_MAX_NAME_LEN), "set_pref_hairstyle", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_HAIR_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_hair_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_FACIAL_HAIRSTYLE, prefs_validate_string(BODY_MAX_NAME_LEN), "set_pref_facial_hairstyle", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_FACIAL_HAIR_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_facial_hair_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_DETAIL, prefs_validate_string(BODY_MAX_NAME_LEN), "set_pref_detail", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_DETAIL_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_detail_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_ACCESSORY, prefs_validate_string(BODY_MAX_NAME_LEN), "set_pref_accessory", FALSE, TRUE)
	// Body size lives in the features assoc list as a float. Wire form
	// is integer percent (×100) so the validator stays in intrange land.
	register_prefs_setter(PREF_KEY_BODY_SIZE_X100, prefs_validate_intrange(round(BODY_SIZE_MIN * 100), round(BODY_SIZE_MAX * 100)), "set_pref_body_size_x100", FALSE, TRUE)

	// --- Step 12 part B ---------------------------------------------------
	// Extremities → mutant colours (features assoc) + ethereal colour.
	register_prefs_setter(PREF_KEY_MUTANT_COLOR_1, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_mutant_color_1", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_MUTANT_COLOR_2, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_mutant_color_2", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_MUTANT_COLOR_3, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_mutant_color_3", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_ETHEREAL_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_ethereal_color", FALSE, TRUE)
	// Taur surface scalars. taur_type is a free-text id (validated by the
	// taur sprite renderer at apply-time); colours are hex.
	register_prefs_setter(PREF_KEY_TAUR_TYPE, prefs_validate_string(BODY_MAX_NAME_LEN), "set_pref_taur_type", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_TAUR_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_taur_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_TAUR_MARKINGS_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_taur_markings_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_TAUR_TERTIARY_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_taur_tertiary_color", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_USE_TAUR_GENITAL_SPRITES, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_use_taur_genital_sprites", FALSE, TRUE)
	// Taur mirror/consistency toggles. Default TRUE on the datum (declared
	// below); when flipped to FALSE, the taur editor begins emitting
	// per-side / per-state asymmetric props. Snapshot-and-restore of
	// asymmetric values is handled inside the editor itself, which already
	// keeps a draft buffer; the toggle merely gates which side of the
	// switch the editor writes through.
	register_prefs_setter(PREF_KEY_TAUR_CONSISTENT_AROUSAL, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_taur_consistent_arousal")
	register_prefs_setter(PREF_KEY_TAUR_MIRROR_EW, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_taur_mirror_ew")
	register_prefs_setter(PREF_KEY_TESTICLE_MIRROR_EW, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_testicle_mirror_ew")

	// --- B1 deviation pass: race/nobility title (freeform string) -------
	register_prefs_setter(PREF_KEY_RACE_TITLE, prefs_validate_string(BODY_MAX_NAME_LEN), "set_pref_race_title")

/*
 * Validators
 *
 * Bare global procs so they can be passed via GLOBAL_PROC_REF without
 * a per-setter callback allocation. Each accepts the raw client value
 * and returns TRUE iff it is acceptable.
 */
/proc/prefs_validate_species_name(value)
	if(!istext(value) || !length(value))
		return FALSE
	var/list/selectable = get_selectable_species()
	return (value in selectable) ? TRUE : FALSE

/proc/prefs_validate_skin_tone(value)
	return prefs_validate_hex(value)

// ---------------------------------------------------------------------------
// Setter procs
//
// Each accepts a pre-validated value and writes the matching savefile
// var. The leaf setters reuse identity.dm's _pref_apply_text helper for
// length-bounded string writes. No re-validation here; sanitize_*() on
// next character load catches schema drift.
// ---------------------------------------------------------------------------

/datum/preferences/proc/set_pref_species(value)
	// Resolve the human-readable species name to a /datum/species
	// subtype via GLOB.species_list (populated in /world/Initialize).
	if(!istext(value) || !length(value))
		return
	if(!GLOB.species_list)
		return
	var/path = GLOB.species_list[value]
	if(!path)
		return
	pref_species = new path()

/datum/preferences/proc/set_pref_body_type(value)
	// BodyType writes to gender — the existing appearance pipeline
	// reads gender to pick the mannequin and clothing fits. Identity's
	// set_pref_gender writes the same field; only one register site
	// owns each pref key (BODY here, IDENTITY there) so dispatch is
	// unambiguous.
	gender = value

/datum/preferences/proc/set_pref_skin_tone(value)
	if(istext(value) && length(value) == 7 && copytext(value, 1, 2) == "#")
		value = copytext(value, 2)
	var/clean_value = sanitize_hexcolor(value, 6, FALSE)
	if(!clean_value)
		return
	var/list/valid_skin_tones = pref_species?.get_skin_list()
	if(valid_skin_tones)
		var/found_skin_tone = FALSE
		for(var/skin_label as anything in valid_skin_tones)
			var/valid_skin_value = sanitize_hexcolor(valid_skin_tones[skin_label], 6, FALSE)
			if(LOWER_TEXT(valid_skin_value) != LOWER_TEXT(clean_value))
				continue
			found_skin_tone = TRUE
			break
		if(!found_skin_tone)
			return
	value = clean_value
	skin_tone = value
	try_update_mutant_colors()

/datum/preferences/proc/set_pref_eye_color(value)
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	eye_color = value

/datum/preferences/proc/set_pref_hairstyle(value)
	_pref_apply_text("hairstyle", value, BODY_MAX_NAME_LEN)

/datum/preferences/proc/set_pref_hair_color(value)
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	hair_color = value

/datum/preferences/proc/set_pref_facial_hairstyle(value)
	_pref_apply_text("facial_hairstyle", value, BODY_MAX_NAME_LEN)

/datum/preferences/proc/set_pref_facial_hair_color(value)
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	facial_hair_color = value

/datum/preferences/proc/set_pref_detail(value)
	_pref_apply_text("detail", value, BODY_MAX_NAME_LEN)

/datum/preferences/proc/set_pref_detail_color(value)
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	detail_color = value

/datum/preferences/proc/set_pref_accessory(value)
	_pref_apply_text("accessory", value, BODY_MAX_NAME_LEN)

/datum/preferences/proc/set_pref_body_size_x100(value)
	// Stored as a float (BODY_SIZE_MIN..BODY_SIZE_MAX). Convert from
	// the wire ×100 form and clamp; intrange validator already bounded
	// the input but we re-clamp in case the float math rounds out.
	var/numeric = isnum(value) ? value : text2num("[value]")
	if(isnull(numeric))
		return
	var/scaled = numeric / 100
	if(scaled < BODY_SIZE_MIN)
		scaled = BODY_SIZE_MIN
	if(scaled > BODY_SIZE_MAX)
		scaled = BODY_SIZE_MAX
	if(!features)
		features = list()
	features["body_size"] = scaled

// ---------------------------------------------------------------------------
// Step 12 part B — Extremities / Taur mirror toggles
// ---------------------------------------------------------------------------

// New /datum/preferences vars introduced by this step. Defaults are TRUE
// per spec §4.5: mirror toggles default ON so the existing taur editor
// behaviour (single canonical side, single arousal state) is preserved
// for legacy slots. Savefile migration is additive — missing keys read
// as the documented default via the var initialiser.
/datum/preferences
	var/taur_consistent_arousal = TRUE
	var/taur_mirror_ew = TRUE
	var/testicle_mirror_ew = TRUE

/datum/preferences/proc/_pref_apply_features_hex(field_name, value)
	if(!features)
		features = list()
	if(istext(value) && length(value) == 7 && copytext(value, 1, 2) == "#")
		// features[] historically stores hex without the leading '#'.
		value = copytext(value, 2)
	features[field_name] = value

/datum/preferences/proc/set_pref_mutant_color_1(value)
	_pref_apply_features_hex("mcolor", value)
	try_update_mutant_colors()

/datum/preferences/proc/set_pref_mutant_color_2(value)
	_pref_apply_features_hex("mcolor2", value)
	try_update_mutant_colors()

/datum/preferences/proc/set_pref_mutant_color_3(value)
	_pref_apply_features_hex("mcolor3", value)
	try_update_mutant_colors()

/datum/preferences/proc/set_pref_ethereal_color(value)
	_pref_apply_features_hex("ethcolor", value)

/datum/preferences/proc/set_pref_taur_type(value)
	// taur_type accepts null (no taur) or a string id; the renderer
	// looks the id up at apply-time and falls back to the default if
	// unknown, so we don't gate here.
	if(istext(value) && !length(value))
		taur_type = null
	else
		taur_type = value

/datum/preferences/proc/set_pref_taur_color(value)
	if(istext(value) && length(value) == 7 && copytext(value, 1, 2) == "#")
		value = copytext(value, 2)
	taur_color = value

/datum/preferences/proc/set_pref_taur_markings_color(value)
	if(istext(value) && length(value) == 7 && copytext(value, 1, 2) == "#")
		value = copytext(value, 2)
	taur_markings = value

/datum/preferences/proc/set_pref_taur_tertiary_color(value)
	if(istext(value) && length(value) == 7 && copytext(value, 1, 2) == "#")
		value = copytext(value, 2)
	taur_tertiary = value

/datum/preferences/proc/set_pref_use_taur_genital_sprites(value)
	use_taur_genital_sprites = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_taur_consistent_arousal(value)
	taur_consistent_arousal = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_taur_mirror_ew(value)
	taur_mirror_ew = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_testicle_mirror_ew(value)
	testicle_mirror_ew = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_race_title(value)
	// B1: per-species title bank. The selected species datum owns the
	// list of valid titles via `race_titles` (gated by `use_titles`);
	// "None" is always accepted. Anything else must appear in the
	// current species's bank, matching the legacy tgui_input_list in
	// preferences.dm:2135.
	if(!istext(value) || !length(value) || value == "None")
		selected_title = "None"
		return
	if(!pref_species)
		selected_title = "None"
		return
	if(!pref_species.use_titles || !length(pref_species.race_titles))
		selected_title = "None"
		return
	if(!(value in pref_species.race_titles))
		// Unknown title for this species — clamp to None rather than
		// accept arbitrary freeform input. Matches the legacy flow.
		selected_title = "None"
		return
	selected_title = value

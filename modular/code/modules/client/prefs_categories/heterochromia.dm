/*
 * heterochromia.dm — TGUI Preferences Menu, Body → Coloration inline
 * heterochromia + second-eye-colour (plan addendum Turn 4 — B3).
 *
 * Parallel pattern to genital_toggles.dm: the fields live on
 * /datum/customizer_entry/organ/eyes (heterochromia bool,
 * second_color hex) rather than as flat /datum/preferences vars, so
 * we expose two shadow pref keys and bridge them to the nested entry.
 *
 * Availability probe: /datum/customizer_choice/organ/eyes declares an
 * `allows_heterochromia` flag per-subtype — some non-humanoid eye
 * customizers (e.g. moth compound eyes) opt out. _pref_has_heterochromia
 * consults the active choice subtype for the current pref_species so
 * the TSX can hide the row on species that block it.
 *
 * Security:
 *   - heterochromia_enabled: bool via prefs_validate_bool.
 *   - second_eye_color: 6-digit hex via prefs_validate_hex.
 *   - Setters reject silently when allows_heterochromia is FALSE on
 *     the active choice (mirrors the legacy HTML handler at
 *     eyes.dm:56/60 which returns early on the same guard).
 */

#define PREF_KEY_HETEROCHROMIA_ENABLED "heterochromia_enabled"
#define PREF_KEY_SECOND_EYE_COLOR      "second_eye_color"

/proc/register_prefs_heterochromia_setters()
	register_prefs_setter(PREF_KEY_HETEROCHROMIA_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_heterochromia_enabled", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_SECOND_EYE_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_second_eye_color", FALSE, TRUE)

/*
 * Locate the /datum/customizer_choice/organ/eyes subtype that's
 * currently active for pref_species. Needed for the allows_heterochromia
 * gate; returns null on species that don't declare an eyes customizer.
 */
/datum/preferences/proc/_pref_get_eyes_choice()
	var/datum/customizer_entry/organ/eyes/entry = _pref_get_or_seed_eyes_entry()
	if(!entry || !entry.customizer_choice_type)
		return null
	return CUSTOMIZER_CHOICE(entry.customizer_choice_type)

/*
 * Seed (or look up) the eyes customizer_entry. Mirrors the genital
 * helper: validate_customizer_entries() walks pref_species.customizers
 * and auto-seeds missing entries.
 */
/datum/preferences/proc/_pref_get_or_seed_eyes_entry()
	var/datum/customizer_entry/organ/eyes/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/eyes)
	if(entry)
		return entry
	if(!pref_species)
		return null
	validate_customizer_entries()
	return get_customizer_entry_of_type(/datum/customizer_entry/organ/eyes)

/datum/preferences/proc/set_pref_heterochromia_enabled(value)
	var/datum/customizer_choice/organ/eyes/choice = _pref_get_eyes_choice()
	if(!choice || !choice.allows_heterochromia)
		return
	var/datum/customizer_entry/organ/eyes/entry = _pref_get_or_seed_eyes_entry()
	if(!entry)
		return
	entry.heterochromia = _pref_coerce_bool(value)

/datum/preferences/proc/set_pref_second_eye_color(value)
	var/datum/customizer_choice/organ/eyes/choice = _pref_get_eyes_choice()
	if(!choice || !choice.allows_heterochromia)
		return
	var/datum/customizer_entry/organ/eyes/entry = _pref_get_or_seed_eyes_entry()
	if(!entry)
		return
	// Validator already confirmed #RRGGBB shape; sanitize_hexcolor gives
	// us the canonical lower-case form the rest of the eyes pipeline
	// expects (matches validate_entry behavior at eyes.dm:25).
	entry.second_color = sanitize_hexcolor("[value]", 6, TRUE, initial(entry.second_color))

/datum/preferences/proc/_pref_read_heterochromia_enabled()
	var/datum/customizer_entry/organ/eyes/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/eyes)
	if(!entry)
		return 0
	return entry.heterochromia ? 1 : 0

/datum/preferences/proc/_pref_read_second_eye_color()
	var/datum/customizer_entry/organ/eyes/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/eyes)
	if(!entry)
		return "#111111"
	return entry.second_color

/datum/preferences/proc/_pref_has_heterochromia()
	var/datum/customizer_choice/organ/eyes/choice = _pref_get_eyes_choice()
	if(!choice)
		return FALSE
	return choice.allows_heterochromia ? TRUE : FALSE

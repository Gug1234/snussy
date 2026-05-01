/**
 * Step 13 — Class & Stats category.
 *
 * Historically every row delegated to the legacy vices_menu / LanguageMenu /
 * LoadoutMenu windows via the Step 14 launch_singleton handshake. The
 * deviation pass (C3/C4/C5) added inline dropdowns co-existing with the
 * legacy HTML surface; this file registers the flat pref setters that
 * back those inline rows. All setters are stat-matrix invalidators
 * because statpack / virtue / vice apply stat deltas (the aggregator
 * in stat_matrix.dm reads these datum instances directly).
 *
 * Wire format:
 *   - statpack / virtue / virtue_two / vice_N: typepath STRING
 *     (text2path'd server-side; empty string clears the slot).
 *   - extra_language_1 / extra_language_2: language name STRING
 *     (validated against GLOB.all_languages; empty/"None" clears).
 *
 * The legacy vices_menu continues to write to the same /datum/preferences
 * vars, so both surfaces stay in sync without extra plumbing.
 */

/proc/register_prefs_class_stats_setters()
	register_prefs_setter(PREF_KEY_JOBLESS_ROLE, GLOBAL_PROC_REF(prefs_validate_jobless_role), "set_pref_jobless_role")
	register_prefs_setter(PREF_KEY_STATPACK, GLOBAL_PROC_REF(prefs_validate_statpack_path), "set_pref_statpack", TRUE)
	register_prefs_setter(PREF_KEY_VIRTUE, GLOBAL_PROC_REF(prefs_validate_virtue_path), "set_pref_virtue", TRUE)
	register_prefs_setter(PREF_KEY_VIRTUE_TWO, GLOBAL_PROC_REF(prefs_validate_virtue_path), "set_pref_virtue_two", TRUE)
	register_prefs_setter(PREF_KEY_VICE_1, GLOBAL_PROC_REF(prefs_validate_vice_path), "set_pref_vice_1", TRUE)
	register_prefs_setter(PREF_KEY_VICE_2, GLOBAL_PROC_REF(prefs_validate_vice_path), "set_pref_vice_2", TRUE)
	register_prefs_setter(PREF_KEY_VICE_3, GLOBAL_PROC_REF(prefs_validate_vice_path), "set_pref_vice_3", TRUE)
	register_prefs_setter(PREF_KEY_VICE_4, GLOBAL_PROC_REF(prefs_validate_vice_path), "set_pref_vice_4", TRUE)
	register_prefs_setter(PREF_KEY_VICE_5, GLOBAL_PROC_REF(prefs_validate_vice_path), "set_pref_vice_5", TRUE)
	register_prefs_setter(PREF_KEY_EXTRA_LANGUAGE_1, GLOBAL_PROC_REF(prefs_validate_known_language), "set_pref_extra_language_1")
	register_prefs_setter(PREF_KEY_EXTRA_LANGUAGE_2, GLOBAL_PROC_REF(prefs_validate_known_language), "set_pref_extra_language_2")

// ---------------------------------------------------------------------------
// Validators
// ---------------------------------------------------------------------------
// All path validators accept an empty string (clears the slot). A non-empty
// value must resolve via text2path() AND lie in the matching global registry
// so the player can't write arbitrary datum types.

/proc/prefs_validate_statpack_path(value)
	if(!istext(value))
		return FALSE
	if(!length(value))
		return TRUE
	var/path = text2path(value)
	if(!path || !ispath(path, /datum/statpack))
		return FALSE
	return (GLOB.statpacks && GLOB.statpacks[path]) ? TRUE : FALSE

/proc/prefs_validate_virtue_path(value)
	if(!istext(value))
		return FALSE
	if(!length(value))
		return TRUE
	var/path = text2path(value)
	if(!path || !ispath(path, /datum/virtue))
		return FALSE
	return (GLOB.virtues && GLOB.virtues[path]) ? TRUE : FALSE

/proc/prefs_validate_vice_path(value)
	if(!istext(value))
		return FALSE
	if(!length(value))
		return TRUE
	var/path = text2path(value)
	if(!path || !ispath(path, /datum/charflaw))
		return FALSE
	return (GLOB.charflaw_singletons && GLOB.charflaw_singletons[path]) ? TRUE : FALSE

/proc/prefs_validate_known_language(value)
	if(!istext(value))
		return FALSE
	if(!length(value) || value == "None")
		return TRUE
	if(!GLOB.all_languages)
		return FALSE
	return (value in GLOB.all_languages) ? TRUE : FALSE

/proc/prefs_validate_jobless_role(value)
	return (value == RETURNTOLOBBY || value == BERANDOMJOB) ? TRUE : FALSE

// ---------------------------------------------------------------------------
// Setter procs
// ---------------------------------------------------------------------------

/// Shared helper: resolve a typepath string to the singleton stored in
/// the matching GLOB registry. Empty string or unknown path returns null
/// (caller decides fallback).
/datum/preferences/proc/_pref_resolve_singleton(value, list/registry, base_type)
	if(!istext(value) || !length(value))
		return null
	var/path = text2path(value)
	if(!path || !ispath(path, base_type))
		return null
	if(!registry)
		return null
	return registry[path]

/datum/preferences/proc/set_pref_statpack(value)
	// Statpack must never be null — the whole stat pipeline assumes an
	// instance. Fall back to the canonical default if the wire value
	// clears the slot or resolves to an unknown type.
	var/datum/statpack/fresh = _pref_resolve_singleton(value, GLOB.statpacks, /datum/statpack)
	if(!fresh)
		fresh = GLOB.statpacks[/datum/statpack/wildcard/fated]
	statpack = fresh

/datum/preferences/proc/set_pref_virtue(value)
	var/datum/virtue/fresh = _pref_resolve_singleton(value, GLOB.virtues, /datum/virtue)
	if(!fresh)
		fresh = GLOB.virtues[/datum/virtue/none]
	virtue = fresh

/datum/preferences/proc/set_pref_virtue_two(value)
	var/datum/virtue/fresh = _pref_resolve_singleton(value, GLOB.virtues, /datum/virtue)
	if(!fresh)
		fresh = GLOB.virtues[/datum/virtue/none]
	virtuetwo = fresh

/datum/preferences/proc/_pref_set_vice_slot(slot_idx, value)
	var/datum/charflaw/fresh = _pref_resolve_singleton(value, GLOB.charflaw_singletons, /datum/charflaw)
	switch(slot_idx)
		if(1) vice1 = fresh
		if(2) vice2 = fresh
		if(3) vice3 = fresh
		if(4) vice4 = fresh
		if(5) vice5 = fresh

/datum/preferences/proc/set_pref_vice_1(value)
	_pref_set_vice_slot(1, value)

/datum/preferences/proc/set_pref_vice_2(value)
	_pref_set_vice_slot(2, value)

/datum/preferences/proc/set_pref_vice_3(value)
	_pref_set_vice_slot(3, value)

/datum/preferences/proc/set_pref_vice_4(value)
	_pref_set_vice_slot(4, value)

/datum/preferences/proc/set_pref_vice_5(value)
	_pref_set_vice_slot(5, value)

/datum/preferences/proc/set_pref_extra_language_1(value)
	if(!istext(value) || !length(value))
		extra_language_1 = "None"
		return
	extra_language_1 = value

/datum/preferences/proc/set_pref_extra_language_2(value)
	if(!istext(value) || !length(value))
		extra_language_2 = "None"
		return
	extra_language_2 = value

/datum/preferences/proc/set_pref_jobless_role(value)
	if(value != RETURNTOLOBBY && value != BERANDOMJOB)
		joblessrole = RETURNTOLOBBY
		return
	joblessrole = value

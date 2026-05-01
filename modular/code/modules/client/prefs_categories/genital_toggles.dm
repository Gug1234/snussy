/*
 * genital_toggles.dm — TGUI Preferences Menu, Body → Genitals inline
 * toggles (plan addendum Turn 2 — B7).
 *
 * Problem:
 *   Penis/testicles/breasts/vagina presence and sub-options (size,
 *   functional, sheathed, virility, lactating, fertility) are NOT flat
 *   /datum/preferences vars — they live on nested
 *   /datum/customizer_entry/organ/<x> datums inside `customizer_entries`.
 *   The central set_pref allow-list only addresses flat top-level keys.
 *
 * Approach:
 *   Shadow pref keys that read/write the nested entry fields directly.
 *   The `_enabled` setter flips `entry.disabled` (inverted semantics:
 *   a disabled customizer_entry means the organ is NOT present). When
 *   the entry is missing entirely (e.g. a slot that hasn't been
 *   visited via the classic HTML picker yet), the setter calls
 *   validate_customizer_entries() to let the species customizer list
 *   seed a default entry before toggling.
 *
 * Security:
 *   All setters validate through the central GLOB.prefs_setter_table
 *   pipeline. Presence setters are bools; size setters are intrange.
 *   No path coming in from the client — the customizer entry type is
 *   fully determined server-side by the setter.
 *
 * Performance:
 *   Each setter does one O(N) walk of customizer_entries where N is
 *   typically < 10. Allocation only on first-time enable of a slot
 *   that lacks a seeded entry.
 */

// --- Pref keys ----------------------------------------------------------
// Presence toggles.
#define PREF_KEY_GENITAL_PENIS_ENABLED       "genital_penis_enabled"
#define PREF_KEY_GENITAL_TESTICLES_ENABLED   "genital_testicles_enabled"
#define PREF_KEY_GENITAL_BREASTS_ENABLED     "genital_breasts_enabled"
#define PREF_KEY_GENITAL_VAGINA_ENABLED      "genital_vagina_enabled"
// Sub-options.
#define PREF_KEY_GENITAL_PENIS_SIZE          "genital_penis_size"
#define PREF_KEY_GENITAL_PENIS_FUNCTIONAL    "genital_penis_functional"
#define PREF_KEY_GENITAL_PENIS_SHEATHED      "genital_penis_sheathed"
#define PREF_KEY_GENITAL_TESTICLES_SIZE      "genital_testicles_size"
#define PREF_KEY_GENITAL_TESTICLES_VIRILITY  "genital_testicles_virility"
#define PREF_KEY_GENITAL_BREASTS_SIZE        "genital_breasts_size"
#define PREF_KEY_GENITAL_BREASTS_LACTATING   "genital_breasts_lactating"
#define PREF_KEY_GENITAL_VAGINA_FERTILITY    "genital_vagina_fertility"

// --- Registration -------------------------------------------------------
/*
 * Hook called by register_prefs_setters() in prefs_set_pref_dispatch.dm.
 * Duplicate keys would fail via stack_trace during init, which is the
 * desired loud-failure mode for schema drift.
 */
/proc/register_prefs_genital_toggle_setters()
	register_prefs_setter(PREF_KEY_GENITAL_PENIS_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_penis_enabled", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_TESTICLES_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_testicles_enabled", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_BREASTS_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_breasts_enabled", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_VAGINA_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_vagina_enabled", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_PENIS_SIZE, prefs_validate_intrange(MIN_PENIS_SIZE, MAX_PENIS_SIZE), "set_pref_genital_penis_size", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_PENIS_FUNCTIONAL, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_penis_functional", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_PENIS_SHEATHED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_penis_sheathed", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_TESTICLES_SIZE, prefs_validate_intrange(MIN_TESTICLES_SIZE, MAX_TESTICLES_SIZE), "set_pref_genital_testicles_size", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_TESTICLES_VIRILITY, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_testicles_virility", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_BREASTS_SIZE, prefs_validate_intrange(MIN_BREASTS_SIZE, MAX_BREASTS_SIZE), "set_pref_genital_breasts_size", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_BREASTS_LACTATING, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_breasts_lactating", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_GENITAL_VAGINA_FERTILITY, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_genital_vagina_fertility", FALSE, TRUE)

// --- Helpers ------------------------------------------------------------

/*
 * Resolve (or seed) the customizer_entry for the given entry type.
 * Seeding goes through the canonical validate_customizer_entries()
 * path so the entry inherits whatever customizer_choice subtype the
 * current species declares. Returns null when the species does not
 * register a matching customizer at all (e.g. a species with no
 * breasts option). Callers should no-op on null.
 */
/datum/preferences/proc/_pref_get_or_seed_genital_entry(entry_type)
	var/datum/customizer_entry/entry = get_customizer_entry_of_type(entry_type)
	if(entry)
		return entry
	if(!pref_species)
		return null
	// validate_customizer_entries() walks pref_species.customizers and
	// calls make_default_customizer_entry() for any customizer_type
	// that lacks a matching entry. Safe to call: it only adds, never
	// removes valid entries.
	validate_customizer_entries()
	return get_customizer_entry_of_type(entry_type)

/*
 * Cast a raw bool-ish payload to 1/0. The validator already clamped
 * the type; this is just the wire → boolean idiom.
 */
/datum/preferences/proc/_pref_coerce_bool(value)
	return !!(isnum(value) ? value : text2num("[value]"))

// --- Setters: presence toggles ------------------------------------------

/datum/preferences/proc/set_pref_genital_penis_enabled(value)
	var/datum/customizer_entry/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/penis)
	if(!entry)
		return
	entry.disabled = !_pref_coerce_bool(value)

/datum/preferences/proc/set_pref_genital_testicles_enabled(value)
	var/datum/customizer_entry/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/testicles)
	if(!entry)
		return
	entry.disabled = !_pref_coerce_bool(value)

/datum/preferences/proc/set_pref_genital_breasts_enabled(value)
	var/datum/customizer_entry/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/breasts)
	if(!entry)
		return
	entry.disabled = !_pref_coerce_bool(value)

/datum/preferences/proc/set_pref_genital_vagina_enabled(value)
	var/datum/customizer_entry/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/vagina)
	if(!entry)
		return
	entry.disabled = !_pref_coerce_bool(value)

// --- Setters: penis sub-options -----------------------------------------

/datum/preferences/proc/set_pref_genital_penis_size(value)
	var/datum/customizer_entry/organ/penis/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/penis)
	if(!entry)
		return
	var/numeric = isnum(value) ? value : text2num("[value]")
	if(isnull(numeric))
		return
	entry.penis_size = sanitize_integer(numeric, MIN_PENIS_SIZE, MAX_PENIS_SIZE, DEFAULT_PENIS_SIZE)

/datum/preferences/proc/set_pref_genital_penis_functional(value)
	var/datum/customizer_entry/organ/penis/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/penis)
	if(!entry)
		return
	entry.functional = _pref_coerce_bool(value)

/datum/preferences/proc/set_pref_genital_penis_sheathed(value)
	var/datum/customizer_entry/organ/penis/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/penis)
	if(!entry)
		return
	entry.sheathed = _pref_coerce_bool(value)

// --- Setters: testicles sub-options -------------------------------------

/datum/preferences/proc/set_pref_genital_testicles_size(value)
	var/datum/customizer_entry/organ/testicles/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/testicles)
	if(!entry)
		return
	var/numeric = isnum(value) ? value : text2num("[value]")
	if(isnull(numeric))
		return
	entry.ball_size = sanitize_integer(numeric, MIN_TESTICLES_SIZE, MAX_TESTICLES_SIZE, DEFAULT_TESTICLES_SIZE)

/datum/preferences/proc/set_pref_genital_testicles_virility(value)
	var/datum/customizer_entry/organ/testicles/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/testicles)
	if(!entry)
		return
	entry.virility = _pref_coerce_bool(value)

// --- Setters: breasts sub-options ---------------------------------------

/datum/preferences/proc/set_pref_genital_breasts_size(value)
	var/datum/customizer_entry/organ/breasts/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/breasts)
	if(!entry)
		return
	var/numeric = isnum(value) ? value : text2num("[value]")
	if(isnull(numeric))
		return
	entry.breast_size = sanitize_integer(numeric, MIN_BREASTS_SIZE, MAX_BREASTS_SIZE, DEFAULT_BREASTS_SIZE)

/datum/preferences/proc/set_pref_genital_breasts_lactating(value)
	var/datum/customizer_entry/organ/breasts/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/breasts)
	if(!entry)
		return
	entry.lactating = _pref_coerce_bool(value)

// --- Setters: vagina sub-options ----------------------------------------

/datum/preferences/proc/set_pref_genital_vagina_fertility(value)
	var/datum/customizer_entry/organ/vagina/entry = _pref_get_or_seed_genital_entry(/datum/customizer_entry/organ/vagina)
	if(!entry)
		return
	entry.fertility = _pref_coerce_bool(value)

// --- Snapshot readers ---------------------------------------------------
/*
 * Helpers invoked by get_pref_snapshot_field() in preferences_tgui.dm.
 * Each returns the current value (post-sanitization) so the TSX can
 * render without knowing the customizer_entry schema.
 */

/datum/preferences/proc/_pref_read_genital_enabled(entry_type)
	var/datum/customizer_entry/entry = get_customizer_entry_of_type(entry_type)
	// Missing entry → same surface as "not present". The TSX doesn't
	// need to distinguish absent-from-species vs disabled — it reads
	// the companion `genitals_*_available` ui_data flag for that.
	if(!entry)
		return 0
	return entry.disabled ? 0 : 1

/datum/preferences/proc/_pref_read_penis_field(field_name)
	var/datum/customizer_entry/organ/penis/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/penis)
	if(!entry)
		switch(field_name)
			if("size")
				return DEFAULT_PENIS_SIZE
			if("functional")
				return 1
			if("sheathed")
				return 1
		return null
	switch(field_name)
		if("size")
			return entry.penis_size
		if("functional")
			return entry.functional ? 1 : 0
		if("sheathed")
			return entry.sheathed ? 1 : 0
	return null

/datum/preferences/proc/_pref_read_testicles_field(field_name)
	var/datum/customizer_entry/organ/testicles/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/testicles)
	if(!entry)
		switch(field_name)
			if("size")
				return DEFAULT_TESTICLES_SIZE
			if("virility")
				return 1
		return null
	switch(field_name)
		if("size")
			return entry.ball_size
		if("virility")
			return entry.virility ? 1 : 0
	return null

/datum/preferences/proc/_pref_read_breasts_field(field_name)
	var/datum/customizer_entry/organ/breasts/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/breasts)
	if(!entry)
		switch(field_name)
			if("size")
				return DEFAULT_BREASTS_SIZE
			if("lactating")
				return 0
		return null
	switch(field_name)
		if("size")
			return entry.breast_size
		if("lactating")
			return entry.lactating ? 1 : 0
	return null

/datum/preferences/proc/_pref_read_vagina_field(field_name)
	var/datum/customizer_entry/organ/vagina/entry = get_customizer_entry_of_type(/datum/customizer_entry/organ/vagina)
	if(!entry)
		return 1 // fertility default
	switch(field_name)
		if("fertility")
			return entry.fertility ? 1 : 0
	return null

/*
 * Species-side availability probe. Returns TRUE when the current
 * pref_species declares any customizer whose type is a subtype of the
 * given abstract. The TSX shows/hides each organ row against this —
 * e.g. a species with no breasts customizer never sees the breast row.
 */
/datum/preferences/proc/_pref_has_genital_customizer(abstract_type)
	if(!pref_species)
		return FALSE
	for(var/ctype as anything in pref_species.customizers)
		if(ispath(ctype, abstract_type))
			return TRUE
	return FALSE

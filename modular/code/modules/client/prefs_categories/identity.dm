/*
 * identity.dm — TGUI Preferences Menu, Identity category (Step 10).
 *
 * Registers Identity-row pref setters into GLOB.prefs_setter_table and
 * implements the matching `set_pref_*` procs on /datum/preferences.
 * Each setter is a leaf mutator: validation has already happened by the
 * time it runs (Step 4 dispatcher invokes the registered validator
 * before call()), so these procs do only the minimum coercion needed
 * to hand a clean value to the savefile var.
 *
 * Scope: representative Identity prefs that exercise every validator
 * shape. Steps 11-14 follow the same pattern for their categories.
 * Complex editors (Faith, Descriptors, Images) remain on their existing
 * standalone HTML/TGUI surfaces and are reached from Identity bodies via
 * `act("launch_singleton", ...)` — that envelope lands in Step 14, so
 * Step 10 bodies present a placeholder button until then.
 *
 * Performance: registration is one-shot and idempotent; the dispatch
 * helpers are O(1) assoc-list lookups.
 */

#define PREF_KEY_REAL_NAME                 "real_name"
#define PREF_KEY_NICKNAME                  "nickname"
#define PREF_KEY_GENDER                    "gender"
#define PREF_KEY_PRONOUNS                  "pronouns"
#define PREF_KEY_VOICE_PACK                "voice_pack"
#define PREF_KEY_VOICE_TYPE                "voice_type"
#define PREF_KEY_VOICE_COLOR               "voice_color"
#define PREF_KEY_VOICE_PITCH_X100          "voice_pitch_x100"
#define PREF_KEY_CHAR_ACCENT               "char_accent"
#define PREF_KEY_BARK_ID                   "bark_id"
#define PREF_KEY_BARK_SPEED                "bark_speed"
#define PREF_KEY_HEAR_BARKS                "hear_barks"
#define PREF_KEY_PATREON_SAY_COLOR         "patreon_say_color"
#define PREF_KEY_PATREON_SAY_COLOR_ENABLED "patreon_say_color_enabled"
#define PREF_KEY_ORIGIN                    "origin"
#define PREF_KEY_FAMILY                    "family"
#define PREF_KEY_SETSPOUSE                 "setspouse"
#define PREF_KEY_GENDER_CHOICE             "gender_choice"
#define PREF_KEY_SONG_ARTIST               "song_artist"
#define PREF_KEY_SONG_TITLE                "song_title"
#define PREF_KEY_FLAVORTEXT                "flavortext"
#define PREF_KEY_OOC_NOTES                 "ooc_notes"
#define PREF_KEY_NSFW_FLAVORTEXT           "nsfw_flavortext"
#define PREF_KEY_ERP_OOC_NOTES             "erp_ooc_notes"

/*
 * Identity-scope text-field length caps. Mirror the existing HTML prefs
 * surface limits so a TGUI-side write can never overflow what the legacy
 * path also accepts. Centralised here so a future tightening pass only
 * touches one site.
 */
#define IDENTITY_MAX_NAME_LEN     64
#define IDENTITY_MAX_NICKNAME_LEN 32
#define IDENTITY_MAX_TITLE_LEN    64
#define IDENTITY_MAX_FLAVOR_LEN   2048
#define IDENTITY_MAX_OOC_LEN      1024
// NSFW siblings of flavortext / OOC notes use the legacy bigmodal
// surface, which historically accepted very long blocks. Cap at 4 KB
// to bound a single set_pref payload while leaving plenty of room.
#define IDENTITY_MAX_NSFW_FLAVOR_LEN 4096
#define IDENTITY_MAX_ERP_OOC_LEN     4096
#define IDENTITY_MAX_SONG_LEN     128
#define IDENTITY_MAX_ACCENT_LEN   64

/*
 * Hook called by ensure_prefs_dispatch_tables() in Step 3. The Step 3
 * file's register_prefs_setters() seeded the trivial bootstrap rows;
 * this proc appends every Identity row. It is safe to call exactly once
 * because register_prefs_setter() rejects duplicate keys with a
 * stack_trace() — a duplicate registration would surface immediately
 * during compile-test.
 */
/proc/register_prefs_identity_setters()
	register_prefs_setter(PREF_KEY_REAL_NAME, prefs_validate_string(IDENTITY_MAX_NAME_LEN), "set_pref_real_name")
	register_prefs_setter(PREF_KEY_NICKNAME, prefs_validate_string(IDENTITY_MAX_NICKNAME_LEN), "set_pref_nickname")
	register_prefs_setter(PREF_KEY_GENDER, prefs_validate_enum(list(MALE, FEMALE, NEUTER, PLURAL)), "set_pref_gender", FALSE, TRUE)
	register_prefs_setter(PREF_KEY_PRONOUNS, prefs_validate_string(32), "set_pref_pronouns")
	register_prefs_setter(PREF_KEY_VOICE_PACK, prefs_validate_string(64), "set_pref_voice_pack")
	register_prefs_setter(PREF_KEY_VOICE_TYPE, prefs_validate_string(32), "set_pref_voice_type")
	register_prefs_setter(PREF_KEY_VOICE_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_voice_color")
	// Voice pitch is stored as a float on the datum (default 1.0); the
	// client sends an integer scaled ×100 so we can use the cheap
	// intrange validator without floating-point edge cases.
	register_prefs_setter(PREF_KEY_VOICE_PITCH_X100, prefs_validate_intrange(50, 150), "set_pref_voice_pitch_x100")
	register_prefs_setter(PREF_KEY_CHAR_ACCENT, prefs_validate_string(IDENTITY_MAX_ACCENT_LEN), "set_pref_char_accent")
	register_prefs_setter(PREF_KEY_BARK_ID, prefs_validate_string(64), "set_pref_bark_id")
	register_prefs_setter(PREF_KEY_BARK_SPEED, prefs_validate_intrange(1, 10), "set_pref_bark_speed")
	register_prefs_setter(PREF_KEY_HEAR_BARKS, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_hear_barks")
	register_prefs_setter(PREF_KEY_PATREON_SAY_COLOR, GLOBAL_PROC_REF(prefs_validate_hex), "set_pref_patreon_say_color")
	register_prefs_setter(PREF_KEY_PATREON_SAY_COLOR_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_patreon_say_color_enabled")
	// Origin is a typepath. The validator confirms the supplied string
	// resolves to an entry in GLOB.origins. The setter resolves the
	// typepath to the canonical /datum/origin instance.
	register_prefs_setter(PREF_KEY_ORIGIN, GLOBAL_PROC_REF(prefs_validate_origin_typepath), "set_pref_origin")
	register_prefs_setter(PREF_KEY_FAMILY, prefs_validate_string(64), "set_pref_family")
	register_prefs_setter(PREF_KEY_SETSPOUSE, prefs_validate_string(IDENTITY_MAX_NAME_LEN), "set_pref_setspouse")
	register_prefs_setter(PREF_KEY_GENDER_CHOICE, prefs_validate_string(64), "set_pref_gender_choice")
	register_prefs_setter(PREF_KEY_SONG_ARTIST, prefs_validate_string(IDENTITY_MAX_SONG_LEN), "set_pref_song_artist")
	register_prefs_setter(PREF_KEY_SONG_TITLE, prefs_validate_string(IDENTITY_MAX_SONG_LEN), "set_pref_song_title")
	register_prefs_setter(PREF_KEY_FLAVORTEXT, prefs_validate_string(IDENTITY_MAX_FLAVOR_LEN), "set_pref_flavortext")
	register_prefs_setter(PREF_KEY_OOC_NOTES, prefs_validate_string(IDENTITY_MAX_OOC_LEN), "set_pref_ooc_notes")
	register_prefs_setter(PREF_KEY_NSFW_FLAVORTEXT, prefs_validate_string(IDENTITY_MAX_NSFW_FLAVOR_LEN), "set_pref_nsfw_flavortext")
	register_prefs_setter(PREF_KEY_ERP_OOC_NOTES, prefs_validate_string(IDENTITY_MAX_ERP_OOC_LEN), "set_pref_erp_ooc_notes")

/*
 * Origin validator. Accepts a typepath string (e.g. "/datum/origin/otava")
 * and returns TRUE iff GLOB.origins contains it. Bare global proc so it
 * registers without a callback factory allocation per setter.
 */
/proc/prefs_validate_origin_typepath(value)
	if(!istext(value) || !length(value))
		return FALSE
	var/path = text2path(value)
	if(!path)
		return FALSE
	return GLOB.origins && GLOB.origins[path] ? TRUE : FALSE

// ---------------------------------------------------------------------------
// Setter procs.
//
// Each accepts a pre-validated value and writes the matching savefile var.
// No defensive re-validation: load_character runs sanitize_*() on next
// load so any drift from a future schema change surfaces there instead of
// being silently absorbed here.
// ---------------------------------------------------------------------------

/datum/preferences/proc/_pref_apply_text(field_name, value, max_len)
	if(!istext(value))
		return
	if(length(value) > max_len)
		value = copytext(value, 1, max_len + 1)
	vars[field_name] = value

/datum/preferences/proc/set_pref_real_name(value)
	_pref_apply_text("real_name", value, IDENTITY_MAX_NAME_LEN)

/datum/preferences/proc/set_pref_nickname(value)
	_pref_apply_text("nickname", value, IDENTITY_MAX_NICKNAME_LEN)

/datum/preferences/proc/set_pref_gender(value)
	gender = value

/datum/preferences/proc/set_pref_pronouns(value)
	pronouns = value

/datum/preferences/proc/set_pref_voice_pack(value)
	voice_pack = value

/datum/preferences/proc/set_pref_voice_type(value)
	voice_type = value

/datum/preferences/proc/set_pref_voice_color(value)
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	voice_color = value

/datum/preferences/proc/set_pref_voice_pitch_x100(value)
	// Stored as a float (default 1.0). Convert from the wire ×100 form.
	voice_pitch = (isnum(value) ? value : text2num("[value]")) / 100
	if(voice_pitch < 0.5)
		voice_pitch = 0.5
	if(voice_pitch > 1.5)
		voice_pitch = 1.5

/datum/preferences/proc/set_pref_char_accent(value)
	_pref_apply_text("char_accent", value, IDENTITY_MAX_ACCENT_LEN)

/datum/preferences/proc/set_pref_bark_id(value)
	_pref_apply_text("bark_id", value, 64)

/datum/preferences/proc/set_pref_bark_speed(value)
	bark_speed = isnum(value) ? value : text2num("[value]")

/datum/preferences/proc/set_pref_hear_barks(value)
	hear_barks = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_patreon_say_color(value)
	if(istext(value) && length(value) == 6)
		value = "#[value]"
	patreon_say_color = value

/datum/preferences/proc/set_pref_patreon_say_color_enabled(value)
	patreon_say_color_enabled = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_origin(value)
	var/path = text2path(value)
	if(!path)
		return
	origin = GLOB.origins[path]

/datum/preferences/proc/set_pref_family(value)
	_pref_apply_text("family", value, 64)

/datum/preferences/proc/set_pref_setspouse(value)
	_pref_apply_text("setspouse", value, IDENTITY_MAX_NAME_LEN)

/datum/preferences/proc/set_pref_gender_choice(value)
	_pref_apply_text("gender_choice", value, 64)

/datum/preferences/proc/set_pref_song_artist(value)
	_pref_apply_text("song_artist", value, IDENTITY_MAX_SONG_LEN)

/datum/preferences/proc/set_pref_song_title(value)
	_pref_apply_text("song_title", value, IDENTITY_MAX_SONG_LEN)

/datum/preferences/proc/set_pref_flavortext(value)
	_pref_apply_text("flavortext", value, IDENTITY_MAX_FLAVOR_LEN)

/datum/preferences/proc/set_pref_ooc_notes(value)
	_pref_apply_text("ooc_notes", value, IDENTITY_MAX_OOC_LEN)

// NSFW flavortext — separate /datum/preferences var (`nsfwflavortext`)
// from the SFW flavortext above. Surfaces the same as the legacy
// `bigmodal` HTML field but routed through the dirty-ledger.
/datum/preferences/proc/set_pref_nsfw_flavortext(value)
	_pref_apply_text("nsfwflavortext", value, IDENTITY_MAX_NSFW_FLAVOR_LEN)

// ERP OOC notes are stored on /datum/preferences as `erpprefs` for
// historical reasons. The TGUI key is namespaced (`erp_ooc_notes`) to
// keep the wire surface readable; the savefile var name is unchanged.
/datum/preferences/proc/set_pref_erp_ooc_notes(value)
	_pref_apply_text("erpprefs", value, IDENTITY_MAX_ERP_OOC_LEN)

// ---------------------------------------------------------------------------
// Identity → Misc / Food / Gnoll / Familiar / Jelly extensions.
// Added to keep all identity-scope prefs inside the unified TGUI menu
// rather than linking out to legacy browser popups.
// ---------------------------------------------------------------------------

#define PREF_KEY_AGE                       "age"
#define PREF_KEY_DNR                       "dnr_pref"
#define PREF_KEY_DOMHAND                   "domhand"
#define PREF_KEY_CULINARY_FAV_FOOD         "culinary_fav_food"
#define PREF_KEY_CULINARY_FAV_DRINK        "culinary_fav_drink"
#define PREF_KEY_CULINARY_HATED_FOOD       "culinary_hated_food"
#define PREF_KEY_CULINARY_HATED_DRINK      "culinary_hated_drink"

#define PREF_KEY_GNOLL_NAME                "gnoll_name"
#define PREF_KEY_GNOLL_PRONOUNS            "gnoll_pronouns"
#define PREF_KEY_GNOLL_PELT                "gnoll_pelt"
#define PREF_KEY_GNOLL_PENIS               "gnoll_penis"
#define PREF_KEY_GNOLL_VAGINA              "gnoll_vagina"
#define PREF_KEY_GNOLL_BREASTS             "gnoll_breasts"
#define PREF_KEY_GNOLL_HEIGHT              "gnoll_height"
#define PREF_KEY_GNOLL_BODY                "gnoll_body"
#define PREF_KEY_GNOLL_FUR                 "gnoll_fur"
#define PREF_KEY_GNOLL_VOICE               "gnoll_voice"
#define PREF_KEY_GNOLL_MUZZLE              "gnoll_muzzle"
#define PREF_KEY_GNOLL_EXPRESSION          "gnoll_expression"

#define PREF_KEY_FAMILIAR_NAME             "familiar_name"
#define PREF_KEY_FAMILIAR_PRONOUNS         "familiar_pronouns"
#define PREF_KEY_FAMILIAR_SPECIE           "familiar_specie"
#define PREF_KEY_FAMILIAR_FLAVORTEXT       "familiar_flavortext"
#define PREF_KEY_FAMILIAR_OOC_NOTES        "familiar_ooc_notes"
#define PREF_KEY_FAMILIAR_HEADSHOT         "familiar_headshot_link"

#define PREF_KEY_JELLY_ENABLED             "jelly_controller_enabled"
#define PREF_KEY_JELLY_NAME                "jelly_name"
#define PREF_KEY_JELLY_PRONOUNS            "jelly_pronouns"
#define PREF_KEY_JELLY_FLAVORTEXT          "jelly_flavortext"
#define PREF_KEY_JELLY_OOC_NOTES           "jelly_ooc_notes"

// Pronouns validator reused by Gnoll/Familiar/Jelly bodies.
/proc/prefs_validate_pronouns(value)
	if(!istext(value))
		return FALSE
	return (value in GLOB.pronouns_list) ? TRUE : FALSE

// Typepath validator for culinary prefs. Accepts either the empty string
// (unset) or a typepath string resolvable to /obj/item/reagent_containers.
// The setter refines the branch (food vs drink).
/proc/prefs_validate_culinary_typepath(value)
	if(value == "" || value == null)
		return TRUE
	if(!istext(value))
		return FALSE
	var/path = text2path(value)
	if(!path)
		return FALSE
	return (ispath(path, /obj/item/reagent_containers/food/snacks) \
		|| ispath(path, /datum/reagent/consumable))

/proc/register_prefs_identity_extras_setters()
	register_prefs_setter(PREF_KEY_AGE, prefs_validate_enum(ALL_AGES_LIST), "set_pref_age")
	register_prefs_setter(PREF_KEY_DNR, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_dnr")
	register_prefs_setter(PREF_KEY_DOMHAND, prefs_validate_intrange(1, 2), "set_pref_domhand")
	register_prefs_setter(PREF_KEY_CULINARY_FAV_FOOD, GLOBAL_PROC_REF(prefs_validate_culinary_typepath), "set_pref_culinary_fav_food")
	register_prefs_setter(PREF_KEY_CULINARY_FAV_DRINK, GLOBAL_PROC_REF(prefs_validate_culinary_typepath), "set_pref_culinary_fav_drink")
	register_prefs_setter(PREF_KEY_CULINARY_HATED_FOOD, GLOBAL_PROC_REF(prefs_validate_culinary_typepath), "set_pref_culinary_hated_food")
	register_prefs_setter(PREF_KEY_CULINARY_HATED_DRINK, GLOBAL_PROC_REF(prefs_validate_culinary_typepath), "set_pref_culinary_hated_drink")

	// Gnoll scalar fields. Descriptor/pelt keys use string validators
	// since the setters resolve the labels against their option tables.
	register_prefs_setter(PREF_KEY_GNOLL_NAME, prefs_validate_string(MAX_NAME_LEN), "set_pref_gnoll_name")
	register_prefs_setter(PREF_KEY_GNOLL_PRONOUNS, GLOBAL_PROC_REF(prefs_validate_pronouns), "set_pref_gnoll_pronouns")
	register_prefs_setter(PREF_KEY_GNOLL_PELT, prefs_validate_string(32), "set_pref_gnoll_pelt")
	register_prefs_setter(PREF_KEY_GNOLL_PENIS, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_gnoll_penis")
	register_prefs_setter(PREF_KEY_GNOLL_VAGINA, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_gnoll_vagina")
	register_prefs_setter(PREF_KEY_GNOLL_BREASTS, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_gnoll_breasts")
	register_prefs_setter(PREF_KEY_GNOLL_HEIGHT, prefs_validate_string(64), "set_pref_gnoll_height")
	register_prefs_setter(PREF_KEY_GNOLL_BODY, prefs_validate_string(64), "set_pref_gnoll_body")
	register_prefs_setter(PREF_KEY_GNOLL_FUR, prefs_validate_string(64), "set_pref_gnoll_fur")
	register_prefs_setter(PREF_KEY_GNOLL_VOICE, prefs_validate_string(64), "set_pref_gnoll_voice")
	register_prefs_setter(PREF_KEY_GNOLL_MUZZLE, prefs_validate_string(64), "set_pref_gnoll_muzzle")
	register_prefs_setter(PREF_KEY_GNOLL_EXPRESSION, prefs_validate_string(64), "set_pref_gnoll_expression")

	register_prefs_setter(PREF_KEY_FAMILIAR_NAME, prefs_validate_string(MAX_NAME_LEN), "set_pref_familiar_name")
	register_prefs_setter(PREF_KEY_FAMILIAR_PRONOUNS, GLOBAL_PROC_REF(prefs_validate_pronouns), "set_pref_familiar_pronouns")
	register_prefs_setter(PREF_KEY_FAMILIAR_SPECIE, prefs_validate_string(64), "set_pref_familiar_specie")
	register_prefs_setter(PREF_KEY_FAMILIAR_FLAVORTEXT, prefs_validate_string(IDENTITY_MAX_FLAVOR_LEN), "set_pref_familiar_flavortext")
	register_prefs_setter(PREF_KEY_FAMILIAR_OOC_NOTES, prefs_validate_string(IDENTITY_MAX_OOC_LEN), "set_pref_familiar_ooc_notes")
	register_prefs_setter(PREF_KEY_FAMILIAR_HEADSHOT, prefs_validate_string(512), "set_pref_familiar_headshot")

	register_prefs_setter(PREF_KEY_JELLY_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_jelly_enabled")
	register_prefs_setter(PREF_KEY_JELLY_NAME, prefs_validate_string(MAX_NAME_LEN), "set_pref_jelly_name")
	register_prefs_setter(PREF_KEY_JELLY_PRONOUNS, GLOBAL_PROC_REF(prefs_validate_pronouns), "set_pref_jelly_pronouns")
	register_prefs_setter(PREF_KEY_JELLY_FLAVORTEXT, prefs_validate_string(IDENTITY_MAX_FLAVOR_LEN), "set_pref_jelly_flavortext")
	register_prefs_setter(PREF_KEY_JELLY_OOC_NOTES, prefs_validate_string(IDENTITY_MAX_OOC_LEN), "set_pref_jelly_ooc_notes")

// --- Setters ---------------------------------------------------------------

/datum/preferences/proc/set_pref_age(value)
	age = value

/datum/preferences/proc/set_pref_dnr(value)
	dnr_pref = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_domhand(value)
	var/n = isnum(value) ? value : text2num("[value]")
	domhand = (n == 1) ? 1 : 2

/datum/preferences/proc/_pref_resolve_culinary_path(value, expect_food)
	if(value == "" || value == null)
		return null
	var/path = text2path("[value]")
	if(!path)
		return null
	if(expect_food && !ispath(path, /obj/item/reagent_containers/food/snacks))
		return null
	if(!expect_food && !ispath(path, /datum/reagent/consumable))
		return null
	return path

/datum/preferences/proc/_pref_apply_culinary(slot, value, expect_food)
	if(!culinary_preferences)
		culinary_preferences = list()
	culinary_preferences[slot] = _pref_resolve_culinary_path(value, expect_food)
	validate_culinary_preferences()

/datum/preferences/proc/set_pref_culinary_fav_food(value)
	_pref_apply_culinary(CULINARY_FAVOURITE_FOOD, value, TRUE)

/datum/preferences/proc/set_pref_culinary_fav_drink(value)
	_pref_apply_culinary(CULINARY_FAVOURITE_DRINK, value, FALSE)

/datum/preferences/proc/set_pref_culinary_hated_food(value)
	_pref_apply_culinary(CULINARY_HATED_FOOD, value, TRUE)

/datum/preferences/proc/set_pref_culinary_hated_drink(value)
	_pref_apply_culinary(CULINARY_HATED_DRINK, value, FALSE)

// ----- Gnoll -----
// Descriptor setters resolve the string label against the gnoll_prefs
// option tables so a bad value falls through without corruption. Null
// guards keep first-open races from runtime'ing.

/datum/preferences/proc/_pref_gnoll_set_descriptor(slot, label)
	if(!gnoll_prefs)
		return
	var/list/options = gnoll_prefs.get_descriptor_options(slot)
	if(!options)
		return
	var/resolved = options[label]
	if(!resolved)
		return
	gnoll_prefs.set_descriptor_value(slot, resolved)

// Snapshot helper — surface the display label for the current descriptor
// value (or null if unset) so the client dropdown can round-trip without
// knowing DM typepaths.
/datum/preferences/proc/_pref_gnoll_descriptor_label(slot)
	if(!gnoll_prefs)
		return null
	var/list/options = gnoll_prefs.get_descriptor_options(slot)
	if(!options)
		return null
	var/value = gnoll_prefs.get_descriptor_value(slot)
	if(!value)
		return null
	return gnoll_prefs.get_selected_label(options, value)

/datum/preferences/proc/set_pref_gnoll_name(value)
	if(!gnoll_prefs || !istext(value))
		return
	gnoll_prefs.gnoll_name = copytext(value, 1, MAX_NAME_LEN + 1)

/datum/preferences/proc/set_pref_gnoll_pronouns(value)
	if(gnoll_prefs)
		gnoll_prefs.gnoll_pronouns = value

/datum/preferences/proc/set_pref_gnoll_pelt(value)
	if(!gnoll_prefs)
		return
	var/list/options = gnoll_prefs.get_pelt_options()
	if(!options)
		return
	// Accept either the display label (preferred) or the raw stored value.
	if(options[value])
		gnoll_prefs.pelt_type = options[value]
		return
	for(var/label in options)
		if(options[label] == value)
			gnoll_prefs.pelt_type = options[label]
			return

/datum/preferences/proc/_pref_gnoll_set_genital(slot, value)
	if(!gnoll_prefs)
		return
	if(!gnoll_prefs.genitals)
		gnoll_prefs.genitals = list()
	gnoll_prefs.genitals[slot] = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_gnoll_penis(value)
	_pref_gnoll_set_genital("penis", value)

/datum/preferences/proc/set_pref_gnoll_vagina(value)
	_pref_gnoll_set_genital("vagina", value)

/datum/preferences/proc/set_pref_gnoll_breasts(value)
	_pref_gnoll_set_genital("breasts", value)

/datum/preferences/proc/set_pref_gnoll_height(value)
	_pref_gnoll_set_descriptor("height", value)

/datum/preferences/proc/set_pref_gnoll_body(value)
	_pref_gnoll_set_descriptor("body", value)

/datum/preferences/proc/set_pref_gnoll_fur(value)
	_pref_gnoll_set_descriptor("fur", value)

/datum/preferences/proc/set_pref_gnoll_voice(value)
	_pref_gnoll_set_descriptor("voice", value)

/datum/preferences/proc/set_pref_gnoll_muzzle(value)
	_pref_gnoll_set_descriptor("muzzle", value)

/datum/preferences/proc/set_pref_gnoll_expression(value)
	_pref_gnoll_set_descriptor("expression", value)

// ----- Familiar -----

/datum/preferences/proc/set_pref_familiar_name(value)
	if(!familiar_prefs || !istext(value))
		return
	familiar_prefs.familiar_name = copytext(value, 1, MAX_NAME_LEN + 1)

/datum/preferences/proc/set_pref_familiar_pronouns(value)
	if(familiar_prefs)
		familiar_prefs.familiar_pronouns = value

/datum/preferences/proc/set_pref_familiar_specie(value)
	if(!familiar_prefs)
		return
	// Accept either the display-name key or a typepath string.
	var/all_types = GLOB.familiar_types
	if(all_types && all_types[value])
		familiar_prefs.familiar_specie = all_types[value]
		return
	var/path = text2path("[value]")
	if(path && ispath(path, /mob/living/simple_animal/pet/familiar))
		familiar_prefs.familiar_specie = path

/datum/preferences/proc/set_pref_familiar_flavortext(value)
	if(!familiar_prefs || !istext(value))
		return
	familiar_prefs.familiar_flavortext = copytext(value, 1, IDENTITY_MAX_FLAVOR_LEN + 1)

/datum/preferences/proc/set_pref_familiar_ooc_notes(value)
	if(!familiar_prefs || !istext(value))
		return
	familiar_prefs.familiar_ooc_notes = copytext(value, 1, IDENTITY_MAX_OOC_LEN + 1)

/datum/preferences/proc/set_pref_familiar_headshot(value)
	if(!familiar_prefs || !istext(value))
		return
	familiar_prefs.familiar_headshot_link = copytext(value, 1, 513)

// ----- Jelly -----

/datum/preferences/proc/set_pref_jelly_enabled(value)
	jelly_controller_enabled = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_jelly_name(value)
	if(!jelly_prefs || !istext(value))
		return
	jelly_prefs.jelly_name = copytext(value, 1, MAX_NAME_LEN + 1)

/datum/preferences/proc/set_pref_jelly_pronouns(value)
	if(jelly_prefs)
		jelly_prefs.jelly_pronouns = value

/datum/preferences/proc/set_pref_jelly_flavortext(value)
	if(!jelly_prefs || !istext(value))
		return
	jelly_prefs.jelly_flavortext = copytext(value, 1, IDENTITY_MAX_FLAVOR_LEN + 1)

/datum/preferences/proc/set_pref_jelly_ooc_notes(value)
	if(!jelly_prefs || !istext(value))
		return
	jelly_prefs.jelly_ooc_notes = copytext(value, 1, IDENTITY_MAX_OOC_LEN + 1)

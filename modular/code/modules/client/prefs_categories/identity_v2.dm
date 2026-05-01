/*
 * identity_v2.dm — TGUI Preferences Menu, Identity/Intimacy extension v2.
 *
 * Added for the deviations pass (TB1 + I3/I4/I5/I6/I7/I8/I9 + IN5/IN6 + O4).
 * Registers pref setters that back the re-shaped Identity/Intimacy bodies:
 * bark pitch/variance sliders, inline Faith/Patron dropdowns, Rumor and
 * noble gossip text, OOC image URLs, combat music dropdown + custom link,
 * headshot link + chatheadshot toggle, and the ERP content opt-in toggles.
 *
 * Separated from identity.dm so the original Step-10 registration block
 * stays a readable snapshot of the first pass; this file carries the
 * follow-up additive surface.
 */

// Additive /datum/preferences vars that back the new URL inputs.
/datum/preferences/var/flavor_ooc_image_url = ""
/datum/preferences/var/nsfw_flavor_ooc_image_url = ""

#define PREF_KEY_BARK_PITCH_X100           "bark_pitch_x100"
#define PREF_KEY_BARK_VARIANCE_X100        "bark_variance_x100"
#define PREF_KEY_FAITH                     "faith"
#define PREF_KEY_PATRON                    "patron"
#define PREF_KEY_RUMOR                     "rumor"
#define PREF_KEY_NOBLE_GOSSIP              "noble_gossip"
#define PREF_KEY_OOC_IMAGE_URL             "ooc_image_url"
#define PREF_KEY_NSFW_OOC_IMAGE_URL        "nsfw_ooc_image_url"
#define PREF_KEY_COMBAT_MUSIC              "combat_music_track"
#define PREF_KEY_HEADSHOT_LINK             "headshot_link"
#define PREF_KEY_CHATHEADSHOT_ENABLED      "chatheadshot_enabled"
#define PREF_KEY_CURSED_ENABLED            "cursed_enabled"
#define PREF_KEY_EXTREME_ERP               "extreme_erp"
#define PREF_KEY_EDGING                    "edging"
#define PREF_KEY_INTIMATE_ENABLED          "intimate_enabled"
#define PREF_KEY_INTIMATE_REACTION         "intimate_reaction_enabled"
#define PREF_KEY_SHOW_INTIMATE_EXAMINE     "show_intimate_examine"
#define PREF_KEY_CHASTITY_HARDMODE         "chastity_hardmode"
#define PREF_KEY_CHASTITY_ENABLED          "pref_chastity_enabled"
#define PREF_KEY_CHASTITY_FLAT             "pref_chastity_flat"
#define PREF_KEY_CHASTITY_ANAL             "pref_chastity_anal"
#define PREF_KEY_CHASTITY_SPIKED           "pref_chastity_spiked"
#define PREF_KEY_CHASTITY_LOCKED           "pref_chastity_locked"
#define PREF_KEY_CHASTITY_SPAWN_KEY        "pref_chastity_spawn_key"
#define PREF_KEY_CHASTITY_RANDOM_KEYS      "pref_chastity_random_keys"
#define PREF_KEY_CHASTITY_KEY_STASHES      "pref_chastity_key_stashes"

// Combat-music typepath validator — accepts a typepath that resolves
// to a subtype present in GLOB.cmode_tracks_by_type.
/proc/prefs_validate_combat_music_typepath(value)
	if(!istext(value) || !length(value))
		return FALSE
	var/path = text2path(value)
	if(!path)
		return FALSE
	return GLOB.cmode_tracks_by_type && GLOB.cmode_tracks_by_type[path] ? TRUE : FALSE

// Faith validator — a faith name resolvable against GLOB.preference_faiths.
/proc/prefs_validate_faith_named(value)
	if(!istext(value))
		return FALSE
	if(!GLOB.preference_faiths || !GLOB.faithlist)
		return FALSE
	for(var/path as anything in GLOB.preference_faiths)
		var/datum/faith/faith = GLOB.faithlist[path]
		if(faith && faith.name == value)
			return TRUE
	return FALSE

// Patron validator — typepath resolvable against GLOB.patronlist.
/proc/prefs_validate_patron_named(value)
	if(!istext(value))
		return FALSE
	var/path = text2path(value)
	if(path && GLOB.patronlist && GLOB.patronlist[path])
		return TRUE
	return FALSE

/proc/prefs_validate_chastity_key_stashes(value)
	if(isnull(value))
		return TRUE
	if(!islist(value))
		return FALSE
	if(length(value) > 5)
		return FALSE
	for(var/name in value)
		if(!istext(name))
			return FALSE
		var/sanitized = trim(sanitize_text(name))
		if(!length(sanitized) || length(sanitized) > MAX_NAME_LEN)
			return FALSE
	return TRUE

/proc/register_prefs_identity_v2_setters()
	register_prefs_setter(PREF_KEY_BARK_PITCH_X100, prefs_validate_intrange(10, 400), "set_pref_bark_pitch_x100")
	register_prefs_setter(PREF_KEY_BARK_VARIANCE_X100, prefs_validate_intrange(0, 200), "set_pref_bark_variance_x100")
	register_prefs_setter(PREF_KEY_FAITH, GLOBAL_PROC_REF(prefs_validate_faith_named), "set_pref_faith")
	register_prefs_setter(PREF_KEY_PATRON, GLOBAL_PROC_REF(prefs_validate_patron_named), "set_pref_patron")
	register_prefs_setter(PREF_KEY_RUMOR, prefs_validate_string(IDENTITY_MAX_FLAVOR_LEN), "set_pref_rumor")
	register_prefs_setter(PREF_KEY_NOBLE_GOSSIP, prefs_validate_string(400), "set_pref_noble_gossip")
	register_prefs_setter(PREF_KEY_OOC_IMAGE_URL, prefs_validate_string(512), "set_pref_ooc_image_url")
	register_prefs_setter(PREF_KEY_NSFW_OOC_IMAGE_URL, prefs_validate_string(512), "set_pref_nsfw_ooc_image_url")
	register_prefs_setter(PREF_KEY_COMBAT_MUSIC, GLOBAL_PROC_REF(prefs_validate_combat_music_typepath), "set_pref_combat_music")
	register_prefs_setter(PREF_KEY_HEADSHOT_LINK, prefs_validate_string(512), "set_pref_headshot_link")
	register_prefs_setter(PREF_KEY_CHATHEADSHOT_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chatheadshot_enabled")
	register_prefs_setter(PREF_KEY_CURSED_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_cursed_enabled")
	register_prefs_setter(PREF_KEY_EXTREME_ERP, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_extreme_erp")
	register_prefs_setter(PREF_KEY_EDGING, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_edging")
	register_prefs_setter(PREF_KEY_INTIMATE_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_intimate_enabled")
	register_prefs_setter(PREF_KEY_INTIMATE_REACTION, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_intimate_reaction")
	register_prefs_setter(PREF_KEY_SHOW_INTIMATE_EXAMINE, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_show_intimate_examine")
	register_prefs_setter(PREF_KEY_CHASTITY_HARDMODE, prefs_validate_intrange(0, 2), "set_pref_chastity_hardmode")
	register_prefs_setter(PREF_KEY_CHASTITY_ENABLED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_enabled")
	register_prefs_setter(PREF_KEY_CHASTITY_FLAT, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_flat")
	register_prefs_setter(PREF_KEY_CHASTITY_ANAL, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_anal")
	register_prefs_setter(PREF_KEY_CHASTITY_SPIKED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_spiked")
	register_prefs_setter(PREF_KEY_CHASTITY_LOCKED, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_locked")
	register_prefs_setter(PREF_KEY_CHASTITY_SPAWN_KEY, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_spawn_key")
	register_prefs_setter(PREF_KEY_CHASTITY_RANDOM_KEYS, GLOBAL_PROC_REF(prefs_validate_bool), "set_pref_chastity_random_keys")
	register_prefs_setter(PREF_KEY_CHASTITY_KEY_STASHES, GLOBAL_PROC_REF(prefs_validate_chastity_key_stashes), "set_pref_chastity_key_stashes")

// --- Setters ---------------------------------------------------------------

/datum/preferences/proc/set_pref_bark_pitch_x100(value)
	var/n = (isnum(value) ? value : text2num("[value]")) / 100
	bark_pitch = clamp(n, 0.1, 4.0)

/datum/preferences/proc/set_pref_bark_variance_x100(value)
	var/n = (isnum(value) ? value : text2num("[value]")) / 100
	bark_variance = clamp(n, 0.0, 2.0)

/datum/preferences/proc/set_pref_faith(value)
	var/datum/faith/resolved_faith
	var/resolved_path
	if(GLOB.preference_faiths && GLOB.faithlist)
		for(var/path as anything in GLOB.preference_faiths)
			var/datum/faith/candidate = GLOB.faithlist[path]
			if(candidate && candidate.name == value)
				resolved_faith = candidate
				resolved_path = path
				break
	if(!resolved_faith)
		return
	// Pull patron from faith godhead so the dropdowns stay in sync with
	// the classic HTML flow (preferences.dm setfaith branch).
	var/datum/patron/resolved = GLOB.patronlist[resolved_faith.godhead]
	if(!resolved)
		var/list/pool = GLOB.patrons_by_faith ? GLOB.patrons_by_faith[resolved_path] : null
		if(length(pool))
			resolved = GLOB.patronlist[pick(pool)]
	if(resolved)
		selected_patron = resolved

/datum/preferences/proc/set_pref_patron(value)
	var/path = text2path(value)
	if(!path)
		return
	var/datum/patron/resolved = GLOB.patronlist[path]
	if(resolved)
		selected_patron = resolved

/datum/preferences/proc/set_pref_rumor(value)
	_pref_apply_text("rumour", value, IDENTITY_MAX_FLAVOR_LEN)

/datum/preferences/proc/set_pref_noble_gossip(value)
	_pref_apply_text("noble_gossip", value, 400)

/datum/preferences/proc/set_pref_ooc_image_url(value)
	_pref_apply_text("flavor_ooc_image_url", value, 512)

/datum/preferences/proc/set_pref_nsfw_ooc_image_url(value)
	_pref_apply_text("nsfw_flavor_ooc_image_url", value, 512)

/datum/preferences/proc/set_pref_combat_music(value)
	var/path = text2path(value)
	if(!path)
		return
	var/datum/combat_music/track = GLOB.cmode_tracks_by_type[path]
	if(track)
		combat_music = track

/datum/preferences/proc/set_pref_headshot_link(value)
	if(!istext(value))
		return
	headshot_link = length(value) > 512 ? copytext(value, 1, 513) : value

/datum/preferences/proc/set_pref_chatheadshot_enabled(value)
	chatheadshot = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_cursed_enabled(value)
	cursed_enabled = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_extreme_erp(value)
	extreme_erp = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_edging(value)
	edging = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_intimate_enabled(value)
	intimate_enabled = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_intimate_reaction(value)
	intimate_reaction_enabled = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_show_intimate_examine(value)
	show_intimate_examine = !!(isnum(value) ? value : text2num("[value]"))

/datum/preferences/proc/set_pref_chastity_hardmode(value)
	var/n = isnum(value) ? value : text2num("[value]")
	chastity_hardmode = clamp(n, 0, 2)

/datum/preferences/proc/_pref_apply_chastity_bool(var_name, value, update_preview = FALSE)
	vars[var_name] = !!(isnum(value) ? value : text2num("[value]"))
	if(update_preview)
		character_preview_view?.update_body()

/datum/preferences/proc/set_pref_chastity_enabled(value)
	_pref_apply_chastity_bool("pref_chastity_enabled", value, TRUE)

/datum/preferences/proc/set_pref_chastity_flat(value)
	_pref_apply_chastity_bool("pref_chastity_flat", value, TRUE)

/datum/preferences/proc/set_pref_chastity_anal(value)
	_pref_apply_chastity_bool("pref_chastity_anal", value, TRUE)

/datum/preferences/proc/set_pref_chastity_spiked(value)
	_pref_apply_chastity_bool("pref_chastity_spiked", value, TRUE)

/datum/preferences/proc/set_pref_chastity_locked(value)
	_pref_apply_chastity_bool("pref_chastity_locked", value)

/datum/preferences/proc/set_pref_chastity_spawn_key(value)
	_pref_apply_chastity_bool("pref_chastity_spawn_key", value)

/datum/preferences/proc/set_pref_chastity_random_keys(value)
	_pref_apply_chastity_bool("pref_chastity_random_keys", value)

/datum/preferences/proc/set_pref_chastity_key_stashes(value)
	if(!islist(value) || !length(value))
		pref_chastity_key_stashes = null
		return
	var/list/out = list()
	for(var/name in value)
		var/sanitized = trim(sanitize_text(name))
		if(!length(sanitized) || length(sanitized) > MAX_NAME_LEN)
			continue
		var/duplicate = FALSE
		for(var/existing in out)
			if(LOWER_TEXT(existing) == LOWER_TEXT(sanitized))
				duplicate = TRUE
				break
		if(!duplicate)
			out += sanitized
		if(length(out) >= 5)
			break
	pref_chastity_key_stashes = length(out) ? out : null

/*
 * class_picker.dm — Addendum Turn 3: C1 inline class picker + C2 villain antag grid.
 *
 * Backs the Class & Stats → Class and Class & Stats → Villain rows with
 * inline pickers rather than the legacy vices_menu HTML handshake.
 *
 * ## Design: dedicated envelopes, not set_pref keys
 *
 * The flat set_pref allow-list assumes one scalar value per key. Job
 * priorities and villain role toggles are N-indexed collections:
 *   - job_preferences is an assoc list of `title → JP_LOW/MEDIUM/HIGH`
 *   - be_special is a string-keyed LIST (presence == enabled)
 *
 * Dumping each job title or ROLE_* into the setter table would either
 * bloat the allow-list (~60 jobs × one setter each) or force the client
 * to serialize composite keys. Instead we expose two dedicated ui_act
 * envelopes that route through their own tiny allow-lists:
 *
 *   set_job_priority   { title, level }    → act_set_job_priority
 *   set_villain_role   { role, enabled }   → act_set_villain_role
 *
 * Both handlers validate their inputs against the live SSjob/occupations
 * list and GLOB.special_roles_rogue respectively, so a rogue client
 * can't plant arbitrary strings.
 *
 * ## Static data
 *
 *   - build_class_picker_options() groups SSjob.occupations by the
 *     GLOB.*_positions buckets the legacy HTML picker already uses
 *     (Nobility / Church / Garrison / …). Jobs with no round-start
 *     spawn slots are skipped like the legacy HTML picker; remaining
 *     jobs may be marked unselectable with a reason when the classic
 *     availability checks would render them without a preference link.
 *   - build_villain_role_options() walks GLOB.special_roles_rogue and
 *     tags each entry with the jobban and account-age gates checked by
 *     the legacy HTML flow.
 *
 * ## Snapshot shape
 *
 * Emitted at ui_data top level (not inside the `prefs` snapshot) so
 * build_prefs_snapshot stays flat-key per its contract. Shape:
 *
 *   job_preferences_map  = { "Blacksmith": 2, "Guardsman": 3, ... }
 *   villain_roles_enabled = [ "Maniac", "Bandit", ... ]
 *
 * The TSX reads the map entries by title and lights up the matching
 * priority button; villain rows check inclusion in the enabled array.
 */

// ---------------------------------------------------------------------------
// Department bucket ordering for the class picker. Mirrors the HTML
// preferences_menu layout so long-time contributors recognize the taxonomy.
// ---------------------------------------------------------------------------

/**
 * Resolve a job title to its human-readable category bucket for the
 * picker. Returns "Other" when the title doesn't appear in any of the
 * registered GLOB position lists.
 *
 * Hardcoded dispatch (rather than a GLOB.vars[] lookup) because
 * dynamic global-by-name access isn't idiomatic in this codebase and
 * the list is short enough that the cost is a wash.
 */
/proc/_prefs_resolve_job_category(title)
	if(!istext(title))
		return "Other"
	if(title in GLOB.noble_positions)
		return "Nobility"
	if(title in GLOB.courtier_positions)
		return "Courtiers"
	if(title in GLOB.church_positions)
		return "Church"
	if(title in GLOB.inquisition_positions)
		return "Inquisition"
	if(title in GLOB.garrison_positions)
		return "Garrison"
	if(title in GLOB.mercenary_positions)
		return "Mercenaries"
	if(title in GLOB.yeoman_positions)
		return "Yeomen"
	if(title in GLOB.peasant_positions)
		return "Peasants"
	if(title in GLOB.youngfolk_positions)
		return "Youngfolk"
	return "Other"

/proc/_prefs_job_visible_in_class_picker(datum/job/job)
	if(!istype(job, /datum/job/roguetown))
		return FALSE
	return job.spawn_positions ? TRUE : FALSE

/proc/_prefs_class_picker_unavailable_message(unavailable_status, datum/job/job, mob/user)
	switch(unavailable_status)
		if(JOB_UNAVAILABLE_GENERIC)
			return "[job.title] is unavailable."
		if(JOB_UNAVAILABLE_BANNED)
			return "You are currently banned from [job.title]."
		if(JOB_UNAVAILABLE_PLAYTIME)
			return "You do not have enough relevant playtime for [job.title]."
		if(JOB_UNAVAILABLE_ACCOUNTAGE)
			return "Your account is not old enough for [job.title]."
		if(JOB_UNAVAILABLE_RACE)
			return "[job.title] is not meant for your kind."
		if(JOB_UNAVAILABLE_SEX)
			return "[job.title] is not meant for your lesser sex."
		if(JOB_UNAVAILABLE_AGE)
			return "[job.title] is not meant for your age."
		if(JOB_UNAVAILABLE_PATRON)
			return "[job.title] requires more faith."
		if(JOB_UNAVAILABLE_LASTCLASS)
			return "You have played [job.title] recently."
		if(JOB_UNAVAILABLE_JOB_COOLDOWN)
			var/remaining_time = 0
			var/user_ckey = user?.ckey
			if(user_ckey && (user_ckey in GLOB.job_respawn_delays))
				remaining_time = round((GLOB.job_respawn_delays[user_ckey] - world.time) / 10)
			return remaining_time ? "You must wait [remaining_time] seconds before playing as [job.title] again." : "[job.title] is on cooldown."
		if(JOB_UNAVAILABLE_VIRTUESVICE)
			return "[job.title] is restricted by your Virtues or Vices."
		if(JOB_UNAVAILABLE_PQ)
			var/player_pq = user?.ckey ? get_playerquality(user.ckey) : "unknown"
			return "You do not meet the Player Quality requirement for [job.title]. (Required: [job.min_pq], Your PQ: [player_pq])"
	return "[job.title] is unavailable."

/proc/_prefs_class_picker_unavailable_reason(datum/job/job, mob/user)
	if(!job || !user)
		return null
	if(isnewplayer(user))
		var/mob/dead/new_player/new_player = user
		var/job_unavailable = new_player.IsJobUnavailable(job.title, latejoin = FALSE)
		var/static/list/acceptable_unavailables = list(
			JOB_AVAILABLE,
			JOB_UNAVAILABLE_SLOTFULL,
		)
		if(!(job_unavailable in acceptable_unavailables))
			return _prefs_class_picker_unavailable_message(job_unavailable, job, user)
	return null

/proc/_prefs_copy_numeric_assoc(list/source)
	var/list/out = list()
	if(!length(source))
		return out
	for(var/source_key in source)
		var/source_value = source[source_key]
		if(isnum(source_value))
			out[source_key] = source_value
	return out

/proc/_prefs_build_trait_descriptors(list/source_traits)
	var/list/out = list()
	if(!length(source_traits))
		return out
	for(var/trait_id in source_traits)
		var/trait_desc = null
		if(islist(GLOB.roguetraits) && (trait_id in GLOB.roguetraits))
			trait_desc = GLOB.roguetraits[trait_id]
		out += list(list(
			"id" = "[trait_id]",
			"desc" = trait_desc,
		))
	return out

/proc/_prefs_build_language_name_list(list/source_paths)
	var/list/out = list()
	if(!length(source_paths))
		return out
	for(var/source_path in source_paths)
		if(ispath(source_path, /datum/language))
			var/datum/language/language_instance = new source_path()
			out += language_instance.vars["name"] || "[source_path]"
			qdel(language_instance)
		else
			out += "[source_path]"
	return out

/proc/_prefs_build_stashed_item_list(list/source_items)
	var/list/out = list()
	if(!length(source_items))
		return out
	for(var/stashed_item in source_items)
		out += "[stashed_item]"
	return out

/proc/_prefs_build_notable_skill_descriptors(list/source_skills)
	var/list/out = list()
	if(!length(source_skills))
		return out
	var/list/notable_skills = list()
	for(var/skill_path in source_skills)
		var/skill_level = source_skills[skill_path]
		if(!isnum(skill_level))
			continue
		if(skill_level >= SKILL_LEVEL_JOURNEYMAN || ispath(skill_path, /datum/skill/combat))
			notable_skills[skill_path] = skill_level
	if(!length(notable_skills))
		return out
	notable_skills = sortTim(notable_skills, /proc/cmp_numeric_dsc, TRUE)
	var/max_skills = 5
	for(var/skill_path in notable_skills)
		if(max_skills <= 0)
			break
		var/skill_rank = notable_skills[skill_path]
		var/skill_name = "[skill_path]"
		if(ispath(skill_path, /datum/skill))
			var/datum/skill/skill_type = skill_path
			skill_name = initial(skill_type.name) || skill_name
		var/skill_rank_name = "[skill_rank]"
		if(SSskills && islist(SSskills.level_names) && length(SSskills.level_names) >= skill_rank)
			skill_rank_name = SSskills.level_names[skill_rank]
		out += list(list(
			"name" = skill_name,
			"level" = skill_rank_name,
		))
		max_skills--
	return out

/proc/_prefs_build_advclass_descriptor(advclass_path)
	if(!ispath(advclass_path, /datum/advclass))
		return null
	var/datum/advclass/advclass_type = advclass_path
	var/advclass_name = initial(advclass_type.name)
	if(!advclass_name)
		return null
	var/datum/advclass/advclass_ref = null
	var/created_local = FALSE
	if(SSrole_class_handler)
		advclass_ref = SSrole_class_handler.get_advclass_by_name(advclass_name)
	if(!advclass_ref)
		advclass_ref = new advclass_path()
		created_local = TRUE
	var/list/out = list(
		"id" = "[advclass_ref.type]",
		"name" = advclass_ref.name || advclass_name,
		"tutorial" = advclass_ref.tutorial,
		"extra_context" = advclass_ref.extra_context,
		"subclass_stats" = _prefs_copy_numeric_assoc(advclass_ref.subclass_stats),
		"stat_ceilings" = _prefs_copy_numeric_assoc(advclass_ref.adv_stat_ceiling),
		"traits" = _prefs_build_trait_descriptors(advclass_ref.traits_applied),
		"spellpoints" = advclass_ref.subclass_spellpoints,
		"languages" = _prefs_build_language_name_list(advclass_ref.subclass_languages),
		"stashed_items" = _prefs_build_stashed_item_list(advclass_ref.subclass_stashed_items),
		"skills" = _prefs_build_notable_skill_descriptors(advclass_ref.subclass_skills),
	)
	if(created_local)
		qdel(advclass_ref)
	return out

/**
 * Build the class-picker static payload consumed by Class.tsx. Walks
 * SSjob.occupations (sorted via cmp_job_display_asc for a stable UI)
 * and emits one descriptor per job.
 *
 * Keys:
 *   title          — savefile-authoritative job title string
 *   display_title  — human-readable label (falls back to title)
 *   category       — bucket label (see _prefs_resolve_job_category)
 *   selection_color — department color for the row accent
 *   description    — short flavor from /datum/job.tutorial (may be null)
 *   banned         — 1 when the caller is jobbanned from this title
 *   selectable     — 1 when the row may mutate job_preferences
 *   unavailable_reason — classic availability text when selectable=0
 *
 * Null-safe: returns an empty list if SSjob hasn't initialized.
 */
/datum/preferences/proc/build_class_picker_options(mob/user)
	var/list/out = list()
	if(!SSjob || !length(SSjob.occupations))
		return out
	var/ckey = parent?.ckey || user?.ckey
	for(var/datum/job/job as anything in sortList(SSjob.occupations, GLOBAL_PROC_REF(cmp_job_display_asc)))
		if(!_prefs_job_visible_in_class_picker(job))
			continue
		var/banned = ckey ? (is_banned_from(ckey, job.title) ? 1 : 0) : 0
		var/unavailable_reason = banned ? null : _prefs_class_picker_unavailable_reason(job, user)
		var/list/advclasses = list()
		if(length(job.job_subclasses))
			for(var/advclass_path in job.job_subclasses)
				var/list/advclass_descriptor = _prefs_build_advclass_descriptor(advclass_path)
				if(length(advclass_descriptor))
					advclasses += list(advclass_descriptor)
		out += list(list(
			"title"           = job.title,
			"display_title"   = job.display_title || job.title,
			"category"        = _prefs_resolve_job_category(job.title),
			"selection_color" = job.selection_color,
			"description"     = job.tutorial,
			"job_stats"       = _prefs_copy_numeric_assoc(job.job_stats),
			"stat_ceilings"   = _prefs_copy_numeric_assoc(job.stat_ceilings),
			"job_traits"      = _prefs_build_trait_descriptors(job.job_traits),
			"advclasses"      = advclasses,
			"banned"          = banned,
			"selectable"      = (!banned && !unavailable_reason) ? 1 : 0,
			"unavailable_reason" = unavailable_reason,
		))
	return out

/**
 * Build the villain-role static payload consumed by Villain.tsx. Walks
 * GLOB.special_roles_rogue (ordered list of ROLE_* → antagonist path).
 */
/proc/_prefs_villain_role_unavailable_reason(role_id, mob/user)
	if(!islist(GLOB.special_roles_rogue) || !(role_id in GLOB.special_roles_rogue))
		return "Unavailable"
	var/role_path = GLOB.special_roles_rogue[role_id]
	if(ispath(role_path) && CONFIG_GET(flag/use_age_restriction_for_jobs))
		var/days_remaining = get_remaining_days(user?.client)
		if(days_remaining)
			return "IN [days_remaining] DAYS"
	return null

/datum/preferences/proc/build_villain_role_options(mob/user)
	var/list/out = list()
	if(!islist(GLOB.special_roles_rogue))
		return out
	var/ckey = parent?.ckey || user?.ckey
	// Hard-block when the player is syndicate-banned — matches the
	// legacy HTML branch that wipes be_special on display.
	var/global_antag_ban = ckey ? (is_banned_from(ckey, ROLE_SYNDICATE) ? 1 : 0) : 0
	for(var/role_id in GLOB.special_roles_rogue)
		var/banned = global_antag_ban
		if(!banned && ckey)
			banned = is_banned_from(ckey, role_id) ? 1 : 0
		var/unavailable_reason = banned ? null : _prefs_villain_role_unavailable_reason(role_id, user)
		out += list(list(
			"id"                 = role_id,
			"label"              = capitalize(role_id),
			"banned"             = banned,
			"selectable"         = (!banned && !unavailable_reason) ? 1 : 0,
			"unavailable_reason" = unavailable_reason,
		))
	return out

// ---------------------------------------------------------------------------
// ui_act handlers — C1 set_job_priority and C2 set_villain_role.
// ---------------------------------------------------------------------------

/// Legal wire values for `level` on set_job_priority. 0 clears the slot.
GLOBAL_LIST_INIT(prefs_job_priority_levels, list(0, JP_LOW, JP_MEDIUM, JP_HIGH))

/**
 * Apply a single job-priority change. Uses the existing
 * SetJobPreferenceLevel helper for HIGH-demotes-others semantics;
 * explicit level==0 removes the entry entirely so the savefile doesn't
 * accumulate NEVER rows.
 *
 * Returns TRUE when the datum was mutated (caller republishes the UI).
 * Returns FALSE on validation failure (unknown title, jobban, or a level
 * outside the allow-list); the rate-limit counter already consumed the
 * attempt so there's no re-entry concern.
 */
/datum/preferences/proc/act_set_job_priority(title, level, mob/user)
	if(!istext(title) || !length(title))
		return FALSE
	var/int_level = isnum(level) ? level : text2num("[level]")
	if(!(int_level in GLOB.prefs_job_priority_levels))
		return FALSE
	if(!SSjob)
		return FALSE
	var/datum/job/job = SSjob.GetJob(title)
	if(!_prefs_job_visible_in_class_picker(job))
		return FALSE
	// Jobban gate: the picker surfaces `banned=1` in the static payload,
	// but a client could still craft a raw ui_act. Server enforces.
	var/ckey = parent?.ckey || user?.ckey
	if(ckey && is_banned_from(ckey, job.title))
		return FALSE
	if(_prefs_class_picker_unavailable_reason(job, user))
		return FALSE
	if(!job_preferences)
		job_preferences = list()
	if(int_level == 0)
		job_preferences -= job.title
	else
		SetJobPreferenceLevel(job, int_level)
	// Job row is zero-filled today but flagged as stat-affecting per
	// Step 5's invalidation contract — future contributors who wire a
	// job stat contribution won't need to hunt for the cache bust.
	invalidate_stat_matrix()
	if(!dirty_keys)
		dirty_keys = list()
	dirty_keys |= "job_preferences"
	return TRUE

/**
 * Toggle a villain antag role opt-in. `be_special` is a string-keyed
 * list (presence == enabled); this proc adds or removes the string
 * atomically after validating against GLOB.special_roles_rogue and the
 * jobban cache.
 *
 * Returns TRUE on mutation; FALSE on unknown role / jobban / no-op.
 */
/datum/preferences/proc/act_set_villain_role(role_id, enabled, mob/user)
	if(!istext(role_id) || !length(role_id))
		return FALSE
	if(!islist(GLOB.special_roles_rogue) || !(role_id in GLOB.special_roles_rogue))
		return FALSE
	var/ckey = parent?.ckey || user?.ckey
	if(ckey)
		// Syndicate ban wipes the whole list (parity with the legacy
		// HTML path); individual-role ban blocks just this role.
		if(is_banned_from(ckey, ROLE_SYNDICATE))
			if(length(be_special))
				be_special = list()
				if(!dirty_keys)
					dirty_keys = list()
				dirty_keys |= "be_special"
				return TRUE
			return FALSE
		if(is_banned_from(ckey, role_id))
			return FALSE
	if(_prefs_villain_role_unavailable_reason(role_id, user))
		return FALSE
	var/want = (isnum(enabled) ? enabled : text2num("[enabled]")) ? TRUE : FALSE
	if(!islist(be_special))
		be_special = list()
	var/have = (role_id in be_special) ? TRUE : FALSE
	if(want == have)
		return FALSE
	if(want)
		be_special |= role_id
	else
		be_special -= role_id
	if(!dirty_keys)
		dirty_keys = list()
	dirty_keys |= "be_special"
	return TRUE

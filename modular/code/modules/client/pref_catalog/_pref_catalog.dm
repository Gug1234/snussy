/**
 * pref_catalog — Phase 1: plan enumerator (no iconforge yet).
 *
 * Walks a list of /datum/species typepaths, collects every unique
 * /datum/customizer_choice referenced via species.customizers, and
 * emits a JSON "catalog plan" describing one job per choice with a
 * sprites map ready to be fed to rustg_iconforge_generate.
 *
 * Phase 1 deliberately does NOT call iconforge. It writes the plan
 * file to disk so we can inspect the data shape and verify coverage
 * before wiring into appearance_preview_materialize.dm in Phase 2.
 *
 * Invocation:
 *   - dev: admin verb in pref_catalog_admin_verb.dm
 *   - future: from /world/New() under a `-pref_catalog_materialize=1`
 *     param branch (Phase 2).
 *
 * Output schema (v1):
 *   {
 *     "version": 1,
 *     "speciesTargets": ["anthromorph", "moth", "constructm", ...],
 *     "jobs": [
 *       // per-customizer_choice catalog
 *       {
 *         "kind": "catalog",
 *         "spritesheetName": "customizer_choice__organ__wings__anthro",
 *         "outputPath": "pref_catalog/sheets/customizer_choice__organ__wings__anthro.png",
 *         "displayName": "Wings",
 *         "customizerChoiceType": "/datum/customizer_choice/organ/wings/anthro",
 *         "allowsAccessoryColorCustomization": true,
 *         "sprites": { "<safe_accessory_name>": { ... }, ... }
 *       },
 *       // shared body-markings catalog (one per build, deduped across all species)
 *       {
 *         "kind": "catalog",
 *         "spritesheetName": "body_markings",
 *         "outputPath": "pref_catalog/sheets/body_markings.png",
 *         "displayName": "Body Markings",
 *         "customizerChoiceType": null,
 *         "allowsAccessoryColorCustomization": true,
 *         "sprites": { "<safe_marking_name>": { ... }, ... }
 *       }
 *     ]
 *   }
 *
 * Sprite key naming: type-path strip + slash→__. Gendered_variants accessories
 * emit two entries with `__m` / `__f` suffixes, each carrying the prefixed
 * icon_state. This matches how /datum/sprite_accessory consumers actually
 * reference icons at runtime.
 */

/// Emit a catalog plan to disk. Returns TRUE on success, FALSE on any failure.
/// `species_types` is a list of /datum/species typepaths. `output_path` is a
/// fully-qualified file path. The directory must already exist.
/proc/pref_catalog_emit_plan(output_path, list/species_types)
	if(!istext(output_path) || !length(output_path))
		stack_trace("pref_catalog_emit_plan: output_path missing")
		return FALSE
	if(!islist(species_types) || !length(species_types))
		stack_trace("pref_catalog_emit_plan: species_types empty")
		return FALSE
	var/list/plan = pref_catalog_build_plan(species_types)
	if(!islist(plan))
		return FALSE
	var/encoded = json_encode(plan)
	if(!istext(encoded) || !length(encoded))
		stack_trace("pref_catalog_emit_plan: json_encode produced no text")
		return FALSE
	rustg_file_write(encoded, output_path)
	return TRUE

/// Build the full plan list (encodable). See file header for schema.
/proc/pref_catalog_build_plan(list/species_types)
	var/list/plan = list(
		"version" = 1,
		"speciesTargets" = list(),
		"jobs" = list(),
	)
	var/list/seen_choice_types = list()
	var/list/seen_marking_types = list()
	var/list/marking_sprites = list()
	for(var/species_type in species_types)
		if(!ispath(species_type, /datum/species))
			stack_trace("pref_catalog_build_plan: '[species_type]' is not a /datum/species path; skipping")
			continue
		var/datum/species/species_proto = new species_type()
		plan["speciesTargets"] += species_proto.id
		for(var/customizer_type in species_proto.customizers)
			if(!ispath(customizer_type, /datum/customizer))
				continue
			var/datum/customizer/customizer = GLOB.customizers[customizer_type]
			if(!customizer)
				stack_trace("pref_catalog_build_plan: customizer [customizer_type] not in GLOB.customizers")
				continue
			for(var/choice_type in customizer.customizer_choices)
				if(seen_choice_types[choice_type])
					continue
				seen_choice_types[choice_type] = TRUE
				var/list/job = pref_catalog_build_choice_job(choice_type)
				if(islist(job))
					plan["jobs"] += list(job)
		// Body markings: dedupe across all species into one shared sprite map.
		// body_marking_sets are pure composites of body_marking entries, so we
		// only need to bake the underlying markings; the UI composes sets.
		for(var/marking_type in species_proto.body_markings)
			if(seen_marking_types[marking_type])
				continue
			seen_marking_types[marking_type] = TRUE
			var/datum/body_marking/marking = GLOB.body_markings_by_type[marking_type]
			if(!marking || !marking.icon || !marking.icon_state)
				continue
			var/list/entry = pref_catalog_body_marking_sprite_entry(marking)
			if(islist(entry))
				marking_sprites[pref_catalog_typepath_to_safe_name(marking_type)] = entry
		qdel(species_proto)
	if(length(marking_sprites))
		plan["jobs"] += list(list(
			"kind" = "catalog",
			"spritesheetName" = "body_markings",
			"outputPath" = "pref_catalog/sheets/body_markings.png",
			"displayName" = "Body Markings",
			"customizerChoiceType" = null,
			"allowsAccessoryColorCustomization" = TRUE,
			"sprites" = marking_sprites,
		))
	return plan

/// Pick a representative preview sprite for a /datum/body_marking. Body markings
/// are rendered as `<icon_state>_<zone>` (or `<zone>_<m|f>` when gendered), with
/// no single canonical preview state. We pick the first applicable zone in
/// HEAD > CHEST > L_ARM > L_LEG order and default to male for gendered ones.
/proc/pref_catalog_body_marking_sprite_entry(datum/body_marking/marking)
	var/zone
	var/affected = marking.affected_bodyparts
	if(affected & HEAD)
		zone = BODY_ZONE_HEAD
	else if(affected & CHEST)
		zone = BODY_ZONE_CHEST
	else if(affected & ARM_LEFT)
		zone = BODY_ZONE_L_ARM
	else if(affected & ARM_RIGHT)
		zone = BODY_ZONE_R_ARM
	else if(affected & LEG_LEFT)
		zone = BODY_ZONE_L_LEG
	else if(affected & LEG_RIGHT)
		zone = BODY_ZONE_R_LEG
	else
		// No renderable zone; nothing useful to preview.
		return null
	var/state_suffix = zone
	if(marking.gendered && (!marking.gender_only_chest || zone == BODY_ZONE_CHEST))
		state_suffix = "[zone]_m"
	var/state = "[marking.icon_state]_[state_suffix]"
	// Fail-soft: if the constructed state isn't in the DMI, probe the
	// gender-flipped variant, then a bare-zone fallback. Same reasoning as
	// the sprite_accessory state probe — iconforge hard-errors where BYOND's
	// icon() would silently return blank.
	if(!icon_exists(marking.icon, state))
		var/list/fallbacks = list(
			"[marking.icon_state]_[zone]_f",
			"[marking.icon_state]_[zone]_m",
			"[marking.icon_state]_[zone]",
			marking.icon_state,
		)
		state = null
		for(var/candidate in fallbacks)
			if(icon_exists(marking.icon, candidate))
				state = candidate
				break
		if(!state)
			stack_trace("pref_catalog_body_marking_sprite_entry: no DMI state found for marking [marking.type] in '[marking.icon]' (base state '[marking.icon_state]', zone '[zone]')")
			return null
	return pref_catalog_sprite_entry(marking.icon, state)

/// Build a single catalog job for one /datum/customizer_choice typepath.
/// Returns null if the choice has no sprite_accessories (e.g. organ-only choices).
/proc/pref_catalog_build_choice_job(choice_type)
	var/datum/customizer_choice/choice = GLOB.customizer_choices[choice_type]
	if(!choice)
		stack_trace("pref_catalog_build_choice_job: '[choice_type]' not in GLOB.customizer_choices")
		return null
	if(!length(choice.sprite_accessories))
		// Plenty of choices are pure-organ with no accessory list (e.g. simple
		// disable-only toggles). Skipping is correct, not an error.
		return null

	var/sheet_name = pref_catalog_typepath_to_safe_name(choice_type)
	var/list/sprites = list()
	// Per-family rendering tweaks:
	//  * Tails sit BEHIND the body; rendered SOUTH they're mostly hidden by
	//    the torso. Render EAST so the tail is silhouetted against open
	//    space, which is what the player actually picks from.
	//  * Genital choices (breasts/penis/testicles) are size-driven via a
	//    numeric `_<N>` suffix the runtime composes from breast_size /
	//    penis_size / ball_size. Pull every existing size as its own entry
	//    so the picker can show all variants.
	var/choice_dir = pref_catalog_choice_render_dir(choice_type)
	var/list/size_suffixes = pref_catalog_choice_size_suffixes(choice_type)
	for(var/accessory_type in choice.sprite_accessories)
		var/datum/sprite_accessory/accessory = GLOB.sprite_accessories[accessory_type]
		if(!accessory)
			stack_trace("pref_catalog_build_choice_job: accessory [accessory_type] missing from GLOB.sprite_accessories")
			continue
		if(!accessory.icon || !accessory.icon_state)
			// Some accessories (e.g. /datum/sprite_accessory/none) are sentinel
			// entries with no renderable sprite. Skip silently.
			continue
		var/safe_acc = pref_catalog_typepath_to_safe_name(accessory_type)
		if(islist(size_suffixes))
			// Size-variant accessory: emit one entry per existing size.
			// Key naming: "<safe_acc>__size<N>" so the picker can render a
			// sub-grid of sizes under each accessory parent.
			var/emitted = 0
			for(var/sfx in size_suffixes)
				var/sized_state = pref_catalog_resolve_sized_accessory_state(accessory, sfx)
				if(!sized_state)
					continue
				sprites["[safe_acc]__size[sfx]"] = pref_catalog_sprite_entry(accessory.icon, sized_state, choice_dir)
				emitted++
			if(!emitted)
				stack_trace("pref_catalog_build_choice_job: no sized DMI states found for accessory [accessory_type] in '[accessory.icon]' (base '[accessory.icon_state]', sizes [json_encode(size_suffixes)])")
			continue
		// `icon_state` on a sprite_accessory is a prefix, not necessarily the
		// final DMI state. The runtime composer adds suffixes for gender
		// (`_f`/`_m`), layer (`_FRONT`/`_BEHIND`/...), or legacy gender
		// prefixes (`m_`/`f_`). BYOND's icon() silently returns blank for
		// missing states, but rustg_iconforge errors out, so we have to
		// resolve a state that actually exists in the DMI here. We pick a
		// single representative variant — the picker only needs a thumbnail.
		var/resolved = pref_catalog_resolve_accessory_state(accessory)
		if(!resolved)
			// No probed variant exists; this accessory is content-broken
			// upstream (no renderable state). Skip rather than fail the
			// whole catalog bake — log so the responsible content owner
			// can fix it.
			stack_trace("pref_catalog_build_choice_job: no DMI state found for accessory [accessory_type] in '[accessory.icon]' (base state '[accessory.icon_state]')")
			continue
		sprites[safe_acc] = pref_catalog_sprite_entry(accessory.icon, resolved, choice_dir)

	if(!length(sprites))
		return null

	return list(
		"kind" = "catalog",
		"spritesheetName" = sheet_name,
		"outputPath" = "pref_catalog/sheets/[sheet_name].png",
		"displayName" = choice.name,
		"customizerChoiceType" = "[choice_type]",
		"allowsAccessoryColorCustomization" = choice.allows_accessory_color_customization ? TRUE : FALSE,
		"sprites" = sprites,
	)

/// Build a single sprite entry (the [SPRITE_OBJECT] shape rust_g.dm documents).
/// Defaults to dir=SOUTH, frame=1, no transforms. Caller may pass a custom
/// dir (e.g. EAST for tails, which would otherwise be hidden behind the
/// body in the SOUTH view). Greyscale tinting happens client-side per the
/// agreed design.
/proc/pref_catalog_sprite_entry(icon_file, icon_state, render_dir = SOUTH)
	return list(
		"icon_file" = "[icon_file]",
		"icon_state" = "[icon_state]",
		"dir" = render_dir,
		"frame" = 1,
		"transform" = list(),
	)

/// Pick the render direction for a customizer choice's catalog thumbnail.
/// Tails (and tail features) are rendered EAST because SOUTH-view tails
/// sit behind the torso and produce mostly-empty thumbnails. Everything
/// else uses SOUTH, the conventional preview face.
/proc/pref_catalog_choice_render_dir(choice_type)
	if(ispath(choice_type, /datum/customizer_choice/organ/tail))
		return EAST
	if(ispath(choice_type, /datum/customizer_choice/organ/tail_feature))
		return EAST
	return SOUTH

/// Return a list of size suffix strings for size-driven accessory families
/// (breasts/penis/testicles), or null for non-sized choices. The runtime
/// composes states as `<icon_state>_<N>` from breast_size / penis_size /
/// ball_size; we emit one entry per integer in the documented range. Sizes
/// whose DMI state doesn't actually exist are skipped per-accessory (some
/// accessories only define a subset of the global range).
/proc/pref_catalog_choice_size_suffixes(choice_type)
	if(ispath(choice_type, /datum/customizer_choice/organ/breasts))
		var/list/out = list()
		for(var/n in MIN_BREASTS_SIZE to MAX_BREASTS_SIZE)
			out += "[n]"
		return out
	if(ispath(choice_type, /datum/customizer_choice/organ/penis))
		var/list/out = list()
		for(var/n in MIN_PENIS_SIZE to MAX_PENIS_SIZE)
			out += "[n]"
		return out
	if(ispath(choice_type, /datum/customizer_choice/organ/testicles))
		var/list/out = list()
		for(var/n in MIN_TESTICLES_SIZE to MAX_TESTICLES_SIZE)
			out += "[n]"
		return out
	return null

/// Resolve a DMI state for one specific size suffix on a size-driven
/// accessory. The runtime composer formats `<icon_state>_<N>`, but the
/// real DMI may key the state with extra layer/frame segments (e.g.
/// `human_1_FRONT_1`). Try the canonical form first, then a couple of
/// layered fallbacks, then bail. Returns the resolved state name or null.
/proc/pref_catalog_resolve_sized_accessory_state(datum/sprite_accessory/accessory, size_suffix)
	if(!accessory || !accessory.icon || !accessory.icon_state || !istext(size_suffix))
		return null
	var/base = "[accessory.icon_state]_[size_suffix]"
	var/list/candidates = list(
		base,
		"[base]_FRONT",
		"[base]_FRONT_1",
		"[base]_1",
		"[base]_ADJ",
	)
	for(var/state in candidates)
		if(icon_exists(accessory.icon, state))
			return state
	// Last-resort scan: any state starting with "<base>_" (covers exotic
	// suffix patterns the runtime also tolerates).
	var/list/all_states = icon_states(accessory.icon)
	if(!islist(all_states) || !length(all_states))
		return null
	var/anchor = "[base]_"
	for(var/state in all_states)
		if(findtext(state, anchor) == 1)
			return state
	return null

/// Probe a sprite_accessory's DMI for the first state that actually exists
/// among the conventional suffix/prefix variants the runtime composer might
/// use. Returns the resolved state name or null if nothing matched.
///
/// `icon_state` on a sprite_accessory is treated by the runtime as a prefix
/// — gender (_f/_m or m_/f_), layer (_FRONT/_BEHIND/_ADJ/...), or both. Many
/// accessories also override `get_icon_state()` to return arbitrary computed
/// names (e.g. bikini -> "bikini_f_0"), in which case the var is just a
/// stable key, not a real state name. We therefore:
///   1. Try a small priority list of conventional suffix/prefix variants
///      (cheap, covers most cases).
///   2. Fall back to scanning the full state list of the DMI and picking
///      the first state that begins with the accessory's `icon_state` or,
///      if that fails, contains it as a substring.
///
/// BYOND's builtin icon() silently returns a blank icon for a missing state,
/// but rustg_iconforge_generate hard-errors. We resolve a single representative
/// variant per accessory because the picker only needs a thumbnail.
/proc/pref_catalog_resolve_accessory_state(datum/sprite_accessory/accessory)
	if(!accessory || !accessory.icon || !accessory.icon_state)
		return null
	var/base = accessory.icon_state
	var/list/candidates = list(
		base,
		"[base]_FRONT",
		"[base]_m",
		"m_[base]",
		"[base]_f",
		"f_[base]",
		"[base]_0",
		"[base]_1",
		"[base]_BEHIND",
		"[base]_ADJ",
		"[base]_FFRONT",
		"[base]_UNDER",
		"[base]_NECK",
	)
	for(var/state in candidates)
		if(icon_exists(accessory.icon, state))
			return state

	// Last-resort scan. Some accessories override get_icon_state() to return
	// computed names where `icon_state` is just a stable key — e.g.
	// /datum/sprite_accessory/underwear/bikini has icon_state="female_bikini"
	// but the DMI only contains "bikini_f_0..9". We try (a) any state that
	// starts with the base, then (b) any state that contains the base, then
	// (c) any state that contains a stripped key (gender prefix removed).
	// First match wins; the picker only needs a thumbnail.
	var/list/all_states = icon_states(accessory.icon)
	if(!islist(all_states) || !length(all_states))
		return null
	var/match = pref_catalog_match_state(all_states, base)
	if(match)
		return match
	// Strip common prefixes that some accessories smuggle into icon_state.
	var/stripped = pref_catalog_strip_state_prefix(base)
	if(stripped && stripped != base)
		match = pref_catalog_match_state(all_states, stripped)
		if(match)
			return match
	return null

/// Pick the first state in `all_states` that matches `needle` by tier:
///   1. exact equality
///   2. starts with "<needle>_" AND contains "_FRONT"   (preferred renderable)
///   3. starts with "<needle>_"                          (any layer/variant)
///   4. exact equality to needle (already covered) — kept tier list flat for clarity
///   5. contains "<needle>_"                             (substring, anchored by '_')
///   6. contains needle                                  (last-resort substring)
///
/// Tier 2 exists because many accessories (e.g. /datum/sprite_accessory/penis)
/// store `icon_state` as a bare prefix while the DMI keys real states with
/// computed suffixes like `human_1_1_FRONT_1` and `human_1_BEHIND_1`. The
/// runtime composes both BEHIND and FRONT layers; for a picker thumbnail we
/// want FRONT. The "<needle>_" prefix and the trailing '_' on substring tiers
/// also avoid bleed onto sibling accessories that share a name fragment
/// (e.g. preferring `human_*` over `humanoid_*` when needle is "human").
/// Order within each tier is the DMI's declaration order, which is stable.
/proc/pref_catalog_match_state(list/all_states, needle)
	if(!islist(all_states) || !istext(needle) || !length(needle))
		return null
	for(var/state in all_states)
		if(state == needle)
			return state
	var/anchor = "[needle]_"
	for(var/state in all_states)
		if(findtext(state, anchor) == 1 && findtext(state, "_FRONT"))
			return state
	for(var/state in all_states)
		if(findtext(state, anchor) == 1)
			return state
	for(var/state in all_states)
		if(findtext(state, anchor))
			return state
	for(var/state in all_states)
		if(findtext(state, needle))
			return state
	return null

/// Strip conventional prefixes some accessories embed in `icon_state` so
/// the substring match has a chance against DMIs that key off the bare
/// trait name. Returns the stripped string, or null if nothing was stripped.
/proc/pref_catalog_strip_state_prefix(state)
	if(!istext(state) || !length(state))
		return null
	var/static/list/prefixes = list("female_", "male_", "f_", "m_")
	for(var/prefix in prefixes)
		if(copytext(state, 1, length(prefix) + 1) == prefix)
			return copytext(state, length(prefix) + 1)
	return null

/// Convert a typepath like /datum/customizer_choice/organ/wings/anthro into
/// a filesystem-safe identifier "customizer_choice__organ__wings__anthro".
/// Used as both the spritesheet name and the per-accessory sprite key prefix.
/proc/pref_catalog_typepath_to_safe_name(typepath)
	var/text = "[typepath]"
	if(copytext(text, 1, 2) == "/")
		text = copytext(text, 2)
	// /datum/ prefix is uniform and uninformative; strip it for shorter keys.
	if(copytext(text, 1, 7) == "datum/")
		text = copytext(text, 7)
	return replacetext(text, "/", "__")

/// Default species set covered by Phase 1.
///
/// Returns every concrete /datum/species subtype that has a non-empty `id`.
/// Dedupe by customizer_choice typepath in `pref_catalog_build_plan` makes
/// adding more species essentially free — they only contribute when they
/// reference a choice no prior species has already covered.
/proc/pref_catalog_default_species_targets()
	var/list/targets = list()
	for(var/species_type in subtypesof(/datum/species))
		var/datum/species/species_proto = species_type
		if(!initial(species_proto.id))
			continue
		targets += species_type
	return targets

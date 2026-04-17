// Extreme Offset Vetting — Phase 2 policy helpers.
// Pure read-only calculations. No state, no logging, no UI.
// Thresholds: modular/code/__DEFINES/extreme_offset.dm
// Spec: modular/code/datums/EXTREME_OFFSET_POLICY.md
//
// Scale representation: /datum/customizer_entry stores `scale` as a raw
// numeric quantized value (see code/modules/client/customizer/customizer_entry.dm
// L20 — `var/scale = 1`, constrained to FEATURE_SCALE_CHOICES at set time).
// No /matrix involved; helpers accept raw numbers.

/// Runtime-tunable aggregate-offset budget for a single character. Summed
/// across all visible (whole-entry-enabled) customizer entries on a prefs
/// datum. Default from EXTREME_OFFSET_DEFAULT_AGGREGATE_BUDGET; admins may
/// retune live for ratcheting over time.
GLOBAL_VAR_INIT(extreme_aggregate_budget, EXTREME_OFFSET_DEFAULT_AGGREGATE_BUDGET)

/// Returns the EXTREME_FLAG_* bitfield for a single entry's transform.
/// `pixel_x`, `pixel_y` are signed int offsets. `scale` is a raw number
/// (1, 2, or anything in between if a future editor allows fractional).
/// Null-safe: treats nulls as zeros / unity.
/proc/compute_entry_extreme_flags(pixel_x, pixel_y, scale)
	var/flags = EXTREME_FLAG_NONE
	var/px = isnum(pixel_x) ? pixel_x : 0
	var/py = isnum(pixel_y) ? pixel_y : 0
	var/sc = isnum(scale) ? scale : 1
	var/abs_px = abs(px)
	var/abs_py = abs(py)

	// Soft pixel band
	if(abs_px > EXTREME_OFFSET_SOFT_PX || abs_py > EXTREME_OFFSET_SOFT_PX)
		flags |= EXTREME_FLAG_SOFT_PX
	// Hard pixel axial
	if(abs_px > EXTREME_OFFSET_HARD_PX || abs_py > EXTREME_OFFSET_HARD_PX)
		flags |= EXTREME_FLAG_HARD_PX
	// Hard pixel diagonal (squared compare; avoids sqrt)
	if((px * px + py * py) > EXTREME_OFFSET_HARD_DIAG_SQ)
		flags |= EXTREME_FLAG_HARD_DIAG

	// Soft/hard scale
	if(sc > EXTREME_OFFSET_SOFT_SCALE)
		flags |= EXTREME_FLAG_SOFT_SCALE
	if(sc > EXTREME_OFFSET_HARD_SCALE)
		flags |= EXTREME_FLAG_HARD_SCALE

	return flags

/proc/entry_is_hard_flagged(flags)
	return (flags & EXTREME_FLAG_HARD_MASK) != 0

/proc/entry_is_soft_flagged(flags)
	return (flags & EXTREME_FLAG_SOFT_MASK) != 0

/// Sums abs(pixel_x) + abs(pixel_y) over every whole-entry-enabled entry.
/// "Visible" here == accessory_type set (whole-entry-disabled entries carry
/// accessory_type == null and are flag-immune per policy). Per-direction
/// hides do NOT exempt an entry from the aggregate budget.
/// Defensive against nulls, non-customizer-entry elements, and bad lists.
/proc/compute_aggregate_offset_budget_used(list/entries)
	var/total = 0
	if(!islist(entries))
		return total
	for(var/datum/customizer_entry/entry as anything in entries)
		if(!istype(entry))
			continue
		if(isnull(entry.accessory_type))
			continue
		// Phase 6: composite fan-out. When sub_entries are populated, sum
		// each non-empty sub's transform. Parent fields mirror sub[1], so
		// iterating sub_entries alone already covers the primary — do NOT
		// also add parent offsets or we'd double-count sub[1].
		if(LAZYLEN(entry.sub_entries))
			for(var/datum/customizer_sub_entry/sub as anything in entry.sub_entries)
				if(!istype(sub))
					continue
				if(isnull(sub.accessory_type))
					continue
				var/spx = isnum(sub.pixel_x) ? sub.pixel_x : 0
				var/spy = isnum(sub.pixel_y) ? sub.pixel_y : 0
				total += abs(spx) + abs(spy)
			continue
		// Pre-migration / empty-sub-list fallback: read from parent.
		var/px = isnum(entry.pixel_x) ? entry.pixel_x : 0
		var/py = isnum(entry.pixel_y) ? entry.pixel_y : 0
		total += abs(px) + abs(py)
	return total

/proc/aggregate_budget_exceeded(budget_used)
	return budget_used > GLOB.extreme_aggregate_budget

/// Recompute the aggregate-extreme caches on a prefs datum. Walks the
/// known customizer_entry collection on prefs (the unified list at
/// /datum/preferences/var/customizer_entries — see
/// code/modules/client/preferences.dm L333). Callers should invoke this
/// whenever a persisted transform var on any owned entry changes, or
/// after load.
///
/// TODO (Phase 3+): other offset-bearing subsystems (body markings,
/// custom piercings, taur genital offsets) do not all live on
/// customizer_entries today. Each has its own storage:
///   * body_markings: flat-hex list, no offsets yet (see body_markings.md).
///   * custom piercings: /datum/custom_piercing_entry sidecar.
///   * taur genital offsets: likely direct vars on prefs.
/// Extend this walker per subsystem once each gains offset fields and a
/// well-defined collection. For now, only customizer_entries contributes.
/datum/preferences/proc/recompute_aggregate_extreme()
	aggregate_offset_budget_used = compute_aggregate_offset_budget_used(customizer_entries)
	aggregate_extreme = aggregate_budget_exceeded(aggregate_offset_budget_used)

// ---------------------------------------------------------------------------
// Phase 4 — Round-join batched admin log.
// ---------------------------------------------------------------------------
// Per-ckey dedupe set. Populated by report_extreme_offsets_on_roundjoin().
// NOT explicitly cleared: this server uses world.Reboot() at round-end (see
// code/controllers/subsystem/ticker.dm L769) which restarts the BYOND process
// and re-initializes all GLOBs. If a future code path introduces mid-process
// round resets without a world reboot, clear this list from that hook.
GLOBAL_LIST_EMPTY(extreme_offsets_logged_ckeys)

/// Phase 4: on round-join (after a character is spawned into the round and
/// job-equipped), emit ONE batched admin chat message per ckey per round if
/// the player has any hard-flagged customizer offsets or has exceeded the
/// aggregate offset budget. Fires regardless of admin presence.
///
/// Call site: /datum/job/proc/after_spawn in
/// code/modules/jobs/job_types/_job.dm, immediately after the
/// "has joined as" log_admin line. That proc fires once per character
/// materialization (roundstart and latejoin both), already skips the
/// non-human / dummy cases, and has H.client / H.mind available.
/proc/report_extreme_offsets_on_roundjoin(mob/living/carbon/human/H)
	if(!istype(H))
		return
	var/client/C = H.client
	if(!C)
		return
	var/datum/preferences/prefs = C.prefs
	if(!prefs)
		return
	var/ckey = C.ckey
	if(!ckey)
		return
	if(GLOB.extreme_offsets_logged_ckeys[ckey])
		return

	// Refresh aggregate caches in case anything mutated mid-lobby without
	// routing through the editor's mutation hooks.
	prefs.recompute_aggregate_extreme()

	var/list/flagged_entries = list()
	for(var/datum/customizer_entry/entry as anything in prefs.customizer_entries)
		if(!istype(entry))
			continue
		if(entry.is_hard_extreme)
			flagged_entries += entry

	if(!length(flagged_entries) && !prefs.aggregate_extreme)
		return

	GLOB.extreme_offsets_logged_ckeys[ckey] = TRUE

	// Phase 5: build + enqueue a review ticket so admins can inspect the
	// player via TGUI. Ticket captures snapshots of the flagged entries at
	// emit time, surviving later mid-round mutations.
	var/datum/extreme_offset_ticket/ticket = new(H, flagged_entries, prefs)
	if(istype(ticket) && GLOB.extreme_offset_review_manager)
		GLOB.extreme_offset_review_manager.enqueue_ticket(ticket)

	var/role = "Unknown"
	if(H.mind && H.mind.assigned_role)
		role = H.mind.assigned_role

	var/list/lines = list()
	lines += "[ADMIN_LOOKUPFLW(H)] joined as [H.real_name] ([role]) with extreme cosmetic offsets:"
	lines += "Acknowledged: [prefs.acknowledge_extreme_offsets ? "YES" : "NO"]"
	if(prefs.aggregate_extreme)
		lines += "Aggregate offset budget: [prefs.aggregate_offset_budget_used] / [GLOB.extreme_aggregate_budget] (EXCEEDED)"
	for(var/datum/customizer_entry/entry as anything in flagged_entries)
		var/emitted_sub = FALSE
		if(LAZYLEN(entry.sub_entries))
			for(var/i in 1 to length(entry.sub_entries))
				var/datum/customizer_sub_entry/sub = entry.sub_entries[i]
				if(!istype(sub) || !sub.is_hard_extreme)
					continue
				lines += "- [entry.customizer_type] \[sub [i]\]: pixel=([sub.pixel_x], [sub.pixel_y]) scale=[sub.scale] flags=[sub.extreme_flags]"
				emitted_sub = TRUE
		if(!emitted_sub)
			lines += "- [entry.customizer_type]: pixel=([entry.pixel_x], [entry.pixel_y]) scale=[entry.scale] flags=[entry.extreme_flags]"
	// Phase 5 review-panel link — routed through /datum/admins/Topic() →
	// handle_extreme_offset_review_topic().
	lines += "<a href='?_src_=holder;[HrefToken(TRUE)];extreme_review=[ckey]'>\[Review Offsets\]</a>"

	var/msg = jointext(lines, "<br>")
	message_admins(msg)

	// Plain-text mirror for the admin log file.
	var/list/log_lines = list()
	log_lines += "ack=[prefs.acknowledge_extreme_offsets ? "1" : "0"]"
	if(prefs.aggregate_extreme)
		log_lines += "agg=[prefs.aggregate_offset_budget_used]/[GLOB.extreme_aggregate_budget]"
	for(var/datum/customizer_entry/entry as anything in flagged_entries)
		var/emitted_sub_log = FALSE
		if(LAZYLEN(entry.sub_entries))
			for(var/i in 1 to length(entry.sub_entries))
				var/datum/customizer_sub_entry/sub = entry.sub_entries[i]
				if(!istype(sub) || !sub.is_hard_extreme)
					continue
				log_lines += "[entry.customizer_type]#[i](px=[sub.pixel_x],py=[sub.pixel_y],sc=[sub.scale],fl=[sub.extreme_flags])"
				emitted_sub_log = TRUE
		if(!emitted_sub_log)
			log_lines += "[entry.customizer_type](px=[entry.pixel_x],py=[entry.pixel_y],sc=[entry.scale],fl=[entry.extreme_flags])"
	log_admin("[key_name(H)] joined with extreme cosmetic offsets: [jointext(log_lines, "; ")]")

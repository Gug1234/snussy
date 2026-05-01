/*
 * stat_matrix.dm \u2014 Server-side stat contribution aggregator (Step 5).
 *
 * Builds a structured breakdown of where a character's stats come from
 * (statpack + job + species + age + virtue + vice), shaped for the TGUI
 * `StatMatrix` widget landing in Step 9. The client sums baseline + rows
 * to avoid a second server round-trip per stat-affecting edit.
 *
 * Contract (matches TECHNICAL_SPECIFICATION \u00a74.1):
 *   list(
 *     "order"    = list("statpack","job","species","age","virtue","vice"),
 *     "stats"    = MOBSTATS,      // STATKEY_STR \u2026 STATKEY_LCK
 *     "rows"     = list(
 *                    "statpack" = list(STATKEY_STR = +2, \u2026),
 *                    "virtue"   = list(STATKEY_WIL = +1, \u2026),
 *                    \u2026 (zero-filled rows permitted)
 *                  ),
 *     "baseline" = 10,            // STATBASELINE from mobs.dm; scrape defensively
 *     "ranges"   = list(          // optional: non-empty only when a
 *                    "statpack" = list(STATKEY_WIL = list(1, 3)) // statpack
 *                  )               // row has range-valued cells
 *   )
 *
 * Caching: result is memoized on `/datum/preferences/stat_matrix_cached`.
 * Invalidated by the Step 3 setter flag `invalidates_stat_matrix` via
 * `prefs_apply_set_pref` (wired in prefs_dirty_ledger.dm).
 *
 * Performance: aggregator cost is bounded by ~6 rows \u00d7 7 stats = 42 writes
 * per rebuild, plus 3\u20135 list lookups. Never hits disk. Safe to call from
 * `ui_data` on every snapshot \u2014 the cache fast-path returns the prior
 * assoc list without allocation.
 */

/**
 * Build (or return cached) stat matrix for this preferences datum.
 *
 * Arguments:
 *   force_rebuild \u2014 when TRUE, bypass the cache and recompute. Useful
 *                   for unit tests that want to pin a known state.
 * Returns:
 *   /list shaped per the contract above. Always safe to serialize.
 */
/datum/preferences/proc/build_stat_matrix(force_rebuild = FALSE)
	if(!force_rebuild && !stat_matrix_dirty && islist(stat_matrix_cached))
		return stat_matrix_cached
	var/list/order = list("statpack", "job", "species", "age", "virtue", "vice")
	var/list/stats = MOBSTATS
	var/list/rows = list()
	var/list/ranges = list()
	for(var/row_id in order)
		// Pre-seed zero-filled row so the client can render a full matrix
		// even when a contributor is unselected ("no hide" rule, \u00a710).
		var/list/row = list()
		for(var/stat_key in stats)
			row[stat_key] = 0
		rows[row_id] = row
	// statpack \u2014 stat_array may carry range values (list(min, max)). For
	// the matrix cell we emit the midpoint (rounded); the range tuple is
	// preserved in the side-channel `ranges[row][stat]` for tooltip copy.
	if(istype(statpack, /datum/statpack))
		var/list/row = rows["statpack"]
		for(var/stat_key in statpack.stat_array)
			var/raw = statpack.stat_array[stat_key]
			if(islist(raw))
				var/list/range = raw
				if(length(range) >= 2)
					row[stat_key] = round((range[1] + range[2]) / 2)
					if(!ranges["statpack"])
						ranges["statpack"] = list()
					ranges["statpack"][stat_key] = list(range[1], range[2])
				else if(length(range) == 1)
					row[stat_key] = range[1]
			else if(isnum(raw))
				row[stat_key] = raw
	// virtue + virtuetwo \u2014 additive into the same row so the UI shows a
	// single "virtue" column. If the design later wants them split, a
	// second row id "virtuetwo" can be appended to `order` without a
	// contract break.
	if(istype(virtue, /datum/virtue))
		var/list/row = rows["virtue"]
		for(var/stat_key in virtue.added_stats)
			var/val = virtue.added_stats[stat_key]
			if(isnum(val))
				row[stat_key] += val
	if(istype(virtuetwo, /datum/virtue))
		var/list/row = rows["virtue"]
		for(var/stat_key in virtuetwo.added_stats)
			var/val = virtuetwo.added_stats[stat_key]
			if(isnum(val))
				row[stat_key] += val
	// vice \u2014 /datum/charflaw instances on prefs apply stat changes via
	// runtime status effects, not a declarative field on the base datum.
	// Pre-spawn we cannot faithfully compute their contribution; leave
	// the row zero-filled and let the client render "\u2014" in those cells.
	// Species / job / age similarly have no universal declarative stat
	// field at the prefs layer (species stat mods live in on-body apply
	// hooks, job stat mods live in job datums' equip flow). Category
	// modules landing in Steps 10\u201313 can extend this proc to pull their
	// contributors in if they gain a declarative shape.
	var/list/out = list()
	out["order"] = order
	out["stats"] = stats
	out["rows"] = rows
	out["baseline"] = 10
	if(length(ranges))
		out["ranges"] = ranges
	stat_matrix_cached = out
	stat_matrix_dirty = FALSE
	return out

/**
 * Cheap invalidator. Callers (setter dispatch, slot load, etc.) flip
 * the dirty flag and null the cached list so the next `build_stat_matrix`
 * rebuilds from scratch.
 */
/datum/preferences/proc/invalidate_stat_matrix()
	stat_matrix_dirty = TRUE
	stat_matrix_cached = null

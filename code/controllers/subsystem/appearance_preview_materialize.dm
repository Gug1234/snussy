/**
 * appearance_preview_materialize.dm — Build-time headless materializer.
 *
 * Scope: WORLD-INIT ONLY. This file does not register a /datum/controller/subsystem
 * because the materialize work must complete BEFORE Master.Initialize would run
 * (no admins, no config, no ticker — just rustg iconforge). It is housed under
 * code/controllers/subsystem/ for discoverability because it is the DM-side
 * counterpart of a build stage.
 *
 * Invocation contract (from tools/build/appearance_preview/materialize.ts):
 *   dreamdaemon roguetown.dmb -close -trusted -verbose -params \
 *     "appearance_preview_materialize=1&appearance_preview_plan_dir=<dir>&appearance_preview_output_dir=<dir>"
 *
 * Where:
 *   - `appearance_preview_plan_dir` holds `iconforge_plan.json` + `manifest.json`
 *     (typically the orchestrator staging root).
 *   - `appearance_preview_output_dir` is where generated PNGs should land, keyed
 *     by each job's declared `outputPath`. Usually equal to the plan dir so the
 *     whole bundle lives together.
 *
 * On success writes `<output_dir>/materialize_status.json`:
 *   {"ok": true, "sheetCount": N, "elapsedMs": M}
 * On failure writes:
 *   {"ok": false, "error": "...", "stage": "..."}
 *
 * The JS caller reads the status file after dreamdaemon exits.
 */

/// Param name checked early in /world/New() to trigger the materialize path.
#define APPEARANCE_PREVIEW_MATERIALIZE_PARAM "appearance_preview_materialize"
#define APPEARANCE_PREVIEW_MATERIALIZE_PLAN_DIR_PARAM "appearance_preview_plan_dir"
#define APPEARANCE_PREVIEW_MATERIALIZE_OUTPUT_DIR_PARAM "appearance_preview_output_dir"
#define APPEARANCE_PREVIEW_MATERIALIZE_STATUS_FILENAME "materialize_status.json"

/**
 * Entry point invoked from /world/New() when the materialize param is set.
 * Returns TRUE on full success, FALSE on any failure. Always writes a status
 * JSON file into the output directory so the JS-side caller can read the
 * result without needing a meaningful process exit code.
 *
 * Arguments:
 *   plan_dir    — directory containing iconforge_plan.json + manifest.json.
 *   output_dir  — directory where generated PNGs are written (keyed by each
 *                 job's `outputPath`). Must exist.
 */
/proc/appearance_preview_materialize_run(plan_dir, output_dir)
	var/start_ms = world.time
	if(!istext(plan_dir) || !length(plan_dir))
		appearance_preview_materialize_write_status(output_dir, FALSE, "missing plan_dir param", "args", 0, 0)
		return FALSE
	if(!istext(output_dir) || !length(output_dir))
		appearance_preview_materialize_write_status(output_dir, FALSE, "missing output_dir param", "args", 0, 0)
		return FALSE

	// Normalize trailing slashes.
	if(copytext(plan_dir, length(plan_dir)) != "/")
		plan_dir = "[plan_dir]/"
	if(copytext(output_dir, length(output_dir)) != "/")
		output_dir = "[output_dir]/"

	var/plan_path = "[plan_dir]iconforge_plan.json"
	if(!fexists(plan_path))
		appearance_preview_materialize_write_status(output_dir, FALSE, "plan file missing at [plan_path]", "read_plan", 0, world.time - start_ms)
		return FALSE

	var/raw = rustg_file_read(plan_path)
	if(!istext(raw) || !length(raw))
		appearance_preview_materialize_write_status(output_dir, FALSE, "plan unreadable or empty", "read_plan", 0, world.time - start_ms)
		return FALSE

	var/list/plan
	try
		plan = json_decode(raw)
	catch
		appearance_preview_materialize_write_status(output_dir, FALSE, "plan json_decode failed", "parse_plan", 0, world.time - start_ms)
		return FALSE
	if(!islist(plan) || !islist(plan["jobs"]))
		appearance_preview_materialize_write_status(output_dir, FALSE, "plan has no jobs list", "parse_plan", 0, world.time - start_ms)
		return FALSE

	// iconforge scratch dir: generate PNGs here, then fcopy into output_dir
	// keyed by the job's declared outputPath. Keeping scratch separate means
	// partial failures leave no half-written files in the output tree.
	var/work_dir = "data/spritesheets/appearance_preview_materialize/"
	var/sheet_count = 0
	// Per-family iconforge position data, captured across all jobs so we
	// can rewrite the manifest once every sheet has been materialized.
	// Layout: family -> list("sprites" = <sprites map>, "tile" = list(w,h),
	// "sheet_id" = "family__0"). RustG iconforge packs sprites in an
	// arbitrary order and always emits a single-row sheet (per the
	// rustg_iconforge_generate docs in code/__DEFINES/rust_g.dm), so the
	// build-side planner cannot predict the real crop rects. The TS
	// bridge writes best-effort placeholder crops; this pass overwrites
	// them with iconforge's actual position data.
	var/list/materialized_by_family = list()
	for(var/list/job in plan["jobs"])
		var/name = job["spritesheetName"]
		var/list/sprites = job["sprites"]
		var/job_output_path = job["outputPath"]
		if(!istext(name) || !length(name) || !islist(sprites) || !istext(job_output_path) || !length(job_output_path))
			appearance_preview_materialize_write_status(output_dir, FALSE, "malformed job entry", "validate_job", sheet_count, world.time - start_ms)
			return FALSE

		var/sprites_json = json_encode(sprites)
		var/data_out = rustg_iconforge_generate(work_dir, name, sprites_json, FALSE, FALSE, TRUE)
		if(data_out == RUSTG_JOB_ERROR || !istext(data_out) || !length(data_out))
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge failed for '[name]': [data_out]", "iconforge_generate", sheet_count, world.time - start_ms)
			return FALSE
		var/list/iconforge_result
		try
			iconforge_result = json_decode(data_out)
		catch
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge result for '[name]' failed json_decode", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		if(!islist(iconforge_result))
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge result for '[name]' not a list", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/err_msg = iconforge_result["error"]
		if(istext(err_msg) && length(err_msg))
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge reported error for '[name]': [err_msg]", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/list/sizes = iconforge_result["sizes"]
		if(!islist(sizes) || length(sizes) != 1)
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge produced [sizes ? length(sizes) : 0] sizes for '[name]' (expected 1)", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/size_id = sizes[1]
		var/generated_path = "[work_dir][name]_[size_id].png"
		if(!fexists(generated_path))
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge output missing at '[generated_path]'", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE

		// Ensure any subdirectory prefix of outputPath exists under output_dir.
		// `outputPath` is a forward-slash relative path emitted by the TS plan
		// (e.g. "sheets/<family>__0.png"). fcopy() creates the destination
		// directory implicitly on recent BYOND, but we also guard via the
		// orchestrator creating `sheets/` during pack. No mkdir call here.
		var/dest_path = "[output_dir][job_output_path]"
		if(!fcopy(generated_path, dest_path))
			appearance_preview_materialize_write_status(output_dir, FALSE, "fcopy failed: '[generated_path]' -> '[dest_path]'", "fcopy", sheet_count, world.time - start_ms)
			return FALSE

		// Capture iconforge's real position data for the manifest rewrite
		// pass below. sprites_out shape (per rust_g.dm):
		//   list("<sprite_name>" = list("size_id" = "32x32", "position" = N), ...)
		var/list/sprites_out = iconforge_result["sprites"]
		if(!islist(sprites_out))
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge result for '[name]' missing sprites map", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/list/tile_dims = appearance_preview_materialize_parse_size(size_id)
		if(!islist(tile_dims))
			appearance_preview_materialize_write_status(output_dir, FALSE, "iconforge size_id '[size_id]' unparseable for '[name]'", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		materialized_by_family[name] = list(
			"sprites" = sprites_out,
			"tile_w" = tile_dims[1],
			"tile_h" = tile_dims[2],
			"output_path" = job_output_path,
		)
		sheet_count++

	// Rewrite manifest.json using iconforge's actual sprite positions.
	// This is the corrective pass that keeps the v2 manifest honest when
	// the TS bridge can only predict a layout that iconforge then ignores.
	var/manifest_path = "[plan_dir]manifest.json"
	var/output_manifest_path = "[output_dir]manifest.json"
	if(fexists(manifest_path))
		if(!appearance_preview_materialize_rewrite_manifest(manifest_path, output_manifest_path, materialized_by_family))
			appearance_preview_materialize_write_status(output_dir, FALSE, "manifest rewrite failed; crops would not match packed sheet", "rewrite_manifest", sheet_count, world.time - start_ms)
			return FALSE
	rustg_iconforge_cleanup()
	appearance_preview_materialize_write_status(output_dir, TRUE, null, null, sheet_count, world.time - start_ms)
	return TRUE

/**
 * Write the materialize status sidecar. Best-effort: if the output dir is
 * itself unwritable there is no recovery path — the JS side will see the
 * missing status file and treat it as a failure.
 */
/proc/appearance_preview_materialize_write_status(output_dir, ok, err_msg, stage, sheet_count, elapsed_ms)
	if(!istext(output_dir) || !length(output_dir))
		return
	if(copytext(output_dir, length(output_dir)) != "/")
		output_dir = "[output_dir]/"
	var/list/payload = list(
		"ok" = ok ? TRUE : FALSE,
		"sheetCount" = sheet_count,
		"elapsedMs" = elapsed_ms,
	)
	if(!ok)
		payload["error"] = istext(err_msg) ? err_msg : "unknown"
		payload["stage"] = istext(stage) ? stage : "unknown"
	var/status_path = "[output_dir][APPEARANCE_PREVIEW_MATERIALIZE_STATUS_FILENAME]"
	// Overwrite atomically via rustg_file_write which maps to an
	// atomic-rename on Windows; the JS caller reads after dreamdaemon exits,
	// so strict atomicity is not required here, but it is free.
	rustg_file_write(json_encode(payload), status_path)

/**
 * Parse a RustG iconforge size_id (e.g. "32x32") into list(width, height).
 * Returns null on any parse failure so callers can fail closed.
 */
/proc/appearance_preview_materialize_parse_size(size_id)
	if(!istext(size_id))
		return null
	var/sep = findtext(size_id, "x")
	if(!sep)
		return null
	var/w = text2num(copytext(size_id, 1, sep))
	var/h = text2num(copytext(size_id, sep + 1))
	if(!isnum(w) || !isnum(h) || w <= 0 || h <= 0)
		return null
	return list(w, h)

/**
 * Rewrite the build-time manifest using iconforge's actual sprite
 * positions. iconforge packs in an arbitrary order and always emits a
 * single row (see rustg_iconforge_generate in code/__DEFINES/rust_g.dm),
 * so the TS bridge's predicted crops are wrong by construction. We fix
 * them here, on the one process that actually knows the truth.
 *
 * Each entry in `materialized_by_family` looks like:
 *   list("sprites" = <iconforge sprites map>,
 *        "tile_w" = N, "tile_h" = N,
 *        "output_path" = "sheets/<family>__0.png")
 *
 * The iconforge sprites map uses keys of shape "<iconState>__<dir>"
 * (see spritesKey() in tools/build/appearance_preview/rustg_bridge.ts);
 * each entry carries a numeric `position`. Final crop for one tile is
 * (position * tile_w, 0, tile_w, tile_h).
 *
 * Returns TRUE on success, FALSE on any malformed input so the caller
 * can fail-closed before the asset datum ever mounts the drift.
 */
/proc/appearance_preview_materialize_rewrite_manifest(manifest_path, output_manifest_path, list/materialized_by_family)
	if(!istext(manifest_path) || !fexists(manifest_path))
		return FALSE
	var/raw = rustg_file_read(manifest_path)
	if(!istext(raw) || !length(raw))
		return FALSE
	var/list/manifest
	try
		manifest = json_decode(raw)
	catch
		return FALSE
	if(!islist(manifest))
		return FALSE
	var/list/sheets = manifest["sheets"]
	var/list/states = manifest["states"]
	if(!islist(sheets) || !islist(states))
		return FALSE

	// Walk each family's iconforge output, compute real crops, and patch
	// the relevant state + sheet records.
	for(var/family in materialized_by_family)
		var/list/mat = materialized_by_family[family]
		if(!islist(mat))
			return FALSE
		var/list/sprites = mat["sprites"]
		var/tile_w = mat["tile_w"]
		var/tile_h = mat["tile_h"]
		if(!islist(sprites) || !isnum(tile_w) || !isnum(tile_h))
			return FALSE

		// Find the sheet record for this family. The planner names it
		// "<family>__0" and stamps `family` into the record itself.
		var/sheet_id = null
		for(var/candidate_id in sheets)
			var/list/sheet = sheets[candidate_id]
			if(islist(sheet) && sheet["family"] == family)
				sheet_id = candidate_id
				break
		if(!sheet_id)
			return FALSE

		// Bucket positions by iconState so we can rewrite each state's
		// per-direction crop map in one go.
		var/list/positions_by_state = list()
		var/max_position = 0
		for(var/sprite_name in sprites)
			var/list/sprite_entry = sprites[sprite_name]
			if(!islist(sprite_entry))
				return FALSE
			var/position = sprite_entry["position"]
			if(!isnum(position) || position < 0)
				return FALSE
			if(position > max_position)
				max_position = position
			var/sep = findtext(sprite_name, "__")
			if(!sep)
				return FALSE
			var/icon_state = copytext(sprite_name, 1, sep)
			var/dir_key = copytext(sprite_name, sep + 2)
			if(!length(icon_state) || !length(dir_key))
				return FALSE
			var/list/per_state = positions_by_state[icon_state]
			if(!islist(per_state))
				per_state = list()
				positions_by_state[icon_state] = per_state
			per_state[dir_key] = position

		// Patch the sheet record: single row, width = (max_pos+1) * tile_w.
		var/list/sheet_rec = sheets[sheet_id]
		sheet_rec["width"] = (max_position + 1) * tile_w
		sheet_rec["height"] = tile_h
		sheet_rec["tileWidth"] = tile_w
		sheet_rec["tileHeight"] = tile_h

		// Patch every state record that belongs to this family. We
		// overwrite the entire crops map so stale per-direction entries
		// from the predicted layout cannot linger.
		for(var/icon_state in positions_by_state)
			var/list/state_rec = states[icon_state]
			if(!islist(state_rec))
				// iconforge returned a sprite the manifest didn't
				// declare — treat as drift, fail closed.
				return FALSE
			var/list/per_state = positions_by_state[icon_state]
			var/list/new_crops = list()
			for(var/dir_key in per_state)
				var/position = per_state[dir_key]
				new_crops[dir_key] = list(
					"x" = position * tile_w,
					"y" = 0,
					"width" = tile_w,
					"height" = tile_h,
				)
			state_rec["crops"] = new_crops

	// Emit the corrected manifest. We write to the plan_dir copy (the
	// source of truth for subsequent materialize runs) AND the output_dir
	// copy (where the build target declares manifest.json as its output).
	// Both must stay in sync so future input-hash short-circuits see the
	// real crops, not the predicted ones. Matches the convention used by
	// every other rustg_file_write caller in the tree: treat as void and
	// trust the write; failure shows up as missing/corrupted JSON on read.
	var/encoded = json_encode(manifest)
	rustg_file_write(encoded, manifest_path)
	if(output_manifest_path != manifest_path)
		rustg_file_write(encoded, output_manifest_path)
	return TRUE

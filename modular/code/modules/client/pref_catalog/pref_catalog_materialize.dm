/**
 * pref_catalog_materialize.dm — Phase 2: iconforge bake of the catalog plan.
 *
 * Reads a plan emitted by `pref_catalog_emit_plan` (see _pref_catalog.dm),
 * runs `rustg_iconforge_generate` once per `kind=="catalog"` job, copies each
 * generated PNG to the configured output directory, and writes a manifest
 * describing the real per-accessory crop rects so the TGUI side can address
 * sprites by safe key without having to know iconforge's pack order.
 *
 * Mirrors the structure of `appearance_preview_materialize.dm` but is its
 * own pipeline: the input plan is produced in-process by DM (no TS bridge),
 * and the manifest schema is shaped for the AccessoryPicker rather than the
 * preview-render asset datums.
 *
 * Output files (under `<output_dir>`):
 *   - sheets/<spritesheetName>.png  (one per catalog job)
 *   - manifest.json                 (schema below)
 *   - materialize_status.json       (ok/error sidecar; matches the
 *                                    preview-materializer's convention)
 *
 * manifest.json schema (v2):
 *   {
 *     "version": 2,
 *     "speciesTargets": [...],          // copied from plan
 *     "sheets": {
 *       "<spritesheetName>": {
 *         "displayName": "Wings",
 *         "customizerChoiceType": "/datum/customizer_choice/...",
 *         "allowsAccessoryColorCustomization": true,
 *         "variants": {
 *           "32x32": {
 *             "outputPath": "sheets/<name>__32x32.png",
 *             "tileWidth": 32, "tileHeight": 32,
 *             "sheetWidth": 320, "sheetHeight": 32,
 *             "entries": {
 *               "<safe_accessory_name>": {"x": N, "y": 0, "width": 32, "height": 32}
 *             }
 *           },
 *           "32x48": { ... }
 *         }
 *       }
 *     }
 *   }
 *
 * A single customizer choice can mix tile sizes (e.g. some horns are 32x32,
 * some 32x48). We emit one PNG + manifest entry per size variant; the picker
 * renders each accessory at its native tile size. Non-canonical sizes
 * (anything outside {32,48,64} for W or H, like authoring mistakes such as
 * 45x34 or 96x34) are dropped with a stack_trace so content owners can fix
 * the source DMI.
 *
 * Returns TRUE on full success, FALSE on any failure. Always writes a status
 * sidecar so an external caller (build hook or admin verb) can read the
 * outcome without parsing logs.
 */

#define PREF_CATALOG_MATERIALIZE_STATUS_FILENAME "materialize_status.json"
#define PREF_CATALOG_MATERIALIZE_MANIFEST_FILENAME "manifest.json"

/proc/pref_catalog_materialize_run(plan_path, output_dir)
	var/start_ms = world.time
	if(!istext(plan_path) || !length(plan_path))
		pref_catalog_materialize_write_status(output_dir, FALSE, "missing plan_path", "args", 0, 0)
		return FALSE
	if(!istext(output_dir) || !length(output_dir))
		pref_catalog_materialize_write_status(output_dir, FALSE, "missing output_dir", "args", 0, 0)
		return FALSE
	if(copytext(output_dir, length(output_dir)) != "/")
		output_dir = "[output_dir]/"

	if(!fexists(plan_path))
		pref_catalog_materialize_write_status(output_dir, FALSE, "plan file missing at [plan_path]", "read_plan", 0, world.time - start_ms)
		return FALSE
	var/raw = rustg_file_read(plan_path)
	if(!istext(raw) || !length(raw))
		pref_catalog_materialize_write_status(output_dir, FALSE, "plan unreadable or empty", "read_plan", 0, world.time - start_ms)
		return FALSE
	var/list/plan
	try
		plan = json_decode(raw)
	catch
		pref_catalog_materialize_write_status(output_dir, FALSE, "plan json_decode failed", "parse_plan", 0, world.time - start_ms)
		return FALSE
	if(!islist(plan) || !islist(plan["jobs"]))
		pref_catalog_materialize_write_status(output_dir, FALSE, "plan has no jobs list", "parse_plan", 0, world.time - start_ms)
		return FALSE

	// Shared scratch dir; iconforge writes <name>_<size>.png here, then we
	// fcopy to output_dir/sheets/<name>.png. Keeping scratch separate means a
	// failure halfway through leaves no half-baked files in the output tree.
	var/work_dir = "data/spritesheets/pref_catalog_materialize/"
	// rustg_iconforge_generate does NOT create the parent directory; it just
	// fails silently (returns success but writes no PNG) if work_dir is
	// missing. rustg_file_write DOES create parents, so we use it to seed a
	// .keep sentinel and ensure the dir exists before the loop. Same idea
	// for output_dir + the sheets/ subdir we'll fcopy into below.
	rustg_file_write("", "[work_dir].keep")
	rustg_file_write("", "[output_dir]sheets/.keep")

	var/list/manifest = list(
		"version" = 2,
		"speciesTargets" = islist(plan["speciesTargets"]) ? plan["speciesTargets"] : list(),
		"sheets" = list(),
	)
	var/list/manifest_sheets = manifest["sheets"]
	var/sheet_count = 0

	for(var/list/job in plan["jobs"])
		if(job["kind"] != "catalog")
			// Future-proof: ignore any non-catalog job kinds the enumerator
			// might add later (e.g. composite previews) without failing.
			continue
		var/sheet_name = job["spritesheetName"]
		var/list/sprites = job["sprites"]
		var/job_output_path = job["outputPath"]
		if(!istext(sheet_name) || !length(sheet_name) || !islist(sprites) || !istext(job_output_path) || !length(job_output_path))
			pref_catalog_materialize_write_status(output_dir, FALSE, "malformed job entry", "validate_job", sheet_count, world.time - start_ms)
			return FALSE

		// `outputPath` in the plan is repo-rooted (e.g. "pref_catalog/sheets/foo.png").
		// In the manifest we store the path RELATIVE to output_dir, so the
		// SSassets registrar can resolve filenames without re-encoding the
		// pref_catalog/ prefix. Strip the leading "pref_catalog/" if present.
		var/manifest_relpath = job_output_path
		if(copytext(manifest_relpath, 1, length("pref_catalog/") + 1) == "pref_catalog/")
			manifest_relpath = copytext(manifest_relpath, length("pref_catalog/") + 1)

		var/sprites_json = json_encode(sprites)
		var/data_out = rustg_iconforge_generate(work_dir, sheet_name, sprites_json, FALSE, FALSE, TRUE)
		if(data_out == RUSTG_JOB_ERROR || !istext(data_out) || !length(data_out))
			pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge failed for '[sheet_name]': [data_out]", "iconforge_generate", sheet_count, world.time - start_ms)
			return FALSE
		var/list/iconforge_result
		try
			iconforge_result = json_decode(data_out)
		catch
			pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge result for '[sheet_name]' failed json_decode", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		if(!islist(iconforge_result))
			pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge result for '[sheet_name]' not a list", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/err_msg = iconforge_result["error"]
		if(istext(err_msg) && length(err_msg))
			pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge reported error for '[sheet_name]': [err_msg]", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/list/sizes = iconforge_result["sizes"]
		if(!islist(sizes) || !length(sizes))
			pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge produced no sizes for '[sheet_name]'", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE
		var/list/sprites_out = iconforge_result["sprites"]
		if(!islist(sprites_out))
			pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge result for '[sheet_name]' missing sprites map", "iconforge_result", sheet_count, world.time - start_ms)
			return FALSE

		// Multi-size handling: a single customizer choice can pull accessories
		// from DMIs with different tile sizes. We emit one PNG + manifest
		// variant per canonical size present, and drop sprites authored at
		// non-canonical sizes (e.g. 45x34) with a stack_trace so the content
		// owner can fix the source DMI. Canonical sizes are W,H ∈ {32,48,64}.
		var/list/sizes_kept = list()
		var/list/sizes_dropped = list()
		for(var/sid in sizes)
			var/list/dims = pref_catalog_materialize_parse_size(sid)
			if(islist(dims) && pref_catalog_materialize_is_canonical_size(dims[1], dims[2]))
				sizes_kept += sid
			else
				sizes_dropped += sid
		if(length(sizes_dropped))
			stack_trace("pref_catalog_materialize: '[sheet_name]' dropping non-canonical sizes ([sizes_dropped.Join(", ")]); kept ([sizes_kept.Join(", ") || "none"]).")
		if(!length(sizes_kept))
			stack_trace("pref_catalog_materialize: skipping '[sheet_name]' — no canonical sizes (got [sizes.Join(", ")]). Fix the source DMI tile sizes.")
			continue

		// Group sprites by size_id so we can build one manifest variant per
		// kept size. Sprites at dropped sizes are skipped with a stack_trace.
		var/list/by_size = list()
		for(var/sprite_key in sprites_out)
			var/list/sprite_entry = sprites_out[sprite_key]
			if(!islist(sprite_entry))
				pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge sprite entry '[sprite_key]' for '[sheet_name]' not a list", "iconforge_result", sheet_count, world.time - start_ms)
				return FALSE
			var/sid = sprite_entry["size_id"]
			if(!(sid in sizes_kept))
				stack_trace("pref_catalog_materialize: dropping '[sprite_key]' from '[sheet_name]' (non-canonical size '[sid]').")
				continue
			var/position = sprite_entry["position"]
			if(!isnum(position) || position < 0)
				pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge sprite '[sprite_key]' for '[sheet_name]' has invalid position", "iconforge_result", sheet_count, world.time - start_ms)
				return FALSE
			var/list/bucket = by_size[sid]
			if(!islist(bucket))
				bucket = list()
				by_size[sid] = bucket
			bucket[sprite_key] = position

		// Strip any "<sheet_name>.png" prefix off the manifest_relpath; we
		// emit per-variant filenames so the .png on the end is replaced with
		// "__<size_id>.png". Manifest_relpath was originally e.g.
		// "sheets/customizer_choice_foo.png" — split off the .png.
		var/relpath_base = manifest_relpath
		if(length(relpath_base) > 4 && copytext(relpath_base, length(relpath_base) - 3) == ".png")
			relpath_base = copytext(relpath_base, 1, length(relpath_base) - 3)

		var/list/variants = list()
		for(var/sid in sizes_kept)
			var/list/bucket = by_size[sid]
			if(!islist(bucket) || !length(bucket))
				// Iconforge listed the size but no kept sprite landed there
				// (shouldn't normally happen, but possible if every sprite at
				// that size dropped for another reason). Skip with a trace.
				stack_trace("pref_catalog_materialize: '[sheet_name]' size '[sid]' has no kept sprites; skipping variant.")
				continue
			var/generated_path = "[work_dir][sheet_name]_[sid].png"
			if(!fexists(generated_path))
				pref_catalog_materialize_write_status(output_dir, FALSE, "iconforge output missing at '[generated_path]'", "iconforge_result", sheet_count, world.time - start_ms)
				return FALSE
			var/variant_relpath = "[relpath_base]__[sid].png"
			var/dest_path = "[output_dir][variant_relpath]"
			if(!fcopy(generated_path, dest_path))
				pref_catalog_materialize_write_status(output_dir, FALSE, "fcopy failed: '[generated_path]' -> '[dest_path]'", "fcopy", sheet_count, world.time - start_ms)
				return FALSE
			var/list/dims = pref_catalog_materialize_parse_size(sid)
			var/tile_w = dims[1]
			var/tile_h = dims[2]
			var/list/entries = list()
			var/max_position = 0
			for(var/sprite_key in bucket)
				var/position = bucket[sprite_key]
				if(position > max_position)
					max_position = position
				entries[sprite_key] = list(
					"x" = position * tile_w,
					"y" = 0,
					"width" = tile_w,
					"height" = tile_h,
				)
			variants[sid] = list(
				"outputPath" = variant_relpath,
				"tileWidth" = tile_w,
				"tileHeight" = tile_h,
				"sheetWidth" = (max_position + 1) * tile_w,
				"sheetHeight" = tile_h,
				"entries" = entries,
			)

		if(!length(variants))
			stack_trace("pref_catalog_materialize: skipping '[sheet_name]' — no canonical variants emitted.")
			continue

		manifest_sheets[sheet_name] = list(
			"displayName" = job["displayName"],
			"customizerChoiceType" = job["customizerChoiceType"],
			"allowsAccessoryColorCustomization" = job["allowsAccessoryColorCustomization"] ? TRUE : FALSE,
			"variants" = variants,
		)
		sheet_count++

	// Write the manifest before status; if the manifest write fails, the
	// status sidecar will still report the error and the AccessoryPicker
	// will refuse to mount on a missing manifest rather than serve stale data.
	var/manifest_path = "[output_dir][PREF_CATALOG_MATERIALIZE_MANIFEST_FILENAME]"
	rustg_file_write(json_encode(manifest), manifest_path)

	rustg_iconforge_cleanup()
	pref_catalog_materialize_write_status(output_dir, TRUE, null, null, sheet_count, world.time - start_ms)
	return TRUE

/proc/pref_catalog_materialize_write_status(output_dir, ok, err_msg, stage, sheet_count, elapsed_ms)
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
	var/status_path = "[output_dir][PREF_CATALOG_MATERIALIZE_STATUS_FILENAME]"
	rustg_file_write(json_encode(payload), status_path)

/proc/pref_catalog_materialize_parse_size(size_id)
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

/// Returns TRUE for tile sizes we treat as canonical for the picker.
/// We accept any combination of {32, 48, 64} on each axis (32x32, 32x48,
/// 32x64, 48x32, 48x48, 48x64, 64x32, 64x48, 64x64). Anything else is an
/// authoring mistake (e.g. 45x34, 96x34) and gets dropped with a stack_trace.
/proc/pref_catalog_materialize_is_canonical_size(w, h)
	if(!isnum(w) || !isnum(h))
		return FALSE
	var/static/list/canonical = list(32, 48, 64)
	return (w in canonical) && (h in canonical)

/// Choose a single dominant size_id when iconforge produces a multi-size
/// spritesheet. We pick the size that the most sprites use; ties are broken
/// by the order iconforge listed the sizes (declaration order, stable).
/// Returns null if no sprite carries a recognizable size_id.
/proc/pref_catalog_materialize_pick_dominant_size(list/sprites_out, list/sizes)
	if(!islist(sprites_out) || !length(sprites_out))
		return null
	if(islist(sizes) && length(sizes) == 1)
		return sizes[1]
	var/list/counts = list()
	for(var/sprite_key in sprites_out)
		var/list/sprite_entry = sprites_out[sprite_key]
		if(!islist(sprite_entry))
			continue
		var/sid = sprite_entry["size_id"]
		if(!istext(sid) || !length(sid))
			continue
		counts[sid] = (counts[sid] || 0) + 1
	if(!length(counts))
		return null
	var/best_sid
	var/best_count = -1
	// Iterate in `sizes` order so iconforge's declaration order breaks ties.
	if(islist(sizes))
		for(var/sid in sizes)
			var/c = counts[sid]
			if(isnum(c) && c > best_count)
				best_count = c
				best_sid = sid
	// Fallback: if `sizes` was missing or didn't cover the seen sids, pick
	// from `counts` directly. Order here is associative-list iteration order.
	if(!best_sid)
		for(var/sid in counts)
			var/c = counts[sid]
			if(c > best_count)
				best_count = c
				best_sid = sid
	return best_sid

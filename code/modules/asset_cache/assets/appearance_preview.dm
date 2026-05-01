/**
 * appearance_preview asset — serves the v2 sheet-backed preview bundle.
 *
 * The RustG/iconforge build pipeline (Step 5/6) publishes two artifacts to
 * `tgui/public/appearance_preview/`:
 *   - `manifest.json` — the v2 manifest the TGUI runtime consumes.
 *   - `iconforge_plan.json` — a deterministic work plan the DM side runs
 *     through `rustg_iconforge_generate` to produce the actual sheet PNGs
 *     at world boot (iconforge is a DM library call, so PNG bytes do not
 *     exist on disk until this runs).
 *
 * Load-time contract (fail-closed):
 *   1. Validate the manifest against the v2 envelope. On any mismatch we
 *      register NO assets so the client sees "bundle unavailable" rather
 *      than a stale v1 bundle or a truncated v2 bundle.
 *   2. Read the iconforge plan and, for each job, invoke
 *      `rustg_iconforge_generate` to emit the sheet PNG.
 *   3. Register the validated manifest and every successfully generated
 *      sheet under the paths declared in the manifest.
 *   4. On any failure during generation, wipe the partial asset list and
 *      abort — we never serve a half-populated bundle.
 */
/datum/asset/simple/appearance_preview
	// keep_local_name is intentionally FALSE: the asset keys contain slashes
	// (`appearance_preview/manifest.json`, `appearance_preview/sheets/<sheet>.png`)
	// and BYOND's browse_rsc transport cannot serve a file whose name contains
	// a slash -- the client would request `appearance_preview%2fmanifest.json`
	// and 404. With keep_local_name off, the transport rewrites the wire name
	// to `asset.<hash>.<ext>` and the TGUI side resolves it via the asset
	// mapping, so the slash-bearing keys stay usable as dictionary lookups
	// without ever appearing in a URL.
	cross_round_cachable = FALSE
	/// Last failure reason recorded by `mount_bundle`, or null if the most
	/// recent mount attempt succeeded. Consumed by the admin rebuild verb
	/// (see `modular/code/modules/client/appearance_preview/appearance_preview_admin.dm`)
	/// so operators get a readable reason without grepping the server log.
	var/last_mount_failure_reason

/datum/asset/simple/appearance_preview/New()
	assets = list()
	mount_bundle()
	..()

/// Record a failure reason, emit the canonical log line, and return FALSE.
/// Centralizing this keeps every failure branch in `mount_bundle` consistent
/// and guarantees the admin-visible reason string matches the server log.
/datum/asset/simple/appearance_preview/proc/_fail_mount(reason)
	last_mount_failure_reason = reason
	log_world("appearance_preview: [reason]")
	return FALSE

/// Attempts to mount the published v2 bundle. Registers entries into
/// `assets` on success; leaves `assets` empty on any failure.
///
/// `root_override` and `allow_fallback_override` are test seams (see the
/// `appearance_preview_mount_bundle_fallback` / `appearance_preview_admin_rebuild`
/// unit tests). Production callers pass no arguments — the default root
/// is the published bundle under `tgui/public/appearance_preview` and the
/// fallback flag is read from `world.params`. When overrides are supplied
/// they bypass those defaults so tests can point at fixture dirs and
/// force the fail-closed vs. boot-fallback branches deterministically.
/datum/asset/simple/appearance_preview/proc/mount_bundle(root_override = null, allow_fallback_override = null)
	last_mount_failure_reason = null
	var/root = istext(root_override) && length(root_override) ? root_override : "tgui/public/appearance_preview"
	var/manifest_path = "[root]/manifest.json"
	var/plan_path = "[root]/iconforge_plan.json"

	var/list/manifest = appearance_preview_load_and_validate_manifest(manifest_path)
	if(!islist(manifest))
		return _fail_mount("manifest missing or failed v2 validation; refusing to mount bundle")

	if(!fexists(plan_path))
		return _fail_mount("iconforge_plan.json missing; refusing to mount bundle")
	var/plan_raw = rustg_file_read(plan_path)
	if(!istext(plan_raw) || !length(plan_raw) || !rustg_json_is_valid(plan_raw))
		return _fail_mount("iconforge_plan.json unreadable or malformed; refusing to mount bundle")
	var/list/plan
	try
		plan = json_decode(plan_raw)
	catch
		return _fail_mount("iconforge_plan.json json_decode failed; refusing to mount bundle")
	if(!islist(plan) || !islist(plan["jobs"]))
		return _fail_mount("iconforge_plan.json has no jobs list; refusing to mount bundle")

	// Index manifest sheet records by family so we can map job output to
	// the declared sheet path. v2 invariant: one sheet per family.
	// These keys mirror APPEARANCE_PREVIEW_MANIFEST_KEY_* / APPEARANCE_PREVIEW_SHEET_KEY_*
	// in modular/code/datums/appearance_preview/_defines.dm. They are inlined here
	// because this asset is included earlier in the DME than _defines.dm, so the
	// preprocessor has not seen those defines yet at this point. If those defines
	// ever change, update the inlined strings in lockstep.
	var/list/manifest_sheets = manifest["sheets"]
	if(!islist(manifest_sheets))
		log_world("appearance_preview: manifest sheets block missing; refusing to mount bundle")
		return FALSE
	var/list/sheets_by_family = list()
	for(var/sheet_id in manifest_sheets)
		var/list/sheet = manifest_sheets[sheet_id]
		if(!islist(sheet))
			log_world("appearance_preview: manifest sheet '[sheet_id]' is not a list; refusing to mount bundle")
			return FALSE
		var/family = sheet["family"]
		if(!istext(family) || !length(family))
			log_world("appearance_preview: manifest sheet '[sheet_id]' missing family; refusing to mount bundle")
			return FALSE
		sheets_by_family[family] = sheet

	// Accumulate into a staging list; only promote to `assets` after every
	// job succeeds. This keeps the fail-closed contract intact: a failure
	// halfway through generation must not leak a half-mounted bundle.
	var/list/staged_assets = list()
	staged_assets["appearance_preview/manifest.json"] = file(manifest_path)

	// Remediation Step 6: validate every job + try the prebuilt path first.
	// On a normal production boot the build pipeline's materialize stage has
	// already published PNGs into `<root>/<outputPath>`; in that case we
	// never invoke `rustg_iconforge_generate` at world init. The iconforge
	// path is kept as a fallback ONLY when boot-fallback is explicitly
	// allowed via `world.params["allow_appearance_preview_boot_fallback"]`.
	var/list/validated_jobs = list()
	var/prebuilt_complete = TRUE
	for(var/list/job in plan["jobs"])
		var/job_name = job["spritesheetName"]
		var/list/job_sprites = job["sprites"]
		if(!istext(job_name) || !length(job_name) || !islist(job_sprites))
			log_world("appearance_preview: malformed iconforge job; refusing to mount bundle")
			return FALSE
		var/list/job_sheet = sheets_by_family[job_name]
		if(!islist(job_sheet))
			log_world("appearance_preview: job family '[job_name]' not present in manifest sheets; refusing to mount bundle")
			return FALSE
		var/job_sheet_path = job_sheet["path"]
		if(!istext(job_sheet_path) || !length(job_sheet_path))
			log_world("appearance_preview: sheet for family '[job_name]' missing path; refusing to mount bundle")
			return FALSE
		var/job_output_path = job["outputPath"]
		if(!istext(job_output_path) || !length(job_output_path))
			log_world("appearance_preview: plan job '[job_name]' missing outputPath; refusing to mount bundle")
			return FALSE
		if(job_output_path != job_sheet_path)
			log_world("appearance_preview: plan/manifest drift for family '[job_name]': plan.outputPath='[job_output_path]' manifest.sheet.path='[job_sheet_path]'; refusing to mount bundle")
			return FALSE
		var/job_hash_icons = job["hashIcons"]
		if(!(job_hash_icons == TRUE || job_hash_icons == FALSE || job_hash_icons == "true" || job_hash_icons == "false"))
			log_world("appearance_preview: plan job '[job_name]' has non-boolean hashIcons '[job_hash_icons]'; refusing to mount bundle")
			return FALSE
		var/prebuilt_path = "[root]/[job_output_path]"
		var/prebuilt_exists = fexists(prebuilt_path)
		if(!prebuilt_exists)
			prebuilt_complete = FALSE
		validated_jobs += list(list(
			"name" = job_name,
			"sprites" = job_sprites,
			"output_path" = job_output_path,
			"prebuilt_path" = prebuilt_path,
			"prebuilt_exists" = prebuilt_exists,
		))

	if(prebuilt_complete)
		// Happy path: materialize stage already published every PNG. Skip
		// iconforge entirely and register the existing files.
		for(var/list/vj in validated_jobs)
			staged_assets["appearance_preview/[vj["output_path"]]"] = file(vj["prebuilt_path"])
		assets = staged_assets
		log_world("appearance_preview: mounted prebuilt bundle ([length(validated_jobs)] sheets) without invoking iconforge")
		return TRUE

	// Prebuilt path failed — at least one sheet PNG is missing. Only fall
	// back to runtime iconforge generation when explicitly permitted; the
	// production default is to fail closed so a stale/partial bundle can
	// never silently serve placeholder art.
	var/allow_fallback
	if(!isnull(allow_fallback_override))
		allow_fallback = allow_fallback_override
	else
		allow_fallback = world.params["allow_appearance_preview_boot_fallback"]
	if(!allow_fallback)
		var/missing_count = 0
		for(var/list/vj in validated_jobs)
			if(!vj["prebuilt_exists"])
				missing_count++
		return _fail_mount("[missing_count]/[length(validated_jobs)] prebuilt sheets missing; `allow_appearance_preview_boot_fallback` not set — refusing to mount bundle (run the materialize build stage or pass the fallback param to boot with iconforge)")

	log_world("appearance_preview: WARNING prebuilt sheets missing; falling back to boot-time iconforge generation because `allow_appearance_preview_boot_fallback` is set")

	var/work_dir = "data/spritesheets/appearance_preview/"
	for(var/list/job in plan["jobs"])
		var/spritesheet_name = job["spritesheetName"]
		var/list/sprites = job["sprites"]
		if(!istext(spritesheet_name) || !length(spritesheet_name) || !islist(sprites))
			log_world("appearance_preview: malformed iconforge job; refusing to mount bundle")
			return FALSE
		var/list/sheet = sheets_by_family[spritesheet_name]
		if(!islist(sheet))
			log_world("appearance_preview: job family '[spritesheet_name]' not present in manifest sheets; refusing to mount bundle")
			return FALSE
		var/sheet_path = sheet["path"]
		if(!istext(sheet_path) || !length(sheet_path))
			log_world("appearance_preview: sheet for family '[spritesheet_name]' missing path; refusing to mount bundle")
			return FALSE

		// Remediation Step 5: the plan's `outputPath` and `hashIcons` fields
		// are load-bearing — the DM runtime consumes them instead of re-
		// deriving from convention. `outputPath` MUST match the manifest
		// sheet record's `path` for the same family; any drift indicates a
		// stale plan/manifest pair (e.g. a partial rebuild or a tampered
		// staging root) and is fail-closed. `hashIcons` is validated as a
		// boolean so Step 6's materialize stage can forward it verbatim to
		// `rustg_iconforge_generate` without a second type-check.
		var/plan_output_path = job["outputPath"]
		if(!istext(plan_output_path) || !length(plan_output_path))
			log_world("appearance_preview: plan job '[spritesheet_name]' missing outputPath; refusing to mount bundle")
			return FALSE
		if(plan_output_path != sheet_path)
			log_world("appearance_preview: plan/manifest drift for family '[spritesheet_name]': plan.outputPath='[plan_output_path]' manifest.sheet.path='[sheet_path]'; refusing to mount bundle")
			return FALSE
		var/plan_hash_icons = job["hashIcons"]
		// BYOND decodes JSON true/false as the numeric literals 1 / 0, so
		// accept both TRUE/FALSE (num) and the bare "true"/"false" text
		// forms a future adapter might emit. Anything else is drift.
		if(!(plan_hash_icons == TRUE || plan_hash_icons == FALSE || plan_hash_icons == "true" || plan_hash_icons == "false"))
			log_world("appearance_preview: plan job '[spritesheet_name]' has non-boolean hashIcons '[plan_hash_icons]'; refusing to mount bundle")
			return FALSE

		var/sprites_json = json_encode(sprites)
		var/data_out = rustg_iconforge_generate(work_dir, spritesheet_name, sprites_json, FALSE, FALSE, TRUE)
		if(data_out == RUSTG_JOB_ERROR || !istext(data_out) || !findtext(data_out, "{", 1, 2))
			log_world("appearance_preview: iconforge generate failed for '[spritesheet_name]': [data_out]")
			return FALSE
		var/list/iconforge_result
		try
			iconforge_result = json_decode(data_out)
		catch
			log_world("appearance_preview: iconforge result for '[spritesheet_name]' failed json_decode")
			return FALSE
		if(!islist(iconforge_result))
			log_world("appearance_preview: iconforge result for '[spritesheet_name]' not a list")
			return FALSE
		var/error_string = iconforge_result["error"]
		if(istext(error_string) && length(error_string))
			log_world("appearance_preview: iconforge reported error for '[spritesheet_name]': [error_string]")
			return FALSE
		var/list/sizes = iconforge_result["sizes"]
		if(!islist(sizes) || !length(sizes))
			log_world("appearance_preview: iconforge returned no sizes for '[spritesheet_name]'; refusing to mount bundle")
			return FALSE
		// v2 invariant: every tile in a family shares one size, so the
		// generated PNG set is exactly one file.
		if(length(sizes) != 1)
			log_world("appearance_preview: iconforge produced [length(sizes)] sizes for '[spritesheet_name]' (expected 1); refusing to mount bundle")
			return FALSE
		var/size_id = sizes[1]
		var/generated_path = "[work_dir][spritesheet_name]_[size_id].png"
		if(!fexists(generated_path))
			log_world("appearance_preview: iconforge output missing at '[generated_path]'; refusing to mount bundle")
			return FALSE

		// Register the generated asset under the plan-declared output path.
		// Validated above to equal the manifest sheet path, so the public
		// asset key `appearance_preview/<outputPath>` is what the TGUI
		// renderer already expects from its manifest consumption.
		staged_assets["appearance_preview/[plan_output_path]"] = fcopy_rsc(generated_path)

	// All jobs succeeded — promote the staged map into the live assets list.
	assets = staged_assets
	// Free iconforge's in-memory DMI cache now that every sheet is materialized.
	rustg_iconforge_cleanup()
	return TRUE

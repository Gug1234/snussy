/**
 * pref_catalog asset — serves the pre-baked customizer-choice catalog.
 *
 * The DM-side materializer (see `pref_catalog_materialize.dm`) writes a
 * manifest + per-variant PNGs into `data/pref_catalog/` at admin/build time.
 * This asset datum mounts that bundle into SSassets so the TGUI side can
 * resolve sheet URLs via `resolveAsset(...)` and render thumbnails through
 * the existing `<SheetPreviewTile>` widget.
 *
 * Asset key naming:
 *   - "pref_catalog/manifest.json"
 *   - "pref_catalog/<sheets/...>/<sheetName>__<WxH>.png"
 *     (paths come straight from the manifest's `variants[<size>].outputPath`)
 *
 * Mount semantics:
 *   - We register what's on disk. If `data/pref_catalog/manifest.json` is
 *     missing, we register nothing (fail-soft) and log; the TGUI side will
 *     see an empty manifest and the picker falls back to a name-only list.
 *   - Per-variant PNG misses are logged + skipped individually rather than
 *     aborting the whole mount, since the materializer can drop entries
 *     for content reasons (non-canonical sizes) and we still want the
 *     remaining sheets usable.
 */
/datum/asset/simple/pref_catalog
	cross_round_cachable = FALSE
	/// Last failure reason from `mount_bundle`, or null on success. Useful
	/// for the rebuild verb to surface a readable reason without log diving.
	var/last_mount_failure_reason

/datum/asset/simple/pref_catalog/New()
	assets = list()
	mount_bundle()
	..()

/datum/asset/simple/pref_catalog/proc/_fail_mount(reason)
	last_mount_failure_reason = reason
	log_world("pref_catalog_asset: [reason]")
	return FALSE

/// Walks `data/pref_catalog/manifest.json` and registers every existing
/// variant PNG plus the manifest itself. Returns TRUE on success, FALSE if
/// the manifest could not be read/validated. Per-variant misses are logged
/// and skipped — they do not fail the whole mount.
/datum/asset/simple/pref_catalog/proc/mount_bundle(root_override = null)
	last_mount_failure_reason = null
	var/root = istext(root_override) && length(root_override) ? root_override : "data/pref_catalog"
	var/manifest_path = "[root]/manifest.json"
	if(!fexists(manifest_path))
		return _fail_mount("manifest missing at '[manifest_path]'; no pref_catalog assets registered")
	var/raw = rustg_file_read(manifest_path)
	if(!istext(raw) || !length(raw))
		return _fail_mount("manifest unreadable at '[manifest_path]'")
	var/list/manifest
	try
		manifest = json_decode(raw)
	catch
		return _fail_mount("manifest json_decode failed at '[manifest_path]'")
	if(!islist(manifest) || !islist(manifest["sheets"]))
		return _fail_mount("manifest at '[manifest_path]' has no 'sheets' map")

	var/list/staged = list()
	staged["pref_catalog/manifest.json"] = file(manifest_path)

	var/registered = 0
	var/skipped = 0
	for(var/sheet_name in manifest["sheets"])
		var/list/sheet = manifest["sheets"][sheet_name]
		if(!islist(sheet))
			skipped++
			continue
		var/list/variants = sheet["variants"]
		if(!islist(variants))
			skipped++
			continue
		for(var/size_id in variants)
			var/list/variant = variants[size_id]
			if(!islist(variant))
				skipped++
				continue
			var/relpath = variant["outputPath"]
			if(!istext(relpath) || !length(relpath))
				skipped++
				continue
			var/disk_path = "[root]/[relpath]"
			if(!fexists(disk_path))
				log_world("pref_catalog_asset: variant PNG missing at '[disk_path]' (sheet '[sheet_name]', size '[size_id]'); skipping")
				skipped++
				continue
			staged["pref_catalog/[relpath]"] = file(disk_path)
			registered++

	assets = staged
	log_world("pref_catalog_asset: mounted [registered] variant PNG(s) from '[root]' ([skipped] skipped)")
	return TRUE

/// Load + decode the pref_catalog manifest for embedding in `ui_static_data`.
/// Returns the parsed manifest (a list) on success, or an empty list when
/// the bundle hasn't been materialized yet. Logged failures are non-fatal —
/// the TGUI picker falls back to a name-only list with no thumbnails.
/proc/pref_catalog_load_manifest_for_static_data(manifest_path = "data/pref_catalog/manifest.json")
	if(!fexists(manifest_path))
		return list()
	var/raw = rustg_file_read(manifest_path)
	if(!istext(raw) || !length(raw))
		return list()
	var/list/manifest
	try
		manifest = json_decode(raw)
	catch
		stack_trace("pref_catalog_load_manifest_for_static_data: json_decode failed at '[manifest_path]'")
		return list()
	if(!islist(manifest))
		return list()
	return manifest

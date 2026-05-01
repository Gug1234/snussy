/**
 * Coverage test for the Phase 3 manifest bridge.
 *
 * For every category in the live appearance-preview manifest, pick the
 * first declared state and assert that uni_icon_from_manifest returns a
 * valid /datum/universal_icon. Exercises the full resolution path:
 * category to state to family to plan sprite entry to universal_icon.
 *
 * Fails closed if the bundle artifacts are missing at test-run time;
 * a missing manifest indicates either a build-pipeline regression or a
 * dev setup that did not publish the artifacts, both of which should
 * surface as a test failure rather than a silent pass.
 */
/datum/unit_test/uni_icon_from_manifest_coverage/Run()
	uni_icon_manifest_bridge_clear_cache()

	var/manifest_path = "tgui/public/appearance_preview/manifest.json"
	TEST_ASSERT(fexists(manifest_path), "appearance_preview manifest bundle missing; run the build pipeline before testing")

	var/manifest_raw = rustg_file_read(manifest_path)
	var/list/manifest = json_decode(manifest_raw)
	TEST_ASSERT(islist(manifest), "manifest.json did not parse into a list")

	var/list/categories = manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES]
	TEST_ASSERT(islist(categories) && length(categories), "manifest has no categories")

	var/covered = 0
	for(var/category_key in categories)
		var/list/category = categories[category_key]
		if(!islist(category))
			continue
		var/list/states = category["states"]
		if(!islist(states) || !length(states))
			continue
		var/state_key = states[1]
		var/datum/universal_icon/resolved = uni_icon_from_manifest(category_key, state_key)
		TEST_ASSERT(istype(resolved), "uni_icon_from_manifest returned non-universal_icon for category=[category_key] state=[state_key]")
		TEST_ASSERT(length("[resolved.icon_file]"), "resolved universal_icon has empty icon_file for category=[category_key] state=[state_key]")
		TEST_ASSERT_EQUAL(resolved.icon_state, state_key, "resolved icon_state should match the requested state_key")
		covered++

	TEST_ASSERT(covered > 0, "coverage test walked zero categories; manifest taxonomy is empty or malformed")

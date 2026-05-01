/datum/preferences/appearance_preview_test_prefs
	var/save_character_calls = 0
	var/update_preview_icon_calls = 0
	var/save_custom_piercings_calls = 0
	var/last_custom_piercing_slot = null
	var/fail_save_character = FALSE

/datum/preferences/appearance_preview_test_prefs/New()
	return

/datum/preferences/appearance_preview_test_prefs/save_character()
	save_character_calls++
	return !fail_save_character

/datum/preferences/appearance_preview_test_prefs/update_preview_icon(jobOnly = FALSE)
	update_preview_icon_calls++

/datum/preferences/appearance_preview_test_prefs/save_custom_piercings(slot)
	save_custom_piercings_calls++
	last_custom_piercing_slot = slot

/datum/unit_test/appearance_preview_manifest_contract/Run()
	var/datum/appearance_preview_manifest_contract/contract = build_appearance_preview_manifest_contract()
	TEST_ASSERT_EQUAL(contract.version, APPEARANCE_PREVIEW_MANIFEST_VERSION, "manifest version should match the frozen contract")
	TEST_ASSERT_EQUAL(contract.canonical_lookup_key, APPEARANCE_PREVIEW_MANIFEST_KEY_ICON_STATE, "canonical lookup key should stay icon_state")

	var/list/category_order = contract.category_order
	TEST_ASSERT_EQUAL(category_order.len, GLOB.appearance_preview_manifest_category_order.len, "category order length should not drift")
	for(var/i in 1 to category_order.len)
		TEST_ASSERT_EQUAL(category_order[i], GLOB.appearance_preview_manifest_category_order[i], "category order entry [i] should match the frozen taxonomy")

	var/list/category_scopes = contract.category_scopes
	for(var/category_key in category_order)
		TEST_ASSERT_EQUAL(category_scopes[category_key], GLOB.appearance_preview_manifest_category_scopes[category_key], "category scope should match the frozen taxonomy")

	var/list/manifest = contract.as_list()
	TEST_ASSERT(appearance_preview_manifest_contract_is_valid(manifest), "fresh contract output should validate")

	var/list/bad_manifest = manifest.Copy()
	bad_manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION] = APPEARANCE_PREVIEW_MANIFEST_VERSION + 1
	TEST_ASSERT(!appearance_preview_manifest_contract_is_valid(bad_manifest), "version drift should fail validation")

	TEST_ASSERT_EQUAL(appearance_preview_dir_to_key(NORTH), APPEARANCE_PREVIEW_DIR_KEY_N, "north should map to the canonical n key")
	TEST_ASSERT_EQUAL(appearance_preview_key_to_dir(APPEARANCE_PREVIEW_DIR_KEY_W), WEST, "w should map back to west")

/datum/unit_test/appearance_preview_commit_paths/Run()
	var/datum/preferences/appearance_preview_test_prefs/custom_prefs = new
	custom_prefs.custom_piercings = list()
	custom_prefs.default_slot = 3
	var/datum/custom_piercing_editor/custom_editor = allocate(/datum/custom_piercing_editor, custom_prefs, null)
	TEST_ASSERT(appearance_preview_commit_custom_piercing_editor(custom_editor), "custom piercing commit should succeed")
	TEST_ASSERT_EQUAL(custom_prefs.save_character_calls, 1, "custom piercing should save once")
	TEST_ASSERT_EQUAL(custom_prefs.update_preview_icon_calls, 1, "custom piercing should refresh once")
	// The two-phase persist pipeline now computes/buffers the sidecar
	// payload directly via `compute_custom_piercings_payload` +
	// `_flush_persist` and no longer routes through the legacy
	// `save_custom_piercings()` wrapper. In headless test prefs the
	// sidecar dir is unavailable so the buffer is empty -- the
	// observable contract is just that the main prefs save + preview
	// refresh fired exactly once, asserted above.

	var/datum/preferences/appearance_preview_test_prefs/taur_prefs = new
	taur_prefs.taur_penis_props = list()
	taur_prefs.taur_penis_erect_state_props = list()
	taur_prefs.taur_testicles_props = list()
	taur_prefs.taur_vagina_props = list()
	taur_prefs.taur_genital_global_hide = list()
	var/datum/taur_genital_offset_editor/taur_editor = allocate(/datum/taur_genital_offset_editor, taur_prefs, "testicles")
	TEST_ASSERT(appearance_preview_commit_taur_genital_offset_editor(taur_editor), "taur commit should succeed")
	TEST_ASSERT_EQUAL(taur_prefs.save_character_calls, 1, "taur commit should save once")
	TEST_ASSERT_EQUAL(taur_prefs.update_preview_icon_calls, 1, "taur commit should refresh once")

	var/datum/preferences/appearance_preview_test_prefs/failing_prefs = new
	failing_prefs.fail_save_character = TRUE
	TEST_ASSERT(!appearance_preview_commit_character_preview(failing_prefs), "failed character save should block the refresh")
	TEST_ASSERT_EQUAL(failing_prefs.save_character_calls, 1, "failed character save should still be attempted once")
	TEST_ASSERT_EQUAL(failing_prefs.update_preview_icon_calls, 0, "failed character save must not refresh the preview")

// ----------------------------------------------------------------------------
// Step 15: v2 manifest envelope validation + commit-once pipeline coverage.
// ----------------------------------------------------------------------------

/// Minimal `/datum/appearance_preview_editor` subtype used exclusively by the
/// commit-pipeline unit tests. Keeps the assertions decoupled from the two
/// real editors so a change in one editor's snapshot shape cannot silently
/// break the commit-contract tests.
/datum/appearance_preview_editor/test_stub
	editor_kind = "test_stub"
	pref_key = "test_stub_pref"
	family_id = APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS
	/// Incremented every time `_apply_snapshot` runs.
	var/apply_calls = 0
	/// Incremented every time `_stage_persist` runs. The Step-4 two-phase
	/// pipeline replaced the legacy `_persist` hook with `_stage_persist`
	/// + `_flush_persist`; the stub still names the counter `persist_calls`
	/// because the assertion lines pre-date the rename.
	var/persist_calls = 0
	/// When TRUE, `_apply_snapshot` returns FALSE so the pipeline aborts
	/// before any persist call.
	var/fail_apply = FALSE
	/// When TRUE, `_stage_persist` returns FALSE.
	var/fail_persist = FALSE
	/// Last snapshot list `_apply_snapshot` received. Used to prove the
	/// pipeline forwarded the client payload unmodified.
	var/list/last_snapshot

/datum/appearance_preview_editor/test_stub/New(datum/preferences/P)
	if(!P)
		qdel(src)
		return
	prefs = P

/datum/appearance_preview_editor/test_stub/_apply_snapshot(list/snapshot)
	apply_calls++
	last_snapshot = snapshot
	return !fail_apply

/datum/appearance_preview_editor/test_stub/_stage_persist()
	persist_calls++
	return !fail_persist

/// Builds the envelope shape the pipeline expects, tailored to the stub
/// editor above. Tests mutate individual fields on the returned list to
/// exercise specific failure modes.
/proc/_appearance_preview_test_envelope(datum/appearance_preview_editor/editor, list/snapshot_override = null)
	return list(
		APPEARANCE_PREVIEW_COMMIT_KEY_EDITOR_KIND = editor.editor_kind,
		APPEARANCE_PREVIEW_COMMIT_KEY_PREF_KEY = editor.pref_key,
		APPEARANCE_PREVIEW_COMMIT_KEY_FAMILY_ID = editor.family_id,
		APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN = editor.revision_token,
		APPEARANCE_PREVIEW_COMMIT_KEY_DIRTY = TRUE,
		APPEARANCE_PREVIEW_COMMIT_KEY_SNAPSHOT = snapshot_override || list("ok" = TRUE),
	)

/datum/unit_test/appearance_preview_manifest_envelope/Run()
	// Build a minimal v2 envelope and prove the shallow validator
	// accepts it. The orchestrator's TS validator already runs a
	// deeper check before publish; we only re-verify the envelope.
	var/datum/appearance_preview_manifest_contract/contract = build_appearance_preview_manifest_contract()
	var/list/manifest = contract.as_list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_SHEETS] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_STATES] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD] = list(
		APPEARANCE_PREVIEW_BUILD_KEY_BUILT_AT = "1970-01-01T00:00:00.000Z",
		APPEARANCE_PREVIEW_BUILD_KEY_BACKEND = APPEARANCE_PREVIEW_BACKEND_ID,
		APPEARANCE_PREVIEW_BUILD_KEY_LAYOUT = APPEARANCE_PREVIEW_LAYOUT_KIND,
		APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT = "deadbeef",
		APPEARANCE_PREVIEW_BUILD_KEY_ADAPTER_VERSIONS = list("taur_offsets" = "1.0.0"),
	)
	TEST_ASSERT(appearance_preview_manifest_v2_envelope_is_valid(manifest), "well-formed v2 envelope should validate")

	// Version mismatch â€” proves fail-closed against stale bundles.
	var/list/stale = manifest.Copy()
	stale[APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION] = APPEARANCE_PREVIEW_MANIFEST_VERSION - 1
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(stale), "stale version should be rejected")

	// Wrong backend id.
	var/list/wrong_backend = manifest.Copy()
	wrong_backend[APPEARANCE_PREVIEW_MANIFEST_KEY_BACKEND] = "python_exporter"
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(wrong_backend), "wrong backend id should be rejected")

	// Wrong layout kind.
	var/list/wrong_layout = manifest.Copy()
	wrong_layout[APPEARANCE_PREVIEW_MANIFEST_KEY_LAYOUT] = "per-state"
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(wrong_layout), "wrong layout kind should be rejected")

	// Missing envelope blocks.
	var/list/missing_sheets = manifest.Copy()
	missing_sheets -= APPEARANCE_PREVIEW_MANIFEST_KEY_SHEETS
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(missing_sheets), "missing sheets block should be rejected")

	var/list/missing_states = manifest.Copy()
	missing_states -= APPEARANCE_PREVIEW_MANIFEST_KEY_STATES
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(missing_states), "missing states block should be rejected")

	var/list/missing_build = manifest.Copy()
	missing_build -= APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(missing_build), "missing build block should be rejected")

	// Build block with wrong inner backend â€” covers the mismatched-twin
	// case where envelope and build metadata disagree.
	var/list/mismatched_build = manifest.Copy()
	// Stash the list-indexed lookup in a typed var so dreamchecker knows
	// .Copy() targets a /list, not the bare return of list indexing.
	var/list/raw_build = mismatched_build[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD]
	var/list/build_block = raw_build.Copy()
	build_block[APPEARANCE_PREVIEW_BUILD_KEY_BACKEND] = "python_exporter"
	mismatched_build[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD] = build_block
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(mismatched_build), "build block with wrong backend should be rejected")

	// Build block missing sourceFingerprint â€” fail-closed on truncated
	// bundles that the TS validator would have rejected upstream.
	var/list/missing_fingerprint = manifest.Copy()
	var/list/raw_fp_build = missing_fingerprint[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD]
	var/list/fp_build = raw_fp_build.Copy()
	fp_build -= APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT
	missing_fingerprint[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD] = fp_build
	TEST_ASSERT(!appearance_preview_manifest_v2_envelope_is_valid(missing_fingerprint), "build block missing sourceFingerprint should be rejected")

/datum/unit_test/appearance_preview_manifest_loader/Run()
	// Positive path: write a valid envelope, load it, prove round-trip.
	var/datum/appearance_preview_manifest_contract/contract = build_appearance_preview_manifest_contract()
	var/list/manifest = contract.as_list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_SHEETS] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_STATES] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD] = list(
		APPEARANCE_PREVIEW_BUILD_KEY_BUILT_AT = "1970-01-01T00:00:00.000Z",
		APPEARANCE_PREVIEW_BUILD_KEY_BACKEND = APPEARANCE_PREVIEW_BACKEND_ID,
		APPEARANCE_PREVIEW_BUILD_KEY_LAYOUT = APPEARANCE_PREVIEW_LAYOUT_KIND,
		APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT = "deadbeef",
		APPEARANCE_PREVIEW_BUILD_KEY_ADAPTER_VERSIONS = list("taur_offsets" = "1.0.0"),
	)
	var/ok_path = "tmp/unit_test_appearance_preview_manifest_ok.json"
	fdel(ok_path)
	text2file(json_encode(manifest), ok_path)
	var/list/loaded = appearance_preview_load_and_validate_manifest(ok_path)
	TEST_ASSERT_NOTNULL(loaded, "valid manifest on disk should load")
	TEST_ASSERT_EQUAL(loaded[APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION], APPEARANCE_PREVIEW_MANIFEST_VERSION, "loaded manifest should preserve version")
	fdel(ok_path)

	// Missing file â€” loader must return null, never throw.
	TEST_ASSERT_NULL(appearance_preview_load_and_validate_manifest("tmp/unit_test_appearance_preview_does_not_exist.json"), "missing file should return null")

	// Stale version bundle â€” loader must reject.
	var/list/stale = manifest.Copy()
	stale[APPEARANCE_PREVIEW_MANIFEST_KEY_VERSION] = APPEARANCE_PREVIEW_MANIFEST_VERSION - 1
	var/stale_path = "tmp/unit_test_appearance_preview_manifest_stale.json"
	fdel(stale_path)
	text2file(json_encode(stale), stale_path)
	TEST_ASSERT_NULL(appearance_preview_load_and_validate_manifest(stale_path), "stale-version manifest on disk should be rejected")
	fdel(stale_path)

	// Malformed JSON â€” rustg_json_is_valid guard must fail closed.
	var/garbage_path = "tmp/unit_test_appearance_preview_manifest_garbage.json"
	fdel(garbage_path)
	text2file("{not valid json", garbage_path)
	TEST_ASSERT_NULL(appearance_preview_load_and_validate_manifest(garbage_path), "malformed JSON should be rejected")
	fdel(garbage_path)

/datum/unit_test/appearance_preview_family_validation/Run()
	TEST_ASSERT(appearance_preview_family_is_valid(APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS), "taur_offsets family should validate")
	TEST_ASSERT(appearance_preview_family_is_valid(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS), "custom_piercings family should validate")
	TEST_ASSERT(appearance_preview_family_is_valid(APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS), "intimate_accessory_offsets family should validate")
	TEST_ASSERT(!appearance_preview_family_is_valid("unregistered_family"), "unknown family id should be rejected")
	TEST_ASSERT(!appearance_preview_family_is_valid(""), "empty string family id should be rejected")
	TEST_ASSERT(!appearance_preview_family_is_valid(null), "null family id should be rejected")
	TEST_ASSERT(!appearance_preview_family_is_valid(42), "non-text family id should be rejected")

/datum/unit_test/hybrid_offset_descriptor_builder/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new

	var/list/shell = hybrid_offset_build_descriptor(APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, "penis", NORTH)
	TEST_ASSERT_NOTNULL(shell, "generic descriptor shell should build from a valid family/target/cardinal dir")
	TEST_ASSERT_EQUAL(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_FAMILY], APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, "descriptor family should echo the sanitized family")
	TEST_ASSERT_EQUAL(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_TARGET_KEY], "penis", "descriptor target_key should echo the sanitized target")
	TEST_ASSERT_EQUAL(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_DIRECTION], APPEARANCE_PREVIEW_DIR_KEY_N, "cardinal BYOND dir should normalize to the canonical TGUI dir key")
	TEST_ASSERT_EQUAL(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY], null, "generic descriptor shells should not invent a manifest category")
	TEST_ASSERT_EQUAL(length(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS]), 0, "generic descriptor shells should not invent guide layers")
	TEST_ASSERT_EQUAL(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_WIDTH], HYBRID_OFFSET_DEFAULT_NATIVE_SIZE, "generic descriptor shell width should use the default native size")
	TEST_ASSERT_EQUAL(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_NATIVE_HEIGHT], HYBRID_OFFSET_DEFAULT_NATIVE_SIZE, "generic descriptor shell height should use the default native size")
	TEST_ASSERT_EQUAL(length(shell[HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS]), length(GLOB.hybrid_offset_allowed_field_keys), "generic descriptor shells should expose the shared transform field set")

	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor("rogue_family", "penis", APPEARANCE_PREVIEW_DIR_KEY_S), "unknown families should be rejected")
	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, "", APPEARANCE_PREVIEW_DIR_KEY_S), "empty target keys should be rejected")
	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, "penis", "sideways"), "unknown direction keys should be rejected")
	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS, "penis", NORTH), "taur descriptor routing should not return a generic shell when no taur source can resolve")

	var/list/resolved_layer = list(
		HYBRID_OFFSET_LAYER_KEY_ICON_STATE = "stud_metal",
		HYBRID_OFFSET_LAYER_KEY_ROLE = HYBRID_OFFSET_LAYER_ROLE_METAL,
		HYBRID_OFFSET_LAYER_KEY_COLOR = "#ffffff",
	)
	var/list/resolved = hybrid_offset_build_descriptor(
		APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS,
		"ear:0",
		APPEARANCE_PREVIEW_DIR_KEY_S,
		APPEARANCE_PREVIEW_CATEGORY_STICKER,
		list(resolved_layer),
		list(APPEARANCE_PREVIEW_PROP_X, "rogue_field", APPEARANCE_PREVIEW_PROP_Y),
		64,
		64,
		TRUE
	)
	TEST_ASSERT_NOTNULL(resolved, "resolved descriptor should build with a manifest category and layer")
	TEST_ASSERT_EQUAL(resolved[HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY], APPEARANCE_PREVIEW_CATEGORY_STICKER, "resolved descriptor should preserve a valid manifest category")
	TEST_ASSERT_EQUAL(length(resolved[HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS]), 1, "resolved descriptor should preserve one sanitized guide layer")
	var/list/first_layer = resolved[HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS][1]
	TEST_ASSERT_EQUAL(first_layer[HYBRID_OFFSET_LAYER_KEY_ICON_STATE], "stud_metal", "resolved layer should preserve the server-provided icon_state")
	TEST_ASSERT_EQUAL(first_layer[HYBRID_OFFSET_LAYER_KEY_ROLE], HYBRID_OFFSET_LAYER_ROLE_METAL, "resolved layer should preserve a valid role")
	TEST_ASSERT_EQUAL(length(resolved[HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS]), 2, "resolved descriptor should drop unknown transform fields")
	TEST_ASSERT_EQUAL(resolved[HYBRID_OFFSET_DESCRIPTOR_KEY_APPROXIMATE_COLOR], TRUE, "resolved descriptor should preserve the approximate-color hint")
	TEST_ASSERT_NULL(hybrid_offset_build_descriptor(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, "ear:0", APPEARANCE_PREVIEW_DIR_KEY_S, null, list(resolved_layer)), "layers without a manifest category should be rejected")

	qdel(test_prefs)

/datum/unit_test/taur_hybrid_offset_descriptor_resolves_server_icon_states/Run()
	TEST_ASSERT_EQUAL(taur_genital_hybrid_target_key("penis", ERECT_STATE_HARD), "penis:2", "penis descriptor target keys should include arousal state")
	TEST_ASSERT_EQUAL(taur_genital_hybrid_target_key("testicles"), "testicles", "single-state taur target keys should stay part-only")
	TEST_ASSERT_EQUAL(taur_genital_resolve_guide_icon_state("penis", "human", APPEARANCE_PREVIEW_DIR_KEY_S, ERECT_STATE_HARD, DEFAULT_PENIS_SIZE, SHEATH_TYPE_NONE, TRUE), "human_2_2_FRONT_1", "hard front-facing penis should resolve through the server helper")
	TEST_ASSERT_EQUAL(taur_genital_resolve_guide_icon_state("penis", "knotted", APPEARANCE_PREVIEW_DIR_KEY_N, ERECT_STATE_NONE, DEFAULT_PENIS_SIZE, SHEATH_TYPE_NONE, TRUE), "knotted_3_BEHIND_1", "north-facing penis should use the authored behind fallback state")
	TEST_ASSERT_EQUAL(taur_genital_resolve_guide_icon_state("penis", "human", APPEARANCE_PREVIEW_DIR_KEY_S, ERECT_STATE_PARTIAL, DEFAULT_PENIS_SIZE, SHEATH_TYPE_SLIT, TRUE), "slit_2_FRONT_1", "front-facing slit penis should resolve through the sheath/slit branch")
	TEST_ASSERT_EQUAL(taur_genital_resolve_guide_icon_state("testicles", "pair", APPEARANCE_PREVIEW_DIR_KEY_N, ERECT_STATE_NONE, DEFAULT_TESTICLES_SIZE), "pair_2_BEHIND", "north-facing testicles should use the behind layer")
	TEST_ASSERT_EQUAL(taur_genital_resolve_guide_icon_state("vagina", "spade", APPEARANCE_PREVIEW_DIR_KEY_W), "spade_FRONT", "vagina descriptors should resolve the front-layer state")

/datum/unit_test/custom_piercing_hybrid_offset_descriptor_resolves_server_layers/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	var/list/entry = sanitize_custom_piercing_entry(list(
		"sticker" = "stud",
		"metal_color" = "#112233",
		"gem_color" = "#445566",
		"props" = default_custom_piercing_props(),
	))
	TEST_ASSERT_NOTNULL(entry, "known sticker entry should sanitize for descriptor tests")

	test_prefs.custom_piercings = list(
		"custom_upper" = list(
			"enabled" = 1,
			"entries" = list(entry),
		),
	)
	test_prefs.mark_custom_piercings_dirty()

	var/list/descriptor = test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, "custom_upper:1", APPEARANCE_PREVIEW_DIR_KEY_S)
	TEST_ASSERT_NOTNULL(descriptor, "custom piercing selected entry should resolve through the shared descriptor entrypoint")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_FAMILY], APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, "descriptor should identify the custom piercing family")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_TARGET_KEY], "custom_upper:1", "descriptor should preserve the selected slot/index target")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY], APPEARANCE_PREVIEW_CATEGORY_STICKER, "custom piercing guide layers should use the sticker manifest category")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_APPROXIMATE_COLOR], TRUE, "custom piercing colors are a guide-only approximation")
	TEST_ASSERT_EQUAL(length(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS]), length(GLOB.custom_piercing_field_keys), "custom piercing descriptors should expose the sticker transform fields")

	var/list/layers = descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS]
	TEST_ASSERT(layers.len >= 1, "custom piercing descriptor should include at least a metal layer")
	var/list/metal_layer = layers[1]
	TEST_ASSERT_EQUAL(metal_layer[HYBRID_OFFSET_LAYER_KEY_ICON_STATE], "stud_metal", "metal layer state should be resolved by DM")
	TEST_ASSERT_EQUAL(metal_layer[HYBRID_OFFSET_LAYER_KEY_ROLE], HYBRID_OFFSET_LAYER_ROLE_METAL, "first descriptor layer should be the metal mask")
	TEST_ASSERT_EQUAL(metal_layer[HYBRID_OFFSET_LAYER_KEY_COLOR], "#112233", "metal layer should preserve sanitized entry color")
	if(layers.len >= 2)
		var/list/gem_layer = layers[2]
		TEST_ASSERT_EQUAL(gem_layer[HYBRID_OFFSET_LAYER_KEY_ICON_STATE], "stud_gem", "gem layer state should be resolved by DM")
		TEST_ASSERT_EQUAL(gem_layer[HYBRID_OFFSET_LAYER_KEY_ROLE], HYBRID_OFFSET_LAYER_ROLE_GEM, "second descriptor layer should be the gem mask")
		TEST_ASSERT_EQUAL(gem_layer[HYBRID_OFFSET_LAYER_KEY_COLOR], "#445566", "gem layer should preserve sanitized entry color")

	var/datum/piercing_sticker/sticker = get_custom_piercing_sticker("stud")
	var/list/prototype_layers = custom_piercing_build_sticker_hybrid_guide_layers(sticker, null, null, FALSE)
	TEST_ASSERT(prototype_layers.len >= 1, "registry prototype layers should expose server-owned sticker states")
	var/list/prototype_metal = prototype_layers[1]
	TEST_ASSERT_EQUAL(prototype_metal[HYBRID_OFFSET_LAYER_KEY_ICON_STATE], "stud_metal", "prototype layer should expose the metal state without TGUI composition")
	TEST_ASSERT_NULL(prototype_metal[HYBRID_OFFSET_LAYER_KEY_COLOR], "prototype layers should not bake colors into registry metadata")

	var/list/grid = test_prefs.build_custom_piercing_hybrid_offset_descriptor_grid()
	TEST_ASSERT_NOTNULL(grid["custom_upper"], "descriptor grid should include configured slots")
	TEST_ASSERT_NOTNULL(grid["custom_upper"]["1"], "descriptor grid should include the selected entry index")
	TEST_ASSERT_NOTNULL(grid["custom_upper"]["1"][APPEARANCE_PREVIEW_DIR_KEY_S], "descriptor grid should include direction descriptors")

	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, "custom_upper:2", APPEARANCE_PREVIEW_DIR_KEY_S), "out-of-range entry indices should not produce descriptors")
	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, "custom_upper:rogue", APPEARANCE_PREVIEW_DIR_KEY_S), "malformed target indices should not produce descriptors")
	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS, "not_a_slot:1", APPEARANCE_PREVIEW_DIR_KEY_S), "unknown slots should not produce descriptors")

	qdel(test_prefs)

/datum/unit_test/appearance_preview_commit_envelope_rejects_bad_inputs/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	var/datum/appearance_preview_editor/test_stub/editor = new(test_prefs)

	// No prefs â€” direct failure path.
	var/datum/appearance_preview_editor/test_stub/orphan_editor = new(test_prefs)
	orphan_editor.prefs = null
	TEST_ASSERT(!appearance_preview_process_commit(orphan_editor, _appearance_preview_test_envelope(editor)), "commit with no prefs should fail")
	var/list/orphan_result = orphan_editor.last_commit_result
	TEST_ASSERT_EQUAL(orphan_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_NO_PREFS, "no_prefs code should be recorded")
	qdel(orphan_editor)

	// Not a list â€” envelope must be validated before any field access.
	TEST_ASSERT(!appearance_preview_process_commit(editor, null), "non-list envelope should fail")
	TEST_ASSERT_EQUAL(editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_ENVELOPE, "invalid_envelope code should be recorded")
	TEST_ASSERT_EQUAL(editor.apply_calls, 0, "invalid envelope must not apply snapshot")
	TEST_ASSERT_EQUAL(test_prefs.save_character_calls, 0, "invalid envelope must not persist")

	// Wrong editor_kind.
	var/list/bad_kind = _appearance_preview_test_envelope(editor)
	bad_kind[APPEARANCE_PREVIEW_COMMIT_KEY_EDITOR_KIND] = "rogue_editor"
	TEST_ASSERT(!appearance_preview_process_commit(editor, bad_kind), "mismatched editor_kind should fail")
	TEST_ASSERT_EQUAL(editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_EDITOR_KIND, "invalid_editor_kind code should be recorded")

	// Wrong pref_key.
	var/list/bad_pref = _appearance_preview_test_envelope(editor)
	bad_pref[APPEARANCE_PREVIEW_COMMIT_KEY_PREF_KEY] = "rogue_pref"
	TEST_ASSERT(!appearance_preview_process_commit(editor, bad_pref), "mismatched pref_key should fail")
	TEST_ASSERT_EQUAL(editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_PREF_KEY, "invalid_pref_key code should be recorded")

	// Wrong family_id (one the editor does not own).
	var/list/bad_family = _appearance_preview_test_envelope(editor)
	bad_family[APPEARANCE_PREVIEW_COMMIT_KEY_FAMILY_ID] = APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS
	TEST_ASSERT(!appearance_preview_process_commit(editor, bad_family), "mismatched family_id should fail")
	TEST_ASSERT_EQUAL(editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_FAMILY_ID, "invalid_family_id code should be recorded")

	// Stale revision token.
	var/list/stale_rev = _appearance_preview_test_envelope(editor)
	stale_rev[APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN] = editor.revision_token - 1
	TEST_ASSERT(!appearance_preview_process_commit(editor, stale_rev), "stale revision token should fail")
	TEST_ASSERT_EQUAL(editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_STALE_REVISION, "stale_revision code should be recorded")

	// Missing snapshot.
	var/list/no_snapshot = _appearance_preview_test_envelope(editor)
	no_snapshot[APPEARANCE_PREVIEW_COMMIT_KEY_SNAPSHOT] = "not a list"
	TEST_ASSERT(!appearance_preview_process_commit(editor, no_snapshot), "non-list snapshot should fail")
	TEST_ASSERT_EQUAL(editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_SNAPSHOT, "invalid_snapshot code should be recorded")

	// None of the above should have touched prefs.
	TEST_ASSERT_EQUAL(editor.apply_calls, 0, "rejected envelopes must not apply snapshots")
	TEST_ASSERT_EQUAL(editor.persist_calls, 0, "rejected envelopes must not persist")
	TEST_ASSERT_EQUAL(test_prefs.save_character_calls, 0, "rejected envelopes must not save")
	TEST_ASSERT_EQUAL(test_prefs.update_preview_icon_calls, 0, "rejected envelopes must not refresh mannequin")
	TEST_ASSERT_EQUAL(editor.revision_token, 1, "rejected envelopes must not bump revision_token")

	qdel(editor)

/datum/unit_test/appearance_preview_commit_pipeline_success/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	var/datum/appearance_preview_editor/test_stub/editor = new(test_prefs)
	var/starting_token = editor.revision_token

	var/list/envelope = _appearance_preview_test_envelope(editor, list("field" = "value"))
	TEST_ASSERT(appearance_preview_process_commit(editor, envelope), "valid envelope should succeed")

	// Single-refresh contract: each side of the commit runs exactly once.
	TEST_ASSERT_EQUAL(editor.apply_calls, 1, "_apply_snapshot should run exactly once")
	TEST_ASSERT_EQUAL(editor.persist_calls, 1, "_persist should run exactly once")
	TEST_ASSERT_EQUAL(test_prefs.save_character_calls, 1, "save_character should run exactly once")
	TEST_ASSERT_EQUAL(test_prefs.update_preview_icon_calls, 1, "update_preview_icon should run exactly once")
	TEST_ASSERT_EQUAL(editor.revision_token, starting_token + 1, "revision_token should bump by 1 on success")

	// Snapshot was forwarded unmodified.
	TEST_ASSERT_EQUAL(editor.last_snapshot["field"], "value", "snapshot should reach _apply_snapshot unmodified")

	// last_commit_result carries the success envelope.
	var/list/result = editor.last_commit_result
	TEST_ASSERT_NOTNULL(result, "last_commit_result should be populated")
	TEST_ASSERT_EQUAL(result["ok"], TRUE, "last_commit_result.ok should be TRUE")
	TEST_ASSERT_EQUAL(result["code"], APPEARANCE_PREVIEW_COMMIT_OK, "success code should be recorded")
	TEST_ASSERT_EQUAL(result[APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN], editor.revision_token, "result revision_token should match editor")

	qdel(editor)

/datum/unit_test/appearance_preview_commit_preserves_draft_on_failure/Run()
	// _apply_snapshot rejection: must not persist or refresh.
	var/datum/preferences/appearance_preview_test_prefs/apply_prefs = new
	var/datum/appearance_preview_editor/test_stub/apply_editor = new(apply_prefs)
	apply_editor.fail_apply = TRUE
	var/apply_token = apply_editor.revision_token

	TEST_ASSERT(!appearance_preview_process_commit(apply_editor, _appearance_preview_test_envelope(apply_editor)), "failing _apply_snapshot should fail the commit")
	TEST_ASSERT_EQUAL(apply_editor.apply_calls, 1, "_apply_snapshot should have been called once")
	TEST_ASSERT_EQUAL(apply_editor.persist_calls, 0, "_persist must not run when _apply_snapshot fails")
	TEST_ASSERT_EQUAL(apply_prefs.save_character_calls, 0, "save_character must not run when _apply_snapshot fails")
	TEST_ASSERT_EQUAL(apply_prefs.update_preview_icon_calls, 0, "update_preview_icon must not run when _apply_snapshot fails")
	TEST_ASSERT_EQUAL(apply_editor.revision_token, apply_token, "revision_token must not bump on apply failure")
	TEST_ASSERT_EQUAL(apply_editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_APPLY_FAILED, "apply_failed code should be recorded")
	qdel(apply_editor)

	// _persist rejection: apply ran, but persist must block save+refresh.
	var/datum/preferences/appearance_preview_test_prefs/persist_prefs = new
	var/datum/appearance_preview_editor/test_stub/persist_editor = new(persist_prefs)
	persist_editor.fail_persist = TRUE
	var/persist_token = persist_editor.revision_token

	TEST_ASSERT(!appearance_preview_process_commit(persist_editor, _appearance_preview_test_envelope(persist_editor)), "failing _persist should fail the commit")
	TEST_ASSERT_EQUAL(persist_editor.apply_calls, 1, "_apply_snapshot should have been called once")
	TEST_ASSERT_EQUAL(persist_editor.persist_calls, 1, "_persist should have been called once")
	TEST_ASSERT_EQUAL(persist_prefs.save_character_calls, 0, "save_character must not run when _persist fails")
	TEST_ASSERT_EQUAL(persist_prefs.update_preview_icon_calls, 0, "update_preview_icon must not run when _persist fails")
	TEST_ASSERT_EQUAL(persist_editor.revision_token, persist_token, "revision_token must not bump on persist failure")
	TEST_ASSERT_EQUAL(persist_editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_PERSIST_FAILED, "persist_failed code should be recorded")
	qdel(persist_editor)

	// save_character rejection: apply+persist ran, but save blocks refresh.
	var/datum/preferences/appearance_preview_test_prefs/save_prefs = new
	save_prefs.fail_save_character = TRUE
	var/datum/appearance_preview_editor/test_stub/save_editor = new(save_prefs)
	var/save_token = save_editor.revision_token

	TEST_ASSERT(!appearance_preview_process_commit(save_editor, _appearance_preview_test_envelope(save_editor)), "failing save_character should fail the commit")
	TEST_ASSERT_EQUAL(save_prefs.save_character_calls, 1, "save_character should have been attempted once")
	TEST_ASSERT_EQUAL(save_prefs.update_preview_icon_calls, 0, "update_preview_icon must not run when save_character fails")
	TEST_ASSERT_EQUAL(save_editor.revision_token, save_token, "revision_token must not bump on save failure")
	TEST_ASSERT_EQUAL(save_editor.last_commit_result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_PERSIST_FAILED, "persist_failed code should be recorded for save failure")
	qdel(save_editor)

/datum/unit_test/appearance_preview_commit_metadata_surface/Run()
	// `appearance_preview_editor_commit_metadata` is what the TGUI
	// editors emit in `ui_data` so the client can echo the contract
	// back on commit. Drift in this shape silently breaks commit
	// acceptance, so lock it down.
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	var/datum/appearance_preview_editor/test_stub/editor = new(test_prefs)
	var/list/meta = appearance_preview_editor_commit_metadata(editor)
	TEST_ASSERT(islist(meta["commit_contract"]), "commit_contract block should be a list")

	var/list/contract = meta["commit_contract"]
	TEST_ASSERT_EQUAL(contract[APPEARANCE_PREVIEW_COMMIT_KEY_EDITOR_KIND], editor.editor_kind, "commit_contract.editor_kind should mirror editor")
	TEST_ASSERT_EQUAL(contract[APPEARANCE_PREVIEW_COMMIT_KEY_PREF_KEY], editor.pref_key, "commit_contract.pref_key should mirror editor")
	TEST_ASSERT_EQUAL(contract[APPEARANCE_PREVIEW_COMMIT_KEY_FAMILY_ID], editor.family_id, "commit_contract.family_id should mirror editor")
	TEST_ASSERT_EQUAL(contract[APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN], editor.revision_token, "commit_contract.revision_token should mirror editor")

	// Null editor â€” proc must not throw.
	var/list/empty = appearance_preview_editor_commit_metadata(null)
	TEST_ASSERT(islist(empty), "null editor should return an empty list, not throw")
	TEST_ASSERT_EQUAL(empty.len, 0, "null editor result should be empty")

	qdel(editor)

// ----------------------------------------------------------------------------
// Step 11: on-disk coherence + mount-bundle fallback + admin retry coverage.
// ----------------------------------------------------------------------------

/// Stub subtype whose two-phase persist hooks stand in for the real editor
/// subtypes without pulling in their full snapshot machinery. `_stage_persist`
/// buffers a sidecar write into `pending_sidecars` using the caller-supplied
/// path and bytes so the split-brain test can prove the sidecar is NOT
/// touched on a `save_character()` failure.
/datum/appearance_preview_editor/test_stub/split_brain_stub
	/// Sidecar path staged by `_stage_persist`.
	var/sidecar_path
	/// Sidecar payload `_flush_persist` would write on success.
	var/new_sidecar_bytes
	/// In-memory data this stub mutates â€” plays the role
	/// `prefs.custom_piercings` does on the real custom-piercing editor.
	var/list/in_memory_data
	/// Snapshot of `in_memory_data` taken by `_capture_prefs_snapshot` and
	/// restored by `_restore_prefs_snapshot`.
	var/list/captured_in_memory_snapshot

/datum/appearance_preview_editor/test_stub/split_brain_stub/_capture_prefs_snapshot()
	captured_in_memory_snapshot = islist(in_memory_data) ? in_memory_data.Copy() : null

/datum/appearance_preview_editor/test_stub/split_brain_stub/_restore_prefs_snapshot()
	in_memory_data = captured_in_memory_snapshot

/datum/appearance_preview_editor/test_stub/split_brain_stub/_apply_snapshot(list/snapshot)
	apply_calls++
	last_snapshot = snapshot
	if(fail_apply)
		return FALSE
	// Mutate the in-memory data to simulate the editor writing a new
	// snapshot into prefs. The post-failure revert must undo this.
	in_memory_data = list("post_commit" = TRUE)
	return TRUE

/datum/appearance_preview_editor/test_stub/split_brain_stub/_stage_persist()
	if(!istext(sidecar_path) || !istext(new_sidecar_bytes))
		return TRUE
	pending_sidecars = list(list("path" = sidecar_path, "bytes" = new_sidecar_bytes))
	return TRUE

/// Writes a minimal v2 manifest + iconforge plan + single prebuilt PNG into
/// `root`. Returns the declared sheet output path (relative to `root`) so the
/// caller can delete it to force a fallback scenario.
/proc/_ap_mount_fixture_build(root)
	// Mkdir-style: write a throwaway file to force the directory to exist.
	var/sheet_rel_path = "sheets/fixture.png"
	var/sheet_abs_path = "[root]/[sheet_rel_path]"
	fdel(sheet_abs_path)
	text2file("stub-png", sheet_abs_path)

	var/datum/appearance_preview_manifest_contract/contract = build_appearance_preview_manifest_contract()
	var/list/manifest = contract.as_list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_SHEETS] = list(
		"fixture_sheet" = list(
			"family" = "fixture_family",
			"path" = sheet_rel_path,
		),
	)
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_STATES] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_CATEGORIES] = list()
	manifest[APPEARANCE_PREVIEW_MANIFEST_KEY_BUILD] = list(
		APPEARANCE_PREVIEW_BUILD_KEY_BUILT_AT = "1970-01-01T00:00:00.000Z",
		APPEARANCE_PREVIEW_BUILD_KEY_BACKEND = APPEARANCE_PREVIEW_BACKEND_ID,
		APPEARANCE_PREVIEW_BUILD_KEY_LAYOUT = APPEARANCE_PREVIEW_LAYOUT_KIND,
		APPEARANCE_PREVIEW_BUILD_KEY_SOURCE_FINGERPRINT = "deadbeef",
		APPEARANCE_PREVIEW_BUILD_KEY_ADAPTER_VERSIONS = list("fixture_family" = "1.0.0"),
	)
	var/manifest_path = "[root]/manifest.json"
	fdel(manifest_path)
	text2file(json_encode(manifest), manifest_path)

	var/list/plan = list(
		"jobs" = list(
			list(
				"spritesheetName" = "fixture_family",
				"sprites" = list(),
				"outputPath" = sheet_rel_path,
				"hashIcons" = FALSE,
			),
		),
	)
	var/plan_path = "[root]/iconforge_plan.json"
	fdel(plan_path)
	text2file(json_encode(plan), plan_path)
	return sheet_rel_path

/proc/_ap_mount_fixture_teardown(root)
	fdel("[root]/manifest.json")
	fdel("[root]/iconforge_plan.json")
	fdel("[root]/sheets/fixture.png")

/datum/unit_test/appearance_preview_split_brain/Run()
	// Forces a `save_character()` failure and asserts BOTH the in-memory
	// prefs snapshot AND the on-disk sidecar remain at their pre-commit
	// state. The two-phase persist pipeline buffers sidecar writes and
	// only drains them after `save_character()` succeeds; this test
	// locks that contract down so a regression cannot re-open the
	// split-brain hole where the sidecar could race ahead of the main
	// prefs file on a save failure.
	var/datum/preferences/appearance_preview_test_prefs/split_prefs = new
	split_prefs.fail_save_character = TRUE

	// Sidecar fixture under tmp/ â€” prove pre-commit bytes survive the
	// failed commit intact.
	var/sidecar_path = "tmp/unit_test_ap_split_brain_sidecar.json"
	fdel(sidecar_path)
	// Use rustg_file_write -- text2file appends a trailing newline that
	// would make the byte-equality assertion below spuriously fail.
	rustg_file_write("PRE_COMMIT_SIDECAR", sidecar_path)

	var/datum/appearance_preview_editor/test_stub/split_brain_stub/editor = new(split_prefs)
	editor.in_memory_data = list("pre_commit" = TRUE)
	editor.sidecar_path = sidecar_path
	editor.new_sidecar_bytes = "POST_COMMIT_SIDECAR"
	var/starting_token = editor.revision_token

	var/list/envelope = _appearance_preview_test_envelope(editor, list("field" = "value"))
	TEST_ASSERT(!appearance_preview_process_commit(editor, envelope), "save_character failure must fail the commit")

	// Error envelope: persist_failed code + unchanged revision_token.
	var/list/result = editor.last_commit_result
	TEST_ASSERT_NOTNULL(result, "last_commit_result must be populated on failure")
	TEST_ASSERT_EQUAL(result["ok"], FALSE, "ok should be FALSE on persist failure")
	TEST_ASSERT_EQUAL(result["code"], APPEARANCE_PREVIEW_COMMIT_ERR_PERSIST_FAILED, "code should be persist_failed")
	TEST_ASSERT_EQUAL(editor.revision_token, starting_token, "revision_token must not bump on persist failure")

	// save_character was attempted but sidecar write must not have run.
	TEST_ASSERT_EQUAL(split_prefs.save_character_calls, 1, "save_character should have been attempted once")
	TEST_ASSERT_EQUAL(split_prefs.update_preview_icon_calls, 0, "update_preview_icon must not run after save failure")

	// In-memory prefs state must be restored to pre-commit.
	TEST_ASSERT_NOTNULL(editor.in_memory_data, "in-memory data must be restored, not nulled")
	TEST_ASSERT_EQUAL(editor.in_memory_data["pre_commit"], TRUE, "in-memory data must match pre-commit snapshot")
	TEST_ASSERT_NULL(editor.in_memory_data["post_commit"], "post-commit mutation must have been reverted")

	// _revert_persist must have discarded the staged sidecar buffer.
	TEST_ASSERT_NULL(editor.pending_sidecars, "pending_sidecars must be cleared on failure")
	TEST_ASSERT_NULL(editor.prefs_snapshot, "prefs_snapshot must be cleared on failure")

	// On-disk sidecar must be byte-identical to pre-commit.
	TEST_ASSERT(fexists(sidecar_path), "sidecar must still exist after failed commit")
	var/sidecar_bytes = rustg_file_read(sidecar_path)
	TEST_ASSERT_EQUAL(sidecar_bytes, "PRE_COMMIT_SIDECAR", "sidecar bytes must be unchanged by a failed commit")

	fdel(sidecar_path)
	qdel(editor)

/datum/unit_test/appearance_preview_mount_bundle_fallback/Run()
	// Builds a fixture bundle and drives `mount_bundle` through three
	// paths: full prebuilt success, fail-closed when a PNG is missing and
	// the fallback flag is off, and branch-selection proof when the flag
	// is on. The third case does not attempt to prove iconforge itself
	// succeeds (it needs real DMIs); instead it asserts the fail-closed
	// reason is absent, which proves the fallback branch was entered.
	var/root = "tmp/unit_test_ap_mount_fallback"
	_ap_mount_fixture_build(root)

	var/datum/asset/simple/appearance_preview/asset = get_asset_datum(/datum/asset/simple/appearance_preview)
	TEST_ASSERT_NOTNULL(asset, "appearance_preview asset datum should be registered")

	// Case 1: every PNG present, fallback disabled â†’ clean mount.
	TEST_ASSERT(asset.mount_bundle(root, FALSE), "complete fixture should mount successfully")
	TEST_ASSERT_NULL(asset.last_mount_failure_reason, "successful mount must clear the failure reason")

	// Case 2: delete the sole sheet PNG, fallback disabled â†’ fail closed
	// with a reason mentioning the fallback flag so admins know the knob.
	fdel("[root]/sheets/fixture.png")
	TEST_ASSERT(!asset.mount_bundle(root, FALSE), "missing prebuilt sheet with fallback off must fail closed")
	TEST_ASSERT_NOTNULL(asset.last_mount_failure_reason, "fail-closed path must record a reason")
	TEST_ASSERT(findtext(asset.last_mount_failure_reason, "allow_appearance_preview_boot_fallback"), "fail-closed reason should mention the fallback flag")

	// Case 3: same state, fallback enabled â†’ the fail-closed branch MUST
	// NOT fire. `mount_bundle` starts by clearing `last_mount_failure_reason`,
	// and the iconforge fallback path does NOT call `_fail_mount` on its
	// internal errors, so the reason staying null here is the proof that
	// the fallback branch executed (even when iconforge itself fails on
	// the synthetic sprites list).
	asset.mount_bundle(root, TRUE)
	TEST_ASSERT_NULL(asset.last_mount_failure_reason, "fallback-enabled run must not record the fail-closed reason")

	// Cleanup: remove fixture + restore production mount so downstream
	// tests and runtime asset lookups see the real bundle again.
	_ap_mount_fixture_teardown(root)
	asset.mount_bundle()

/datum/unit_test/appearance_preview_admin_rebuild/Run()
	// Exercises the admin-rebuild retry surface. After a simulated mount
	// failure the asset's `last_mount_failure_reason` must be populated;
	// a subsequent successful mount must clear it. This is the same data
	// surface `admin_rebuild_appearance_preview_bundle` (in
	// `modular/code/modules/client/appearance_preview/appearance_preview_admin.dm`)
	// reads when reporting the outcome in chat, so locking down this
	// transition contract guards the admin verb without needing a
	// /client/proc invocation.
	var/root = "tmp/unit_test_ap_admin_rebuild"
	_ap_mount_fixture_build(root)

	var/datum/asset/simple/appearance_preview/asset = get_asset_datum(/datum/asset/simple/appearance_preview)
	TEST_ASSERT_NOTNULL(asset, "appearance_preview asset datum should be registered")

	// Step 1: simulate a failure by pointing at an empty tmp dir that
	// has no manifest. The asset must record the manifest-missing reason.
	var/empty_root = "tmp/unit_test_ap_admin_rebuild_empty"
	fdel("[empty_root]/manifest.json")
	TEST_ASSERT(!asset.mount_bundle(empty_root, FALSE), "empty root should fail")
	TEST_ASSERT_NOTNULL(asset.last_mount_failure_reason, "failure must populate last_mount_failure_reason")
	TEST_ASSERT(findtext(asset.last_mount_failure_reason, "manifest"), "failure reason should mention manifest")

	// Step 2: the admin "rebuild" path â€” point at the good fixture and
	// retry. Must succeed AND clear the prior failure reason so the chat
	// readout reflects the current attempt, not a stale one.
	TEST_ASSERT(asset.mount_bundle(root, FALSE), "rebuild against good fixture should succeed")
	TEST_ASSERT_NULL(asset.last_mount_failure_reason, "successful rebuild must clear last_mount_failure_reason")

	// Cleanup.
	_ap_mount_fixture_teardown(root)
	asset.mount_bundle()

/datum/unit_test/appearance_preview_legacy_shim_guard/Run()
	// The Step 9 remediation wrapped the legacy commit shim procs in
	// `#ifdef UNIT_TESTS` so a production build cannot accidentally
	// re-adopt the pre-Step-12 unvalidated commit path. This test is
	// itself gated by `UNIT_TESTS` (the whole unit_tests module is), so
	// simply calling each shim here proves both sides of the contract:
	//   - Under UNIT_TESTS the shims exist and this compiles + runs.
	//   - Without UNIT_TESTS the shims are absent AND this test is
	//     absent together, so there is no surface for a regressed
	//     caller to hit.
	// A removed shim that forgot to drop the `#ifdef` would fail this
	// compile at the proc-reference below, turning a silent security
	// regression into a loud build break.
#ifdef UNIT_TESTS
	TEST_ASSERT_EQUAL(appearance_preview_commit_custom_piercing_editor(null), FALSE, "custom piercing shim must exist under UNIT_TESTS and early-return FALSE on a null editor")
	TEST_ASSERT_EQUAL(appearance_preview_commit_taur_genital_offset_editor(null), FALSE, "taur shim must exist under UNIT_TESTS and early-return FALSE on a null editor")
#else
	TEST_FAIL("unit test compiled without UNIT_TESTS â€” shim guard is not being exercised")
#endif

/datum/unit_test/appearance_preview_custom_piercing_post_render_key/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	test_prefs.custom_piercings = list(
		"custom_upper" = list(
			"enabled" = 1,
			"entries" = list(),
		),
	)

	var/list/locs = block(run_loc_bottom_left, run_loc_top_right)
	var/mob/living/carbon/human/consistent/character = allocate(/mob/living/carbon/human/consistent, pick(locs))
	TEST_ASSERT_NOTNULL(character, "test character should allocate")

	test_prefs.copy_to(character, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE)
	var/first_key = character.generate_custom_piercing_post_overlay_key()
	var/copied_version = character.custom_piercings_version

	test_prefs.copy_to(character, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE)
	var/second_key = character.generate_custom_piercing_post_overlay_key()
	TEST_ASSERT_EQUAL(first_key, second_key, "no-op copy_to should preserve the custom piercing post-render key")
	TEST_ASSERT_EQUAL(character.custom_piercings_version, copied_version, "no-op copy_to should preserve the copied prefs version")

	test_prefs.custom_piercings_version += 1
	test_prefs.copy_to(character, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE)
	var/third_key = character.generate_custom_piercing_post_overlay_key()
	TEST_ASSERT_NOTEQUAL(second_key, third_key, "copied custom_piercings_version should participate in the render key")

	var/prefs_version_before_suppress = test_prefs.custom_piercings_version
	character.custom_piercing_post_render_suppressed = TRUE
	var/suppressed_key = character.generate_custom_piercing_post_overlay_key()
	TEST_ASSERT_NOTEQUAL(third_key, suppressed_key, "preview suppression should participate in the render key")
	TEST_ASSERT_EQUAL(test_prefs.custom_piercings_version, prefs_version_before_suppress, "preview suppression must not mutate prefs-side versioning")

	character.custom_piercing_post_render_suppressed = FALSE
	character.custom_piercing_preview_suppressed_target_key = custom_piercing_hybrid_target_key("custom_upper", 1)
	var/target_suppressed_key = character.generate_custom_piercing_post_overlay_key()
	TEST_ASSERT_NOTEQUAL(third_key, target_suppressed_key, "selected-entry preview suppression should participate in the render key")
	TEST_ASSERT_EQUAL(test_prefs.custom_piercings_version, prefs_version_before_suppress, "selected-entry preview suppression must not mutate prefs-side versioning")

/datum/unit_test/appearance_preview_custom_piercing_selected_entry_suppression/Run()
	var/list/locs = block(run_loc_bottom_left, run_loc_top_right)
	var/mob/living/carbon/human/consistent/character = allocate(/mob/living/carbon/human/consistent, pick(locs))
	TEST_ASSERT_NOTNULL(character, "test character should allocate")

	var/target_key = custom_piercing_hybrid_target_key("custom_upper", 2)
	character.custom_piercing_preview_suppressed_target_key = target_key

	TEST_ASSERT(custom_piercing_entry_is_preview_suppressed(character, "custom_upper", 2), "matching slot/index should be suppressed on preview dummies")
	TEST_ASSERT(!custom_piercing_entry_is_preview_suppressed(character, "custom_upper", 1), "non-selected entries in the same slot should stay visible")
	TEST_ASSERT(!custom_piercing_entry_is_preview_suppressed(character, "custom_lower", 2), "same index in a different slot should stay visible")

	character.custom_piercing_preview_suppressed_target_key = "custom_upper"
	TEST_ASSERT(!custom_piercing_entry_is_preview_suppressed(character, "custom_upper", 1), "slot-only legacy targets should not narrow-suppress an entry")

/datum/unit_test/appearance_preview_custom_piercing_props_sanitize/Run()
	var/list/defaults = default_custom_piercing_props()
	var/list/null_props = sanitize_custom_piercing_props(null)
	TEST_ASSERT_EQUAL(null_props["sx"], defaults["sx"], "null props should rebuild south-x from defaults")
	TEST_ASSERT_EQUAL(null_props["wabove"], defaults["wabove"], "null props should preserve default above-layer flags")

	var/list/raw = list(
		"sx" = 999,
		"sy" = -999,
		"sturn" = -90,
		"sflip" = 0,
		"sabove" = 5,
		"shide" = 0,
		"sshrink" = 9,
		"nx" = "bad",
		"mystery" = 42,
	)
	var/list/sanitized = sanitize_custom_piercing_props(raw)
	TEST_ASSERT_EQUAL(sanitized["sx"], CUSTOM_PIERCING_OFFSET_MAX, "x offsets should clamp high")
	TEST_ASSERT_EQUAL(sanitized["sy"], CUSTOM_PIERCING_OFFSET_MIN, "y offsets should clamp low")
	TEST_ASSERT_EQUAL(sanitized["sturn"], 270, "turn should normalize into the 0-359 range")
	TEST_ASSERT_EQUAL(sanitized["sflip"], 0, "falsey numeric flags should coerce to 0")
	TEST_ASSERT_EQUAL(sanitized["sabove"], 1, "truthy numeric flags should coerce to 1")
	TEST_ASSERT_EQUAL(sanitized["shide"], 0, "falsey numeric flags should stay hidden-off")
	TEST_ASSERT_EQUAL(sanitized["sshrink"], 4, "shrink should clamp to the maximum")
	TEST_ASSERT_EQUAL(sanitized["nx"], 0, "bad numeric text should fall back to 0")
	TEST_ASSERT_EQUAL(sanitized["wy"], defaults["wy"], "unspecified keys should preserve defaults")
	TEST_ASSERT_NULL(sanitized["mystery"], "unknown keys should be dropped from the output")

/datum/unit_test/appearance_preview_custom_piercing_entry_sanitize_rejects_arbitrary_payload/Run()
	var/list/cleaned = sanitize_custom_piercing_entry(list(
		"sticker" = "stud",
		"metal_color" = "#112233",
		"gem_color" = "#445566",
		"custom_name" = "Allowed name",
		"custom_desc" = "Allowed description",
		"zone" = "",
		"hide_when_covered" = 0,
		"props" = list(
			"sx" = 5,
			"canvas" = "bad nested prop",
		),
		"canvas" = list("pixels" = list(1, 2, 3)),
		"drawing" = "bad arbitrary payload",
		"icon_state" = "forged_state",
		"iconState" = "forgedState",
		"layers" = list(list("iconState" = "forged_layer")),
	))
	TEST_ASSERT_NOTNULL(cleaned, "known sticker entry should survive sanitizer")
	TEST_ASSERT_NULL(cleaned["canvas"], "entry sanitizer must drop arbitrary canvas payloads")
	TEST_ASSERT_NULL(cleaned["drawing"], "entry sanitizer must drop arbitrary drawing payloads")
	TEST_ASSERT_NULL(cleaned["icon_state"], "entry sanitizer must drop forged BYOND icon-state fields")
	TEST_ASSERT_NULL(cleaned["iconState"], "entry sanitizer must drop forged TGUI iconState fields")
	TEST_ASSERT_NULL(cleaned["layers"], "entry sanitizer must drop arbitrary overlay layer stacks")
	var/list/cleaned_props = cleaned["props"]
	TEST_ASSERT_NOTNULL(cleaned_props, "entry sanitizer should keep sanitized props")
	TEST_ASSERT_EQUAL(cleaned_props["sx"], 5, "known props should survive entry sanitization")
	TEST_ASSERT_NULL(cleaned_props["canvas"], "nested arbitrary prop keys should be dropped")
	TEST_ASSERT_NULL(sanitize_custom_piercing_entry(list("sticker" = "unknown_sticker")), "unknown stickers should be rejected before persistence")

/datum/unit_test/appearance_preview_intimate_accessory_offset_phase_one_scope/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	var/list/allowed_fields = test_prefs.get_intimate_accessory_offset_allowed_fields()
	TEST_ASSERT_EQUAL(allowed_fields.len, 2, "phase-one intimate accessory offsets should expose only x/y")
	TEST_ASSERT(APPEARANCE_PREVIEW_PROP_X in allowed_fields, "phase-one intimate accessory offsets should allow x")
	TEST_ASSERT(APPEARANCE_PREVIEW_PROP_Y in allowed_fields, "phase-one intimate accessory offsets should allow y")
	TEST_ASSERT(!(APPEARANCE_PREVIEW_PROP_TURN in allowed_fields), "phase-one intimate accessory offsets should defer turn")
	TEST_ASSERT(!(APPEARANCE_PREVIEW_PROP_FLIP in allowed_fields), "phase-one intimate accessory offsets should defer flip")
	TEST_ASSERT(!(APPEARANCE_PREVIEW_PROP_HIDE in allowed_fields), "phase-one intimate accessory offsets should defer hide")
	TEST_ASSERT(!(APPEARANCE_PREVIEW_PROP_SHRINK in allowed_fields), "phase-one intimate accessory offsets should defer shrink")
	TEST_ASSERT(!(APPEARANCE_PREVIEW_PROP_ABOVE in allowed_fields), "phase-one intimate accessory offsets should defer above")
	TEST_ASSERT(test_prefs.intimate_accessory_offset_field_is_allowed(APPEARANCE_PREVIEW_PROP_X), "x should validate through the helper")
	TEST_ASSERT(!test_prefs.intimate_accessory_offset_field_is_allowed(APPEARANCE_PREVIEW_PROP_TURN), "turn should fail validation through the helper")

	var/list/rows = test_prefs.get_intimate_accessory_offset_scope_data()
	TEST_ASSERT(rows.len >= 2, "scope data should include regular intimate accessory rows")

	var/list/genital_row
	var/list/breast_insertable_row
	for(var/list/row as anything in rows)
		if(row["key"] == "genital_piercing")
			genital_row = row
		if(row["key"] == "breast_insertable")
			breast_insertable_row = row

	TEST_ASSERT_NOTNULL(genital_row, "genital piercing row should be present")
	TEST_ASSERT_EQUAL(genital_row["offset_target_key"], "genital", "editable rows should expose the custom-piercing slot key as the offset target")
	TEST_ASSERT_EQUAL(genital_row["offset_editor_family"], APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS, "rows should identify the intimate accessory offset family")
	TEST_ASSERT_EQUAL(genital_row["offset_scope"], "phase_one_xy", "rows should document the phase-one x/y-only scope")
	var/list/genital_allowed = genital_row["offset_allowed_fields"]
	TEST_ASSERT_EQUAL(genital_allowed.len, 2, "editable rows should carry the x/y-only allowed field list")
	TEST_ASSERT(APPEARANCE_PREVIEW_PROP_X in genital_allowed, "editable row should allow x")
	TEST_ASSERT(APPEARANCE_PREVIEW_PROP_Y in genital_allowed, "editable row should allow y")

	TEST_ASSERT_NOTNULL(breast_insertable_row, "non-custom regular rows should still be present for UI context")
	TEST_ASSERT_EQUAL(breast_insertable_row["offset_editable"], FALSE, "rows without a custom slot key should not claim offset editor support")
	TEST_ASSERT_NULL(breast_insertable_row["offset_target_key"], "non-editable rows should not expose an offset target")

/datum/unit_test/appearance_preview_intimate_accessory_hybrid_descriptor/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	test_prefs.set_custom_piercing_slot_equipped_typepath("ear", /obj/item/intimate_accessory/piercing/ear/gold)

	var/list/descriptor = test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS, "ear", APPEARANCE_PREVIEW_DIR_KEY_S)
	TEST_ASSERT_NOTNULL(descriptor, "equipped intimate accessory target should resolve through the shared descriptor entrypoint")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_FAMILY], APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS, "descriptor should identify the intimate accessory offset family")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_TARGET_KEY], "ear", "descriptor should preserve the active intimate accessory target")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_MANIFEST_CATEGORY], APPEARANCE_PREVIEW_CATEGORY_INTIMATE_ACCESSORY, "regular intimate accessories should use the intimate accessory manifest category")
	TEST_ASSERT_EQUAL(descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_APPROXIMATE_COLOR], TRUE, "item tint is a guide-only approximation")

	var/list/allowed_fields = descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_ALLOWED_FIELDS]
	TEST_ASSERT_EQUAL(allowed_fields.len, 2, "phase-one descriptors should expose only x/y")
	TEST_ASSERT(APPEARANCE_PREVIEW_PROP_X in allowed_fields, "descriptor should allow x")
	TEST_ASSERT(APPEARANCE_PREVIEW_PROP_Y in allowed_fields, "descriptor should allow y")
	TEST_ASSERT(!(APPEARANCE_PREVIEW_PROP_TURN in allowed_fields), "descriptor should not expose advanced transforms")

	var/list/layers = descriptor[HYBRID_OFFSET_DESCRIPTOR_KEY_LAYERS]
	TEST_ASSERT_EQUAL(layers.len, 1, "regular intimate accessory descriptor should emit one server-resolved guide layer")
	var/list/layer = layers[1]
	TEST_ASSERT_EQUAL(layer[HYBRID_OFFSET_LAYER_KEY_ICON_STATE], "ear_pierce", "ear descriptor layer should use the server-resolved overlay state")
	TEST_ASSERT_EQUAL(layer[HYBRID_OFFSET_LAYER_KEY_ROLE], HYBRID_OFFSET_LAYER_ROLE_GUIDE, "regular accessory layer should be a guide layer")
	TEST_ASSERT_EQUAL(layer[HYBRID_OFFSET_LAYER_KEY_COLOR], "#C4B651", "guide layer should carry the selected item's metal color")

	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS, "unknown_slot", APPEARANCE_PREVIEW_DIR_KEY_S), "unknown intimate accessory targets should be rejected")
	TEST_ASSERT_NULL(test_prefs.build_hybrid_offset_descriptor(APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS, "nose", APPEARANCE_PREVIEW_DIR_KEY_S), "unequipped intimate accessory targets should not produce guide descriptors")

	qdel(test_prefs)

/datum/unit_test/appearance_preview_intimate_accessory_target_suppression/Run()
	var/list/locs = block(run_loc_bottom_left, run_loc_top_right)
	var/mob/living/carbon/human/consistent/character = allocate(/mob/living/carbon/human/consistent, pick(locs))
	TEST_ASSERT_NOTNULL(character, "test character should allocate")
	character.intimate_ear_piercing = new /obj/item/intimate_accessory/piercing/ear/gold(character)
	character.intimate_nose_piercing = new /obj/item/intimate_accessory/piercing/nose/silver(character)

	TEST_ASSERT_NOTNULL(character.intimate_ear_piercing, "test setup should equip an ear piercing")
	TEST_ASSERT_NOTNULL(character.intimate_nose_piercing, "test setup should equip a nose piercing")
	TEST_ASSERT(character.clear_intimate_accessory_offset_target("ear"), "valid intimate target should clear the matching preview item")
	TEST_ASSERT_NULL(character.intimate_ear_piercing, "targeted suppression should clear only the active ear piercing")
	TEST_ASSERT_NOTNULL(character.intimate_nose_piercing, "targeted suppression should not clear unrelated intimate accessories")
	TEST_ASSERT(!character.clear_intimate_accessory_offset_target("breast_insertable"), "non-offset targets should be rejected by preview suppression")

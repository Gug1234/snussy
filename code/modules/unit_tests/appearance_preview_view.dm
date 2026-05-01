/**
 * appearance_preview_view.dm — Step 12 unit tests for the Phase 1
 * live character preview port.
 *
 * Scope:
 *   - View lifecycle (construct + destroy leaves no dangling state).
 *   - Flag-gated no-flatten guarantee on `build_mannequin_previews`.
 *   - Prefs-side tab/editor invariants on slot switch.
 *   - Tab → family map shape validation.
 *
 * The lifecycle test intentionally does NOT call `create_body()` — the
 * dummy slot pool relies on subsystems not available at unit-test time
 * and would make the test flaky without adding coverage the structural
 * checks here already provide. The real dummy allocation path is
 * exercised by `appearance_preview_commit_paths` and by the
 * integration smoke in Step 13.
 */

// -----------------------------------------------------------------------------
// View lifecycle — construct + destroy.
// -----------------------------------------------------------------------------

/datum/unit_test/char_preview_creates_and_destroys_cleanly/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	var/atom/movable/screen/map_view/char_preview/view = new(null, test_prefs)

	TEST_ASSERT_NOTNULL(view, "view should construct")
	TEST_ASSERT_NOTNULL(view.assigned_map, "assigned_map id should be set by Initialize")
	TEST_ASSERT_EQUAL(view.preferences, test_prefs, "view should hold the owning prefs ref")
	TEST_ASSERT_EQUAL(view.active_editor_family, APPEARANCE_PREVIEW_FAMILY_NONE, "new view should start with no active family")
	TEST_ASSERT_NULL(view.active_editor_target_key, "new view should start without active target metadata")
	TEST_ASSERT_NULL(view.body, "body is not allocated until create_body() runs")

	QDEL_NULL(view)
	TEST_ASSERT_NULL(view, "QDEL_NULL should null the view reference")

// -----------------------------------------------------------------------------
// Flag-gated no-flatten guarantee.
//
// With APPEARANCE_PREVIEW_LEGACY_FLATTEN undefined (the target Phase 1 state),
// `build_mannequin_previews` must short-circuit to an empty list — no
// getFlatIcon, no icon2base64, no dummy checkout. When the flag is defined
// (current soak-cycle default) the legacy path is intentionally live and
// this assertion would be wrong; skip the check.
// -----------------------------------------------------------------------------

/datum/unit_test/char_preview_update_body_no_flatten/Run()
#ifdef APPEARANCE_PREVIEW_LEGACY_FLATTEN
	// Legacy flatten path still compiled — the no-flatten invariant is
	// a property of the new path only. Step 13's CI double-compile
	// validates the undefined-flag configuration.
	return
#else
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	// Use the commit-test stub subtype rather than `allocate(/datum/appearance_preview_editor, ...)`.
	// The base editor's New() takes no arguments, so passing the prefs
	// ref through the `allocate` varargs hits an "illegal use of
	// list2args() or named parameters" runtime. The stub inherits the
	// no-flatten short-circuit unchanged.
	var/datum/appearance_preview_editor/test_stub/editor = new(test_prefs)
	var/list/result = editor.build_mannequin_previews(null)
	TEST_ASSERT_NOTNULL(result, "build_mannequin_previews must never return null under the new path")
	TEST_ASSERT_EQUAL(result.len, 0, "build_mannequin_previews must return an empty list when the legacy flatten path is disabled")
	qdel(editor)
#endif

// -----------------------------------------------------------------------------
// Slot switch resets tab + active editor.
// -----------------------------------------------------------------------------

/datum/unit_test/prefs_change_slot_resets_tab/Run()
	var/datum/preferences/appearance_preview_test_prefs/test_prefs = new
	test_prefs.active_tab = APPEARANCE_PREVIEW_TAB_TAUR_OFFSETS
	// A bare datum stands in for the real editor — change_slot_reset_preview
	// must drop the reference without invoking _on_tab_exit (the old slot's
	// draft is meaningless against the new slot).
	test_prefs.active_editor = new /datum()

	test_prefs.change_slot_reset_preview()

	TEST_ASSERT_EQUAL(test_prefs.active_tab, APPEARANCE_PREVIEW_TAB_INFO, "slot switch must reset active_tab to Info")
	TEST_ASSERT_NULL(test_prefs.active_editor, "slot switch must clear active_editor")

// -----------------------------------------------------------------------------
// Tab → family map shape.
// -----------------------------------------------------------------------------

/datum/unit_test/prefs_tab_to_family_map_valid/Run()
	var/list/valid_tabs = GLOB.appearance_preview_valid_tabs
	var/list/valid_families = list(
		APPEARANCE_PREVIEW_FAMILY_NONE,
		APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS,
		APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS,
		APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS,
	)

	TEST_ASSERT_NOTNULL(GLOB.appearance_preview_tab_to_family, "tab→family map must exist")
	TEST_ASSERT(GLOB.appearance_preview_tab_to_family.len > 0, "tab→family map must be non-empty")

	for(var/tab_key in GLOB.appearance_preview_tab_to_family)
		TEST_ASSERT(tab_key in valid_tabs, "tab→family key [tab_key] must appear in appearance_preview_valid_tabs")
		var/family = GLOB.appearance_preview_tab_to_family[tab_key]
		TEST_ASSERT(family in valid_families, "tab→family value for [tab_key] must be a known APPEARANCE_PREVIEW_FAMILY_* constant")

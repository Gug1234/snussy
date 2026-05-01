/**
 * Shared commit contract + pipeline for appearance-preview editors.
 *
 * ## Contract (Step 12)
 *
 * Every editor commit goes through `appearance_preview_process_commit`,
 * which validates a standardised envelope before touching prefs:
 *
 *   {
 *     "editor_kind":    "<kind>",       // must match editor.editor_kind
 *     "pref_key":       "<key>",        // must match editor.pref_key
 *     "family_id":      "<family>",     // must match editor.family_id AND
 *                                       // be registered in
 *                                       // GLOB.appearance_preview_known_editor_families
 *     "revision_token": <int>,          // optional; if provided, must
 *                                       // match editor.revision_token
 *     "dirty":          <bool>,         // informational only
 *     "snapshot":       { ... }         // dispatched to editor._apply_snapshot
 *   }
 *
 * On success the pipeline persists once and refreshes the mannequin once,
 * bumps `editor.revision_token`, and writes the outcome into
 * `editor.last_commit_result`. On failure `last_commit_result` records the
 * error code and message; the editor's prefs are left untouched so the
 * client's draft remains recoverable.
 *
 * The legacy pref-only helper `appearance_preview_commit_character_preview`
 * and the two editor shims are retained for existing callers (notably the
 * Step 15 unit tests); they bypass envelope validation and must not be
 * used from the UI path.
 */

// Editor kind + family id constants are defined in
// `modular/code/datums/appearance_preview/_defines.dm` so they are visible to
// the editor .dm files, which are included earlier in `roguetown.dme`.

GLOBAL_LIST_INIT(appearance_preview_known_editor_families, list(
	APPEARANCE_PREVIEW_FAMILY_TAUR_OFFSETS,
	APPEARANCE_PREVIEW_FAMILY_CUSTOM_PIERCINGS,
	APPEARANCE_PREVIEW_FAMILY_INTIMATE_ACCESSORY_OFFSETS,
))

// --- Commit envelope keys ------------------------------------------------
//
// Keys and result codes are defined in
// `modular/code/datums/appearance_preview/_defines.dm` so they are visible
// to the unit tests and any future caller included earlier in the DME.

// --- Shared editor base type --------------------------------------------
//
// Concrete editors (`/datum/custom_piercing_editor`,
// `/datum/taur_genital_offset_editor`) set `parent_type` to this base so
// the pipeline can dispatch through a single typed surface. Subtypes
// override `editor_kind`, `pref_key`, `family_id`, `_apply_snapshot`, and
// `_persist`. All other state (`prefs`, `owning_client`, `rate_limiter`)
// remains owned by the subtype to keep this refactor minimally invasive.

/datum/appearance_preview_editor
	/// Preferences datum being edited. Subtypes set this in `New`.
	var/datum/preferences/prefs
	/// Stable editor kind identifier. Must match what the client sends.
	var/editor_kind
	/// Stable preference-key identifier. Used by the commit pipeline to
	/// reject envelopes pointed at the wrong editor.
	var/pref_key
	/// Adapter family this editor's previews come from. Validated against
	/// `GLOB.appearance_preview_known_editor_families` at commit time.
	var/family_id
	/// Monotonic revision counter. Bumped on every successful commit so a
	/// stale/retried commit envelope can be rejected.
	var/revision_token = 1
	/// Outcome of the most recent commit. Surfaced in `ui_data` so the
	/// client can surface errors and clear its dirty flag.
	var/list/last_commit_result
	/// Step 4 remediation (two-phase persist): subtype-interpreted deep-copy
	/// of the prefs fields this editor will mutate during `_apply_snapshot`.
	/// Taken before `_apply_snapshot` and used by `_revert_persist` to
	/// restore the in-memory state when `save_character()` fails. Cleared
	/// once the pipeline reaches its success or degraded-success tail.
	var/list/prefs_snapshot
	/// Step 4 remediation: in-memory buffer of sidecar writes staged by
	/// `_stage_persist` before `save_character()` runs. Each entry is a
	/// list with keys `"path"` (absolute sidecar path), `"bytes"` (string
	/// payload), and optional `"delete"` (TRUE to unlink the sidecar
	/// instead of writing). `_flush_persist` drains this after the main
	/// prefs save succeeds; `_revert_persist` discards it on failure so
	/// the sidecar can never race ahead of the main prefs file.
	var/list/pending_sidecars
#ifdef APPEARANCE_PREVIEW_LEGACY_FLATTEN
	/// Per-direction base64 PNG snapshots of the owning client's character,
	/// lazily populated by `build_mannequin_previews()`. Cached across
	/// ui_data passes because the render path is expensive (dummy mob
	/// setup + getFlatIcon × 4 dirs). Cleared via
	/// `invalidate_mannequin_cache()` when a commit lands so the next open
	/// reflects the saved state. Shape: `list("s" = <b64>, ...)` with
	/// missing directions simply absent.
	///
	/// Step 11: gated behind APPEARANCE_PREVIEW_LEGACY_FLATTEN. When the
	/// flag is undefined the live char_preview_view replaces this cache
	/// entirely; editors receive an empty list from build_mannequin_previews
	/// and the TSX MannequinBackdrop falls through to its no-mannequin path.
	var/list/cached_mannequin_previews
	/// ckey of the client whose mannequin is cached. Prevents a stale
	/// mannequin leaking across admin-driven editor reassignments.
	var/mannequin_cache_ckey
#endif

/// Abstract: subtypes must apply `snapshot` into `prefs` and return TRUE on
/// success. A FALSE return aborts the pipeline before any persist call so
/// the on-disk state stays consistent with the last successful commit.
/datum/appearance_preview_editor/proc/_apply_snapshot(list/snapshot)
	return FALSE

/// Push the shared appearance_preview bundle (manifest + sheet PNGs) to
/// the client when any editor TGUI window opens. The TSX side
/// (`useAppearancePreview()`) resolves `appearance_preview/manifest.json`
/// via `resolveAsset`, which only works after the asset datum has been
/// sent to that client. Every editor window that renders previews MUST
/// inherit this hook -- do not override it in subtypes unless you also
/// include the base bundle.
/datum/appearance_preview_editor/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/appearance_preview))

/**
 * Build per-direction base64-encoded PNG snapshots of the owning
 * client's character mannequin. The editors render these behind the
 * accessory preview tile so players can see the body part they are
 * editing in context.
 *
 * Return shape: `list("s" = <b64>, "n" = <b64>, "e" = <b64>, "w" = <b64>)`
 * — strictly the four cardinal keys used by the manifest. Missing or
 * failing directions are simply omitted; the TSX side treats an
 * absent entry as "no mannequin for this facing" and falls through to
 * the bare accessory.
 *
 * Mannequin generation is intentionally expensive (dummy mob setup,
 * overlay compile, icon extraction × 4 dirs) so the result is cached on
 * the editor datum. Subtypes override `_should_invalidate_mannequin()`
 * if their draft state can change what the mannequin should display;
 * the base contract is "generate once per window open, preserve across
 * a commit refresh" because the post-commit `update_preview_icon` pass
 * re-renders the classic character preview map and the TGUI mannequin
 * reflects the committed state from then on. Callers who need a live
 * preview-while-editing can call `invalidate_mannequin_cache()` on
 * user-visible draft changes; cost vs. fidelity trade-off is owned by
 * the subtype, not this base proc.
 */
/datum/appearance_preview_editor/proc/invalidate_mannequin_cache()
#ifdef APPEARANCE_PREVIEW_LEGACY_FLATTEN
	cached_mannequin_previews = null
	mannequin_cache_ckey = null
#endif
	return

/**
 * Hook: strip the editable body region from the mannequin so the preview
 * does not render a static (already-committed) copy of the part the user
 * is offsetting / tinting. Subtypes mutate the dummy in place; the base
 * update pass refreshes overlays so the stripped region is genuinely
 * absent from the per-direction snapshots.
 *
 * Intentionally no-op on the base -- editors that do not draw a movable
 * overlay (future read-only preview editors) want the full mannequin.
 */
/datum/appearance_preview_editor/proc/_strip_mannequin_for_preview(mob/living/carbon/human/dummy/mannequin)
	return

/datum/appearance_preview_editor/proc/build_mannequin_previews(mob/user)
#ifndef APPEARANCE_PREVIEW_LEGACY_FLATTEN
	// Step 11: live-preview path. The char_preview_view renders the
	// mannequin natively via a map_view screen; editor TSX reads the
	// `character_preview_view` ref from ui_static_data and falls through
	// to the no-mannequin render when mannequin_previews is empty.
	return list()
#else
	if(!prefs?.parent)
		return list()
	// `prefs.parent` is a /client (see /datum/preferences/var/client/parent).
	var/client/owning_client = prefs.parent
	var/ckey = owning_client.ckey
	if(islist(cached_mannequin_previews) && mannequin_cache_ckey == ckey)
		return cached_mannequin_previews

	// Refuse lobby previews: `update_preview_icon` itself short-circuits
	// for new-player lobby sessions (no body yet), so we mirror that
	// instead of crashing inside `copy_to`.
	if(owning_client.is_new_player())
		return list()

	var/mob/living/carbon/human/dummy/mannequin = generate_or_wait_for_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)
	if(!mannequin)
		return list()
	prefs.copy_to(mannequin, 1, TRUE, TRUE)
	if(owning_client.taur_genital_editor_instance && mannequin.sexcon)
		mannequin.sexcon.bottom_exposed = TRUE
	var/obj/item/organ/penis/preview_penis = mannequin.getorganslot(ORGAN_SLOT_PENIS)
	if(preview_penis)
		preview_penis.erect_state = prefs.preview_erect_state
	// Strip the part the editor is currently mutating. The mannequin is
	// the "context body" the player edits against; it must NOT contain
	// the part being offset or coloured, or the preview shows a static
	// doppelganger glued to the committed position while the editor's
	// live overlay hovers uncoupled next to it. Subtypes that own an
	// editable body region override `_strip_mannequin_for_preview` to
	// zero out that region before the per-direction snapshot pass.
	_strip_mannequin_for_preview(mannequin)
	mannequin.regenerate_clothes()
	mannequin.update_body()
	mannequin.update_hair()
	mannequin.update_body_parts(redraw = TRUE)
	mannequin.rebuild_obscured_flags()

	var/list/out = list()
	// Map cardinal BYOND constants to the manifest's string keys so the
	// TSX lookup (keyed by "s"/"n"/"e"/"w") resolves without a second
	// translation pass on the client.
	var/list/dir_key_by_byond = list(
		"[SOUTH]" = "s",
		"[NORTH]" = "n",
		"[EAST]" = "e",
		"[WEST]" = "w",
	)
	for(var/D in GLOB.cardinals)
		mannequin.setDir(D)
		mannequin.update_body_parts(redraw = TRUE)
		COMPILE_OVERLAYS(mannequin)
		var/icon/frame = getFlatIcon(mannequin, defdir = D, no_anim = TRUE)
		if(!frame)
			continue
		var/b64 = icon2base64(frame)
		if(!istext(b64) || !length(b64))
			continue
		out[dir_key_by_byond["[D]"]] = b64

	unset_busy_human_dummy(DUMMY_HUMAN_SLOT_PREFERENCES)

	cached_mannequin_previews = out
	mannequin_cache_ckey = ckey
	return out
#endif

/**
 * Step 4 remediation — two-phase persist hooks.
 *
 * Subtypes override `_capture_prefs_snapshot` / `_restore_prefs_snapshot`
 * to deep-copy (respectively restore) the prefs fields they mutate. The
 * base implementations are no-ops so editors with no mutable prefs state
 * (e.g. future read-only editors) work without ceremony.
 *
 * `_stage_persist` runs *before* `save_character()` and MUST NOT touch
 * disk — it fills `pending_sidecars` with `(path, bytes)` tuples. The
 * base flush then drains that buffer only after the main prefs file has
 * been written, guaranteeing the sidecar and main prefs file cannot
 * disagree across a save failure.
 *
 * `_flush_persist` returns TRUE on full success, FALSE if any sidecar
 * write reported a failure. A FALSE return surfaces as a degraded-
 * success code to the client; the commit is NOT rolled back because the
 * main prefs file is already the authoritative record.
 */
/datum/appearance_preview_editor/proc/_capture_prefs_snapshot()
	return

/datum/appearance_preview_editor/proc/_restore_prefs_snapshot()
	return

/datum/appearance_preview_editor/proc/_stage_persist()
	return TRUE

/datum/appearance_preview_editor/proc/_flush_persist()
	if(!islist(pending_sidecars) || !length(pending_sidecars))
		return TRUE
	var/all_ok = TRUE
	for(var/list/entry as anything in pending_sidecars)
		if(!islist(entry))
			all_ok = FALSE
			continue
		var/path = entry["path"]
		if(!istext(path) || !length(path))
			all_ok = FALSE
			continue
		if(entry["delete"])
			if(fexists(path))
				fdel(path)
			continue
		var/bytes = entry["bytes"]
		if(!istext(bytes))
			all_ok = FALSE
			continue
		// Write-temp-then-replace: a partial rustg_file_write on the final
		// path would leave a truncated sidecar on disk. Writing to `.tmp`
		// first and only clobbering the real path once the temp exists
		// keeps readers from ever seeing a half-written file.
		var/tmp_path = "[path].tmp"
		rustg_file_write(bytes, tmp_path)
		if(!fexists(tmp_path))
			all_ok = FALSE
			continue
		if(fexists(path))
			fdel(path)
		fcopy(tmp_path, path)
		fdel(tmp_path)
		if(!fexists(path))
			all_ok = FALSE
	pending_sidecars = null
	return all_ok

/datum/appearance_preview_editor/proc/_revert_persist()
	pending_sidecars = null
	_restore_prefs_snapshot()
	prefs_snapshot = null

/// Legacy back-compat: some callers (notably the Step 15 unit-test shims)
/// still invoke `_persist()` directly. Route them through the two-phase
/// pipeline so the new stage/flush contract is exercised even on that
/// path. Subtypes should NOT override this — override the two-phase
/// hooks instead.
/datum/appearance_preview_editor/proc/_persist()
	if(!_stage_persist())
		pending_sidecars = null
		return FALSE
	return _flush_persist()

// --- Pipeline helpers ----------------------------------------------------

/proc/appearance_preview_editor_manifest_metadata()
	return list(
		"appearance_preview_manifest_version" = APPEARANCE_PREVIEW_MANIFEST_VERSION,
		"appearance_preview_manifest_category_order" = GLOB.appearance_preview_manifest_category_order.Copy(),
		"appearance_preview_manifest_category_scopes" = GLOB.appearance_preview_manifest_category_scopes.Copy(),
	)

/// Returns the commit-envelope metadata every editor emits in `ui_data`.
/// The client echoes these values back on commit so the server can detect
/// a rogue or stale envelope.
/proc/appearance_preview_editor_commit_metadata(datum/appearance_preview_editor/editor)
	if(!editor)
		return list()
	return list(
		"commit_contract" = list(
			APPEARANCE_PREVIEW_COMMIT_KEY_EDITOR_KIND = editor.editor_kind,
			APPEARANCE_PREVIEW_COMMIT_KEY_PREF_KEY = editor.pref_key,
			APPEARANCE_PREVIEW_COMMIT_KEY_FAMILY_ID = editor.family_id,
			APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN = editor.revision_token,
		),
		"last_commit_result" = editor.last_commit_result,
	)

/proc/appearance_preview_refresh_character_preview(datum/preferences/prefs)
	if(!prefs)
		return FALSE
	prefs.update_preview_icon()
	return TRUE

/proc/appearance_preview_commit_character_preview(datum/preferences/prefs)
	if(!prefs)
		return FALSE
	if(!prefs.save_character())
		return FALSE
	appearance_preview_refresh_character_preview(prefs)
	return TRUE

/// Internal helper: records `code`/`message` on the editor, returns FALSE.
/// The editor's current `revision_token` is always echoed so a stale
/// response also tells the client what the server's current token is.
/proc/_appearance_preview_record_commit_failure(datum/appearance_preview_editor/editor, code, message)
	if(!editor)
		return FALSE
	editor.last_commit_result = list(
		"ok" = FALSE,
		"code" = code,
		"message" = message,
		APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN = editor.revision_token,
	)
	return FALSE

/**
 * Validated commit pipeline. Returns TRUE on success, FALSE on any
 * validation or persistence failure. Callers (editor `ui_act` handlers)
 * should return the boolean directly so TGUI auto-pushes updated `ui_data`
 * the client reads `last_commit_result` from that push to clear its dirty
 * flag or surface the error.
 *
 * Never throws. Every failure mode routes through
 * `_appearance_preview_record_commit_failure`, so the editor always has a
 * populated `last_commit_result` when this returns.
 */
/proc/appearance_preview_process_commit(datum/appearance_preview_editor/editor, list/params)
	if(!editor)
		return FALSE
	if(!editor.prefs)
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_NO_PREFS, "Editor has no preferences datum.")
	if(!islist(params))
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_ENVELOPE, "Missing commit envelope.")

	if(params[APPEARANCE_PREVIEW_COMMIT_KEY_EDITOR_KIND] != editor.editor_kind)
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_EDITOR_KIND, "Expected editor_kind [editor.editor_kind].")

	if(params[APPEARANCE_PREVIEW_COMMIT_KEY_PREF_KEY] != editor.pref_key)
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_PREF_KEY, "Expected pref_key [editor.pref_key].")

	var/incoming_family = params[APPEARANCE_PREVIEW_COMMIT_KEY_FAMILY_ID]
	if(incoming_family != editor.family_id)
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_FAMILY_ID, "Expected family_id [editor.family_id].")
	if(!appearance_preview_family_is_valid(incoming_family))
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_FAMILY_ID, "Unknown family_id [incoming_family].")

	var/incoming_token = params[APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN]
	if(!isnull(incoming_token))
		if(!isnum(incoming_token) || incoming_token != editor.revision_token)
			return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_STALE_REVISION, "Stale revision. Client sent [incoming_token]; server at [editor.revision_token].")

	var/list/snapshot = params[APPEARANCE_PREVIEW_COMMIT_KEY_SNAPSHOT]
	if(!islist(snapshot))
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_INVALID_SNAPSHOT, "Missing or malformed snapshot.")

	// --- Two-phase persist (Step 4 remediation) ---------------------------
	// Capture a deep-copy of the prefs fields this editor will mutate, so a
	// later `save_character()` failure can restore them without leaving the
	// in-memory state diverged from the on-disk prefs file.
	editor._capture_prefs_snapshot()

	if(!editor._apply_snapshot(snapshot))
		editor._revert_persist()
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_APPLY_FAILED, "Snapshot rejected by editor.")
	if(!editor._stage_persist())
		editor._revert_persist()
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_PERSIST_FAILED, "Editor-specific stage_persist failed.")
	if(!editor.prefs.save_character())
		// Main prefs file failed to write. Sidecars are still buffered in
		// `pending_sidecars` and have NOT touched disk, so reverting the
		// in-memory prefs state leaves the on-disk state fully coherent
		// with the last successful commit.
		editor._revert_persist()
		return _appearance_preview_record_commit_failure(editor, APPEARANCE_PREVIEW_COMMIT_ERR_PERSIST_FAILED, "save_character() failed.")

	// Main prefs file is now authoritative. Flush buffered sidecars.
	var/flush_ok = editor._flush_persist()
	editor.prefs_snapshot = null
	appearance_preview_refresh_character_preview(editor.prefs)
	// Mannequin preview is baked from prefs on the fly; invalidate the
	// cache so the next `ui_data` tick rebuilds the PNGs against the
	// newly-committed state.
	editor.invalidate_mannequin_cache()

	editor.revision_token += 1
	if(flush_ok)
		editor.last_commit_result = list(
			"ok" = TRUE,
			"code" = APPEARANCE_PREVIEW_COMMIT_OK,
			"message" = null,
			APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN = editor.revision_token,
		)
		return TRUE

	// Degraded-success tail: `save_character()` succeeded so the main prefs
	// file carries the new snapshot, but at least one sidecar write failed.
	// The client treats this as success (draft is NOT preserved — the user
	// cannot usefully retry the same commit since the main prefs already
	// advanced), but surfaces a banner so an admin can investigate. The
	// next successful commit re-stages and re-writes the sidecar.
	log_world("appearance_preview: degraded-success commit for editor_kind=[editor.editor_kind] pref_key=[editor.pref_key]: save_character succeeded but sidecar flush reported a failure")
	editor.last_commit_result = list(
		"ok" = TRUE,
		"code" = APPEARANCE_PREVIEW_COMMIT_DEGRADED_SIDECAR,
		"message" = "Commit saved, but a sidecar file failed to write. The next save will retry.",
		APPEARANCE_PREVIEW_COMMIT_KEY_REVISION_TOKEN = editor.revision_token,
	)
	return TRUE

// --- Legacy shims --------------------------------------------------------
//
// Retained so the Step 15 unit tests (code/modules/unit_tests/appearance_preview.dm)
// can drive commits without building a full envelope. These skip envelope
// validation, so they must not be called from the UI path and are compiled
// out of non-test builds to eliminate any chance of re-adoption.

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)
/proc/appearance_preview_commit_custom_piercing_editor(datum/custom_piercing_editor/editor)
	if(!editor?.prefs)
		return FALSE
	if(!editor._persist())
		return FALSE
	return appearance_preview_commit_character_preview(editor.prefs)

/proc/appearance_preview_commit_taur_genital_offset_editor(datum/taur_genital_offset_editor/editor)
	if(!editor?.prefs)
		return FALSE
	if(!editor._persist())
		return FALSE
	return appearance_preview_commit_character_preview(editor.prefs)
#endif

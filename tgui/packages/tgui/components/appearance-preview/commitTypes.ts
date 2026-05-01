/**
 * @file commitTypes.ts
 * @description Shared commit-envelope types for appearance-preview editors.
 *
 * One contract, consumed by both `TaurGenitalOffsetEditor` and
 * `CustomPiercingEditor` (and the `useCommitController` hook below them), so
 * the close-time commit race fix does not have to be reimplemented per-editor.
 *
 * These mirror the DM side of the Step 12 commit envelope exactly:
 *   - `CommitContract`: the pref/family/revision metadata echoed on every
 *     `commit` action.
 *   - `CommitResult` / `LastCommitResult`: the server-reported outcome
 *     envelope written to `ui_data.last_commit_result`.
 *   - `CommitIntent`: client-side tag driving close-safe tear-down.
 *   - `CommitStatus`: lifecycle state exposed to the UI by the controller.
 *
 * Keep this file free of React imports — it is shared by both TSX and pure
 * logic tests.
 */

/** Intent attached to a `requestCommit` call. */
export type CommitIntent = 'save' | 'close';

/** Lifecycle states surfaced by `useCommitController` to the UI. */
export type CommitStatus = 'idle' | 'committing' | 'error';

/** Metadata echoed back on every `commit` action (Step 12 contract). */
export interface CommitContract {
  editor_kind: string;
  pref_key: string;
  family_id: string;
  revision_token: number;
}

/** Server-reported commit outcome written to `ui_data.last_commit_result`. */
export interface CommitResult {
  ok: boolean;
  code: string;
  message: string | null;
  revision_token: number;
}

/** `ui_data.last_commit_result` is null before the first commit attempt. */
export type LastCommitResult = CommitResult | null;

/**
 * Controller-synthetic codes used when the server never produced a result
 * (timeout, busy). These never appear on the DM side; they exist so the
 * banner surface always has a stable code to render.
 */
export const COMMIT_CODE_TIMEOUT = 'CONTROLLER_TIMEOUT';
export const COMMIT_CODE_BUSY = 'CONTROLLER_BUSY';

/**
 * Server-originated degraded-success code from Step 4's two-phase persist.
 * The commit succeeded in memory + on the main prefs file, but a staged
 * sidecar flush failed. The draft MUST be treated as saved (main prefs is
 * authoritative), but the UI surfaces an amber banner so the user knows a
 * best-effort retry is pending. Mirrors
 * `APPEARANCE_PREVIEW_COMMIT_DEGRADED_SIDECAR` in `_defines.dm`.
 */
export const COMMIT_CODE_DEGRADED_SIDECAR = 'degraded_sidecar';

/** Default commit timeout in milliseconds. 10s matches spec §10. */
export const COMMIT_DEFAULT_TIMEOUT_MS = 10_000;

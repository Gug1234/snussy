/**
 * @file CommitController.tsx
 * @description Close-safe commit state machine for appearance-preview editors.
 *
 * ## Why this exists
 *
 * Before this controller each editor hand-rolled `setCommitting` +
 * `setCommitError` + `lastHandledCommitResult` tracking, and wired its Close
 * button to `act('commit'); act('close');` in sequence. That sequence is
 * fire-and-forget: TGUI tears the window down the instant `act('close')`
 * dispatches, so a server-side commit failure at Close time silently
 * discarded the user's draft.
 *
 * The controller below is the single source of truth for commit lifecycle
 * across both editors. Close with a dirty draft routes through
 * `requestCommit('close', snapshot)` and **only** dispatches the `close`
 * action after the server has reported `last_commit_result.ok === true`.
 * On failure the editor stays open, the banner shows the error, and the
 * draft is untouched.
 *
 * ## State machine
 *
 *   idle ──(requestCommit)──▶ committing
 *     committing ──(success)──▶ idle      [+ if intent==='close': act('close')]
 *     committing ──(failure)──▶ error
 *     committing ──(10s)───────▶ error     [timeout — no close dispatch]
 *     error    ──(requestCommit)──▶ committing   (retry path)
 *     error    ──(clearError)──▶ idle
 *
 * ## Concurrency guarantees
 *
 *  - At most one commit in flight per editor instance. A second
 *    `requestCommit` while `status === 'committing'` resolves immediately
 *    with a synthetic `CONTROLLER_BUSY` result and does **not** dispatch.
 *  - Each server result is consumed exactly once via a ref-equality guard
 *    against the previous `last_commit_result` object reference. TGUI
 *    produces a new object ref per ui_data push, so ref-equality is
 *    sufficient (no revision token counting required).
 *  - A 10s timeout converts a silently-lost server response into an error
 *    banner without dispatching `close`, preserving the "keep draft on
 *    failure" contract even across a server crash.
 *
 * ## Scale note (200-client worst case)
 *
 * The controller never polls and never sends per-keystroke traffic: the
 * only server traffic it originates is one `act('commit')` per explicit
 * Save/Close click. Under 200 concurrent editors that is bounded by user
 * input rate, not by React re-render rate.
 */

import { useCallback, useEffect, useRef, useState } from 'react';

import {
  COMMIT_CODE_BUSY,
  COMMIT_CODE_DEGRADED_SIDECAR,
  COMMIT_CODE_TIMEOUT,
  COMMIT_DEFAULT_TIMEOUT_MS,
  type CommitContract,
  type CommitIntent,
  type CommitResult,
  type CommitStatus,
  type LastCommitResult,
} from './commitTypes';

/** Minimal `act` shape — widening `useBackend<T>()['act']` would be overkill. */
type ActFn = (action: string, payload?: Record<string, unknown>) => void;

export interface UseCommitControllerArgs {
  /** TGUI `act` from the owning editor's `useBackend` call. */
  act: ActFn;
  /** Commit envelope metadata echoed back on every commit. */
  contract: CommitContract;
  /**
   * Latest `data.last_commit_result` from the editor's ui_data. Must be the
   * same object reference between ui_data pushes — TGUI already satisfies
   * this, but if the owner maps it into a new object per render the
   * controller will consume stale results repeatedly.
   */
  lastCommitResult: LastCommitResult;
  /**
   * Override for the close-dispatch. Defaults to `act('close')`. Exposed so
   * tests can assert the dispatch without touching the TGUI runtime.
   */
  closeDispatch?: () => void;
  /** Override for the 10s timeout (used by tests). */
  timeoutMs?: number;
}

export interface CommitController<TSnapshot> {
  /** Current lifecycle state — feed into `CommitBar` + banner rendering. */
  status: CommitStatus;
  /** Human-readable error message, or null when idle/committing. */
  error: string | null;
  /**
   * Human-readable warning message for a degraded-success commit (main
   * prefs persisted, but a staged sidecar flush failed). Orthogonal to
   * `error`: degraded commits are still `ok === true` from the server, so
   * the controller transitions to `idle` and clears the draft, but the
   * warning lingers on an amber banner until the next successful commit
   * replaces it or the caller explicitly clears it.
   */
  warning: string | null;
  /**
   * Dispatches `act('commit', envelope)` and resolves when the server
   * writes a matching `last_commit_result` or the 10s timeout fires.
   */
  requestCommit: (
    intent: CommitIntent,
    snapshot: TSnapshot,
  ) => Promise<CommitResult>;
  /** Transitions from `error` back to `idle` without touching the draft. */
  clearError: () => void;
  /** Clears the degraded-success warning banner. */
  clearWarning: () => void;
}

/**
 * Hook factory for the controller. See the file-level doc comment for the
 * full contract; inline notes below cover the non-obvious pieces.
 */
export function useCommitController<TSnapshot>(
  args: UseCommitControllerArgs,
): CommitController<TSnapshot> {
  const {
    act,
    contract,
    lastCommitResult,
    closeDispatch,
    timeoutMs = COMMIT_DEFAULT_TIMEOUT_MS,
  } = args;

  const [status, setStatus] = useState<CommitStatus>('idle');
  const [error, setError] = useState<string | null>(null);
  // Degraded-success banner is amber and coexists with `idle` status (the
  // commit DID succeed; the sidecar flush is what failed). Tracked on its
  // own axis so it doesn't fight the error/idle lifecycle.
  const [warning, setWarning] = useState<string | null>(null);

  /**
   * Seed the "last seen" ref with the current result so the very first
   * render does not consume a pre-existing commit outcome as if it were
   * our own. Subsequent ui_data pushes produce a new object ref and will
   * trip the effect below.
   */
  const lastSeenRef = useRef<LastCommitResult>(lastCommitResult);

  /**
   * The single in-flight request. Holding intent + resolver + timeout
   * together lets both the success/failure path and the timeout path
   * tear everything down atomically.
   */
  const pendingRef = useRef<{
    intent: CommitIntent;
    resolve: (result: CommitResult) => void;
    timeoutId: ReturnType<typeof setTimeout>;
  } | null>(null);

  // Keep `closeDispatch` callable from inside the effect without making it
  // a dependency that re-subscribes every render.
  const closeDispatchRef = useRef<() => void>(
    closeDispatch ?? (() => act('close')),
  );
  closeDispatchRef.current = closeDispatch ?? (() => act('close'));

  /**
   * Consume each new `last_commit_result` exactly once. Ref-equality is the
   * correct de-dupe key here: TGUI pushes ui_data as a new object tree per
   * frame, so a new result => new ref, and an unchanged result keeps the
   * previous ref. Revision tokens are intentionally not used — they would
   * force a spurious consume on any unrelated ui_data push whose result
   * already happens to match the latest revision.
   */
  useEffect(() => {
    if (lastCommitResult === lastSeenRef.current) return;
    lastSeenRef.current = lastCommitResult;
    const pending = pendingRef.current;
    if (!pending || !lastCommitResult) return;

    clearTimeout(pending.timeoutId);
    pendingRef.current = null;

    if (lastCommitResult.ok) {
      setStatus('idle');
      setError(null);
      // Degraded-success: main prefs persisted but a sidecar flush failed.
      // Hoist an amber warning; the draft is still cleared by the caller
      // because the main prefs file is authoritative (Step 4 pipeline).
      if (lastCommitResult.code === COMMIT_CODE_DEGRADED_SIDECAR) {
        setWarning(
          lastCommitResult.message ??
            'Saved, but a secondary file could not be written. The server will retry on the next commit.',
        );
      } else {
        setWarning(null);
      }
      if (pending.intent === 'close') {
        // Only dispatch close AFTER the server confirmed persistence.
        closeDispatchRef.current();
      }
    } else {
      setStatus('error');
      setError(lastCommitResult.message ?? lastCommitResult.code);
    }

    pending.resolve(lastCommitResult);
  }, [lastCommitResult]);

  const requestCommit = useCallback(
    (intent: CommitIntent, snapshot: TSnapshot): Promise<CommitResult> => {
      // Reject re-entrancy. Two Saves in flight would race for the single
      // `last_commit_result` slot and one of them would be silently lost.
      if (pendingRef.current) {
        return Promise.resolve({
          ok: false,
          code: COMMIT_CODE_BUSY,
          message: 'A commit is already in flight.',
          revision_token: contract.revision_token,
        });
      }

      setStatus('committing');
      setError(null);

      return new Promise<CommitResult>((resolve) => {
        const timeoutId = setTimeout(() => {
          // The server never answered. Surface a timeout error but do NOT
          // dispatch close — the draft must remain recoverable.
          if (
            pendingRef.current &&
            pendingRef.current.timeoutId === timeoutId
          ) {
            pendingRef.current = null;
            setStatus('error');
            setError(
              'Commit timed out — your draft has been preserved. Please try again.',
            );
            resolve({
              ok: false,
              code: COMMIT_CODE_TIMEOUT,
              message: 'Commit timed out.',
              revision_token: contract.revision_token,
            });
          }
        }, timeoutMs);

        pendingRef.current = { intent, resolve, timeoutId };

        act('commit', {
          editor_kind: contract.editor_kind,
          pref_key: contract.pref_key,
          family_id: contract.family_id,
          revision_token: contract.revision_token,
          dirty: true,
          snapshot,
        });
      });
    },
    [act, contract, timeoutMs],
  );

  const clearError = useCallback(() => {
    setStatus((prev) => (prev === 'error' ? 'idle' : prev));
    setError(null);
  }, []);

  const clearWarning = useCallback(() => {
    setWarning(null);
  }, []);

  // Belt-and-suspenders: if the component unmounts while a commit is in
  // flight (edge case — TGUI normally doesn't allow this without close),
  // cancel the timeout so it cannot fire against a dead setState.
  useEffect(
    () => () => {
      if (pendingRef.current) {
        clearTimeout(pendingRef.current.timeoutId);
        pendingRef.current = null;
      }
    },
    [],
  );

  return { status, error, warning, requestCommit, clearError, clearWarning };
}

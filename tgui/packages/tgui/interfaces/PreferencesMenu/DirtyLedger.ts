/**
 * @file DirtyLedger.ts
 * @description Client-side dirty-write store for the PreferencesMenu
 * (Step 8).
 *
 * Architecture:
 *   - Module-level singleton (one ledger per TGUI window). The shell
 *     mounts exactly one PreferencesMenu, so cross-instance bleed is a
 *     non-concern; the singleton keeps the React surface lean and lets
 *     non-React code (debounce timers) reach the same state.
 *   - React surface via {@link useDirtyLedger}, which subscribes to
 *     change notifications through `useSyncExternalStore` and proxies
 *     mutator calls to the singleton.
 *   - Server contract:
 *       - Autosave keys (text/multi-option) dispatch as
 *         `act('set_pref', { key, value })` on debounce expiry
 *         (~1500 ms after the last `stage()` call for that key).
 *       - Non-autosave keys accumulate until the user explicitly hits
 *         Save, at which point {@link flushBatch} chunks them into
 *         one or more `act('commit', { pairs: [...] })` calls capped at
 *         {@link COMMIT_BATCH_MAX} (32) keys per call to match the
 *         server's `PREFS_COMMIT_BATCH_MAX`.
 *       - Discard clears all pending values and dispatches
 *         `act('discard')`; the server reloads the slot.
 *
 * Performance:
 *   - O(1) stage / hasPending / flush enqueue.
 *   - One Map<string, Entry> + one Map<string, timer> at steady state;
 *     no allocation on hot paths beyond debounce-timer reuse.
 *   - drain() resolves immediately when nothing is in-flight, so the
 *     bottom-bar Join-flow (Step 15) pays zero cost in the common case.
 *
 * NOT in scope for Step 8:
 *   - Retry-on-failure UI (red banner): server already preserves
 *     dirty_keys on persist failure (§4.3); a future polish step wires
 *     the toast.
 *   - Per-key conflict resolution against incoming `ui_data` snapshots:
 *     the server is authoritative; pending values shadow snapshot reads
 *     in the bodies until commit ack lands and the snapshot updates.
 */

import { useEffect, useSyncExternalStore } from 'react';

import { useBackend } from '../../backend';

/** Mirrors PREFS_COMMIT_BATCH_MAX in code/__DEFINES/preferences_tgui.dm. */
export const COMMIT_BATCH_MAX = 32;

/** Default autosave debounce (ms) per spec §4.3. */
export const AUTOSAVE_DEBOUNCE_MS = 1500;

/** Default drain timeout (ms) used by the bottom-bar Join flow (§15). */
export const DEFAULT_DRAIN_TIMEOUT_MS = 1500;

/** Server `act` signature, kept narrow to the envelopes the ledger emits. */
type LedgerAct = (action: string, payload?: Record<string, unknown>) => void;

/** Optional staging hint used to opt a key into the autosave path. */
export interface StageOptions {
  /**
   * Mark this key as autosave-eligible. Autosave keys are flushed on
   * a per-key debounce timer and never participate in the
   * Save/Discard modal gate.
   */
  autosave?: boolean;
}

interface LedgerEntry {
  pendingValue: unknown;
  autosave: boolean;
}

interface PendingDrain {
  resolve: () => void;
  reject: (err: Error) => void;
  timer: ReturnType<typeof setTimeout> | null;
}

/* -------------------------------------------------------------------------- */
/* Singleton state                                                            */
/* -------------------------------------------------------------------------- */

const entries = new Map<string, LedgerEntry>();
const debounceTimers = new Map<string, ReturnType<typeof setTimeout>>();
const subscribers = new Set<() => void>();
const pendingDrains: PendingDrain[] = [];

let dispatcher: LedgerAct | null = null;
let inFlightCount = 0;

/** Bumped on every observable state change so useSyncExternalStore notices. */
let revision = 0;

function notify(): void {
  revision++;
  for (const sub of subscribers) {
    sub();
  }
}

function getRevision(): number {
  return revision;
}

function subscribe(cb: () => void): () => void {
  subscribers.add(cb);
  return () => {
    subscribers.delete(cb);
  };
}

/**
 * Update the act dispatcher. Called once per render of the consuming
 * hook so the ledger always holds the current backend's `act` and
 * never goes stale across HMR or remounts.
 */
function setDispatcher(act: LedgerAct | null): void {
  dispatcher = act;
}

/**
 * Resolve any drains whose pending count just reached zero.
 *
 * Called whenever a flush completes (synchronously, since BYOND ui_act
 * is fire-and-forget — there is no server ack callback). Treating the
 * dispatch itself as "done" matches how the existing intimate-prefs
 * flush flows handle it.
 */
function maybeResolveDrains(): void {
  if (inFlightCount > 0 || entries.size === 0) {
    // Either still draining, or no work pending.
    if (inFlightCount === 0) {
      while (pendingDrains.length > 0) {
        const d = pendingDrains.shift();
        if (!d) break;
        if (d.timer) clearTimeout(d.timer);
        d.resolve();
      }
    }
  }
}

/* -------------------------------------------------------------------------- */
/* Mutators                                                                   */
/* -------------------------------------------------------------------------- */

/**
 * Stage a pending write. Autosave keys schedule a debounced
 * `set_pref`; non-autosave keys accumulate for the next
 * {@link flushBatch}.
 *
 * @param key  PREF_KEY_* string token; must match a server allow-list entry.
 * @param value Post-validation client value. The server validator runs
 *              again authoritatively.
 * @param opts Optional staging hints (see {@link StageOptions}).
 */
function stage(key: string, value: unknown, opts: StageOptions = {}): void {
  const autosave = opts.autosave === true;
  entries.set(key, { pendingValue: value, autosave });

  if (autosave) {
    const existing = debounceTimers.get(key);
    if (existing) {
      clearTimeout(existing);
    }
    const timer = setTimeout(() => {
      debounceTimers.delete(key);
      flushAutosaveKey(key);
    }, AUTOSAVE_DEBOUNCE_MS);
    debounceTimers.set(key, timer);
  }

  notify();
}

/**
 * Send a single autosave key as `set_pref`. Pulled out so the timer
 * callback stays tiny and so test harnesses can force-flush a key
 * without waiting for the debounce.
 */
function flushAutosaveKey(key: string): void {
  const entry = entries.get(key);
  if (!entry || !dispatcher) {
    return;
  }
  entries.delete(key);
  inFlightCount++;
  try {
    dispatcher('set_pref', { key, value: entry.pendingValue });
  } finally {
    // BYOND ui_act is fire-and-forget; no ack callback exists, so the
    // act of dispatching counts as "in-flight resolved" for drain
    // purposes. The server's own dirty_keys preserves on-failure
    // recovery.
    inFlightCount--;
    maybeResolveDrains();
  }
  notify();
}

/**
 * Flush all currently-staged keys via one or more `commit` envelopes.
 * Autosave keys are included in the batch (and their pending debounce
 * timers cancelled) so an explicit Save commits everything visible.
 */
function flushBatch(): void {
  if (entries.size === 0 || !dispatcher) {
    return;
  }
  // Cancel any pending autosave debounces — they'd otherwise re-fire
  // for keys we are about to commit synchronously.
  for (const [, timer] of debounceTimers) {
    clearTimeout(timer);
  }
  debounceTimers.clear();

  const pairs: Array<{ key: string; value: unknown }> = [];
  for (const [key, entry] of entries) {
    pairs.push({ key, value: entry.pendingValue });
  }
  entries.clear();

  // Chunk to honor the server's PREFS_COMMIT_BATCH_MAX cap.
  for (let i = 0; i < pairs.length; i += COMMIT_BATCH_MAX) {
    const slice = pairs.slice(i, i + COMMIT_BATCH_MAX);
    inFlightCount++;
    try {
      dispatcher('commit', { pairs: slice });
    } finally {
      inFlightCount--;
    }
  }
  maybeResolveDrains();
  notify();
}

/**
 * Drop all staged values and tell the server to reload the slot.
 * Cancels every outstanding debounce so a stale autosave can't sneak
 * in after the discard.
 */
function discardAll(): void {
  for (const [, timer] of debounceTimers) {
    clearTimeout(timer);
  }
  debounceTimers.clear();
  const had = entries.size > 0;
  entries.clear();
  if (dispatcher) {
    dispatcher('discard');
  }
  if (had) {
    notify();
  }
  maybeResolveDrains();
}

/* -------------------------------------------------------------------------- */
/* Read-side                                                                  */
/* -------------------------------------------------------------------------- */

/**
 * @param includeAutosave When true, autosave keys count toward the
 *   "dirty" verdict. Defaults to false because autosave keys are
 *   explicitly excluded from the Save/Discard modal trigger per
 *   spec §4.3 ("DirtyModal does not fire for autosave keys").
 */
function hasPending(includeAutosave = false): boolean {
  if (entries.size === 0) {
    return false;
  }
  if (includeAutosave) {
    return true;
  }
  for (const [, entry] of entries) {
    if (!entry.autosave) {
      return true;
    }
  }
  return false;
}

/** Return the pending value for `key`, or `undefined` if not staged. */
function peek(key: string): unknown {
  return entries.get(key)?.pendingValue;
}

/**
 * Wait until no commits / autosaves are in flight. Resolves
 * immediately when idle. Rejects with `Error('drain_timeout')` if the
 * deadline elapses without reaching idle — the bottom-bar Join flow
 * surfaces this as the save-failed banner per spec §4.3 / §15.
 */
function drain(timeoutMs: number = DEFAULT_DRAIN_TIMEOUT_MS): Promise<void> {
  if (inFlightCount === 0 && entries.size === 0) {
    return Promise.resolve();
  }
  return new Promise<void>((resolve, reject) => {
    const drainHandle: PendingDrain = {
      resolve,
      reject,
      timer: null,
    };
    if (timeoutMs > 0) {
      drainHandle.timer = setTimeout(() => {
        const idx = pendingDrains.indexOf(drainHandle);
        if (idx >= 0) {
          pendingDrains.splice(idx, 1);
        }
        reject(new Error('drain_timeout'));
      }, timeoutMs);
    }
    pendingDrains.push(drainHandle);
  });
}

/* -------------------------------------------------------------------------- */
/* React surface                                                              */
/* -------------------------------------------------------------------------- */

/**
 * Hook returning the ledger's mutator/reader surface. The returned
 * shape is referentially stable across re-renders for callbacks
 * (the methods are module-level functions); only `revision` is the
 * subscription trigger.
 */
export interface DirtyLedgerHandle {
  /** See {@link stage}. */
  stage: typeof stage;
  /** See {@link flushBatch}. */
  flushBatch: typeof flushBatch;
  /** See {@link discardAll}. */
  discardAll: typeof discardAll;
  /** See {@link hasPending}. */
  hasPending: typeof hasPending;
  /** See {@link peek}. */
  peek: typeof peek;
  /** See {@link drain}. */
  drain: typeof drain;
  /** Monotonic revision; consumers can compare for snapshot diffing. */
  revision: number;
}

/**
 * Subscribe a React component to the ledger. Components that need to
 * re-render when pending state changes (TopBar, modal gate, body
 * fields wanting to show their staged value) call this; components
 * that only mutate (autosave inputs in steady state) can call
 * {@link getLedger} instead to avoid the subscription cost.
 */
export function useDirtyLedger(): DirtyLedgerHandle {
  const { act } = useBackend<{
    /* shape unused here */
  }>();
  // Keep the singleton's dispatcher pointing at the current act on
  // every render. useEffect avoids touching React state during render.
  useEffect(() => {
    setDispatcher(act as LedgerAct);
    return () => {
      // Don't null out the dispatcher on unmount — stage() called
      // from a body unmount cleanup (e.g. blur during navigation)
      // still needs a valid dispatcher for the trailing autosave.
    };
  }, [act]);

  const rev = useSyncExternalStore(subscribe, getRevision, getRevision);
  return {
    stage,
    flushBatch,
    discardAll,
    hasPending,
    peek,
    drain,
    revision: rev,
  };
}

/**
 * Non-subscribing accessor for the ledger surface. Use from event
 * handlers and timers that mutate but never need to re-render the
 * caller (e.g. the BottomBar Join handler in Step 15).
 */
export function getLedger(): Omit<DirtyLedgerHandle, 'revision'> {
  return { stage, flushBatch, discardAll, hasPending, peek, drain };
}

/**
 * Test/HMR hook: wipe all ledger state. NOT exported through
 * `useDirtyLedger` because production code never needs it.
 */
export function __resetDirtyLedger(): void {
  for (const [, timer] of debounceTimers) {
    clearTimeout(timer);
  }
  debounceTimers.clear();
  entries.clear();
  inFlightCount = 0;
  while (pendingDrains.length > 0) {
    const d = pendingDrains.shift();
    if (!d) break;
    if (d.timer) clearTimeout(d.timer);
    d.reject(new Error('ledger_reset'));
  }
  notify();
}

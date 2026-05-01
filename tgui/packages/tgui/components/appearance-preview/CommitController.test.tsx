/**
 * @file CommitController.test.tsx
 * @description Remediation Step 10 regression coverage for the close-safe
 * commit controller. Validates the four properties the Step 1 plan
 * called out:
 *
 *   1. `requestCommit('close')` does NOT dispatch `act('close')` before the
 *      server reports success.
 *   2. A failing close-intent commit leaves the draft intact (no close
 *      dispatch, status transitions to `error`, banner text exposed).
 *   3. A re-entrant commit while one is in flight resolves synchronously
 *      with the `CONTROLLER_BUSY` synthetic code without dispatching.
 *   4. A timeout with no server response surfaces the timeout banner and
 *      never dispatches close, preserving the draft.
 *
 * ## Test harness
 *
 * Happy-dom + react-dom/client give us a real DOM to render into. We use
 * a tiny `<Harness>` component that calls `useCommitController` and
 * writes the latest controller reference into a mutable slot so tests can
 * invoke `requestCommit` and re-render with a fresh `lastCommitResult`.
 *
 * React 19's `act(fn)` is the correct synchronisation primitive for
 * driving state + effect flushes. All timers use real `setTimeout` and a
 * short override of the default 10s controller timeout so the timeout
 * test runs in <50 ms.
 */

import { afterEach, beforeEach, describe, expect, it } from 'bun:test';
import { act, type ReactElement } from 'react';
import { createRoot, type Root } from 'react-dom/client';

import { type CommitController, useCommitController } from './CommitController';
import {
  COMMIT_CODE_BUSY,
  COMMIT_CODE_DEGRADED_SIDECAR,
  COMMIT_CODE_TIMEOUT,
  type CommitContract,
  type CommitResult,
  type LastCommitResult,
} from './commitTypes';

// ── Harness ─────────────────────────────────────────────────────────────────

interface ControllerSlot {
  /** Live controller reference. Refreshed on every render. */
  controller: CommitController<Record<string, unknown>> | null;
  /** Recorded `act(...)` dispatches so tests can assert call ordering. */
  acts: { action: string; payload?: Record<string, unknown> }[];
  /** Count of `closeDispatch` invocations. Incremented by the override. */
  closeCount: number;
}

interface HarnessProps {
  slot: ControllerSlot;
  contract: CommitContract;
  lastCommitResult: LastCommitResult;
  /** Short timeout used by the timeout-path test. */
  timeoutMs?: number;
}

function Harness(props: HarnessProps): ReactElement {
  const { slot, contract, lastCommitResult, timeoutMs } = props;
  const controller = useCommitController<Record<string, unknown>>({
    act: (action, payload) => {
      slot.acts.push({ action, payload });
    },
    contract,
    lastCommitResult,
    closeDispatch: () => {
      slot.closeCount += 1;
    },
    timeoutMs,
  });
  // Publish the controller ref after each render so the test can reach
  // `requestCommit` / `clearError`.
  slot.controller = controller;
  return null as unknown as ReactElement;
}

// ── Shared fixture plumbing ─────────────────────────────────────────────────

const BASE_CONTRACT: CommitContract = {
  editor_kind: 'custom_piercing',
  pref_key: 'test_pref',
  family_id: 'custom_piercings',
  revision_token: 7,
};

interface Mounted {
  root: Root;
  slot: ControllerSlot;
  setProps: (patch: Partial<HarnessProps>) => Promise<void>;
  unmount: () => void;
}

/**
 * Mount the harness into a fresh DOM container and return helpers that
 * update its props + tear it down. Every prop update runs inside `act`
 * so React flushes state + effects before control returns.
 */
async function mountHarness(
  initial: Omit<HarnessProps, 'slot'>,
): Promise<Mounted> {
  const container = document.createElement('div');
  document.body.appendChild(container);
  const root = createRoot(container);
  const slot: ControllerSlot = {
    controller: null,
    acts: [],
    closeCount: 0,
  };
  let currentProps: HarnessProps = { ...initial, slot };
  await act(async () => {
    root.render(<Harness {...currentProps} />);
  });
  const setProps = async (patch: Partial<HarnessProps>): Promise<void> => {
    currentProps = { ...currentProps, ...patch };
    await act(async () => {
      root.render(<Harness {...currentProps} />);
    });
  };
  const unmount = () => {
    act(() => {
      root.unmount();
    });
    container.remove();
  };
  return { root, slot, setProps, unmount };
}

/**
 * Flush pending microtasks + a short real-time delay so timer-driven
 * paths (controller timeout) fire inside the caller's `act` scope.
 */
async function flushTimers(ms: number): Promise<void> {
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, ms));
  });
}

let mounted: Mounted | null = null;
afterEach(() => {
  if (mounted) {
    mounted.unmount();
    mounted = null;
  }
});

// ── Tests ───────────────────────────────────────────────────────────────────

describe('useCommitController close-intent lifecycle', () => {
  it('does not dispatch close until the server confirms success', async () => {
    mounted = await mountHarness({
      contract: BASE_CONTRACT,
      lastCommitResult: null,
    });
    const { slot, setProps } = mounted;

    // Kick off a close-intent commit. The controller should synchronously
    // dispatch `commit` but NOT `close` until the server result lands.
    let resultPromise!: Promise<CommitResult>;
    await act(async () => {
      resultPromise = slot.controller!.requestCommit('close', {
        sample: 'payload',
      });
    });
    expect(slot.acts.map((a) => a.action)).toEqual(['commit']);
    expect(slot.closeCount).toBe(0);
    expect(slot.controller!.status).toBe('committing');

    // Server pushes a successful result. Controller consumes it via the
    // ref-equality guard, transitions to idle, and dispatches close.
    await setProps({
      lastCommitResult: {
        ok: true,
        code: 'ok',
        message: null,
        revision_token: 8,
      },
    });
    const result = await resultPromise;
    expect(result.ok).toBe(true);
    expect(slot.controller!.status).toBe('idle');
    expect(slot.controller!.error).toBeNull();
    expect(slot.closeCount).toBe(1);
  });

  it('preserves the draft when a close-intent commit fails', async () => {
    mounted = await mountHarness({
      contract: BASE_CONTRACT,
      lastCommitResult: null,
    });
    const { slot, setProps } = mounted;

    let resultPromise!: Promise<CommitResult>;
    await act(async () => {
      resultPromise = slot.controller!.requestCommit('close', {
        sample: 'payload',
      });
    });

    // Server rejects. Controller must transition to `error`, expose the
    // server message, and crucially NOT dispatch close — the window stays
    // open so the user can correct and retry.
    await setProps({
      lastCommitResult: {
        ok: false,
        code: 'validation_failed',
        message: 'Slot cannot be empty.',
        revision_token: 7,
      },
    });
    const result = await resultPromise;
    expect(result.ok).toBe(false);
    expect(result.code).toBe('validation_failed');
    expect(slot.controller!.status).toBe('error');
    expect(slot.controller!.error).toBe('Slot cannot be empty.');
    expect(slot.closeCount).toBe(0);
  });

  it('rejects a re-entrant commit with CONTROLLER_BUSY and does not dispatch', async () => {
    mounted = await mountHarness({
      contract: BASE_CONTRACT,
      lastCommitResult: null,
    });
    const { slot } = mounted;

    let firstPromise!: Promise<CommitResult>;
    let secondPromise!: Promise<CommitResult>;
    await act(async () => {
      firstPromise = slot.controller!.requestCommit('save', {});
      secondPromise = slot.controller!.requestCommit('save', {});
    });

    // Only one commit hit the server; the second resolved locally.
    expect(slot.acts.length).toBe(1);
    const second = await secondPromise;
    expect(second.ok).toBe(false);
    expect(second.code).toBe(COMMIT_CODE_BUSY);
    // Controller is still waiting on the first result; status stays
    // `committing` until the server responds (or the test tears down).
    expect(slot.controller!.status).toBe('committing');
    // Keep firstPromise alive so the timeout does not fire during teardown.
    void firstPromise;
  });

  it('times out with CONTROLLER_TIMEOUT without dispatching close', async () => {
    mounted = await mountHarness({
      contract: BASE_CONTRACT,
      lastCommitResult: null,
      timeoutMs: 20,
    });
    const { slot } = mounted;

    let promise!: Promise<CommitResult>;
    await act(async () => {
      promise = slot.controller!.requestCommit('close', { sample: 'v' });
    });
    await flushTimers(40);
    const result = await promise;
    expect(result.ok).toBe(false);
    expect(result.code).toBe(COMMIT_CODE_TIMEOUT);
    expect(slot.controller!.status).toBe('error');
    // Close must not dispatch on timeout — the draft must stay recoverable.
    expect(slot.closeCount).toBe(0);
  });
});

describe('useCommitController save-intent lifecycle', () => {
  it('clears the dirty banner on a save-intent success without closing', async () => {
    mounted = await mountHarness({
      contract: BASE_CONTRACT,
      lastCommitResult: null,
    });
    const { slot, setProps } = mounted;

    let promise!: Promise<CommitResult>;
    await act(async () => {
      promise = slot.controller!.requestCommit('save', { x: 1 });
    });
    await setProps({
      lastCommitResult: {
        ok: true,
        code: 'ok',
        message: null,
        revision_token: 8,
      },
    });
    const result = await promise;
    expect(result.ok).toBe(true);
    expect(slot.closeCount).toBe(0);
    expect(slot.controller!.status).toBe('idle');
  });

  it('exposes the degraded-success warning without blocking close', async () => {
    mounted = await mountHarness({
      contract: BASE_CONTRACT,
      lastCommitResult: null,
    });
    const { slot, setProps } = mounted;

    let promise!: Promise<CommitResult>;
    await act(async () => {
      promise = slot.controller!.requestCommit('close', { x: 1 });
    });
    await setProps({
      lastCommitResult: {
        ok: true,
        code: COMMIT_CODE_DEGRADED_SIDECAR,
        message: 'sidecar flush failed; retry queued',
        revision_token: 8,
      },
    });
    const result = await promise;
    // Degraded success: main prefs persisted → close still dispatches,
    // but the amber warning banner text is exposed for the shell.
    expect(result.ok).toBe(true);
    expect(result.code).toBe(COMMIT_CODE_DEGRADED_SIDECAR);
    expect(slot.closeCount).toBe(1);
    expect(slot.controller!.status).toBe('idle');
    expect(slot.controller!.warning).toBe('sidecar flush failed; retry queued');
  });
});

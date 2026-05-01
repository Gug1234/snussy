/**
 * @file BottomBar.tsx
 * @description Persistent bottom bar for the PreferencesMenu shell
 * (Step 15). Hosts the round-entry flows — Join Game / Observe /
 * Join Migrant Wave — so players don't have to close the prefs
 * window to commit to a round.
 *
 * Hidden when `data.standalone === 1` so admins VV-ing a target's
 * prefs never see join/observe controls.
 *
 * Action dispatch:
 *   - Each button calls `act('prefs_action', { action, ... })` which
 *     routes through the disjoint `GLOB.prefs_action_table` on the
 *     server (NOT `prefs_setter_table`). This is the sole client-side
 *     surface for bottom-bar actions.
 *   - Before dispatching a Join action, we consult the client
 *     DirtyLedger. If non-autosave dirt is pending, we surface the
 *     DirtyModal in `'join'` variant. Save & Join / Discard & Join
 *     flushes (or discards), then drains the in-flight queue up to
 *     DEFAULT_DRAIN_TIMEOUT_MS before firing the action.
 *
 * Performance: the status text updates on the normal ui_data cadence
 * (signal-driven on the server); no per-tick poll.
 */

import { useState } from 'react';
import { Box, Button, Dropdown, Flex } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { PREFS_ACTIONS } from './constants';
import { DEFAULT_DRAIN_TIMEOUT_MS, useDirtyLedger } from './DirtyLedger';
import { DirtyModal } from './DirtyModal';
import type { MigrantWaveDescriptor, PreferencesMenuData } from './types';

/** Pending join decision awaiting a DirtyModal resolution. */
type PendingJoin =
  | { kind: 'join_round' }
  | { kind: 'observe' }
  | { kind: 'join_migrant'; waveId: string; waveLabel: string }
  | null;

export function BottomBar() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const ledger = useDirtyLedger();
  const [pendingJoin, setPendingJoin] = useState<PendingJoin>(null);

  // Hide on the admin-standalone path per spec addendum.
  if (data.standalone === 1) {
    return null;
  }

  const canJoin = data.can_join === 1;
  const joinBlockReason = data.join_block_reason ?? undefined;
  const waves: readonly MigrantWaveDescriptor[] = data.migrant_waves ?? [];
  const status = data.lobby_status ?? '';

  /**
   * Fire the action envelope. BYOND ui_act is fire-and-forget; the
   * server closes the TGUI window on success, so there's no follow-up
   * state to reconcile here.
   */
  const dispatchAction = (
    action: string,
    extra?: Record<string, unknown>,
  ): void => {
    act('prefs_action', { action, ...(extra ?? {}) });
  };

  /**
   * Route a Join-class action through the dirty-check gate. When the
   * ledger has non-autosave dirt we surface the DirtyModal; autosave
   * keys are drained opportunistically (up to DEFAULT_DRAIN_TIMEOUT_MS)
   * to avoid clobbering a late-firing debounce on its way in.
   */
  const attemptJoin = async (pending: Exclude<PendingJoin, null>) => {
    if (ledger.hasPending(false)) {
      setPendingJoin(pending);
      return;
    }
    // Even with no explicit dirt there may be an autosave debounce
    // mid-flight; give the ledger a chance to drain before handing
    // control to the lobby path so the slot we join with reflects the
    // last edit. drain() resolves immediately when nothing is queued.
    try {
      await ledger.drain(DEFAULT_DRAIN_TIMEOUT_MS);
    } catch {
      // Timeout — fall through and let the lobby path see whatever
      // the savefile currently holds. The red "save failed" banner
      // (Step 19 polish) surfaces the retry prompt separately.
    }
    executePending(pending);
  };

  /** Dispatch the action corresponding to a resolved pending intent. */
  const executePending = (pending: Exclude<PendingJoin, null>) => {
    switch (pending.kind) {
      case 'join_round':
        dispatchAction(PREFS_ACTIONS.JOIN_ROUND);
        return;
      case 'observe':
        dispatchAction(PREFS_ACTIONS.OBSERVE);
        return;
      case 'join_migrant':
        dispatchAction(PREFS_ACTIONS.JOIN_MIGRANT, { wave_id: pending.waveId });
        return;
    }
  };

  /** Resolve the DirtyModal join-variant decision. */
  const resolveJoinDirty = async (mode: 'save' | 'discard' | 'cancel') => {
    const target = pendingJoin;
    setPendingJoin(null);
    if (!target || mode === 'cancel') {
      return;
    }
    if (mode === 'save') {
      ledger.flushBatch();
    } else {
      ledger.discardAll();
    }
    try {
      await ledger.drain(DEFAULT_DRAIN_TIMEOUT_MS);
    } catch {
      // Drain timeout — still proceed, same policy as attemptJoin().
    }
    executePending(target);
  };

  // Precompute the "active" migrant label for the plain-button case.
  const soleWave = waves.length === 1 ? waves[0] : null;
  const migrantButtonLabel = soleWave
    ? `Join Migrant Wave: ${soleWave.label}`
    : waves.length > 0
      ? 'Join Migrant Wave'
      : 'No Migrant Wave';
  const migrantDisabled = waves.length === 0;

  const pendingLabel = (() => {
    if (!pendingJoin) return '';
    if (pendingJoin.kind === 'join_round') return 'Join Game';
    if (pendingJoin.kind === 'observe') return 'Observe';
    return `Join Migrant Wave: ${pendingJoin.waveLabel}`;
  })();

  return (
    <>
      <Flex align="center" p={1} className="PrefsMenu__bottomBar">
        <Flex.Item>
          <Button
            color="good"
            disabled={!canJoin}
            tooltip={!canJoin ? joinBlockReason : undefined}
            onClick={() => attemptJoin({ kind: 'join_round' })}
          >
            Join Game
          </Button>
        </Flex.Item>
        <Flex.Item ml={1}>
          <Button onClick={() => attemptJoin({ kind: 'observe' })}>
            Observe
          </Button>
        </Flex.Item>
        <Flex.Item ml={1}>
          {waves.length > 1 ? (
            <Dropdown
              options={waves.map((w) => ({
                value: w.id,
                displayText: `${w.label} (${w.slots_remaining} slots)`,
              }))}
              selected=""
              displayText="Join Migrant Wave"
              onSelected={(waveId: string) => {
                const wave = waves.find((w) => w.id === waveId);
                if (!wave) return;
                attemptJoin({
                  kind: 'join_migrant',
                  waveId: wave.id,
                  waveLabel: wave.label,
                });
              }}
            />
          ) : (
            <Button
              disabled={migrantDisabled}
              onClick={() =>
                soleWave &&
                attemptJoin({
                  kind: 'join_migrant',
                  waveId: soleWave.id,
                  waveLabel: soleWave.label,
                })
              }
            >
              {migrantButtonLabel}
            </Button>
          )}
        </Flex.Item>
        <Flex.Item grow={1} ml={1}>
          <Box textAlign="right" color="label">
            {status}
          </Box>
        </Flex.Item>
      </Flex>

      {pendingJoin && (
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'rgba(0,0,0,0.6)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 10,
          }}
        >
          <div style={{ background: '#181818' }}>
            <DirtyModal
              variant="join"
              toTabLabel={pendingLabel}
              onSave={() => resolveJoinDirty('save')}
              onDiscard={() => resolveJoinDirty('discard')}
              onCancel={() => resolveJoinDirty('cancel')}
            />
          </div>
        </div>
      )}
    </>
  );
}

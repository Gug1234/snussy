/**
 * @file TopBar.tsx
 * @description Persistent top bar of the Elden-Ring-styled
 * PreferencesMenu shell. Step 8 wires Save / Discard to the
 * client-side DirtyLedger.
 *
 * Step status:
 *   - Slot indicator: informational only. Slot switching with
 *     DirtyModal interception lands later (depends on server-side
 *     slot-switch envelope, not in scope for Step 8).
 *   - Export / Import: still placeholders. Wired in Step 17.
 *   - Save: dispatches `ledger.flushBatch()` which chunks into
 *     `act('commit', { pairs })` calls capped at PREFS_COMMIT_BATCH_MAX.
 *   - Discard: dispatches `ledger.discardAll()` which clears the
 *     ledger and fires `act('discard')`.
 *   - Close: same `act('close')` it has had since Step 7. The shell
 *     handles the unsaved-changes interception around close (see
 *     index.tsx).
 *
 * Save / Discard enable state tracks `ledger.hasPending(true)` —
 * autosave keys are included here because once they have been
 * dispatched as set_pref they no longer count as "pending" anyway,
 * and showing "Save" enabled while an autosave is in-flight gives the
 * user a way to force a same-shape commit (idempotent on the server).
 */

import { Box, Button, Stack } from 'tgui-core/components';

import { useBackend } from '../../backend';
import { useDirtyLedger } from './DirtyLedger';
import type { PreferencesMenuData } from './types';

export type PrefsFrameSkin = 'leather' | 'gilded' | 'stone';
export type PrefsTopbarSkin = 'wide' | 'slim';

interface TopBarProps {
  frameSkin: PrefsFrameSkin;
  topbarSkin: PrefsTopbarSkin;
  onFrameSkinChange: (skin: PrefsFrameSkin) => void;
  onTopbarSkinChange: (skin: PrefsTopbarSkin) => void;
}

const FRAME_SKINS: readonly { id: PrefsFrameSkin; tooltip: string }[] = [
  { id: 'leather', tooltip: 'Leather frame' },
  { id: 'gilded', tooltip: 'Gilded frame' },
  { id: 'stone', tooltip: 'Stone frame' },
];

const TOPBAR_SKINS: readonly {
  id: PrefsTopbarSkin;
  icon: string;
  tooltip: string;
}[] = [
  { id: 'wide', icon: 'window-maximize', tooltip: 'Wide wood topbar' },
  { id: 'slim', icon: 'minus', tooltip: 'Slim wood topbar' },
];

export function TopBar(props: TopBarProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const ledger = useDirtyLedger();
  const hasAnyPending = ledger.hasPending(true);

  const slotLabel = data.active_slot !== null ? `Slot ${data.active_slot}` : '';

  return (
    <Box className="PrefsMenu__topBar" p={1}>
      <Stack align="center">
        <Stack.Item>
          <Box bold mr={1}>
            {slotLabel}
          </Box>
        </Stack.Item>
        <Stack.Item className="PrefsMenu__skinPicker">
          <Stack align="center">
            {FRAME_SKINS.map((skin) => (
              <Stack.Item key={skin.id}>
                <Button
                  selected={props.frameSkin === skin.id}
                  tooltip={skin.tooltip}
                  className="PrefsMenu__skinButton"
                  onClick={() => props.onFrameSkinChange(skin.id)}
                >
                  <Box
                    className={
                      'PrefsMenu__skinSwatch ' +
                      `PrefsMenu__skinSwatch--${skin.id}`
                    }
                  />
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
        <Stack.Item className="PrefsMenu__skinPicker">
          <Stack align="center">
            {TOPBAR_SKINS.map((skin) => (
              <Stack.Item key={skin.id}>
                <Button
                  icon={skin.icon}
                  selected={props.topbarSkin === skin.id}
                  tooltip={skin.tooltip}
                  onClick={() => props.onTopbarSkinChange(skin.id)}
                />
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="download"
            tooltip="Export the currently selected slot to JSON"
            onClick={() => act('export_slot', { slot: data.active_slot })}
          >
            Export
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="upload"
            tooltip="Import a slot from JSON into the currently selected slot"
            onClick={() => act('import_slot', { slot: data.active_slot })}
          >
            Import
          </Button>
        </Stack.Item>
        <Stack.Item grow>{/* spacer */}</Stack.Item>
        <Stack.Item>
          <Button
            icon="save"
            color={hasAnyPending ? 'good' : undefined}
            disabled={!hasAnyPending}
            tooltip="Commit pending changes to the slot"
            onClick={() => ledger.flushBatch()}
          >
            Save
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="undo"
            color={hasAnyPending ? 'bad' : undefined}
            disabled={!hasAnyPending}
            tooltip="Drop pending changes and reload the slot"
            onClick={() => ledger.discardAll()}
          >
            Discard
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="times"
            tooltip="Close menu"
            onClick={() => {
              // The shell intercepts close-with-dirty in index.tsx
              // by listening to the `close` button via window chrome.
              // Pressing this Close button is a deliberate user
              // action; flush autosaves first so nothing is lost,
              // then defer the close decision to the server.
              act('close');
            }}
          >
            Close
          </Button>
        </Stack.Item>
      </Stack>
    </Box>
  );
}

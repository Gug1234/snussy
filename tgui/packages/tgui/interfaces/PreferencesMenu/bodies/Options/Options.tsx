/**
 * @file bodies/Options/Options.tsx
 * @description Options category — single body covering the prefs scalars
 * surfaced by the Step 2 + Step 3 dispatch seed.
 *
 * Bitfield-backed visuals/audio/chat/gameplay toggles continue to ride
 * the legacy `/client/verb/toggle_*` surface. Mirroring them here would
 * require a second write path through the `/datum/preferences.toggles`
 * bitmask that is currently mutated by the legacy verbs without going
 * through the dispatch table — out of scope for Step 13.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';
// tgui-core does not export a standalone Checkbox; Button.Checkbox is the supported surface.
const Checkbox = Button.Checkbox;

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefsRouter } from '../../PrefsRouter';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

type BitfieldToggleRow = {
  label: string;
  key: string;
  mask: number;
};

const VISUAL_TOGGLES: readonly BitfieldToggleRow[] = [
  { label: 'Floating text', key: 'floating_text_toggles', mask: 1 << 0 },
  { label: 'XP text', key: 'floating_text_toggles', mask: 1 << 1 },
];
const AUDIO_TOGGLES: readonly BitfieldToggleRow[] = [
  { label: 'Adminhelp sounds', key: 'toggles', mask: 1 << 0 },
  { label: 'MIDI music', key: 'toggles', mask: 1 << 1 },
  { label: 'Ambience', key: 'toggles', mask: 1 << 2 },
  { label: 'Lobby music', key: 'toggles', mask: 1 << 3 },
  { label: 'Instruments', key: 'toggles', mask: 1 << 7 },
  { label: 'Ship ambience', key: 'toggles', mask: 1 << 8 },
  { label: 'Prayer chimes', key: 'toggles', mask: 1 << 9 },
  { label: 'Announcements', key: 'toggles', mask: 1 << 11 },
];
const CHAT_TOGGLES: readonly BitfieldToggleRow[] = [
  { label: 'OOC channel', key: 'chat_toggles', mask: 1 << 0 },
  { label: 'Deadchat', key: 'chat_toggles', mask: 1 << 1 },
  { label: 'Ghost ears', key: 'chat_toggles', mask: 1 << 2 },
  { label: 'Ghost sight', key: 'chat_toggles', mask: 1 << 3 },
  { label: 'Prayer channel', key: 'chat_toggles', mask: 1 << 4 },
];
const GAMEPLAY_TOGGLES: readonly BitfieldToggleRow[] = [
  { label: 'Public member visibility', key: 'toggles', mask: 1 << 4 },
];

function BitfieldSection(props: {
  title: string;
  rows: readonly BitfieldToggleRow[];
}) {
  const { act, data } = useBackend<
    PreferencesMenuData & {
      toggles?: number;
      chat_toggles?: number;
      floating_text_toggles?: number;
    }
  >();
  return (
    <Section title={props.title}>
      <Stack vertical>
        {props.rows.map((row) => {
          const current = Number((data as any)[row.key] ?? 0);
          const checked = (current & row.mask) !== 0;
          return (
            <Stack.Item key={`${row.key}:${row.mask}`}>
              <Checkbox
                checked={checked}
                onClick={() =>
                  act('toggle_bitfield', {
                    field: row.key,
                    mask: row.mask,
                  })
                }
              >
                {row.label}
              </Checkbox>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
}

function OptionsBody() {
  const { act } = useBackend();
  const router = usePrefsRouter();
  const preferClassicHtml = usePrefField<boolean>(
    PREF_KEYS.UI_PREFER_CLASSIC_HTML,
    false,
    { autosave: true },
  );
  const lobbyButtonClassic = usePrefField<boolean>(
    PREF_KEYS.UI_LOBBY_BUTTON_CLASSIC,
    false,
    { autosave: true },
  );

  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Classic UI">
          <Stack vertical>
            <Stack.Item>
              <Checkbox
                checked={preferClassicHtml.value === true}
                onClick={() =>
                  preferClassicHtml.setValue(
                    !(preferClassicHtml.value === true),
                  )
                }
              >
                Always use classic HTML preferences
              </Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Checkbox
                checked={lobbyButtonClassic.value === true}
                onClick={() =>
                  lobbyButtonClassic.setValue(
                    !(lobbyButtonClassic.value === true),
                  )
                }
              >
                Show classic lobby Setup Character button
              </Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="sliders-h"
                onClick={() =>
                  act('launch_singleton', {
                    editor: 'classic_options',
                    return_category: PREFS_CATEGORIES.OPTIONS,
                    return_row: 'options',
                  })
                }
              >
                Open Classic Options (full bitfields)
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Keybindings">
          <Stack vertical>
            <Stack.Item>
              <Box color="label">
                Keybinding configuration is its own category below.
              </Box>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="keyboard"
                onClick={() =>
                  router.go(PREFS_CATEGORIES.KEYBINDINGS, 'keybindings')
                }
              >
                Go to Keybindings
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <BitfieldSection title="Visuals" rows={VISUAL_TOGGLES} />
      </Stack.Item>
      <Stack.Item>
        <BitfieldSection title="Audio" rows={AUDIO_TOGGLES} />
      </Stack.Item>
      <Stack.Item>
        <BitfieldSection title="Chat" rows={CHAT_TOGGLES} />
      </Stack.Item>
      <Stack.Item>
        <BitfieldSection title="Gameplay" rows={GAMEPLAY_TOGGLES} />
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.OPTIONS,
  id: 'options',
  label: 'Options',
  component: OptionsBody,
});

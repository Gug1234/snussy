/**
 * @file bodies/Keybindings/Keybindings.tsx
 * @description Keybindings category — singleton handshake stub.
 *
 * Spec called for an inline re-port of the keybinds TGUI surface;
 * scope-deferred to a follow-up because the existing window owns its
 * own capture/conflict-resolution loop that doesn't round-trip
 * cleanly through the flat snapshot. Until then the row launches the
 * existing keybinds window via Step 14's launch_singleton envelope.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';

function KeybindingsBody() {
  const { act } = useBackend();
  return (
    <Section title="Keybindings">
      <Stack vertical>
        <Stack.Item>
          <Box>
            Keybind editing uses the existing keybinds window until the
            singleton handshake lands (Step 14).
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="keyboard"
            onClick={() =>
              act('launch_singleton', {
                editor: 'keybindings',
                return_category: PREFS_CATEGORIES.KEYBINDINGS,
                return_row: 'keybindings',
              })
            }
          >
            Open Keybindings
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.KEYBINDINGS,
  id: 'keybindings',
  label: 'Keybindings',
  component: KeybindingsBody,
});

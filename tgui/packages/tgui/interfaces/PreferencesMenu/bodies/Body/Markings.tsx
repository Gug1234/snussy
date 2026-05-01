/**
 * @file bodies/Body/Markings.tsx
 * @description Body → Markings row body — singleton handshake stub.
 *
 * The markings editor (`/datum/preferences/proc/ShowMarkings` at
 * code/modules/client/preferences_body_markings.dm:194) is a
 * full-window picker with its own DMI palette + per-zone targeting.
 * Re-implementing it inline would balloon Step 12; the row instead
 * launches the legacy window via the Step 14 singleton handshake.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';

function MarkingsBody() {
  const { act } = useBackend();
  return (
    <Section title="Markings">
      <Stack vertical>
        <Stack.Item>
          <Box>
            Body markings use the legacy markings window until the singleton
            handshake lands (Step 14).
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="paint-brush"
            onClick={() =>
              act('launch_singleton', {
                editor: 'body_markings',
                return_category: PREFS_CATEGORIES.BODY,
                return_row: 'markings',
              })
            }
          >
            Open Markings Editor
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'markings',
  label: 'Markings',
  component: MarkingsBody,
});

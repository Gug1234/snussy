/**
 * @file bodies/Identity/Descriptors.tsx
 * @description Identity → Descriptors row body — singleton handshake stub.
 *
 * Descriptors live in `code/modules/client/preferences_descriptors.dm`
 * and use a complex datum-backed picker. Step 10 surfaces a button that
 * delegates to the existing surface via `launch_singleton`; full
 * embedding lands when the singleton coordinator does (Step 14).
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';

function DescriptorsBody() {
  const { act } = useBackend();
  return (
    <Section title="Descriptors">
      <Stack vertical>
        <Stack.Item>
          <Box>
            Body descriptors (height, build, scars, …) use the existing picker.
            The TGUI integration handshake lands in Step 14.
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="user-edit"
            onClick={() =>
              act('launch_singleton', {
                editor: 'descriptors',
                return_category: PREFS_CATEGORIES.IDENTITY,
                return_row: 'descriptors',
              })
            }
          >
            Open Descriptors Editor
          </Button>{' '}
          <Button
            icon="eye"
            onClick={() => act('preview_examine')}
            tooltip="Show an examine panel for your preview body using your current descriptors."
          >
            Preview in chat
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'descriptors',
  label: 'Descriptors',
  component: DescriptorsBody,
});

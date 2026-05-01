/**
 * @file bodies/Identity/Images.tsx
 * @description Identity → Images row body (I8).
 *
 * Inline headshot URL + chat-headshot toggle + launcher to the legacy
 * gallery manager for multi-image management. Per-image gallery edits
 * still go through the existing examine-panel flow until a bespoke
 * TGUI gallery editor lands.
 */

import { Box, Button, Input, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

function ImagesBody() {
  const { act } = useBackend();
  const headshot = usePrefField<string>(PREF_KEYS.HEADSHOT_LINK, '', {
    autosave: true,
  });
  const chatHeadshot = usePrefField<boolean>(
    PREF_KEYS.CHATHEADSHOT_ENABLED,
    false,
  );

  return (
    <Section title="Images">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Headshot URL</Box>
          <Input
            fluid
            value={headshot.value ?? ''}
            onChange={(val: string) => headshot.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!chatHeadshot.value}
            onClick={() => chatHeadshot.setValue(!chatHeadshot.value)}
          >
            Show headshot in chat messages
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="image"
            onClick={() =>
              act('launch_singleton', {
                editor: 'images',
                return_category: PREFS_CATEGORIES.IDENTITY,
                return_row: 'images',
              })
            }
          >
            Manage galleries…
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'images',
  label: 'Images',
  component: ImagesBody,
});

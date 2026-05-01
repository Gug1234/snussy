/**
 * @file bodies/Body/Head.tsx
 * @description Body → Head row body.
 *
 * Head detail + accessory free-text inputs, plus the detail colour
 * moved from Coloration per B5 deviation, and a launcher button into
 * the Head customizer singleton for the deep per-feature editor.
 */

import { Box, Button, Input, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

function HeadBody() {
  const { act } = useBackend();
  const detail = usePrefField<string>(PREF_KEYS.DETAIL, 'Nothing', {
    autosave: true,
  });
  const accessory = usePrefField<string>(PREF_KEYS.ACCESSORY, 'Nothing', {
    autosave: true,
  });
  const detailColor = usePrefField<string>(PREF_KEYS.DETAIL_COLOR, '#000000', {
    autosave: true,
  });

  return (
    <Section title="Head">
      <Stack vertical>
        <Stack.Item>
          <Button
            icon="paint-brush"
            onClick={() =>
              act('launch_singleton', {
                editor: 'head_customizer',
                return_category: PREFS_CATEGORIES.BODY,
                return_row: 'head',
              })
            }
          >
            Open Head Customizer
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Head detail</Box>
          <Input
            fluid
            value={detail.value ?? 'Nothing'}
            onChange={(val: string) => detail.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Detail colour</Box>
          <Input
            value={detailColor.value ?? '#000000'}
            onChange={(val: string) => detailColor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Head accessory</Box>
          <Input
            fluid
            value={accessory.value ?? 'Nothing'}
            onChange={(val: string) => accessory.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box italic color="label" fontSize="0.85em">
            Per-species detail / accessory dropdowns arrive in Step 12.
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'head',
  label: 'Head',
  component: HeadBody,
});

/**
 * @file bodies/Intimacy/CustomSexActions.tsx
 * @description Intimacy → Custom Sex Actions row. Launcher for the
 * existing standalone editor; inline embedding is deferred.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';

const ROW_ID = 'custom_sex_actions';

function CustomSexActionsBody() {
  const { act } = useBackend();
  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Custom Sex Actions">
          <Box mb={1} color="label">
            Opens the full Custom Sex Actions editor in its own window.
          </Box>
          <Button
            icon="heart"
            onClick={() =>
              act('launch_singleton', {
                editor: 'custom_sex',
                return_category: PREFS_CATEGORIES.INTIMACY,
                return_row: ROW_ID,
              })
            }
          >
            Open Custom Sex Actions Editor
          </Button>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.INTIMACY,
  id: ROW_ID,
  label: 'Custom Sex Actions',
  component: CustomSexActionsBody,
  visible: (data) => !data?.intimacy_gated,
});

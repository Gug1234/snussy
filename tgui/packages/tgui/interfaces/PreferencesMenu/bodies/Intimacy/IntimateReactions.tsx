/**
 * @file bodies/Intimacy/IntimateReactions.tsx
 * @description Intimacy → Intimate Reactions row. Launcher for the
 * existing standalone editor.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';

const ROW_ID = 'intimate_reactions';

function IntimateReactionsBody() {
  const { act } = useBackend();
  return (
    <Stack vertical>
      <Stack.Item>
        <Section title="Intimate Reactions">
          <Box mb={1} color="label">
            Opens the Intimate Reactions editor in its own window.
          </Box>
          <Button
            icon="comments"
            onClick={() =>
              act('launch_singleton', {
                editor: 'intimate_reactions',
                return_category: PREFS_CATEGORIES.INTIMACY,
                return_row: ROW_ID,
              })
            }
          >
            Open Intimate Reactions Editor
          </Button>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.INTIMACY,
  id: ROW_ID,
  label: 'Intimate Reactions',
  component: IntimateReactionsBody,
  visible: (data) => !data?.intimacy_gated,
});

/**
 * @file MarkingsTab.tsx
 * @description "Markings" tab body for the Phase 1 PreferencesMenu shell.
 *
 * Step 8 landing: placeholder body. Body marking selection remains on the
 * classic preferences panel until a follow-up migration.
 */

import { Box, Section } from 'tgui-core/components';

export function MarkingsTab() {
  return (
    <Section title="Body Markings">
      <Box color="label">
        Body markings continue to be authored on the classic preferences panel.
        This tab is a placeholder so the shell layout matches the planned final
        taxonomy.
      </Box>
    </Section>
  );
}

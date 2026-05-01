/**
 * @file GameTab.tsx
 * @description "Game Preferences" tab body for the Phase 1 PreferencesMenu
 * shell.
 *
 * Step 8 landing: placeholder body. Client/game preferences continue to
 * live on the classic preferences panel until a follow-up migration.
 */

import { Box, Section } from 'tgui-core/components';

export function GameTab() {
  return (
    <Section title="Game Preferences">
      <Box color="label">
        OOC and client-side preferences continue to live on the classic
        preferences panel. This tab is a placeholder to match the planned final
        taxonomy.
      </Box>
    </Section>
  );
}

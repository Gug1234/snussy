/**
 * @file InfoTab.tsx
 * @description "Info" tab body for the Phase 1 PreferencesMenu shell.
 *
 * Step 8 landing: placeholder body. Full info-pane migration (name,
 * species, age, gender, job preferences, flavor text, vice menu,
 * loadout, trait selector) is out of Phase 1 scope — the legacy HTML
 * `ShowChoices` surface still hosts these panels.
 *
 * The placeholder is authored so that a future step can replace the
 * inner `<Box>` content without touching the shell.
 */

import { Box, Section } from 'tgui-core/components';

export function InfoTab() {
  return (
    <Section title="Character Info">
      <Box color="label" mb={1}>
        Name, species, age, gender, job priorities, flavor text, loadout, and
        trait selection continue to live in the classic preferences panel for
        now.
      </Box>
      <Box italic color="label">
        This tab will absorb those panes in a future pass. Use this window for
        the live preview, rotation, background selection, and the Taur Offsets /
        Intimate Accessories editors.
      </Box>
    </Section>
  );
}

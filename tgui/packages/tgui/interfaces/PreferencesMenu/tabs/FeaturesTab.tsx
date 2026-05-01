/**
 * @file FeaturesTab.tsx
 * @description "Features" tab body (hair, tails, wings, horns, genitals,
 * etc.) for the Phase 1 PreferencesMenu shell.
 *
 * Step 8 landing: placeholder body. The Features tab owns the
 * "taur offsets available" toggle in the final design, but Phase 1
 * drives taur-tab visibility from the server-side organ check
 * (`data.taur_offsets_available`) so the placeholder does not need
 * to surface a toggle yet.
 */

import { Box, Section } from 'tgui-core/components';

export function FeaturesTab() {
  return (
    <Section title="Features">
      <Box color="label" mb={1}>
        Hair, facial hair, eyes, ears, tails, wings, horns, breasts, vagina, and
        penis/testicles selection remain on the classic preferences panel for
        now.
      </Box>
      <Box italic color="label">
        The Taur Offsets tab appears automatically when the current character
        has a taur body.
      </Box>
    </Section>
  );
}

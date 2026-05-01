/**
 * @file bodies/Body/Taur.tsx
 * @description Body → Taur row body (Step 12 part B).
 *
 * Surfaces the three mirror toggles that gate how the existing
 * TaurGenitalOffsetEditor writes draft state, plus a launch button
 * for the editor itself (via the Step 14 singleton handshake).
 *
 * The toggles default TRUE so legacy slots keep their canonical
 * single-side / single-arousal-state behaviour. Flipping one OFF
 * does not destroy data — the editor keeps a draft buffer and
 * snapshot-restores asymmetric values when toggled back ON. (See
 * `code/__DEFINES/preferences_tgui.dm:81-83` and the editor at
 * `modular/code/modules/client/taur_genital_offset_editor.dm`.)
 *
 * The whole row is gated on `data.taur_offsets_available` — non-taur
 * species don't see it at all, matching the existing TaurOffsetsTab
 * placeholder behaviour.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';
// tgui-core does not export a standalone Checkbox; Button.Checkbox is the supported surface.
const Checkbox = Button.Checkbox;

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function TaurBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const available = data.taur_offsets_available === 1;

  const consistentArousal = usePrefField<boolean>(
    PREF_KEYS.TAUR_CONSISTENT_AROUSAL,
    true,
  );
  const mirrorEW = usePrefField<boolean>(PREF_KEYS.TAUR_MIRROR_EW, true);
  const testicleMirrorEW = usePrefField<boolean>(
    PREF_KEYS.TESTICLE_MIRROR_EW,
    true,
  );

  if (!available) {
    return (
      <Section title="Taur">
        <Box italic color="label">
          Your current species does not use taur sprites.
        </Box>
      </Section>
    );
  }

  return (
    <Section title="Taur">
      <Stack vertical>
        <Stack.Item>
          <Checkbox
            checked={consistentArousal.value !== false}
            onClick={() =>
              consistentArousal.setValue(!(consistentArousal.value !== false))
            }
          >
            Consistent arousal state
          </Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Checkbox
            checked={mirrorEW.value !== false}
            onClick={() => mirrorEW.setValue(!(mirrorEW.value !== false))}
          >
            Mirror east / west sides
          </Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Checkbox
            checked={testicleMirrorEW.value !== false}
            onClick={() =>
              testicleMirrorEW.setValue(!(testicleMirrorEW.value !== false))
            }
          >
            Mirror testicle east / west sides
          </Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="sliders-h"
            onClick={() =>
              act('launch_singleton', {
                editor: 'taur_genital_offsets',
                return_category: PREFS_CATEGORIES.BODY,
                return_row: 'taur',
              })
            }
          >
            Open Taur Offset Editor
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'taur',
  label: 'Taur',
  component: TaurBody,
});

/**
 * @file TaurOffsetsTab.tsx
 * @description Taur Genital Offsets tab body (Phase 1, Step 9).
 *
 * ## Phase 1 scope note
 *
 * The existing standalone `TaurGenitalOffsetEditor` interface owns a full
 * client-side draft state machine, arousal-state switcher, per-part
 * sanitiser, and commit envelope validated by the server's
 * `appearance_preview_process_commit` pipeline. Porting that surface
 * inline into the tabbed prefs shell would require merging its ui_data
 * schema, ui_act handlers, and commit routing into `/datum/preferences`
 * — a refactor well beyond the Phase 1 TDI-win scope.
 *
 * Instead, Step 9 lands the tab body as a launch affordance: the
 * `act('open_taur_editor', { part })` call routes through the DM opener
 * with `standalone = FALSE`, which:
 *   1. Sets `prefs.active_tab = "taur_offsets"` so the preview view's
 *      strip pass hides the taur layer while editing (preventing the
 *      "doppelganger" bug).
 *   2. Binds the editor to `prefs.active_editor` so the singleton guard
 *      fires `_on_tab_exit()` on subsequent tab switches (DirtyModal
 *      resolves the save/discard choice client-side before the switch
 *      reaches the server).
 *   3. Opens the standalone editor window alongside the prefs shell.
 *
 * A future step can inline the editor body directly in this tab once the
 * commit envelope is unified; the tab contract (route through
 * `open_taur_editor`) will not change.
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../backend';
import type { PreferencesMenuData } from '../types';

/**
 * Part keys accepted by `open_taur_editor`. Mirrors
 * `GLOB.taur_genital_part_keys`.
 */
const TAUR_PARTS: readonly { id: string; label: string }[] = [
  { id: 'penis', label: 'Penis' },
  { id: 'testicles', label: 'Testicles' },
  { id: 'vagina', label: 'Vagina' },
];

export function TaurOffsetsTab() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const available = data.taur_offsets_available === 1;

  return (
    <Section title="Taur Genital Offsets">
      <Box color="label" mb={1}>
        Per-direction offset, rotation, flip, scale, and hide controls for each
        taur genital layer. Editing one part at a time hides the corresponding
        layer on the live preview backdrop automatically.
      </Box>
      {!available && (
        <Box color="bad" bold mb={1}>
          This character does not have a taur body. Switch species or add a taur
          body organ to enable the offset editor.
        </Box>
      )}
      <Stack>
        {TAUR_PARTS.map((part) => (
          <Stack.Item key={part.id} grow>
            <Button
              fluid
              disabled={!available}
              icon="sliders-h"
              onClick={() => act('open_taur_editor', { part: part.id })}
            >
              Edit {part.label}
            </Button>
          </Stack.Item>
        ))}
      </Stack>
      <Box italic color="label" mt={1}>
        The editor opens in a companion window. Changes apply to the live
        preview instantly; press Save in the editor to persist them.
      </Box>
    </Section>
  );
}

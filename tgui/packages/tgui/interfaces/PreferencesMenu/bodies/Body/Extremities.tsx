/**
 * @file bodies/Body/Extremities.tsx
 * @description Body → Extremities row body (Step 12 part B).
 *
 * Surfaces the three "mutant" colour scalars (mcolor / mcolor2 /
 * mcolor3 in the BYOND features assoc) and the ethereal accent
 * colour. These are pure hex inputs; per-species use of each slot is
 * documented elsewhere and not editorialised here.
 *
 * Body shape changes (digitigrade, snouts, ear/tail variants, etc.)
 * are wired up under the species datum's customizer pickers, not in
 * the prefs root, so the corresponding rows live in their own future
 * Body row (Body → Mutations) once the customizer launcher lands.
 */

import { Box, Button, Input, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

function ExtremitiesBody() {
  const { act } = useBackend();
  const mcolor1 = usePrefField<string>(PREF_KEYS.MUTANT_COLOR_1, '#FFFFFF', {
    autosave: true,
  });
  const mcolor2 = usePrefField<string>(PREF_KEYS.MUTANT_COLOR_2, '#FFFFFF', {
    autosave: true,
  });
  const mcolor3 = usePrefField<string>(PREF_KEYS.MUTANT_COLOR_3, '#FFFFFF', {
    autosave: true,
  });
  const ethColor = usePrefField<string>(PREF_KEYS.ETHEREAL_COLOR, '#9C3030', {
    autosave: true,
  });

  return (
    <Section title="Extremities">
      <Stack vertical>
        <Stack.Item>
          <Button
            icon="paint-brush"
            onClick={() =>
              act('launch_singleton', {
                editor: 'extremities_customizer',
                return_category: PREFS_CATEGORIES.BODY,
                return_row: 'extremities',
              })
            }
          >
            Open Extremities Customizer
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Mutant colour 1</Box>
          <Input
            value={mcolor1.value ?? '#FFFFFF'}
            onChange={(val: string) => mcolor1.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Mutant colour 2</Box>
          <Input
            value={mcolor2.value ?? '#FFFFFF'}
            onChange={(val: string) => mcolor2.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Mutant colour 3</Box>
          <Input
            value={mcolor3.value ?? '#FFFFFF'}
            onChange={(val: string) => mcolor3.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Ethereal accent</Box>
          <Input
            value={ethColor.value ?? '#9C3030'}
            onChange={(val: string) => ethColor.setValue(val)}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'extremities',
  label: 'Extremities',
  component: ExtremitiesBody,
});

/**
 * @file bodies/Body/Hair.tsx
 * @description Body → Hair row body.
 *
 * Hairstyle and facial hairstyle pickers. Step 11 part A ships the
 * fallback path: a Dropdown when the server has registered a flat
 * hairstyle list, otherwise a freeform Input. Step 12 part B replaces
 * this with a `SheetPreviewTile` grid backed by a preloaded sprite
 * sheet (the asset bundle ships per-species accessory sheets) once
 * the per-species accessory dump lands in static data.
 */

import { useBackend } from 'tgui/backend';
import { Box, Dropdown, Input, Section, Stack } from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData, PrefsOption } from '../../types';
import { usePrefField } from '../usePrefField';

function pickerFor(
  options: readonly PrefsOption[],
  value: string,
  onPick: (id: string) => void,
  fallbackOnChange: (val: string) => void,
) {
  if (options.length === 0) {
    return (
      <Input
        fluid
        value={value}
        onChange={(val: string) => fallbackOnChange(val)}
      />
    );
  }
  const labels = options.map((opt) => opt.label);
  return (
    <Dropdown
      options={labels}
      selected={value || labels[0]}
      onSelected={(label: string) => {
        const match = options.find((opt) => opt.label === label);
        if (match) {
          onPick(match.id);
        }
      }}
    />
  );
}

function HairBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const hairOptions: readonly PrefsOption[] = data.hairstyle_options ?? [];
  const facialOptions: readonly PrefsOption[] =
    data.facial_hairstyle_options ?? [];
  const hairstyle = usePrefField<string>(PREF_KEYS.HAIRSTYLE, 'Bald', {
    autosave: true,
  });
  const facialHairstyle = usePrefField<string>(
    PREF_KEYS.FACIAL_HAIRSTYLE,
    'Shaved',
    { autosave: true },
  );
  // B4 deviation: hair/facial-hair colours moved here from Coloration.
  const hairColor = usePrefField<string>(PREF_KEYS.HAIR_COLOR, '#000000', {
    autosave: true,
  });
  const facialHairColor = usePrefField<string>(
    PREF_KEYS.FACIAL_HAIR_COLOR,
    '#000000',
    { autosave: true },
  );

  return (
    <Section title="Hair">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Hairstyle</Box>
          {pickerFor(
            hairOptions,
            hairstyle.value ?? 'Bald',
            (id) => hairstyle.setValue(id),
            (val) => hairstyle.setValue(val),
          )}
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Hair colour</Box>
          <Input
            value={hairColor.value ?? '#000000'}
            onChange={(val: string) => hairColor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Facial hairstyle</Box>
          {pickerFor(
            facialOptions,
            facialHairstyle.value ?? 'Shaved',
            (id) => facialHairstyle.setValue(id),
            (val) => facialHairstyle.setValue(val),
          )}
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Facial hair colour</Box>
          <Input
            value={facialHairColor.value ?? '#000000'}
            onChange={(val: string) => facialHairColor.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box italic color="label" fontSize="0.85em">
            Sheet-tile picker arrives in Step 12 once per-species accessory
            metadata is published.
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'hair',
  label: 'Hair',
  component: HairBody,
});

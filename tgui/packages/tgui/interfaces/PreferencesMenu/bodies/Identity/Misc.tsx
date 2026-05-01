/**
 * @file bodies/Identity/Misc.tsx
 * @description Identity → Misc row body.
 *
 * Catch-all for low-volume identity prefs plus the absorbed food/drink
 * dropdowns (old Food row was merged here). Per-character hardmode
 * lives in the Intimacy → Chastity row; donator say color is removed.
 */

import { Box, Button, Dropdown, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function MiscBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const age = usePrefField<string>(PREF_KEYS.AGE, 'Adult');
  const dnr = usePrefField<boolean>(PREF_KEYS.DNR, false);
  const domhand = usePrefField<number>(PREF_KEYS.DOMHAND, 2);

  const foods = data.food_options ?? [];
  const drinks = data.drink_options ?? [];
  const favFood = usePrefField<string>(PREF_KEYS.CULINARY_FAV_FOOD, '');
  const favDrink = usePrefField<string>(PREF_KEYS.CULINARY_FAV_DRINK, '');
  const hatedFood = usePrefField<string>(PREF_KEYS.CULINARY_HATED_FOOD, '');
  const hatedDrink = usePrefField<string>(PREF_KEYS.CULINARY_HATED_DRINK, '');

  const ageOptions = (data.age_options ?? ['Adult', 'Middle-Aged', 'Old']).map(
    (label) => ({ value: label, displayText: label }),
  );
  const foodOptions = foods.map((f) => ({
    value: f.id,
    displayText: f.quality ? `${f.label} (${f.quality})` : f.label,
  }));
  const drinkOptions = drinks.map((d) => ({
    value: d.id,
    displayText:
      d.quality !== undefined ? `${d.label} (Q${d.quality})` : d.label,
  }));
  const labelFor = (
    options: typeof foodOptions,
    value: string | null | undefined,
  ) => options.find((o) => o.value === value)?.displayText ?? 'Unset';

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section title="Misc">
          <Stack vertical g={1}>
            <Stack.Item>
              <Box mb={0.5}>Age</Box>
              <Dropdown
                width="12rem"
                options={ageOptions}
                selected={age.value ?? 'Adult'}
                displayText={age.value ?? 'Adult'}
                onSelected={(v) => age.setValue(v)}
              />
            </Stack.Item>
            <Stack.Item>
              <Box mb={0.5}>Unrevivable (DNR)</Box>
              <Button
                icon={dnr.value ? 'check-square' : 'square'}
                color={dnr.value ? 'bad' : undefined}
                onClick={() => dnr.setValue(!dnr.value)}
              >
                {dnr.value ? 'Yes — stay dead' : 'No — resuscitation allowed'}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Box mb={0.5}>Hand Dominance</Box>
              <Button
                icon="hand-paper"
                onClick={() => domhand.setValue(domhand.value === 1 ? 2 : 1)}
              >
                {domhand.value === 1 ? 'Left-handed' : 'Right-handed'}
              </Button>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Food & Drink">
          <Stack vertical g={1}>
            <Stack.Item>
              <Box mb={0.5}>Favourite Food</Box>
              <Dropdown
                width="100%"
                options={foodOptions}
                selected={favFood.value ?? ''}
                displayText={labelFor(foodOptions, favFood.value)}
                onSelected={(v) => favFood.setValue(v)}
              />
            </Stack.Item>
            <Stack.Item>
              <Box mb={0.5}>Favourite Drink</Box>
              <Dropdown
                width="100%"
                options={drinkOptions}
                selected={favDrink.value ?? ''}
                displayText={labelFor(drinkOptions, favDrink.value)}
                onSelected={(v) => favDrink.setValue(v)}
              />
            </Stack.Item>
            <Stack.Item>
              <Box mb={0.5}>Hated Food</Box>
              <Dropdown
                width="100%"
                options={foodOptions}
                selected={hatedFood.value ?? ''}
                displayText={labelFor(foodOptions, hatedFood.value)}
                onSelected={(v) => hatedFood.setValue(v)}
              />
            </Stack.Item>
            <Stack.Item>
              <Box mb={0.5}>Hated Drink</Box>
              <Dropdown
                width="100%"
                options={drinkOptions}
                selected={hatedDrink.value ?? ''}
                displayText={labelFor(drinkOptions, hatedDrink.value)}
                onSelected={(v) => hatedDrink.setValue(v)}
              />
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
    </Stack>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'misc',
  label: 'Misc',
  component: MiscBody,
});

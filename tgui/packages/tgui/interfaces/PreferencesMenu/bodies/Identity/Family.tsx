/**
 * @file bodies/Identity/Family.tsx
 * @description Identity → Family row body.
 *
 * Family ties + preferred-spouse text. Family value space is large and
 * driven by FAMILY_* defines on the DM side; the dropdown is permissive
 * and the server validates the string against length only (the existing
 * sanitize sweep on load_character clamps unknown values).
 */

import { Box, Dropdown, Input, Section, Stack } from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import { usePrefField } from '../usePrefField';

const FAMILY_OPTIONS = ['None', 'Spouse', 'Sibling', 'Parent', 'Child'];
const SPOUSE_GENDER_OPTIONS = ['Any gender', 'male', 'female'];

function FamilyBody() {
  const family = usePrefField<string>(PREF_KEYS.FAMILY, 'None');
  const spouse = usePrefField<string>(PREF_KEYS.SETSPOUSE, '', {
    autosave: true,
  });
  const genderChoice = usePrefField<string>(
    PREF_KEYS.GENDER_CHOICE,
    'Any gender',
  );

  return (
    <Section title="Family">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Family relation</Box>
          <Dropdown
            options={FAMILY_OPTIONS}
            selected={family.value ?? 'None'}
            onSelected={(val: string) => family.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Preferred spouse name</Box>
          <Input
            fluid
            value={spouse.value ?? ''}
            onChange={(val: string) => spouse.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Spouse gender preference</Box>
          <Dropdown
            options={SPOUSE_GENDER_OPTIONS}
            selected={genderChoice.value ?? 'Any gender'}
            onSelected={(val: string) => genderChoice.setValue(val)}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'family',
  label: 'Family',
  component: FamilyBody,
});

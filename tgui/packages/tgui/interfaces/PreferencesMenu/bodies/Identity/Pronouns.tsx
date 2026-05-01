/**
 * @file bodies/Identity/Pronouns.tsx
 * @description Identity → Pronouns row body.
 *
 * Split out of the Name row; surfaces only the pronoun selector, fed
 * by `data.pronouns_options` (falls back to a small canned list when
 * the server hasn't emitted static data yet).
 */

import { Box, Dropdown, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

const FALLBACK_PRONOUNS = ['he/him', 'she/her', 'they/them', 'it/its'];

function PronounsBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const pronouns = usePrefField<string>(PREF_KEYS.PRONOUNS, 'he/him');
  const options = (data.pronouns_options ?? FALLBACK_PRONOUNS).map((p) => ({
    value: p,
    displayText: p,
  }));

  return (
    <Section title="Pronouns">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Select the pronouns used for your character.</Box>
          <Dropdown
            width="16rem"
            options={options}
            selected={pronouns.value ?? 'he/him'}
            displayText={pronouns.value ?? 'he/him'}
            onSelected={(val: string) => pronouns.setValue(val)}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'pronouns',
  label: 'Pronouns',
  component: PronounsBody,
});

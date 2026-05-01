/**
 * @file bodies/Identity/Familiar.tsx
 * @description Identity → Familiar row body. Inline editor for the
 * player's witch-familiar roundstart profile.
 */

import {
  Box,
  Dropdown,
  Input,
  Section,
  Stack,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function FamiliarBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const name = usePrefField<string>(PREF_KEYS.FAMILIAR_NAME, '');
  const pronouns = usePrefField<string>(PREF_KEYS.FAMILIAR_PRONOUNS, 'it/its');
  const specie = usePrefField<string>(PREF_KEYS.FAMILIAR_SPECIE, '');
  const flavortext = usePrefField<string>(PREF_KEYS.FAMILIAR_FLAVORTEXT, '', {
    autosave: true,
  });
  const oocNotes = usePrefField<string>(PREF_KEYS.FAMILIAR_OOC_NOTES, '', {
    autosave: true,
  });
  const headshot = usePrefField<string>(PREF_KEYS.FAMILIAR_HEADSHOT, '');

  const pronounOpts = (
    data.pronouns_options ?? ['he/him', 'she/her', 'they/them', 'it/its']
  ).map((p) => ({ value: p, displayText: p }));
  const specieOpts = (data.familiar_species_options ?? []).map((p) => ({
    value: p,
    displayText: p,
  }));

  return (
    <Section title="Familiar Identity">
      <Stack vertical g={1}>
        <Stack.Item>
          <Box mb={0.5}>Name</Box>
          <Input
            fluid
            value={name.value ?? ''}
            onChange={(val: string) => name.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Pronouns</Box>
          <Dropdown
            width="100%"
            options={pronounOpts}
            selected={pronouns.value ?? 'it/its'}
            displayText={pronouns.value ?? 'it/its'}
            onSelected={(v) => pronouns.setValue(v)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Species</Box>
          <Dropdown
            width="100%"
            options={specieOpts}
            selected={specie.value ?? ''}
            displayText={specie.value ?? 'Unset'}
            onSelected={(v) => specie.setValue(v)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Flavortext</Box>
          <TextArea
            height="8rem"
            value={flavortext.value ?? ''}
            onChange={(val: string) => flavortext.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>OOC Notes</Box>
          <TextArea
            height="6rem"
            value={oocNotes.value ?? ''}
            onChange={(val: string) => oocNotes.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Headshot URL</Box>
          <Input
            fluid
            value={headshot.value ?? ''}
            onChange={(val: string) => headshot.setValue(val)}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'familiar',
  label: 'Familiar',
  component: FamiliarBody,
  visible: (data) => !!data?.familiar_row_visible,
});

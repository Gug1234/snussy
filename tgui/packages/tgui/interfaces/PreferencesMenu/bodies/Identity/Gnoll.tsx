/**
 * @file bodies/Identity/Gnoll.tsx
 * @description Identity → Gnoll row body. Inline form for the roundstart
 * gnoll opt-in profile (replaces the legacy classic browser popup).
 */

import {
  Box,
  Button,
  Dropdown,
  Input,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function labelDropdown(labels: readonly string[]) {
  return labels.map((l) => ({ value: l, displayText: l }));
}

function GnollBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const gnollName = usePrefField<string>(PREF_KEYS.GNOLL_NAME, '');
  const pronouns = usePrefField<string>(PREF_KEYS.GNOLL_PRONOUNS, 'he/him');
  const pelt = usePrefField<string>(PREF_KEYS.GNOLL_PELT, 'firepelt');
  const penis = usePrefField<boolean>(PREF_KEYS.GNOLL_PENIS, false);
  const vagina = usePrefField<boolean>(PREF_KEYS.GNOLL_VAGINA, false);
  const breasts = usePrefField<boolean>(PREF_KEYS.GNOLL_BREASTS, false);
  const height = usePrefField<string>(PREF_KEYS.GNOLL_HEIGHT, 'Moderate');
  const body = usePrefField<string>(PREF_KEYS.GNOLL_BODY, 'Muscular');
  const fur = usePrefField<string>(PREF_KEYS.GNOLL_FUR, 'Coarse');
  const voice = usePrefField<string>(PREF_KEYS.GNOLL_VOICE, 'Growly');
  const muzzle = usePrefField<string>(PREF_KEYS.GNOLL_MUZZLE, 'Long');
  const expression = usePrefField<string>(PREF_KEYS.GNOLL_EXPRESSION, 'Alert');

  const descOpts = data.gnoll_descriptor_options ?? {};
  const pronounOpts = labelDropdown(
    data.pronouns_options ?? ['he/him', 'she/her', 'they/them', 'it/its'],
  );
  const peltOpts = labelDropdown(
    data.gnoll_pelt_options ?? [pelt.value ?? 'firepelt'],
  );

  const descRow = (
    caption: string,
    slot: string,
    field: ReturnType<typeof usePrefField<string>>,
  ) => {
    const opts = labelDropdown(
      descOpts[slot] ?? (field.value ? [field.value] : []),
    );
    return (
      <Stack.Item>
        <Box mb={0.5}>{caption}</Box>
        <Dropdown
          width="100%"
          options={opts}
          selected={field.value ?? ''}
          displayText={field.value ?? 'Unset'}
          onSelected={(v) => field.setValue(v)}
        />
      </Stack.Item>
    );
  };

  return (
    <Section title="Gnoll Identity">
      <Stack vertical g={1}>
        <Stack.Item>
          <Box mb={0.5}>Name</Box>
          <Input
            fluid
            value={gnollName.value ?? ''}
            onChange={(val: string) => gnollName.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Pronouns</Box>
          <Dropdown
            width="100%"
            options={pronounOpts}
            selected={pronouns.value ?? 'he/him'}
            displayText={pronouns.value ?? 'he/him'}
            onSelected={(v) => pronouns.setValue(v)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Pelt</Box>
          <Dropdown
            width="100%"
            options={peltOpts}
            selected={pelt.value ?? 'firepelt'}
            displayText={pelt.value ?? 'firepelt'}
            onSelected={(v) => pelt.setValue(v)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Genitals</Box>
          <Stack g={0.5}>
            <Stack.Item>
              <Button
                icon={penis.value ? 'check-square' : 'square'}
                onClick={() => penis.setValue(!penis.value)}
              >
                Penis
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon={vagina.value ? 'check-square' : 'square'}
                onClick={() => vagina.setValue(!vagina.value)}
              >
                Vagina
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon={breasts.value ? 'check-square' : 'square'}
                onClick={() => breasts.setValue(!breasts.value)}
              >
                Breasts
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
        {descRow('Height', 'height', height)}
        {descRow('Build', 'body', body)}
        {descRow('Coat', 'fur', fur)}
        {descRow('Voice', 'voice', voice)}
        {descRow('Muzzle', 'muzzle', muzzle)}
        {descRow('Expression', 'expression', expression)}
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'gnoll',
  label: 'Gnoll',
  component: GnollBody,
  visible: (data) => !!data?.gnoll_row_visible,
});

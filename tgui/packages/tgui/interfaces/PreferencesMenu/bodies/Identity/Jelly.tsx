/**
 * @file bodies/Identity/Jelly.tsx
 * @description Identity → Jelly row body. Opt-in toggle + the inline
 * jelly-controller profile (replaces the legacy popup).
 */

import {
  Box,
  Button,
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

function JellyBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const enabled = usePrefField<boolean>(PREF_KEYS.JELLY_ENABLED, false);
  const name = usePrefField<string>(PREF_KEYS.JELLY_NAME, '');
  const pronouns = usePrefField<string>(PREF_KEYS.JELLY_PRONOUNS, 'it/its');
  const flavortext = usePrefField<string>(PREF_KEYS.JELLY_FLAVORTEXT, '', {
    autosave: true,
  });
  const oocNotes = usePrefField<string>(PREF_KEYS.JELLY_OOC_NOTES, '', {
    autosave: true,
  });

  const pronounOpts = (
    data.pronouns_options ?? ['he/him', 'she/her', 'they/them', 'it/its']
  ).map((p) => ({ value: p, displayText: p }));

  return (
    <Section title="Jelly Controller">
      <Stack vertical g={1}>
        <Stack.Item>
          <Button
            icon={enabled.value ? 'check-square' : 'square'}
            color={enabled.value ? 'good' : undefined}
            onClick={() => enabled.setValue(!enabled.value)}
          >
            {enabled.value
              ? 'Jelly controller enabled'
              : 'Enable jelly controller'}
          </Button>
        </Stack.Item>
        {enabled.value ? (
          <>
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
          </>
        ) : null}
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'jelly',
  label: 'Jelly',
  component: JellyBody,
  visible: (data) => !!data?.jelly_row_visible,
});

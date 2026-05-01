/**
 * @file bodies/Body/Race.tsx
 * @description Body → Race row body.
 *
 * Species selection + B1 deviation: a per-species race/nobility title
 * dropdown. The title bank is owned by the species datum
 * (`/datum/species.race_titles`, gated by `use_titles`); the row hides
 * the title dropdown when the current species opts out. Picking a
 * species surfaces its flavor text directly under the dropdown.
 *
 * Stat impact: species sets the statpack, so the server-side setter
 * flags invalidates_stat_matrix=TRUE. The title is cosmetic and uses
 * the debounced autosave path.
 */

import { useBackend } from 'tgui/backend';
import { Box, Dropdown, Section, Stack } from 'tgui-core/components';

import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData, PrefsOption } from '../../types';
import { usePrefField } from '../usePrefField';

function RaceBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const options: readonly PrefsOption[] = data.species_options ?? [];
  const labels = options.map((opt) => opt.label);
  const species = usePrefField<string>(PREF_KEYS.SPECIES, options[0]?.id ?? '');
  const title = usePrefField<string>(PREF_KEYS.RACE_TITLE, 'None', {
    autosave: true,
  });
  const speciesDescriptions = data.species_descriptions ?? {};
  const speciesRaceTitles = data.species_race_titles ?? {};
  const selectedSpeciesLabel =
    options.find((opt) => opt.id === species.value)?.label ?? '';
  const flavor = selectedSpeciesLabel
    ? speciesDescriptions[selectedSpeciesLabel]
    : undefined;
  const titleBank: readonly string[] = selectedSpeciesLabel
    ? (speciesRaceTitles[selectedSpeciesLabel] ?? [])
    : [];
  const titlesAvailable = titleBank.length > 0;
  const currentTitle = title.value ?? 'None';
  // Fallback to "None" on the dropdown when the stored title isn't in
  // the active species's bank (e.g. after a species switch). The
  // server setter clamps to "None" in that case anyway; mirroring it
  // client-side avoids a flash of an invalid selection.
  const displayedTitle = titleBank.includes(currentTitle)
    ? currentTitle
    : 'None';

  return (
    <Section title="Race">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Species</Box>
          {labels.length > 0 ? (
            <Dropdown
              options={labels}
              selected={species.value ?? labels[0]}
              onSelected={(label: string) => {
                const match = options.find((opt) => opt.label === label);
                if (match) {
                  species.setValue(match.id);
                }
              }}
            />
          ) : (
            <Box italic color="label">
              No selectable species available.
            </Box>
          )}
        </Stack.Item>
        {flavor ? (
          <Stack.Item>
            <Box
              mt={0.25}
              p={0.5}
              style={{
                background: 'rgba(255,255,255,0.04)',
                borderLeft: '2px solid #887',
              }}
            >
              <Box italic color="label" fontSize="0.85em">
                {flavor}
              </Box>
            </Box>
          </Stack.Item>
        ) : null}
        {titlesAvailable ? (
          <Stack.Item>
            <Box mb={0.5} mt={0.5}>
              Race title
            </Box>
            <Dropdown
              options={titleBank as string[]}
              selected={displayedTitle}
              displayText={displayedTitle}
              onSelected={(label: string) => {
                title.setValue(label);
              }}
            />
          </Stack.Item>
        ) : null}
        <Stack.Item>
          <Box italic color="label" fontSize="0.85em">
            Changing race recomputes your stat matrix on save.
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.BODY,
  id: 'race',
  label: 'Race',
  component: RaceBody,
});

/**
 * @file bodies/Identity/Faith.tsx
 * @description Identity → Faith row body (I5).
 *
 * Inline Faith + Patron dropdowns. Faith options and per-faith patron
 * lists are delivered via ui_static_data. Selecting a faith server-side
 * snaps the patron to the faith godhead so the two dropdowns stay in
 * sync without a client-side round-trip.
 */

import { Box, Dropdown, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function FaithBody() {
  const { data } = useBackend<PreferencesMenuData>();
  const faith = usePrefField<string>(PREF_KEYS.FAITH, '');
  const patron = usePrefField<string>(PREF_KEYS.PATRON, '');

  // Filter out null/undefined defensively — Dropdown's internal findIndex
  // calls `option.value` on non-string entries and crashes if any option is
  // null. Server-side payload occasionally emits nulls for unbuilt faiths.
  const faithOptions = ((data.faith_options ?? []) as (string | null)[]).filter(
    (f): f is string => typeof f === 'string' && f.length > 0,
  );
  const patronsByFaith = (data.patron_options_by_faith ?? {}) as Record<
    string,
    ({ id: string; label: string } | null)[]
  >;
  const currentFaith = faith.value ?? faithOptions[0] ?? '';
  const patronOptions = (patronsByFaith[currentFaith] ?? []).filter(
    (p): p is { id: string; label: string } =>
      !!p && typeof p.id === 'string' && typeof p.label === 'string',
  );
  const patronLabels = patronOptions.map((p) => p.label);
  const currentPatron =
    patronOptions.find((p) => p.id === patron.value)?.label ??
    patronLabels[0] ??
    '';

  return (
    <Section title="Faith">
      <Stack vertical>
        <Stack.Item>
          <Box mb={0.5}>Faith</Box>
          <Dropdown
            options={faithOptions}
            selected={currentFaith}
            onSelected={(val: string) => faith.setValue(val)}
          />
        </Stack.Item>
        <Stack.Item>
          <Box mb={0.5}>Patron</Box>
          <Dropdown
            options={patronLabels}
            selected={currentPatron}
            onSelected={(label: string) => {
              const match = patronOptions.find((p) => p.label === label);
              if (match) {
                patron.setValue(match.id);
              }
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.IDENTITY,
  id: 'faith',
  label: 'Faith',
  component: FaithBody,
});

/**
 * @file bodies/ClassStats/Language.tsx
 * @description Class & Stats → Language row body.
 *
 * C5 deviation — inline dropdowns for the two triumph language slots
 * (extra_language_1 / extra_language_2). The second slot's label is
 * annotated with "(triumph cost: 1)" when a non-None value is picked,
 * matching the LanguageMenu triumph-cost flow; slot 1 is free. The
 * legacy LanguageMenu launcher stays below for edge cases (restricted
 * matrix, granted languages, admin overrides).
 */

import { Box, Button, Dropdown, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

interface LanguageSlotProps {
  slotLabel: string;
  prefKey: string;
  costLabel?: string;
  options: readonly { id: string; label: string }[];
}

function LanguageSlot({
  slotLabel,
  prefKey,
  costLabel,
  options,
}: LanguageSlotProps) {
  const field = usePrefField<string>(prefKey, 'None');
  const current = field.value ?? 'None';
  // Defensive: drop null/malformed option entries before they reach
  // <Dropdown>. tgui-core's Dropdown reads `.value` on every option
  // without a typeof guard, so a single null entry from a malformed
  // GLOB.all_languages emit would crash the entire pref menu.
  const safeOptions = options.filter(
    (opt): opt is { id: string; label: string } =>
      !!opt && typeof opt.id === 'string',
  );
  const labelFor = (opt: { id: string; label: string }): string => {
    const base =
      typeof opt.label === 'string' && opt.label.length > 0
        ? opt.label
        : opt.id;
    return opt.id !== 'None' && costLabel ? `${base} ${costLabel}` : base;
  };
  const labels = safeOptions.map((opt) => labelFor(opt));
  const currentOpt = safeOptions.find((opt) => opt.id === current);
  const displayed = currentOpt ? labelFor(currentOpt) : 'None';
  return (
    <Stack.Item>
      <Box mb={0.25}>{slotLabel}</Box>
      <Dropdown
        options={labels}
        selected={displayed}
        displayText={displayed}
        onSelected={(label: string) => {
          const idx = labels.findIndex((l) => l === label);
          if (idx >= 0) {
            field.setValue(safeOptions[idx].id);
          }
        }}
      />
    </Stack.Item>
  );
}

function LanguageBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const options = data.language_options ?? [{ id: 'None', label: 'None' }];

  return (
    <Section title="Language">
      <Stack vertical>
        <Stack.Item>
          <Box italic color="label" fontSize="0.85em">
            Extra languages beyond your species default. Slot 1 is free; slot 2
            costs 1 triumph when filled.
          </Box>
        </Stack.Item>
        <LanguageSlot
          slotLabel="Extra language (slot 1)"
          prefKey={PREF_KEYS.EXTRA_LANGUAGE_1}
          options={options}
        />
        <LanguageSlot
          slotLabel="Extra language (slot 2)"
          prefKey={PREF_KEYS.EXTRA_LANGUAGE_2}
          costLabel="(triumph cost: 1)"
          options={options}
        />
        <Stack.Item mt={0.5}>
          <Button
            icon="comments"
            onClick={() =>
              act('launch_singleton', {
                editor: 'language_menu',
                return_category: PREFS_CATEGORIES.CLASS_STATS,
                return_row: 'language',
              })
            }
          >
            Open classic Language Menu
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.CLASS_STATS,
  id: 'language',
  label: 'Language',
  component: LanguageBody,
});

/**
 * @file bodies/ClassStats/VirtueVice.tsx
 * @description Class & Stats → Virtue / Vice row body.
 *
 * C4 deviation — inline virtue (1 slot) + vice (5 slots) dropdowns
 * with verbose `name — desc` labels so players can see the gameplay
 * ability without leaving the prefs window. The legacy launcher is
 * preserved below for conflict-check flow and the second virtue slot
 * (gated by statpack = "Virtuous").
 *
 * Note: virtuetwo is intentionally not surfaced here because its
 * unlock condition is gated by the Virtuous statpack; players who
 * need it open the classic picker.
 */

import { Box, Button, Dropdown, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

const DESC_PREVIEW = 80;

/**
 * Build the dropdown label for a virtue / vice option.
 *
 * Defensive: the DM emit walks GLOB.virtues / GLOB.charflaw_singletons
 * and an entry can land here with a missing `name` or `desc`
 * (third-party module proto, partially loaded list, etc). Returning
 * `undefined`/`null` from here puts a null inside the `options` array
 * passed to <Dropdown>, and the Dropdown's internal option resolver
 * dereferences `.value` on every entry — a single null crashes the
 * whole pref menu. Always return a non-empty string.
 */
function verboseLabel(
  opt: { id: string; label: string; desc: string } | undefined,
): string {
  if (!opt) {
    return '— none —';
  }
  const label =
    typeof opt.label === 'string' && opt.label.length > 0
      ? opt.label
      : typeof opt.id === 'string' && opt.id.length > 0
        ? opt.id
        : '— unnamed —';
  if (!opt.desc) {
    return label;
  }
  const short =
    opt.desc.length > DESC_PREVIEW
      ? `${opt.desc.slice(0, DESC_PREVIEW).trimEnd()}…`
      : opt.desc;
  return `${label} — ${short}`;
}

interface TraitSlotProps {
  slotLabel: string;
  prefKey: string;
  options: readonly { id: string; label: string; desc: string }[];
}

function TraitSlot({ slotLabel, prefKey, options }: TraitSlotProps) {
  const field = usePrefField<string>(prefKey, '');
  // Strip null/garbage entries before they reach <Dropdown>. A single
  // null option crashes the dropdown renderer because tgui-core does
  // `option.value` on every entry without a typeof guard.
  const safeOptions = options.filter(
    (opt): opt is { id: string; label: string; desc: string } =>
      !!opt && typeof opt.id === 'string',
  );
  const selected = safeOptions.find((opt) => opt.id === field.value);
  const labelOptions = safeOptions.map((opt) => verboseLabel(opt));
  const selectedLabel = verboseLabel(selected);
  return (
    <Stack.Item>
      <Box mb={0.25}>{slotLabel}</Box>
      {options.length === 0 ? (
        <Box italic color="label">
          None registered.
        </Box>
      ) : (
        <Dropdown
          options={labelOptions}
          selected={selectedLabel}
          displayText={selectedLabel}
          onSelected={(label: string) => {
            const match = safeOptions.find(
              (opt) => verboseLabel(opt) === label,
            );
            if (match) {
              field.setValue(match.id);
            }
          }}
        />
      )}
    </Stack.Item>
  );
}

function VirtueViceBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const virtueOptions = data.virtue_options ?? [];
  const viceOptions = data.vice_options ?? [];

  return (
    <Section title="Virtues & Vices">
      <Stack vertical>
        <TraitSlot
          slotLabel="Virtue"
          prefKey={PREF_KEYS.VIRTUE}
          options={virtueOptions}
        />
        <TraitSlot
          slotLabel="Vice 1"
          prefKey={PREF_KEYS.VICE_1}
          options={viceOptions}
        />
        <TraitSlot
          slotLabel="Vice 2"
          prefKey={PREF_KEYS.VICE_2}
          options={viceOptions}
        />
        <TraitSlot
          slotLabel="Vice 3"
          prefKey={PREF_KEYS.VICE_3}
          options={viceOptions}
        />
        <TraitSlot
          slotLabel="Vice 4"
          prefKey={PREF_KEYS.VICE_4}
          options={viceOptions}
        />
        <TraitSlot
          slotLabel="Vice 5"
          prefKey={PREF_KEYS.VICE_5}
          options={viceOptions}
        />
        <Stack.Item mt={0.5}>
          <Button
            icon="balance-scale"
            onClick={() =>
              act('launch_singleton', {
                editor: 'virtue_vice',
                return_category: PREFS_CATEGORIES.CLASS_STATS,
                return_row: 'virtue_vice',
              })
            }
          >
            Open classic Virtue / Vice picker
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Box italic color="label" fontSize="0.85em">
            Second virtue slot unlocks in the classic picker when the Virtuous
            statpack is selected.
          </Box>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.CLASS_STATS,
  id: 'virtue_vice',
  label: 'Virtues & Vices',
  component: VirtueViceBody,
});

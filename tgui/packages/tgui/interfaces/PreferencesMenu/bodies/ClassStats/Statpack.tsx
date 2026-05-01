/**
 * @file bodies/ClassStats/Statpack.tsx
 * @description Class & Stats → Statpack row body.
 *
 * C3 deviation — inline statpack picker. Lists each statpack from
 * `data.statpack_options` as a selectable button with its flavor
 * description and a compact stat-delta summary. The legacy launcher
 * button is preserved at the bottom for users who prefer the classic
 * vices_menu window (both writes converge on the same `statpack`
 * var on /datum/preferences).
 */

import { Box, Button, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

function formatStatDelta(value: number | readonly [number, number]): string {
  if (Array.isArray(value)) {
    const [lo, hi] = value;
    return `${lo >= 0 ? '+' : ''}${lo}…${hi >= 0 ? '+' : ''}${hi}`;
  }
  const num = value as number;
  return `${num >= 0 ? '+' : ''}${num}`;
}

function formatStatArray(
  stats: Record<string, number | readonly [number, number]>,
): string {
  const parts: string[] = [];
  for (const key of Object.keys(stats)) {
    const short = key.replace(/^STAT_/, '').slice(0, 3);
    parts.push(`${short} ${formatStatDelta(stats[key])}`);
  }
  return parts.join(' · ');
}

function StatpackBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const statpack = usePrefField<string>(PREF_KEYS.STATPACK, '');
  const options = data.statpack_options ?? [];

  return (
    <Section title="Statpack">
      <Stack vertical>
        <Stack.Item>
          <Box italic color="label" fontSize="0.85em">
            Click a statpack to apply. Stat deltas below each label; hover for
            full flavor.
          </Box>
        </Stack.Item>
        {options.length === 0 ? (
          <Stack.Item>
            <Box color="label" italic>
              No statpacks registered yet — open the classic picker below.
            </Box>
          </Stack.Item>
        ) : (
          options.map((opt) => {
            const selected = statpack.value === opt.id;
            const statsLine = formatStatArray(opt.stat_array ?? {});
            return (
              <Stack.Item key={opt.id}>
                <Button
                  fluid
                  selected={selected}
                  tooltip={opt.desc}
                  onClick={() => statpack.setValue(opt.id)}
                >
                  <Box bold>{opt.label}</Box>
                  {statsLine ? (
                    <Box color="label" fontSize="0.8em">
                      {statsLine}
                    </Box>
                  ) : null}
                </Button>
              </Stack.Item>
            );
          })
        )}
        <Stack.Item mt={0.5}>
          <Button
            icon="dice"
            onClick={() =>
              act('launch_singleton', {
                editor: 'statpack',
                return_category: PREFS_CATEGORIES.CLASS_STATS,
                return_row: 'statpack',
              })
            }
          >
            Open classic Statpack picker
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.CLASS_STATS,
  id: 'statpack',
  label: 'Statpack',
  component: StatpackBody,
});

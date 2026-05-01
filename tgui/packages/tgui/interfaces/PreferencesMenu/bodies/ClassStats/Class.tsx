/**
 * @file bodies/ClassStats/Class.tsx
 * @description Class & Stats → Class row body (Addendum Turn 3 C1).
 *
 * Inline job-priority picker. Renders one collapsible section per
 * department bucket (Nobility / Garrison / Peasants / …, with any
 * uncategorized titles landing in "Other"), and one four-button row
 * per job with Off / Low / Medium / High levels. The active priority
 * highlights in gold; banned rows are disabled with a "BANNED" pill.
 *
 * Dispatch: `act('set_job_priority', { title, level })`. The envelope
 * is rate-limited server-side and validates against SSjob.occupations
 * + is_banned_from, so rapid toggles are safe.
 *
 * Data source: `job_options` (static) + `job_preferences_map` (dynamic).
 * Falls back to a legacy launcher button if the static payload is
 * absent (e.g. during the ui_assets handshake).
 */

import { useState } from 'react';
import { Box, Button, Collapsible, Section, Stack } from 'tgui-core/components';

import { useBackend } from '../../../../backend';
import { useClassPreview } from '../../ClassPreviewContext';
import { PREF_KEYS, PREFS_CATEGORIES } from '../../constants';
import { registerPrefsBody } from '../../MiddleColumn';
import type { PreferencesMenuData } from '../../types';
import { usePrefField } from '../usePrefField';

// Priority levels mirror code/__DEFINES/preferences.dm (JP_LOW=1,
// JP_MEDIUM=2, JP_HIGH=3). 0 means "off" — the server clears the slot
// rather than storing NEVER so savefiles stay compact.
const PRIORITY_LEVELS: { level: number; label: string; color: string }[] = [
  { level: 0, label: 'Off', color: 'grey' },
  { level: 1, label: 'Low', color: 'olive' },
  { level: 2, label: 'Med', color: 'good' },
  { level: 3, label: 'High', color: 'gold' },
];

// Department display order. Any bucket the server emits that isn't in
// this list gets appended alphabetically after the known ones.
const CATEGORY_ORDER = [
  'Nobility',
  'Courtiers',
  'Church',
  'Inquisition',
  'Garrison',
  'Mercenaries',
  'Yeomen',
  'Peasants',
  'Youngfolk',
  'Other',
];

const JOBLESS_RETURN_TO_LOBBY = 'Return to Lobby';
const JOBLESS_RANDOM_JOB = 'Be Random Role';

const JOBLESS_OPTIONS: readonly { value: string; label: string }[] = [
  { value: JOBLESS_RETURN_TO_LOBBY, label: 'Return to Lobby' },
  { value: JOBLESS_RANDOM_JOB, label: 'Random Role' },
];

type JobOption = NonNullable<PreferencesMenuData['job_options']>[number];

function ClassBody() {
  const { act, data } = useBackend<PreferencesMenuData>();
  const { classPreviewTitle, setClassPreviewTitle } = useClassPreview();
  const joblessRole = usePrefField<string>(
    PREF_KEYS.JOBLESS_ROLE,
    JOBLESS_RETURN_TO_LOBBY,
    { autosave: true },
  );
  const options = data.job_options ?? [];
  const priorities = data.job_preferences_map ?? {};
  const [filter, setFilter] = useState('');

  if (!options.length) {
    // Static payload hasn't landed yet — keep the legacy launcher as a
    // hard fallback so the row is never completely inert.
    return (
      <Section title="Class">
        <Box mb={1}>Loading class roster…</Box>
        <Button
          icon="user-shield"
          onClick={() =>
            act('launch_singleton', {
              editor: 'class_picker',
              return_category: PREFS_CATEGORIES.CLASS_STATS,
              return_row: 'class',
            })
          }
        >
          Open Classic Picker
        </Button>
      </Section>
    );
  }

  // Group options by category in a single pass.
  const groups: Record<string, JobOption[]> = {};
  for (const job of options) {
    if (
      filter &&
      !job.display_title.toLowerCase().includes(filter.toLowerCase())
    ) {
      continue;
    }
    const bucket = job.category || 'Other';
    (groups[bucket] ??= []).push(job);
  }

  const orderedCategories = [
    ...CATEGORY_ORDER.filter((c) => groups[c]?.length),
    ...Object.keys(groups)
      .filter((c) => !CATEGORY_ORDER.includes(c))
      .sort(),
  ];

  return (
    <Section
      title="Class"
      buttons={
        <Button
          icon="user-shield"
          tooltip="Open legacy HTML picker"
          onClick={() =>
            act('launch_singleton', {
              editor: 'class_picker',
              return_category: PREFS_CATEGORIES.CLASS_STATS,
              return_row: 'class',
            })
          }
        >
          Classic
        </Button>
      }
    >
      <Stack vertical>
        <Stack.Item>
          <Stack align="center">
            <Stack.Item grow>If role unavailable</Stack.Item>
            {JOBLESS_OPTIONS.map((option) => (
              <Stack.Item key={option.value}>
                <Button
                  selected={joblessRole.value === option.value}
                  onClick={() => joblessRole.setValue(option.value)}
                >
                  {option.label}
                </Button>
              </Stack.Item>
            ))}
          </Stack>
        </Stack.Item>
        <Stack.Item>
          <input
            type="text"
            placeholder="Filter jobs…"
            value={filter}
            onChange={(e) => setFilter(e.target.value)}
            style={{
              width: '100%',
              padding: '2px 4px',
              background: '#111',
              color: '#ddd',
              border: '1px solid #444',
            }}
          />
        </Stack.Item>
        {orderedCategories.map((category) => (
          <Stack.Item key={category}>
            <Collapsible
              title={`${category} (${groups[category]!.length})`}
              open
            >
              <Stack vertical>
                {groups[category]!.map((job) => {
                  const active = priorities[job.title] ?? 0;
                  const accent = job.selection_color || '#888';
                  const selectable = !job.banned && job.selectable !== 0;
                  const inspected = classPreviewTitle === job.title;
                  return (
                    <Stack.Item key={job.title}>
                      <Stack align="center">
                        <Stack.Item grow basis={0}>
                          <Box
                            inline
                            style={{
                              borderLeft: `3px solid ${accent}`,
                              background: inspected
                                ? 'rgba(212, 177, 100, 0.08)'
                                : undefined,
                              paddingLeft: 6,
                              paddingRight: 4,
                              opacity: selectable ? 1 : 0.4,
                            }}
                          >
                            <b>{job.display_title}</b>
                            {!!job.banned && (
                              <Box inline color="bad" ml={1}>
                                [BANNED]
                              </Box>
                            )}
                            {!job.banned && job.unavailable_reason ? (
                              <Box inline color="bad" ml={1}>
                                [{job.unavailable_reason}]
                              </Box>
                            ) : null}
                            {job.description ? (
                              <Box fontSize="0.85em" color="label">
                                {job.description}
                              </Box>
                            ) : null}
                          </Box>
                        </Stack.Item>
                        <Stack.Item>
                          <Button
                            icon="eye"
                            selected={inspected}
                            tooltip="Show class details"
                            onClick={() => setClassPreviewTitle(job.title)}
                          />
                        </Stack.Item>
                        {PRIORITY_LEVELS.map((p) => (
                          <Stack.Item key={p.level}>
                            <Button
                              disabled={!selectable}
                              selected={active === p.level}
                              color={active === p.level ? p.color : undefined}
                              onClick={() => {
                                setClassPreviewTitle(job.title);
                                act('set_job_priority', {
                                  title: job.title,
                                  level: p.level,
                                });
                              }}
                            >
                              {p.label}
                            </Button>
                          </Stack.Item>
                        ))}
                      </Stack>
                    </Stack.Item>
                  );
                })}
              </Stack>
            </Collapsible>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
}

registerPrefsBody({
  category: PREFS_CATEGORIES.CLASS_STATS,
  id: 'class',
  label: 'Class',
  component: ClassBody,
});

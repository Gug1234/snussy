/**
 * @file RightColumn.tsx
 * @description Persistent preview pane of the Elden-Ring shell.
 *
 * Mounts `<CharacterPreviewMapView/>` ONCE for the lifetime of the
 * window. Re-mounting on body switch would force a BYOND map control
 * re-init and defeat the live-preview win (spec §1.3 critical path).
 *
 * Step 9 additions: stat-matrix table under the preview and a single
 * Examine-preview button (acts as the singleton entry point per
 * spec §3.2; the actual preview window lands in Step 14).
 */

import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Section,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import { CharacterPreviewMapView } from '../../components/appearance-preview';
import { IntimateAccessoryOffsetPreviewPanel } from './bodies/Intimacy/IntimateAccessoryOffsetEditor';
import { useClassPreview } from './ClassPreviewContext';
import { PREFS_CATEGORIES, type PrefsCategoryId } from './constants';
import type { PreferencesMenuData } from './types';
import { StatMatrix } from './widgets';

type JobOption = NonNullable<PreferencesMenuData['job_options']>[number];

interface RightColumnProps {
  activeCategory: PrefsCategoryId;
  activeRow: string | null;
}

function formatStatName(stat: string): string {
  return stat.charAt(0).toUpperCase() + stat.slice(1);
}

function formatStatValue(value: number, signed = true): string {
  if (!signed) {
    return `${value}`;
  }
  return value > 0 ? `+${value}` : `${value}`;
}

function StatValueList(props: {
  values?: Record<string, number>;
  signed?: boolean;
}) {
  const entries = Object.entries(props.values ?? {}).filter(
    ([, value]) => value !== 0,
  );
  if (!entries.length) {
    return null;
  }
  return (
    <Box color="label" fontSize="0.9em">
      {entries.map(([stat, value]) => (
        <Box inline key={stat} mr={1} color={value > 0 ? 'good' : 'bad'}>
          {formatStatName(stat)} {formatStatValue(value, props.signed)}
        </Box>
      ))}
    </Box>
  );
}

function TraitList(props: { traits?: JobOption['job_traits'] }) {
  const traits = props.traits ?? [];
  if (!traits.length) {
    return null;
  }
  return (
    <Stack vertical mt={0.5}>
      {traits.map((trait) => (
        <Stack.Item key={trait.id}>
          <Box color="gold">{trait.id}</Box>
          {trait.desc ? (
            <Box color="label" fontSize="0.85em">
              {trait.desc}
            </Box>
          ) : null}
        </Stack.Item>
      ))}
    </Stack>
  );
}

function pickDefaultJob(
  options: readonly JobOption[],
  priorities: Record<string, number>,
  classPreviewTitle: string | null,
): JobOption | undefined {
  const inspected = options.find((job) => job.title === classPreviewTitle);
  if (inspected) {
    return inspected;
  }
  let bestJob: JobOption | undefined;
  let bestPriority = 0;
  for (const job of options) {
    const priority = priorities[job.title] ?? 0;
    if (priority > bestPriority) {
      bestJob = job;
      bestPriority = priority;
    }
  }
  return (
    bestJob ??
    options.find(
      (job) =>
        (job.advclasses?.length ?? 0) > 0 ||
        Object.keys(job.job_stats ?? {}).length > 0 ||
        (job.job_traits?.length ?? 0) > 0,
    ) ??
    options[0]
  );
}

function ClassDetailsColumn() {
  const { data } = useBackend<PreferencesMenuData>();
  const { classPreviewTitle, setClassPreviewTitle } = useClassPreview();
  const options = data.job_options ?? [];
  const priorities = data.job_preferences_map ?? {};
  const selectedJob = pickDefaultJob(options, priorities, classPreviewTitle);
  const optionLabels = options.map(
    (job) => `${job.display_title} (${job.category || 'Other'})`,
  );
  const selectedLabel = selectedJob
    ? `${selectedJob.display_title} (${selectedJob.category || 'Other'})`
    : '';

  return (
    <Section className="PrefsMenu__rightColumn" title="Class Details" fill>
      {!selectedJob ? (
        <Box color="label">No class selected.</Box>
      ) : (
        <Stack vertical>
          <Stack.Item>
            <Dropdown
              options={optionLabels}
              selected={selectedLabel}
              displayText={selectedLabel}
              onSelected={(label: string) => {
                const index = optionLabels.indexOf(label);
                const job = options[index];
                if (job) {
                  setClassPreviewTitle(job.title);
                }
              }}
            />
          </Stack.Item>
          <Stack.Item>
            <Box fontSize="1.15em" bold color="gold">
              {selectedJob.display_title}
            </Box>
            {selectedJob.description ? (
              <Box color="label" fontSize="0.9em">
                {selectedJob.description}
              </Box>
            ) : null}
          </Stack.Item>
          {Object.keys(selectedJob.job_stats ?? {}).length ? (
            <Stack.Item>
              <Box bold>Class Stats</Box>
              <StatValueList values={selectedJob.job_stats} />
            </Stack.Item>
          ) : null}
          {(selectedJob.job_traits?.length ?? 0) > 0 ? (
            <Stack.Item>
              <Box bold>Class Traits</Box>
              <TraitList traits={selectedJob.job_traits} />
            </Stack.Item>
          ) : null}
          {Object.keys(selectedJob.stat_ceilings ?? {}).length ? (
            <Stack.Item>
              <Box bold color="bad">
                Class Stat Limits
              </Box>
              <StatValueList
                values={selectedJob.stat_ceilings}
                signed={false}
              />
            </Stack.Item>
          ) : null}
          {(selectedJob.advclasses?.length ?? 0) > 0 ? (
            <Stack.Item>
              <Box bold mb={0.5}>
                Advanced Classes
              </Box>
              <Stack vertical>
                {selectedJob.advclasses!.map((advclass, index) => (
                  <Stack.Item key={advclass.id}>
                    <Collapsible title={advclass.name} open={index === 0}>
                      <Stack vertical>
                        {advclass.tutorial ? (
                          <Stack.Item>
                            <Box color="label" fontSize="0.9em">
                              {advclass.tutorial}
                            </Box>
                          </Stack.Item>
                        ) : null}
                        {Object.keys(advclass.subclass_stats ?? {}).length ? (
                          <Stack.Item>
                            <Box bold>Stat Gains</Box>
                            <StatValueList values={advclass.subclass_stats} />
                          </Stack.Item>
                        ) : null}
                        {(advclass.traits?.length ?? 0) > 0 ? (
                          <Stack.Item>
                            <Box bold>Trait Gains</Box>
                            <TraitList traits={advclass.traits} />
                          </Stack.Item>
                        ) : null}
                        {Object.keys(advclass.stat_ceilings ?? {}).length ? (
                          <Stack.Item>
                            <Box bold color="bad">
                              Stat Limits
                            </Box>
                            <StatValueList
                              values={advclass.stat_ceilings}
                              signed={false}
                            />
                          </Stack.Item>
                        ) : null}
                        {advclass.spellpoints ? (
                          <Stack.Item>
                            <Box color="label">
                              Spellpoints: <b>{advclass.spellpoints}</b>
                            </Box>
                          </Stack.Item>
                        ) : null}
                        {(advclass.languages?.length ?? 0) > 0 ? (
                          <Stack.Item>
                            <Box color="label">
                              Languages: {advclass.languages!.join(', ')}
                            </Box>
                          </Stack.Item>
                        ) : null}
                        {(advclass.skills?.length ?? 0) > 0 ? (
                          <Stack.Item>
                            <Box bold>Notable Skills</Box>
                            {advclass.skills!.map((skill) => (
                              <Box
                                key={`${skill.name}-${skill.level}`}
                                color="label"
                              >
                                {skill.name} — {skill.level}
                              </Box>
                            ))}
                          </Stack.Item>
                        ) : null}
                        {(advclass.stashed_items?.length ?? 0) > 0 ? (
                          <Stack.Item>
                            <Box bold>Stashed Items</Box>
                            {advclass.stashed_items!.map((item) => (
                              <Box key={item} color="label">
                                {item}
                              </Box>
                            ))}
                          </Stack.Item>
                        ) : null}
                        {advclass.extra_context ? (
                          <Stack.Item>
                            <Box color="label" fontSize="0.9em">
                              {advclass.extra_context}
                            </Box>
                          </Stack.Item>
                        ) : null}
                      </Stack>
                    </Collapsible>
                  </Stack.Item>
                ))}
              </Stack>
            </Stack.Item>
          ) : (
            <Stack.Item>
              <Box color="label" italic>
                No advanced class options registered.
              </Box>
            </Stack.Item>
          )}
        </Stack>
      )}
    </Section>
  );
}

/**
 * RightColumn — mannequin preview + stat matrix + examine.
 *
 * The component is intentionally devoid of effects/state so React
 * never re-renders the map control on shell route changes; only a
 * change in `character_preview_view` (rare, on slot reload) does.
 * StatMatrix is also pure-render and bails out when `stat_matrix` is
 * undefined, so a cold first-open never costs anything extra here.
 */
export function RightColumn(props: RightColumnProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const { character_preview_view, stat_matrix } = data;

  if (
    props.activeCategory === PREFS_CATEGORIES.CLASS_STATS &&
    props.activeRow === 'class'
  ) {
    return <ClassDetailsColumn />;
  }

  if (
    props.activeCategory === PREFS_CATEGORIES.INTIMACY &&
    props.activeRow === 'intimate_accessory'
  ) {
    return (
      <Section className="PrefsMenu__rightColumn" title="Accessory Offset" fill>
        <IntimateAccessoryOffsetPreviewPanel />
      </Section>
    );
  }

  return (
    <Section className="PrefsMenu__rightColumn" title="Preview" fill>
      <Stack vertical fill>
        <Stack.Item>
          <Box>
            <CharacterPreviewMapView
              mapId={character_preview_view}
              width={192}
              height={192}
            />
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="eye"
            tooltip="Open the examine preview window"
            onClick={() => act('request_examine_preview')}
          >
            Preview Examine
          </Button>
        </Stack.Item>
        <Stack.Item grow>
          <StatMatrix data={stat_matrix} />
        </Stack.Item>
      </Stack>
    </Section>
  );
}

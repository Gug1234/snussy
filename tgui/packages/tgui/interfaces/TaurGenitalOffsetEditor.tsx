/**
 * @file TaurGenitalOffsetEditor.tsx
 * @description Per-direction taur genital sprite tuning panel. Players pick a
 * part (penis/testicles/vagina) and a direction (S/N/E/W) and adjust x/y/turn/
 * flip/above/hide/shrink for just that combination. The editor is now
 * numeric-only; the lobby mannequin is the only preview source of truth.
 */

import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  LabeledList,
  NumberInput,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';

type PartKey = 'penis' | 'testicles' | 'vagina';
type DirKey = 's' | 'n' | 'e' | 'w';
type FieldKey = 'x' | 'y' | 'turn' | 'flip' | 'above' | 'hide' | 'shrink';

type PartProps = Record<string, number>;

type BackendData = {
  active_part: PartKey;
  active_erect_state: number;
  active_dir: DirKey;
  part_keys: PartKey[];
  erect_state_keys: number[];
  erect_state_labels: Record<number, string>;
  dir_keys: DirKey[];
  field_keys: FieldKey[];
  props: Record<PartKey, PartProps>;
  global_hide: Record<DirKey, number>;
};

const DIR_LABELS: Record<DirKey, string> = {
  s: 'South',
  n: 'North',
  e: 'East',
  w: 'West',
};

const PART_LABELS: Record<PartKey, string> = {
  penis: 'Penis',
  testicles: 'Testicles',
  vagina: 'Vagina',
};

// Drag sensitivity constants.
const ROT_PER_PIXEL = 1.5; // degrees per horizontal pixel during RMB drag
const SCALE_PER_PIXEL = 0.01; // shrink delta per vertical pixel during MMB drag
// Native sprite-space size of the preview canvas (server renders 32x32
// mannequin into a 96x96 transparent canvas so parts can be offset well past
// the body edge without clipping).
const PREVIEW_SPRITE_PX = 96;
// Preview image display size (square, px). Used to scale the ghost overlay.
const PREVIEW_PX = 288;
// Clamps matching the server-side `_apply_field` bounds.
const XY_MIN = -64;
const XY_MAX = 64;
const SHRINK_MIN = 0.1;
const SHRINK_MAX = 4.0;
const clamp = (v: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, v));

export function TaurGenitalOffsetEditor(props) {
  const { act, data } = useBackend<BackendData>();
  const {
    active_part,
    active_erect_state,
    active_dir,
    part_keys = [],
    erect_state_keys = [],
    erect_state_labels = {},
    dir_keys = [],
    props: allProps = {} as Record<PartKey, PartProps>,
    global_hide = {} as Record<DirKey, number>,
  } = data;

  const currentProps = allProps[active_part] ?? {};
  const activeStateLabel =
    active_part === 'penis'
      ? erect_state_labels[active_erect_state] ?? 'Arousal'
      : null;
  const k = (field: FieldKey) => `${active_dir}${field}`;
  const val = (field: FieldKey, fallback = 0): number => {
    const v = currentProps[k(field)];
    return typeof v === 'number' ? v : fallback;
  };

  return (
    <Window theme="rogue">
      <Window.Content scrollable>
        <Section title="Taur Genital Offsets">
          <Box mb={1} opacity={0.6} fontSize="11px" italic>
            Tune per-direction sprite placement for each taur genital. Use the
            number inputs below; the lobby mannequin updates separately.
          </Box>

          <Tabs>
            {part_keys.map((p) => (
              <Tabs.Tab
                key={p}
                selected={p === active_part}
                onClick={() => act('select_part', { part: p })}
              >
                {PART_LABELS[p]}
              </Tabs.Tab>
            ))}
          </Tabs>

          {active_part === 'penis' && (
            <Box mt={1}>
              <Tabs>
                {erect_state_keys.map((state) => (
                  <Tabs.Tab
                    key={state}
                    selected={state === active_erect_state}
                    onClick={() => act('select_state', { state })}
                  >
                    {erect_state_labels[state] ?? `State ${state}`}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Box>
          )}

          <Box mt={1}>
            <Section
              title={`${PART_LABELS[active_part]}${activeStateLabel ? ` — ${activeStateLabel}` : ''} — ${DIR_LABELS[active_dir]}`}
              buttons={
                <>
                  <Button
                    icon="undo"
                    compact
                    tooltip={
                      active_part === 'penis'
                        ? 'Reset this direction in the current arousal state to defaults'
                        : 'Reset this direction to defaults'
                    }
                    onClick={() =>
                      act('reset_dir', {
                        part: active_part,
                        dir: active_dir,
                      })
                    }
                  >
                    Reset Dir
                  </Button>
                  <Button
                    icon="undo-alt"
                    color="bad"
                    compact
                    tooltip={
                      active_part === 'penis'
                        ? 'Reset all directions in every arousal state to defaults'
                        : 'Reset ALL directions of this part to defaults'
                    }
                    onClick={() => act('reset_part', { part: active_part })}
                  >
                    Reset Part
                  </Button>
                  <Button
                    compact
                    tooltip="Copy East to West with X and rotation mirrored, Y preserved"
                    onClick={() =>
                      act('mirror_east_to_west', {
                        part: active_part,
                      })
                    }
                  >
                    Mirror E -&gt; W
                  </Button>
                </>
              }
            >
              <Tabs>
                {dir_keys.map((d) => (
                  <Tabs.Tab
                    key={d}
                    selected={d === active_dir}
                    onClick={() => act('select_dir', { dir: d })}
                  >
                    {DIR_LABELS[d]}
                  </Tabs.Tab>
                ))}
              </Tabs>

              <LabeledList>
                <LabeledList.Item label="Offset X">
                  <NumberInput
                    width="60px"
                    step={1}
                    stepPixelSize={4}
                    value={val('x')}
                    minValue={-64}
                    maxValue={64}
                    onChange={(value) =>
                      act('set_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'x',
                        value,
                      })
                    }
                  />
                  <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
                </LabeledList.Item>
                <LabeledList.Item label="Offset Y">
                  <NumberInput
                    width="60px"
                    step={1}
                    stepPixelSize={4}
                    value={val('y')}
                    minValue={-64}
                    maxValue={64}
                    onChange={(value) =>
                      act('set_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'y',
                        value,
                      })
                    }
                  />
                  <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
                </LabeledList.Item>
                <LabeledList.Item label="Rotation">
                  <NumberInput
                    width="60px"
                    step={5}
                    stepPixelSize={4}
                    value={val('turn')}
                    minValue={-359}
                    maxValue={359}
                    onChange={(value) =>
                      act('set_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'turn',
                        value,
                      })
                    }
                  />
                  <span style={{ opacity: 0.4, marginLeft: '6px' }}>deg</span>
                </LabeledList.Item>
                <LabeledList.Item label="Scale">
                  <NumberInput
                    width="70px"
                    step={0.05}
                    stepPixelSize={4}
                    value={val('shrink', 1.0)}
                    minValue={0.1}
                    maxValue={4.0}
                    onChange={(value) =>
                      act('set_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'shrink',
                        value,
                      })
                    }
                  />
                  <span style={{ opacity: 0.4, marginLeft: '6px' }}>x</span>
                  {(active_part === 'penis' || active_part === 'testicles') &&
                    val('shrink', 1) >= 3 && (
                      <span
                        style={{
                          marginLeft: '8px',
                          fontSize: '11px',
                          fontStyle: 'italic',
                          color: '#c97a7a',
                          opacity: 0.85,
                        }}
                      >
                        very mature.
                      </span>
                    )}
                </LabeledList.Item>
                <LabeledList.Item label="Horizontal Flip">
                  <Button.Checkbox
                    checked={!!val('flip')}
                    onClick={() =>
                      act('toggle_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'flip',
                      })
                    }
                  >
                    {val('flip') ? 'Flipped' : 'Normal'}
                  </Button.Checkbox>
                </LabeledList.Item>
                <LabeledList.Item label="Layer">
                  <Button.Checkbox
                    checked={!!val('above')}
                    onClick={() =>
                      act('toggle_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'above',
                      })
                    }
                  >
                    {val('above') ? 'Over Body' : 'Under Body'}
                  </Button.Checkbox>
                </LabeledList.Item>
                <LabeledList.Item label="Hide">
                  <Button.Checkbox
                    checked={!!val('hide')}
                    color={val('hide') ? 'bad' : undefined}
                    onClick={() =>
                      act('toggle_field', {
                        part: active_part,
                        dir: active_dir,
                        field: 'hide',
                      })
                    }
                  >
                    {val('hide') ? 'Hidden this direction' : 'Visible'}
                  </Button.Checkbox>
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Box>
        </Section>

        <Section title="Global Per-Direction Hide">
          <Box mb={1} opacity={0.6} fontSize="11px" italic>
            Hides ALL taur genital sprites (not just this part) when the
            character faces the toggled direction. Stacks on top of per-part
            hide.
          </Box>
          <Stack>
            {(dir_keys as DirKey[]).map((d) => (
              <Stack.Item key={d} grow>
                <Button.Checkbox
                  fluid
                  checked={!!global_hide[d]}
                  color={global_hide[d] ? 'bad' : undefined}
                  onClick={() => act('toggle_global_hide', { dir: d })}
                >
                  {DIR_LABELS[d]}
                </Button.Checkbox>
              </Stack.Item>
            ))}
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
}


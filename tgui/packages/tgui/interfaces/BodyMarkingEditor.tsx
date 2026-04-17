/**
 * @file BodyMarkingEditor.tsx
 * @description Per-character body marking editor. Pairs with
 * /datum/body_marking_editor (modular/code/modules/client/body_marking_editor.dm).
 *
 * Layout: three-column Stack inside a Window. The left column is a zone
 * picker, the middle column is the active zone's entry list plus add /
 * preset / reset controls, and the right column is the detail editor for
 * the currently selected entry (color, offset nudge pad, rotation / scale /
 * flip). All persistent state lives on the backend; the only client-side
 * state is transient UI selection (`selectedEntryName`) plus debounced
 * text-input buffers for the color hex field and absolute-offset numeric
 * entry.
 */

import { useEffect, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  DmIcon,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NumberInput,
  Section,
  Stack,
} from 'tgui-core/components';

// ── Types ────────────────────────────────────────────────────────────────────

type MarkingEntry = {
  name: string;
  color: string;
  pixel_x: number;
  pixel_y: number;
  flip_x: number | boolean;
  flip_y: number | boolean;
  rotation: number;
  scale: number;
};

type MarkingZone = {
  id: string;
  label: string;
  entries: MarkingEntry[];
};

type AvailableMarking = {
  name: string;
  key: string;
  icon: string;
  icon_state: string;
  affected_bodyparts: number;
  default_color: string;
};

type MarkingSet = {
  name: string;
  key: string;
};

type BodyMarkingEditorData = {
  active_zone: string;
  zones: MarkingZone[];
  available_markings: AvailableMarking[];
  sets: MarkingSet[];
  max_per_zone: number;
  offset_min: number;
  offset_max: number;
};

// ── Constants ────────────────────────────────────────────────────────────────

// Body zone → bitflag. Mirrors code/__DEFINES/_bodyparts.dm; kept local so the
// TSX stays self-contained per the phase-4 guardrails. Used only to badge
// "(may not render)" hints on incompatible markings in the add-dropdown; the
// server is the source of truth for compatibility enforcement.
const ZONE_BODYPART_FLAGS: Record<string, number> = {
  head: 1 << 0, // BODY_FLAG_HEAD
  chest: 1 << 1, // BODY_FLAG_CHEST
  l_arm: 1 << 3, // BODY_FLAG_LEFT_ARM
  r_arm: 1 << 2, // BODY_FLAG_RIGHT_ARM
  l_leg: 1 << 5, // BODY_FLAG_LEFT_LEG
  r_leg: 1 << 4, // BODY_FLAG_RIGHT_LEG
  l_hand: 1 << 3, // treated as left arm for compatibility hint
  r_hand: 1 << 2, // treated as right arm for compatibility hint
};

const ROTATION_CHOICES = [0, 90, 180, 270] as const;
const SCALE_CHOICES = [1, 2] as const;
const HEX_COLOR_RE = /^[0-9A-Fa-f]{6}$/;

const PREVIEW_SIZE = 96;

// ── Helpers ──────────────────────────────────────────────────────────────────

function clamp(value: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, value));
}

function toBool(v: number | boolean): boolean {
  return !!v;
}

function findZone(
  zones: MarkingZone[],
  id: string,
): MarkingZone | undefined {
  return zones.find((z) => z.id === id);
}

// ── Top-level component ──────────────────────────────────────────────────────

export function BodyMarkingEditor(props) {
  const { act, data } = useBackend<BodyMarkingEditorData>();
  const {
    active_zone,
    zones = [],
    max_per_zone,
  } = data;

  const activeZone = findZone(zones, active_zone);
  const entries = activeZone?.entries ?? [];

  // Transient UI selection — auto-follows the first entry of the active zone
  // whenever the active zone changes or the previously selected entry is
  // removed. The server doesn't track "selected entry"; everything is
  // addressed by (zone, name) tuples in ui_act.
  const [selectedEntryName, setSelectedEntryName] = useState<string | null>(
    entries[0]?.name ?? null,
  );
  useEffect(() => {
    if (!activeZone) {
      setSelectedEntryName(null);
      return;
    }
    if (
      selectedEntryName === null ||
      !entries.some((e) => e.name === selectedEntryName)
    ) {
      setSelectedEntryName(entries[0]?.name ?? null);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [active_zone, entries.map((e) => e.name).join('|')]);

  const selectedEntry =
    entries.find((e) => e.name === selectedEntryName) ?? null;

  return (
    <Window theme="rogue" width={780} height={560}>
      <Window.Content>
        <Section
          title="Body Markings Editor"
          fill
          buttons={
            <>
              <Button icon="save" color="good" onClick={() => act('save')}>
                Save
              </Button>
              <Button icon="times" onClick={() => act('close')}>
                Close
              </Button>
            </>
          }
        >
          <Stack fill>
            <Stack.Item basis="18%" shrink={0}>
              <ZonePicker />
            </Stack.Item>
            <Stack.Item basis="32%" shrink={0}>
              <ZoneEntryList
                zone={activeZone}
                selectedEntryName={selectedEntryName}
                onSelectEntry={setSelectedEntryName}
                maxPerZone={max_per_zone}
              />
            </Stack.Item>
            <Stack.Item grow>
              {activeZone && selectedEntry ? (
                <EntryDetailPanel
                  zoneId={activeZone.id}
                  entry={selectedEntry}
                />
              ) : (
                <Section title="Marking details" fill>
                  <Box opacity={0.6} italic>
                    {activeZone
                      ? 'Add a marking on the left to edit it.'
                      : 'Select a body zone to begin.'}
                  </Box>
                </Section>
              )}
            </Stack.Item>
          </Stack>
        </Section>
      </Window.Content>
    </Window>
  );
}

// ── Zone picker (left column) ────────────────────────────────────────────────

function ZonePicker() {
  const { act, data } = useBackend<BodyMarkingEditorData>();
  const { active_zone, zones = [], max_per_zone } = data;

  return (
    <Section title="Body zones" fill scrollable>
      <Stack vertical>
        {zones.map((zone) => {
          const count = zone.entries.length;
          const selected = zone.id === active_zone;
          return (
            <Stack.Item key={zone.id}>
              <Button
                fluid
                selected={selected}
                onClick={() => act('select_zone', { zone: zone.id })}
              >
                <Flex align="center">
                  <Flex.Item grow={1}>{zone.label}</Flex.Item>
                  <Flex.Item
                    ml={0.5}
                    style={{ opacity: count > 0 ? 1 : 0.5 }}
                  >
                    {count}/{max_per_zone}
                  </Flex.Item>
                </Flex>
              </Button>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
}

// ── Zone entry list + add / preset / reset controls (middle column) ─────────

function ZoneEntryList(props: {
  zone: MarkingZone | undefined;
  selectedEntryName: string | null;
  onSelectEntry: (name: string | null) => void;
  maxPerZone: number;
}) {
  const { act, data } = useBackend<BodyMarkingEditorData>();
  const { zone, selectedEntryName, onSelectEntry, maxPerZone } = props;
  const { available_markings = [], sets = [] } = data;

  const entries = zone?.entries ?? [];
  const atCap = entries.length >= maxPerZone;

  // Add-dropdown local state. We keep the picked marking name separate from
  // the server state so the user can preview their selection before
  // committing with the "Add" button.
  const [pickedMarking, setPickedMarking] = useState<string | null>(null);
  const [pickedSet, setPickedSet] = useState<string | null>(null);

  const zoneFlag = zone ? ZONE_BODYPART_FLAGS[zone.id] ?? 0 : 0;

  // Build dropdown options; hint-flag incompatible markings without filtering
  // them out. Server still accepts them if its per-limb registry permits.
  const markingOptions = available_markings.map((m) => {
    const compatible =
      zoneFlag === 0 || (m.affected_bodyparts & zoneFlag) !== 0;
    return {
      value: m.name,
      displayText: compatible ? m.name : `${m.name} (may not render)`,
    };
  });

  const setOptions = sets.map((s) => ({
    value: s.name,
    displayText: s.name,
  }));

  const pickedMarkingInfo = available_markings.find(
    (m) => m.name === pickedMarking,
  );

  return (
    <Section
      title={zone ? `${zone.label} (${entries.length}/${maxPerZone})` : 'Zone'}
      fill
      scrollable
    >
      {!zone && (
        <Box opacity={0.6} italic>
          No zone selected.
        </Box>
      )}

      {!!zone && (
        <>
          <Stack vertical>
            {entries.length === 0 && (
              <Stack.Item>
                <Box opacity={0.6} italic>
                  No markings on this zone yet.
                </Box>
              </Stack.Item>
            )}
            {entries.map((entry, idx) => {
              const selected = entry.name === selectedEntryName;
              return (
                <Stack.Item key={entry.name}>
                  <Flex align="center">
                    <Flex.Item grow={1}>
                      <Button
                        fluid
                        selected={selected}
                        onClick={() => onSelectEntry(entry.name)}
                      >
                        <Flex align="center">
                          <Flex.Item>
                            <Box
                              inline
                              style={{
                                display: 'inline-block',
                                width: '12px',
                                height: '12px',
                                marginRight: '6px',
                                verticalAlign: 'middle',
                                backgroundColor: `#${entry.color}`,
                                border: '1px solid #222',
                              }}
                            />
                          </Flex.Item>
                          <Flex.Item grow={1}>{entry.name}</Flex.Item>
                        </Flex>
                      </Button>
                    </Flex.Item>
                    <Flex.Item ml={0.5}>
                      <Button
                        icon="arrow-up"
                        tooltip="Move up"
                        disabled={idx === 0}
                        onClick={() =>
                          act('reorder', {
                            zone: zone.id,
                            name: entry.name,
                            direction: 'up',
                          })
                        }
                      />
                      <Button
                        icon="arrow-down"
                        tooltip="Move down"
                        disabled={idx === entries.length - 1}
                        onClick={() =>
                          act('reorder', {
                            zone: zone.id,
                            name: entry.name,
                            direction: 'down',
                          })
                        }
                      />
                      <Button
                        icon="times"
                        color="bad"
                        tooltip="Remove"
                        onClick={() =>
                          act('remove_entry', {
                            zone: zone.id,
                            name: entry.name,
                          })
                        }
                      />
                    </Flex.Item>
                  </Flex>
                </Stack.Item>
              );
            })}
          </Stack>

          <Box mt={1}>
            <Box bold mb={0.5}>
              Add marking
            </Box>
            <Flex align="center">
              <Flex.Item grow={1}>
                <Dropdown
                  width="100%"
                  selected={pickedMarking ?? ''}
                  options={markingOptions}
                  onSelected={(value: string) => setPickedMarking(value)}
                />
              </Flex.Item>
              <Flex.Item ml={0.5}>
                <Button
                  icon="plus"
                  color="good"
                  disabled={atCap || !pickedMarking}
                  tooltip={
                    atCap
                      ? `Max ${maxPerZone} per zone`
                      : pickedMarking
                        ? undefined
                        : 'Pick a marking first'
                  }
                  onClick={() => {
                    if (!pickedMarking) {
                      return;
                    }
                    act('add_marking', {
                      zone: zone.id,
                      name: pickedMarking,
                    });
                  }}
                >
                  Add
                </Button>
              </Flex.Item>
            </Flex>
            {!!pickedMarkingInfo && (
              <Box mt={0.5} opacity={0.8} fontSize="11px">
                <DmIcon
                  icon={pickedMarkingInfo.icon}
                  icon_state={pickedMarkingInfo.icon_state}
                  width={24}
                  height={24}
                />
                <Box inline ml={0.5} verticalAlign="middle">
                  {pickedMarkingInfo.icon_state}
                </Box>
              </Box>
            )}
          </Box>

          <Box mt={1}>
            <Box bold mb={0.5}>
              Apply preset
            </Box>
            <Flex align="center">
              <Flex.Item grow={1}>
                <Dropdown
                  width="100%"
                  selected={pickedSet ?? ''}
                  options={setOptions}
                  onSelected={(value: string) => setPickedSet(value)}
                />
              </Flex.Item>
              <Flex.Item ml={0.5}>
                <Button
                  icon="paint-brush"
                  disabled={!pickedSet}
                  tooltip="Overwrites ALL zones with the preset contents."
                  onClick={() => {
                    if (!pickedSet) {
                      return;
                    }
                    act('apply_set', { set: pickedSet });
                  }}
                >
                  Apply
                </Button>
              </Flex.Item>
            </Flex>
            <Box mt={0.5} opacity={0.6} fontSize="11px" italic>
              Presets replace every zone&apos;s markings.
            </Box>
          </Box>

          <Box mt={1}>
            <Button
              icon="undo"
              onClick={() => act('reset_zone', { zone: zone.id })}
            >
              Reset Zone
            </Button>
            <Button
              ml={0.5}
              icon="undo"
              color="bad"
              onClick={() => act('reset_all')}
            >
              Reset All
            </Button>
          </Box>
        </>
      )}
    </Section>
  );
}

// ── Entry detail panel (right column) ────────────────────────────────────────

function EntryDetailPanel(props: { zoneId: string; entry: MarkingEntry }) {
  const { zoneId, entry } = props;
  return (
    <Section title={`Editing: ${entry.name}`} fill scrollable>
      <EntryPreview zoneId={zoneId} entry={entry} />
      <Box mt={1}>
        <ColorEditor zoneId={zoneId} entry={entry} />
      </Box>
      <Box mt={1}>
        <OffsetEditor zoneId={zoneId} entry={entry} />
      </Box>
      <Box mt={1}>
        <TransformEditor zoneId={zoneId} entry={entry} />
      </Box>
      <Box mt={1}>
        <ResetEntryButton zoneId={zoneId} entry={entry} />
      </Box>
    </Section>
  );
}

// Looks up the full marking descriptor from `available_markings` by name so
// the preview/detail panel can draw the DMI thumbnail.
function useMarkingInfo(name: string): AvailableMarking | undefined {
  const { data } = useBackend<BodyMarkingEditorData>();
  return data.available_markings?.find((m) => m.name === name);
}

function EntryPreview(props: { zoneId: string; entry: MarkingEntry }) {
  const { entry } = props;
  const info = useMarkingInfo(entry.name);

  // Build CSS transform. Server stores rotation in 0/90/180/270 and scale in
  // {1, 2}; flips are booleans. We translate first so rotation pivots around
  // the post-offset origin, matching how the in-world sprite is composited.
  const sx = (toBool(entry.flip_x) ? -1 : 1) * entry.scale;
  const sy = (toBool(entry.flip_y) ? -1 : 1) * entry.scale;
  const transform = `translate(${entry.pixel_x}px, ${-entry.pixel_y}px) rotate(${entry.rotation}deg) scale(${sx}, ${sy})`;

  return (
    <Box>
      <Box bold mb={0.5}>
        Preview
      </Box>
      <Box
        style={{
          position: 'relative',
          width: `${PREVIEW_SIZE}px`,
          height: `${PREVIEW_SIZE}px`,
          border: '1px solid rgba(255, 255, 255, 0.25)',
          background:
            'repeating-conic-gradient(#222 0% 25%, #333 0% 50%) 50% / 16px 16px',
          overflow: 'hidden',
        }}
      >
        {!!info && (
          <Box
            style={{
              position: 'absolute',
              left: '50%',
              top: '50%',
              marginLeft: '-16px',
              marginTop: '-16px',
              transform,
              transformOrigin: 'center center',
            }}
          >
            <DmIcon
              icon={info.icon}
              icon_state={info.icon_state}
              width={32}
              height={32}
            />
            {/*
              DmIcon doesn't composite color like the in-world `color` matrix,
              so we approximate by stacking a multiply overlay on top of the
              icon. Final in-world appearance is still server-authoritative;
              this is a positioning aid, not a WYSIWYG.
            */}
            <Box
              style={{
                position: 'absolute',
                left: 0,
                top: 0,
                width: '32px',
                height: '32px',
                backgroundColor: `#${entry.color}`,
                mixBlendMode: 'multiply',
                opacity: 0.55,
                pointerEvents: 'none',
              }}
            />
          </Box>
        )}
      </Box>
      <Box mt={0.5} opacity={0.6} fontSize="11px" italic>
        Offset / rotate / flip / scale preview. Final color is composited by
        the game; this overlay is a positioning aid.
      </Box>
    </Box>
  );
}

function ColorEditor(props: { zoneId: string; entry: MarkingEntry }) {
  const { act } = useBackend<BodyMarkingEditorData>();
  const { zoneId, entry } = props;
  const [draft, setDraft] = useState(entry.color);

  // Reset the draft whenever the committed value changes (e.g. reset_entry
  // from elsewhere). We compare to the committed value to avoid stomping on
  // in-progress edits when ui_data re-emits for unrelated reasons.
  useEffect(() => {
    setDraft(entry.color);
  }, [entry.color]);

  const commit = () => {
    const normalized = draft.replace(/^#/, '');
    if (!HEX_COLOR_RE.test(normalized)) {
      setDraft(entry.color);
      return;
    }
    if (normalized.toLowerCase() === entry.color.toLowerCase()) {
      return;
    }
    act('set_color', {
      zone: zoneId,
      name: entry.name,
      color: normalized,
    });
  };

  const valid = HEX_COLOR_RE.test(draft.replace(/^#/, ''));

  return (
    <Box>
      <Box bold mb={0.5}>
        Color
      </Box>
      <Flex align="center">
        <Flex.Item>
          <Box
            style={{
              display: 'inline-block',
              width: '28px',
              height: '18px',
              verticalAlign: 'middle',
              backgroundColor: `#${entry.color}`,
              border: '1px solid #222',
            }}
          />
        </Flex.Item>
        <Flex.Item ml={1}>
          <Input
            value={draft}
            width="7rem"
            maxLength={7}
            placeholder="RRGGBB"
            onChange={(value: string) => setDraft(value)}
            onBlur={commit}
            onEnter={commit}
          />
        </Flex.Item>
        {!valid && (
          <Flex.Item ml={1}>
            <Box color="bad" fontSize="11px">
              Invalid hex
            </Box>
          </Flex.Item>
        )}
      </Flex>
    </Box>
  );
}

function OffsetEditor(props: { zoneId: string; entry: MarkingEntry }) {
  const { act, data } = useBackend<BodyMarkingEditorData>();
  const { zoneId, entry } = props;
  const { offset_min, offset_max } = data;

  const nudge = (dx: number, dy: number) =>
    act('nudge', { zone: zoneId, name: entry.name, dx, dy });

  const resetOffset = () =>
    act('set_offset', {
      zone: zoneId,
      name: entry.name,
      pixel_x: 0,
      pixel_y: 0,
    });

  const setAbsX = (value: number) =>
    act('set_offset', {
      zone: zoneId,
      name: entry.name,
      pixel_x: clamp(value, offset_min, offset_max),
      pixel_y: entry.pixel_y,
    });

  const setAbsY = (value: number) =>
    act('set_offset', {
      zone: zoneId,
      name: entry.name,
      pixel_x: entry.pixel_x,
      pixel_y: clamp(value, offset_min, offset_max),
    });

  return (
    <Box>
      <Box bold mb={0.5}>
        Offset
      </Box>
      <Flex>
        <Flex.Item>
          <NudgePad onNudge={nudge} onReset={resetOffset} />
        </Flex.Item>
        <Flex.Item ml={2} grow={1}>
          <LabeledList>
            <LabeledList.Item label="Pixel X">
              <NumberInput
                value={entry.pixel_x}
                minValue={offset_min}
                maxValue={offset_max}
                step={1}
                width="4.5rem"
                onChange={setAbsX}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Pixel Y">
              <NumberInput
                value={entry.pixel_y}
                minValue={offset_min}
                maxValue={offset_max}
                step={1}
                width="4.5rem"
                onChange={setAbsY}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Range">
              <Box opacity={0.6} fontSize="11px">
                {offset_min} to {offset_max} px
              </Box>
            </LabeledList.Item>
          </LabeledList>
        </Flex.Item>
      </Flex>
    </Box>
  );
}

// Nudge pad: center "reset to 0,0" button surrounded by ±1 arrows, with a
// second row of ±8 coarse-step arrows. We fire `nudge` with deltas rather
// than computing the absolute target client-side so the server's clamp is
// authoritative.
function NudgePad(props: {
  onNudge: (dx: number, dy: number) => void;
  onReset: () => void;
}) {
  const { onNudge, onReset } = props;
  return (
    <Box>
      {/* Fine: ±1 */}
      <Flex justify="center">
        <Flex.Item>
          <Button
            icon="angle-up"
            tooltip="+1 Y"
            onClick={() => onNudge(0, 1)}
          />
        </Flex.Item>
      </Flex>
      <Flex justify="center" align="center">
        <Flex.Item>
          <Button
            icon="angle-left"
            tooltip="-1 X"
            onClick={() => onNudge(-1, 0)}
          />
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="crosshairs"
            tooltip="Reset offset to 0,0"
            onClick={onReset}
          />
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="angle-right"
            tooltip="+1 X"
            onClick={() => onNudge(1, 0)}
          />
        </Flex.Item>
      </Flex>
      <Flex justify="center">
        <Flex.Item>
          <Button
            icon="angle-down"
            tooltip="-1 Y"
            onClick={() => onNudge(0, -1)}
          />
        </Flex.Item>
      </Flex>
      {/* Coarse: ±8 */}
      <Box mt={0.5}>
        <Flex justify="center">
          <Flex.Item>
            <Button
              icon="angle-double-left"
              tooltip="-8 X"
              onClick={() => onNudge(-8, 0)}
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              icon="angle-double-up"
              tooltip="+8 Y"
              onClick={() => onNudge(0, 8)}
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              icon="angle-double-down"
              tooltip="-8 Y"
              onClick={() => onNudge(0, -8)}
            />
          </Flex.Item>
          <Flex.Item>
            <Button
              icon="angle-double-right"
              tooltip="+8 X"
              onClick={() => onNudge(8, 0)}
            />
          </Flex.Item>
        </Flex>
      </Box>
    </Box>
  );
}

function TransformEditor(props: { zoneId: string; entry: MarkingEntry }) {
  const { act } = useBackend<BodyMarkingEditorData>();
  const { zoneId, entry } = props;

  const fire = (patch: Partial<MarkingEntry>) => {
    // Server's `set_transform` validates rotation ∈ {0,90,180,270} and
    // scale ∈ {1,2}. We always send the full quadruple so server state is
    // unambiguous after each tick.
    act('set_transform', {
      zone: zoneId,
      name: entry.name,
      rotation: patch.rotation ?? entry.rotation,
      scale: patch.scale ?? entry.scale,
      flip_x:
        patch.flip_x !== undefined ? (patch.flip_x ? 1 : 0) : toBool(entry.flip_x) ? 1 : 0,
      flip_y:
        patch.flip_y !== undefined ? (patch.flip_y ? 1 : 0) : toBool(entry.flip_y) ? 1 : 0,
    });
  };

  return (
    <Box>
      <Box bold mb={0.5}>
        Transform
      </Box>
      <LabeledList>
        <LabeledList.Item label="Rotation">
          {ROTATION_CHOICES.map((deg) => (
            <Button
              key={deg}
              selected={entry.rotation === deg}
              tooltip={`${deg} degrees`}
              onClick={() => fire({ rotation: deg })}
            >
              {/* Plain `${deg}°` is avoided here because the rogue-themed
                  Pterra font does not ship a Latin-1 DEGREE SIGN glyph and
                  renders it as a stray "8". Use ASCII-only labels + a
                  tooltip. Matches TaurGenitalOffsetEditor's approach. */}
              {deg}
            </Button>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Scale">
          {SCALE_CHOICES.map((s) => (
            <Button
              key={s}
              selected={entry.scale === s}
              onClick={() => fire({ scale: s })}
            >
              {s}×
            </Button>
          ))}
        </LabeledList.Item>
        <LabeledList.Item label="Flip">
          <Button.Checkbox
            checked={toBool(entry.flip_x)}
            onClick={() => fire({ flip_x: !toBool(entry.flip_x) })}
          >
            Horizontal
          </Button.Checkbox>
          <Button.Checkbox
            checked={toBool(entry.flip_y)}
            onClick={() => fire({ flip_y: !toBool(entry.flip_y) })}
          >
            Vertical
          </Button.Checkbox>
        </LabeledList.Item>
      </LabeledList>
    </Box>
  );
}

// "Reset Entry" — per the spec, color stays; offset + transform go back to
// defaults. There's no dedicated server action for this, so we compose it
// out of existing primitives: set_offset(0,0) + set_transform(0, 1, 0, 0).
function ResetEntryButton(props: { zoneId: string; entry: MarkingEntry }) {
  const { act } = useBackend<BodyMarkingEditorData>();
  const { zoneId, entry } = props;
  return (
    <Button
      icon="undo"
      onClick={() => {
        act('set_offset', {
          zone: zoneId,
          name: entry.name,
          pixel_x: 0,
          pixel_y: 0,
        });
        act('set_transform', {
          zone: zoneId,
          name: entry.name,
          rotation: 0,
          scale: 1,
          flip_x: 0,
          flip_y: 0,
        });
      }}
    >
      Reset Entry (keeps color)
    </Button>
  );
}

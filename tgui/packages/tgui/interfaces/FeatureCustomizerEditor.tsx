/**
 * @file FeatureCustomizerEditor.tsx
 * @description Per-character bodypart feature customizer editor. Pairs
 * with /datum/feature_customizer_editor (modular/code/modules/client/
 * feature_customizer_editor.dm).
 *
 * Layout: three-column Stack inside a Window. Left column picks the
 * customizer slot (hair/beard/horns/etc), middle column picks an
 * accessory for the active slot, right column edits color / offset /
 * transform / hair-only fields for the selected entry. All persistent
 * state is server-side; the only client-side state is transient
 * text-input drafts (debounced commit on blur/Enter) and accessory grid
 * scroll position.
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
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';

// ── Types ────────────────────────────────────────────────────────────────────

type ColorKey = {
  key: number;
  name: string;
};

type CustomizerEntry = {
  accessory_type: string | null;
  customizer_choice_type: string | null;
  customizer_choice_name: string | null;
  accessory_choice_name?: string;
  accessory_icon?: string;
  accessory_icon_state?: string;
  accessory_colors?: string;
  accessory_color_disabled?: number | boolean;
  accessory_color_keys?: number;
  color_keys: ColorKey[];
  disabled: number | boolean;
  pixel_x: number;
  pixel_y: number;
  flip_x: number | boolean;
  flip_y: number | boolean;
  rotation: number;
  scale: number;
  // Phase 3 extreme-offset vetting caches (see
  // modular/code/__DEFINES/extreme_offset.dm).
  is_hard_extreme?: number | boolean;
  is_soft_extreme?: number | boolean;
  extreme_flags?: number;
  // Hair-only.
  hair_color?: string;
  natural_gradient?: string | null;
  natural_color?: string;
  dye_gradient?: string | null;
  dye_color?: string;
  // Phase 6 composite sub-entries.
  sub_entries?: SubEntry[];
  allow_sub_entries?: number | boolean;
  max_sub_entries?: number;
  migrated_v?: number;
};

type SubEntry = {
  accessory_type: string | null;
  accessory_colors?: string;
  accessory_choice_name?: string;
  accessory_icon?: string;
  accessory_icon_state?: string;
  accessory_color_disabled?: number | boolean;
  accessory_color_keys?: number;
  pixel_x: number;
  pixel_y: number;
  flip_x: number | boolean;
  flip_y: number | boolean;
  rotation: number;
  scale: number;
  is_hard_extreme?: number | boolean;
  is_soft_extreme?: number | boolean;
  extreme_flags?: number;
  hair_color?: string;
};

type CustomizerInfo = {
  customizer_type: string;
  name: string;
  allows_disabling: number | boolean;
  allowed_by_species: number | boolean;
  entry: CustomizerEntry | null;
};

type AvailableAccessory = {
  accessory_type: string;
  name: string;
  icon: string;
  icon_state: string;
  color_keys?: number;
  color_disabled?: number | boolean;
};

type HairGradientOption = {
  gradient_type: string;
  name: string;
};

type FeatureCustomizerEditorData = {
  active_customizer_type: string | null;
  customizers: CustomizerInfo[];
  available_accessories: Record<string, AvailableAccessory[]>;
  hair_gradients: HairGradientOption[];
  offset_min: number;
  offset_max: number;
  rotation_choices: number[];
  scale_choices: number[];
  dirty: number | boolean;
  // Phase 3 extreme-offset vetting surface.
  aggregate_extreme?: number | boolean;
  aggregate_offset_budget_used?: number;
  extreme_aggregate_budget?: number;
  acknowledge_extreme_offsets?: number | boolean;
};

// ── Constants ────────────────────────────────────────────────────────────────

const HEX_COLOR_RE = /^[0-9A-Fa-f]{6}$/;
const PREVIEW_SIZE = 96;

// Mirror of EXTREME_FLAG_* bits from
// modular/code/__DEFINES/extreme_offset.dm. Keep in sync if the DM
// defines change.
const EXTREME_FLAG_SOFT_PX = 1 << 0;
const EXTREME_FLAG_SOFT_SCALE = 1 << 1;
const EXTREME_FLAG_HARD_PX = 1 << 2;
const EXTREME_FLAG_HARD_DIAG = 1 << 3;
const EXTREME_FLAG_HARD_SCALE = 1 << 4;

const EXTREME_WARNING_TOOLTIP =
  "WARNING: 'Avoid making characters that significantly clash with the aesthetic of the setting. We are flexible, but we have limits.' Characters with extreme offsets are reported to admin logging upon joining a round as a measure to curb abuse.\n\nEnable 'Acknowledge extreme cosmetic offsets are logged' in ERP Preferences to save without confirmation each time.";

// ── Helpers ──────────────────────────────────────────────────────────────────

function clamp(value: number, lo: number, hi: number): number {
  return Math.max(lo, Math.min(hi, value));
}

function toBool(v: number | boolean | undefined): boolean {
  return !!v;
}

/**
 * Splits the packed `#aabbcc#112233` accessory_colors string into bare
 * 6-hex values. The server ships colors as a `#`-delimited concat; we
 * strip empties created by the leading delimiter.
 */
function unpackAccessoryColors(packed: string | undefined): string[] {
  if (!packed) {
    return [];
  }
  return packed.split('#').filter((s) => s.length > 0);
}

function findCustomizer(
  list: CustomizerInfo[],
  type: string | null,
): CustomizerInfo | undefined {
  if (!type) {
    return undefined;
  }
  return list.find((c) => c.customizer_type === type);
}

// ── Top-level component ──────────────────────────────────────────────────────

export function FeatureCustomizerEditor(props) {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const {
    active_customizer_type,
    customizers = [],
    dirty,
    aggregate_extreme,
    aggregate_offset_budget_used = 0,
    extreme_aggregate_budget = 0,
    acknowledge_extreme_offsets,
  } = data;

  const active = findCustomizer(customizers, active_customizer_type);
  const ackOn = toBool(acknowledge_extreme_offsets);
  const aggExtreme = toBool(aggregate_extreme);

  return (
    <Window theme="rogue" width={880} height={640}>
      <Window.Content>
        <Section
          title="Bodypart Features"
          fill
          buttons={
            <>
              <Tooltip content="Configure in ERP Preferences">
                <Box
                  inline
                  mr={1}
                  fontSize="10px"
                  px={0.5}
                  style={{
                    border: `1px solid ${ackOn ? '#3a7' : '#555'}`,
                    color: ackOn ? '#6e6' : '#aaa',
                    borderRadius: '2px',
                  }}
                >
                  {ackOn ? 'ACK ON' : 'ACK OFF'}
                </Box>
              </Tooltip>
              {!!dirty && (
                <Box inline mr={1} color="average" fontSize="11px" italic>
                  Unsaved changes
                </Box>
              )}
              <Button
                icon="save"
                color="good"
                disabled={!dirty}
                onClick={() => act('save')}
              >
                Save
              </Button>
              <Button icon="times" onClick={() => act('close')}>
                Close
              </Button>
            </>
          }
        >
          {aggExtreme && (
            <AggregateExtremeBanner
              used={aggregate_offset_budget_used}
              budget={extreme_aggregate_budget}
            />
          )}
          {customizers.length === 0 ? (
            <NoticeBox>
              No customizers available for this species.
            </NoticeBox>
          ) : (
            <Stack fill>
              <Stack.Item basis="22%" shrink={0}>
                <CustomizerPicker />
              </Stack.Item>
              <Stack.Item basis="36%" shrink={0}>
                <AccessoryPicker active={active} />
              </Stack.Item>
              <Stack.Item grow>
                <DetailPanel active={active} />
              </Stack.Item>
            </Stack>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
}

// ── Aggregate-extreme banner ────────────────────────────────────────────────

function AggregateExtremeBanner(props: { used: number; budget: number }) {
  const { used, budget } = props;
  const [collapsed, setCollapsed] = useState(false);
  return (
    <Box
      mb={0.5}
      p={0.5}
      style={{
        border: '1px solid #a33',
        backgroundColor: 'rgba(160, 40, 40, 0.15)',
        borderRadius: '2px',
      }}
    >
      <Flex align="center">
        <Flex.Item grow={1}>
          <Box bold color="bad">
            Total offset budget: {used} / {budget}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            icon={collapsed ? 'chevron-down' : 'chevron-up'}
            compact
            onClick={() => setCollapsed(!collapsed)}
          />
        </Flex.Item>
      </Flex>
      {!collapsed && (
        <Box mt={0.5} fontSize="11px">
          Your character&apos;s combined pixel offsets exceed the
          setting&apos;s aesthetic guidelines. Admins will be notified
          on round join unless you enable acknowledgment in ERP
          Preferences.
        </Box>
      )}
    </Box>
  );
}

// ── Customizer picker (left column) ──────────────────────────────────────────

function CustomizerPicker() {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const { active_customizer_type, customizers = [] } = data;

  return (
    <Section title="Slots" fill scrollable>
      <Stack vertical>
        {customizers.map((c) => {
          const selected = c.customizer_type === active_customizer_type;
          const allowed = toBool(c.allowed_by_species);
          const disabledEntry = !!c.entry && toBool(c.entry.disabled);
          return (
            <Stack.Item key={c.customizer_type}>
              <Button
                fluid
                selected={selected}
                onClick={() =>
                  act('select_customizer', {
                    customizer_type: c.customizer_type,
                  })
                }
              >
                <Flex align="center">
                  <Flex.Item
                    grow={1}
                    style={{ opacity: allowed ? 1 : 0.45 }}
                  >
                    {c.name}
                  </Flex.Item>
                  {disabledEntry && (
                    <Flex.Item ml={0.5} fontSize="10px" opacity={0.7}>
                      (disabled)
                    </Flex.Item>
                  )}
                </Flex>
              </Button>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
}

// ── Accessory picker (middle column) ─────────────────────────────────────────

function AccessoryPicker(props: { active: CustomizerInfo | undefined }) {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const { active } = props;
  const { available_accessories = {} } = data;

  if (!active) {
    return (
      <Section title="Accessory" fill>
        <Box opacity={0.6} italic>
          Select a slot on the left.
        </Box>
      </Section>
    );
  }

  const allowed = toBool(active.allowed_by_species);
  const entry = active.entry;
  const options = available_accessories[active.customizer_type] ?? [];
  const allowsDisabling = toBool(active.allows_disabling);

  return (
    <Section
      title={active.name}
      fill
      scrollable
      buttons={
        <Button
          icon={entry && toBool(entry.disabled) ? 'eye-slash' : 'eye'}
          disabled={!allowsDisabling || !entry}
          tooltip={
            !allowsDisabling
              ? 'This slot cannot be disabled'
              : !entry
                ? 'No entry to toggle'
                : undefined
          }
          onClick={() =>
            act('toggle_disabled', {
              customizer_type: active.customizer_type,
            })
          }
        >
          {entry && toBool(entry.disabled) ? 'Enable' : 'Disable'}
        </Button>
      }
    >
      {!allowed && (
        <NoticeBox info>
          Not allowed by current species.
        </NoticeBox>
      )}

      <Flex align="center" mb={1}>
        <Flex.Item>
          {!!entry?.accessory_icon && !!entry.accessory_icon_state ? (
            <DmIcon
              icon={entry.accessory_icon}
              icon_state={entry.accessory_icon_state}
              width={32}
              height={32}
            />
          ) : (
            <Box
              style={{
                width: '32px',
                height: '32px',
                border: '1px solid #444',
              }}
            />
          )}
        </Flex.Item>
        <Flex.Item ml={1} grow={1}>
          <Box bold>
            {entry?.accessory_choice_name ?? 'No accessory'}
          </Box>
          {!!entry?.customizer_choice_name && (
            <Box opacity={0.6} fontSize="11px">
              {entry.customizer_choice_name}
            </Box>
          )}
        </Flex.Item>
      </Flex>

      <Flex mb={1}>
        <Flex.Item>
          <Button
            icon="arrow-left"
            disabled={!entry || options.length <= 1}
            onClick={() =>
              act('rotate_accessory', {
                customizer_type: active.customizer_type,
                direction: -1,
              })
            }
          >
            Prev
          </Button>
        </Flex.Item>
        <Flex.Item ml={0.5}>
          <Button
            icon="arrow-right"
            iconPosition="right"
            disabled={!entry || options.length <= 1}
            onClick={() =>
              act('rotate_accessory', {
                customizer_type: active.customizer_type,
                direction: 1,
              })
            }
          >
            Next
          </Button>
        </Flex.Item>
      </Flex>

      <Box bold mb={0.5}>
        Choose accessory
      </Box>
      {options.length === 0 ? (
        <Box opacity={0.6} italic>
          No accessories available.
        </Box>
      ) : (
        <Flex wrap="wrap" align="flex-start">
          {options.map((opt) => {
            const selected = entry?.accessory_type === opt.accessory_type;
            return (
              <Flex.Item key={opt.accessory_type} m={0.25}>
                <Button
                  selected={selected}
                  tooltip={opt.name}
                  onClick={() =>
                    act('change_accessory', {
                      customizer_type: active.customizer_type,
                      accessory_type: opt.accessory_type,
                    })
                  }
                >
                  {/* Mirrors CustomPiercingEditor's StickerPicker layout: a
                      Flex inline row with the DmIcon sized in its own slot
                      and the label beside it. The previous layout used
                      `fluid` on the Button and a fixed 78px Flex.Item,
                      which made `Flex`'s default `align="stretch"` force
                      all buttons in a row to match the tallest button's
                      height and caused the DmIcon to render underneath the
                      Button's own background/border in the rogue theme. */}
                  <Flex inline align="center">
                    <DmIcon
                      icon={opt.icon}
                      icon_state={opt.icon_state}
                      width={32}
                      height={32}
                    />
                    <Box
                      inline
                      ml={0.5}
                      style={{
                        maxWidth: '80px',
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {opt.name}
                    </Box>
                  </Flex>
                </Button>
              </Flex.Item>
            );
          })}
        </Flex>
      )}
    </Section>
  );
}

// ── Detail panel (right column) ──────────────────────────────────────────────

function DetailPanel(props: { active: CustomizerInfo | undefined }) {
  const { active } = props;
  // Phase 6 — which sub-entry tab the player is editing. 1 == primary,
  // whose values are mirrored on the parent entry's legacy fields.
  const [subIndex, setSubIndex] = useState<number>(1);

  if (!active) {
    return (
      <Section title="Details" fill>
        <Box opacity={0.6} italic>
          Select a slot.
        </Box>
      </Section>
    );
  }

  const entry = active.entry;
  if (!entry) {
    return (
      <Section title="Details" fill>
        <NoticeBox>No accessory selected.</NoticeBox>
      </Section>
    );
  }

  const subs = entry.sub_entries ?? [];
  const allowSubs = toBool(entry.allow_sub_entries);
  const clampedIndex = Math.min(Math.max(subIndex, 1), Math.max(subs.length, 1));
  // Build the "view" entry — for primary, use the parent entry so existing
  // getters (hair gradients etc) come along for free; for sub-entries, use
  // the sub payload but graft parent-level hair gradient fields onto it so
  // the shared HairEditor reads them unchanged. Sub-entries skip the hair
  // gradient block (those are parent-owned); only hair_color is per-sub.
  const viewEntry: CustomizerEntry =
    clampedIndex === 1 || !subs[clampedIndex - 1]
      ? entry
      : ({
          ...entry,
          ...subs[clampedIndex - 1],
        } as CustomizerEntry);

  return (
    <Section title="Details" fill scrollable>
      {allowSubs && (
        <SubEntryNav
          customizerType={active.customizer_type}
          entry={entry}
          subIndex={clampedIndex}
          setSubIndex={setSubIndex}
        />
      )}
      {clampedIndex > 1 && (
        <SubAccessoryPicker
          customizerType={active.customizer_type}
          subIndex={clampedIndex}
          currentType={viewEntry.accessory_type}
        />
      )}
      <EntryPreview entry={viewEntry} />
      <Box mt={1}>
        <ColorEditor
          customizerType={active.customizer_type}
          entry={viewEntry}
          subIndex={clampedIndex}
        />
      </Box>
      {viewEntry.hair_color !== undefined && (
        <Box mt={1}>
          <HairEditor entry={viewEntry} subIndex={clampedIndex} />
        </Box>
      )}
      <Box mt={1}>
        <OffsetEditor
          customizerType={active.customizer_type}
          entry={viewEntry}
          subIndex={clampedIndex}
        />
      </Box>
      <Box mt={1}>
        <TransformEditor
          customizerType={active.customizer_type}
          entry={viewEntry}
          subIndex={clampedIndex}
        />
      </Box>
    </Section>
  );
}

// ── Sub-entry navigation (Phase 6) ──────────────────────────────────────────

function SubEntryNav(props: {
  customizerType: string;
  entry: CustomizerEntry;
  subIndex: number;
  setSubIndex: (idx: number) => void;
}) {
  const { act } = useBackend<FeatureCustomizerEditorData>();
  const { customizerType, entry, subIndex, setSubIndex } = props;
  const subs = entry.sub_entries ?? [];
  const cap = entry.max_sub_entries ?? 3;
  const atCap = subs.length >= cap;
  return (
    <Box mb={1}>
      <Flex align="center">
        <Flex.Item grow={1}>
          <Flex wrap="wrap">
            {subs.map((sub, idx) => {
              const humanIdx = idx + 1;
              const selected = humanIdx === subIndex;
              const hard = toBool(sub.is_hard_extreme);
              const soft = toBool(sub.is_soft_extreme);
              return (
                <Flex.Item key={humanIdx} mr={0.5}>
                  <Button
                    selected={selected}
                    onClick={() => setSubIndex(humanIdx)}
                    tooltip={
                      humanIdx === 1 ? 'Primary sub-entry' : `Sub-entry ${humanIdx}`
                    }
                  >
                    <Box
                      inline
                      style={
                        hard
                          ? { color: '#f66' }
                          : soft
                            ? { color: '#fc6' }
                            : undefined
                      }
                    >
                      {humanIdx === 1 ? 'Primary' : `Sub ${humanIdx}`}
                      {hard ? '!' : soft ? '~' : ''}
                    </Box>
                  </Button>
                </Flex.Item>
              );
            })}
            <Flex.Item mr={0.5}>
              <Button
                icon="plus"
                disabled={atCap}
                tooltip={
                  atCap
                    ? `Max ${cap} sub-entries reached`
                    : 'Add a sub-entry (extra stacked overlay)'
                }
                onClick={() =>
                  act('add_sub_entry', { customizer_type: customizerType })
                }
              />
            </Flex.Item>
            {subIndex > 1 && (
              <Flex.Item>
                <Button
                  icon="times"
                  color="bad"
                  tooltip={`Remove sub-entry ${subIndex}`}
                  onClick={() => {
                    act('remove_sub_entry', {
                      customizer_type: customizerType,
                      sub_index: subIndex,
                    });
                    setSubIndex(Math.max(1, subIndex - 1));
                  }}
                />
              </Flex.Item>
            )}
          </Flex>
        </Flex.Item>
      </Flex>
    </Box>
  );
}

// ── Sub-entry accessory picker (Phase 6) ────────────────────────────────────

function SubAccessoryPicker(props: {
  customizerType: string;
  subIndex: number;
  currentType: string | null;
}) {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const { customizerType, subIndex, currentType } = props;
  const options = data.available_accessories?.[customizerType] ?? [];
  if (options.length === 0) {
    return null;
  }
  const dropdownOptions = options.map((opt) => ({
    value: opt.accessory_type,
    displayText: opt.name,
  }));
  return (
    <Box mb={1}>
      <Flex align="center">
        <Flex.Item basis="32%">
          <Box fontSize="11px" bold>
            Sub {subIndex} accessory
          </Box>
        </Flex.Item>
        <Flex.Item grow={1}>
          <Dropdown
            width="100%"
            selected={currentType ?? ''}
            options={dropdownOptions}
            onSelected={(value: string) => {
              if (!value) return;
              act('set_sub_accessory', {
                customizer_type: customizerType,
                sub_index: subIndex,
                accessory_type: value,
              });
            }}
          />
        </Flex.Item>
      </Flex>
    </Box>
  );
}

// ── Preview ──────────────────────────────────────────────────────────────────

function EntryPreview(props: { entry: CustomizerEntry }) {
  const { entry } = props;

  // Server stores rotation in {0,90,180,270} and scale in {1,2}; flips
  // are 0/1. Translate first so rotation pivots around the post-offset
  // origin, matching how the in-world sprite is composited.
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
        {!!entry.accessory_icon && !!entry.accessory_icon_state && (
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
              icon={entry.accessory_icon}
              icon_state={entry.accessory_icon_state}
              width={32}
              height={32}
            />
          </Box>
        )}
      </Box>
      <Box mt={0.5} opacity={0.6} fontSize="11px" italic>
        Position / rotation / flip / scale preview only. Final color
        compositing is done by the game.
      </Box>
    </Box>
  );
}

// ── Color editor ─────────────────────────────────────────────────────────────

function ColorEditor(props: {
  customizerType: string;
  entry: CustomizerEntry;
  subIndex?: number;
}) {
  const { act } = useBackend<FeatureCustomizerEditorData>();
  const { customizerType, entry, subIndex = 1 } = props;

  if (toBool(entry.accessory_color_disabled)) {
    return null;
  }

  const colors = unpackAccessoryColors(entry.accessory_colors);
  const keys = entry.color_keys ?? [];

  if (keys.length === 0) {
    return null;
  }

  return (
    <Box>
      <Flex align="center" mb={0.5}>
        <Flex.Item grow={1}>
          <Box bold>Colors</Box>
        </Flex.Item>
        {subIndex === 1 && (
          <Flex.Item>
            <Button
              icon="undo"
              onClick={() =>
                act('reset_colors', { customizer_type: customizerType })
              }
            >
              Reset Colors
            </Button>
          </Flex.Item>
        )}
      </Flex>
      <Stack vertical>
        {keys.map((ck, idx) => (
          <Stack.Item key={ck.key}>
            <ColorRow
              customizerType={customizerType}
              colorIndex={ck.key}
              label={ck.name || `Color ${idx + 1}`}
              currentHex={colors[idx] ?? '000000'}
              subIndex={subIndex}
            />
          </Stack.Item>
        ))}
      </Stack>
    </Box>
  );
}

function ColorRow(props: {
  customizerType: string;
  colorIndex: number;
  label: string;
  currentHex: string;
  subIndex?: number;
}) {
  const { act } = useBackend<FeatureCustomizerEditorData>();
  const { customizerType, colorIndex, label, currentHex, subIndex = 1 } = props;
  const [draft, setDraft] = useState(currentHex);

  // Reset the draft when the committed value changes (e.g. reset_colors
  // from elsewhere). Compare against the committed value to avoid
  // stomping on in-progress edits when ui_data re-emits.
  useEffect(() => {
    setDraft(currentHex);
  }, [currentHex]);

  const commit = () => {
    const normalized = draft.replace(/^#/, '');
    if (!HEX_COLOR_RE.test(normalized)) {
      setDraft(currentHex);
      return;
    }
    if (normalized.toLowerCase() === currentHex.toLowerCase()) {
      return;
    }
    const action = subIndex === 1 ? 'set_color' : 'set_sub_color';
    const params: Record<string, any> = {
      customizer_type: customizerType,
      color_index: colorIndex,
      hex: normalized,
    };
    if (subIndex !== 1) {
      params.sub_index = subIndex;
    }
    act(action, params);
  };

  const valid = HEX_COLOR_RE.test(draft.replace(/^#/, ''));

  return (
    <Flex align="center">
      <Flex.Item basis="40%">
        <Box fontSize="11px">{label}</Box>
      </Flex.Item>
      <Flex.Item>
        <Box
          style={{
            display: 'inline-block',
            width: '24px',
            height: '16px',
            verticalAlign: 'middle',
            backgroundColor: `#${currentHex}`,
            border: '1px solid #222',
          }}
        />
      </Flex.Item>
      <Flex.Item ml={0.5}>
        <Input
          value={draft}
          width="6.5rem"
          maxLength={7}
          placeholder="RRGGBB"
          onChange={(value: string) => setDraft(value)}
          onBlur={commit}
          onEnter={commit}
        />
      </Flex.Item>
      {!valid && (
        <Flex.Item ml={0.5}>
          <Box color="bad" fontSize="10px">
            invalid
          </Box>
        </Flex.Item>
      )}
    </Flex>
  );
}

// ── Hair-only editor ─────────────────────────────────────────────────────────

function HairEditor(props: { entry: CustomizerEntry; subIndex?: number }) {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const { entry, subIndex = 1 } = props;
  const { hair_gradients = [] } = data;

  const gradientOptions = [
    { value: '', displayText: '(none)' },
    ...hair_gradients.map((g) => ({
      value: g.gradient_type,
      displayText: g.name,
    })),
  ];

  // Hair gradients are server-keyed by typepath text; "" means no
  // gradient. The server validates the path before assigning, so an
  // empty selection is a no-op (server won't accept blank); we just
  // display it as the "none" placeholder when natural_gradient is null.
  const naturalGradient = entry.natural_gradient ?? '';
  const dyeGradient = entry.dye_gradient ?? '';
  const NONE_GRADIENT = '/datum/hair_gradient/none';
  const naturalIsNone = !naturalGradient || naturalGradient === NONE_GRADIENT;
  const dyeIsNone = !dyeGradient || dyeGradient === NONE_GRADIENT;

  // Phase 6 — sub-entries share the parent's gradients. Only the solid
  // hair_color is per-sub. Hide gradient controls when editing sub 2+.
  const showGradients = subIndex === 1;
  const hairAction = subIndex === 1 ? 'set_hair_color' : 'set_sub_hair_color';
  const extraParams: Record<string, any> =
    subIndex === 1 ? {} : { sub_index: subIndex };

  return (
    <Box>
      <Box bold mb={0.5}>
        Hair colors
      </Box>
      <LabeledList>
        <LabeledList.Item label="Hair">
          <HairHexInput
            value={entry.hair_color ?? ''}
            action={hairAction}
            extraParams={extraParams}
          />
        </LabeledList.Item>
        {showGradients && (
          <LabeledList.Item label="Natural gradient">
            <Flex align="center">
              <Flex.Item grow={1}>
                <Dropdown
                  width="100%"
                  selected={naturalGradient}
                  options={gradientOptions}
                  onSelected={(value: string) => {
                    if (!value) {
                      return;
                    }
                    act('set_natural_gradient', { gradient_type: value });
                  }}
                />
              </Flex.Item>
              <Flex.Item ml={0.5}>
                <Button
                  icon="eraser"
                  tooltip="Clear gradient"
                  disabled={naturalIsNone}
                  onClick={() => act('clear_natural_gradient')}
                />
              </Flex.Item>
            </Flex>
          </LabeledList.Item>
        )}
        {showGradients && (
          <LabeledList.Item label="Natural color">
            <HairHexInput
              value={entry.natural_color ?? ''}
              action="set_natural_color"
            />
          </LabeledList.Item>
        )}
        {showGradients && (
          <LabeledList.Item label="Dye gradient">
            <Flex align="center">
              <Flex.Item grow={1}>
                <Dropdown
                  width="100%"
                  selected={dyeGradient}
                  options={gradientOptions}
                  onSelected={(value: string) => {
                    if (!value) {
                      return;
                    }
                    act('set_dye_gradient', { gradient_type: value });
                  }}
                />
              </Flex.Item>
              <Flex.Item ml={0.5}>
                <Button
                  icon="eraser"
                  tooltip="Clear gradient"
                  disabled={dyeIsNone}
                  onClick={() => act('clear_dye_gradient')}
                />
              </Flex.Item>
            </Flex>
          </LabeledList.Item>
        )}
        {showGradients && (
          <LabeledList.Item label="Dye color">
            <HairHexInput
              value={entry.dye_color ?? ''}
              action="set_dye_color"
            />
          </LabeledList.Item>
        )}
      </LabeledList>
    </Box>
  );
}

function HairHexInput(props: {
  value: string;
  action: string;
  extraParams?: Record<string, any>;
}) {
  const { act } = useBackend<FeatureCustomizerEditorData>();
  const { value, action, extraParams = {} } = props;
  const [draft, setDraft] = useState(value);

  useEffect(() => {
    setDraft(value);
  }, [value]);

  const commit = () => {
    const normalized = draft.replace(/^#/, '');
    if (!HEX_COLOR_RE.test(normalized)) {
      setDraft(value);
      return;
    }
    if (normalized.toLowerCase() === (value || '').toLowerCase()) {
      return;
    }
    act(action, { hex: normalized, ...extraParams });
  };

  const valid = HEX_COLOR_RE.test(draft.replace(/^#/, ''));

  return (
    <Flex align="center">
      <Flex.Item>
        <Box
          style={{
            display: 'inline-block',
            width: '20px',
            height: '14px',
            verticalAlign: 'middle',
            backgroundColor: value ? `#${value}` : 'transparent',
            border: '1px solid #222',
          }}
        />
      </Flex.Item>
      <Flex.Item ml={0.5}>
        <Input
          value={draft}
          width="6.5rem"
          maxLength={7}
          placeholder="RRGGBB"
          onChange={(v: string) => setDraft(v)}
          onBlur={commit}
          onEnter={commit}
        />
      </Flex.Item>
      {!valid && (
        <Flex.Item ml={0.5}>
          <Box color="bad" fontSize="10px">
            invalid
          </Box>
        </Flex.Item>
      )}
    </Flex>
  );
}

// ── Offset editor ────────────────────────────────────────────────────────────

function OffsetEditor(props: {
  customizerType: string;
  entry: CustomizerEntry;
  subIndex?: number;
}) {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const { customizerType, entry, subIndex = 1 } = props;
  const { offset_min, offset_max } = data;

  const flags = entry.extreme_flags ?? 0;
  const hardPx = (flags & EXTREME_FLAG_HARD_PX) !== 0;
  const hardDiag = (flags & EXTREME_FLAG_HARD_DIAG) !== 0;
  const softPx = (flags & EXTREME_FLAG_SOFT_PX) !== 0;
  // HARD_PX triggers per-axis coloring; HARD_DIAG means combined magnitude
  // exceeds the diagonal threshold even if no single axis is hard — color
  // both axes in that case.
  const pxExtreme = hardPx || hardDiag;
  const pyExtreme = hardPx || hardDiag;
  const hardExtreme = toBool(entry.is_hard_extreme);

  const nudgeAction = subIndex === 1 ? 'nudge' : 'sub_nudge';
  const setOffsetAction = subIndex === 1 ? 'set_offset' : 'set_sub_offset';
  const extraParams: Record<string, any> =
    subIndex === 1 ? {} : { sub_index: subIndex };

  const nudge = (dx: number, dy: number) =>
    act(nudgeAction, {
      customizer_type: customizerType,
      dx,
      dy,
      ...extraParams,
    });

  const resetOffset = () =>
    act(setOffsetAction, {
      customizer_type: customizerType,
      pixel_x: 0,
      pixel_y: 0,
      ...extraParams,
    });

  const setAbsX = (value: number) =>
    act(setOffsetAction, {
      customizer_type: customizerType,
      pixel_x: clamp(value, offset_min, offset_max),
      pixel_y: entry.pixel_y,
      ...extraParams,
    });

  const setAbsY = (value: number) =>
    act(setOffsetAction, {
      customizer_type: customizerType,
      pixel_x: entry.pixel_x,
      pixel_y: clamp(value, offset_min, offset_max),
      ...extraParams,
    });

  return (
    <Box>
      <Box bold mb={0.5}>
        Offset
      </Box>
      {hardExtreme && (
        <Tooltip content={EXTREME_WARNING_TOOLTIP}>
          <Box
            color="bad"
            bold
            mb={0.5}
            fontSize="11px"
            style={{
              border: '1px solid #a33',
              padding: '2px 4px',
              borderRadius: '2px',
            }}
          >
            EXTREME OFFSET, PLEASE READ
          </Box>
        </Tooltip>
      )}
      <Flex>
        <Flex.Item>
          <NudgePad onNudge={nudge} onReset={resetOffset} />
        </Flex.Item>
        <Flex.Item ml={2} grow={1}>
          <LabeledList>
            <LabeledList.Item
              label="Pixel X"
              labelColor={
                pxExtreme ? 'bad' : softPx ? 'average' : undefined
              }
            >
              <Box
                inline
                style={
                  pxExtreme
                    ? { outline: '1px solid #c33', padding: '1px' }
                    : softPx
                      ? { outline: '1px solid #c93', padding: '1px' }
                      : undefined
                }
              >
                <NumberInput
                  value={entry.pixel_x}
                  minValue={offset_min}
                  maxValue={offset_max}
                  step={1}
                  width="4.5rem"
                  onChange={setAbsX}
                />
              </Box>
            </LabeledList.Item>
            <LabeledList.Item
              label="Pixel Y"
              labelColor={
                pyExtreme ? 'bad' : softPx ? 'average' : undefined
              }
            >
              <Box
                inline
                style={
                  pyExtreme
                    ? { outline: '1px solid #c33', padding: '1px' }
                    : softPx
                      ? { outline: '1px solid #c93', padding: '1px' }
                      : undefined
                }
              >
                <NumberInput
                  value={entry.pixel_y}
                  minValue={offset_min}
                  maxValue={offset_max}
                  step={1}
                  width="4.5rem"
                  onChange={setAbsY}
                />
              </Box>
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

// Nudge pad: center "reset to 0,0" surrounded by ±1 arrows, with a
// second row of ±8 coarse-step arrows. We fire `nudge` with deltas so
// the server's clamp is authoritative.
function NudgePad(props: {
  onNudge: (dx: number, dy: number) => void;
  onReset: () => void;
}) {
  const { onNudge, onReset } = props;
  return (
    <Box>
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

// ── Transform editor ────────────────────────────────────────────────────────

function TransformEditor(props: {
  customizerType: string;
  entry: CustomizerEntry;
  subIndex?: number;
}) {
  const { act, data } = useBackend<FeatureCustomizerEditorData>();
  const { customizerType, entry, subIndex = 1 } = props;
  const { rotation_choices = [], scale_choices = [] } = data;

  const flags = entry.extreme_flags ?? 0;
  const hardScale = (flags & EXTREME_FLAG_HARD_SCALE) !== 0;
  const softScale = (flags & EXTREME_FLAG_SOFT_SCALE) !== 0;

  const setAction = subIndex === 1 ? 'set_transform' : 'set_sub_transform';
  const resetAction =
    subIndex === 1 ? 'reset_transform' : 'reset_sub_transform';
  const extraParams: Record<string, any> =
    subIndex === 1 ? {} : { sub_index: subIndex };

  // Always send the full quadruple so server state is unambiguous after
  // each tick. Server validates rotation ∈ rotation_choices, scale ∈
  // scale_choices.
  const fire = (patch: {
    rotation?: number;
    scale?: number;
    flip_x?: boolean;
    flip_y?: boolean;
  }) => {
    act(setAction, {
      customizer_type: customizerType,
      rotation: patch.rotation ?? entry.rotation,
      scale: patch.scale ?? entry.scale,
      flip_x:
        patch.flip_x !== undefined
          ? patch.flip_x
            ? 1
            : 0
          : toBool(entry.flip_x)
            ? 1
            : 0,
      flip_y:
        patch.flip_y !== undefined
          ? patch.flip_y
            ? 1
            : 0
          : toBool(entry.flip_y)
            ? 1
            : 0,
      ...extraParams,
    });
  };

  return (
    <Box>
      <Flex align="center" mb={0.5}>
        <Flex.Item grow={1}>
          <Box bold>Transform</Box>
        </Flex.Item>
        <Flex.Item>
          <Button
            icon="undo"
            onClick={() =>
              act(resetAction, {
                customizer_type: customizerType,
                ...extraParams,
              })
            }
          >
            Reset Transform
          </Button>
        </Flex.Item>
      </Flex>
      <LabeledList>
        <LabeledList.Item label="Rotation">
          {rotation_choices.map((deg) => (
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
        <LabeledList.Item
          label="Scale"
          labelColor={
            hardScale ? 'bad' : softScale ? 'average' : undefined
          }
        >
          {hardScale ? (
            <Tooltip content={EXTREME_WARNING_TOOLTIP}>
              <Box
                inline
                style={{ outline: '1px solid #c33', padding: '1px' }}
              >
                {scale_choices.map((s) => (
                  <Button
                    key={s}
                    selected={entry.scale === s}
                    onClick={() => fire({ scale: s })}
                  >
                    {s}×
                  </Button>
                ))}
              </Box>
            </Tooltip>
          ) : (
            <Box
              inline
              style={
                softScale
                  ? { outline: '1px solid #c93', padding: '1px' }
                  : undefined
              }
            >
              {scale_choices.map((s) => (
                <Button
                  key={s}
                  selected={entry.scale === s}
                  onClick={() => fire({ scale: s })}
                >
                  {s}×
                </Button>
              ))}
            </Box>
          )}
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

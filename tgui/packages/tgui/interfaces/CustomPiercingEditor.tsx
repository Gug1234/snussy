/**
 * @file CustomPiercingEditor.tsx
 * @description Per-character custom piercing (sticker) editor.
 *
 * Data contract matches /datum/custom_piercing_editor::ui_data. Mutations on
 * the backend only touch in-memory state + set `dirty`; persistence to disk
 * happens on the explicit "Save" button or when the window is closed
 * (autosave on Destroy). The top half mirrors the lobby intimate-accessory
 * prefs for selection and keyed-slot offsets; the bottom half is the two-slot
 * freeform sticker editor.
 */

import { useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Divider,
  Dropdown,
  Flex,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Slider,
  Stack,
  Tabs,
  TextArea,
} from 'tgui-core/components';

// ── Types ────────────────────────────────────────────────────────────────────

type SlotKey = string;
type DirKey = 's' | 'n' | 'e' | 'w';

type StickerInfo = {
  id: string;
  name: string;
  category: string;
  has_gem: number;
  directional: number;
  suggested_slots: string[];
};

type PiercingEntry = {
  sticker: string;
  metal_color: string;
  gem_color: string | null;
  props: Record<string, number>;
  custom_name: string | null;
  custom_desc: string | null;
  hide_when_covered: number;
  zone: string;
};

type SlotConfig = {
  enabled: number;
  suppress_legacy: number;
  display_name: string | null;
  hide_from_examine: number;
  entries: PiercingEntry[];
};

type AccessorySlotData = {
  key: string;
  custom_key?: string | null;
  label: string;
  group?: AccessoryGroupKey | null;
  current: string;
  options: string[];
  slot_props?: Record<string, number> | null;
};

type AccessoryGroupKey = 'genital' | 'rear' | 'torso' | 'head' | 'other';

type AccessoryGroupData = {
  key: AccessoryGroupKey;
  label: string;
  slots: AccessorySlotData[];
};

type BackendData = {
  regular_slots: AccessorySlotData[];
  active_slot: SlotKey | null;
  active_entry: number;
  slot_keys: SlotKey[];
  slot_labels: Record<SlotKey, string>;
  freeform_slots: SlotKey[];
  entry_zones: string[];
  entry_zone_labels: Record<string, string>;
  dir_keys: DirKey[];
  field_keys: string[];
  max_per_slot: number;
  max_total: number;
  max_name_length: number;
  max_desc_length: number;
  default_metal_color: string;
  default_gem_color: string;
  dirty: number;
  /** JSON envelope for the most recent `export_preset` action. */
  export_payload: string | null;
  /** Last import result string, e.g. "ok: imported 5 entries..." or "error: ...". */
  import_status: string | null;
  sticker_registry: Record<string, StickerInfo>;
  custom_piercings: Record<SlotKey, SlotConfig>;
};

// ── Helpers ──────────────────────────────────────────────────────────────────

const DIR_LABELS: Record<DirKey, string> = {
  s: 'South',
  n: 'North',
  e: 'East',
  w: 'West',
};

const ACCESSORY_GROUP_LABELS: Record<AccessoryGroupKey, string> = {
  genital: 'Genital',
  rear: 'Rear',
  torso: 'Torso',
  head: 'Head',
  other: 'Other',
};

const ACCESSORY_GROUP_ORDER: AccessoryGroupKey[] = [
  'genital',
  'rear',
  'torso',
  'head',
  'other',
];

function getAccessoryGroupKey(slotKey: string): AccessoryGroupKey {
  switch (slotKey) {
    case 'ear':
    case 'nose':
    case 'tongue':
      return 'head';
    case 'breast':
    case 'belly':
      return 'torso';
    case 'genital':
    case 'insertable_genital':
    case 'pintle':
      return 'genital';
    case 'rear':
    case 'insertable_rear':
      return 'rear';
    case 'genital_piercing':
    case 'genital_insertable':
      return 'genital';
    case 'rear_piercing':
    case 'rear_insertable':
      return 'rear';
    case 'breast_piercing':
    case 'breast_insertable':
    case 'belly_piercing':
      return 'torso';
    case 'mouth_piercing':
    case 'mouth_insertable':
    case 'ear_piercing':
    case 'nose_piercing':
      return 'head';
    default:
      return 'other';
  }
}

function groupAccessorySlots(slots: AccessorySlotData[]): AccessoryGroupData[] {
  const sourceSlots = Array.isArray(slots) ? slots : [];
  const grouped: Record<AccessoryGroupKey, AccessorySlotData[]> = {
    genital: [],
    rear: [],
    torso: [],
    head: [],
    other: [],
  };

  for (const slot of sourceSlots) {
    if (!slot?.key) {
      continue;
    }
    grouped[(slot.group as AccessoryGroupKey) || getAccessoryGroupKey(slot.key)].push(slot);
  }

  return ACCESSORY_GROUP_ORDER.flatMap((key) => {
    const groupSlots = grouped[key];
    if (!groupSlots.length) {
      return [];
    }

    return [
      {
        key,
        label: ACCESSORY_GROUP_LABELS[key],
        slots: groupSlots,
      },
    ];
  });
}

// ── Top-level component ──────────────────────────────────────────────────────

export function CustomPiercingEditor(props) {
  const { act, data } = useBackend<BackendData>();
  const {
    regular_slots = [] as AccessorySlotData[],
    active_slot,
    active_entry,
    slot_keys = [],
    slot_labels = {},
    freeform_slots = [],
    custom_piercings = {},
    dirty,
    export_payload,
    import_status,
  } = data;
  const accessoryGroups = groupAccessorySlots(regular_slots);
  const [activeAccessoryTab, setActiveAccessoryTab] = useState<AccessoryGroupKey>(
    accessoryGroups[0]?.key ?? 'genital',
  );
  const activeCustomSlot = !!active_slot && freeform_slots.includes(active_slot);
  const selectedFreeformSlot = activeCustomSlot
    ? active_slot
    : freeform_slots[0] ?? null;
  const slotCfg: SlotConfig | undefined = selectedFreeformSlot
    ? custom_piercings[selectedFreeformSlot]
    : undefined;
  const entries = slotCfg?.entries ?? [];
  const entry =
    active_entry >= 1 && active_entry <= entries.length
      ? entries[active_entry - 1]
      : undefined;

  // Import/export modal state. Opening import shows an editable textarea;
  // opening export is driven by the backend via `export_payload`.
  const [showImport, setShowImport] = useState(false);
  const [importText, setImportText] = useState('');
  const modalOpen = !!export_payload || showImport;

  return (
    <Window theme="rogue" width={860} height={720}>
      <Window.Content scrollable>
        <Section
          title="Intimate Accessories"
          buttons={
            <>
              {!!dirty && (
                <Box inline mr={1} color="average" italic fontSize="11px">
                  Unsaved changes
                </Box>
              )}
              <Button
                icon="file-export"
                tooltip="Export your custom piercing loadout as JSON so you can share it or keep a backup."
                onClick={() => act('export_preset')}
              >
                Export
              </Button>
              <Button
                icon="file-import"
                tooltip="Paste a previously-exported loadout to replace your current stickers."
                onClick={() => {
                  setImportText('');
                  setShowImport(true);
                }}
              >
                Import
              </Button>
              <Button
                icon="save"
                color={dirty ? 'good' : undefined}
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
          <NoticeBox info>
            Normal slots are offset-only: edit the per-direction metal-base
            position here, and let the game keep the gem/cross masks aligned
            automatically. The freeform slots below are the only place where
            sticker layouts, colors, and per-sticker transforms are edited.
          </NoticeBox>

          {modalOpen && (
            <ImportExportModal
              exportPayload={export_payload}
              importStatus={import_status}
              importText={importText}
              setImportText={setImportText}
              onCloseImport={() => setShowImport(false)}
            />
          )}

          {!!accessoryGroups.length && (
            <Box mt={1}>
              <AccessorySlotsSection
                groups={accessoryGroups}
                activeGroup={activeAccessoryTab}
                setActiveGroup={setActiveAccessoryTab}
              />
            </Box>
          )}

          <Box mt={2}>
            <FreeformStickerSlotsSection
              activeSlot={selectedFreeformSlot}
              activeEntry={active_entry}
              slotKeys={slot_keys}
              slotLabels={slot_labels}
              slotCfg={slotCfg}
              entry={entry}
              customPiercings={custom_piercings}
              onSelectSlot={(slot) => act('select_slot', { slot })}
            />
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
}

// ── Normal-slot offsets ─────────────────────────────────────────────────────

function AccessorySlotsSection(props: {
  groups: AccessoryGroupData[];
  activeGroup: AccessoryGroupKey;
  setActiveGroup: (group: AccessoryGroupKey) => void;
}) {
  const { groups, activeGroup, setActiveGroup } = props;
  const group = groups.find((candidate) => candidate.key === activeGroup) ?? groups[0];
  const slots = group?.slots ?? [];

  if (!group || !slots.length) {
    return (
      <Section title="Normal Slot Offsets">
        <Box italic color="label">
          No offset-editable normal slots are available yet.
        </Box>
      </Section>
    );
  }

  return (
    <Section
      title="Normal Slot Controls"
      buttons={
        <Box opacity={0.6} fontSize="11px" mt="4px">
          Choose the equipped accessory here; keyed slots also expose transform controls.
        </Box>
      }
    >
      <Tabs>
        {groups.map((candidate) => (
          <Tabs.Tab
            key={candidate.key}
            selected={activeGroup === candidate.key}
            onClick={() => setActiveGroup(candidate.key)}
          >
            {candidate.label}
          </Tabs.Tab>
        ))}
      </Tabs>

      <Box mt={1}>
      <Stack vertical>
        {slots.map((slot) => (
          <Stack.Item key={slot.key}>
            <RegularSlotCard slot={slot} />
          </Stack.Item>
        ))}
      </Stack>
      </Box>
    </Section>
  );
}

function RegularSlotCard(props: { slot: AccessorySlotData }) {
  const { act } = useBackend<BackendData>();
  const { slot } = props;
  const options = Array.isArray(slot.options) && slot.options.length ? slot.options : ['None'];

  return (
    <Section
      title={`${slot.label} Slot`}
      buttons={
        slot.current !== 'None' && (
          <Button
            icon="times"
            color="bad"
            compact
            tooltip="Clear this slot"
            onClick={() =>
              act('set_regular_slot_equipped', {
                slot: slot.key,
                option: 'None',
              })
            }
          />
        )
      }
    >
      <Stack align="center">
        <Stack.Item grow>
          <Dropdown
            width="100%"
            selected={slot.current}
            options={options}
            onSelected={(value: string) =>
              act('set_regular_slot_equipped', {
                slot: slot.key,
                option: value,
              })
            }
          />
        </Stack.Item>
      </Stack>

      {slot.custom_key ? (
        <Box mt={1}>
          <RegularSlotOffsetEditor slot={slot} />
        </Box>
      ) : (
        <Box mt={1} opacity={0.65} italic fontSize="11px">
          This slot does not expose transform controls.
        </Box>
      )}
    </Section>
  );
}

function RegularSlotOffsetEditor(props: { slot: AccessorySlotData }) {
  const { act, data } = useBackend<BackendData>();
  const { slot } = props;
  const slotKey = slot.custom_key;
  const { dir_keys = ['s', 'n', 'e', 'w'] } = data;
  const [activeDir, setActiveDir] = useState<DirKey>(
    (dir_keys[0] as DirKey) ?? 's',
  );
  const props_ = slot.slot_props ?? {};

  if (!slotKey) {
    return null;
  }

  const getN = (key: 'x' | 'y', fallback = 0): number => {
    const v = props_[`${activeDir}${key}`];
    return typeof v === 'number' ? v : fallback;
  };

  const updateField = (field: 'x' | 'y', value: number) => {
    act('set_slot_prop_field', {
      slot: slotKey,
      dir: activeDir,
      field,
      value,
    });
  };

  const nudgeField = (field: 'x' | 'y', delta: number) => {
    act('nudge_slot_prop_field', {
      slot: slotKey,
      dir: activeDir,
      field,
      delta,
    });
  };

  return (
    <Box>
      <Flex align="center" mb={1} wrap>
        <Flex.Item>
          <Box bold mr={1}>
            Per-direction offsets:
          </Box>
        </Flex.Item>
        {dir_keys.map((dir) => (
          <Flex.Item key={dir} mr={0.5} mb={0.25}>
            <Button
              selected={dir === activeDir}
              onClick={() => setActiveDir(dir as DirKey)}
            >
              {DIR_LABELS[dir as DirKey] ?? dir}
            </Button>
          </Flex.Item>
        ))}
        <Flex.Item grow={1} />
        <Flex.Item>
          <Button
            icon="undo"
            tooltip="Reset this slot to the default offset block"
            onClick={() => act('reset_slot_props', { slot: slotKey })}
          >
            Reset
          </Button>
        </Flex.Item>
      </Flex>

      <LabeledList>
        <LabeledList.Item label="X offset">
          <NumberInput
            value={getN('x')}
            minValue={-64}
            maxValue={64}
            step={1}
            width="60px"
            onChange={(value) => updateField('x', value)}
          />
          <Button ml={1} icon="minus" onClick={() => nudgeField('x', -1)} />
          <Button icon="plus" onClick={() => nudgeField('x', 1)} />
        </LabeledList.Item>

        <LabeledList.Item label="Y offset">
          <NumberInput
            value={getN('y')}
            minValue={-64}
            maxValue={64}
            step={1}
            width="60px"
            onChange={(value) => updateField('y', value)}
          />
          <Button ml={1} icon="minus" onClick={() => nudgeField('y', -1)} />
          <Button icon="plus" onClick={() => nudgeField('y', 1)} />
        </LabeledList.Item>
      </LabeledList>

      <Box mt={0.5} opacity={0.65} italic fontSize="11px">
        The same offset block is applied to every mask layer for this slot.
      </Box>
    </Box>
  );
}

function FreeformStickerSlotsSection(props: {
  activeSlot: SlotKey | null;
  activeEntry: number;
  slotKeys: SlotKey[];
  slotLabels: Record<SlotKey, string>;
  slotCfg: SlotConfig | undefined;
  entry: PiercingEntry | undefined;
  customPiercings: Record<SlotKey, SlotConfig>;
  onSelectSlot: (slot: SlotKey) => void;
}) {
  const {
    activeSlot,
    activeEntry,
    slotKeys,
    slotLabels,
    slotCfg,
    entry,
    customPiercings,
    onSelectSlot,
  } = props;

  return (
    <Section
      title="Freeform Sticker Slots"
      buttons={
        <Box opacity={0.6} fontSize="11px" mt="4px">
          These are the only slots that expose sticker editing.
        </Box>
      }
    >
      <Tabs>
        {slotKeys.map((slot) => {
          const cfg = customPiercings[slot];
          const count = cfg?.entries?.length ?? 0;
          const label =
            (cfg?.display_name && cfg.display_name.trim()) ||
            slotLabels[slot] ||
            slot;
          return (
            <Tabs.Tab
              key={slot}
              selected={slot === activeSlot}
              onClick={() => onSelectSlot(slot)}
            >
              {label}
              {count > 0 ? ` (${count})` : ''}
            </Tabs.Tab>
          );
        })}
      </Tabs>

      {!activeSlot && (
        <Box mt={2} opacity={0.6} italic>
          Pick a freeform slot tab to begin.
        </Box>
      )}

      {!!activeSlot && !!slotCfg && (
        <SlotPanel
          slotKey={activeSlot}
          slotCfg={slotCfg}
          entry={entry}
          entryIndex={activeEntry}
        />
      )}
    </Section>
  );
}

// ── Import / export modal ────────────────────────────────────────────────────

/**
 * Shared modal for both import (paste JSON) and export (copy JSON) flows.
 * Only one flow is ever visible at a time — export takes priority when the
 * backend has populated `export_payload`.
 */
function ImportExportModal(props: {
  exportPayload: string | null;
  importStatus: string | null;
  importText: string;
  setImportText: (s: string) => void;
  onCloseImport: () => void;
}) {
  const { act } = useBackend<BackendData>();
  const {
    exportPayload,
    importStatus,
    importText,
    setImportText,
    onCloseImport,
  } = props;
  const isExport = !!exportPayload;
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    if (!exportPayload) {
      return;
    }
    // navigator.clipboard is the modern path; BYOND's CEF shell supports it
    // when invoked from a user gesture. The worst case is silent failure,
    // which players work around by manually selecting the textarea contents.
    navigator.clipboard
      ?.writeText(exportPayload)
      .then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 1500);
      })
      .catch(() => {});
  };

  const handleClose = () => {
    act('close_io_modal');
    onCloseImport();
  };

  const statusColor = (() => {
    if (!importStatus) return 'label';
    return importStatus.startsWith('ok') ? 'good' : 'bad';
  })();

  return (
    <Section
      title={isExport ? 'Export Loadout' : 'Import Loadout'}
      buttons={
        <Button icon="times" onClick={handleClose}>
          Close
        </Button>
      }
      mb={1}
      style={{
        border: '1px solid rgba(255,255,255,0.25)',
      }}
    >
      {isExport ? (
        <>
          <Box mb={0.5} fontSize="0.85em" color="label">
            Copy this JSON to share your base accessory choices and sticker
            layout. Paste it into the Import dialog on another character to
            apply it.
          </Box>
          <TextArea
            fluid
            monospace
            height="8rem"
            value={exportPayload ?? ''}
            onChange={() => {}}
          />
          <Box mt={0.5}>
            <Button icon="copy" color="good" onClick={handleCopy}>
              {copied ? 'Copied!' : 'Copy to clipboard'}
            </Button>
          </Box>
        </>
      ) : (
        <>
          <Box mb={0.5} fontSize="0.85em" color="label">
            Paste a previously-exported loadout below. This will{' '}
            <Box inline bold color="bad">
              replace
            </Box>{' '}
            your current base accessory choices and stickers across all slots.
            You can still undo by closing the editor without saving.
          </Box>
          <TextArea
            fluid
            monospace
            height="8rem"
            placeholder="Paste exported JSON here…"
            value={importText}
            onChange={(value) => setImportText(value)}
          />
          <Box mt={0.5}>
            <Button
              icon="check"
              color="good"
              disabled={!importText.trim()}
              onClick={() => act('import_preset', { payload: importText })}
            >
              Apply Import
            </Button>
            {!!importStatus && (
              <Box inline ml={1} color={statusColor} italic>
                {importStatus}
              </Box>
            )}
          </Box>
        </>
      )}
    </Section>
  );
}

// ── Slot panel: toggles + entry list + detail editor ─────────────────────────

function SlotPanel(props: {
  slotKey: SlotKey;
  slotCfg: SlotConfig;
  entry: PiercingEntry | undefined;
  entryIndex: number;
}) {
  const { act, data } = useBackend<BackendData>();
  const { slotKey, slotCfg, entry, entryIndex } = props;
  const {
    slot_labels = {},
    freeform_slots = [],
    max_per_slot,
    max_name_length,
    dir_keys = ['s', 'n', 'e', 'w'],
  } = data;
  const entries = slotCfg.entries ?? [];
  const atCap = entries.length >= max_per_slot;
  const isFreeform = freeform_slots.includes(slotKey);
  // Direction preview is pure UI state — every edit action already takes
  // `dir` as an explicit param, so the server doesn't need to know which
  // direction button is currently highlighted. Shared between the preview
  // panel and the per-dir offset editor so they stay in sync.
  const [activeDir, setActiveDir] = useState<DirKey>(
    (dir_keys[0] as DirKey) ?? 's',
  );

  return (
    <Stack vertical mt={1}>
      <Stack.Item>
        <Section>
          <LabeledList>
            <LabeledList.Item label="Enabled">
              <Button.Checkbox
                checked={!!slotCfg.enabled}
                onClick={() => act('toggle_slot_enabled')}
              >
                {slotCfg.enabled ? 'Yes' : 'No'}
              </Button.Checkbox>
            </LabeledList.Item>
            {isFreeform ? (
              <>
                <LabeledList.Item label="Slot name">
                  <Input
                    value={slotCfg.display_name ?? ''}
                    maxLength={max_name_length}
                    placeholder={slot_labels[slotKey] ?? slotKey}
                    width="18rem"
                    onBlur={(value) =>
                      act('set_slot_display_name', { name: value })
                    }
                  />
                  <Box inline ml={1} opacity={0.6} fontSize="11px" italic>
                    Shown as the tab label and on examine (e.g. &quot;a glowing
                    rune&quot;). Leave blank for the default.
                  </Box>
                </LabeledList.Item>
                <LabeledList.Item label="Hide from examine">
                  <Button.Checkbox
                    checked={!!slotCfg.hide_from_examine}
                    onClick={() => act('toggle_hide_from_examine')}
                  >
                    {slotCfg.hide_from_examine ? 'Yes' : 'No'}
                  </Button.Checkbox>
                  <Box inline ml={1} opacity={0.6} fontSize="11px" italic>
                    When on, other players won&apos;t see this slot mentioned on
                    examine — it still renders on your sprite.
                  </Box>
                </LabeledList.Item>
              </>
            ) : (
              <LabeledList.Item label="Replace legacy overlay">
                <Button.Checkbox
                  checked={!!slotCfg.suppress_legacy}
                  onClick={() => act('toggle_suppress_legacy')}
                >
                  {slotCfg.suppress_legacy ? 'Yes' : 'No'}
                </Button.Checkbox>
                <Box inline ml={1} opacity={0.6} fontSize="11px" italic>
                  When on, your configured stickers replace the item&apos;s default
                  piercing sprite instead of layering over it.
                </Box>
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Flex>
          <Flex.Item basis="300px" shrink={0}>
            <EntryList
              entries={entries}
              activeIndex={entryIndex}
            />
          </Flex.Item>
          <Flex.Item ml={1} grow={1}>
            {entry ? (
              <EntryDetail
                entry={entry}
                entryIndex={entryIndex}
                activeDir={activeDir}
                setActiveDir={setActiveDir}
              />
            ) : (
              <Section title="Selected piercing">
                <Box opacity={0.6} italic>
                  {entries.length === 0
                    ? `No piercings on ${slot_labels[slotKey] ?? slotKey} yet. Add one from the picker below.`
                    : 'Select a piercing on the left to edit it.'}
                </Box>
              </Section>
            )}
          </Flex.Item>
        </Flex>
        <Box mt={1} opacity={0.55} italic fontSize="11px">
          Select a slot above, then use the piece bank and per-direction offset
          controls here.
        </Box>
      </Stack.Item>

      <Stack.Item>
        <StickerPicker key={slotKey} slotKey={slotKey} disabled={atCap} />
        {!!atCap && (
          <Box mt={1} color="bad" italic fontSize="11px">
            Slot is full ({max_per_slot} pieces). Remove one to add another.
          </Box>
        )}
      </Stack.Item>
    </Stack>
  );
}

// ── Entry list with reorder + remove ─────────────────────────────────────────

function EntryList(props: {
  entries: PiercingEntry[];
  activeIndex: number;
}) {
  const { act, data } = useBackend<BackendData>();
  const { entries, activeIndex } = props;
  const { sticker_registry = {} } = data;

  if (entries.length === 0) {
    return (
      <Section title="Pieces">
        <Box opacity={0.6} italic>
          None yet.
        </Box>
      </Section>
    );
  }

  return (
    <Section title={`Pieces (${entries.length})`} scrollable maxHeight="220px">
      <Box
        style={{
          display: 'flex',
          gap: '0.75rem',
          overflowX: 'auto',
          paddingBottom: '0.25rem',
        }}
      >
        {entries.map((entry, idx) => {
          const oneIdx = idx + 1;
          const selected = oneIdx === activeIndex;
          const info = sticker_registry[entry.sticker];
          const label = entry.custom_name || info?.name || entry.sticker;
          return (
            <Box key={oneIdx} style={{ flex: '0 0 auto', width: '112px' }}>
              <Button
                selected={selected}
                onClick={() =>
                  act('select_entry', { index: selected ? 0 : oneIdx })
                }
                style={{
                  width: '100%',
                  minHeight: '48px',
                  padding: '8px 10px',
                  textAlign: 'left',
                }}
              >
                <Box bold>
                  {oneIdx}. {label}
                </Box>
                <Box fontSize="11px" opacity={0.7}>
                  {info?.category || 'misc'}
                  {entry.custom_name ? ' · custom name' : ''}
                </Box>
              </Button>
              <Flex justify="center" mt={0.25}>
                <Flex.Item mr={0.25}>
                  <Button
                    icon="arrow-up"
                    compact
                    tooltip="Move up"
                    disabled={oneIdx === 1}
                    onClick={() =>
                      act('move_entry', { index: oneIdx, delta: -1 })
                    }
                  />
                </Flex.Item>
                <Flex.Item mr={0.25}>
                  <Button
                    icon="arrow-down"
                    compact
                    tooltip="Move down"
                    disabled={oneIdx === entries.length}
                    onClick={() =>
                      act('move_entry', { index: oneIdx, delta: 1 })
                    }
                  />
                </Flex.Item>
                <Flex.Item>
                  <Button
                    icon="trash"
                    compact
                    color="bad"
                    tooltip="Remove"
                    onClick={() => act('remove_entry', { index: oneIdx })}
                  />
                </Flex.Item>
              </Flex>
            </Box>
          );
        })}
      </Box>
    </Section>
  );
}

// ── Sticker picker list ─────────────────────────────────────────────────────

function StickerPicker(props: { slotKey: SlotKey; disabled: boolean }) {
  const { act, data } = useBackend<BackendData>();
  const { slotKey, disabled } = props;
  const { sticker_registry = {} } = data;
  const stickers = Object.values(sticker_registry).sort((left, right) => {
    const categoryCompare = (left.category || 'misc').localeCompare(
      right.category || 'misc',
    );
    if (categoryCompare !== 0) {
      return categoryCompare;
    }
    const nameCompare = left.name.localeCompare(right.name);
    if (nameCompare !== 0) {
      return nameCompare;
    }
    return left.id.localeCompare(right.id);
  });

  const [selectedStickerId, setSelectedStickerId] = useState<string | null>(
    () =>
      stickers.find((sticker) => sticker.suggested_slots?.includes(slotKey))
        ?.id ?? stickers[0]?.id ?? null,
  );

  const selectedSticker = selectedStickerId
    ? sticker_registry[selectedStickerId]
    : null;

  const handlePick = (stickerId: string) => {
    setSelectedStickerId(stickerId);
    act('add_entry', {
      slot: slotKey,
      sticker: stickerId,
    });
  };

  return (
    <Section title="Add sticker">
      <Flex gap={1} align="start">
        <Flex.Item basis="65%" grow={1}>
          <Box
            style={{
              maxHeight: '280px',
              overflowY: 'auto',
              paddingRight: '0.25rem',
            }}
          >
            <Stack vertical>
              {stickers.length ? (
                stickers.map((sticker) => {
                  const suggested = sticker.suggested_slots?.includes(slotKey);
                  const selected = sticker.id === selectedStickerId;
                  return (
                    <Stack.Item key={sticker.id}>
                      <Button
                        fluid
                        selected={selected}
                        disabled={disabled}
                        color={suggested ? 'good' : undefined}
                        tooltip={`${sticker.name}${suggested ? ' (suggested)' : ''}${sticker.has_gem ? ' · has gem' : ''}`}
                        onClick={() => handlePick(sticker.id)}
                        style={{ textAlign: 'left' }}
                      >
                        <Flex align="center">
                          <Flex.Item grow={1}>
                            <Box bold inline>
                              {sticker.name}
                            </Box>
                            <Box inline ml={1} opacity={0.7} fontSize="11px">
                              {sticker.category || 'misc'}
                            </Box>
                            {suggested && (
                              <Box inline ml={1} color="good" fontSize="11px">
                                suggested
                              </Box>
                            )}
                            {sticker.has_gem && (
                              <Box inline ml={1} opacity={0.7} fontSize="11px">
                                gem
                              </Box>
                            )}
                          </Flex.Item>
                        </Flex>
                      </Button>
                    </Stack.Item>
                  );
                })
              ) : (
                <Box opacity={0.6} italic>
                  No stickers available.
                </Box>
              )}
            </Stack>
          </Box>
        </Flex.Item>

        <Flex.Item basis="220px" shrink={0}>
          <Section title="Selected">
            {selectedSticker ? (
              <Stack vertical>
                <Stack.Item>
                  <Box bold>{selectedSticker.name}</Box>
                </Stack.Item>
                <Stack.Item>
                  <Box opacity={0.75} fontSize="11px">
                    {selectedSticker.category || 'misc'}
                    {selectedSticker.has_gem ? ' · has gem' : ''}
                    {selectedSticker.directional ? ' · directional' : ''}
                  </Box>
                </Stack.Item>
                <Stack.Item>
                  <Box opacity={0.6} italic fontSize="11px">
                    Click a row to add it. The mannequin shows the rendered result.
                  </Box>
                </Stack.Item>
              </Stack>
            ) : (
              <Box opacity={0.6} italic>
                Select an option to inspect it.
              </Box>
            )}
          </Section>
        </Flex.Item>
      </Flex>
    </Section>
  );
}

// ── Per-entry detail: colors, name/desc, per-dir props ───────────────────────

function EntryDetail(props: {
  entry: PiercingEntry;
  entryIndex: number;
  activeDir: DirKey;
  setActiveDir: (dir: DirKey) => void;
}) {
  const { act, data } = useBackend<BackendData>();
  const { entry, entryIndex, activeDir, setActiveDir } = props;
  const {
    sticker_registry = {},
    max_name_length,
    max_desc_length,
    entry_zones = [],
    entry_zone_labels = {},
  } = data;
  const info = sticker_registry[entry.sticker];
  const hasGem = !!info?.has_gem;

  const zoneOptions = entry_zones.map(
    (z) => (entry_zone_labels[z] ?? z) || 'Always visible',
  );
  const currentZoneLabel =
    entry_zone_labels[entry.zone ?? ''] ??
    entry_zone_labels[''] ??
    'Always visible';

  return (
    <Section title={`Editing: ${info?.name ?? entry.sticker}`}>
      <LabeledList>
        <LabeledList.Item label="Metal">
          <Button
            icon="palette"
            onClick={() =>
              act('pick_color', { index: entryIndex, which: 'metal' })
            }
          >
            Change
          </Button>
          <Box
            inline
            ml={1}
            style={{
              display: 'inline-block',
              width: '24px',
              height: '14px',
              verticalAlign: 'middle',
              backgroundColor: entry.metal_color,
              border: '1px solid #222',
            }}
          />
          <Box inline ml={0.5} fontSize="11px" opacity={0.7}>
            {entry.metal_color}
          </Box>
        </LabeledList.Item>

        {!!hasGem && (
          <LabeledList.Item label="Gem">
            <Button
              icon="palette"
              onClick={() =>
                act('pick_color', { index: entryIndex, which: 'gem' })
              }
            >
              Change
            </Button>
            <Box
              inline
              ml={1}
              style={{
                display: 'inline-block',
                width: '24px',
                height: '14px',
                verticalAlign: 'middle',
                backgroundColor: entry.gem_color ?? '#000',
                border: '1px solid #222',
              }}
            />
            <Box inline ml={0.5} fontSize="11px" opacity={0.7}>
              {entry.gem_color ?? '—'}
            </Box>
          </LabeledList.Item>
        )}

        <LabeledList.Item label="Hide when covered">
          <Button.Checkbox
            checked={!!entry.hide_when_covered}
            onClick={() =>
              act('toggle_hide_when_covered', { index: entryIndex })
            }
          >
            {entry.hide_when_covered ? 'Yes' : 'No'}
          </Button.Checkbox>
        </LabeledList.Item>

        <LabeledList.Item label="Body zone">
          <Dropdown
            width="160px"
            selected={currentZoneLabel}
            options={zoneOptions}
            onSelected={(label: string) => {
              const picked =
                entry_zones.find(
                  (z) =>
                    ((entry_zone_labels[z] ?? z) || 'Always visible') === label,
                ) ?? '';
              act('set_entry_zone', { index: entryIndex, zone: picked });
            }}
          />
          <Box inline ml={1} opacity={0.6} fontSize="11px" italic>
            Hides when this body zone is covered by clothing. &quot;Always visible&quot;
            ignores clothing.
          </Box>
        </LabeledList.Item>

        <LabeledList.Item label="Custom name">
          <Input
            value={entry.custom_name ?? ''}
            maxLength={max_name_length}
            placeholder={info?.name ?? entry.sticker}
            width="100%"
            onBlur={(value) =>
              act('set_name_desc', {
                index: entryIndex,
                name: value,
                desc: entry.custom_desc ?? '',
              })
            }
          />
        </LabeledList.Item>

        <LabeledList.Item label="Custom description">
          <TextArea
            value={entry.custom_desc ?? ''}
            maxLength={max_desc_length}
            height="60px"
            width="100%"
            onBlur={(value) =>
              act('set_name_desc', {
                index: entryIndex,
                name: entry.custom_name ?? '',
                desc: value,
              })
            }
          />
        </LabeledList.Item>
      </LabeledList>

      <Divider />

      <OffsetEditor
        entry={entry}
        entryIndex={entryIndex}
        activeDir={activeDir}
        setActiveDir={setActiveDir}
      />
    </Section>
  );
}

// ── Per-direction offset editor (taur-editor style) ──────────────────────────

function OffsetEditor(props: {
  entry: PiercingEntry;
  entryIndex: number;
  activeDir: DirKey;
  setActiveDir: (dir: DirKey) => void;
}) {
  const { act, data } = useBackend<BackendData>();
  const { entry, entryIndex, activeDir, setActiveDir } = props;
  const { dir_keys = ['s', 'n', 'e', 'w'] } = data;
  const props_ = entry.props ?? {};
  const getN = (key: string, fallback = 0): number => {
    const v = props_[`${activeDir}${key}`];
    return typeof v === 'number' ? v : fallback;
  };

  return (
    <Box>
      <Flex align="center" mb={1}>
        <Flex.Item>
          <Box bold mr={1}>
            Per-direction offsets:
          </Box>
        </Flex.Item>
        {dir_keys.map((dir) => (
          <Flex.Item key={dir} mr={0.5}>
            <Button
              selected={dir === activeDir}
              onClick={() => setActiveDir(dir as DirKey)}
            >
              {DIR_LABELS[dir as DirKey] ?? dir}
            </Button>
          </Flex.Item>
        ))}
        <Flex.Item grow={1} />
        <Flex.Item>
          <Button
            icon="undo"
            tooltip="Reset all directions to defaults"
            onClick={() => act('reset_entry_props', { index: entryIndex })}
          >
            Reset all
          </Button>
        </Flex.Item>
      </Flex>

      <LabeledList>
        <LabeledList.Item label="X offset">
          <NumberInput
            value={getN('x')}
            minValue={-64}
            maxValue={64}
            step={1}
            width="60px"
            onChange={(value) =>
              act('set_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'x',
                value,
              })
            }
          />
          <Button
            ml={1}
            icon="minus"
            onClick={() =>
              act('nudge_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'x',
                delta: -1,
              })
            }
          />
          <Button
            icon="plus"
            onClick={() =>
              act('nudge_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'x',
                delta: 1,
              })
            }
          />
        </LabeledList.Item>

        <LabeledList.Item label="Y offset">
          <NumberInput
            value={getN('y')}
            minValue={-64}
            maxValue={64}
            step={1}
            width="60px"
            onChange={(value) =>
              act('set_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'y',
                value,
              })
            }
          />
          <Button
            ml={1}
            icon="minus"
            onClick={() =>
              act('nudge_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'y',
                delta: -1,
              })
            }
          />
          <Button
            icon="plus"
            onClick={() =>
              act('nudge_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'y',
                delta: 1,
              })
            }
          />
        </LabeledList.Item>

        <LabeledList.Item label="Rotation">
          <Slider
            value={getN('turn')}
            minValue={0}
            maxValue={359}
            step={1}
            unit="°"
            width="200px"
            onChange={(_event, value) =>
              act('set_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'turn',
                value,
              })
            }
          />
        </LabeledList.Item>

        <LabeledList.Item label="Shrink">
          <Slider
            value={getN('shrink', 1) as number}
            minValue={0.1}
            maxValue={4}
            step={0.05}
            format={(v) => v.toFixed(2)}
            width="200px"
            onChange={(_event, value) =>
              act('set_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'shrink',
                value,
              })
            }
          />
        </LabeledList.Item>

        <LabeledList.Item label="Flags">
          <Button.Checkbox
            checked={!!getN('flip')}
            onClick={() =>
              act('toggle_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'flip',
              })
            }
          >
            Flip
          </Button.Checkbox>
          <Button.Checkbox
            checked={!!getN('above', 1)}
            tooltip="In-game only — the preview here has no body silhouette to layer against."
            onClick={() =>
              act('toggle_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'above',
              })
            }
          >
            Above body
          </Button.Checkbox>
          <Button.Checkbox
            checked={!!getN('hide')}
            onClick={() =>
              act('toggle_prop_field', {
                index: entryIndex,
                dir: activeDir,
                field: 'hide',
              })
            }
          >
            Hide on this dir
          </Button.Checkbox>
        </LabeledList.Item>
      </LabeledList>
    </Box>
  );
}

// ── Preview panel: client-side compositing + ghost drag ──────────────────────

/**
 * A client-side-only preview of the current slot's stickers.
 *
 * No server round-trip is needed for rendering: every entry's sticker DMI
 * thumbnail is composited with CSS transforms using the entry's x/y/turn/
 * shrink props and metal color. Dragging the active entry updates a local
 * ghost position in React state (zero `act()` calls during drag). On mouseup
 * a single `commit_drag` fires with the final absolute x/y, which the server
 * batches into one dirty-flip.
 *
 * Compared to a server-side mannequin regeneration pipeline, this pattern
 * costs: 0 Topic() calls during drag, 1 Topic() call on release, 0 icon
 * regenerations server-side. Scales trivially to hundreds of concurrent
 * editors.
 *
 * The preview canvas is a simple 32x32-px sprite space scaled up 5x. Sprite
 * coordinates use +y = up (matching Byond); CSS uses +y = down, so we invert.
 */


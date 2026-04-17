/**
 * @file CustomPiercingEditor.tsx
 * @description Per-character custom piercing (sticker) editor.
 *
 * Data contract matches /datum/custom_piercing_editor::ui_data. Mutations on
 * the backend only touch in-memory state + set `dirty`; persistence to disk
 * happens on the explicit "Save" button or when the window is closed
 * (autosave on Destroy). This matches the custom sex flavor editor pattern
 * and keeps disk thrash manageable at 200+ concurrent editors.
 */

import { useRef, useState } from 'react';
import { useBackend } from 'tgui/backend';
import { Window } from 'tgui/layouts';
import {
  Box,
  Button,
  Divider,
  DmIcon,
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

type BackendData = {
  active_slot: SlotKey | null;
  active_entry: number;
  slot_keys: SlotKey[];
  slot_labels: Record<SlotKey, string>;
  freeform_slots: SlotKey[];
  entry_zones: string[];
  entry_zone_labels: Record<string, string>;
  dir_keys: DirKey[];
  field_keys: string[];
  sticker_icon: string;
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

function groupStickersByCategory(
  registry: Record<string, StickerInfo>,
): Record<string, StickerInfo[]> {
  const out: Record<string, StickerInfo[]> = {};
  for (const id of Object.keys(registry)) {
    const s = registry[id];
    const cat = s.category || 'misc';
    if (!out[cat]) {
      out[cat] = [];
    }
    out[cat].push(s);
  }
  for (const cat of Object.keys(out)) {
    out[cat].sort((a, b) => a.name.localeCompare(b.name));
  }
  return out;
}

// ── Top-level component ──────────────────────────────────────────────────────

export function CustomPiercingEditor(props) {
  const { act, data } = useBackend<BackendData>();
  const {
    active_slot,
    active_entry,
    slot_keys = [],
    slot_labels = {},
    custom_piercings = {},
    dirty,
    export_payload,
    import_status,
  } = data;

  const slotCfg: SlotConfig | undefined = active_slot
    ? custom_piercings[active_slot]
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
          title="Custom Piercings"
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
            Stickers only render when the matching intimate accessory item is
            equipped. Changes are saved when you press Save or close this
            window.
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

          <Tabs>
            {slot_keys.map((slot) => {
              const cfg = custom_piercings[slot];
              const count = cfg?.entries?.length ?? 0;
              const label =
                (cfg?.display_name && cfg.display_name.trim()) ||
                slot_labels[slot] ||
                slot;
              return (
                <Tabs.Tab
                  key={slot}
                  selected={slot === active_slot}
                  onClick={() => act('select_slot', { slot })}
                >
                  {label}
                  {count > 0 ? ` (${count})` : ''}
                </Tabs.Tab>
              );
            })}
          </Tabs>

          {!active_slot && (
            <Box mt={2} opacity={0.6} italic>
              Pick a slot tab to begin.
            </Box>
          )}

          {!!active_slot && !!slotCfg && (
            <SlotPanel
              slotKey={active_slot}
              slotCfg={slotCfg}
              entry={entry}
              entryIndex={active_entry}
            />
          )}
        </Section>
      </Window.Content>
    </Window>
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
            Copy this JSON to share your loadout. Paste it into the Import
            dialog on another character to apply it.
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
            your current stickers across all slots. You can still undo by
            closing the editor without saving.
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
  const { slot_labels = {}, freeform_slots = [], max_per_slot, max_name_length, dir_keys = ['s', 'n', 'e', 'w'] } = data;
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
            {isFreeform && (
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
            )}
            {!isFreeform && (
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
          <Flex.Item ml={1} basis="180px" shrink={0}>
            <PreviewPanel
              entries={entries}
              activeIndex={entryIndex}
              activeDir={activeDir}
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
      </Stack.Item>

      <Stack.Item>
        <StickerPicker slotKey={slotKey} disabled={atCap} />
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
    <Section title={`Pieces (${entries.length})`} scrollable maxHeight="280px">
      {entries.map((entry, idx) => {
        const oneIdx = idx + 1;
        const selected = oneIdx === activeIndex;
        const info = sticker_registry[entry.sticker];
        const label = entry.custom_name || info?.name || entry.sticker;
        return (
          <Box
            key={oneIdx}
            p={0.5}
            mb={0.5}
            backgroundColor={selected ? 'rgba(255,255,255,0.08)' : undefined}
            style={{ border: '1px solid rgba(255,255,255,0.1)' }}
          >
            <Flex align="center">
              <Flex.Item grow={1}>
                <Button
                  fluid
                  selected={selected}
                  onClick={() =>
                    act('select_entry', { index: selected ? 0 : oneIdx })
                  }
                >
                  <StickerThumb
                    stickerId={entry.sticker}
                    metalColor={entry.metal_color}
                  />
                  <Box inline ml={1}>
                    {oneIdx}. {label}
                  </Box>
                </Button>
              </Flex.Item>
              <Flex.Item ml={0.5}>
                <Button
                  icon="arrow-up"
                  tooltip="Move up"
                  disabled={oneIdx === 1}
                  onClick={() =>
                    act('move_entry', { index: oneIdx, delta: -1 })
                  }
                />
                <Button
                  icon="arrow-down"
                  tooltip="Move down"
                  disabled={oneIdx === entries.length}
                  onClick={() => act('move_entry', { index: oneIdx, delta: 1 })}
                />
                <Button
                  icon="trash"
                  color="bad"
                  tooltip="Remove"
                  onClick={() => act('remove_entry', { index: oneIdx })}
                />
              </Flex.Item>
            </Flex>
          </Box>
        );
      })}
    </Section>
  );
}

// ── Sticker thumbnail via DmIcon (reads the shared sticker DMI directly) ────

function StickerThumb(props: {
  stickerId: string;
  metalColor?: string;
  scale?: number;
}) {
  const { data } = useBackend<BackendData>();
  const { sticker_icon } = data;
  const { stickerId, metalColor, scale = 1 } = props;
  // Raw DMI thumbnail. Color overlays aren't composited here (DmIcon doesn't
  // support multi-layer tinting); the metal color shows as a swatch.
  return (
    <Flex inline align="center">
      <DmIcon
        icon={sticker_icon}
        icon_state={stickerId}
        width={32 * scale}
        height={32 * scale}
      />
      {!!metalColor && (
        <Box
          inline
          ml={0.5}
          style={{
            width: '10px',
            height: '10px',
            backgroundColor: metalColor,
            border: '1px solid #222',
          }}
        />
      )}
    </Flex>
  );
}

// ── Sticker picker grid ──────────────────────────────────────────────────────

function StickerPicker(props: { slotKey: SlotKey; disabled: boolean }) {
  const { act, data } = useBackend<BackendData>();
  const { slotKey, disabled } = props;
  const { sticker_registry = {} } = data;
  const grouped = groupStickersByCategory(sticker_registry);
  const categories = Object.keys(grouped).sort();

  return (
    <Section title="Add sticker">
      {categories.map((cat) => (
        <Box key={cat} mb={1}>
          <Box bold mb={0.5}>
            {cat}
          </Box>
          <Flex wrap="wrap">
            {grouped[cat].map((sticker) => {
              const suggested = sticker.suggested_slots?.includes(slotKey);
              return (
                <Flex.Item key={sticker.id} m={0.25}>
                  <Button
                    disabled={disabled}
                    color={suggested ? 'good' : undefined}
                    tooltip={`${sticker.name}${suggested ? ' (suggested)' : ''}${sticker.has_gem ? ' · has gem' : ''}`}
                    onClick={() => act('add_entry', { sticker: sticker.id })}
                  >
                    <Flex inline align="center">
                      <StickerThumb stickerId={sticker.id} />
                      <Box inline ml={0.5}>
                        {sticker.name}
                      </Box>
                    </Flex>
                  </Button>
                </Flex.Item>
              );
            })}
          </Flex>
        </Box>
      ))}
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
            onChange={(value) =>
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
            onChange={(value) =>
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

// Piercing preview constants.
const PIERCING_PREVIEW_PX = 288; // on-screen canvas size (96 sprite * 3x zoom)
// Virtual sprite-space size used purely for offset math — matches the taur
// editor's 96x96 padded canvas so stickers can travel ±64 without clipping.
const PIERCING_SPRITE_PX = 96;
// Actual render size of an individual sticker DMI (native 32x32 tile).
const PIERCING_STICKER_PX = 32;
const PIERCING_SCREEN_SCALE = PIERCING_PREVIEW_PX / PIERCING_SPRITE_PX;
const PIERCING_XY_MIN = -64;
const PIERCING_XY_MAX = 64;

const piercingClamp = (v: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, v));

function PreviewPanel(props: {
  entries: PiercingEntry[];
  activeIndex: number;
  activeDir: DirKey;
}) {
  const { act, data } = useBackend<BackendData>();
  const { entries, activeIndex, activeDir } = props;
  const { sticker_icon, sticker_registry = {} } = data;

  // Ghost drag state. Only the active entry can be dragged.
  const dragStartPos = useRef<{ x: number; y: number } | null>(null);
  const dragStartVals = useRef<{ x: number; y: number }>({ x: 0, y: 0 });
  const [ghost, setGhost] = useState<{ dx: number; dy: number } | null>(null);

  const activeEntry =
    activeIndex >= 1 && activeIndex <= entries.length
      ? entries[activeIndex - 1]
      : undefined;

  const propN = (entry: PiercingEntry, key: string, fallback = 0): number => {
    const v = entry.props?.[`${activeDir}${key}`];
    return typeof v === 'number' ? v : fallback;
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    if (!activeEntry || e.button !== 0) {
      return;
    }
    e.preventDefault();
    dragStartPos.current = { x: e.clientX, y: e.clientY };
    dragStartVals.current = {
      x: propN(activeEntry, 'x'),
      y: propN(activeEntry, 'y'),
    };
    setGhost({ dx: 0, dy: 0 });
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!dragStartPos.current) {
      return;
    }
    setGhost({
      dx: e.clientX - dragStartPos.current.x,
      dy: e.clientY - dragStartPos.current.y,
    });
  };

  const finishDrag = () => {
    const g = ghost;
    const start = dragStartVals.current;
    dragStartPos.current = null;
    setGhost(null);
    if (!g || !activeEntry) {
      return;
    }
    if (g.dx === 0 && g.dy === 0) {
      return;
    }
    // Screen pixels → sprite pixels. Invert dy because sprite +y = up.
    const nextX = piercingClamp(
      Math.round(start.x + g.dx / PIERCING_SCREEN_SCALE),
      PIERCING_XY_MIN,
      PIERCING_XY_MAX,
    );
    const nextY = piercingClamp(
      Math.round(start.y - g.dy / PIERCING_SCREEN_SCALE),
      PIERCING_XY_MIN,
      PIERCING_XY_MAX,
    );
    act('commit_drag', {
      index: activeIndex,
      dir: activeDir,
      x: nextX,
      y: nextY,
    });
  };

  // Build entry render list. Active entry is rendered last (on top) and
  // offset by the live ghost delta during a drag; other entries use their
  // committed props unchanged.
  const renderEntry = (entry: PiercingEntry, oneIdx: number) => {
    if (!sticker_registry[entry.sticker]) {
      return null;
    }
    const x = propN(entry, 'x');
    const y = propN(entry, 'y');
    const turn = propN(entry, 'turn', 0);
    const shrink = propN(entry, 'shrink', 1);
    const hide = propN(entry, 'hide', 0);
    const flip = propN(entry, 'flip', 0);
    if (hide) {
      return null;
    }
    const isActive = oneIdx === activeIndex;
    const isDragging = isActive && !!ghost;
    // Sprite space → screen space (center-anchored). The sticker renders at
    // its native 32x32 tile size; PIERCING_SPRITE_PX is only used for the
    // offset math's coordinate space.
    const centerOffset = (PIERCING_PREVIEW_PX - PIERCING_STICKER_PX) / 2;
    let screenX = centerOffset + x * PIERCING_SCREEN_SCALE;
    let screenY = centerOffset - y * PIERCING_SCREEN_SCALE;
    if (isDragging && ghost) {
      screenX += ghost.dx;
      screenY += ghost.dy;
    }
    // Flip is rendered client-side via CSS scaleX(-1) rather than a server
    // regenerated sprite: BYOND's getFlatIcon does not honor
    // mutable_appearance.transform, so any scale/rotate/flip has to happen
    // in the DOM to show up live.
    const scaleX = shrink * (flip ? -1 : 1);
    return (
      <Box
        key={oneIdx}
        style={{
          position: 'absolute',
          left: `${screenX}px`,
          top: `${screenY}px`,
          width: `${PIERCING_STICKER_PX}px`,
          height: `${PIERCING_STICKER_PX}px`,
          transform: `rotate(${turn}deg) scale(${scaleX}, ${shrink})`,
          transformOrigin: '50% 50%',
          pointerEvents: 'none',
          opacity: isDragging ? 0.7 : 1,
          outline: isActive ? '1px dashed #ffffff80' : undefined,
          outlineOffset: '-1px',
        }}
      >
        <DmIcon
          icon={sticker_icon}
          icon_state={entry.sticker}
          width={PIERCING_STICKER_PX}
          height={PIERCING_STICKER_PX}
          color={entry.metal_color}
        />
      </Box>
    );
  };

  return (
    <Section title="Preview" fill>
      <Box
        style={{
          position: 'relative',
          width: `${PIERCING_PREVIEW_PX}px`,
          height: `${PIERCING_PREVIEW_PX}px`,
          margin: '0 auto',
          background: '#0e0e0e',
          border: '1px solid #333',
          imageRendering: 'pixelated',
          userSelect: 'none',
          cursor: activeEntry ? (ghost ? 'grabbing' : 'grab') : 'default',
        }}
        onMouseDown={handleMouseDown}
        onMouseMove={handleMouseMove}
        onMouseUp={finishDrag}
        onMouseLeave={finishDrag}
      >
        {/* Center crosshair for orientation. */}
        <Box
          style={{
            position: 'absolute',
            left: '50%',
            top: 0,
            bottom: 0,
            width: '1px',
            background: 'rgba(255,255,255,0.08)',
            pointerEvents: 'none',
          }}
        />
        <Box
          style={{
            position: 'absolute',
            top: '50%',
            left: 0,
            right: 0,
            height: '1px',
            background: 'rgba(255,255,255,0.08)',
            pointerEvents: 'none',
          }}
        />
        {entries.map((entry, idx) =>
          idx + 1 === activeIndex ? null : renderEntry(entry, idx + 1),
        )}
        {activeEntry ? renderEntry(activeEntry, activeIndex) : null}
      </Box>
      <Box mt={0.5} fontSize="10px" opacity={0.5} textAlign="center">
        Dir: {DIR_LABELS[activeDir as DirKey] ?? activeDir}
      </Box>
      <Box mt={0.5} fontSize="10px" opacity={0.4} textAlign="center" italic>
        {activeEntry
          ? 'Drag active piercing to reposition. Release to save.'
          : 'Select a piercing to drag it.'}
      </Box>
    </Section>
  );
}

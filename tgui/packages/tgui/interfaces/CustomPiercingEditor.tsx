/**
 * @file CustomPiercingEditor.tsx
 * @description Custom piercing / intimate accessory editor rebuilt on the
 * v2 shared appearance-preview runtime (Step 11 of the RustG-First refactor).
 *
 * ## Client-first contract
 *
 * The editor owns all draft state from the moment the panel opens. No
 * server round-trips happen during editing -- every control mutates local
 * React state and the preview updates immediately. On Save the client posts
 * a single `commit` action carrying a full snapshot of both surfaces:
 *
 *   - `regular_slots`: `{ <slot_key>: <option display label> | null }`
 *   - `custom_piercings`: the full freeform sticker-slot map.
 *
 * Export / import still round-trip through the server because the
 * sanitize + JSON-validate pipeline lives in DM. Color pickers use HTML5
 * native inputs so they never touch the server.
 *
 * ## Preview pipeline
 *
 * The server renders the real mannequin backdrop with the active selected
 * entry suppressed. TGUI renders only that one active sticker guide through
 * `HybridOffsetOverlay`, using server-owned descriptors or registry
 * prototype layers for newly added local entries. The editor never rebuilds
 * custom piercing icon-state names from sticker ids.
 */

import {
  type CSSProperties,
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  Box,
  Button,
  Dropdown,
  Input,
  LabeledList,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
  TextArea,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import {
  APPEARANCE_PREVIEW_DIRECTION_KEYS,
  type AppearancePreviewManifestV2,
  AppearancePreviewProvider,
  type AppearancePreviewV2DirectionKey,
  copyTextToClipboard,
  type DirectionalOffsetProps,
  DirectionControls,
  EditorShell,
  type HybridGuideDescriptor,
  HybridOffsetControls,
  HybridOffsetOverlay,
  ModalDialog,
  type OffsetTransformProps,
  useAppearancePreview,
  useCommitController,
} from '../components/appearance-preview';
import { Window } from '../layouts';
import {
  applyCustomPiercingDirectionalDraftsToProps,
  applyCustomPiercingHybridDraftToProps,
  applySelectedCustomPiercingGuideDraftToFreeform,
  buildCustomPiercingCommitSnapshot,
  combineCustomPiercingHybridDraft,
  type CustomPiercingHybridDescriptorMap,
  customPiercingPropsToHybridDraft,
  type CustomPiercingStickerHybridInfo,
  getCustomPiercingHybridDescriptor,
} from './CustomPiercingEditorLogic';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

type DirKey = AppearancePreviewV2DirectionKey;
type FieldKey = 'x' | 'y' | 'turn' | 'flip' | 'above' | 'hide' | 'shrink';

type PropMap = Record<string, number>;

type StickerInfo = CustomPiercingStickerHybridInfo & {
  id: string;
  name: string;
  category: string;
  has_gem: 0 | 1;
  directional: 0 | 1;
  suggested_slots: string[];
};

type PiercingEntry = {
  sticker: string;
  metal_color: string;
  gem_color: string | null;
  custom_name: string;
  custom_desc: string;
  zone: string;
  hide_when_covered: 0 | 1;
  props: PropMap;
};

type SlotConfig = {
  enabled: 0 | 1;
  suppress_legacy: 0 | 1;
  display_name: string;
  hide_from_examine: 0 | 1;
  entries: PiercingEntry[];
  slot_props: PropMap;
  equipped_typepath?: string | null;
};

type RegularSlotRow = {
  key: string;
  label: string;
  custom_key: string | null;
  group: string | null;
  current: string;
  options: string[];
  slot_props: PropMap | null;
};

type InitialSnapshot = {
  custom_piercings: Record<string, SlotConfig>;
  regular_slots: RegularSlotRow[];
};

type BackendData = {
  initial_slot: string | null;
  slot_keys: string[];
  slot_labels: Record<string, string>;
  freeform_slots: string[];
  entry_zones: string[];
  entry_zone_labels: Record<string, string>;
  dir_keys: DirKey[];
  field_keys: FieldKey[];
  sticker_icon: string;
  max_per_slot: number;
  max_total: number;
  max_name_length: number;
  max_desc_length: number;
  offset_min: number;
  offset_max: number;
  default_metal_color: string;
  default_gem_color: string;
  sticker_registry: Record<string, StickerInfo>;
  initial_snapshot: InitialSnapshot;
  export_payload: string | null;
  import_status: string | null;
  import_payload: Record<string, SlotConfig> | null;
  /** Commit envelope metadata echoed back on every `commit` action. */
  commit_contract: CommitContract;
  /** Outcome of the most recent commit, or null before the first attempt. */
  last_commit_result: LastCommitResult;
  /**
   * Per-direction base64 PNG snapshots of the owning client's character
   * mannequin, built server-side by `build_mannequin_previews()`. Rendered
   * as a background layer behind the accessory so players can judge
   * alignment against their actual body. Missing directions (or an empty
   * payload on the lobby) are handled gracefully — the preview simply
   * falls through to the bare checkerboard.
   */
  mannequin_previews?: Partial<Record<DirKey, string>>;
  /**
   * Server-resolved selected-entry guide descriptors, keyed by slot, one-based
   * entry index, then direction. New local entries use registry prototypes.
   */
  hybrid_descriptors?: CustomPiercingHybridDescriptorMap;
};

/** Commit envelope metadata contract (Step 12). */
type CommitContract = {
  editor_kind: string;
  pref_key: string;
  family_id: string;
  revision_token: number;
};

/** Server-reported commit outcome. */
type LastCommitResult = {
  ok: boolean;
  code: string;
  message: string | null;
  revision_token: number;
} | null;

type CommitSnapshot = {
  custom_piercings: Record<string, SlotConfig>;
  regular_slots: Record<string, string>;
};

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const DIR_LABELS: Record<DirKey, string> = {
  s: 'South',
  n: 'North',
  e: 'East',
  w: 'West',
};

const TURN_MIN = -359;
const TURN_MAX = 359;
const SHRINK_MIN = 0.1;
const SHRINK_MAX = 4.0;

const PREVIEW_SCALE = 3;
const PREVIEW_TILE_PX = 32 * PREVIEW_SCALE;
const PREVIEW_FRAME_PX = 288;

const GROUP_LABELS: Record<string, string> = {
  genital: 'Genital',
  rear: 'Rear',
  torso: 'Torso',
  head: 'Head',
  other: 'Other',
};

const GROUP_ORDER = ['genital', 'rear', 'torso', 'head', 'other'];

const clamp = (n: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, n));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function defaultPropMap(): PropMap {
  const out: PropMap = {};
  for (const dir of APPEARANCE_PREVIEW_DIRECTION_KEYS) {
    out[`${dir}x`] = 0;
    out[`${dir}y`] = 0;
    out[`${dir}turn`] = 0;
    out[`${dir}flip`] = 0;
    out[`${dir}above`] = 0;
    out[`${dir}hide`] = 0;
    out[`${dir}shrink`] = 1.0;
  }
  return out;
}

function applyField(
  props: PropMap,
  dir: DirKey,
  field: FieldKey,
  raw: number | boolean,
  offsetMin: number,
  offsetMax: number,
): PropMap {
  const key = `${dir}${field}`;
  const out = { ...props };
  switch (field) {
    case 'x':
    case 'y':
      out[key] = clamp(Math.round(Number(raw) || 0), offsetMin, offsetMax);
      break;
    case 'turn':
      out[key] = clamp(Math.round(Number(raw) || 0), TURN_MIN, TURN_MAX);
      break;
    case 'flip':
    case 'above':
    case 'hide':
      out[key] = raw ? 1 : 0;
      break;
    case 'shrink': {
      const n = Number(raw);
      out[key] = clamp(Number.isFinite(n) ? n : 1.0, SHRINK_MIN, SHRINK_MAX);
      break;
    }
  }
  return out;
}

function getAccessoryGroup(slotKey: string): string {
  if (slotKey.startsWith('genital_')) return 'genital';
  if (slotKey.startsWith('rear_')) return 'rear';
  if (
    slotKey === 'breast_piercing' ||
    slotKey === 'breast_insertable' ||
    slotKey === 'belly_piercing'
  ) {
    return 'torso';
  }
  if (
    slotKey === 'mouth_piercing' ||
    slotKey === 'mouth_insertable' ||
    slotKey === 'ear_piercing' ||
    slotKey === 'nose_piercing'
  ) {
    return 'head';
  }
  return 'other';
}

// ---------------------------------------------------------------------------
// Root
// ---------------------------------------------------------------------------

export function CustomPiercingEditor() {
  return (
    <Window theme="rogue" width={820} height={720}>
      <Window.Content scrollable>
        <AppearancePreviewProvider>
          <CustomPiercingEditorInner />
        </AppearancePreviewProvider>
      </Window.Content>
    </Window>
  );
}

function CustomPiercingEditorInner() {
  const { act, data } = useBackend<BackendData>();
  const {
    initial_slot,
    slot_labels = {},
    freeform_slots = ['custom_upper', 'custom_lower'],
    entry_zones = [],
    entry_zone_labels = {},
    dir_keys = ['s', 'n', 'e', 'w'],
    max_per_slot = 12,
    max_total = 64,
    max_name_length = 48,
    max_desc_length = 256,
    offset_min = -64,
    offset_max = 64,
    default_metal_color = '#C0C0C0',
    default_gem_color = '#FF0000',
    sticker_registry = {},
    initial_snapshot,
    export_payload,
    import_status,
    import_payload,
    hybrid_descriptors = {},
  } = data;
  const mannequinPreviews = data.mannequin_previews;

  const { manifest, loading, error } = useAppearancePreview();

  // -- Local draft state ----------------------------------------------
  // Seeded once from the initial snapshot. Both surfaces live here; the
  // server is only touched on commit / export / import / close.
  const [freeform, setFreeform] = useState<Record<string, SlotConfig>>(() => ({
    ...(initial_snapshot?.custom_piercings ?? {}),
  }));

  // Regular slots: map of slot_key -> current option display label.
  const regularSlotsInitial: RegularSlotRow[] =
    initial_snapshot?.regular_slots ?? [];
  const [regularSelections, setRegularSelections] = useState<
    Record<string, string>
  >(() => {
    const out: Record<string, string> = {};
    for (const row of regularSlotsInitial) {
      out[row.key] = row.current;
    }
    return out;
  });

  const [activeSlot, setActiveSlot] = useState<string>(
    initial_slot && freeform_slots.includes(initial_slot)
      ? initial_slot
      : (freeform_slots[0] ?? 'custom_upper'),
  );
  const [activeEntry, setActiveEntry] = useState<number>(0);
  const [activeDir, setActiveDir] = useState<DirKey>('s');
  const [editingSlotProps, setEditingSlotProps] = useState(false);
  const [dirty, setDirty] = useState(false);
  // Commit lifecycle is owned by the shared controller so Close cannot tear
  // the window down before the server confirms persistence. EditorShell
  // consumes the controller + renders DirtyIndicator/CommitBar/banner.
  const commitController = useCommitController<CommitSnapshot>({
    act,
    contract: data.commit_contract,
    lastCommitResult: data.last_commit_result,
  });
  const [ioOpen, setIoOpen] = useState(false);
  const [importText, setImportText] = useState('');

  // ── Refocus sync (Remediation Step 8) ────────────────────────────────
  // Mirror of the taur editor's effect: when the server pushes a new
  // `initial_slot` (user re-invoked the verb on a different freeform slot),
  // reseed the active slot if the draft is clean, otherwise queue + notice
  // so the refocus is never silently dropped and the draft is never
  // silently overwritten.
  const [refocusNotice, setRefocusNotice] = useState<string | null>(null);
  const pendingRefocusRef = useRef<string | null>(null);
  const lastSeenInitialSlotRef = useRef<string | null>(
    initial_slot && freeform_slots.includes(initial_slot) ? initial_slot : null,
  );

  useEffect(() => {
    const nextSlot =
      initial_slot && freeform_slots.includes(initial_slot)
        ? initial_slot
        : null;
    if (nextSlot === lastSeenInitialSlotRef.current) return;
    lastSeenInitialSlotRef.current = nextSlot;
    if (nextSlot === null) return;

    if (!dirty) {
      setActiveSlot(nextSlot);
      setRefocusNotice(null);
      pendingRefocusRef.current = null;
      return;
    }

    pendingRefocusRef.current = nextSlot;
    setRefocusNotice(
      'Another open request was ignored to protect your unsaved edits.',
    );
  }, [initial_slot, freeform_slots, dirty]);

  useEffect(() => {
    if (dirty) return;
    const pending = pendingRefocusRef.current;
    if (!pending) return;
    pendingRefocusRef.current = null;
    setActiveSlot(pending);
    setRefocusNotice(null);
  }, [dirty]);

  // -- Import payload ------- re-seed freeform draft ------------------------
  // When the server sends a sanitised import snapshot, replace the
  // freeform draft with it so the UI reflects what would actually be
  // committed. Close the modal after consuming.
  useEffect(() => {
    if (!import_payload) return;
    setFreeform({ ...import_payload });
    setDirty(true);
    setIoOpen(false);
    act('close_io_modal');
  }, [import_payload]);

  // -- Open/close io modal when server-driven export/import arrives ---
  useEffect(() => {
    if (export_payload !== null || import_status !== null) {
      setIoOpen(true);
    }
  }, [export_payload, import_status]);

  // -- Helpers over the active slot / entry ---------------------------
  const activeCfg: SlotConfig | null = freeform[activeSlot] ?? null;
  const entries = activeCfg?.entries ?? [];
  const entryCount = entries.length;
  const clampedEntryIdx = Math.min(activeEntry, Math.max(0, entryCount - 1));
  const activeEntryData: PiercingEntry | null =
    entries[clampedEntryIdx] ?? null;

  const totalEntries = useMemo(
    () =>
      Object.values(freeform).reduce(
        (acc, slot) => acc + (slot?.entries?.length ?? 0),
        0,
      ),
    [freeform],
  );

  const markDirty = useCallback(() => setDirty(true), []);

  const updateSlot = useCallback(
    (slotKey: string, patch: Partial<SlotConfig>) => {
      setFreeform((prev) => {
        const existing: SlotConfig = prev[slotKey] ?? {
          enabled: 0,
          suppress_legacy: 0,
          display_name: '',
          hide_from_examine: 0,
          entries: [],
          slot_props: defaultPropMap(),
        };
        return { ...prev, [slotKey]: { ...existing, ...patch } };
      });
      markDirty();
    },
    [markDirty],
  );

  const updateEntry = useCallback(
    (slotKey: string, idx: number, patch: Partial<PiercingEntry>) => {
      setFreeform((prev) => {
        const slot = prev[slotKey];
        if (!slot || !slot.entries[idx]) return prev;
        const nextEntries = slot.entries.slice();
        nextEntries[idx] = { ...nextEntries[idx], ...patch };
        return { ...prev, [slotKey]: { ...slot, entries: nextEntries } };
      });
      markDirty();
    },
    [markDirty],
  );

  const addEntry = (slotKey: string, stickerId: string) => {
    const sticker = sticker_registry[stickerId];
    if (!sticker) return;
    if (totalEntries >= max_total) return;
    const cfg = freeform[slotKey];
    const currentCount = cfg?.entries?.length ?? 0;
    if (currentCount >= max_per_slot) return;
    const newEntry: PiercingEntry = {
      sticker: stickerId,
      metal_color: default_metal_color,
      gem_color: sticker.has_gem ? default_gem_color : null,
      custom_name: '',
      custom_desc: '',
      zone: '',
      hide_when_covered: 0,
      props: defaultPropMap(),
    };
    setFreeform((prev) => {
      const existing: SlotConfig = prev[slotKey] ?? {
        enabled: 1,
        suppress_legacy: 0,
        display_name: '',
        hide_from_examine: 0,
        entries: [],
        slot_props: defaultPropMap(),
      };
      return {
        ...prev,
        [slotKey]: {
          ...existing,
          enabled: 1,
          entries: [...existing.entries, newEntry],
        },
      };
    });
    setActiveEntry(currentCount);
    markDirty();
  };

  const removeEntry = (slotKey: string, idx: number) => {
    setFreeform((prev) => {
      const slot = prev[slotKey];
      if (!slot || !slot.entries[idx]) return prev;
      const nextEntries = slot.entries.slice();
      nextEntries.splice(idx, 1);
      return { ...prev, [slotKey]: { ...slot, entries: nextEntries } };
    });
    setActiveEntry((prev) => Math.max(0, prev - (idx <= activeEntry ? 1 : 0)));
    markDirty();
  };

  const moveEntry = (slotKey: string, idx: number, delta: number) => {
    const target = idx + delta;
    setFreeform((prev) => {
      const slot = prev[slotKey];
      if (!slot) return prev;
      if (target < 0 || target >= slot.entries.length) return prev;
      const nextEntries = slot.entries.slice();
      const [moved] = nextEntries.splice(idx, 1);
      nextEntries.splice(target, 0, moved);
      return { ...prev, [slotKey]: { ...slot, entries: nextEntries } };
    });
    if (activeEntry === idx) setActiveEntry(target);
    markDirty();
  };

  // -- Prop field editors ----------------------------------------------
  const writeActiveEntryProps = (next: PropMap) => {
    if (!activeEntryData) return;
    updateEntry(activeSlot, clampedEntryIdx, { props: next });
  };

  const writeSlotProps = (next: PropMap) => {
    if (!activeCfg) return;
    updateSlot(activeSlot, { slot_props: next });
  };

  const currentPropSource: PropMap = editingSlotProps
    ? (activeCfg?.slot_props ?? defaultPropMap())
    : (activeEntryData?.props ?? defaultPropMap());

  const setPropField = (field: FieldKey, raw: number | boolean) => {
    const next = applyField(
      currentPropSource,
      activeDir,
      field,
      raw,
      offset_min,
      offset_max,
    );
    if (editingSlotProps) writeSlotProps(next);
    else writeActiveEntryProps(next);
  };

  const togglePropField = (field: FieldKey) => {
    setPropField(field, !currentPropSource[`${activeDir}${field}`]);
  };

  const resetCurrentDir = () => {
    const defaults = defaultPropMap();
    const next = { ...currentPropSource };
    for (const f of [
      'x',
      'y',
      'turn',
      'flip',
      'above',
      'hide',
      'shrink',
    ] as FieldKey[]) {
      next[`${activeDir}${f}`] = defaults[`${activeDir}${f}`];
    }
    if (editingSlotProps) writeSlotProps(next);
    else writeActiveEntryProps(next);
  };

  const resetAllDirs = () => {
    if (editingSlotProps) writeSlotProps(defaultPropMap());
    else writeActiveEntryProps(defaultPropMap());
  };

  const propVal = (field: FieldKey, fb = 0) => {
    const v = currentPropSource[`${activeDir}${field}`];
    return typeof v === 'number' ? v : fb;
  };

  const activeEntryHybridDescriptor = useMemo(
    () =>
      getCustomPiercingHybridDescriptor({
        descriptors: hybrid_descriptors,
        stickerRegistry: sticker_registry,
        slotKey: activeSlot,
        entryIndex: clampedEntryIdx,
        direction: activeDir,
        entry: activeEntryData,
        defaultMetalColor: default_metal_color,
        defaultGemColor: default_gem_color,
      }),
    [
      activeDir,
      activeEntryData?.gem_color,
      activeEntryData?.metal_color,
      activeEntryData?.sticker,
      activeSlot,
      clampedEntryIdx,
      default_gem_color,
      default_metal_color,
      hybrid_descriptors,
      sticker_registry,
    ],
  );

  const activeEntryHybridDraft = useMemo(
    () => customPiercingPropsToHybridDraft(activeEntryData?.props, activeDir),
    [activeDir, activeEntryData?.props],
  );

  const activeEntryGuideDraft = useMemo(
    () =>
      combineCustomPiercingHybridDraft(
        activeEntryData?.props,
        activeCfg?.slot_props,
        activeDir,
      ),
    [activeCfg?.slot_props, activeDir, activeEntryData?.props],
  );

  const updateActiveEntryHybridDraft = (nextDraft: OffsetTransformProps) => {
    if (!activeEntryData) return;
    writeActiveEntryProps(
      applyCustomPiercingHybridDraftToProps(
        activeEntryData.props ?? defaultPropMap(),
        activeDir,
        nextDraft,
        offset_min,
        offset_max,
      ),
    );
  };

  const updateActiveEntryGuideDraft = (nextDraft: OffsetTransformProps) => {
    if (!activeEntryData) return;
    setFreeform((prev) =>
      applySelectedCustomPiercingGuideDraftToFreeform(
        prev,
        activeSlot,
        clampedEntryIdx,
        activeDir,
        nextDraft,
        offset_min,
        offset_max,
      ),
    );
    markDirty();
  };

  const copyActiveEntryHybridDraftToAll = (
    nextDrafts: DirectionalOffsetProps,
  ) => {
    if (!activeEntryData) return;
    writeActiveEntryProps(
      applyCustomPiercingDirectionalDraftsToProps(
        activeEntryData.props ?? defaultPropMap(),
        nextDrafts,
        offset_min,
        offset_max,
      ),
    );
  };

  // -- Commit snapshot builder ----------------------------------------
  // Pure closure over current draft state; the shell invokes this at the
  // moment of Save/Close so the latest state is captured.
  const buildSnapshot = (): CommitSnapshot =>
    buildCustomPiercingCommitSnapshot(freeform, regularSelections);

  const onExport = () => {
    act('export_preset', { custom_piercings: freeform });
  };

  const onImport = () => {
    if (!importText.trim()) return;
    act('import_preset', { payload: importText });
  };

  const closeIoModal = () => {
    setIoOpen(false);
    setImportText('');
    act('close_io_modal');
  };

  // -- Regular accessory section helpers -------------------------------
  const regularRowsByGroup = useMemo(() => {
    const out: Record<string, RegularSlotRow[]> = {};
    for (const row of regularSlotsInitial) {
      const group = row.group || getAccessoryGroup(row.key);
      if (!out[group]) out[group] = [];
      out[group].push(row);
    }
    return out;
  }, [regularSlotsInitial]);

  const updateRegular = (key: string, value: string) => {
    setRegularSelections((prev) => ({ ...prev, [key]: value }));
    markDirty();
  };

  // -- Render ---------------------------------------------------------
  // Export/Import live in the shell header so they are reachable regardless
  // of scroll position. Banner + dirty indicator + CommitBar are all owned
  // by EditorShell now.
  const headerSlot = (
    <Box style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
      <Button
        icon="file-export"
        tooltip="Export the current freeform sticker draft as JSON"
        onClick={onExport}
      >
        Export
      </Button>
      <Button
        icon="file-import"
        tooltip="Import a freeform sticker preset from JSON"
        onClick={() => setIoOpen(true)}
      >
        Import
      </Button>
    </Box>
  );

  return (
    <EditorShell<CommitSnapshot>
      title="Intimate Accessories & Piercings"
      dirty={dirty}
      commitController={commitController}
      buildSnapshot={buildSnapshot}
      onCommitted={() => setDirty(false)}
      onCloseClean={() => act('close')}
      headerSlot={headerSlot}
    >
      {refocusNotice && (
        <div
          role="status"
          aria-live="polite"
          style={{
            marginBottom: '0.5rem',
            padding: '0.25rem 0.5rem',
            background: 'rgba(180, 140, 60, 0.15)',
            border: '1px solid rgba(180, 140, 60, 0.45)',
            borderRadius: '2px',
            fontSize: '11px',
          }}
        >
          {refocusNotice}
        </div>
      )}
      <Box mb={1} opacity={0.6} fontSize="11px" italic>
        Choose equipped intimate accessories and compose custom sticker
        piercings. Changes apply locally; the lobby mannequin updates on
        explicit Save.
      </Box>

      <RegularAccessorySection
        rowsByGroup={regularRowsByGroup}
        selections={regularSelections}
        onChange={updateRegular}
      />

      <FreeformStickerSection
        freeform={freeform}
        freeformSlots={freeform_slots}
        slotLabels={slot_labels}
        activeSlot={activeSlot}
        setActiveSlot={setActiveSlot}
        activeEntry={clampedEntryIdx}
        setActiveEntry={setActiveEntry}
        activeDir={activeDir}
        setActiveDir={setActiveDir}
        dirKeys={dir_keys}
        activeCfg={activeCfg}
        activeEntryData={activeEntryData}
        activeEntryHybridDescriptor={activeEntryHybridDescriptor}
        activeEntryHybridDraft={activeEntryHybridDraft}
        activeEntryGuideDraft={activeEntryGuideDraft}
        stickerRegistry={sticker_registry}
        entryZones={entry_zones}
        entryZoneLabels={entry_zone_labels}
        maxPerSlot={max_per_slot}
        totalEntries={totalEntries}
        maxTotal={max_total}
        maxNameLength={max_name_length}
        maxDescLength={max_desc_length}
        offsetMin={offset_min}
        offsetMax={offset_max}
        defaultMetalColor={default_metal_color}
        defaultGemColor={default_gem_color}
        editingSlotProps={editingSlotProps}
        setEditingSlotProps={setEditingSlotProps}
        loading={loading}
        error={error}
        manifest={manifest}
        mannequinPreviews={mannequinPreviews}
        propVal={propVal}
        setPropField={setPropField}
        togglePropField={togglePropField}
        resetCurrentDir={resetCurrentDir}
        resetAllDirs={resetAllDirs}
        updateActiveEntryHybridDraft={updateActiveEntryHybridDraft}
        updateActiveEntryGuideDraft={updateActiveEntryGuideDraft}
        copyActiveEntryHybridDraftToAll={copyActiveEntryHybridDraftToAll}
        updateSlot={updateSlot}
        updateEntry={updateEntry}
        addEntry={addEntry}
        removeEntry={removeEntry}
        moveEntry={moveEntry}
      />

      {ioOpen && (
        <ImportExportModal
          exportPayload={export_payload}
          importStatus={import_status}
          importText={importText}
          onImportTextChange={setImportText}
          onImport={onImport}
          onClose={closeIoModal}
        />
      )}
    </EditorShell>
  );
}

// ---------------------------------------------------------------------------
// Regular Accessory Section
// ---------------------------------------------------------------------------

function RegularAccessorySection(props: {
  rowsByGroup: Record<string, RegularSlotRow[]>;
  selections: Record<string, string>;
  onChange: (slotKey: string, value: string) => void;
}) {
  const { rowsByGroup, selections, onChange } = props;
  const groups = GROUP_ORDER.filter(
    (g) => rowsByGroup[g] && rowsByGroup[g].length,
  );
  if (!groups.length) return null;

  return (
    <Section title="Equipped Intimate Accessories">
      <Stack vertical>
        {groups.map((group) => (
          <Stack.Item key={group}>
            <Box fontSize="12px" mb={0.5} opacity={0.75}>
              {GROUP_LABELS[group] ?? group}
            </Box>
            <LabeledList>
              {rowsByGroup[group].map((row) => (
                <LabeledList.Item key={row.key} label={row.label}>
                  <Dropdown
                    width="220px"
                    selected={selections[row.key] ?? row.current}
                    options={row.options}
                    onSelected={(value) => onChange(row.key, value)}
                  />
                </LabeledList.Item>
              ))}
            </LabeledList>
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Freeform Sticker Section
// ---------------------------------------------------------------------------

type FreeformSectionProps = {
  freeform: Record<string, SlotConfig>;
  freeformSlots: string[];
  slotLabels: Record<string, string>;
  activeSlot: string;
  setActiveSlot: (slot: string) => void;
  activeEntry: number;
  setActiveEntry: (idx: number) => void;
  activeDir: DirKey;
  setActiveDir: (dir: DirKey) => void;
  dirKeys: DirKey[];
  activeCfg: SlotConfig | null;
  activeEntryData: PiercingEntry | null;
  activeEntryHybridDescriptor: HybridGuideDescriptor | null;
  activeEntryHybridDraft: OffsetTransformProps;
  activeEntryGuideDraft: OffsetTransformProps;
  stickerRegistry: Record<string, StickerInfo>;
  entryZones: string[];
  entryZoneLabels: Record<string, string>;
  maxPerSlot: number;
  totalEntries: number;
  maxTotal: number;
  maxNameLength: number;
  maxDescLength: number;
  offsetMin: number;
  offsetMax: number;
  defaultMetalColor: string;
  defaultGemColor: string;
  editingSlotProps: boolean;
  setEditingSlotProps: (v: boolean) => void;
  loading: boolean;
  error: Error | null;
  manifest: AppearancePreviewManifestV2 | null;
  /** Per-direction mannequin backdrop PNGs; see `MannequinBackdrop`. */
  mannequinPreviews?: Partial<Record<DirKey, string>>;
  propVal: (field: FieldKey, fb?: number) => number;
  setPropField: (field: FieldKey, raw: number | boolean) => void;
  togglePropField: (field: FieldKey) => void;
  resetCurrentDir: () => void;
  resetAllDirs: () => void;
  updateActiveEntryHybridDraft: (nextDraft: OffsetTransformProps) => void;
  updateActiveEntryGuideDraft: (nextDraft: OffsetTransformProps) => void;
  copyActiveEntryHybridDraftToAll: (nextDrafts: DirectionalOffsetProps) => void;
  updateSlot: (slotKey: string, patch: Partial<SlotConfig>) => void;
  updateEntry: (
    slotKey: string,
    idx: number,
    patch: Partial<PiercingEntry>,
  ) => void;
  addEntry: (slotKey: string, stickerId: string) => void;
  removeEntry: (slotKey: string, idx: number) => void;
  moveEntry: (slotKey: string, idx: number, delta: number) => void;
};

function FreeformStickerSection(props: FreeformSectionProps) {
  const {
    freeform,
    freeformSlots,
    slotLabels,
    activeSlot,
    setActiveSlot,
    activeEntry,
    setActiveEntry,
    activeDir,
    setActiveDir,
    dirKeys,
    activeCfg,
    activeEntryData,
    activeEntryHybridDescriptor,
    activeEntryHybridDraft,
    activeEntryGuideDraft,
    stickerRegistry,
    entryZones,
    entryZoneLabels,
    maxPerSlot,
    totalEntries,
    maxTotal,
    maxNameLength,
    maxDescLength,
    offsetMin,
    offsetMax,
    defaultMetalColor,
    defaultGemColor,
    editingSlotProps,
    setEditingSlotProps,
    loading,
    error,
    manifest,
    mannequinPreviews,
    propVal,
    setPropField,
    togglePropField,
    resetCurrentDir,
    resetAllDirs,
    updateActiveEntryHybridDraft,
    updateActiveEntryGuideDraft,
    copyActiveEntryHybridDraftToAll,
    updateSlot,
    updateEntry,
    addEntry,
    removeEntry,
    moveEntry,
  } = props;

  const entries = activeCfg?.entries ?? [];

  return (
    <Section title="Freeform Sticker Slots">
      <Tabs>
        {freeformSlots.map((slot) => {
          const cfg = freeform[slot];
          const label =
            (cfg?.display_name && cfg.display_name.trim()) ||
            slotLabels[slot] ||
            slot;
          const count = cfg?.entries?.length ?? 0;
          return (
            <Tabs.Tab
              key={slot}
              selected={slot === activeSlot}
              onClick={() => {
                setActiveSlot(slot);
                setActiveEntry(0);
                setEditingSlotProps(false);
              }}
            >
              {label} ({count})
            </Tabs.Tab>
          );
        })}
      </Tabs>

      <Box mt={1} opacity={0.6} fontSize="11px">
        Total entries: {totalEntries} / {maxTotal} &middot; This slot:{' '}
        {entries.length} / {maxPerSlot}
      </Box>

      <Stack mt={1}>
        <Stack.Item grow={1} basis="240px">
          <SlotControls
            slotKey={activeSlot}
            cfg={activeCfg}
            slotLabels={slotLabels}
            maxNameLength={maxNameLength}
            onPatch={(p) => updateSlot(activeSlot, p)}
          />
          <EntryList
            entries={entries}
            stickerRegistry={stickerRegistry}
            activeEntry={activeEntry}
            onSelect={(idx) => {
              setActiveEntry(idx);
              setEditingSlotProps(false);
            }}
            onRemove={(idx) => removeEntry(activeSlot, idx)}
            onMove={(idx, delta) => moveEntry(activeSlot, idx, delta)}
          />
          <StickerPicker
            stickerRegistry={stickerRegistry}
            slotKey={activeSlot}
            canAdd={totalEntries < maxTotal && entries.length < maxPerSlot}
            onAdd={(id) => addEntry(activeSlot, id)}
          />
        </Stack.Item>
        <Stack.Item grow={1} basis="320px">
          <Section
            title="Preview"
            buttons={
              <DirectionControls
                activeDir={activeDir}
                dirKeys={dirKeys}
                onChange={setActiveDir}
              />
            }
          >
            <SelectedEntryPreview
              loading={loading}
              error={error}
              manifest={manifest}
              cfg={activeCfg}
              entry={activeEntryData}
              descriptor={activeEntryHybridDescriptor}
              draftProps={activeEntryGuideDraft}
              onDraftChange={updateActiveEntryGuideDraft}
              direction={activeDir}
              mannequinPreviews={mannequinPreviews}
            />
          </Section>
          <EntryDetail
            activeEntryData={activeEntryData}
            stickerRegistry={stickerRegistry}
            entryZones={entryZones}
            entryZoneLabels={entryZoneLabels}
            maxNameLength={maxNameLength}
            maxDescLength={maxDescLength}
            defaultMetalColor={defaultMetalColor}
            defaultGemColor={defaultGemColor}
            onPatch={(patch) => {
              if (!activeEntryData) return;
              updateEntry(activeSlot, activeEntry, patch);
            }}
          />
          {editingSlotProps ? (
            <PropsEditor
              editingSlotProps={editingSlotProps}
              setEditingSlotProps={setEditingSlotProps}
              hasEntry={!!activeEntryData}
              dirLabel={DIR_LABELS[activeDir]}
              propVal={propVal}
              setPropField={setPropField}
              togglePropField={togglePropField}
              resetCurrentDir={resetCurrentDir}
              resetAllDirs={resetAllDirs}
              offsetMin={offsetMin}
              offsetMax={offsetMax}
            />
          ) : (
            <SelectedEntryHybridControls
              descriptor={activeEntryHybridDescriptor}
              draftProps={activeEntryHybridDraft}
              direction={activeDir}
              dirKeys={dirKeys}
              hasEntry={!!activeEntryData}
              onDirectionChange={setActiveDir}
              onDraftChange={updateActiveEntryHybridDraft}
              onCopyToAll={copyActiveEntryHybridDraftToAll}
              onEditSlotProps={() => setEditingSlotProps(true)}
              offsetMin={offsetMin}
              offsetMax={offsetMax}
            />
          )}
        </Stack.Item>
      </Stack>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Slot-level controls (enable / suppress legacy / display name / examine)
// ---------------------------------------------------------------------------

function SlotControls(props: {
  slotKey: string;
  cfg: SlotConfig | null;
  slotLabels: Record<string, string>;
  maxNameLength: number;
  onPatch: (patch: Partial<SlotConfig>) => void;
}) {
  const { slotKey, cfg, slotLabels, maxNameLength, onPatch } = props;
  const enabled = !!cfg?.enabled;
  const suppressLegacy = !!cfg?.suppress_legacy;
  const hideExamine = !!cfg?.hide_from_examine;
  const displayName = cfg?.display_name ?? '';

  return (
    <Section title="Slot Settings">
      <LabeledList>
        <LabeledList.Item label="Slot">
          <Box>{slotLabels[slotKey] ?? slotKey}</Box>
        </LabeledList.Item>
        <LabeledList.Item label="Enabled">
          <Button.Checkbox
            checked={enabled}
            onClick={() => onPatch({ enabled: enabled ? 0 : 1 })}
          >
            {enabled ? 'On' : 'Off'}
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Display Name">
          <Input
            width="180px"
            value={displayName}
            maxLength={maxNameLength}
            placeholder={slotLabels[slotKey] ?? slotKey}
            onChange={(value) => onPatch({ display_name: value })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Hide from examine">
          <Button.Checkbox
            checked={hideExamine}
            onClick={() => onPatch({ hide_from_examine: hideExamine ? 0 : 1 })}
          >
            {hideExamine ? 'Hidden' : 'Visible'}
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Suppress legacy sprite">
          <Button.Checkbox
            checked={suppressLegacy}
            onClick={() => onPatch({ suppress_legacy: suppressLegacy ? 0 : 1 })}
          >
            {suppressLegacy ? 'Suppressed' : 'Normal'}
          </Button.Checkbox>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Entry list (reorderable via up/down)
// ---------------------------------------------------------------------------

function EntryList(props: {
  entries: PiercingEntry[];
  stickerRegistry: Record<string, StickerInfo>;
  activeEntry: number;
  onSelect: (idx: number) => void;
  onRemove: (idx: number) => void;
  onMove: (idx: number, delta: number) => void;
}) {
  const { entries, stickerRegistry, activeEntry, onSelect, onRemove, onMove } =
    props;
  if (!entries.length) {
    return (
      <Section title="Entries">
        <Box opacity={0.55} italic>
          No entries. Pick a sticker below to add the first one.
        </Box>
      </Section>
    );
  }
  return (
    <Section title="Entries">
      <Stack vertical>
        {entries.map((entry, idx) => {
          const info = stickerRegistry[entry.sticker];
          const label =
            entry.custom_name?.trim() ||
            info?.name ||
            entry.sticker ||
            '(unknown)';
          const isActive = idx === activeEntry;
          return (
            <Stack.Item key={idx}>
              <Stack align="center">
                <Stack.Item grow>
                  <Button
                    fluid
                    selected={isActive}
                    onClick={() => onSelect(idx)}
                  >
                    {idx + 1}. {label}
                  </Button>
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="arrow-up"
                    tooltip="Move up"
                    disabled={idx === 0}
                    onClick={() => onMove(idx, -1)}
                  />
                  <Button
                    icon="arrow-down"
                    tooltip="Move down"
                    disabled={idx === entries.length - 1}
                    onClick={() => onMove(idx, 1)}
                  />
                  <Button
                    icon="trash"
                    color="bad"
                    tooltip="Remove"
                    onClick={() => onRemove(idx)}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Sticker picker (add new entry)
// ---------------------------------------------------------------------------

function StickerPicker(props: {
  stickerRegistry: Record<string, StickerInfo>;
  slotKey: string;
  canAdd: boolean;
  onAdd: (id: string) => void;
}) {
  const { stickerRegistry, slotKey, canAdd, onAdd } = props;
  const [filter, setFilter] = useState('');
  const [showAll, setShowAll] = useState(false);

  const ids = useMemo(
    () => Object.keys(stickerRegistry).sort(),
    [stickerRegistry],
  );

  const filtered = ids.filter((id) => {
    const info = stickerRegistry[id];
    if (!info) return false;
    if (
      !showAll &&
      info.suggested_slots.length &&
      !info.suggested_slots.includes(slotKey)
    ) {
      return false;
    }
    if (filter) {
      const q = filter.toLowerCase();
      if (
        !info.id.toLowerCase().includes(q) &&
        !info.name.toLowerCase().includes(q)
      ) {
        return false;
      }
    }
    return true;
  });

  return (
    <Section title="Add Sticker">
      <Stack align="center" mb={0.5}>
        <Stack.Item grow>
          <Input
            fluid
            value={filter}
            placeholder="Filter..."
            onChange={(value) => setFilter(value)}
          />
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={showAll}
            tooltip="Show stickers even if they don't suggest this slot"
            onClick={() => setShowAll(!showAll)}
          >
            All
          </Button.Checkbox>
        </Stack.Item>
      </Stack>
      {!canAdd && (
        <NoticeBox danger>
          Slot or global entry cap reached. Remove an entry to add a new one.
        </NoticeBox>
      )}
      <Box
        style={{
          maxHeight: '180px',
          overflowY: 'auto',
          border: '1px solid rgba(255, 255, 255, 0.08)',
          padding: '4px',
        }}
      >
        {filtered.length === 0 && (
          <Box opacity={0.55} italic>
            No matching stickers.
          </Box>
        )}
        {filtered.map((id) => {
          const info = stickerRegistry[id];
          return (
            <Button
              key={id}
              fluid
              disabled={!canAdd}
              onClick={() => onAdd(id)}
              tooltip={`${id}${info.has_gem ? ' (has gem)' : ''}`}
            >
              {info.name}
            </Button>
          );
        })}
      </Box>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Per-entry detail (sticker swap, colors, zone, name/desc)
// ---------------------------------------------------------------------------

function EntryDetail(props: {
  activeEntryData: PiercingEntry | null;
  stickerRegistry: Record<string, StickerInfo>;
  entryZones: string[];
  entryZoneLabels: Record<string, string>;
  maxNameLength: number;
  maxDescLength: number;
  defaultMetalColor: string;
  defaultGemColor: string;
  onPatch: (patch: Partial<PiercingEntry>) => void;
}) {
  const {
    activeEntryData,
    stickerRegistry,
    entryZones,
    entryZoneLabels,
    maxNameLength,
    maxDescLength,
    defaultMetalColor,
    defaultGemColor,
    onPatch,
  } = props;

  if (!activeEntryData) {
    return (
      <Section title="Entry Detail">
        <Box opacity={0.55} italic>
          Select an entry to edit.
        </Box>
      </Section>
    );
  }

  const info = stickerRegistry[activeEntryData.sticker];
  const hasGem = !!info?.has_gem;
  const metalColor = activeEntryData.metal_color || defaultMetalColor;
  const gemColor = activeEntryData.gem_color || defaultGemColor;

  const zoneOptions = entryZones.map(
    (z) => entryZoneLabels[z] ?? (z || 'Always'),
  );
  const currentZoneLabel =
    entryZoneLabels[activeEntryData.zone ?? ''] ??
    activeEntryData.zone ??
    'Always';

  return (
    <Section title={`Entry: ${info?.name ?? activeEntryData.sticker}`}>
      <LabeledList>
        <LabeledList.Item label="Metal">
          <input
            type="color"
            value={metalColor}
            onChange={(e) => onPatch({ metal_color: e.target.value })}
            style={{ width: '48px', height: '24px', padding: 0 }}
          />
          <span style={{ marginLeft: '6px', opacity: 0.6 }}>{metalColor}</span>
        </LabeledList.Item>
        {hasGem && (
          <LabeledList.Item label="Gem">
            <input
              type="color"
              value={gemColor}
              onChange={(e) => onPatch({ gem_color: e.target.value })}
              style={{ width: '48px', height: '24px', padding: 0 }}
            />
            <span style={{ marginLeft: '6px', opacity: 0.6 }}>{gemColor}</span>
          </LabeledList.Item>
        )}
        <LabeledList.Item label="Hide when covered">
          <Button.Checkbox
            checked={!!activeEntryData.hide_when_covered}
            onClick={() =>
              onPatch({
                hide_when_covered: activeEntryData.hide_when_covered ? 0 : 1,
              })
            }
          >
            {activeEntryData.hide_when_covered ? 'Yes' : 'No'}
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Zone">
          <Dropdown
            width="180px"
            selected={currentZoneLabel}
            options={zoneOptions}
            onSelected={(value) => {
              const idx = zoneOptions.indexOf(value);
              const zone = idx >= 0 ? entryZones[idx] : '';
              onPatch({ zone });
            }}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Custom name">
          <Input
            width="220px"
            value={activeEntryData.custom_name}
            maxLength={maxNameLength}
            placeholder={info?.name ?? ''}
            onChange={(value) => onPatch({ custom_name: value })}
          />
        </LabeledList.Item>
        <LabeledList.Item label="Description">
          <TextArea
            width="220px"
            height="60px"
            value={activeEntryData.custom_desc}
            maxLength={maxDescLength}
            onChange={(value) => onPatch({ custom_desc: value })}
          />
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Props editor (per-direction offsets, reused for entry + slot)
// ---------------------------------------------------------------------------

function SelectedEntryHybridControls(props: {
  descriptor: HybridGuideDescriptor | null;
  draftProps: OffsetTransformProps;
  direction: DirKey;
  dirKeys: DirKey[];
  hasEntry: boolean;
  onDirectionChange: (dir: DirKey) => void;
  onDraftChange: (nextDraft: OffsetTransformProps) => void;
  onCopyToAll: (nextDrafts: DirectionalOffsetProps) => void;
  onEditSlotProps: () => void;
  offsetMin: number;
  offsetMax: number;
}) {
  const {
    descriptor,
    draftProps,
    direction,
    dirKeys,
    hasEntry,
    onDirectionChange,
    onDraftChange,
    onCopyToAll,
    onEditSlotProps,
    offsetMin,
    offsetMax,
  } = props;

  if (!hasEntry) {
    return null;
  }

  return (
    <Section
      title={`Entry Offsets - ${DIR_LABELS[direction]}`}
      buttons={
        <Button.Checkbox
          checked={false}
          tooltip="Edit slot-wide offsets instead of the selected entry"
          onClick={onEditSlotProps}
        >
          Slot
        </Button.Checkbox>
      }
    >
      <HybridOffsetControls
        descriptor={descriptor}
        draftProps={draftProps}
        direction={direction}
        dirKeys={dirKeys}
        onDirectionChange={onDirectionChange}
        onDraftChange={onDraftChange}
        onCopyToAll={onCopyToAll}
        offsetMin={offsetMin}
        offsetMax={offsetMax}
        turnMin={TURN_MIN}
        turnMax={TURN_MAX}
        shrinkMin={SHRINK_MIN}
        shrinkMax={SHRINK_MAX}
      />
    </Section>
  );
}

function PropsEditor(props: {
  editingSlotProps: boolean;
  setEditingSlotProps: (v: boolean) => void;
  hasEntry: boolean;
  dirLabel: string;
  propVal: (field: FieldKey, fb?: number) => number;
  setPropField: (field: FieldKey, raw: number | boolean) => void;
  togglePropField: (field: FieldKey) => void;
  resetCurrentDir: () => void;
  resetAllDirs: () => void;
  offsetMin: number;
  offsetMax: number;
}) {
  const {
    editingSlotProps,
    setEditingSlotProps,
    hasEntry,
    dirLabel,
    propVal,
    setPropField,
    togglePropField,
    resetCurrentDir,
    resetAllDirs,
    offsetMin,
    offsetMax,
  } = props;

  if (!editingSlotProps && !hasEntry) {
    return null;
  }

  const title = editingSlotProps
    ? `Slot Offsets - ${dirLabel}`
    : `Entry Offsets - ${dirLabel}`;

  return (
    <Section
      title={title}
      buttons={
        <>
          <Button.Checkbox
            checked={editingSlotProps}
            tooltip="Edit slot-wide offsets instead of the selected entry"
            onClick={() => setEditingSlotProps(!editingSlotProps)}
          >
            Slot
          </Button.Checkbox>
          <Button
            icon="undo"
            compact
            tooltip="Reset this direction to defaults"
            onClick={resetCurrentDir}
          >
            Dir
          </Button>
          <Button
            icon="undo-alt"
            color="bad"
            compact
            tooltip="Reset all directions to defaults"
            onClick={resetAllDirs}
          >
            All
          </Button>
        </>
      }
    >
      <LabeledList>
        <LabeledList.Item label="Offset X">
          <NumberInput
            width="60px"
            step={1}
            stepPixelSize={4}
            value={propVal('x')}
            minValue={offsetMin}
            maxValue={offsetMax}
            onChange={(v) => setPropField('x', v)}
          />
          <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
        </LabeledList.Item>
        <LabeledList.Item label="Offset Y">
          <NumberInput
            width="60px"
            step={1}
            stepPixelSize={4}
            value={propVal('y')}
            minValue={offsetMin}
            maxValue={offsetMax}
            onChange={(v) => setPropField('y', v)}
          />
          <span style={{ opacity: 0.4, marginLeft: '6px' }}>px</span>
        </LabeledList.Item>
        <LabeledList.Item label="Rotation">
          <NumberInput
            width="60px"
            step={5}
            stepPixelSize={4}
            value={propVal('turn')}
            minValue={TURN_MIN}
            maxValue={TURN_MAX}
            onChange={(v) => setPropField('turn', v)}
          />
          <span style={{ opacity: 0.4, marginLeft: '6px' }}>deg</span>
        </LabeledList.Item>
        <LabeledList.Item label="Scale">
          <NumberInput
            width="70px"
            step={0.05}
            stepPixelSize={4}
            value={propVal('shrink', 1.0)}
            minValue={SHRINK_MIN}
            maxValue={SHRINK_MAX}
            onChange={(v) => setPropField('shrink', v)}
          />
          <span style={{ opacity: 0.4, marginLeft: '6px' }}>x</span>
        </LabeledList.Item>
        <LabeledList.Item label="Horizontal Flip">
          <Button.Checkbox
            checked={!!propVal('flip')}
            onClick={() => togglePropField('flip')}
          >
            {propVal('flip') ? 'Flipped' : 'Normal'}
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Layer">
          <Button.Checkbox
            checked={!!propVal('above')}
            onClick={() => togglePropField('above')}
          >
            {propVal('above') ? 'Over Body' : 'Under Body'}
          </Button.Checkbox>
        </LabeledList.Item>
        <LabeledList.Item label="Hide">
          <Button.Checkbox
            checked={!!propVal('hide')}
            color={propVal('hide') ? 'bad' : undefined}
            onClick={() => togglePropField('hide')}
          >
            {propVal('hide') ? 'Hidden this direction' : 'Visible'}
          </Button.Checkbox>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
}

// ---------------------------------------------------------------------------
// Preview pane
// ---------------------------------------------------------------------------

/**
 * Behind-the-accessory character mannequin layer. Renders the server-built
 * base64 PNG for the current direction centered under the accessory tile
 * so players can judge alignment against their actual body. Missing or
 * failing directions (e.g. lobby previews where `update_preview_icon`
 * short-circuits) simply render nothing -- the checkerboard remains
 * visible and the accessory still composites above it.
 */
function MannequinBackdrop(props: {
  mannequinPreviews?: Partial<Record<DirKey, string>>;
  direction: DirKey;
}) {
  const { mannequinPreviews, direction } = props;
  const b64 = mannequinPreviews?.[direction];
  if (!b64) return null;
  const style: CSSProperties = {
    position: 'absolute',
    left: '50%',
    top: '50%',
    // Match the accessory tile footprint so the body and accessory share
    // the same 32x32 logical coordinate system. `imageRendering: pixelated`
    // keeps the DMI aesthetic at PREVIEW_SCALE zoom.
    width: `${PREVIEW_TILE_PX}px`,
    height: `${PREVIEW_TILE_PX}px`,
    marginLeft: `${-PREVIEW_TILE_PX / 2}px`,
    marginTop: `${-PREVIEW_TILE_PX / 2}px`,
    backgroundImage: `url(data:image/png;base64,${b64})`,
    backgroundRepeat: 'no-repeat',
    backgroundPosition: 'center',
    backgroundSize: 'contain',
    imageRendering: 'pixelated',
    pointerEvents: 'none',
  };
  return <div style={style} aria-hidden />;
}

function SelectedEntryPreview(props: {
  loading: boolean;
  error: Error | null;
  manifest: AppearancePreviewManifestV2 | null;
  cfg: SlotConfig | null;
  entry: PiercingEntry | null;
  descriptor: HybridGuideDescriptor | null;
  draftProps: OffsetTransformProps;
  onDraftChange: (nextDraft: OffsetTransformProps) => void;
  direction: DirKey;
  mannequinPreviews?: Partial<Record<DirKey, string>>;
}) {
  const {
    loading,
    error,
    manifest,
    cfg,
    entry,
    descriptor,
    draftProps,
    onDraftChange,
    direction,
    mannequinPreviews,
  } = props;

  const frameStyle = {
    position: 'relative' as const,
    width: `${PREVIEW_FRAME_PX}px`,
    height: `${PREVIEW_FRAME_PX}px`,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    background:
      'repeating-conic-gradient(#222 0 25%, #2a2a2a 0 50%) 50% / 16px 16px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
  };

  if (loading || !manifest) {
    return (
      <Box style={frameStyle}>
        <Box opacity={0.65} italic>
          Loading preview assets...
        </Box>
      </Box>
    );
  }
  if (error) {
    return (
      <Box style={frameStyle}>
        <Box color="bad" italic>
          {error.message}
        </Box>
      </Box>
    );
  }
  if (!cfg || !cfg.enabled || !cfg.entries.length) {
    return (
      <Box style={frameStyle}>
        <Box opacity={0.55} italic>
          {cfg?.entries?.length ? 'Slot disabled.' : 'No entries in this slot.'}
        </Box>
      </Box>
    );
  }

  if (!entry) {
    return (
      <Box style={frameStyle}>
        <Box opacity={0.55} italic>
          Select an entry to edit its placement.
        </Box>
      </Box>
    );
  }

  return (
    <HybridOffsetOverlay
      manifest={manifest}
      descriptor={descriptor}
      direction={direction}
      draftProps={draftProps}
      onDraftChange={onDraftChange}
      mapView={
        <Box style={frameStyle}>
          <MannequinBackdrop
            mannequinPreviews={mannequinPreviews}
            direction={direction}
          />
        </Box>
      }
      previewWidth={PREVIEW_FRAME_PX}
      previewHeight={PREVIEW_FRAME_PX}
      guideScale={PREVIEW_SCALE}
      dragPixelRatio={PREVIEW_SCALE}
      transformPixelRatio={PREVIEW_SCALE}
    />
  );
}

// ---------------------------------------------------------------------------
// Import / Export modal
// ---------------------------------------------------------------------------

function ImportExportModal(props: {
  exportPayload: string | null;
  importStatus: string | null;
  importText: string;
  onImportTextChange: (v: string) => void;
  onImport: () => void;
  onClose: () => void;
}) {
  const {
    exportPayload,
    importStatus,
    importText,
    onImportTextChange,
    onImport,
    onClose,
  } = props;

  // Transient copy-to-clipboard status. Announced via the modal's
  // aria-live region so screen readers hear success/failure without a
  // focus shift. Cleared on a short timer so the modal doesn't show a
  // stale "Copied" message after the user moves on.
  const [copyStatus, setCopyStatus] = useState<string | null>(null);
  const [copyStatusTone, setCopyStatusTone] = useState<
    'good' | 'bad' | 'neutral'
  >('neutral');

  const onCopy = useCallback(async () => {
    if (!exportPayload) return;
    const ok = await copyTextToClipboard(exportPayload);
    if (ok) {
      setCopyStatus('Copied to clipboard.');
      setCopyStatusTone('good');
    } else {
      setCopyStatus('Copy failed — select the text manually and use Ctrl+C.');
      setCopyStatusTone('bad');
    }
  }, [exportPayload]);

  // The modal surfaces either the copy status (short-lived, local) or
  // the import status (server-sourced). Copy status takes precedence
  // because it's the most-recent interaction.
  const liveStatus = copyStatus ?? importStatus;
  const liveStatusTone: 'good' | 'bad' | 'neutral' = copyStatus
    ? copyStatusTone
    : importStatus
      ? importStatus.startsWith('error')
        ? 'bad'
        : 'good'
      : 'neutral';

  return (
    <ModalDialog
      open
      onClose={onClose}
      title="Import / Export Freeform Stickers"
      status={liveStatus}
      statusTone={liveStatusTone}
    >
      {exportPayload && (
        <>
          <Box
            mb={0.5}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              gap: '0.5rem',
            }}
          >
            <Box opacity={0.7} fontSize="11px">
              Copy this JSON to save your current draft.
            </Box>
            <Button
              icon="copy"
              onClick={onCopy}
              tooltip="Copy export payload to clipboard"
            >
              Copy
            </Button>
          </Box>
          {/* tgui-core's <TextArea> has no readOnly prop. Use a plain
              native textarea for the export-copy affordance — read-only
              display of a JSON payload doesn't need the Input plumbing. */}
          <textarea
            readOnly
            aria-label="Export payload"
            style={{
              width: '100%',
              height: '140px',
              fontFamily: 'monospace',
              fontSize: '11px',
            }}
            value={exportPayload}
          />
        </>
      )}
      <Box mt={1} opacity={0.7} fontSize="11px">
        Paste a JSON payload and press Import to replace your freeform draft
        with its contents.
      </Box>
      <TextArea
        width="100%"
        height="140px"
        value={importText}
        onChange={(value) => onImportTextChange(value)}
      />
      <Box mt={0.5}>
        <Button
          icon="file-import"
          disabled={!importText.trim()}
          onClick={onImport}
        >
          Import
        </Button>
      </Box>
    </ModalDialog>
  );
}

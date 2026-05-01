/**
 * @file CustomPiercingEditorLogic.ts
 * @description Pure adapter logic for the custom piercing editor.
 *
 * The custom piercing save payload stores one flat props map per sticker
 * entry, keyed by direction + field (`sx`, `wturn`, and so on). The shared
 * hybrid overlay edits a single `OffsetTransformProps` object for the active
 * direction. This module owns that conversion and the lookup of server-owned
 * guide descriptors so the React surface does not compose runtime icon-state
 * names locally.
 */

import type {
  AppearancePreviewV2DirectionKey,
  DirectionalOffsetProps,
  HybridGuideDescriptor,
  HybridGuideLayer,
  OffsetTransformProps,
} from '../components/appearance-preview';

export type DirKey = AppearancePreviewV2DirectionKey;
export type FieldKey =
  | 'x'
  | 'y'
  | 'turn'
  | 'flip'
  | 'above'
  | 'hide'
  | 'shrink';

/** Per-entry custom piercing props keyed `<dir><field>`, such as `sx`. */
export type CustomPiercingPropMap = Record<string, number>;

/** Minimal selected-entry shape needed by the hybrid descriptor adapter. */
export interface CustomPiercingEntryLike {
  sticker: string;
  metal_color?: string | null;
  gem_color?: string | null;
  custom_name?: string | null;
  custom_desc?: string | null;
  zone?: string | null;
  hide_when_covered?: number | boolean | null;
  props?: CustomPiercingPropMap | null;
}

/** Minimal custom-piercing slot shape accepted by save/drag adapters. */
export interface CustomPiercingSlotLike {
  enabled?: number | boolean | null;
  suppress_legacy?: number | boolean | null;
  display_name?: string | null;
  hide_from_examine?: number | boolean | null;
  entries?: readonly CustomPiercingEntryLike[] | null;
  slot_props?: CustomPiercingPropMap | null;
  equipped_typepath?: string | null;
}

/** Sanitized entry shape emitted in the custom piercing save snapshot. */
export interface CustomPiercingCommitEntry {
  sticker: string;
  metal_color: string;
  gem_color: string | null;
  custom_name: string;
  custom_desc: string;
  zone: string;
  hide_when_covered: 0 | 1;
  props: CustomPiercingPropMap;
}

/** Sanitized slot shape emitted in the custom piercing save snapshot. */
export interface CustomPiercingCommitSlot {
  enabled: 0 | 1;
  suppress_legacy: 0 | 1;
  display_name: string;
  hide_from_examine: 0 | 1;
  entries: CustomPiercingCommitEntry[];
  slot_props: CustomPiercingPropMap;
  equipped_typepath?: string | null;
}

/** Commit snapshot shape consumed by the shared appearance-preview controller. */
export interface CustomPiercingCommitSnapshot {
  custom_piercings: Record<string, CustomPiercingCommitSlot>;
  regular_slots: Record<string, string>;
}

/** Sticker registry fields used for unsaved-entry preview descriptors. */
export interface CustomPiercingStickerHybridInfo {
  id?: string;
  name?: string;
  manifest_category?: string | null;
  hybrid_layers?: readonly HybridGuideLayer[] | null;
}

/** Server descriptor grid emitted as slot -> 1-based entry index -> direction. */
export type CustomPiercingHybridDescriptorMap = Record<
  string,
  Record<string, Partial<Record<DirKey, HybridGuideDescriptor | null>>>
>;

/** Arguments for resolving the active selected-entry guide descriptor. */
export interface CustomPiercingDescriptorLookupArgs {
  descriptors: CustomPiercingHybridDescriptorMap | null | undefined;
  stickerRegistry: Record<string, CustomPiercingStickerHybridInfo | undefined>;
  slotKey: string;
  /** Zero-based UI entry index. DM target keys stay one-based. */
  entryIndex: number;
  direction: DirKey;
  entry: CustomPiercingEntryLike | null | undefined;
  defaultMetalColor: string;
  defaultGemColor: string;
}

/** Client feedback clamps mirrored from the DM sanitizer. */
export const TURN_MIN = -359;
export const TURN_MAX = 359;
export const SHRINK_MIN = 0.1;
export const SHRINK_MAX = 4.0;

const DEFAULT_NATIVE_SIZE = 32;
const CUSTOM_PIERCING_FAMILY = 'custom_piercings';
const DEFAULT_MANIFEST_CATEGORY = 'sticker';
const CUSTOM_PIERCING_ALLOWED_FIELDS = [
  'x',
  'y',
  'turn',
  'flip',
  'hide',
  'shrink',
  'above',
] as const;
const CUSTOM_PIERCING_DIRECTIONS: readonly DirKey[] = ['s', 'n', 'e', 'w'];
const CUSTOM_PIERCING_PROP_FIELDS: readonly FieldKey[] = [
  'x',
  'y',
  'turn',
  'flip',
  'above',
  'hide',
  'shrink',
];

const clamp = (value: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, value));

const toFlag = (value: number | boolean | null | undefined): 0 | 1 =>
  typeof value === 'boolean' || typeof value === 'number' ? (value ? 1 : 0) : 0;

const textOrEmpty = (value: string | null | undefined): string =>
  typeof value === 'string' ? value : '';

/**
 * Copies only the known directional prop fields into a commit payload.
 *
 * TGUI is not the security boundary, but stripping unknown keys here prevents
 * editor-only data such as descriptor caches or future drawing experiments
 * from being accidentally included in the single save snapshot.
 */
function cloneCustomPiercingPropsForCommit(
  props: CustomPiercingPropMap | null | undefined,
): CustomPiercingPropMap {
  const out: CustomPiercingPropMap = {};
  if (!props) {
    return out;
  }
  for (const direction of CUSTOM_PIERCING_DIRECTIONS) {
    for (const field of CUSTOM_PIERCING_PROP_FIELDS) {
      const key = `${direction}${field}`;
      const value = props[key];
      if (typeof value === 'number' && Number.isFinite(value)) {
        out[key] = value;
      }
    }
  }
  return out;
}

/** Copies one selected entry into the bounded save-snapshot shape. */
function cloneCustomPiercingEntryForCommit(
  entry: CustomPiercingEntryLike | null | undefined,
): CustomPiercingCommitEntry | null {
  if (!entry || typeof entry.sticker !== 'string' || !entry.sticker.length) {
    return null;
  }
  return {
    sticker: entry.sticker,
    metal_color: textOrEmpty(entry.metal_color),
    gem_color: typeof entry.gem_color === 'string' ? entry.gem_color : null,
    custom_name: textOrEmpty(entry.custom_name),
    custom_desc: textOrEmpty(entry.custom_desc),
    zone: textOrEmpty(entry.zone),
    hide_when_covered: toFlag(entry.hide_when_covered),
    props: cloneCustomPiercingPropsForCommit(entry.props),
  };
}

/** Copies one freeform slot into the bounded save-snapshot shape. */
function cloneCustomPiercingSlotForCommit(
  slot: CustomPiercingSlotLike | null | undefined,
): CustomPiercingCommitSlot | null {
  if (!slot) {
    return null;
  }
  const entries: CustomPiercingCommitEntry[] = [];
  for (const entry of slot.entries ?? []) {
    const nextEntry = cloneCustomPiercingEntryForCommit(entry);
    if (nextEntry) {
      entries.push(nextEntry);
    }
  }
  const out: CustomPiercingCommitSlot = {
    enabled: toFlag(slot.enabled),
    suppress_legacy: toFlag(slot.suppress_legacy),
    display_name: textOrEmpty(slot.display_name),
    hide_from_examine: toFlag(slot.hide_from_examine),
    entries,
    slot_props: cloneCustomPiercingPropsForCommit(slot.slot_props),
  };
  if (typeof slot.equipped_typepath === 'string') {
    out.equipped_typepath = slot.equipped_typepath;
  }
  return out;
}

/**
 * Converts a zero-based UI entry index into the DM descriptor target key.
 *
 * The server contract intentionally uses one-based entry indexes so target
 * keys align with BYOND list semantics. Invalid inputs return null so callers
 * can fall back to a map-only preview.
 */
export function customPiercingTargetKey(
  slotKey: string,
  entryIndex: number,
): string | null {
  if (!slotKey || entryIndex < 0 || !Number.isFinite(entryIndex)) {
    return null;
  }
  return `${slotKey}:${Math.floor(entryIndex) + 1}`;
}

/** Reads a finite numeric field from a flat custom piercing props map. */
function readCustomPiercingProp(
  props: CustomPiercingPropMap | null | undefined,
  dir: DirKey,
  field: FieldKey,
  fallback = 0,
): number {
  const value = props?.[`${dir}${field}`];
  return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

/** Applies one clamped/coerced field write to a custom piercing props map. */
export function applyCustomPiercingField(
  props: CustomPiercingPropMap,
  dir: DirKey,
  field: FieldKey,
  raw: number | boolean,
  offsetMin: number,
  offsetMax: number,
): CustomPiercingPropMap {
  const out = { ...props };
  const key = `${dir}${field}`;
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
      const value = Number(raw);
      out[key] = clamp(
        Number.isFinite(value) ? value : 1,
        SHRINK_MIN,
        SHRINK_MAX,
      );
      break;
    }
  }
  return out;
}

/**
 * Converts an entry's flat props map into the shared overlay draft shape for
 * one active direction.
 */
export function customPiercingPropsToHybridDraft(
  props: CustomPiercingPropMap | null | undefined,
  dir: DirKey,
): OffsetTransformProps {
  return {
    x: readCustomPiercingProp(props, dir, 'x'),
    y: readCustomPiercingProp(props, dir, 'y'),
    turn: readCustomPiercingProp(props, dir, 'turn'),
    flip: !!readCustomPiercingProp(props, dir, 'flip'),
    above: !!readCustomPiercingProp(props, dir, 'above'),
    hide: !!readCustomPiercingProp(props, dir, 'hide'),
    shrink: readCustomPiercingProp(props, dir, 'shrink', 1),
  };
}

/**
 * Combines entry-local and slot-wide props into the visual guide transform.
 *
 * The custom piercing renderer applies slot props around every entry in the
 * slot. The selected-entry overlay should show that final combined placement,
 * while drag writes still target only the selected entry.
 */
export function combineCustomPiercingHybridDraft(
  entryProps: CustomPiercingPropMap | null | undefined,
  slotProps: CustomPiercingPropMap | null | undefined,
  dir: DirKey,
): OffsetTransformProps {
  const entry = customPiercingPropsToHybridDraft(entryProps, dir);
  const slot = customPiercingPropsToHybridDraft(slotProps, dir);
  return {
    x: entry.x + slot.x,
    y: entry.y + slot.y,
    turn: entry.turn + slot.turn,
    flip: entry.flip !== slot.flip,
    above: !!entry.above || !!slot.above,
    hide: entry.hide || slot.hide,
    shrink: entry.shrink * slot.shrink,
  };
}

/**
 * Writes a shared overlay draft back into the existing flat props map.
 *
 * The commit payload remains unchanged: only the adapter surface changes from
 * local sheet composition to the shared hybrid overlay contract.
 */
export function applyCustomPiercingHybridDraftToProps(
  props: CustomPiercingPropMap,
  dir: DirKey,
  draft: OffsetTransformProps,
  offsetMin: number,
  offsetMax: number,
): CustomPiercingPropMap {
  let next = applyCustomPiercingField(
    props,
    dir,
    'x',
    draft.x,
    offsetMin,
    offsetMax,
  );
  next = applyCustomPiercingField(
    next,
    dir,
    'y',
    draft.y,
    offsetMin,
    offsetMax,
  );
  next = applyCustomPiercingField(
    next,
    dir,
    'turn',
    draft.turn,
    offsetMin,
    offsetMax,
  );
  next = applyCustomPiercingField(
    next,
    dir,
    'flip',
    draft.flip,
    offsetMin,
    offsetMax,
  );
  next = applyCustomPiercingField(
    next,
    dir,
    'above',
    !!draft.above,
    offsetMin,
    offsetMax,
  );
  next = applyCustomPiercingField(
    next,
    dir,
    'hide',
    draft.hide,
    offsetMin,
    offsetMax,
  );
  return applyCustomPiercingField(
    next,
    dir,
    'shrink',
    draft.shrink,
    offsetMin,
    offsetMax,
  );
}

/**
 * Writes a combined visual guide draft back to entry-local props.
 *
 * Dragging the guide should preserve the current slot-wide transform and only
 * move the selected entry. Numeric fields therefore subtract the slot draft;
 * booleans are converted back to entry-local values as far as the combined
 * transform model allows.
 */
export function applyCombinedCustomPiercingHybridDraftToEntryProps(
  entryProps: CustomPiercingPropMap,
  slotProps: CustomPiercingPropMap | null | undefined,
  dir: DirKey,
  draft: OffsetTransformProps,
  offsetMin: number,
  offsetMax: number,
): CustomPiercingPropMap {
  const slot = customPiercingPropsToHybridDraft(slotProps, dir);
  const entryDraft: OffsetTransformProps = {
    x: draft.x - slot.x,
    y: draft.y - slot.y,
    turn: draft.turn - slot.turn,
    flip: draft.flip !== slot.flip,
    above: !!draft.above && !slot.above,
    hide: draft.hide && !slot.hide,
    shrink: slot.shrink ? draft.shrink / slot.shrink : draft.shrink,
  };
  return applyCustomPiercingHybridDraftToProps(
    entryProps,
    dir,
    entryDraft,
    offsetMin,
    offsetMax,
  );
}

/**
 * Applies one dragged guide transform to the selected entry inside a freeform
 * slot map.
 *
 * The helper returns a new map/slot/entry only for a valid selected entry. It
 * intentionally preserves sibling entries and slot-wide props by reference so
 * tests can catch accidental broad writes during drag.
 */
export function applySelectedCustomPiercingGuideDraftToFreeform<
  TSlot extends CustomPiercingSlotLike,
>(
  freeform: Record<string, TSlot>,
  slotKey: string,
  entryIndex: number,
  direction: DirKey,
  draft: OffsetTransformProps,
  offsetMin: number,
  offsetMax: number,
): Record<string, TSlot> {
  const slot = freeform[slotKey];
  if (!slot?.entries?.[entryIndex]) {
    return freeform;
  }
  const entry = slot.entries[entryIndex];
  const nextEntries = slot.entries.slice();
  nextEntries[entryIndex] = {
    ...entry,
    props: applyCombinedCustomPiercingHybridDraftToEntryProps(
      entry.props ?? {},
      slot.slot_props,
      direction,
      draft,
      offsetMin,
      offsetMax,
    ),
  };
  return {
    ...freeform,
    [slotKey]: {
      ...slot,
      entries: nextEntries,
    } as TSlot,
  };
}

/** Writes a full directional draft map back into a flat entry props map. */
export function applyCustomPiercingDirectionalDraftsToProps(
  props: CustomPiercingPropMap,
  drafts: DirectionalOffsetProps,
  offsetMin: number,
  offsetMax: number,
): CustomPiercingPropMap {
  let next = { ...props };
  for (const direction of Object.keys(drafts) as DirKey[]) {
    next = applyCustomPiercingHybridDraftToProps(
      next,
      direction,
      drafts[direction],
      offsetMin,
      offsetMax,
    );
  }
  return next;
}

/**
 * Builds the exact client-side save snapshot for the custom piercing editor.
 *
 * The server remains authoritative and re-sanitizes every field, but this
 * adapter keeps the single commit payload small and intentionally excludes
 * arbitrary drawing/canvas/descriptor data from normal sticker saves.
 */
export function buildCustomPiercingCommitSnapshot(
  freeform: Record<string, CustomPiercingSlotLike>,
  regularSelections: Record<string, string>,
): CustomPiercingCommitSnapshot {
  const customPiercings: Record<string, CustomPiercingCommitSlot> = {};
  for (const [slotKey, slot] of Object.entries(freeform)) {
    const nextSlot = cloneCustomPiercingSlotForCommit(slot);
    if (nextSlot) {
      customPiercings[slotKey] = nextSlot;
    }
  }
  return {
    custom_piercings: customPiercings,
    regular_slots: { ...regularSelections },
  };
}

/** Adds the currently selected entry colors to server or registry layers. */
function applyEntryColorsToDescriptor(
  descriptor: HybridGuideDescriptor,
  entry: CustomPiercingEntryLike,
  defaultMetalColor: string,
  defaultGemColor: string,
): HybridGuideDescriptor {
  const metalColor = entry.metal_color || defaultMetalColor;
  const gemColor = entry.gem_color || defaultGemColor;
  return {
    ...descriptor,
    layers: descriptor.layers.map((layer) => {
      if (layer.role === 'metal') {
        return { ...layer, color: metalColor };
      }
      if (layer.role === 'gem') {
        return { ...layer, color: gemColor };
      }
      return { ...layer };
    }),
  };
}

/** Builds a descriptor for unsaved entries from server-provided registry metadata. */
function buildRegistryDescriptor(
  args: CustomPiercingDescriptorLookupArgs,
): HybridGuideDescriptor | null {
  const { stickerRegistry, slotKey, entryIndex, direction, entry } = args;
  if (!entry) {
    return null;
  }
  const targetKey = customPiercingTargetKey(slotKey, entryIndex);
  if (!targetKey) {
    return null;
  }
  const sticker = stickerRegistry[entry.sticker];
  const layers = sticker?.hybrid_layers?.filter((layer) => !!layer.iconState);
  if (!layers?.length) {
    return null;
  }
  return {
    id: `${targetKey}:${direction}`,
    family: CUSTOM_PIERCING_FAMILY,
    targetKey,
    manifestCategory: sticker?.manifest_category ?? DEFAULT_MANIFEST_CATEGORY,
    direction,
    layers,
    nativeWidth: DEFAULT_NATIVE_SIZE,
    nativeHeight: DEFAULT_NATIVE_SIZE,
    allowedFields: CUSTOM_PIERCING_ALLOWED_FIELDS,
    approximateColor: true,
  };
}

/**
 * Resolves the selected custom piercing guide descriptor.
 *
 * Existing entries prefer the DM-emitted descriptor grid. Newly added local
 * entries fall back to sticker registry `hybrid_layers`, which are also
 * server-owned metadata. TGUI never derives `piercing_<id>_*` state names.
 */
export function getCustomPiercingHybridDescriptor(
  args: CustomPiercingDescriptorLookupArgs,
): HybridGuideDescriptor | null {
  const {
    descriptors,
    slotKey,
    entryIndex,
    direction,
    entry,
    defaultMetalColor,
    defaultGemColor,
  } = args;
  if (!entry) {
    return null;
  }
  const entryKey = String(Math.floor(entryIndex) + 1);
  const descriptor =
    descriptors?.[slotKey]?.[entryKey]?.[direction] ??
    buildRegistryDescriptor(args);
  if (!descriptor) {
    return null;
  }
  return applyEntryColorsToDescriptor(
    descriptor,
    entry,
    defaultMetalColor,
    defaultGemColor,
  );
}

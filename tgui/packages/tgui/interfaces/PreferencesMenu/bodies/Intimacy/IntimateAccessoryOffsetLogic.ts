/**
 * @file IntimateAccessoryOffsetLogic.ts
 * @description Pure adapter helpers for the PreferencesMenu intimate
 * accessory offset entrypoint.
 *
 * Phase one is intentionally constrained to x/y pixel offsets. Some legacy
 * regular accessory paths share the custom-piercing prop sanitizer, but not
 * every base intimate accessory has a proven turn/flip/shrink render path.
 * Keeping the client and DM contract x/y-only lets later descriptor work add
 * advanced transforms deliberately instead of accidentally exposing drift.
 */

import type {
  DirectionalOffsetProps,
  DirectionKey,
  HybridGuideDescriptor,
  HybridOffsetField,
  OffsetTransformProps,
} from '../../../../components/appearance-preview';

/** Stable scope token emitted by DM and consumed by the menu row. */
export type IntimateAccessoryOffsetScope = 'phase_one_xy';

/** Server family id used by intimate accessory offset descriptors. */
export type IntimateAccessoryOffsetFamily = 'intimate_accessory_offsets';

/** The only transform fields enabled during phase one. */
export type IntimateAccessoryPhaseOneField = Extract<
  HybridOffsetField,
  'x' | 'y'
>;

/** Canonical ordered field list for the phase-one editor surface. */
export const INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS = [
  'x',
  'y',
] as const satisfies readonly IntimateAccessoryPhaseOneField[];

/** Direction order shared by props conversion, save snapshots, and controls. */
export const INTIMATE_ACCESSORY_OFFSET_DIRECTIONS = [
  's',
  'n',
  'e',
  'w',
] as const satisfies readonly DirectionKey[];

/** Slot-level prop map keyed like custom-piercing slot props (`sx`, `ny`). */
export type IntimateAccessoryOffsetPropMap = Record<string, number>;

/** Descriptor grid emitted by DM for the currently active intimate target. */
export type IntimateAccessoryHybridDescriptorMap = Record<
  string,
  Partial<Record<DirectionKey, HybridGuideDescriptor | null>>
>;

/** One compact regular-accessory row emitted by the DM preferences datum. */
export interface IntimateAccessoryOffsetRow {
  key: string;
  label: string;
  group: string | null;
  current: string;
  custom_key: string | null;
  offset_target_key: string | null;
  offset_editable: 0 | 1;
  offset_allowed_fields: readonly IntimateAccessoryPhaseOneField[];
  offset_scope: IntimateAccessoryOffsetScope;
  offset_editor_family: IntimateAccessoryOffsetFamily;
  slot_props: IntimateAccessoryOffsetPropMap;
}

/** Lookup set used by normalizers and tests. */
const PHASE_ONE_FIELD_SET = new Set<string>(
  INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS,
);

/** Returns true when a field is part of the phase-one x/y-only contract. */
export function isPhaseOneIntimateAccessoryOffsetField(
  field: unknown,
): field is IntimateAccessoryPhaseOneField {
  return typeof field === 'string' && PHASE_ONE_FIELD_SET.has(field);
}

const textOrNull = (value: unknown): string | null =>
  typeof value === 'string' && value.length ? value : null;

const textOrFallback = (value: unknown, fallback: string): string =>
  typeof value === 'string' && value.length ? value : fallback;

const flag = (value: unknown): 0 | 1 => (value ? 1 : 0);

const clamp = (value: number, lo: number, hi: number): number =>
  Math.max(lo, Math.min(hi, value));

const finiteNumber = (value: unknown, fallback = 0): number =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;

/** Builds the inert full transform shape expected by HybridOffsetOverlay. */
function phaseOneDraft(x = 0, y = 0): OffsetTransformProps {
  return {
    x,
    y,
    turn: 0,
    flip: false,
    hide: false,
    shrink: 1,
    above: undefined,
  };
}

/**
 * Keeps allowed fields ordered by the phase-one contract and strips any
 * advanced fields a stale or forged client might try to smuggle in.
 */
function normalizeAllowedFields(
  fields: unknown,
): readonly IntimateAccessoryPhaseOneField[] {
  if (!Array.isArray(fields)) {
    return INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS;
  }
  const present = new Set(
    fields.filter(isPhaseOneIntimateAccessoryOffsetField),
  );
  const normalized = INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS.filter(
    (field) => present.has(field),
  );
  return normalized.length
    ? normalized
    : INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS;
}

/**
 * Normalizes slot-level props down to the phase-one x/y contract.
 *
 * DM still uses the broader custom-piercing slot-prop schema internally, but
 * the regular intimate accessory surface must not expose advanced transforms
 * until the renderer supports them uniformly. Unknown and advanced keys are
 * dropped client-side and re-sanitized server-side on save.
 */
export function normalizeIntimateAccessoryOffsetProps(
  props: unknown,
): IntimateAccessoryOffsetPropMap {
  const out: IntimateAccessoryOffsetPropMap = {};
  if (!props || typeof props !== 'object') {
    return out;
  }
  const raw = props as Record<string, unknown>;
  for (const direction of INTIMATE_ACCESSORY_OFFSET_DIRECTIONS) {
    for (const field of INTIMATE_ACCESSORY_PHASE_ONE_ALLOWED_FIELDS) {
      const key = `${direction}${field}`;
      const value = raw[key];
      if (typeof value === 'number' && Number.isFinite(value)) {
        out[key] = value;
      }
    }
  }
  return out;
}

/**
 * Converts one untrusted server row into a stable UI row.
 *
 * DM is the authority, but the client still normalizes defensively so the row
 * surface cannot accidentally expose future transform fields before the shared
 * descriptor editor supports them.
 */
function normalizeRow(row: unknown): IntimateAccessoryOffsetRow | null {
  if (!row || typeof row !== 'object') {
    return null;
  }
  const raw = row as Record<string, unknown>;
  const key = textOrNull(raw.key);
  const label = textOrNull(raw.label);
  if (!key || !label) {
    return null;
  }
  const customKey = textOrNull(raw.custom_key);
  const targetKey = textOrNull(raw.offset_target_key) ?? customKey;
  const editable = flag(raw.offset_editable) && targetKey ? 1 : 0;

  return {
    key,
    label,
    group: textOrNull(raw.group),
    current: textOrFallback(raw.current, 'None'),
    custom_key: customKey,
    offset_target_key: targetKey,
    offset_editable: editable,
    offset_allowed_fields: normalizeAllowedFields(raw.offset_allowed_fields),
    offset_scope: 'phase_one_xy',
    offset_editor_family: 'intimate_accessory_offsets',
    slot_props: normalizeIntimateAccessoryOffsetProps(raw.slot_props),
  };
}

/** Normalizes the complete optional DM row payload. */
export function normalizeIntimateAccessoryOffsetRows(
  rows: unknown,
): IntimateAccessoryOffsetRow[] {
  if (!Array.isArray(rows)) {
    return [];
  }
  const normalized: IntimateAccessoryOffsetRow[] = [];
  for (const row of rows) {
    const next = normalizeRow(row);
    if (next) {
      normalized.push(next);
    }
  }
  return normalized;
}

/** Returns rows that can actually launch an offset target. */
export function getEditableIntimateAccessoryOffsetRows(
  rows: readonly IntimateAccessoryOffsetRow[],
): IntimateAccessoryOffsetRow[] {
  return rows.filter((row) => row.offset_editable && row.offset_target_key);
}

/** Groups rows by the server-provided region key while preserving row order. */
export function groupIntimateAccessoryOffsetRows(
  rows: readonly IntimateAccessoryOffsetRow[],
): Record<string, IntimateAccessoryOffsetRow[]> {
  const grouped: Record<string, IntimateAccessoryOffsetRow[]> = {};
  for (const row of rows) {
    const group = row.group || 'other';
    if (!grouped[group]) {
      grouped[group] = [];
    }
    grouped[group].push(row);
  }
  return grouped;
}

/** Returns the row for one server-owned target key. */
export function findIntimateAccessoryOffsetRow(
  rows: readonly IntimateAccessoryOffsetRow[],
  targetKey: string | null | undefined,
): IntimateAccessoryOffsetRow | null {
  if (!targetKey) {
    return null;
  }
  return rows.find((row) => row.offset_target_key === targetKey) ?? null;
}

/**
 * Chooses a valid active target.
 *
 * Existing server state wins when it still points at an editable target;
 * otherwise the first editable row becomes the compact editor default.
 */
export function getInitialIntimateAccessoryOffsetTarget(
  rows: readonly IntimateAccessoryOffsetRow[],
  requestedTargetKey?: string | null,
): string | null {
  const requested = findIntimateAccessoryOffsetRow(rows, requestedTargetKey);
  if (requested?.offset_target_key && requested.offset_editable) {
    return requested.offset_target_key;
  }
  return (
    getEditableIntimateAccessoryOffsetRows(rows)[0]?.offset_target_key ?? null
  );
}

/** Resolves one server-owned intimate accessory guide descriptor. */
export function getIntimateAccessoryHybridDescriptor(
  descriptors: IntimateAccessoryHybridDescriptorMap | null | undefined,
  targetKey: string | null | undefined,
  direction: DirectionKey,
): HybridGuideDescriptor | null {
  if (!targetKey) {
    return null;
  }
  return descriptors?.[targetKey]?.[direction] ?? null;
}

/** Converts flat x/y props into the shared one-direction draft shape. */
export function intimateAccessoryPropsToHybridDraft(
  props: IntimateAccessoryOffsetPropMap | null | undefined,
  direction: DirectionKey,
): OffsetTransformProps {
  return phaseOneDraft(
    finiteNumber(props?.[`${direction}x`]),
    finiteNumber(props?.[`${direction}y`]),
  );
}

/** Writes one x/y-only draft back into the compact flat prop map. */
export function applyIntimateAccessoryHybridDraftToProps(
  props: IntimateAccessoryOffsetPropMap | null | undefined,
  direction: DirectionKey,
  draft: OffsetTransformProps,
  offsetMin: number,
  offsetMax: number,
): IntimateAccessoryOffsetPropMap {
  const out = normalizeIntimateAccessoryOffsetProps(props);
  out[`${direction}x`] = clamp(
    Math.round(finiteNumber(draft.x)),
    offsetMin,
    offsetMax,
  );
  out[`${direction}y`] = clamp(
    Math.round(finiteNumber(draft.y)),
    offsetMin,
    offsetMax,
  );
  return out;
}

/** Applies all directional x/y drafts to one compact prop map. */
export function applyIntimateAccessoryDirectionalDraftsToProps(
  props: IntimateAccessoryOffsetPropMap | null | undefined,
  drafts: DirectionalOffsetProps,
  offsetMin: number,
  offsetMax: number,
): IntimateAccessoryOffsetPropMap {
  let next = normalizeIntimateAccessoryOffsetProps(props);
  for (const direction of INTIMATE_ACCESSORY_OFFSET_DIRECTIONS) {
    next = applyIntimateAccessoryHybridDraftToProps(
      next,
      direction,
      drafts[direction],
      offsetMin,
      offsetMax,
    );
  }
  return next;
}

/** Builds the smallest save payload accepted by the DM x/y-only sanitizer. */
export function buildIntimateAccessoryOffsetSaveProps(
  props: IntimateAccessoryOffsetPropMap | null | undefined,
): IntimateAccessoryOffsetPropMap {
  return normalizeIntimateAccessoryOffsetProps(props);
}

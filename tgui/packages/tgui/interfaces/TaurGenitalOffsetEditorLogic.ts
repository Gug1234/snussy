/**
 * @file TaurGenitalOffsetEditorLogic.ts
 * @description Pure adapter logic for the taur genital offset editor.
 *
 * The React interface keeps the existing save payload shape: each part stores
 * one flat props map keyed by direction + field (`sx`, `wturn`, and so on).
 * The shared hybrid overlay instead expects a single `OffsetTransformProps`
 * object for the active direction. This module owns that conversion and the
 * lookup of server-resolved `hybrid_descriptors`, so tests can cover the Step
 * 11 migration without importing the full TGUI window/runtime.
 */

import type {
  AppearancePreviewV2DirectionKey,
  HybridGuideDescriptor,
  OffsetTransformProps,
} from '../components/appearance-preview';

export type PartKey = 'penis' | 'testicles' | 'vagina';
export type DirKey = AppearancePreviewV2DirectionKey;
export type FieldKey =
  | 'x'
  | 'y'
  | 'turn'
  | 'flip'
  | 'above'
  | 'hide'
  | 'shrink';

/** Single-part props map, keyed `<dir><field>` (e.g. `sx`, `wturn`). */
export type PartProps = Record<string, number>;

/** Server descriptor map emitted by `/datum/preferences/proc/build_taur_hybrid_offset_descriptor_grid()`. */
export type TaurHybridDescriptorMap = {
  penis?: Record<string, Partial<Record<DirKey, HybridGuideDescriptor | null>>>;
  testicles?: Partial<Record<DirKey, HybridGuideDescriptor | null>>;
  vagina?: Partial<Record<DirKey, HybridGuideDescriptor | null>>;
};

/** Client feedback clamps mirrored from the DM taur sanitizer. */
export const XY_MIN = -64;
export const XY_MAX = 64;
export const TURN_MIN = -359;
export const TURN_MAX = 359;
export const SHRINK_MIN = 0.1;
export const SHRINK_MAX = 4.0;

const DIRECTION_KEYS: readonly DirKey[] = ['s', 'n', 'e', 'w'];

const clamp = (value: number, lo: number, hi: number) =>
  Math.max(lo, Math.min(hi, value));

/** Reads a finite numeric direction field from the legacy props map. */
function readPartProp(
  props: PartProps,
  dir: DirKey,
  field: FieldKey,
  fallback = 0,
): number {
  const value = props[`${dir}${field}`];
  return Number.isFinite(value) ? value : fallback;
}

/** Builds the default props map for one part across all four directions. */
export function defaultPartProps(part: PartKey): PartProps {
  const above = part === 'vagina' ? 1 : 0;
  const out: PartProps = {};
  for (const dir of DIRECTION_KEYS) {
    out[`${dir}x`] = 0;
    out[`${dir}y`] = 0;
    out[`${dir}turn`] = 0;
    out[`${dir}flip`] = 0;
    out[`${dir}above`] = above;
    out[`${dir}hide`] = 0;
    out[`${dir}shrink`] = 1.0;
  }
  return out;
}

/** Applies one field write with the right clamp / coerce for that field. */
export function applyField(
  props: PartProps,
  dir: DirKey,
  field: FieldKey,
  raw: number | boolean,
): PartProps {
  const key = `${dir}${field}`;
  const out = { ...props };
  switch (field) {
    case 'x':
    case 'y':
      out[key] = clamp(Math.round(Number(raw) || 0), XY_MIN, XY_MAX);
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

/**
 * Selects the server-resolved hybrid descriptor for the active taur tab.
 *
 * Penis descriptors are keyed by arousal state then direction because the
 * guide sprite changes between flaccid, partial, and hard states. Testicles
 * and vaginas are single-state and are keyed directly by direction.
 */
export function getActiveTaurHybridDescriptor(
  descriptors: TaurHybridDescriptorMap | null | undefined,
  part: PartKey,
  erectState: number,
  direction: DirKey,
): HybridGuideDescriptor | null {
  if (!descriptors) {
    return null;
  }
  if (part === 'penis') {
    return descriptors.penis?.[String(erectState)]?.[direction] ?? null;
  }
  return descriptors[part]?.[direction] ?? null;
}

/**
 * Converts the editor's existing per-direction props map into the shared
 * overlay draft shape. Global hide is display-only here: it hides the guide
 * in the overlay without changing the per-part commit payload.
 */
export function partPropsToTaurHybridDraft(
  props: PartProps,
  dir: DirKey,
  globalHide?: Partial<Record<DirKey, number>>,
): OffsetTransformProps {
  return {
    x: readPartProp(props, dir, 'x'),
    y: readPartProp(props, dir, 'y'),
    turn: readPartProp(props, dir, 'turn'),
    flip: !!readPartProp(props, dir, 'flip'),
    above: !!readPartProp(props, dir, 'above'),
    hide: !!readPartProp(props, dir, 'hide') || !!globalHide?.[dir],
    shrink: readPartProp(props, dir, 'shrink', 1),
  };
}

/**
 * Writes a shared overlay draft back into the legacy taur props map.
 *
 * The commit payload shape remains unchanged for Step 11. All writes continue
 * through `applyField()` so local clamps match the pre-existing editor controls
 * and the server-side sanitizer still receives compact, bounded values.
 */
export function applyTaurHybridDraftToPartProps(
  props: PartProps,
  dir: DirKey,
  draft: OffsetTransformProps,
): PartProps {
  let next = applyField(props, dir, 'x', draft.x);
  next = applyField(next, dir, 'y', draft.y);
  next = applyField(next, dir, 'turn', draft.turn);
  next = applyField(next, dir, 'flip', draft.flip);
  next = applyField(next, dir, 'above', !!draft.above);
  next = applyField(next, dir, 'hide', draft.hide);
  next = applyField(next, dir, 'shrink', draft.shrink);
  return next;
}

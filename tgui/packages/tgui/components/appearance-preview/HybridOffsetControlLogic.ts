/**
 * @file HybridOffsetControlLogic.ts
 * @description Pure draft-transform helpers for hybrid offset controls.
 *
 * The React control surface imports this module, and tests import it directly
 * so descriptor-gated transform behavior can be verified without evaluating
 * browser-only BYOND map-view components.
 */

import type {
  DirectionalOffsetProps,
  HybridOffsetField,
  OffsetTransformProps,
} from './shared';

/** Draft defaults shared by reset/copy/mirror helpers. */
export const DEFAULT_HYBRID_OFFSET_TRANSFORM: OffsetTransformProps = {
  x: 0,
  y: 0,
  turn: 0,
  flip: false,
  hide: false,
  shrink: 1,
  above: undefined,
};

type HybridOffsetControlField = HybridOffsetField | 'reset';

/**
 * Checks whether a descriptor allows a control field.
 *
 * Kept in the pure helper module so tests and UI agree on field gating without
 * importing the overlay component.
 */
export function hybridOffsetControlAllowsField(
  allowedFields: readonly HybridOffsetField[] | null | undefined,
  field: HybridOffsetField,
): boolean {
  return Array.isArray(allowedFields) && allowedFields.includes(field);
}

/**
 * Returns a draft with one field changed, respecting descriptor field gates.
 *
 * The special `reset` field resets only allowed fields so future x/y-only
 * intimate accessory descriptors do not accidentally wipe unsupported state
 * that an editor may be carrying for another target type.
 */
export function updateHybridOffsetField(
  draft: OffsetTransformProps,
  field: HybridOffsetControlField,
  value: number | boolean | null,
  allowedFields: readonly HybridOffsetField[] | null | undefined,
): OffsetTransformProps {
  if (field === 'reset') {
    let next = { ...draft };
    for (const allowedField of allowedFields ?? []) {
      next = {
        ...next,
        [allowedField]: DEFAULT_HYBRID_OFFSET_TRANSFORM[allowedField],
      };
    }
    return next;
  }
  if (!hybridOffsetControlAllowsField(allowedFields, field)) {
    return draft;
  }
  return {
    ...draft,
    [field]: value,
  };
}

/**
 * Copies one active direction draft to every direction key.
 *
 * `previous` is accepted for call-site ergonomics and future extension, but
 * the operation is intentionally literal: every direction receives a copy of
 * the active transform.
 */
export function copyHybridOffsetToAllDirections(
  source: OffsetTransformProps,
  previous?: DirectionalOffsetProps,
): DirectionalOffsetProps {
  void previous;
  return {
    s: { ...source },
    n: { ...source },
    e: { ...source },
    w: { ...source },
  };
}

/**
 * Mirrors an east/west transform by negating horizontal offset and rotation.
 *
 * Vertical offset, hide state, flip, shrink, and above are preserved. The
 * descriptor gate decides which mirrored fields may actually change.
 */
export function mirrorHybridOffsetTransform(
  source: OffsetTransformProps,
  allowedFields: readonly HybridOffsetField[] | null | undefined,
): OffsetTransformProps {
  return {
    ...source,
    x: hybridOffsetControlAllowsField(allowedFields, 'x')
      ? -source.x
      : source.x,
    turn: hybridOffsetControlAllowsField(allowedFields, 'turn')
      ? -source.turn
      : source.turn,
  };
}

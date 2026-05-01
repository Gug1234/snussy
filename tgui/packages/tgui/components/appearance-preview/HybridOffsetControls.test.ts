/**
 * @file HybridOffsetControls.test.ts
 * @description Step 8 unit coverage for descriptor-gated transform control
 * helpers. The visible React controls delegate all draft changes through these
 * helpers so editor migrations can reuse the same reset/copy/mirror semantics.
 */

import { describe, expect, it } from 'bun:test';

import type { DirectionalOffsetProps, OffsetTransformProps } from './shared';
import {
  copyHybridOffsetToAllDirections,
  DEFAULT_HYBRID_OFFSET_TRANSFORM,
  mirrorHybridOffsetTransform,
  updateHybridOffsetField,
} from './HybridOffsetControlLogic';

const draft: OffsetTransformProps = {
  x: 4,
  y: -2,
  turn: 35,
  flip: false,
  hide: false,
  shrink: 1.25,
  above: true,
};

describe('hybrid offset control helpers', () => {
  it('ignores edits to transform fields not allowed by the descriptor', () => {
    expect(updateHybridOffsetField(draft, 'turn', 90, ['x', 'y'])).toEqual(
      draft,
    );
    expect(updateHybridOffsetField(draft, 'x', -8, ['x', 'y'])).toEqual({
      ...draft,
      x: -8,
    });
  });

  it('resets allowed fields while preserving unsupported draft data', () => {
    const reset = updateHybridOffsetField(draft, 'reset', null, ['x', 'y']);
    expect(reset).toEqual({
      ...draft,
      x: DEFAULT_HYBRID_OFFSET_TRANSFORM.x,
      y: DEFAULT_HYBRID_OFFSET_TRANSFORM.y,
    });
  });

  it('copies the active transform to every direction', () => {
    const previous: DirectionalOffsetProps = {
      s: DEFAULT_HYBRID_OFFSET_TRANSFORM,
      n: { ...DEFAULT_HYBRID_OFFSET_TRANSFORM, y: 2 },
      e: { ...DEFAULT_HYBRID_OFFSET_TRANSFORM, x: 3 },
      w: { ...DEFAULT_HYBRID_OFFSET_TRANSFORM, x: -3 },
    };

    expect(copyHybridOffsetToAllDirections(draft, previous)).toEqual({
      s: draft,
      n: draft,
      e: draft,
      w: draft,
    });
  });

  it('mirrors east/west placement by negating x and turn', () => {
    expect(mirrorHybridOffsetTransform(draft, ['x', 'y', 'turn'])).toEqual({
      ...draft,
      x: -4,
      turn: -35,
    });
  });
});

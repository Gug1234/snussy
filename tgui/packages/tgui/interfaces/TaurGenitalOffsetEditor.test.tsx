/**
 * @file TaurGenitalOffsetEditor.test.tsx
 * @description Focused Step 12 regression tests for the taur offset editor.
 *
 * These tests cover the pure adapter layer between the legacy taur save shape
 * (`s/y/turn/...` fields inside a part props map) and the shared
 * `HybridOffsetOverlay` contract. The renderer should consume server-resolved
 * `hybrid_descriptors`; source-level drift guards keep local runtime DMI
 * state-name builders from being reintroduced in TGUI.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

import { describe, expect, it } from 'bun:test';

import type { HybridGuideDescriptor } from '../components/appearance-preview';
import {
  applyTaurHybridDraftToPartProps,
  getActiveTaurHybridDescriptor,
  partPropsToTaurHybridDraft,
} from './TaurGenitalOffsetEditorLogic';

const descriptor = (
  targetKey: string,
  direction: 's' | 'n' | 'e' | 'w',
  iconState: string,
): HybridGuideDescriptor => ({
  id: `taur_offsets:${targetKey}:${direction}`,
  family: 'taur_offsets',
  targetKey,
  manifestCategory: 'intimate_accessory',
  direction,
  layers: [{ iconState, role: 'guide' }],
  nativeWidth: 32,
  nativeHeight: 32,
  allowedFields: ['x', 'y', 'turn', 'flip', 'above', 'hide', 'shrink'],
  approximateColor: false,
});

/**
 * Reads a colocated taur editor source file for static drift checks.
 *
 * Rendering the whole TGUI interface in this focused unit test would require
 * the BYOND/TGUI runtime globals. Source checks are intentionally narrow: they
 * only guard against reintroducing the known local composition symbols and
 * against disconnecting the editor from the server descriptor path.
 */
const readInterfaceSource = (filename: string) =>
  readFileSync(join(import.meta.dir, filename), 'utf8');

describe('taur hybrid descriptor adapter', () => {
  it('selects the server-resolved descriptor for the active part, arousal state, and direction', () => {
    const descriptors = {
      penis: {
        '2': {
          n: descriptor('penis:2', 'n', 'knotted_3_BEHIND_1'),
        },
      },
      testicles: {
        s: descriptor('testicles', 's', 'pair_2_ADJ'),
      },
      vagina: {
        w: descriptor('vagina', 'w', 'spade_FRONT'),
      },
    };

    expect(
      getActiveTaurHybridDescriptor(descriptors, 'penis', 2, 'n')?.layers[0]
        .iconState,
    ).toBe('knotted_3_BEHIND_1');
    expect(
      getActiveTaurHybridDescriptor(descriptors, 'testicles', 0, 's')
        ?.targetKey,
    ).toBe('testicles');
    expect(getActiveTaurHybridDescriptor(descriptors, 'vagina', 0, 'n')).toBe(
      null,
    );
  });

  it('adapts legacy direction props to and from overlay draft transforms', () => {
    const props = {
      sx: 3,
      sy: -4,
      sturn: 15,
      sflip: 1,
      sabove: 0,
      shide: 0,
      sshrink: 1.25,
      nx: 9,
    };

    expect(
      partPropsToTaurHybridDraft(props, 's', {
        s: 1,
        n: 0,
        e: 0,
        w: 0,
      }),
    ).toEqual({
      x: 3,
      y: -4,
      turn: 15,
      flip: true,
      above: false,
      hide: true,
      shrink: 1.25,
    });

    const next = applyTaurHybridDraftToPartProps(props, 's', {
      x: 70,
      y: -80,
      turn: 400,
      flip: false,
      above: true,
      hide: true,
      shrink: 5,
    });

    expect(next).toEqual({
      ...props,
      sx: 64,
      sy: -64,
      sturn: 359,
      sflip: 0,
      sabove: 1,
      shide: 1,
      sshrink: 4,
    });
  });

  it('passes server descriptor layer states through without client-side renaming', () => {
    const sentinelState = 'server_exact_taur_state__do_not_recompose';
    const descriptors = {
      penis: {
        '1': {
          e: descriptor('penis:1', 'e', sentinelState),
        },
      },
    };

    expect(
      getActiveTaurHybridDescriptor(descriptors, 'penis', 1, 'e')?.layers,
    ).toEqual([{ iconState: sentinelState, role: 'guide' }]);
  });
});

describe('taur editor drift guard', () => {
  it('does not reintroduce local taur runtime icon-state builders', () => {
    const editorSource = readInterfaceSource('TaurGenitalOffsetEditor.tsx');
    const logicSource = readInterfaceSource('TaurGenitalOffsetEditorLogic.ts');
    const combinedSource = `${editorSource}\n${logicSource}`;

    expect(combinedSource).not.toContain('composeTaurState');
    expect(combinedSource).not.toContain('preview_descriptors');
    expect(combinedSource).not.toContain('PreviewDescriptor');
    expect(combinedSource).not.toContain('SheetPreviewTile');
    expect(combinedSource).not.toContain('penisLayerForDir');
    expect(combinedSource).not.toContain('testicleLayerForDir');
  });

  it('keeps the taur UI wired to hybrid_descriptors and HybridOffsetOverlay', () => {
    const editorSource = readInterfaceSource('TaurGenitalOffsetEditor.tsx');

    expect(editorSource).toContain(
      'hybrid_descriptors?: TaurHybridDescriptorMap',
    );
    expect(editorSource).toContain('getActiveTaurHybridDescriptor(');
    expect(editorSource).toContain('<HybridOffsetOverlay');
    expect(editorSource).toContain('descriptor={descriptor}');
    expect(editorSource).toContain('transformPixelRatio={PREVIEW_SCALE}');
  });
});

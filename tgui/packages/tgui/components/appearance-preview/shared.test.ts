import { describe, expect, it } from 'bun:test';

import {
  listSheetPaths,
  listStatesInCategory,
  resolveCrop,
  resolvePreviewTile,
  resolveState,
  resolveVariant,
} from './lookup';
import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type AppearancePreviewManifestV2,
  type DirectionKey,
  type HybridGuideDescriptor,
  type HybridGuideLayer,
  type OffsetTransformProps,
} from './shared';

describe('appearance preview v2 lookup helpers', () => {
  const manifest: AppearancePreviewManifestV2 = {
    version: APPEARANCE_PREVIEW_MANIFEST_VERSION,
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    canonicalLookupKey: 'icon_state',
    categoryOrder: ['sticker'],
    categories: {
      sticker: {
        key: 'sticker',
        scope: 'catalog',
        states: ['stud_metal', 'stud_gem'],
      },
    },
    sheets: {
      custom_piercings__0: {
        id: 'custom_piercings__0',
        family: 'custom_piercings',
        path: 'sheets/custom_piercings__0.png',
        width: 64,
        height: 128,
        tileWidth: 32,
        tileHeight: 32,
        contentHash: 'hash-abc',
      },
    },
    states: {
      stud_metal: {
        iconState: 'stud_metal',
        family: 'custom_piercings',
        sheetId: 'custom_piercings__0',
        crops: {
          s: { x: 0, y: 0, width: 32, height: 32 },
          n: { x: 0, y: 32, width: 32, height: 32 },
        },
        variants: { gem: 'stud_gem' },
      },
      stud_gem: {
        iconState: 'stud_gem',
        family: 'custom_piercings',
        sheetId: 'custom_piercings__0',
        crops: {
          s: { x: 32, y: 0, width: 32, height: 32 },
        },
      },
    },
    build: {
      builtAt: '1970-01-01T00:00:00.000Z',
      backend: APPEARANCE_PREVIEW_BACKEND_ID,
      layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
      sourceFingerprint: 'fingerprint-abc',
      adapterVersions: { custom_piercings: '1.0.0' },
    },
  };

  it('resolves known states and rejects missing ones', () => {
    expect(resolveState(manifest, 'stud_metal')?.iconState).toBe('stud_metal');
    expect(resolveState(manifest, 'does_not_exist')).toBeNull();
    expect(resolveState(null, 'stud_metal')).toBeNull();
  });

  it('resolves declared variants but not unknown keys', () => {
    const base = resolveState(manifest, 'stud_metal');
    expect(resolveVariant(manifest, base, 'gem')?.iconState).toBe('stud_gem');
    expect(resolveVariant(manifest, base, 'missing_key')).toBeNull();
  });

  it('resolves crops and falls back to s only when requested dir is absent', () => {
    const state = resolveState(manifest, 'stud_metal');
    expect(resolveCrop(state, 'n')?.direction).toBe('n');
    // stud_metal has no 'e' crop; falls back to 's'.
    expect(resolveCrop(state, 'e')?.direction).toBe('s');
    // stud_gem has only 's'; asking for 'e' still returns 's' fallback.
    const gem = resolveState(manifest, 'stud_gem');
    expect(resolveCrop(gem, 'e')?.direction).toBe('s');
  });

  it('rejects unresolvable tiles rather than guessing', () => {
    // Manifest with a state whose sheetId is orphaned => resolveState returns null.
    const broken: AppearancePreviewManifestV2 = {
      ...manifest,
      states: {
        orphan: {
          iconState: 'orphan',
          family: 'custom_piercings',
          sheetId: 'does_not_exist',
          crops: { s: { x: 0, y: 0, width: 32, height: 32 } },
        },
      },
    };
    expect(resolvePreviewTile(broken, 'orphan', 's')).toBeNull();
  });

  it('composes a ready-to-render tile bundle', () => {
    const tile = resolvePreviewTile(manifest, 'stud_metal', 's');
    expect(tile).not.toBeNull();
    expect(tile!.sheet.path).toBe('sheets/custom_piercings__0.png');
    expect(tile!.crop).toEqual({ x: 0, y: 0, width: 32, height: 32 });
    expect(tile!.resolvedDirection).toBe('s');
  });

  it('enumerates sheet paths and category states', () => {
    expect(listSheetPaths(manifest)).toEqual([
      'sheets/custom_piercings__0.png',
    ]);
    expect(
      listStatesInCategory(manifest, 'sticker').map((s) => s.iconState),
    ).toEqual(['stud_metal', 'stud_gem']);
    expect(listStatesInCategory(manifest, 'missing_cat')).toEqual([]);
  });
});

describe('hybrid offset guide descriptor contract', () => {
  it('accepts the shared descriptor shape emitted by DM', () => {
    const transform = {
      x: 2,
      y: -3,
      turn: 90,
      flip: false,
      hide: false,
      shrink: 1,
      above: true,
    } satisfies OffsetTransformProps;

    const layer = {
      iconState: 'piercing_stud_metal',
      role: 'metal',
      color: '#c0c0c0',
    } satisfies HybridGuideLayer;

    const direction = 's' satisfies DirectionKey;
    const descriptor = {
      id: 'custom_piercings:ears:0:s',
      family: 'custom_piercings',
      targetKey: 'ears:0',
      manifestCategory: 'sticker',
      direction,
      layers: [layer],
      nativeWidth: 32,
      nativeHeight: 32,
      allowedFields: ['x', 'y', 'turn', 'flip', 'hide', 'shrink', 'above'],
      approximateColor: true,
    } satisfies HybridGuideDescriptor;

    expect(descriptor.layers[0].iconState).toBe('piercing_stud_metal');
    expect(transform.above).toBe(true);
  });
});

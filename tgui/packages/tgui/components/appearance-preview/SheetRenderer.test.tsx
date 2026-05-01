/**
 * @file SheetRenderer.test.tsx
 * @description Step 14 coverage for the v2 sheet-cropping renderer.
 *
 * Strategy: invoke `SheetPreviewTile` as a plain function and inspect the
 * returned React element. This avoids standing up react-dom's rendering
 * pipeline (happy-dom is preloaded, but exercising render() is overkill for
 * a stateless presentational component) and keeps the tests focused on the
 * pure rendering contract:
 *
 *   - Unresolvable inputs (null manifest, unknown iconState, unknown sheet,
 *     missing direction with no south fallback) return an
 *     `<AppearancePreviewFallback>` element instead of silently rendering.
 *   - Resolvable inputs return a `<Box>` whose inline styles carry the exact
 *     background-image URL, background-position offsets, background-size,
 *     and element dimensions derived from the manifest crop rect.
 *   - Scale factor multiplies every pixel dimension uniformly.
 */

import { describe, expect, it } from 'bun:test';
import type { ReactElement } from 'react';

import { Box } from '../Box';
import { AppearancePreviewFallback } from './fallback';
import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type AppearancePreviewManifestV2,
} from './shared';
import { SheetPreviewTile } from './SheetRenderer';

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
      states: ['stud_metal'],
    },
  },
  sheets: {
    pack: {
      id: 'pack',
      family: 'custom_piercings',
      path: 'sheets/pack.png',
      width: 128,
      height: 64,
      tileWidth: 32,
      tileHeight: 32,
      contentHash: 'hash',
    },
  },
  states: {
    stud_metal: {
      iconState: 'stud_metal',
      family: 'custom_piercings',
      sheetId: 'pack',
      crops: {
        s: { x: 0, y: 0, width: 32, height: 32 },
        n: { x: 32, y: 32, width: 32, height: 32 },
      },
    },
    orphan: {
      iconState: 'orphan',
      family: 'custom_piercings',
      sheetId: 'missing',
      crops: { s: { x: 0, y: 0, width: 32, height: 32 } },
    },
  },
  build: {
    builtAt: '1970-01-01T00:00:00.000Z',
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    sourceFingerprint: 'fp',
    adapterVersions: { custom_piercings: '1.0.0' },
  },
};

/** Narrow the React element helper for readability. */
type El = ReactElement<{ style?: Record<string, string> }>;

describe('SheetPreviewTile fallback cases', () => {
  it('renders the fallback when the manifest is null', () => {
    const el = SheetPreviewTile({
      manifest: null,
      iconState: 'stud_metal',
    }) as El;
    expect(el.type).toBe(AppearancePreviewFallback);
  });

  it('renders the fallback when the iconState is unknown', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'does_not_exist',
    }) as El;
    expect(el.type).toBe(AppearancePreviewFallback);
  });

  it('renders the fallback when the referenced sheet is missing', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'orphan',
    }) as El;
    expect(el.type).toBe(AppearancePreviewFallback);
  });
});

describe('SheetPreviewTile resolution cases', () => {
  it('renders a Box for a resolvable state at the default direction', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
    }) as El;
    expect(el.type).toBe(Box);
    const style = el.props.style!;
    expect(style.width).toBe('32px');
    expect(style.height).toBe('32px');
    // Renderer prefixes manifest-relative paths with the manifest root.
    expect(style.backgroundImage).toBe(
      'url("appearance_preview/sheets/pack.png")',
    );
    expect(style.backgroundPosition).toBe('0px 0px');
    expect(style.backgroundSize).toBe('128px 64px');
    expect(style.imageRendering).toBe('pixelated');
  });

  it('uses the requested direction crop when present', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
      direction: 'n',
    }) as El;
    const style = el.props.style!;
    expect(style.backgroundPosition).toBe('-32px -32px');
  });

  it('falls back to the south crop when the requested direction is absent', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
      direction: 'e',
    }) as El;
    expect(el.type).toBe(Box);
    const style = el.props.style!;
    // south crop is (0,0,32,32); fallback must place the tile at origin.
    expect(style.backgroundPosition).toBe('0px 0px');
  });

  it('scales every pixel dimension uniformly', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
      direction: 'n',
      scale: 2,
    }) as El;
    const style = el.props.style!;
    expect(style.width).toBe('64px');
    expect(style.height).toBe('64px');
    expect(style.backgroundPosition).toBe('-64px -64px');
    expect(style.backgroundSize).toBe('256px 128px');
  });

  it('omits the filter style when no tint colour is supplied', () => {
    const el = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
    }) as El;
    const style = el.props.style!;
    expect(style.filter).toBeUndefined();
  });

  it('never emits a CSS `filter` even when a tint colour is supplied', () => {
    // Remediation Step 3: the legacy
    // `filter: drop-shadow(0 0 0 <color>) saturate(0)` path did not
    // actually tint the sprite — it desaturated to greyscale and painted a
    // zero-offset shadow behind. The canvas compositor now owns tinting,
    // so the untinted DOM output must never carry a CSS `filter`
    // declaration. Tinted callers get routed to an internal `<TintedTile>`
    // subcomponent instead of a plain `<Box>` with style; golden-pixel
    // coverage of the canvas compositor itself lands in Step 10
    // (`tint.test.ts`).
    const singleColor = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
      color: '#ff0000',
    }) as El;
    expect(singleColor.type).not.toBe(Box);
    expect(singleColor.props?.style?.filter).toBeUndefined();

    const multiColor = SheetPreviewTile({
      manifest,
      iconState: 'stud_metal',
      color: ['#ff0000', '#00ff00', '#0000ff'],
    }) as El;
    expect(multiColor.type).not.toBe(Box);
    expect(multiColor.props?.style?.filter).toBeUndefined();
  });
});

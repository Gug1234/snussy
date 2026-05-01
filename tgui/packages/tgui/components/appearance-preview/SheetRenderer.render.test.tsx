/**
 * @file SheetRenderer.render.test.tsx
 * @description Remediation Step 10 render-through coverage for the v2
 * sheet-cropping renderer. The prop-inspection suite in
 * {@link ./SheetRenderer.test.tsx} locked in the element structure; this
 * file locks in the DOM-level behaviour that the previous coverage gap
 * let the broken CSS-filter tint slip through: namely, a tinted tile
 * actually swaps its `background-image` URL to the canvas-composited
 * output instead of silently rendering the untinted sprite with a
 * grayscale filter.
 *
 * Happy-dom provides `HTMLCanvasElement` and `Image` stubs but no
 * rasterizer, so we stub `canvas.getContext("2d")` + `canvas.toDataURL()`
 * to return a sentinel URL. The render test then asserts that, once the
 * sheet-side Image stub fires `onload`, the rendered DOM element's
 * `style.backgroundImage` contains the sentinel URL.
 */

import { afterEach, beforeEach, describe, expect, it } from 'bun:test';
import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';

import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type AppearancePreviewManifestV2,
} from './shared';
import { SheetPreviewTile } from './SheetRenderer';
import { __resetTintCachesForTests } from './tint';

// ── Canvas + Image stubs ────────────────────────────────────────────────────

/** Sentinel data URL the stubbed canvas always returns. */
const DATA_URL_SENTINEL = 'data:image/png;base64,RENDER-TEST-SENTINEL';

type StubStash = {
  origGetContext: typeof HTMLCanvasElement.prototype.getContext;
  origToDataURL: typeof HTMLCanvasElement.prototype.toDataURL;
  origImage: typeof globalThis.Image;
};
let stash: StubStash | null = null;

function installStubs(): void {
  const origGetContext = HTMLCanvasElement.prototype.getContext;
  const origToDataURL = HTMLCanvasElement.prototype.toDataURL;
  const origImage = globalThis.Image;
  stash = { origGetContext, origToDataURL, origImage };

  // Minimal context stub: accepts every op the compositor emits and
  // round-trips hex colours through `fillStyle` so the colour validator
  // in tint.ts accepts them. No pixel data is actually drawn.
  Object.defineProperty(HTMLCanvasElement.prototype, 'getContext', {
    configurable: true,
    value: function getContextStub(kind: string) {
      if (kind !== '2d') return null;
      let _fill = '#000000';
      return {
        get fillStyle(): string {
          return _fill;
        },
        set fillStyle(v: string) {
          if (/^#[0-9a-f]{3,8}$/i.test(v)) _fill = v.toLowerCase();
        },
        globalCompositeOperation: 'source-over',
        clearRect: () => {},
        drawImage: () => {},
        fillRect: () => {},
      };
    },
  });
  Object.defineProperty(HTMLCanvasElement.prototype, 'toDataURL', {
    configurable: true,
    value: () => DATA_URL_SENTINEL,
  });

  // Image stub that fires `onload` synchronously on src assignment so the
  // compositor's IMAGE_CACHE transitions to `ready` during the effect.
  class StubImage {
    onload: (() => void) | null = null;
    onerror: (() => void) | null = null;
    private _src = '';
    get src(): string {
      return this._src;
    }
    set src(v: string) {
      this._src = v;
      if (this.onload) this.onload();
    }
  }
  (globalThis as unknown as { Image: unknown }).Image = StubImage;
}

function restoreStubs(): void {
  if (!stash) return;
  Object.defineProperty(HTMLCanvasElement.prototype, 'getContext', {
    configurable: true,
    value: stash.origGetContext,
  });
  Object.defineProperty(HTMLCanvasElement.prototype, 'toDataURL', {
    configurable: true,
    value: stash.origToDataURL,
  });
  (globalThis as unknown as { Image: unknown }).Image = stash.origImage;
  stash = null;
}

// ── Manifest fixture ────────────────────────────────────────────────────────

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
      },
      variants: undefined,
      flags: undefined,
    },
  },
  build: {
    builtAt: '2026-04-21T00:00:00.000Z',
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    sourceFingerprint: 'feedfacefeedface',
    adapterVersions: { custom_piercings: '1.0.0' },
  },
};

// ── Lifecycle ───────────────────────────────────────────────────────────────

let container: HTMLDivElement | null = null;
let root: Root | null = null;

beforeEach(() => {
  __resetTintCachesForTests();
  installStubs();
  container = document.createElement('div');
  document.body.appendChild(container);
  root = createRoot(container);
});

afterEach(() => {
  if (root) {
    act(() => {
      root!.unmount();
    });
    root = null;
  }
  if (container) {
    container.remove();
    container = null;
  }
  restoreStubs();
});

/** Find the first `<div>` (Box) inside the render container. */
function firstBox(): HTMLDivElement {
  const el = container!.querySelector('div');
  if (!el) {
    throw new Error('No rendered element found');
  }
  return el as HTMLDivElement;
}

// ── Tests ───────────────────────────────────────────────────────────────────

describe('SheetPreviewTile render output', () => {
  it('renders the untinted sheet URL as the background-image when color is null', async () => {
    await act(async () => {
      root!.render(
        <SheetPreviewTile
          manifest={manifest}
          iconState="stud_metal"
          direction="s"
          color={null}
        />,
      );
    });
    const el = firstBox();
    const bg = el.style.backgroundImage;
    // Untinted path must reference the sheet asset URL and must NOT
    // contain the canvas sentinel (which would mean the tinted path ran
    // accidentally).
    expect(bg).toContain('sheets/pack.png');
    expect(bg).not.toContain(DATA_URL_SENTINEL);
  });

  it('swaps to the composited data URL once the sheet image loads (single colour)', async () => {
    await act(async () => {
      root!.render(
        <SheetPreviewTile
          manifest={manifest}
          iconState="stud_metal"
          direction="s"
          color="#c0c0c0"
        />,
      );
    });
    // StubImage fires `onload` synchronously on src set, so the effect
    // should have already composited and re-rendered by the time `act`
    // returns.
    const el = firstBox();
    const bg = el.style.backgroundImage;
    // The canvas stub returns DATA_URL_SENTINEL; a successful composite
    // means the rendered Box must be using that URL rather than the
    // raw sheet path.
    expect(bg).toContain(DATA_URL_SENTINEL);
  });

  it('swaps to the composited data URL for a multi-colour GAGS tint', async () => {
    await act(async () => {
      root!.render(
        <SheetPreviewTile
          manifest={manifest}
          iconState="stud_metal"
          direction="s"
          color={['#ff0000', '#00ff00', '#0000ff']}
        />,
      );
    });
    const el = firstBox();
    expect(el.style.backgroundImage).toContain(DATA_URL_SENTINEL);
  });

  it('falls back to the untinted background when every supplied colour is invalid', async () => {
    // `normaliseColorList` drops invalid colours with a dev warning.
    // An all-invalid list degenerates to an empty colour set, which the
    // renderer treats as an untinted call — so the output must reference
    // the raw sheet URL, not a composited data URL.
    await act(async () => {
      root!.render(
        <SheetPreviewTile
          manifest={manifest}
          iconState="stud_metal"
          direction="s"
          color={['not-a-colour', 'also-bad']}
        />,
      );
    });
    const el = firstBox();
    expect(el.style.backgroundImage).toContain('sheets/pack.png');
    expect(el.style.backgroundImage).not.toContain(DATA_URL_SENTINEL);
  });
});

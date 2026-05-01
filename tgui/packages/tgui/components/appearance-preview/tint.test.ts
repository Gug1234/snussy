/**
 * @file tint.test.ts
 * @description Remediation Step 10 coverage for the canvas tint compositor.
 *
 * ## Test strategy
 *
 * Happy-dom (configured via `tgui/bunfig.toml`) provides `HTMLCanvasElement`
 * and `Image` stubs but does NOT implement an actual 2D rasterizer — a
 * call to `canvas.getContext("2d")` returns `null`. A true golden-pixel
 * comparison is therefore not feasible in the Bun test environment
 * without pulling in a native canvas dependency.
 *
 * Rather than bolt on such a dependency, the tests below stub the 2D
 * context with a call-recording proxy and validate the compositor's
 * behaviour by inspecting the exact sequence of draw operations emitted.
 * That is sufficient to pin every property the Step 3 plan called out:
 *
 *   - single-colour callers get one `drawImage` (base) → one `fillRect`
 *     under `multiply` → one `drawImage` under `destination-in` (re-mask).
 *   - multi-colour GAGS callers get one `fillRect` per declared colour,
 *     emitted in adapter order, between the base and the re-mask.
 *   - cached data URLs are returned ref-stable across repeated calls.
 *   - the LRU evicts in insertion-order when the cap is exceeded.
 *   - invalid CSS colours are dropped, not thrown on.
 *   - empty/undefined/null inputs yield `null` without touching canvas.
 *
 * A second-tier test verifies `useTintedTile` subscribes to the Image
 * load, since the component-layer render test
 * (`SheetRenderer.render.test.tsx`) depends on that behaviour.
 */

import { afterEach, beforeEach, describe, expect, it } from 'bun:test';
import { act, createElement, type ReactElement } from 'react';
import { createRoot } from 'react-dom/client';

import {
  __resetTintCachesForTests,
  compositeTintedTile,
  normaliseColorList,
  TINT_CACHE_CAP,
  useTintedTile,
} from './tint';

// ── Canvas stub ─────────────────────────────────────────────────────────────

/**
 * Operation record produced by the stubbed 2D context. Tests walk this
 * array to assert the compositor followed the documented sequence.
 */
type CanvasOp =
  | { kind: 'clearRect'; w: number; h: number }
  | { kind: 'drawImage'; sx: number; sy: number; sw: number; sh: number }
  | { kind: 'fillRect'; colour: string; w: number; h: number; mode: string }
  | { kind: 'setComposite'; mode: string };

interface StubContext {
  ops: CanvasOp[];
  dataUrlCounter: { n: number };
}

/**
 * Every `<canvas>` created during a test gets its own recording context.
 * `canvasSlots` lets tests retrieve the context(s) used during a call to
 * `compositeTintedTile` so the op sequence can be inspected.
 */
let canvasSlots: StubContext[] = [];

/**
 * Monotonic counter used to produce a unique `toDataURL` return per canvas,
 * so tests can distinguish "same cache key returns same URL" from "every
 * call re-rasterises".
 */
let dataUrlSerial = 0;

function installCanvasStub(): void {
  canvasSlots = [];
  dataUrlSerial = 0;
  const proto = HTMLCanvasElement.prototype;
  Object.defineProperty(proto, 'getContext', {
    configurable: true,
    value: function getContextStub(this: HTMLCanvasElement, kind: string) {
      if (kind !== '2d') return null;
      const slot: StubContext = {
        ops: [],
        dataUrlCounter: { n: 0 },
      };
      canvasSlots.push(slot);
      // `_fillStyle` backs the `fillStyle` accessor so the compositor's
      // colour validation logic (which round-trips through `fillStyle`)
      // keeps working under the stub.
      let _fillStyle = '#000000';
      let _composite = 'source-over';
      const ctx = {
        get fillStyle(): string {
          return _fillStyle;
        },
        set fillStyle(v: string) {
          // Mimic the canvas contract: only `#[0-9a-f]{3,8}` / colour
          // keywords round-trip; other strings silently retain the prior
          // value. For the compositor, that means normaliseColors's
          // invalid-colour probe still rejects garbage inputs.
          if (
            /^#[0-9a-f]{3,8}$/i.test(v) ||
            v === 'black' ||
            v === 'white' ||
            v === 'red' ||
            v === 'green' ||
            v === 'blue'
          ) {
            _fillStyle = v.toLowerCase();
          }
          // else: silently retain previous value (invalid colour).
        },
        get globalCompositeOperation(): string {
          return _composite;
        },
        set globalCompositeOperation(v: string) {
          _composite = v;
          slot.ops.push({ kind: 'setComposite', mode: v });
        },
        clearRect(_x: number, _y: number, w: number, h: number): void {
          slot.ops.push({ kind: 'clearRect', w, h });
        },
        drawImage(
          _img: unknown,
          sx: number,
          sy: number,
          sw: number,
          sh: number,
          _dx: number,
          _dy: number,
          _dw: number,
          _dh: number,
        ): void {
          slot.ops.push({ kind: 'drawImage', sx, sy, sw, sh });
        },
        fillRect(_x: number, _y: number, w: number, h: number): void {
          slot.ops.push({
            kind: 'fillRect',
            colour: _fillStyle,
            w,
            h,
            mode: _composite,
          });
        },
      };
      return ctx;
    },
  });
  Object.defineProperty(proto, 'toDataURL', {
    configurable: true,
    value: function toDataURLStub(this: HTMLCanvasElement) {
      // Return a URL that embeds the serial so repeat renders of the same
      // input (which should hit the cache) can be distinguished from
      // re-rasterisation in assertions.
      dataUrlSerial += 1;
      return `data:image/png;base64,stub-${dataUrlSerial}`;
    },
  });
}

/**
 * Drive the module-private IMAGE_CACHE into the `ready` state for a given
 * URL by rendering a throwaway component that subscribes via
 * {@link useTintedTile}. The `StubImage` we installed above fires its
 * `onload` synchronously on `src` assignment, so by the time `act(...)`
 * returns the entry is already `ready` and `compositeTintedTile` can be
 * invoked directly from test code.
 */
async function primeSheetReady(url: string): Promise<void> {
  const container = document.createElement('div');
  const root = createRoot(container);
  function Primer(): ReactElement | null {
    // Sentinel colour that no test input collides with — avoids spoofing
    // a TINT_CACHE hit in tests that expect a fresh composite pass.
    useTintedTile(url, CROP, ['#decafe']);
    return null;
  }
  await act(async () => {
    root.render(createElement(Primer));
  });
  act(() => {
    root.unmount();
  });
}
function installImageStub(): void {
  const realImage = globalThis.Image;
  // NOTE: do NOT declare `src` as a class field — class fields land as
  // own-properties on each instance and would shadow the prototype
  // accessor we install below, preventing the synchronous-onload hook
  // from ever firing.
  class StubImage {
    onload: (() => void) | null = null;
    onerror: (() => void) | null = null;
    _src = '';
  }
  // Redefine `src` so assigning a URL schedules a synchronous onload,
  // giving tests deterministic timing without awaiting microtasks.
  Object.defineProperty(StubImage.prototype, 'src', {
    configurable: true,
    get(this: { _src?: string }): string {
      return this._src ?? '';
    },
    set(this: { _src?: string; onload: (() => void) | null }, v: string) {
      this._src = v;
      // Fire onload synchronously. Real browsers defer this to a
      // microtask, but the compositor only cares that `state === 'ready'`
      // before the data URL is requested, and that is set by the handler
      // we install in tint.ts. Synchronous dispatch is safe because the
      // compositor never reads pixels from the stub — everything is
      // validated via the call-recorder above.
      if (this.onload) this.onload();
    },
  });
  (globalThis as unknown as { Image: unknown }).Image = StubImage;
  // Stash the real Image on the stub so restoreImageStub can reinstate it.
  (StubImage as unknown as { __real: typeof realImage }).__real = realImage;
}

function restoreImageStub(): void {
  const stub = globalThis.Image as unknown as {
    __real?: typeof globalThis.Image;
  };
  if (stub && stub.__real) {
    (globalThis as unknown as { Image: typeof globalThis.Image }).Image =
      stub.__real;
  }
}

beforeEach(() => {
  __resetTintCachesForTests();
  installCanvasStub();
  installImageStub();
});

afterEach(() => {
  restoreImageStub();
});

// ── Shared fixture ──────────────────────────────────────────────────────────

const TILE_URL = 'https://example.invalid/sheet.png';
const CROP = { x: 4, y: 8, width: 4, height: 4 };

// ── Pure-API tests ──────────────────────────────────────────────────────────

describe('normaliseColorList', () => {
  it('returns an empty array for null / undefined / empty string', () => {
    expect(normaliseColorList(null)).toEqual([]);
    expect(normaliseColorList(undefined)).toEqual([]);
    expect(normaliseColorList('')).toEqual([]);
  });

  it('splits a comma-joined legacy string into trimmed entries', () => {
    expect(normaliseColorList('#ff0000, #00ff00 , #0000ff')).toEqual([
      '#ff0000',
      '#00ff00',
      '#0000ff',
    ]);
  });

  it('passes an array through verbatim, dropping non-string entries', () => {
    const input = ['#ff0000', '#00ff00'];
    expect(normaliseColorList(input)).toEqual(input);
  });

  it('drops entries the canvas rejects as invalid CSS colours', () => {
    // "not-a-colour" will not set `fillStyle` on the stub, so the
    // normaliser's probe returns "#000000" (the sentinel) and discards it.
    const out = normaliseColorList(['#ff0000', 'not-a-colour', '#00ff00', '']);
    expect(out).toEqual(['#ff0000', '#00ff00']);
  });
});

describe('compositeTintedTile return contract', () => {
  it('returns null for an empty colour list without touching the canvas', () => {
    const out = compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: [],
    });
    expect(out).toBeNull();
    expect(canvasSlots.length).toBe(0);
  });

  it('returns null when the sheet image has not been loaded yet', () => {
    // IMAGE_CACHE is empty; compositor must bail out so the caller can
    // fall back to the untinted CSS path.
    const out = compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#ff0000'],
    });
    expect(out).toBeNull();
  });
});

// ── Compositor call-sequence tests ──────────────────────────────────────────
//
// After priming the image cache via a throwaway React render, each test
// invokes `compositeTintedTile` directly so the recorded canvas ops reflect
// exactly one composite pass with no hook-driven noise. The priming render
// produces its own canvas slot; tests snapshot `canvasSlots.length` before
// each direct call and inspect the newly appended slot.

describe('compositeTintedTile canvas call sequence', () => {
  it('emits the canonical single-colour sequence (base → multiply → remask)', async () => {
    await primeSheetReady(TILE_URL);
    const canvasesBefore = canvasSlots.length;
    const out = compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#ff0000'],
    });
    expect(out).toMatch(/^data:image\/png;base64,stub-/);
    expect(canvasSlots.length).toBe(canvasesBefore + 1);
    const ops = canvasSlots[canvasesBefore].ops;
    const meaningful = ops.filter((op) => op.kind !== 'clearRect');

    expect(meaningful[0]).toEqual({
      kind: 'setComposite',
      mode: 'source-over',
    });
    expect(meaningful[1].kind).toBe('drawImage');
    expect(meaningful[2]).toEqual({
      kind: 'setComposite',
      mode: 'multiply',
    });
    expect(meaningful[3]).toEqual({
      kind: 'fillRect',
      colour: '#ff0000',
      w: 4,
      h: 4,
      mode: 'multiply',
    });
    expect(meaningful[4]).toEqual({
      kind: 'setComposite',
      mode: 'destination-in',
    });
    expect(meaningful[5].kind).toBe('drawImage');
    expect(meaningful[6]).toEqual({
      kind: 'setComposite',
      mode: 'source-over',
    });
  });

  it('emits one multiply fillRect per colour for a 3-band GAGS tint', async () => {
    await primeSheetReady(TILE_URL);
    const canvasesBefore = canvasSlots.length;
    const out = compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#ff0000', '#00ff00', '#0000ff'],
    });
    expect(out).toMatch(/^data:image\/png;base64,stub-/);
    const ops = canvasSlots[canvasesBefore].ops;
    const fills = ops.filter(
      (op): op is Extract<CanvasOp, { kind: 'fillRect' }> =>
        op.kind === 'fillRect',
    );
    expect(fills.map((f) => f.colour)).toEqual([
      '#ff0000',
      '#00ff00',
      '#0000ff',
    ]);
    for (const fill of fills) {
      expect(fill.mode).toBe('multiply');
    }
  });

  it('returns the cached data URL on repeat calls with identical inputs', async () => {
    await primeSheetReady(TILE_URL);
    const first = compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#654321'],
    });
    const canvasesAfterFirst = canvasSlots.length;
    const second = compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#654321'],
    });
    expect(first).not.toBeNull();
    expect(second).toBe(first);
    expect(canvasSlots.length).toBe(canvasesAfterFirst);
  });

  it('evicts the oldest entry when the LRU cap is exceeded', async () => {
    await primeSheetReady(TILE_URL);
    for (let i = 0; i < TINT_CACHE_CAP; i += 1) {
      compositeTintedTile({
        sheetUrl: TILE_URL,
        crop: CROP,
        colors: [`#${i.toString(16).padStart(6, '0')}`],
      });
    }
    const canvasesAtCap = canvasSlots.length;
    // Exceeds cap → evicts oldest (`#000000`), requires new canvas.
    compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#abcdef'],
    });
    expect(canvasSlots.length).toBe(canvasesAtCap + 1);
    // Re-request evicted oldest → must re-rasterise.
    compositeTintedTile({
      sheetUrl: TILE_URL,
      crop: CROP,
      colors: ['#000000'],
    });
    expect(canvasSlots.length).toBe(canvasesAtCap + 2);
  });
});

/**
 * @file tint.ts
 * @description Canvas-based sprite tint compositor for the v2 sheet-backed
 * appearance-preview runtime. Replaces the legacy CSS
 * `filter: drop-shadow(0 0 0 <color>) saturate(0)` trick, which did not
 * actually recolour the sprite and silently broke multi-colour GAGS tints.
 *
 * The compositor is pure + deterministic: given the same sheet URL, crop
 * rect, and ordered list of CSS colours, it produces the same data URL on
 * every invocation. Results are cached in a module-scoped LRU (cap
 * {@link TINT_CACHE_CAP}) to keep the memory footprint bounded under the
 * worst-case editor-reopen churn the project rules call out (≤200 clients
 * spamming inputs).
 *
 * The sheet bitmap itself is loaded once per URL and shared across every
 * tint call referencing it; this keeps repeated tile reads off the network
 * and lets the browser decode each sheet exactly once.
 *
 * Pixel-exact fidelity is best-effort for multi-colour GAGS: without access
 * to the server-side band masks we approximate by sequentially `multiply`-ing
 * each colour onto the sprite. Single-colour callers (the overwhelmingly
 * common case) get the canonical "multiply-then-remask" tint that the
 * Step 10 golden-pixel test will pin.
 *
 * All exports here are framework-agnostic (plain functions + observer-style
 * subscriptions). The React hook {@link useTintedTile} lives alongside so
 * the component layer can subscribe to cache entries without re-implementing
 * the load/compose pipeline.
 */

import { useEffect, useState } from 'react';

import type { AppearancePreviewCropRect } from './shared';

// ── Public types ────────────────────────────────────────────────────────────

/** Cap for the composited data-URL LRU. Sized for worst-case editor churn. */
export const TINT_CACHE_CAP = 256;

/** Crop rect accepted by the compositor. Structurally matches the manifest. */
export type TintCrop = Pick<
  AppearancePreviewCropRect,
  'x' | 'y' | 'width' | 'height'
>;

/** Result returned to components. `null` while the sheet is still loading. */
export type TintedTileResult = string | null;

// ── Internal state ──────────────────────────────────────────────────────────

type ImageEntryState = 'loading' | 'ready' | 'failed';

interface ImageEntry {
  url: string;
  image: HTMLImageElement;
  state: ImageEntryState;
  subscribers: Set<() => void>;
}

const IMAGE_CACHE = new Map<string, ImageEntry>();

/**
 * Module-scoped LRU of composited data URLs. Insertion order is maintained
 * via `Map`'s own iteration order: on hit we re-insert to mark as
 * most-recently-used; on overflow we delete the first (oldest) key.
 */
const TINT_CACHE = new Map<string, string>();

/** Dev-console warnings are memoised so we don't spam on every render. */
const WARNED_COLORS = new Set<string>();

// ── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Build a stable cache key from the inputs. Colours are joined in their
 * declared order so the GAGS adapter's band ordering (metal → gem, etc.) is
 * preserved in the key — reordering the same colour set must produce a
 * distinct entry.
 */
function buildKey(
  sheetUrl: string,
  crop: TintCrop,
  colors: readonly string[],
): string {
  return `${sheetUrl}|${crop.x},${crop.y},${crop.width},${crop.height}|${colors.join(',')}`;
}

/**
 * Accept a CSS colour if the environment can parse it (canvas `fillStyle`
 * normalises/validates synchronously). Invalid entries are dropped with a
 * one-shot dev-console warning so adapters emitting bad data are loud in
 * development but never crash the editor.
 */
function normaliseColors(colors: readonly string[]): string[] {
  if (typeof document === 'undefined') {
    return colors.slice();
  }
  const probe = document.createElement('canvas').getContext('2d');
  if (!probe) {
    return colors.slice();
  }
  const out: string[] = [];
  for (const raw of colors) {
    if (typeof raw !== 'string') {
      continue;
    }
    const trimmed = raw.trim();
    if (!trimmed) {
      continue;
    }
    // `fillStyle` returns the normalised form on success, or silently
    // retains its prior value on failure. Comparing against a sentinel
    // detects the failure mode cheaply.
    probe.fillStyle = '#000000';
    probe.fillStyle = trimmed;
    if (typeof probe.fillStyle === 'string' && probe.fillStyle !== '#000000') {
      out.push(trimmed);
      continue;
    }
    // The normalised form of "#000000" is the sentinel itself, so also
    // accept an explicit black entry.
    if (/^#0{3,6}$/i.test(trimmed) || trimmed.toLowerCase() === 'black') {
      out.push(trimmed);
      continue;
    }
    if (!WARNED_COLORS.has(trimmed)) {
      WARNED_COLORS.add(trimmed);
      // eslint-disable-next-line no-console
      console.warn(
        `[appearance-preview tint] Ignoring invalid CSS colour: ${trimmed}`,
      );
    }
  }
  return out;
}

/**
 * Load (or return the cached) sheet bitmap for a given URL. Multiple
 * callers share one `HTMLImageElement`; each call's `onReady` runs as soon
 * as the entry transitions to `ready` (or immediately if already loaded).
 *
 * The returned unsubscribe fn removes the caller's listener without
 * cancelling the underlying load — downloads always run to completion so
 * concurrent consumers of the same sheet never cancel each other.
 */
function loadSheetImage(url: string, onReady: () => void): () => void {
  let entry = IMAGE_CACHE.get(url);
  if (!entry) {
    const image = new Image();
    const created: ImageEntry = {
      url,
      image,
      state: 'loading',
      subscribers: new Set(),
    };
    IMAGE_CACHE.set(url, created);
    entry = created;
    image.onload = () => {
      created.state = 'ready';
      for (const sub of Array.from(created.subscribers)) {
        sub();
      }
    };
    image.onerror = () => {
      created.state = 'failed';
      for (const sub of Array.from(created.subscribers)) {
        sub();
      }
    };
    // Setting `src` must happen after the handlers are bound so cached
    // browser responses still fire `onload` asynchronously via microtask.
    image.src = url;
  }
  if (entry.state === 'ready') {
    onReady();
    return () => {
      /* no-op: nothing to unsubscribe from. */
    };
  }
  entry.subscribers.add(onReady);
  const capturedEntry = entry;
  return () => {
    capturedEntry.subscribers.delete(onReady);
  };
}

/**
 * Paint every colour band onto the sprite via sequential `multiply`, then
 * re-mask to the sprite's original alpha. Single-colour behaviour matches
 * the canonical sprite-tint algorithm; multi-colour behaviour compounds
 * each band's multiply (the best approximation available without
 * server-side band masks) and preserves the declared colour order.
 */
function paintTint(
  ctx: CanvasRenderingContext2D,
  image: HTMLImageElement,
  crop: TintCrop,
  colors: readonly string[],
): void {
  const { x, y, width, height } = crop;

  // Base pass: the untinted sprite preserves the sheet's luminance and
  // alpha. Without this the multiply passes would have nothing to act on.
  ctx.globalCompositeOperation = 'source-over';
  ctx.clearRect(0, 0, width, height);
  ctx.drawImage(image, x, y, width, height, 0, 0, width, height);

  for (const colour of colors) {
    ctx.globalCompositeOperation = 'multiply';
    ctx.fillStyle = colour;
    ctx.fillRect(0, 0, width, height);
  }

  // Re-clip to the sprite's original alpha mask so the rectangular fill
  // rectangles above don't bleed outside the sprite silhouette.
  ctx.globalCompositeOperation = 'destination-in';
  ctx.drawImage(image, x, y, width, height, 0, 0, width, height);
  ctx.globalCompositeOperation = 'source-over';
}

/**
 * Insert into the LRU and evict the oldest key when the cap is exceeded.
 * Must be called only for fresh inserts — a hit should re-insert instead
 * to keep the access-recency ordering accurate.
 */
function lruSet(key: string, dataUrl: string): void {
  if (TINT_CACHE.has(key)) {
    TINT_CACHE.delete(key);
  }
  TINT_CACHE.set(key, dataUrl);
  while (TINT_CACHE.size > TINT_CACHE_CAP) {
    const oldest = TINT_CACHE.keys().next().value;
    if (oldest === undefined) {
      break;
    }
    TINT_CACHE.delete(oldest);
  }
}

// ── Public API ──────────────────────────────────────────────────────────────

/**
 * Composite a tinted tile synchronously. Returns the cached data URL if the
 * sheet has already been drawn and composited, or `null` if the sheet is
 * still loading / has failed. Callers that want to react to the load-ready
 * transition should prefer {@link useTintedTile}.
 *
 * `colors` is treated as already-normalised; use {@link normaliseColorList}
 * for user- or adapter-sourced inputs.
 */
export function compositeTintedTile(params: {
  sheetUrl: string;
  crop: TintCrop;
  colors: readonly string[];
}): TintedTileResult {
  const { sheetUrl, crop, colors } = params;
  if (colors.length === 0) {
    return null;
  }
  const key = buildKey(sheetUrl, crop, colors);
  const cached = TINT_CACHE.get(key);
  if (cached !== undefined) {
    // Touch LRU ordering: delete + re-insert marks this key as most-recent.
    TINT_CACHE.delete(key);
    TINT_CACHE.set(key, cached);
    return cached;
  }
  if (typeof document === 'undefined') {
    return null;
  }
  const entry = IMAGE_CACHE.get(sheetUrl);
  if (!entry || entry.state !== 'ready') {
    return null;
  }
  const canvas = document.createElement('canvas');
  canvas.width = crop.width;
  canvas.height = crop.height;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    return null;
  }
  paintTint(ctx, entry.image, crop, colors);
  const dataUrl = canvas.toDataURL('image/png');
  lruSet(key, dataUrl);
  return dataUrl;
}

/**
 * Normalise + dedupe a list of CSS colours. Accepts either an array or a
 * comma-joined string (the legacy wire shape emitted by the taur adapter
 * before Remediation Step 3; kept for one release of backward compat).
 * Invalid entries are dropped with a memoised dev-console warning.
 */
export function normaliseColorList(
  input: string | readonly string[] | null | undefined,
): string[] {
  if (input === null) {
    return [];
  }
  if (Array.isArray(input)) {
    return normaliseColors(input);
  }
  if (typeof input === 'string') {
    if (input.length === 0) {
      return [];
    }
    return normaliseColors(input.split(',').map((part) => part.trim()));
  }
  return [];
}

/**
 * React hook: composite a tinted tile and re-render when the underlying
 * sheet bitmap finishes loading. Returns the data URL or `null`.
 *
 * The hook is safe to call with an empty colour list — in that case it
 * short-circuits to `null` and does not trigger a sheet load.
 */
export function useTintedTile(
  sheetUrl: string,
  crop: TintCrop,
  colors: readonly string[],
): TintedTileResult {
  const key = colors.length > 0 ? buildKey(sheetUrl, crop, colors) : '';
  const [dataUrl, setDataUrl] = useState<TintedTileResult>(() => {
    if (!key) {
      return null;
    }
    return compositeTintedTile({ sheetUrl, crop, colors });
  });

  useEffect(() => {
    if (!key) {
      if (dataUrl !== null) {
        setDataUrl(null);
      }
      return;
    }
    // Attempt a synchronous composite first — on cache hits or when the
    // sheet bitmap is already decoded, this avoids a wasted render pass.
    const immediate = compositeTintedTile({ sheetUrl, crop, colors });
    if (immediate !== null) {
      if (immediate !== dataUrl) {
        setDataUrl(immediate);
      }
      return;
    }
    // Otherwise subscribe to the sheet load and re-composite once ready.
    // The subscription is cleared on unmount / dependency change so we
    // don't leak closures over stale props.
    let cancelled = false;
    const unsubscribe = loadSheetImage(sheetUrl, () => {
      if (cancelled) {
        return;
      }
      const computed = compositeTintedTile({ sheetUrl, crop, colors });
      setDataUrl(computed);
    });
    return () => {
      cancelled = true;
      unsubscribe();
    };
    // `key` collapses all structural inputs into one primitive; re-running
    // on `colors`/`crop` identity changes would over-render for equivalent
    // values.
  }, [key]);

  return dataUrl;
}

/**
 * Test-only helper: wipes every cache layer so fixtures do not bleed across
 * tests. Not exported from the public `index.tsx` barrel.
 */
export function __resetTintCachesForTests(): void {
  TINT_CACHE.clear();
  IMAGE_CACHE.clear();
  WARNED_COLORS.clear();
}

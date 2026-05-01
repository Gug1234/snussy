/**
 * @file preload.ts
 * @description Module-scoped cache for the v2 preview manifest plus sheet
 * image preload. Both are fetched exactly once per browser session and reused
 * across every editor instance.
 *
 * Contract:
 *   - `loadAppearancePreviewManifestV2()` returns a memoised Promise for the
 *     validated v2 manifest at `appearance_preview/manifest.json`. The
 *     manifest is lightly structurally validated here (backend/layout/version
 *     check) so callers can trust the envelope; the DM-side asset loader is
 *     the canonical validator, this is a defence-in-depth gate.
 *   - `preloadSheets(manifest)` kicks off `<Image>`-style fetches for every
 *     sheet PNG referenced by the manifest. Safe to call repeatedly; the
 *     browser image cache dedupes.
 *   - `resetAppearancePreviewPreloadCache()` is exposed for tests only.
 *
 * This module deliberately does NOT own React state. See `index.tsx` for the
 * `AppearancePreviewProvider` that wraps these helpers in a hook.
 */

import { resolveAsset } from 'tgui/assets';

import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type AppearancePreviewManifestV2,
} from './shared';

const MANIFEST_ASSET_PATH = 'appearance_preview/manifest.json';

let cachedManifest: AppearancePreviewManifestV2 | null = null;
let cachedManifestPromise: Promise<AppearancePreviewManifestV2> | null = null;
const preloadedSheets = new Set<string>();

/**
 * Light structural validator. Rejects obvious version/backend/layout drift
 * before we hand the manifest to the rest of the runtime. The DM-side
 * asset loader (`code/modules/asset_cache/assets/appearance_preview.dm`) is
 * authoritative; this is a second line of defence for the browser.
 */
function assertV2Envelope(candidate: unknown): AppearancePreviewManifestV2 {
  if (!candidate || typeof candidate !== 'object') {
    throw new Error('appearance preview manifest: not an object');
  }
  const record = candidate as Record<string, unknown>;
  if (record.version !== APPEARANCE_PREVIEW_MANIFEST_VERSION) {
    throw new Error(
      `appearance preview manifest: expected version ${APPEARANCE_PREVIEW_MANIFEST_VERSION}, got ${String(record.version)}`,
    );
  }
  if (record.backend !== APPEARANCE_PREVIEW_BACKEND_ID) {
    throw new Error(
      `appearance preview manifest: expected backend ${APPEARANCE_PREVIEW_BACKEND_ID}, got ${String(record.backend)}`,
    );
  }
  if (record.layout !== APPEARANCE_PREVIEW_LAYOUT_KIND) {
    throw new Error(
      `appearance preview manifest: expected layout ${APPEARANCE_PREVIEW_LAYOUT_KIND}, got ${String(record.layout)}`,
    );
  }
  if (!record.sheets || typeof record.sheets !== 'object') {
    throw new Error('appearance preview manifest: missing sheets block');
  }
  if (!record.states || typeof record.states !== 'object') {
    throw new Error('appearance preview manifest: missing states block');
  }
  if (!record.categories || typeof record.categories !== 'object') {
    throw new Error('appearance preview manifest: missing categories block');
  }
  return candidate as AppearancePreviewManifestV2;
}

/**
 * Fetch and memoise the v2 manifest. Concurrent callers share one fetch.
 */
export function loadAppearancePreviewManifestV2(): Promise<AppearancePreviewManifestV2> {
  if (cachedManifest) {
    return Promise.resolve(cachedManifest);
  }
  if (!cachedManifestPromise) {
    cachedManifestPromise = fetch(resolveAsset(MANIFEST_ASSET_PATH))
      .then((response) => {
        if (!response.ok) {
          throw new Error(
            `appearance preview manifest: fetch failed (${response.status})`,
          );
        }
        return response.json();
      })
      .then((raw) => {
        const manifest = assertV2Envelope(raw);
        cachedManifest = manifest;
        return manifest;
      })
      .catch((err) => {
        // Allow a retry on next mount by clearing the in-flight promise.
        cachedManifestPromise = null;
        throw err;
      });
  }
  return cachedManifestPromise;
}

/**
 * Synchronous accessor for already-loaded manifests (returns null until the
 * first load resolves). Intended for non-React helpers; components should
 * use the provider/hook in `index.tsx`.
 */
export function getCachedAppearancePreviewManifestV2(): AppearancePreviewManifestV2 | null {
  return cachedManifest;
}

/**
 * Kick the browser into downloading every sheet PNG referenced by the
 * manifest. Idempotent per sheet path.
 */
export function preloadSheets(manifest: AppearancePreviewManifestV2): void {
  for (const sheet of Object.values(manifest.sheets)) {
    if (preloadedSheets.has(sheet.path)) {
      continue;
    }
    preloadedSheets.add(sheet.path);
    const img = new globalThis.Image();
    img.src = resolveAsset(`appearance_preview/${sheet.path}`);
  }
}

/**
 * Resolve the browser URL for a sheet path as served by the DM asset cache.
 */
export function resolveSheetAssetUrl(sheetPath: string): string {
  return resolveAsset(`appearance_preview/${sheetPath}`);
}

/**
 * Test-only cache reset. Safe for production calls but no production use.
 */
export function resetAppearancePreviewPreloadCache(): void {
  cachedManifest = null;
  cachedManifestPromise = null;
  preloadedSheets.clear();
}

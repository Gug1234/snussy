/**
 * @file lookup.ts
 * @description State and variant resolution helpers for the v2 sheet-backed
 * appearance preview runtime. Pure functions only — no React, no IO, no
 * module-level state. Companion to `shared.ts` (canonical v2 types) and
 * consumed by `SheetRenderer.tsx`, `preload.ts`, and the Step 9 editor shell.
 *
 * Resolution rules (fail-closed):
 *   - `resolveState` returns the v2 state record for a canonical icon_state,
 *     or null if the state is absent, its declared sheet is missing, or its
 *     crop for the requested direction is absent.
 *   - `resolveVariant` chases a state's `variants` map to another state by
 *     variant-key (e.g. "gem", "partial", "hard"). Returns null if the
 *     variant key is unknown or the referenced state is absent.
 *   - `resolveCrop` picks the crop rect for the requested direction, falling
 *     back to "s" only if the state has no crop at the requested direction
 *     AND has a "s" crop. Absent "s" fallback -> null (renderer shows
 *     fallback tile). This matches the DM-side adapter guarantee that every
 *     state contributes an "s" tile.
 *
 * All helpers accept a manifest-or-null signature so call sites can invoke
 * them during the brief pre-load window without null-check noise.
 */

import type {
  AppearancePreviewCropRect,
  AppearancePreviewManifestV2,
  AppearancePreviewSheetRecord,
  AppearancePreviewStateRecord,
  AppearancePreviewV2DirectionKey,
} from './shared';

/** Narrow, non-nullable sheet+state+crop bundle used by the renderer. */
export interface ResolvedPreviewTile {
  state: AppearancePreviewStateRecord;
  sheet: AppearancePreviewSheetRecord;
  crop: AppearancePreviewCropRect;
  /** The direction that actually resolved (may differ from the request). */
  resolvedDirection: AppearancePreviewV2DirectionKey;
}

/**
 * Look up a state by its canonical icon_state key.
 * Returns null if the state is absent or references a missing sheet.
 */
export function resolveState(
  manifest: AppearancePreviewManifestV2 | null,
  iconState: string,
): AppearancePreviewStateRecord | null {
  if (!manifest || !iconState) {
    return null;
  }
  const state = manifest.states[iconState];
  if (!state) {
    return null;
  }
  if (!manifest.sheets[state.sheetId]) {
    return null;
  }
  return state;
}

/**
 * Resolve a variant reference off a base state. `variantKey` is the
 * adapter-defined alias (e.g. "gem", "partial", "hard"); the resolved value
 * is looked up as another top-level state.
 */
export function resolveVariant(
  manifest: AppearancePreviewManifestV2 | null,
  base: AppearancePreviewStateRecord | null,
  variantKey: string,
): AppearancePreviewStateRecord | null {
  if (!manifest || !base || !variantKey) {
    return null;
  }
  const targetIconState = base.variants?.[variantKey];
  if (!targetIconState) {
    return null;
  }
  return resolveState(manifest, targetIconState);
}

/**
 * Resolve the crop rect for `direction`. Falls back to "s" only if the state
 * lacks the requested direction but has a south crop. Returns null otherwise.
 */
export function resolveCrop(
  state: AppearancePreviewStateRecord | null,
  direction: AppearancePreviewV2DirectionKey,
): {
  crop: AppearancePreviewCropRect;
  direction: AppearancePreviewV2DirectionKey;
} | null {
  if (!state) {
    return null;
  }
  const requested = state.crops[direction];
  if (requested) {
    return { crop: requested, direction };
  }
  if (direction !== 's') {
    const south = state.crops.s;
    if (south) {
      return { crop: south, direction: 's' };
    }
  }
  return null;
}

/**
 * One-shot resolver that returns a fully-ready tile bundle for the renderer
 * or null if any link is missing. Prefer this in render code.
 */
export function resolvePreviewTile(
  manifest: AppearancePreviewManifestV2 | null,
  iconState: string,
  direction: AppearancePreviewV2DirectionKey,
): ResolvedPreviewTile | null {
  const state = resolveState(manifest, iconState);
  if (!state) {
    return null;
  }
  const sheet = manifest!.sheets[state.sheetId];
  const crop = resolveCrop(state, direction);
  if (!crop) {
    return null;
  }
  return {
    state,
    sheet,
    crop: crop.crop,
    resolvedDirection: crop.direction,
  };
}

/**
 * Enumerate the sheet paths required to cover every state in the manifest.
 * Used by `preload.ts` so the first paint of any editor never shows a
 * network-fetch flicker.
 */
export function listSheetPaths(
  manifest: AppearancePreviewManifestV2 | null,
): string[] {
  if (!manifest) {
    return [];
  }
  return Object.values(manifest.sheets).map((sheet) => sheet.path);
}

/**
 * List every state belonging to a named category. Returns [] for missing
 * categories. Used by editor shells that iterate catalog-scoped families.
 */
export function listStatesInCategory(
  manifest: AppearancePreviewManifestV2 | null,
  categoryKey: string,
): AppearancePreviewStateRecord[] {
  if (!manifest) {
    return [];
  }
  const category = manifest.categories[categoryKey];
  if (!category) {
    return [];
  }
  const out: AppearancePreviewStateRecord[] = [];
  for (const iconState of category.states) {
    const state = manifest.states[iconState];
    if (state) {
      out.push(state);
    }
  }
  return out;
}

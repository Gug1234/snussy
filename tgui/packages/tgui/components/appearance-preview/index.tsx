/**
 * @file index.tsx
 * @description Shared entrypoint for the v2 sheet-backed appearance preview
 * runtime. Exports:
 *   - `AppearancePreviewProvider` and `useAppearancePreview` — React-level
 *     manifest loading + sheet preload.
 *   - `SheetPreviewTile` — sheet-crop renderer.
 *   - `AppearancePreviewFallback` — visible placeholder for missing states.
 *   - `AppearancePreviewDirectionButtons` — shared S/N/E/W picker.
 *   - v2 type re-exports from `./shared` and pure lookup helpers from
 *     `./lookup`.
 *
 * The legacy v1 surface (per-state, Python-exporter) was removed alongside
 * the Python exporter; all consumers must go through the v2 runtime above.
 */

import {
  createContext,
  type ReactNode,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';

import {
  getCachedAppearancePreviewManifestV2,
  loadAppearancePreviewManifestV2,
  preloadSheets,
} from './preload';
import type { AppearancePreviewManifestV2 } from './shared';

// ── v2 re-exports ───────────────────────────────────────────────────────────

export { AppearancePreviewFallback } from './fallback';
export {
  listSheetPaths,
  listStatesInCategory,
  resolveCrop,
  type ResolvedPreviewTile,
  resolvePreviewTile,
  resolveState,
  resolveVariant,
} from './lookup';
export {
  getCachedAppearancePreviewManifestV2,
  loadAppearancePreviewManifestV2,
  preloadSheets,
  resetAppearancePreviewPreloadCache,
  resolveSheetAssetUrl,
} from './preload';
export {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  APPEARANCE_PREVIEW_V2_DIRECTION_ORDER,
  type AppearancePreviewBuildMetadata,
  type AppearancePreviewCategoryRecord,
  type AppearancePreviewCropRect,
  type AppearancePreviewManifestV2,
  type AppearancePreviewSheetRecord,
  type AppearancePreviewStateRecord,
  type AppearancePreviewV2DirectionKey,
  type DirectionalOffsetProps,
  type DirectionKey,
  type HybridGuideDescriptor,
  type HybridGuideFamily,
  type HybridGuideLayer,
  type HybridGuideLayerColor,
  type HybridGuideLayerRole,
  type HybridOffsetField,
  type OffsetTransformProps,
} from './shared';
export { SheetPreviewTile, type SheetPreviewTileProps } from './SheetRenderer';
export {
  compositeTintedTile,
  normaliseColorList,
  TINT_CACHE_CAP,
  type TintCrop,
  type TintedTileResult,
  useTintedTile,
} from './tint';

// ── Live map_view character preview (Phase 1 / Step 7) ─────────────────────
export {
  CHARACTER_PREVIEW_BACKGROUND_STATES,
  CharacterPreviewMapView,
  type CharacterPreviewMapViewBackendData,
} from './CharacterPreviewMapView';

// ── Editor scaffold (Step 9) ────────────────────────────────────────────────
export { CommitBar } from './CommitBar';
export {
  APPEARANCE_PREVIEW_DIRECTION_KEYS,
  AppearancePreviewDirectionButtons,
  type AppearancePreviewDirectionKey,
  DirectionControls,
} from './DirectionControls';
export { DirtyIndicator } from './DirtyIndicator';
export { EditorShell } from './EditorShell';
export {
  copyHybridOffsetToAllDirections,
  DEFAULT_HYBRID_OFFSET_TRANSFORM,
  HybridOffsetControls,
  type HybridOffsetControlsProps,
  mirrorHybridOffsetTransform,
  updateHybridOffsetField,
} from './HybridOffsetControls';
export {
  buildHybridOffsetCssTransform,
  hybridOffsetAllowsField,
  type HybridOffsetDragDelta,
  HybridOffsetOverlay,
  type HybridOffsetOverlayProps,
  normaliseHybridOffsetTransform,
  resolveHybridOffsetDragDraft,
} from './HybridOffsetOverlay';
export { copyTextToClipboard, ModalDialog } from './ModalDialog';

// ── Close-safe commit controller (Remediation Step 1) ───────────────────────
export {
  type CommitController,
  useCommitController,
  type UseCommitControllerArgs,
} from './CommitController';
export {
  COMMIT_CODE_BUSY,
  COMMIT_CODE_DEGRADED_SIDECAR,
  COMMIT_CODE_TIMEOUT,
  COMMIT_DEFAULT_TIMEOUT_MS,
  type CommitContract,
  type CommitIntent,
  type CommitResult,
  type CommitStatus,
  type LastCommitResult,
} from './commitTypes';

// ── Provider + hook ─────────────────────────────────────────────────────────

interface AppearancePreviewContextValue {
  manifest: AppearancePreviewManifestV2 | null;
  loading: boolean;
  error: Error | null;
}

const defaultContext: AppearancePreviewContextValue = {
  manifest: null,
  loading: true,
  error: null,
};

const AppearancePreviewContext =
  createContext<AppearancePreviewContextValue>(defaultContext);

/**
 * Mounts the shared v2 manifest + sheet-preload pipeline for its subtree.
 * Safe to nest — the module-level preload cache dedupes.
 */
export function AppearancePreviewProvider(props: { children: ReactNode }) {
  const cached = getCachedAppearancePreviewManifestV2();
  const [manifest, setManifest] = useState<AppearancePreviewManifestV2 | null>(
    cached,
  );
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (manifest) {
      preloadSheets(manifest);
      return;
    }
    let cancelled = false;
    loadAppearancePreviewManifestV2()
      .then((loaded) => {
        if (cancelled) {
          return;
        }
        preloadSheets(loaded);
        setManifest(loaded);
      })
      .catch((err: Error) => {
        if (!cancelled) {
          setError(err);
        }
      });
    return () => {
      cancelled = true;
    };
  }, [manifest]);

  const value = useMemo<AppearancePreviewContextValue>(
    () => ({ manifest, loading: !manifest && !error, error }),
    [manifest, error],
  );

  return (
    <AppearancePreviewContext.Provider value={value}>
      {props.children}
    </AppearancePreviewContext.Provider>
  );
}

/**
 * Access the current v2 manifest. Null while the initial load is in flight.
 * Must be called inside an `<AppearancePreviewProvider>`.
 */
export function useAppearancePreview(): AppearancePreviewContextValue {
  return useContext(AppearancePreviewContext);
}

// ── Shared direction picker ─────────────────────────────────────────────────

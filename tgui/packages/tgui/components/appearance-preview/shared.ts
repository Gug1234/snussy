/**
 * Shared pure types for the v2 sheet-backed appearance preview contract.
 *
 * This module mirrors the canonical types in
 * `tools/build/appearance_preview/types.ts`; the runtime validator in
 * `tools/build/appearance_preview/schema/manifest_v2.ts` is the source of
 * truth for field-level invariants. The v1 (per-state, Python exporter)
 * surface was removed alongside the Python exporter.
 */

// ---------------------------------------------------------------------------
// v2 sheet-backed contract.
//
// CRITICAL: these types are a hand-mirrored copy of the canonical contract in
//   tools/build/appearance_preview/types.ts
// They live here because the tgui tsconfig (`tgui/tsconfig.json`) only
// includes `./packages`, so a direct import would silently bypass type
// checking. A drift detector test belongs in Step 14
// (`tgui/packages/tgui/components/appearance-preview/lookup.test.ts`) â€” until
// then, any change to the canonical types MUST be reflected here in the same
// commit, and the runtime validator
// (`tools/build/appearance_preview/schema/manifest_v2.ts`) is the source of
// truth for the field-level invariants.
// ---------------------------------------------------------------------------

/** v2 manifest version. Mirror of `APPEARANCE_PREVIEW_MANIFEST_VERSION`. */
export const APPEARANCE_PREVIEW_MANIFEST_VERSION = 2 as const;

/** Sole supported preview build backend. */
export const APPEARANCE_PREVIEW_BACKEND_ID = 'rustg_iconforge' as const;

/** Sole supported asset layout. */
export const APPEARANCE_PREVIEW_LAYOUT_KIND = 'sheet' as const;

/** Canonical per-direction key for v2 manifests. */
export type AppearancePreviewV2DirectionKey = 's' | 'n' | 'e' | 'w';

/** Default direction order when no override is supplied. */
export const APPEARANCE_PREVIEW_V2_DIRECTION_ORDER: readonly AppearancePreviewV2DirectionKey[] =
  ['s', 'n', 'e', 'w'] as const;

// ---------------------------------------------------------------------------
// Hybrid offset guide descriptors.
//
// These types describe the single active guide overlay used by offset editors.
// DM remains authoritative for the full character render; TGUI receives a
// resolved descriptor, renders the listed guide layer(s), mutates local draft
// transform props during interaction, and sends sanitized values only on save.
// ---------------------------------------------------------------------------

/** Direction key shared by manifest crops, editor drafts, and guide overlays. */
export type DirectionKey = AppearancePreviewV2DirectionKey;

/** Server-owned editor families that may emit one active guide descriptor. */
export type HybridGuideFamily =
  | 'taur_offsets'
  | 'custom_piercings'
  | 'intimate_accessory_offsets';

/** Transform field names that can be selectively enabled per descriptor. */
export type HybridOffsetField =
  | 'x'
  | 'y'
  | 'turn'
  | 'flip'
  | 'hide'
  | 'shrink'
  | 'above';

/** Semantic hint for layer ordering and control affordances. */
export type HybridGuideLayerRole = 'base' | 'metal' | 'gem' | 'guide';

/** Optional tint payload for a guide layer. Tinting is advisory, not final. */
export type HybridGuideLayerColor = string | readonly string[] | null;

/**
 * Draft transform props for one direction. Pixel coordinates use the BYOND
 * convention: positive x moves east/right, positive y moves north/up. The
 * overlay component will convert y into CSS screen-space when it renders.
 */
export interface OffsetTransformProps {
  x: number;
  y: number;
  turn: number;
  flip: boolean;
  hide: boolean;
  shrink: number;
  above?: boolean;
}

/** Complete directional draft map for editors that store all four directions. */
export type DirectionalOffsetProps = Record<DirectionKey, OffsetTransformProps>;

/**
 * One resolved sprite layer for the active guide. `iconState` maps directly to
 * `SheetPreviewTile.iconState`; `color` maps directly to its tint input.
 */
export interface HybridGuideLayer {
  iconState: string;
  color?: HybridGuideLayerColor;
  role?: HybridGuideLayerRole;
}

/**
 * Normalized client-side descriptor for one editable guide overlay.
 *
 * DM emits the canonical target identity, manifest category, resolved layer
 * icon states, native guide dimensions, and field gates. TGUI must not compose
 * runtime DMI state names from target ids once this descriptor is available.
 */
export interface HybridGuideDescriptor {
  id: string;
  family: HybridGuideFamily;
  targetKey: string;
  manifestCategory: string | null;
  direction: DirectionKey;
  layers: readonly HybridGuideLayer[];
  nativeWidth: number;
  nativeHeight: number;
  allowedFields: readonly HybridOffsetField[];
  approximateColor?: boolean;
}

/** Pixel-space crop rectangle within a packed sheet (zero-based, top-left). */
export interface AppearancePreviewCropRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

/** One packed sheet emitted by the build helper. */
export interface AppearancePreviewSheetRecord {
  id: string;
  family: string;
  path: string;
  width: number;
  height: number;
  tileWidth: number;
  tileHeight: number;
  contentHash: string;
}

/** Per-state record. One state -> one sheet tile, with its full direction set. */
export interface AppearancePreviewStateRecord {
  iconState: string;
  family: string;
  sheetId: string;
  crops: Partial<
    Record<AppearancePreviewV2DirectionKey, AppearancePreviewCropRect>
  >;
  variants?: Record<string, string>;
  flags?: readonly string[];
}

/** Adapter category as it appears in the v2 manifest. */
export interface AppearancePreviewCategoryRecord {
  key: string;
  scope: 'family' | 'catalog';
  states: readonly string[];
}

/** Build metadata block embedded in the v2 manifest. */
export interface AppearancePreviewBuildMetadata {
  builtAt: string;
  backend: typeof APPEARANCE_PREVIEW_BACKEND_ID;
  layout: typeof APPEARANCE_PREVIEW_LAYOUT_KIND;
  sourceFingerprint: string;
  adapterVersions: Record<string, string>;
}

/** v2 manifest root. Consumed by the Step 8 sheet-cropping renderer. */
export interface AppearancePreviewManifestV2 {
  version: typeof APPEARANCE_PREVIEW_MANIFEST_VERSION;
  backend: typeof APPEARANCE_PREVIEW_BACKEND_ID;
  layout: typeof APPEARANCE_PREVIEW_LAYOUT_KIND;
  canonicalLookupKey: 'icon_state';
  categoryOrder: readonly string[];
  categories: Record<string, AppearancePreviewCategoryRecord>;
  sheets: Record<string, AppearancePreviewSheetRecord>;
  states: Record<string, AppearancePreviewStateRecord>;
  build: AppearancePreviewBuildMetadata;
}

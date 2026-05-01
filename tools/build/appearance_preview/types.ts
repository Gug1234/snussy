/**
 * tools/build/appearance_preview/types.ts
 *
 * Shared TypeScript contract for the RustG/iconforge-backed appearance preview
 * build pipeline. Every module under `tools/build/appearance_preview/` consumes
 * these types: the bridge that schedules iconforge work, the staging layer that
 * publishes bundles atomically, the CLI entrypoint, and the per-family
 * adapters that will be added in Step 3.
 *
 * Step 1 scope: type surface only. No runtime behavior depends on these
 * definitions yet; downstream steps wire them up.
 *
 * Design notes:
 * - `BackendId` is fixed to the single supported backend per the greenfield
 *   spec. There is no Python fallback type and no compatibility variant.
 * - `LayoutKind` is fixed to `"sheet"` because per-state file layouts are
 *   removed by this refactor.
 * - Manifest version is exposed as a numeric literal so the schema validator
 *   in Step 4 can compare against it without string parsing.
 */

/** Single supported preview build backend. */
export type BackendId = "rustg_iconforge";

/** Single supported asset layout. Per-state files are no longer emitted. */
export type LayoutKind = "sheet";

/**
 * Manifest schema version. Bumped from v1 (per-state) to v2 (sheet-backed).
 * The DM-side define in `modular/code/datums/appearance_preview/_defines.dm`
 * must stay in lockstep with this constant; Step 4 enforces the bump.
 */
export const APPEARANCE_PREVIEW_MANIFEST_VERSION: 2 = 2;

/** The currently supported backend identifier as a runtime constant. */
export const APPEARANCE_PREVIEW_BACKEND_ID: BackendId = "rustg_iconforge";

/** The currently supported layout kind as a runtime constant. */
export const APPEARANCE_PREVIEW_LAYOUT_KIND: LayoutKind = "sheet";

/**
 * Canonical per-direction key used by both the manifest and the runtime.
 * Mirrors `APPEARANCE_PREVIEW_DIR_KEY_*` in the DM defines.
 */
export type DirectionKey = "s" | "n" | "e" | "w";

/** Canonical direction order used when no override is supplied. */
export const DEFAULT_DIRECTION_ORDER: readonly DirectionKey[] = [
  "s",
  "n",
  "e",
  "w",
] as const;

/**
 * Pixel-space crop rectangle within a packed sheet. Coordinates are zero-based
 * top-left origin. `width` and `height` should equal the adapter's tile size
 * unless the adapter explicitly emits a non-uniform tile (rare).
 */
export interface CropRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

/**
 * Adapter-supplied description of a single content family (taur offsets,
 * custom piercings, future markings, etc.). Step 2 finalizes the loader that
 * produces these records from `config/adapters.json`; Step 3 ships the first
 * concrete adapters.
 */
export interface AdapterRecord {
  /** Stable family key, e.g. `"taur_offsets"`, `"custom_piercings"`. */
  family: string;
  /**
   * Adapter implementation version. Participates in cache keys so adapter
   * logic changes invalidate cached sheets even if source DMIs are unchanged.
   */
  adapterVersion: string;
  /**
   * Tile size in pixels for every state this adapter emits. Mixed tile sizes
   * within a single adapter are not supported in v2.
   */
  tileSize: { width: number; height: number };
  /** Direction order this adapter expects every state to provide. */
  directionOrder: readonly DirectionKey[];
}

/**
 * One packed sheet emitted by the build helper. The build orchestrator decides
 * how many sheets a family needs based on tile count and a target maximum
 * sheet dimension.
 */
export interface SheetRecord {
  /** Stable identifier within the manifest, e.g. `"taur_offsets__0"`. */
  id: string;
  /** Owning adapter family. */
  family: string;
  /** Public-relative path to the packed sheet PNG, e.g. `"sheets/taur_offsets__0.png"`. */
  path: string;
  /** Sheet pixel dimensions. */
  width: number;
  height: number;
  /** Tile size used to slot states into the grid. */
  tileWidth: number;
  tileHeight: number;
  /** xxh64 fingerprint of the packed sheet bytes; used by cache + integrity checks. */
  contentHash: string;
}

/**
 * Per-state record. One state describes one icon-state at one tile position
 * within one sheet, with its full direction set. Optional variants point at
 * sibling state ids (e.g. an erect or gem variant).
 */
export interface StateRecord {
  /** Canonical lookup key (icon-state string, per the DM contract). */
  iconState: string;
  /** Owning adapter family. */
  family: string;
  /** Owning sheet id. */
  sheetId: string;
  /**
   * Per-direction crop rectangles. A state may declare a subset of the
   * four directions (e.g. piercing states that only render from `s`);
   * consumers fall back to the `s` crop when the requested direction is
   * absent. A state with *zero* declared crops is a hard validation error
   * caught by `validateManifestV2`.
   */
  crops: Partial<Record<DirectionKey, CropRect>>;
  /**
   * Optional named variant references, e.g. `{ erect: "...", gem: "..." }`.
   * Values are other `StateRecord.iconState` keys within the same family.
   */
  variants?: Record<string, string>;
  /**
   * Adapter-specific validation flags surfaced to the runtime so it can show
   * fallbacks instead of guessing. Examples: `multi_frame`, `non_uniform`.
   */
  flags?: readonly string[];
}

/**
 * Adapter category as it appears in the manifest. Mirrors the DM
 * `appearance_preview_manifest_category_*` taxonomy.
 */
export interface CategoryRecord {
  /** Category key, e.g. `"genitals"`, `"sticker"`. */
  key: string;
  /** Family-vs-catalog scope from the DM defines. */
  scope: "family" | "catalog";
  /** Ordered icon-state keys belonging to this category. */
  states: readonly string[];
}

/**
 * Build metadata block embedded in the manifest. Surfaces the backend used,
 * the source fingerprint, and adapter versions so a stale bundle can never be
 * mistaken for a current one at runtime.
 */
export interface BuildMetadata {
  /** ISO-8601 UTC timestamp of the manifest write. */
  builtAt: string;
  /** Backend identifier. */
  backend: BackendId;
  /** Layout kind. */
  layout: LayoutKind;
  /** xxh64 fingerprint over the sorted source file set. */
  sourceFingerprint: string;
  /** Map of `family -> adapterVersion` for every adapter that contributed. */
  adapterVersions: Record<string, string>;
}

/**
 * Manifest v2 root. Consumed by the TGUI runtime (Step 8) and validated by
 * the schema module (Step 4). The DM-side mirror lives in
 * `modular/code/datums/appearance_preview/manifest.dm`.
 */
export interface ManifestV2 {
  version: typeof APPEARANCE_PREVIEW_MANIFEST_VERSION;
  backend: BackendId;
  layout: LayoutKind;
  /** Canonical lookup key name; always `"icon_state"` in v2. */
  canonicalLookupKey: "icon_state";
  /** Ordered category keys preserved by the build pipeline. */
  categoryOrder: readonly string[];
  /** Categories keyed by `CategoryRecord.key`. */
  categories: Record<string, CategoryRecord>;
  /** Sheets keyed by `SheetRecord.id`. */
  sheets: Record<string, SheetRecord>;
  /** States keyed by `StateRecord.iconState`. */
  states: Record<string, StateRecord>;
  /** Build metadata block. */
  build: BuildMetadata;
}

/**
 * Per-stage timing emitted in the structured build summary. Stage names
 * intentionally mirror the analytics events listed in the spec
 * (scan, hash, sheet pack, publish).
 */
export type BuildStageName = "scan" | "hash" | "pack" | "publish";

/**
 * Structured build summary written by the orchestrator (Step 5) and consumed
 * by `build.ts` summary logging (Step 6). The shape matches the existing
 * Python exporter summary fields where possible to keep `build.ts` parsing
 * simple, but new v2 fields are additive.
 */
export interface BuildResult {
  status: "ok" | "failed";
  backend: BackendId;
  manifestVersion: typeof APPEARANCE_PREVIEW_MANIFEST_VERSION;
  /** Path the manifest was published to (after staging promotion). */
  manifestPath: string;
  metrics: {
    totalSeconds: number;
    stageSeconds: Record<BuildStageName, number>;
    cacheHits: number;
    cacheMisses: number;
    cacheHitRate: number;
    sheetCount: number;
    stateCount: number;
  };
  /** Optional human-readable failure detail when `status === "failed"`. */
  error?: string;
}

/**
 * File entry produced by adapter source discovery and consumed by
 * `fingerprintFiles` in `./adapters/source_scan.ts`. Kept as a minimal shape
 * so adapters can produce them cheaply during source discovery.
 */
export interface SourceFileEntry {
  /** Repo-relative path. */
  path: string;
  /** Optional precomputed mtime in ms; the bridge will stat if omitted. */
  mtimeMs?: number;
}

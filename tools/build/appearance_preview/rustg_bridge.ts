/**
 * tools/build/appearance_preview/rustg_bridge.ts
 *
 * TypeScript surface for scheduling RustG/iconforge work from the build
 * pipeline. Iconforge itself is a DM-side library call (see
 * `rustg_iconforge_generate` in `code/__DEFINES/rust_g.dm`) so this bridge
 * cannot invoke it directly from Bun. Instead it produces a deterministic
 * work plan (`IconforgeJobPlan`) that a DM-side runner — wired in Step 5 —
 * consumes during a headless build invocation.
 *
 * Step 1 scope:
 *   - Function signatures finalized.
 *   - `buildSheets` consumes a caller-supplied discovery map keyed by family
 *     so the scan/pack split in `build.ts` performs exactly one
 *     `discoverSources` pass per adapter (Remediation Step 2).
 *   - `emitManifest` is scaffolded with explicit `NotYetWired` markers so
 *     downstream steps have a stable surface to replace without churn.
 *
 * Bindings audit (`code/__DEFINES/rust_g.dm`):
 *   - `rustg_iconforge_generate(file_path, spritesheet_name, sprites, hash_icons)`
 *   - `rustg_iconforge_generate_async(...)` + `rustg_iconforge_check(job_id)`
 *   - `rustg_iconforge_cleanup`
 *   - `rustg_iconforge_cache_valid(input_hash, dmi_hashes, sprites)`
 * These cover everything Step 5 needs; no new DM bindings are added in this step.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { createHash } from "node:crypto";

import type {
  AdapterRecord,
  BuildMetadata,
  CropRect,
  DirectionKey,
  ManifestV2,
  SheetRecord,
  StateRecord,
} from "./types";
import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
} from "./types";
import type { Adapter, AdapterDiscovery, DiscoveredState } from "./adapters/contract";
import { AdapterMismatchError, SheetOverflowError } from "./errors";

/**
 * Deterministic plan for one iconforge invocation. Step 5's DM runner reads
 * a serialized JSON file containing one `IconforgeJobPlan` per sheet and
 * calls `rustg_iconforge_generate` for each.
 *
 * ### Load-bearing plan fields (Remediation Step 5)
 *
 * `outputPath` and `hashIcons` are consumed by the DM-side runtime
 * (`code/modules/asset_cache/assets/appearance_preview.dm::mount_bundle`)
 * AND by the headless materialize stage (`tools/build/appearance_preview/
 * materialize.ts`, Step 6). They are not merely informational:
 *
 *   - `outputPath` MUST equal the matching `SheetRecord.path` in the
 *     manifest for the same family. The DM runtime validates this and
 *     fails closed on any drift so a stale plan/manifest pair cannot
 *     silently publish an unreachable asset.
 *   - `hashIcons` is passed verbatim to `rustg_iconforge_generate`'s
 *     hash-icons flag at materialize time. It must be a boolean.
 *
 * Any future field added here must be treated as part of the DM-facing
 * contract: add a matching validator in `mount_bundle` and the
 * `inlined_keys.test.ts` drift test before shipping the bridge change.
 */
export interface IconforgeJobPlan {
  /** Spritesheet name passed to `rustg_iconforge_generate`. */
  spritesheetName: string;
  /**
   * Output PNG path inside the staging root. MUST match the corresponding
   * `SheetRecord.path` in the manifest (validated by the DM runtime).
   */
  outputPath: string;
  /**
   * `sprites` payload as documented in `rust_g.dm`. Opaque to the bridge —
   * the adapter is responsible for constructing it correctly.
   */
  sprites: unknown;
  /**
   * Whether to request DMI input hashing for cache validity checks.
   * Consumed by both the DM runtime validator and the materialize stage
   * (the latter forwards it to `rustg_iconforge_generate`).
   */
  hashIcons: boolean;
}

/** Aggregated input to the DM-side runner. */
export interface IconforgeWorkPlan {
  /** Stable token used to correlate logs and cache entries. */
  buildToken: string;
  /** Adapter records that contributed to this plan. */
  adapters: readonly AdapterRecord[];
  /** Per-sheet jobs in deterministic order. */
  jobs: readonly IconforgeJobPlan[];
}

// Source fingerprinting lives in `./adapters/source_scan.ts`
// (`fingerprintFiles`) where it is content-hashed rather than mtime-based.
// An earlier `hashSources` helper here folded `mtime` into the digest —
// that was deleted in Remediation Step 2 because a fresh git checkout and
// a local workspace produce different mtimes for identical content, which
// would silently invalidate the cache on CI.

/**
 * Maximum sheet dimension (px) before the orchestrator must split a family
 * across multiple sheets. Matches the conservative iconforge guidance and
 * leaves headroom under the typical GPU max texture size.
 */
export const MAX_SHEET_DIMENSION = 4096;

/** Filename used for the iconforge work plan inside the staging root. */
export const ICONFORGE_PLAN_FILENAME = "iconforge_plan.json";

/** Filename used for the manifest inside the staging root. */
export const MANIFEST_FILENAME = "manifest.json";

/** Subdirectory inside the staging root where packed sheet PNGs live. */
export const SHEETS_DIRNAME = "sheets";

/**
 * Compute the deterministic packed sheet layout for one adapter family.
 *
 * Layout (v2): a single grid per family. One column per state, four rows
 * (one per direction). Tile size comes from `adapter.record.tileSize`.
 *
 * Throws `SheetOverflowError` when the resulting grid exceeds
 * `MAX_SHEET_DIMENSION`. v2 of this layout intentionally does not split
 * across multiple sheets — current adapters comfortably fit. If a future
 * adapter overflows, this function is the chokepoint to extend.
 *
 * @returns ordered tuple of `(orderedKeys, sheet, perStateCrops)`.
 */
export function planFamilySheet(
  adapter: Adapter,
  discovery: AdapterDiscovery,
): {
  orderedKeys: readonly string[];
  sheet: SheetRecord;
  crops: ReadonlyMap<string, Record<DirectionKey, CropRect>>;
} {
  const family = adapter.record.family;
  const tileWidth = adapter.record.tileSize.width;
  const tileHeight = adapter.record.tileSize.height;
  const directions = adapter.record.directionOrder;

  // Index every discovered state by its canonical key for O(1) lookup.
  const byKey = new Map<string, DiscoveredState>();
  for (const state of discovery.states) {
    byKey.set(state.iconState, state);
  }

  const orderedKeys = adapter.orderStates(
    discovery.states.map((s) => s.iconState),
  );

  const sheetWidth = orderedKeys.length * tileWidth;
  const sheetHeight = directions.length * tileHeight;

  if (sheetWidth > MAX_SHEET_DIMENSION || sheetHeight > MAX_SHEET_DIMENSION) {
    throw new SheetOverflowError(
      family,
      `Family "${family}" packed sheet ${sheetWidth}x${sheetHeight}px ` +
        `exceeds MAX_SHEET_DIMENSION (${MAX_SHEET_DIMENSION}).`,
    );
  }

  const crops = new Map<string, Record<DirectionKey, CropRect>>();
  for (let col = 0; col < orderedKeys.length; col++) {
    const key = orderedKeys[col];
    const perDir: Partial<Record<DirectionKey, CropRect>> = {};
    for (let row = 0; row < directions.length; row++) {
      perDir[directions[row]] = {
        x: col * tileWidth,
        y: row * tileHeight,
        width: tileWidth,
        height: tileHeight,
      };
    }
    crops.set(key, perDir as Record<DirectionKey, CropRect>);
  }

  // Deterministic content hash over the inputs that uniquely determine the
  // packed PNG bytes: family + adapter version + ordered state list + the
  // sourceState the iconforge runner will read for each tile. Sheet bytes
  // are produced by the DM-side runner (Step 7) so we hash the plan inputs
  // here rather than the bytes — cache validity stays correct because the
  // inputs are exactly what RustG iconforge consumes.
  const planHash = createHash("sha256");
  planHash.update(family);
  planHash.update("\0");
  planHash.update(adapter.record.adapterVersion);
  planHash.update("\0");
  for (const key of orderedKeys) {
    const state = byKey.get(key);
    if (!state) {
      // orderStates returned a key not present in discovery — adapter bug.
      throw new SheetOverflowError(
        family,
        `Adapter returned ordered key "${key}" not present in discovery.`,
      );
    }
    planHash.update(key);
    planHash.update("=");
    planHash.update(state.iconFile);
    planHash.update(":");
    planHash.update(state.sourceState);
    planHash.update("\0");
  }
  const contentHash = planHash.digest("hex").slice(0, 16);

  const sheet: SheetRecord = {
    id: `${family}__0`,
    family,
    path: `${SHEETS_DIRNAME}/${family}__0.png`,
    width: sheetWidth,
    height: sheetHeight,
    tileWidth,
    tileHeight,
    contentHash,
  };

  return { orderedKeys, sheet, crops };
}

/**
 * Build the iconforge work plan + manifest records for every adapter, then
 * write `iconforge_plan.json` into the staging root for the DM-side runner
 * (Step 7) to consume. Returns the records needed to assemble the final
 * manifest.
 *
 * Note on the architectural split: iconforge itself is a DM library call,
 * so actual PNG encoding happens at world boot from the plan written here.
 * This function's job is to produce a deterministic, validatable plan +
 * manifest pair so the orchestrator can publish atomically without ever
 * holding partial bundles.
 *
 * ## Remediation Step 2 — single-discovery contract
 *
 * Prior revisions of this function re-invoked `adapter.discoverSources(
 * process.cwd())` here, duplicating the scan that `build.ts` had already
 * performed and silently diverging from the scan set whenever
 * `options.repoRoot !== process.cwd()`. The cache key was computed from
 * the `repoRoot` scan while the packed plan referenced the `cwd` scan, so
 * the published manifest could reference sources that were never
 * fingerprinted. The fix is to hand in the already-computed discovery map
 * (keyed by `adapter.record.family`) plus the canonical `repoRoot` so any
 * future source-resolution lookup here uses the same root. Any missing
 * entry in the map is an integration bug — surface as
 * `AdapterMismatchError` before any staging I/O runs.
 *
 * @param adapters Registered adapters in load order.
 * @param discoveries Discovery results keyed by `adapter.record.family`.
 *                    Must contain an entry for every adapter.
 * @param repoRoot Absolute repo root used by callers for path resolution.
 *                 Reserved for future use; currently documented so callers
 *                 cannot silently revert to `process.cwd()`.
 * @param stagingRoot Absolute staging directory to write `iconforge_plan.json`.
 */
export function buildSheets(
  adapters: readonly Adapter[],
  discoveries: ReadonlyMap<string, AdapterDiscovery>,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars -- load-bearing
  repoRoot: string,
  stagingRoot: string,
): {
  sheets: SheetRecord[];
  states: StateRecord[];
  plan: IconforgeWorkPlan;
} {
  const sheets: SheetRecord[] = [];
  const states: StateRecord[] = [];
  const jobs: IconforgeJobPlan[] = [];

  // `repoRoot` is accepted and documented so callers cannot silently
  // revert to `process.cwd()` on a future refactor. No source lookup
  // currently needs it (adapters resolve paths during discovery), but
  // reserving the parameter keeps the public contract stable.
  void repoRoot;

  for (const adapter of adapters) {
    const family = adapter.record.family;
    const discovery = discoveries.get(family);
    if (!discovery) {
      // Caller did not run discovery for this adapter. Fail fast rather
      // than silently re-scanning from the wrong root.
      throw new AdapterMismatchError(
        family,
        `buildSheets: no AdapterDiscovery supplied for family "${family}". ` +
          `Ensure the scan stage populated the discoveries map for every ` +
          `registered adapter before calling buildSheets.`,
      );
    }
    const { orderedKeys, sheet, crops } = planFamilySheet(adapter, discovery);
    sheets.push(sheet);

    // Emit a StateRecord per ordered key.
    const byKey = new Map<string, DiscoveredState>();
    for (const s of discovery.states) byKey.set(s.iconState, s);

    for (const key of orderedKeys) {
      const src = byKey.get(key);
      if (!src) continue;
      const cropMap = crops.get(key);
      if (!cropMap) continue;
      states.push({
        iconState: key,
        family,
        sheetId: sheet.id,
        crops: cropMap,
        variants: src.variants,
        flags: src.flags,
      });
    }

    // One iconforge job per family. The `sprites` payload mirrors the
    // shape documented in `rust_g.dm` line 211-220. Position-in-sheet is
    // implicit: jobs preserve `orderedKeys` order; the DM runner places
    // tile N at column N. Direction frames live as separate sprite entries
    // because iconforge packs per-frame, and we want one row per direction.
    const sprites: Record<string, unknown> = {};
    const directions = adapter.record.directionOrder;
    for (let col = 0; col < orderedKeys.length; col++) {
      const key = orderedKeys[col];
      const src = byKey.get(key);
      if (!src) continue;
      for (let row = 0; row < directions.length; row++) {
        const dir = directions[row];
        sprites[spritesKey(key, dir)] = {
          icon_file: src.iconFile,
          icon_state: src.sourceState,
          dir: byondDirCode(dir),
          frame: 1,
          transform: src.transform ?? [],
        };
      }
    }

    jobs.push({
      spritesheetName: family,
      outputPath: `${SHEETS_DIRNAME}/${family}__0.png`,
      sprites,
      hashIcons: true,
    });
  }

  const plan: IconforgeWorkPlan = {
    buildToken: createHash("sha256")
      .update(sheets.map((s) => s.contentHash).join("|"))
      .digest("hex")
      .slice(0, 16),
    adapters: adapters.map((a) => a.record),
    jobs,
  };

  // Ensure the sheets/ subdirectory exists so the DM runner can write into
  // it without an extra mkdir. The plan JSON itself sits at the staging root.
  fs.mkdirSync(path.join(stagingRoot, SHEETS_DIRNAME), { recursive: true });
  fs.writeFileSync(
    path.join(stagingRoot, ICONFORGE_PLAN_FILENAME),
    JSON.stringify(plan, null, 2),
    "utf8",
  );

  return { sheets, states, plan };
}

/**
 * Sprite key used inside one iconforge job's `sprites` map. Encoding the
 * direction in the key keeps every frame independently addressable on the
 * DM side without requiring iconforge per-state animation support.
 */
function spritesKey(iconState: string, dir: DirectionKey): string {
  return `${iconState}__${dir}`;
}

/**
 * Map our `DirectionKey` enum to the BYOND numeric direction code that
 * iconforge expects in the `dir` field. Mirrors `code/__DEFINES/dcs/dirs.dm`.
 */
function byondDirCode(dir: DirectionKey): number {
  switch (dir) {
    case "s": return 2;
    case "n": return 1;
    case "e": return 4;
    case "w": return 8;
  }
}

/**
 * Emit a manifest v2 JSON file into the staging root.
 *
 * @returns Absolute path of the written manifest file.
 */
export function emitManifest(
  records: {
    sheets: readonly SheetRecord[];
    states: readonly StateRecord[];
    categoryOrder: readonly string[];
    categories: ManifestV2["categories"];
  },
  adapters: readonly AdapterRecord[],
  sourceFingerprint: string,
  stagingRoot: string,
): string {
  const manifest = assembleManifest(records, adapters, sourceFingerprint);
  const target = path.join(stagingRoot, MANIFEST_FILENAME);
  fs.writeFileSync(target, JSON.stringify(manifest, null, 2), "utf8");
  return path.resolve(target);
}

/**
 * Build a `BuildMetadata` block. Pure helper, safe to use today by tests
 * that need a synthetic manifest.
 *
 * @param adapters Adapter records to record versions for.
 * @param sourceFingerprint Source set fingerprint.
 */
export function buildMetadata(
  adapters: readonly AdapterRecord[],
  sourceFingerprint: string,
): BuildMetadata {
  const adapterVersions: Record<string, string> = {};
  for (const adapter of adapters) {
    adapterVersions[adapter.family] = adapter.adapterVersion;
  }
  return {
    builtAt: new Date().toISOString(),
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    sourceFingerprint,
    adapterVersions,
  };
}

/**
 * Assemble a synthetic `ManifestV2` from supplied records. Used by Step 4's
 * schema tests today and by Step 5's orchestrator once adapters land. Does
 * NOT validate inputs — that is the schema validator's job.
 *
 * @param records Sheets + states + categories to embed verbatim.
 * @param adapters Adapter records used for build metadata.
 * @param sourceFingerprint Source set fingerprint.
 */
export function assembleManifest(
  records: {
    sheets: readonly SheetRecord[];
    states: readonly StateRecord[];
    categoryOrder: readonly string[];
    categories: ManifestV2["categories"];
  },
  adapters: readonly AdapterRecord[],
  sourceFingerprint: string,
): ManifestV2 {
  const sheets: Record<string, SheetRecord> = {};
  for (const sheet of records.sheets) {
    sheets[sheet.id] = sheet;
  }
  const states: Record<string, StateRecord> = {};
  for (const state of records.states) {
    states[state.iconState] = state;
  }
  return {
    version: APPEARANCE_PREVIEW_MANIFEST_VERSION,
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    layout: APPEARANCE_PREVIEW_LAYOUT_KIND,
    canonicalLookupKey: "icon_state",
    categoryOrder: records.categoryOrder,
    categories: records.categories,
    sheets,
    states,
    build: buildMetadata(adapters, sourceFingerprint),
  };
}

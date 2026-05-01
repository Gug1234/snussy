/**
 * tools/build/appearance_preview/build.ts
 *
 * End-to-end orchestrator for the RustG/iconforge appearance preview build.
 *
 * Pipeline:
 *   1. scan    — load adapter config + run `discoverSources` per adapter.
 *   2. hash    — fingerprint every adapter's source set; compute cache key.
 *   3. pack    — `planFamilySheet` per family; write `iconforge_plan.json`.
 *   4. publish — write manifest, validate v2 schema, atomic publish.
 *
 * Cache hit short-circuits steps 3-4. Per the spec ("Cache keys should
 * include source fingerprints, manifest version, backend identifier, and
 * adapter version"), the cache key folds in every invalidation axis.
 *
 * Atomic publish via `staging.ts` is the WinError 145 fix — the live tree
 * is never deleted before its replacement is in place. Any failure rolls
 * back the staging tree without touching the previous bundle.
 */

import * as fs from "node:fs";
import * as path from "node:path";

import {
  buildSheets,
  emitManifest,
  MANIFEST_FILENAME,
} from "./rustg_bridge";
import {
  computeCacheKey,
  isCacheHit,
  readCache,
  writeCache,
} from "./cache";
import {
  loadAdapters,
} from "./adapters";
import { fingerprintFiles } from "./adapters/source_scan";
import {
  AppearancePreviewBuildError,
  ManifestInvalidError,
} from "./errors";
import { validateManifestV2 } from "./schema/manifest_v2";
import {
  createStagingRoot,
  publishStaging,
  rollbackStaging,
} from "./staging";
import {
  createMetricsBuilder,
  emitSummary,
  makeFailedResult,
  makeOkResult,
} from "./summary";
import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type BuildResult,
  type CategoryRecord,
  type ManifestV2,
  type SourceFileEntry,
} from "./types";
import type { Adapter, AdapterDiscovery } from "./adapters/contract";

/** Public orchestrator options. */
export interface BuildAppearancePreviewsOptions {
  /** Path to `adapters.json`. */
  adapterConfig: string;
  /** Public bundle target (e.g. `tgui/public/appearance_preview`). */
  publicRoot: string;
  /** Optional persistent cache directory. Cache disabled when omitted. */
  cacheDir?: string | null;
  /**
   * Optional repo root used for adapter source resolution. Defaults to
   * `process.cwd()` so the CLI can run from the repo root with no flag.
   */
  repoRoot?: string;
  /**
   * If true, a successful build still emits no `summary.json` line on
   * stdout. Used by tests that consume the `BuildResult` directly.
   */
  silent?: boolean;
}

/**
 * Run the full build pipeline. Always emits exactly one `BuildResult`,
 * either via `emitSummary` (when `silent` is false) or via the return
 * value. Never throws — failures are wrapped into a `failed` result.
 */
export async function buildAppearancePreviews(
  options: BuildAppearancePreviewsOptions,
): Promise<BuildResult> {
  const repoRoot = path.resolve(options.repoRoot ?? process.cwd());
  const publicRoot = path.resolve(options.publicRoot);
  const metrics = createMetricsBuilder();

  // ===== scan =====
  metrics.startStage("scan");
  let adapters: readonly Adapter[];
  let discoveries: Map<string, AdapterDiscovery>;
  try {
    adapters = loadAdapters(options.adapterConfig);
    discoveries = new Map();
    for (const adapter of adapters) {
      discoveries.set(adapter.record.family, adapter.discoverSources(repoRoot));
    }
  } catch (err) {
    return finishFailure(metrics, publicRoot, err, options.silent);
  } finally {
    metrics.endStage("scan");
  }

  // ===== hash =====
  metrics.startStage("hash");
  let sourceFingerprint: string;
  let cacheKey: string;
  try {
    const allSources: SourceFileEntry[] = [];
    for (const discovery of discoveries.values()) {
      for (const entry of discovery.sources) allSources.push(entry);
    }
    sourceFingerprint = fingerprintFiles(repoRoot, allSources);
    const adapterVersions: Record<string, string> = {};
    for (const adapter of adapters) {
      adapterVersions[adapter.record.family] = adapter.record.adapterVersion;
    }
    cacheKey = computeCacheKey({
      manifestVersion: APPEARANCE_PREVIEW_MANIFEST_VERSION,
      backend: APPEARANCE_PREVIEW_BACKEND_ID,
      adapterVersions,
      sourceFingerprint,
    });
  } catch (err) {
    return finishFailure(metrics, publicRoot, err, options.silent);
  } finally {
    metrics.endStage("hash");
  }

  // ===== cache check =====
  if (options.cacheDir) {
    const record = readCache(options.cacheDir);
    if (isCacheHit(record, cacheKey, options.cacheDir)) {
      metrics.recordCacheHit(adapters.length);
      const cachedManifest = readCachedManifestCounts(record.manifestPath);
      if (cachedManifest) {
        metrics.recordCounts(cachedManifest.sheetCount, cachedManifest.stateCount);
      }
      const result = makeOkResult({
        backend: APPEARANCE_PREVIEW_BACKEND_ID,
        manifestPath: record.manifestPath,
        metrics: metrics.finalize(),
      });
      if (!options.silent) emitSummary(result);
      return result;
    }
  }
  metrics.recordCacheMiss(adapters.length);

  // ===== pack + publish =====
  let stagingRoot: string | null = null;
  try {
    stagingRoot = createStagingRoot(publicRoot);

    metrics.startStage("pack");
    // Remediation Step 2: hand buildSheets the already-computed discoveries
    // map + resolved repoRoot so there is exactly one discoverSources pass
    // per build and cwd coupling is eliminated.
    const { sheets, states } = buildSheets(
      adapters,
      discoveries,
      repoRoot,
      stagingRoot,
    );
    metrics.endStage("pack");

    // Assemble category records from each adapter's previewMetadata.
    const categories: Record<string, CategoryRecord> = {};
    const categoryOrder: string[] = [];
    for (const adapter of adapters) {
      const discovery = discoveries.get(adapter.record.family)!;
      const meta = adapter.previewMetadata(discovery);
      for (const cat of meta.categories) {
        if (categories[cat.key]) {
          // Two adapters claim the same category key. v2 disallows this so
          // ownership is never ambiguous.
          throw new ManifestInvalidError(
            `Category "${cat.key}" claimed by multiple adapters; ` +
              `at least "${adapter.record.family}" duplicates an earlier owner.`,
          );
        }
        categories[cat.key] = cat;
        categoryOrder.push(cat.key);
      }
    }

    metrics.startStage("publish");
    const stagedManifestPath = emitManifest(
      {
        sheets,
        states,
        categoryOrder,
        categories,
      },
      adapters.map((a) => a.record),
      sourceFingerprint,
      stagingRoot,
    );

    // Round-trip the manifest through the v2 validator before publish so a
    // schema bug never reaches the public tree.
    const manifestRaw = JSON.parse(
      fs.readFileSync(stagedManifestPath, "utf8"),
    ) as unknown;
    validateManifestV2(manifestRaw);

    const publishResult = publishStaging(publicRoot, stagingRoot);
    stagingRoot = null; // Promoted; no longer subject to rollback.
    metrics.endStage("publish");

    metrics.recordCounts(sheets.length, states.length);

    const finalManifestPath = path.join(
      publishResult.publishedPath,
      MANIFEST_FILENAME,
    );

    if (options.cacheDir) {
      try {
        writeCache(options.cacheDir, cacheKey, finalManifestPath);
      } catch (err) {
        // Cache write failure must not invalidate a successful publish; log
        // to stderr and continue.
        process.stderr.write(
          `appearance_preview: cache write failed: ${(err as Error).message}\n`,
        );
      }
    }

    const result = makeOkResult({
      backend: APPEARANCE_PREVIEW_BACKEND_ID,
      manifestPath: finalManifestPath,
      metrics: metrics.finalize(),
    });
    if (!options.silent) emitSummary(result);
    return result;
  } catch (err) {
    if (stagingRoot) rollbackStaging(stagingRoot);
    return finishFailure(metrics, publicRoot, err, options.silent);
  }
}

/**
 * Read sheet/state counts from a previously-published manifest so cache hits
 * still report accurate `sheetCount` / `stateCount` in the summary. Failure
 * is treated as "unknown" rather than aborting — the cache hit is still valid.
 */
function readCachedManifestCounts(
  manifestPath: string,
): { sheetCount: number; stateCount: number } | null {
  try {
    const parsed = JSON.parse(fs.readFileSync(manifestPath, "utf8")) as ManifestV2;
    return {
      sheetCount: Object.keys(parsed.sheets ?? {}).length,
      stateCount: Object.keys(parsed.states ?? {}).length,
    };
  } catch {
    return null;
  }
}

/** Wrap an error into a `failed` result and emit it once. */
function finishFailure(
  metrics: ReturnType<typeof createMetricsBuilder>,
  publicRoot: string,
  err: unknown,
  silent: boolean | undefined,
): BuildResult {
  const message =
    err instanceof AppearancePreviewBuildError
      ? `${err.code}: ${err.message}`
      : err instanceof Error
        ? err.message
        : String(err);
  const result = makeFailedResult({
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    manifestPath: path.join(publicRoot, MANIFEST_FILENAME),
    metrics: metrics.finalize(),
    error: message,
  });
  if (!silent) emitSummary(result);
  return result;
}

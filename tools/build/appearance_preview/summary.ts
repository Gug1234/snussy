/**
 * tools/build/appearance_preview/summary.ts
 *
 * Structured build summary writer. The orchestrator (`build.ts`) calls
 * `emitSummary` exactly once per invocation, regardless of success or
 * failure, so `tools/build/build.ts` (Step 6) can parse a single trailing
 * JSON line of stdout to obtain the full `BuildResult`.
 *
 * Output contract:
 *   - One `BuildResult` JSON object printed as the LAST stdout line.
 *   - All preceding stdout/stderr is human-readable progress logging.
 *
 * `extractBuildResult` is the symmetric reader, exported so tests and the
 * top-level `build.ts` can share the same parser.
 */

import type {
  BackendId,
  BuildResult,
  BuildStageName,
} from "./types";
import { APPEARANCE_PREVIEW_MANIFEST_VERSION } from "./types";

/** Mutable accumulator returned by `createMetricsBuilder`. */
export interface MetricsBuilder {
  /** Mark the start of a stage. Pairs with `endStage(name)`. */
  startStage(name: BuildStageName): void;
  /** Mark the end of a stage. Records elapsed seconds. */
  endStage(name: BuildStageName): void;
  /** Increment cache hit count by `n` (default 1). */
  recordCacheHit(n?: number): void;
  /** Increment cache miss count by `n` (default 1). */
  recordCacheMiss(n?: number): void;
  /** Record final aggregate counts. */
  recordCounts(sheetCount: number, stateCount: number): void;
  /** Finalize and produce the `metrics` block of `BuildResult`. */
  finalize(): BuildResult["metrics"];
}

/**
 * Create a fresh metrics builder. Stage timings default to zero so a stage
 * that was never entered (e.g. `pack` skipped on a cache hit) still appears
 * in the summary as `0`.
 */
export function createMetricsBuilder(): MetricsBuilder {
  const stageSeconds: Record<BuildStageName, number> = {
    scan: 0,
    hash: 0,
    pack: 0,
    publish: 0,
  };
  const stageStartedAt = new Map<BuildStageName, number>();
  let cacheHits = 0;
  let cacheMisses = 0;
  let sheetCount = 0;
  let stateCount = 0;
  const totalStart = performance.now();

  return {
    startStage(name) {
      stageStartedAt.set(name, performance.now());
    },
    endStage(name) {
      const started = stageStartedAt.get(name);
      if (started === undefined) return;
      stageSeconds[name] += (performance.now() - started) / 1000;
      stageStartedAt.delete(name);
    },
    recordCacheHit(n = 1) {
      cacheHits += n;
    },
    recordCacheMiss(n = 1) {
      cacheMisses += n;
    },
    recordCounts(sheets, states) {
      sheetCount = sheets;
      stateCount = states;
    },
    finalize() {
      const totalSeconds = (performance.now() - totalStart) / 1000;
      const total = cacheHits + cacheMisses;
      const cacheHitRate = total === 0 ? 0 : cacheHits / total;
      return {
        totalSeconds,
        stageSeconds,
        cacheHits,
        cacheMisses,
        cacheHitRate,
        sheetCount,
        stateCount,
      };
    },
  };
}

/** Construct an `ok` `BuildResult`. */
export function makeOkResult(args: {
  backend: BackendId;
  manifestPath: string;
  metrics: BuildResult["metrics"];
}): BuildResult {
  return {
    status: "ok",
    backend: args.backend,
    manifestVersion: APPEARANCE_PREVIEW_MANIFEST_VERSION,
    manifestPath: args.manifestPath,
    metrics: args.metrics,
  };
}

/** Construct a `failed` `BuildResult`. */
export function makeFailedResult(args: {
  backend: BackendId;
  manifestPath: string;
  metrics: BuildResult["metrics"];
  error: string;
}): BuildResult {
  return {
    status: "failed",
    backend: args.backend,
    manifestVersion: APPEARANCE_PREVIEW_MANIFEST_VERSION,
    manifestPath: args.manifestPath,
    metrics: args.metrics,
    error: args.error,
  };
}

/**
 * Print the final summary as a single stdout line. Always called exactly
 * once per orchestrator invocation. The trailing newline lets line-based
 * shell tools (`tail -1`, etc.) round-trip the JSON without buffering.
 */
export function emitSummary(result: BuildResult): void {
  process.stdout.write(`${JSON.stringify(result)}\n`);
}

/**
 * Locate the trailing JSON object in captured stdout. Mirrors the parser
 * already used in `tools/build/build.ts` for the Python exporter so the
 * Step 6 swap is a one-line change. Returns `null` if no parseable object
 * is present (treat as a build failure).
 */
export function extractBuildResult(stdout: string): BuildResult | null {
  const lines = stdout
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line.length > 0);
  for (let i = lines.length - 1; i >= 0; i -= 1) {
    try {
      return JSON.parse(lines[i]) as BuildResult;
    } catch {
      continue;
    }
  }
  return null;
}

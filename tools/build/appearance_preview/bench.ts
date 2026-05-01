/**
 * tools/build/appearance_preview/bench.ts
 *
 * Benchmark harness for the RustG/iconforge appearance-preview build.
 *
 * Measures two regimes:
 *   1. Cold build — cache + public bundle wiped before each iteration.
 *   2. Warm build — cache retained; adapter sources untouched. Expected to
 *      short-circuit via `isCacheHit` and skip pack/publish entirely.
 *
 * Emits a single JSON line per regime on stdout so CI can capture the
 * numbers without parsing free-form logs. Honors `--runs <n>` (default 3)
 * and `--out <file>` for a structured summary written to disk.
 *
 * Usage:
 *   bun tools/build/appearance_preview/bench.ts \
 *     [--adapter-config <path>] [--public-root <path>] \
 *     [--cache-dir <path>] [--runs <n>] [--out <file>]
 *
 * Defaults match `cli.ts` so invoking with no flags benches the canonical
 * build target.
 */

import * as fs from "node:fs";
import * as path from "node:path";

import { buildAppearancePreviews } from "./build";
import {
  materializeAppearancePreviews,
  type MaterializeResult,
} from "./materialize";
import type { BuildResult } from "./types";

interface BenchOptions {
  adapterConfig: string;
  publicRoot: string;
  cacheDir: string;
  runs: number;
  outFile: string | null;
  /**
   * When set, each cold iteration runs the headless materialize stage
   * after orchestrator publish + PNG wipe. This records the real PNG
   * encode wall-time players pay at world boot, closing the "cold bench
   * only measures manifest publication" gap called out by the Step 12
   * review findings. Off by default because it requires a pre-built
   * `roguetown.dmb`; Juke / CI invocations should pass --materialize.
   */
  materialize: boolean;
  /** Path to a pre-built DMB. Required when --materialize is set. */
  dmbPath: string | null;
  /** Optional explicit dreamdaemon.exe path; falls through to resolver. */
  dreamDaemonPath: string | null;
}

interface RunSample {
  iteration: number;
  status: BuildResult["status"];
  totalSeconds: number;
  stageSeconds: BuildResult["metrics"]["stageSeconds"];
  cacheHits: number;
  cacheMisses: number;
  sheetCount: number;
  stateCount: number;
  /**
   * Wall-clock seconds spent in the headless materialize stage for this
   * iteration, or null when the stage did not run (warm regime, or
   * --materialize not supplied for a cold run). This is the number that
   * actually reflects PNG-encode cost.
   */
  materializeSeconds: number | null;
  /**
   * Status of the materialize run for this iteration. `ok` on success,
   * `failed` when the DM sidecar reported !ok, `skipped` when disabled.
   */
  materializeStatus: "ok" | "failed" | "skipped";
  /** PNG count reported by the DM materialize proc's status sidecar. */
  materializeSheetCount: number;
}

interface RegimeStats {
  regime: "cold" | "warm";
  runs: number;
  samples: RunSample[];
  /** Wall-clock seconds, computed over successful samples only. */
  stats: {
    min: number;
    max: number;
    mean: number;
    median: number;
  };
  /**
   * Materialize wall-clock statistics, computed over successful
   * materialize samples only. Null when materialize was disabled for
   * every run in the regime.
   */
  materializeStats: {
    min: number;
    max: number;
    mean: number;
    median: number;
  } | null;
  cacheHitRate: number;
}

function parseArgs(argv: readonly string[]): BenchOptions {
  const opts: BenchOptions = {
    adapterConfig: "tools/build/appearance_preview/config/adapters.json",
    publicRoot: "tgui/public/appearance_preview",
    cacheDir: "tools/build/tmp/appearance_preview_cache",
    runs: 3,
    outFile: null,
    materialize: false,
    dmbPath: null,
    dreamDaemonPath: null,
  };
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    const next = argv[i + 1];
    switch (flag) {
      case "--adapter-config":
        opts.adapterConfig = next;
        i++;
        break;
      case "--public-root":
        opts.publicRoot = next;
        i++;
        break;
      case "--cache-dir":
        opts.cacheDir = next;
        i++;
        break;
      case "--runs": {
        const n = Number.parseInt(next ?? "", 10);
        if (!Number.isFinite(n) || n < 1) {
          throw new Error(`--runs expects a positive integer, got: ${next}`);
        }
        opts.runs = n;
        i++;
        break;
      }
      case "--out":
        opts.outFile = next;
        i++;
        break;
      case "--materialize":
        // Boolean switch; the DMB path is required separately so a bare
        // --materialize fails loudly rather than silently skipping.
        opts.materialize = true;
        break;
      case "--no-materialize":
        opts.materialize = false;
        break;
      case "--dmb":
        opts.dmbPath = next;
        i++;
        break;
      case "--dreamdaemon":
        opts.dreamDaemonPath = next;
        i++;
        break;
      default:
        throw new Error(`Unknown flag: ${flag}`);
    }
  }
  if (opts.materialize && !opts.dmbPath) {
    throw new Error(
      "--materialize requires --dmb <path-to-roguetown.dmb>. Build it with " +
        "`.\\tools\\build\\build.bat -DLOCALTEST` first.",
    );
  }
  return opts;
}

/**
 * Best-effort directory wipe. Missing directories are not an error.
 * Used between cold runs to force the orchestrator back through the
 * pack/publish path.
 */
function wipeDir(target: string): void {
  if (!fs.existsSync(target)) return;
  fs.rmSync(target, { recursive: true, force: true });
}

function summarize(samples: readonly RunSample[]): RegimeStats["stats"] {
  const successful = samples
    .filter((s) => s.status === "ok")
    .map((s) => s.totalSeconds)
    .sort((a, b) => a - b);
  if (successful.length === 0) {
    return { min: 0, max: 0, mean: 0, median: 0 };
  }
  const sum = successful.reduce((acc, v) => acc + v, 0);
  const mid = Math.floor(successful.length / 2);
  return {
    min: successful[0],
    max: successful[successful.length - 1],
    mean: sum / successful.length,
    median:
      successful.length % 2 === 0
        ? (successful[mid - 1] + successful[mid]) / 2
        : successful[mid],
  };
}

/**
 * Summarise materialize wall-times across the samples. Returns null when
 * materialize was skipped for every sample so the regime report stays
 * honest about what it did and didn't measure.
 */
function summarizeMaterialize(
  samples: readonly RunSample[],
): RegimeStats["materializeStats"] {
  const successful = samples
    .filter((s) => s.materializeStatus === "ok" && s.materializeSeconds != null)
    .map((s) => s.materializeSeconds as number)
    .sort((a, b) => a - b);
  if (successful.length === 0) return null;
  const sum = successful.reduce((acc, v) => acc + v, 0);
  const mid = Math.floor(successful.length / 2);
  return {
    min: successful[0],
    max: successful[successful.length - 1],
    mean: sum / successful.length,
    median:
      successful.length % 2 === 0
        ? (successful[mid - 1] + successful[mid]) / 2
        : successful[mid],
  };
}

/**
 * Wipe every prebuilt sheet PNG declared by the just-published manifest.
 * Required between a successful orchestrator publish and the materialize
 * call so we measure a true cold PNG encode rather than DM's fast-path
 * "sheets already present — register and move on" branch.
 */
function wipeManifestSheets(publicRoot: string): void {
  const manifestPath = path.join(publicRoot, "manifest.json");
  if (!fs.existsSync(manifestPath)) return;
  let manifest: { sheets?: Record<string, { path?: string }> };
  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  } catch {
    return;
  }
  const sheets = manifest.sheets ?? {};
  for (const entry of Object.values(sheets)) {
    const rel = entry?.path;
    if (!rel || typeof rel !== "string") continue;
    const abs = path.join(publicRoot, rel);
    try {
      fs.rmSync(abs, { force: true });
    } catch {
      // best-effort; the materialize stage will overwrite on success.
    }
  }
}

async function runRegime(
  regime: "cold" | "warm",
  opts: BenchOptions,
): Promise<RegimeStats> {
  const samples: RunSample[] = [];
  let totalHits = 0;
  let totalLookups = 0;
  for (let i = 0; i < opts.runs; i++) {
    if (regime === "cold") {
      // Cold regime wipes both the cache and the published bundle so the
      // orchestrator must redo scan → hash → pack → publish every iteration.
      wipeDir(opts.cacheDir);
      wipeDir(opts.publicRoot);
    }
    const result = await buildAppearancePreviews({
      adapterConfig: opts.adapterConfig,
      publicRoot: opts.publicRoot,
      cacheDir: opts.cacheDir,
      silent: true,
    });
    const m = result.metrics;

    // Materialize stage — only runs on cold iterations with a DMB path.
    // Warm iterations never wipe PNGs, so invoking materialize there
    // would measure the fast-path "sheets already present" branch rather
    // than real encode cost, which is misleading noise.
    let materializeSeconds: number | null = null;
    let materializeStatus: RunSample["materializeStatus"] = "skipped";
    let materializeSheetCount = 0;
    if (regime === "cold" && opts.materialize && opts.dmbPath) {
      // Delete the just-published PNGs so the DM proc does the full
      // iconforge encode rather than no-op'ing on preexisting files.
      wipeManifestSheets(opts.publicRoot);
      const matStart = performance.now();
      let mat: MaterializeResult;
      try {
        mat = await materializeAppearancePreviews({
          dmbPath: opts.dmbPath,
          planDir: path.resolve(opts.publicRoot),
          outputDir: path.resolve(opts.publicRoot),
          dreamDaemonPath: opts.dreamDaemonPath ?? undefined,
        });
      } catch (err) {
        materializeSeconds = (performance.now() - matStart) / 1000;
        materializeStatus = "failed";
        samples.push({
          iteration: i + 1,
          status: result.status,
          totalSeconds: m.totalSeconds,
          stageSeconds: m.stageSeconds,
          cacheHits: m.cacheHits,
          cacheMisses: m.cacheMisses,
          sheetCount: m.sheetCount,
          stateCount: m.stateCount,
          materializeSeconds,
          materializeStatus,
          materializeSheetCount: 0,
        });
        // eslint-disable-next-line no-console
        console.error(
          `materialize failed on cold iteration ${i + 1}: ${(err as Error).message}`,
        );
        totalHits += m.cacheHits;
        totalLookups += m.cacheHits + m.cacheMisses;
        continue;
      }
      // Prefer the DM-reported elapsedMs when the proc succeeded — it
      // excludes dreamdaemon boot/teardown and reflects pure encode cost.
      materializeSeconds = mat.ok
        ? mat.elapsedMs / 1000
        : (performance.now() - matStart) / 1000;
      materializeStatus = mat.ok ? "ok" : "failed";
      materializeSheetCount = mat.sheetCount;
    }

    samples.push({
      iteration: i + 1,
      status: result.status,
      totalSeconds: m.totalSeconds,
      stageSeconds: m.stageSeconds,
      cacheHits: m.cacheHits,
      cacheMisses: m.cacheMisses,
      sheetCount: m.sheetCount,
      stateCount: m.stateCount,
      materializeSeconds,
      materializeStatus,
      materializeSheetCount,
    });
    totalHits += m.cacheHits;
    totalLookups += m.cacheHits + m.cacheMisses;
  }
  return {
    regime,
    runs: opts.runs,
    samples,
    stats: summarize(samples),
    materializeStats: summarizeMaterialize(samples),
    cacheHitRate: totalLookups === 0 ? 0 : totalHits / totalLookups,
  };
}

async function main(): Promise<number> {
  const opts = parseArgs(process.argv.slice(2));

  // Cold first so the warm regime has a valid cache + bundle to reuse.
  const cold = await runRegime("cold", opts);
  const warm = await runRegime("warm", opts);

  const coldOk = cold.samples.every((s) => s.status === "ok");
  const warmOk = warm.samples.every((s) => s.status === "ok");

  // Warm regime must short-circuit via the cache. A warm run that misses
  // cache indicates invalidation-axis drift (adapter version bump, source
  // mutation, stale cacheDir). We surface it as a non-zero exit so CI can
  // catch regressions in cache-key computation.
  const warmShortCircuited = warm.samples.every((s) => s.cacheMisses === 0);

  // Materialize must not silently fail when --materialize is on. Any
  // failure surfaces as a warn status and a non-zero exit alongside the
  // existing regime-failure exit contract. When --materialize is off,
  // every cold sample reports `skipped` and this check is a no-op.
  const materializeOk = cold.samples.every(
    (s) => s.materializeStatus !== "failed",
  );

  const summary = {
    status:
      coldOk && warmOk && warmShortCircuited && materializeOk ? "ok" : "warn",
    warmShortCircuited,
    materializeOk,
    cold,
    warm,
  } as const;

  // One JSON line on stdout for CI capture.
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(summary));

  if (opts.outFile) {
    fs.mkdirSync(path.dirname(path.resolve(opts.outFile)), { recursive: true });
    fs.writeFileSync(
      opts.outFile,
      JSON.stringify(summary, null, 2) + "\n",
      "utf8",
    );
  }

  if (!coldOk || !warmOk) return 1;
  if (!warmShortCircuited) return 2;
  if (!materializeOk) return 3;
  return 0;
}

main().then(
  (code) => {
    process.exit(code);
  },
  (err: unknown) => {
    // eslint-disable-next-line no-console
    console.error("bench failed:", err);
    process.exit(1);
  },
);

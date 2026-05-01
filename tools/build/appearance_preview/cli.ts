#!/usr/bin/env bun
/**
 * tools/build/appearance_preview/cli.ts
 *
 * CLI entrypoint for the RustG/iconforge-backed appearance preview build.
 *
 * Usage:
 *   bun tools/build/appearance_preview/cli.ts \
 *     --public tgui/public/appearance_preview \
 *     --adapter-config tools/build/appearance_preview/config/adapters.json \
 *     [--cache-dir tmp/appearance_preview_cache]
 *
 * Step 1 scope:
 *   - Argument parsing.
 *   - Staging root creation via `createStagingRoot`.
 *   - Explicit "not yet wired" abort if build orchestration is invoked.
 *   - Guaranteed `rollbackStaging` on any error path so the live bundle is
 *     never touched by a half-complete build attempt.
 *
 * Step 5 replaces the central body with a real orchestrator call.
 */

import { buildAppearancePreviews } from "./build";
import {
  AppearancePreviewBuildError,
  PublishLockError,
} from "./errors";
import { materializeAppearancePreviews } from "./materialize";

/** Parsed CLI options. */
interface CliOptions {
  publicRoot: string;
  adapterConfig: string;
  cacheDir: string | null;
  /**
   * When true (the default, matching the Step 6 plan), after a successful
   * orchestrator publish the CLI spawns `dreamdaemon` against `dmbPath` to
   * materialize PNG sheets into the published bundle. Disabled automatically
   * when no DMB is provided, because we cannot invoke the DM runtime without
   * one.
   */
  materialize: boolean;
  /** Path to a pre-built `roguetown.dmb`. Required when `materialize`. */
  dmbPath: string | null;
  /** Optional explicit dreamdaemon executable path. */
  dreamDaemonPath: string | null;
}

/**
 * Minimal argv parser. Intentionally avoids pulling in a CLI framework so the
 * preview build stays decoupled from the rest of `tools/build`.
 *
 * @param argv `process.argv.slice(2)` from the caller.
 * @returns Parsed options.
 * @throws Error with a usage message if required flags are missing.
 */
function parseArgs(argv: readonly string[]): CliOptions {
  let publicRoot: string | null = null;
  let adapterConfig: string | null = null;
  let cacheDir: string | null = null;
  // Step 6: `--materialize` defaults on, but is effectively a no-op unless
  // a DMB path is also supplied. `--no-materialize` explicitly disables it
  // for developers who want only the plan/manifest published.
  let materialize = true;
  let dmbPath: string | null = null;
  let dreamDaemonPath: string | null = null;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const next = (): string => {
      const value = argv[i + 1];
      if (value === undefined) {
        throw new Error(`Flag ${arg} requires a value.`);
      }
      i++;
      return value;
    };
    switch (arg) {
      case "--public":
      case "--public-root":
        publicRoot = next();
        break;
      case "--adapter-config":
      case "--adapters":
        adapterConfig = next();
        break;
      case "--cache-dir":
        cacheDir = next();
        break;
      case "--materialize":
        materialize = true;
        break;
      case "--no-materialize":
        materialize = false;
        break;
      case "--dmb":
        dmbPath = next();
        break;
      case "--dreamdaemon":
        dreamDaemonPath = next();
        break;
      case "-h":
      case "--help":
        printUsage();
        process.exit(0);
      default:
        throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!publicRoot) {
    throw new Error("Missing required flag: --public <path>");
  }
  if (!adapterConfig) {
    throw new Error("Missing required flag: --adapter-config <path>");
  }

  return {
    publicRoot,
    adapterConfig,
    cacheDir,
    materialize,
    dmbPath,
    dreamDaemonPath,
  };
}

/** Print the CLI usage summary to stderr. */
function printUsage(): void {
  process.stderr.write(
    [
      "Usage: bun tools/build/appearance_preview/cli.ts \\",
      "  --public <publicRoot> \\",
      "  --adapter-config <path/to/adapters.json> \\",
      "  [--cache-dir <path>] \\",
      "  [--materialize | --no-materialize]  # default on; requires --dmb",
      "  [--dmb <path/to/roguetown.dmb>] \\",
      "  [--dreamdaemon <path/to/dreamdaemon.exe>]",
      "",
    ].join("\n"),
  );
}

/**
 * Entry point. Returns the exit code; the bottom of the file calls
 * `process.exit` with it so tests can import `main` without exiting.
 */
export async function main(argv: readonly string[]): Promise<number> {
  let options: CliOptions;
  try {
    options = parseArgs(argv);
  } catch (err) {
    process.stderr.write(`appearance_preview: ${(err as Error).message}\n`);
    printUsage();
    return 2;
  }

  try {
    // Step 5: invoke the orchestrator. It handles its own staging
    // creation, atomic publish, and rollback. The CLI only translates the
    // returned `BuildResult` into a process exit code.
    const result = await buildAppearancePreviews({
      adapterConfig: options.adapterConfig,
      publicRoot: options.publicRoot,
      cacheDir: options.cacheDir,
    });
    if (result.status !== "ok") {
      return 1;
    }

    // Step 6: optional materialize pass. We only invoke dreamdaemon when
    // the caller both asked for it AND supplied a DMB path. A missing DMB
    // with `--materialize` on is treated as "skip silently" rather than
    // a hard error so the CLI stays usable in early-iteration workflows
    // that have not produced a DMB yet; the Juke target enforces DMB
    // availability via its own `dependsOn` edge.
    if (options.materialize && options.dmbPath) {
      const materializeResult = await materializeAppearancePreviews({
        dmbPath: options.dmbPath,
        planDir: options.publicRoot,
        outputDir: options.publicRoot,
        dreamDaemonPath: options.dreamDaemonPath ?? undefined,
      });
      if (!materializeResult.ok) {
        process.stderr.write(
          `appearance_preview: materialize failed at stage '${materializeResult.stage}': ${materializeResult.error}\n`,
        );
        if (materializeResult.diagnosticLog) {
          process.stderr.write(materializeResult.diagnosticLog + "\n");
        }
        return 1;
      }
      process.stderr.write(
        `appearance_preview: materialized ${materializeResult.sheetCount} sheet(s) in ${materializeResult.elapsedMs}ms\n`,
      );
    } else if (options.materialize && !options.dmbPath) {
      process.stderr.write(
        "appearance_preview: --materialize requested but no --dmb supplied; skipping materialize stage\n",
      );
    }
    return 0;
  } catch (err) {
    // Defensive: `buildAppearancePreviews` never throws by contract, but
    // an unexpected programmer error must not leak.
    if (err instanceof PublishLockError) {
      process.stderr.write(
        `appearance_preview: PUBLISH_LOCK at ${err.targetPath}: ${err.message}\n`,
      );
      return 1;
    }
    if (err instanceof AppearancePreviewBuildError) {
      process.stderr.write(
        `appearance_preview: ${err.code}: ${err.message}\n`,
      );
      return 1;
    }
    process.stderr.write(
      `appearance_preview: unexpected error: ${(err as Error).stack ?? String(err)}\n`,
    );
    return 1;
  }
}

// Only invoke `main` when this file is run directly under Bun, not when it is
// imported by tests or by the orchestrator in Step 5.
//
// Bun sets `import.meta.main` to true for the entry module.
// Reference: https://bun.sh/docs/api/import-meta
const isEntry = (import.meta as unknown as { main?: boolean }).main === true;
if (isEntry) {
  main(process.argv.slice(2)).then((code) => process.exit(code));
}

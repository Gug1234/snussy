/**
 * tools/build/appearance_preview/materialize.ts
 *
 * Headless materialize stage: invoke a pre-built `roguetown.dmb` under
 * `dreamdaemon` with the `appearance_preview_materialize` world-param. The
 * DM-side entry point (`appearance_preview_materialize.dm`) reads the plan
 * in `planDir`, runs every iconforge job, writes the resulting PNGs into
 * `outputDir`, and drops a `materialize_status.json` sidecar we read back
 * after process exit.
 *
 * Why a sidecar instead of an exit code? BYOND's `del(world)` always
 * exits 0 regardless of in-proc failure; we cannot rely on it to signal
 * materialize success. The DM proc always writes the status file before
 * shutdown, so its presence+contents are the single source of truth.
 *
 * This module is intentionally decoupled from the orchestrator so it can
 * be invoked ad-hoc for local development: `bun tools/build/appearance_preview/materialize.ts`
 * is a valid integration-test entry point.
 */

import * as fs from "node:fs";
import * as path from "node:path";

function removeDynamicRscForDmb(dmbPath: string): void {
  const parsed = path.parse(dmbPath);
  const dynRscPath = path.join(parsed.dir, `${parsed.name}.dyn.rsc`);
  try {
    fs.rmSync(dynRscPath, { force: true });
  } catch {
    // Best-effort cleanup. A live DreamDaemon lock will surface as bad runtime
    // resources on the next boot rather than failing materialization itself.
  }
}

/** Options for a single materialize invocation. */
export interface MaterializeOptions {
  /** Absolute path to the pre-built `roguetown.dmb`. */
  dmbPath: string;
  /**
   * Absolute path to the directory containing `iconforge_plan.json` and
   * `manifest.json`. Typically equal to `outputDir` so the bundle lives
   * in one place; split for tests that want to materialize into a
   * different tree than the plan was authored into.
   */
  planDir: string;
  /** Absolute path where generated PNGs (keyed by `outputPath`) should land. */
  outputDir: string;
  /**
   * Optional explicit `dreamdaemon.exe` path. Falls back to `DM_EXE` env
   * var (with `dm.exe` substituted for `dreamdaemon.exe` on the same dir)
   * and then PATH.
   */
  dreamDaemonPath?: string;
  /**
   * Kill the subprocess if it runs past this many milliseconds. Matches
   * the "fail loudly rather than hang CI forever" rule. Default 5 min.
   */
  timeoutMs?: number;
}

/** Structured result from a materialize run. */
export interface MaterializeResult {
  ok: boolean;
  sheetCount: number;
  elapsedMs: number;
  /** When !ok, a human-readable explanation. */
  error?: string;
  /** When !ok, the DM-side stage where failure occurred. */
  stage?: string;
  /** Exit code from dreamdaemon (0 is typical even on failure). */
  exitCode: number;
  /** Best-effort stdout/stderr capture for debugging. */
  diagnosticLog: string;
}

/** Raw shape of `materialize_status.json` written by the DM side. */
interface MaterializeStatus {
  ok: boolean;
  sheetCount?: number;
  elapsedMs?: number;
  error?: string;
  stage?: string;
}

/** Name of the sidecar file the DM proc writes. Must match the DM define. */
const STATUS_FILENAME = "materialize_status.json";

/** Default timeout — ~5 min, enough for a cold iconforge encode of every sheet. */
const DEFAULT_TIMEOUT_MS = 5 * 60 * 1000;

/**
 * Resolve a dreamdaemon executable path. Prefers an explicit override,
 * then derives from `DM_EXE` (the build convention used by lib/byond.ts),
 * then probes the standard BYOND install locations on Windows, then
 * falls back to the platform-default binary name and lets the OS
 * resolve via PATH.
 */
function resolveDreamDaemonPath(explicit: string | undefined): string {
  if (explicit && fs.existsSync(explicit)) return explicit;
  const ddName =
    process.platform === "win32" ? "dreamdaemon.exe" : "DreamDaemon";

  const candidates: string[] = [];
  const dmExe = process.env.DM_EXE;
  if (dmExe) {
    for (const entry of dmExe.split(",")) {
      if (!entry) continue;
      // DM_EXE typically points at `dm.exe`; dreamdaemon lives alongside.
      candidates.push(path.join(path.dirname(entry), ddName));
    }
  }
  if (process.platform === "win32") {
    // Mirror the search order used by lib/byond.ts's getDmPath.
    candidates.push(`C:\\Program Files\\BYOND\\bin\\${ddName}`);
    candidates.push(`C:\\Program Files (x86)\\BYOND\\bin\\${ddName}`);
  }
  for (const c of candidates) {
    if (fs.existsSync(c)) return c;
  }
  // Final fallback: bare executable name so the OS can resolve via PATH.
  // If PATH lookup also fails the subprocess spawn surfaces a clear
  // "Executable not found" error to the Juke target.
  return ddName;
}

/**
 * Build the `-params` value for dreamdaemon. DM parses it as an HTTP-style
 * querystring (`params["key"]` retrieval in `/world/New()`), so we encode
 * each value with `encodeURIComponent`.
 */
function buildParamsString(planDir: string, outputDir: string): string {
  const parts = [
    `appearance_preview_materialize=1`,
    `appearance_preview_plan_dir=${encodeURIComponent(planDir)}`,
    `appearance_preview_output_dir=${encodeURIComponent(outputDir)}`,
  ];
  return parts.join("&");
}

/**
 * Run the materialize stage. Never throws on expected failures (missing
 * status file, non-ok status, subprocess error); all of those are folded
 * into the returned `MaterializeResult` with `ok === false`. Programmer
 * errors (invalid options) still throw.
 */
export async function materializeAppearancePreviews(
  options: MaterializeOptions,
): Promise<MaterializeResult> {
  const dmbPath = path.resolve(options.dmbPath);
  const planDir = path.resolve(options.planDir);
  const outputDir = path.resolve(options.outputDir);

  if (!fs.existsSync(dmbPath)) {
    throw new Error(`materialize: dmb not found at ${dmbPath}`);
  }
  if (!fs.existsSync(path.join(planDir, "iconforge_plan.json"))) {
    throw new Error(
      `materialize: iconforge_plan.json not present in ${planDir}`,
    );
  }
  removeDynamicRscForDmb(dmbPath);
  fs.mkdirSync(outputDir, { recursive: true });
  // Ensure the sheet output subdirectory and the iconforge scratch dir both
  // exist before dreamdaemon runs. rustg_iconforge_generate does not create
  // its own output directory; if missing it silently fails to write the PNG
  // while still returning a well-formed JSON result, so the downstream
  // `fexists` check is the first thing that notices. Creating the scratch
  // dir up front (instead of from DM) keeps this guarantee on the same side
  // as the rest of the filesystem setup.
  fs.mkdirSync(path.join(outputDir, "sheets"), { recursive: true });
  fs.mkdirSync(
    path.resolve(
      process.cwd(),
      "data",
      "spritesheets",
      "appearance_preview_materialize",
    ),
    { recursive: true },
  );

  const statusPath = path.join(outputDir, STATUS_FILENAME);
  // Remove any stale status file before launch so a crashed subprocess
  // cannot be mistaken for a successful run on its predecessor's residue.
  try {
    fs.rmSync(statusPath, { force: true });
  } catch {
    // best-effort; permission errors surface via the post-run read.
  }

  const ddPath = resolveDreamDaemonPath(options.dreamDaemonPath);
  const paramsStr = buildParamsString(planDir, outputDir);
  const args = [
    dmbPath,
    "-close",
    "-trusted",
    "-verbose",
    "-params",
    paramsStr,
  ];

  const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const start = Date.now();
  let stdout = "";
  let stderr = "";
  let exitCode = -1;
  let timedOut = false;

  // Bun's subprocess API is the same tested path the rest of the build uses
  // (see lib/byond.ts). Inherit stdio so dreamdaemon's log is visible in CI
  // output while still capturing a copy for diagnostic storage.
  const proc = Bun.spawn({
    cmd: [ddPath, ...args],
    stdout: "pipe",
    stderr: "pipe",
    // Run in repo root so DM relative paths resolve the same as a normal build.
    cwd: process.cwd(),
  });

  const stdoutPromise = proc.stdout
    ? new Response(proc.stdout).text().then((t) => (stdout = t))
    : Promise.resolve("");
  const stderrPromise = proc.stderr
    ? new Response(proc.stderr).text().then((t) => (stderr = t))
    : Promise.resolve("");

  const timer = setTimeout(() => {
    timedOut = true;
    try {
      proc.kill();
    } catch {
      // ignore
    }
  }, timeoutMs);

  try {
    exitCode = await proc.exited;
    clearTimeout(timer);
    await Promise.allSettled([stdoutPromise, stderrPromise]);
  } finally {
    removeDynamicRscForDmb(dmbPath);
  }
  const elapsedMs = Date.now() - start;
  const diagnosticLog = `${stdout}${stderr ? `\n[stderr]\n${stderr}` : ""}`;

  if (timedOut) {
    return {
      ok: false,
      sheetCount: 0,
      elapsedMs,
      error: `materialize: subprocess exceeded ${timeoutMs}ms and was killed`,
      stage: "subprocess_timeout",
      exitCode,
      diagnosticLog,
    };
  }

  // DM side writes the status sidecar before `del(world)`. If it is missing,
  // dreamdaemon died before reaching the status write (e.g. compile stubs,
  // DMB mismatch, RUST_G load failure) and we have to infer a failure.
  if (!fs.existsSync(statusPath)) {
    return {
      ok: false,
      sheetCount: 0,
      elapsedMs,
      error: `materialize: status sidecar missing at ${statusPath} (subprocess exit code ${exitCode})`,
      stage: "no_status",
      exitCode,
      diagnosticLog,
    };
  }

  let status: MaterializeStatus;
  try {
    status = JSON.parse(fs.readFileSync(statusPath, "utf8")) as MaterializeStatus;
  } catch (err) {
    return {
      ok: false,
      sheetCount: 0,
      elapsedMs,
      error: `materialize: status sidecar unparseable: ${(err as Error).message}`,
      stage: "bad_status",
      exitCode,
      diagnosticLog,
    };
  }

  if (!status.ok) {
    return {
      ok: false,
      sheetCount: status.sheetCount ?? 0,
      elapsedMs,
      error: status.error ?? "unknown DM-side failure",
      stage: status.stage ?? "dm_failure",
      exitCode,
      diagnosticLog,
    };
  }

  return {
    ok: true,
    sheetCount: status.sheetCount ?? 0,
    elapsedMs,
    exitCode,
    diagnosticLog,
  };
}

/**
 * Minimal CLI entry so local devs can run the stage by itself. Usage:
 *   bun tools/build/appearance_preview/materialize.ts \
 *     --dmb roguetown.dmb \
 *     --plan-dir tgui/public/appearance_preview \
 *     [--output-dir tgui/public/appearance_preview] \
 *     [--dreamdaemon <path>]
 */
async function mainCli(argv: readonly string[]): Promise<number> {
  const flags: Record<string, string> = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith("--")) {
      process.stderr.write(`materialize: unexpected arg ${a}\n`);
      return 2;
    }
    const value = argv[i + 1];
    if (value === undefined || value.startsWith("--")) {
      process.stderr.write(`materialize: flag ${a} requires a value\n`);
      return 2;
    }
    flags[a.slice(2)] = value;
    i++;
  }
  const dmb = flags["dmb"];
  const planDir = flags["plan-dir"];
  const outputDir = flags["output-dir"] ?? planDir;
  const dd = flags["dreamdaemon"];
  if (!dmb || !planDir) {
    process.stderr.write(
      "Usage: bun tools/build/appearance_preview/materialize.ts --dmb <path> --plan-dir <path> [--output-dir <path>] [--dreamdaemon <path>]\n",
    );
    return 2;
  }
  const result = await materializeAppearancePreviews({
    dmbPath: dmb,
    planDir,
    outputDir,
    dreamDaemonPath: dd,
  });
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
  return result.ok ? 0 : 1;
}

const isEntry = (import.meta as unknown as { main?: boolean }).main === true;
if (isEntry) {
  mainCli(process.argv.slice(2)).then((code) => process.exit(code));
}

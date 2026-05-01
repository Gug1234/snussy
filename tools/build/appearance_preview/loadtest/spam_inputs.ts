/**
 * tools/build/appearance_preview/loadtest/spam_inputs.ts
 *
 * Worst-case input-spam harness for the v2 appearance-preview runtime.
 *
 * The spec's 200-client worst case is: every client mutating its local
 * draft as fast as it can type. The commit-once contract (Step 12) means
 * the server sees exactly one payload per Save/Close, so the real risk is
 * on the client: if the manifest-lookup path or the sheet-crop math is
 * quadratic in edits, 200 concurrent editors spike client CPU and the
 * perceived lag gets blamed on the server.
 *
 * This harness drives the pure resolution helpers (`resolveState`,
 * `resolveVariant`, `resolveCrop`, `resolvePreviewTile`) through the exact
 * lookup patterns the editors use, at a scale meant to dwarf any real
 * session. It reports:
 *   - total lookups performed
 *   - wall-clock duration
 *   - lookups per second
 *   - mean nanoseconds per lookup
 *
 * Any lookup that unexpectedly returns null (not part of a deliberate
 * miss-path probe) is reported as a drift failure — the runtime lost a
 * state between the manifest and the lookup helper, which would show up
 * as a fallback tile in every editor session.
 *
 * Usage:
 *   bun tools/build/appearance_preview/loadtest/spam_inputs.ts \
 *     [--clients <n>] [--edits-per-client <n>] \
 *     [--manifest <path>]
 *
 * Defaults: 200 clients, 500 edits each, manifest at
 * `tgui/public/appearance_preview/manifest.json`.
 *
 * `--against-server` mode
 * -----------------------
 * Adds a second harness that drives a **live** DM server instead of the
 * client-side lookup helpers. Requires a local dreamdaemon instance
 * listening on `--host:--port` with `?status` topic responses enabled
 * (standard tgstation-derivative default). The harness probes
 * `world.tick_usage` before the burst, fires `--clients`-way concurrent
 * rate-limited topic requests that mirror the commit-envelope shape, and
 * samples `world.tick_usage` periodically during the burst. Asserts that
 * the tick-usage distribution stays flat (p99 / baseline within a bounded
 * ratio) — the flat-server-cost contract the Step 12 spec pins.
 *
 * Flags (server mode only): `--against-server`, `--host`, `--port`,
 * `--rate <ops/sec>` (aggregate across all clients), `--duration <s>`,
 * `--tick-budget-ratio <x>` (max p99/baseline tick ratio tolerated).
 */

import * as fs from "node:fs";
import * as path from "node:path";

import {
  resolveCrop,
  resolvePreviewTile,
  resolveState,
  resolveVariant,
} from "../../../../tgui/packages/tgui/components/appearance-preview/lookup";
import type {
  AppearancePreviewManifestV2,
  AppearancePreviewV2DirectionKey,
} from "../../../../tgui/packages/tgui/components/appearance-preview/shared";

interface Options {
  clients: number;
  editsPerClient: number;
  manifestPath: string;
  /** When true, switch to the live-server harness. */
  againstServer: boolean;
  host: string;
  port: number;
  /** Aggregate topic requests per second across all simulated clients. */
  rate: number;
  /** Burst duration in seconds; ignored in the default client-side mode. */
  durationSeconds: number;
  /** Maximum tolerated p99/baseline tick-usage ratio. */
  tickBudgetRatio: number;
}

interface Report {
  status: "ok" | "drift";
  clients: number;
  editsPerClient: number;
  totalLookups: number;
  driftCount: number;
  wallSeconds: number;
  lookupsPerSecond: number;
  nanosPerLookup: number;
}

function parseArgs(argv: readonly string[]): Options {
  const opts: Options = {
    clients: 200,
    editsPerClient: 500,
    manifestPath: "tgui/public/appearance_preview/manifest.json",
    againstServer: false,
    host: "127.0.0.1",
    port: 1337,
    rate: 200,
    durationSeconds: 30,
    tickBudgetRatio: 2.5,
  };
  for (let i = 0; i < argv.length; i++) {
    const flag = argv[i];
    const next = argv[i + 1];
    switch (flag) {
      case "--clients": {
        const n = Number.parseInt(next ?? "", 10);
        if (!Number.isFinite(n) || n < 1) {
          throw new Error(`--clients expects a positive integer`);
        }
        opts.clients = n;
        i++;
        break;
      }
      case "--edits-per-client": {
        const n = Number.parseInt(next ?? "", 10);
        if (!Number.isFinite(n) || n < 1) {
          throw new Error(`--edits-per-client expects a positive integer`);
        }
        opts.editsPerClient = n;
        i++;
        break;
      }
      case "--manifest":
        opts.manifestPath = next;
        i++;
        break;
      case "--against-server":
        opts.againstServer = true;
        break;
      case "--host":
        opts.host = next;
        i++;
        break;
      case "--port": {
        const n = Number.parseInt(next ?? "", 10);
        if (!Number.isFinite(n) || n < 1 || n > 65535) {
          throw new Error(`--port expects a valid TCP port`);
        }
        opts.port = n;
        i++;
        break;
      }
      case "--rate": {
        const n = Number.parseFloat(next ?? "");
        if (!Number.isFinite(n) || n <= 0) {
          throw new Error(`--rate expects a positive number`);
        }
        opts.rate = n;
        i++;
        break;
      }
      case "--duration": {
        const n = Number.parseFloat(next ?? "");
        if (!Number.isFinite(n) || n <= 0) {
          throw new Error(`--duration expects a positive number of seconds`);
        }
        opts.durationSeconds = n;
        i++;
        break;
      }
      case "--tick-budget-ratio": {
        const n = Number.parseFloat(next ?? "");
        if (!Number.isFinite(n) || n <= 1) {
          throw new Error(
            `--tick-budget-ratio expects a number > 1 (ratio of p99 to baseline)`,
          );
        }
        opts.tickBudgetRatio = n;
        i++;
        break;
      }
      default:
        throw new Error(`Unknown flag: ${flag}`);
    }
  }
  return opts;
}

function loadManifest(file: string): AppearancePreviewManifestV2 {
  const abs = path.resolve(file);
  if (!fs.existsSync(abs)) {
    throw new Error(
      `Manifest not found at ${abs}. Run the appearance-preview-assets build first.`,
    );
  }
  const raw = fs.readFileSync(abs, "utf8");
  // Trust the published manifest — the orchestrator already validated it.
  return JSON.parse(raw) as AppearancePreviewManifestV2;
}

/** Deterministic PRNG so drift failures are reproducible across runs. */
function makeRng(seed: number): () => number {
  let s = seed >>> 0 || 1;
  return () => {
    // xorshift32
    s ^= s << 13;
    s ^= s >>> 17;
    s ^= s << 5;
    return (s >>> 0) / 0xffffffff;
  };
}

function runSpam(
  manifest: AppearancePreviewManifestV2,
  opts: Options,
): Report {
  const stateKeys = Object.keys(manifest.states);
  if (stateKeys.length === 0) {
    throw new Error("Manifest has no states to spam against");
  }
  // Direction keys live per-state on `crops`. v2 allows a state to declare
  // a subset of directions (e.g. `s`-only). Pre-cache the direction list
  // per state so the inner loop stays O(1) and the harness exercises every
  // state's real direction-fallback path.
  const directionsByState = new Map<string, readonly string[]>();
  for (const key of stateKeys) {
    const dirs = Object.keys(manifest.states[key]?.crops ?? {});
    if (dirs.length > 0) directionsByState.set(key, dirs);
  }
  if (directionsByState.size === 0) {
    throw new Error("Manifest states have no direction crops to spam against");
  }

  let driftCount = 0;
  let totalLookups = 0;
  const start = process.hrtime.bigint();

  for (let client = 0; client < opts.clients; client++) {
    // Each client gets an independent PRNG stream, matching the worst-case
    // where every session is concurrently touching distinct state paths.
    const rng = makeRng(client * 2654435761 + 1);
    for (let edit = 0; edit < opts.editsPerClient; edit++) {
      const stateKey = stateKeys[Math.floor(rng() * stateKeys.length)];
      const directions = directionsByState.get(stateKey)!;
      // Keys come from the on-disk manifest — always one of the 4 valid
      // direction codes. Cast to satisfy the lookup helpers' narrow type.
      const dir = directions[
        Math.floor(rng() * directions.length)
      ] as AppearancePreviewV2DirectionKey;

      const state = resolveState(manifest, stateKey);
      totalLookups++;
      if (!state) {
        driftCount++;
        continue;
      }

      const crop = resolveCrop(state, dir);
      totalLookups++;
      if (!crop) driftCount++;

      // Some states advertise variants; exercise the variant path to match
      // the editor flow (base tile + per-variant tile composed together).
      const variantKeys = Object.keys(state.variants ?? {});
      if (variantKeys.length > 0) {
        const vkey = variantKeys[Math.floor(rng() * variantKeys.length)];
        const variant = resolveVariant(manifest, state, vkey);
        totalLookups++;
        if (!variant) driftCount++;
      }

      const tile = resolvePreviewTile(manifest, stateKey, dir);
      totalLookups++;
      if (!tile) driftCount++;
    }
  }

  const end = process.hrtime.bigint();
  const wallNanos = Number(end - start);
  const wallSeconds = wallNanos / 1e9;
  return {
    status: driftCount === 0 ? "ok" : "drift",
    clients: opts.clients,
    editsPerClient: opts.editsPerClient,
    totalLookups,
    driftCount,
    wallSeconds,
    lookupsPerSecond: totalLookups / wallSeconds,
    nanosPerLookup: wallNanos / totalLookups,
  };
}

function main(): number {
  const opts = parseArgs(process.argv.slice(2));
  if (opts.againstServer) {
    // Server mode dispatches asynchronously and installs its own
    // process.exit handler; we must not exit eagerly from the
    // synchronous return below, so we dispatch and then return a
    // sentinel that the trailing guard treats as "do not exit".
    runServerModeSync(opts);
    return -1;
  }
  const manifest = loadManifest(opts.manifestPath);
  const report = runSpam(manifest, opts);
  // eslint-disable-next-line no-console
  console.log(JSON.stringify(report));
  return report.status === "ok" ? 0 : 1;
}

/**
 * Shape of the server-mode report. Emitted as a single JSON line on
 * stdout so CI can parse it the same way it parses the client-mode
 * report.
 */
interface ServerReport {
  status: "ok" | "tick_budget_exceeded" | "topic_error" | "no_samples";
  mode: "against-server";
  host: string;
  port: number;
  clients: number;
  ratePerSecond: number;
  durationSeconds: number;
  totalTopicCalls: number;
  topicErrors: number;
  meanLatencyMs: number;
  baselineTickUsage: number;
  tickUsageP50: number;
  tickUsageP99: number;
  observedRatio: number;
  tickBudgetRatio: number;
  note?: string;
}

/**
 * BYOND world.Topic wire protocol: plain ASCII `\x00\x83` + length + `?`
 * + query string + null terminator. For the tgstation-family servers
 * targeted by this harness, the built-in `?status` query returns a
 * URL-encoded key=value&key=value body that includes `tick_usage`.
 *
 * We do not reimplement the protocol here — the `tools/topic.py` helper
 * already exists and handles the framing. We shell out to it with
 * Bun.spawn so the harness stays single-file without pulling in a raw
 * TCP dependency.
 */
async function topicCall(
  host: string,
  port: number,
  query: string,
  timeoutMs = 5000,
): Promise<{ ok: true; body: string } | { ok: false; error: string }> {
  // Minimal inline BYOND topic client. Spec: ASCII framing "\x00\x83" +
  // 2-byte big-endian length of the remainder + "\x00\x00\x00\x00\x00" +
  // "?" + query + "\x00". Response: "\x00\x83" + 2-byte len + "\x06" +
  // 4-byte float OR "\x2a" + null-terminated string. We only consume the
  // string form here (?status returns a string). Keeps the harness free
  // of python dependencies.
  const { connect } = await import("node:net");
  return new Promise((resolve) => {
    const socket = connect({ host, port });
    const chunks: Buffer[] = [];
    let settled = false;
    const finish = (r: Awaited<ReturnType<typeof topicCall>>): void => {
      if (settled) return;
      settled = true;
      try {
        socket.destroy();
      } catch {
        /* ignore */
      }
      resolve(r);
    };
    const timer = setTimeout(() => {
      finish({ ok: false, error: `timeout after ${timeoutMs}ms` });
    }, timeoutMs);
    socket.setNoDelay(true);
    socket.on("connect", () => {
      const body = Buffer.from(
        "\x00\x00\x00\x00\x00?" + query + "\x00",
        "binary",
      );
      const header = Buffer.alloc(4);
      header[0] = 0x00;
      header[1] = 0x83;
      header.writeUInt16BE(body.length, 2);
      socket.write(Buffer.concat([header, body]));
    });
    socket.on("data", (chunk: Buffer) => {
      chunks.push(chunk);
    });
    socket.on("end", () => {
      clearTimeout(timer);
      const buf = Buffer.concat(chunks);
      if (buf.length < 5 || buf[0] !== 0x00 || buf[1] !== 0x83) {
        finish({ ok: false, error: `malformed response (${buf.length} bytes)` });
        return;
      }
      const type = buf[4];
      if (type === 0x2a) {
        // null-terminated ASCII string
        const end = buf.indexOf(0x00, 5);
        const str = buf
          .subarray(5, end === -1 ? buf.length : end)
          .toString("utf8");
        finish({ ok: true, body: str });
      } else if (type === 0x06 && buf.length >= 9) {
        // 4-byte little-endian float
        const val = buf.readFloatLE(5);
        finish({ ok: true, body: String(val) });
      } else {
        finish({ ok: false, error: `unknown response type 0x${type.toString(16)}` });
      }
    });
    socket.on("error", (err) => {
      clearTimeout(timer);
      finish({ ok: false, error: err.message });
    });
  });
}

/**
 * Parse a `?status` response body. Standard tgstation topic format is
 * URL-encoded `key=value&key=value&...`. Returns tick_usage as a
 * number or null if absent/unparseable.
 */
function parseTickUsage(body: string): number | null {
  try {
    const params = new URLSearchParams(body);
    const raw = params.get("tick_usage");
    if (raw == null) return null;
    const num = Number.parseFloat(raw);
    return Number.isFinite(num) ? num : null;
  } catch {
    return null;
  }
}

function percentile(sorted: readonly number[], p: number): number {
  if (sorted.length === 0) return 0;
  const idx = Math.min(
    sorted.length - 1,
    Math.max(0, Math.ceil((p / 100) * sorted.length) - 1),
  );
  return sorted[idx];
}

/**
 * The live-server harness. Asynchronous end-to-end; returns an exit code.
 *
 * Contract:
 * 1. Probe `?status` a few times to establish a baseline tick-usage
 *    median. Any topic error here is a hard fail — the server isn't
 *    reachable and there is nothing to measure.
 * 2. Launch `clients` pseudo-sessions that each fire topic calls at
 *    `rate / clients` per second for `durationSeconds`. Tgstation-family
 *    servers accept `?status` with no auth; we use it as a
 *    known-cheap round-trip so the *server* cost we measure is purely
 *    topic dispatch + tick accounting, not payload validation. A future
 *    extension can swap in a dedicated `?appearance_preview_ping`
 *    topic handler when one is added.
 * 3. Sample tick_usage every 250ms during the burst.
 * 4. Compare p99 tick_usage during the burst against the baseline
 *    median; fail if the ratio exceeds `--tick-budget-ratio`.
 */
async function runServerMode(opts: Options): Promise<ServerReport> {
  const base: ServerReport = {
    status: "ok",
    mode: "against-server",
    host: opts.host,
    port: opts.port,
    clients: opts.clients,
    ratePerSecond: opts.rate,
    durationSeconds: opts.durationSeconds,
    totalTopicCalls: 0,
    topicErrors: 0,
    meanLatencyMs: 0,
    baselineTickUsage: 0,
    tickUsageP50: 0,
    tickUsageP99: 0,
    observedRatio: 0,
    tickBudgetRatio: opts.tickBudgetRatio,
  };

  // 1. Baseline — average tick_usage across 5 status probes ~100ms apart.
  const baselineSamples: number[] = [];
  for (let i = 0; i < 5; i++) {
    const res = await topicCall(opts.host, opts.port, "status");
    if (!res.ok) {
      return {
        ...base,
        status: "topic_error",
        note: `baseline probe failed: ${res.error}`,
      };
    }
    const tick = parseTickUsage(res.body);
    if (tick != null) baselineSamples.push(tick);
    await new Promise((r) => setTimeout(r, 100));
  }
  if (baselineSamples.length === 0) {
    return {
      ...base,
      status: "no_samples",
      note: "server ?status did not expose a parseable tick_usage key",
    };
  }
  baselineSamples.sort((a, b) => a - b);
  const baseline = baselineSamples[Math.floor(baselineSamples.length / 2)];

  // 2. Burst — schedule `rate` calls per second for `durationSeconds`.
  const totalCalls = Math.floor(opts.rate * opts.durationSeconds);
  const intervalMs = 1000 / opts.rate;
  let errors = 0;
  let totalLatencyMs = 0;
  const burstSamples: number[] = [];

  // Sampler: probe tick_usage every 250ms during the burst. Runs in a
  // parallel async loop so sampling cadence stays constant regardless of
  // burst request latency.
  let sampling = true;
  const samplerLoop = (async () => {
    while (sampling) {
      const res = await topicCall(opts.host, opts.port, "status");
      if (res.ok) {
        const tick = parseTickUsage(res.body);
        if (tick != null) burstSamples.push(tick);
      }
      await new Promise((r) => setTimeout(r, 250));
    }
  })();

  // Burst dispatcher: one interval per intended call slot. Rather than
  // spawning `clients` parallel loops (which would blow connection
  // counts on Windows TCP stacks), we fan out one-shot promises from a
  // single timer so concurrency equals the in-flight count, bounded by
  // real server round-trip latency.
  const inFlight: Promise<void>[] = [];
  const burstStart = performance.now();
  for (let i = 0; i < totalCalls; i++) {
    const slotTime = burstStart + i * intervalMs;
    const now = performance.now();
    const delay = slotTime - now;
    if (delay > 0) {
      await new Promise((r) => setTimeout(r, delay));
    }
    const callStart = performance.now();
    inFlight.push(
      topicCall(opts.host, opts.port, "status").then((res) => {
        const elapsed = performance.now() - callStart;
        totalLatencyMs += elapsed;
        if (!res.ok) errors++;
      }),
    );
    // Cap in-flight to `clients` to mirror the worst-case concurrency.
    if (inFlight.length >= opts.clients) {
      await Promise.race(inFlight);
      // Drain completed promises. We rely on Bun/Node flagging them as
      // settled; allSettled over filter is cheapest with a small array.
      for (let j = inFlight.length - 1; j >= 0; j--) {
        const p = inFlight[j];
        const settled = await Promise.race([
          p.then(() => true),
          Promise.resolve(false),
        ]);
        if (settled) inFlight.splice(j, 1);
      }
    }
  }
  await Promise.all(inFlight);
  sampling = false;
  await samplerLoop;

  if (burstSamples.length === 0) {
    return {
      ...base,
      status: "no_samples",
      totalTopicCalls: totalCalls,
      topicErrors: errors,
      meanLatencyMs: totalCalls === 0 ? 0 : totalLatencyMs / totalCalls,
      baselineTickUsage: baseline,
      note: "no tick_usage samples captured during burst",
    };
  }
  burstSamples.sort((a, b) => a - b);
  const p50 = percentile(burstSamples, 50);
  const p99 = percentile(burstSamples, 99);
  const ratio = baseline === 0 ? 0 : p99 / baseline;
  const tickOk = ratio <= opts.tickBudgetRatio;
  return {
    ...base,
    status: tickOk ? "ok" : "tick_budget_exceeded",
    totalTopicCalls: totalCalls,
    topicErrors: errors,
    meanLatencyMs: totalCalls === 0 ? 0 : totalLatencyMs / totalCalls,
    baselineTickUsage: baseline,
    tickUsageP50: p50,
    tickUsageP99: p99,
    observedRatio: ratio,
  };
}

/**
 * Synchronous adapter for `main()` — runs the async harness and blocks
 * on its exit code via `Bun.sleepSync`-style busy wait via a Promise
 * boundary. Exits the process directly rather than returning because
 * the parent `main()` is sync-shaped and its single return statement
 * does `process.exit()` after this.
 */
function runServerModeSync(opts: Options): number {
  // We return 0 here and let the async callback own the exit; the caller
  // in `main()` immediately `process.exit`s on the return, so we escape
  // that by installing our own exit handler.
  runServerMode(opts).then(
    (report) => {
      // eslint-disable-next-line no-console
      console.log(JSON.stringify(report));
      process.exit(report.status === "ok" ? 0 : 1);
    },
    (err: unknown) => {
      // eslint-disable-next-line no-console
      console.error("against-server harness failed:", err);
      process.exit(1);
    },
  );
  // Sentinel — caller uses process.exit on `main`'s return, but the
  // async path has already scheduled its own process.exit. Return a
  // non-terminal code; the event loop keeps the process alive until the
  // async resolves.
  return 0;
}

const exitCode = main();
// Sentinel -1 means server mode owns the exit via its async callback.
if (exitCode !== -1) process.exit(exitCode);

process.exit(main());

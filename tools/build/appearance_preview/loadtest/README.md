# Appearance preview load test

Worst-case input-spam harness for the v2 appearance-preview runtime.
Runs in two modes:

1. **Client mode (default).** Drives the pure v2 lookup helpers through a
   200-client × 500-edit spam to validate the client-side path stays
   flat under the `PROJECT_RULES` worst-case.
2. **`--against-server` mode.** Drives a live local DM server via the
   BYOND `world.Topic` protocol, samples `world.tick_usage` across a
   rate-limited burst, and asserts the p99/baseline ratio stays under
   `--tick-budget-ratio`. This is the server-side flat-cost contract
   check the Step 12 spec pins.

The server-side commit contract is also enforced separately by DM unit
tests (`/datum/unit_test/appearance_preview_*`), which cover validation,
split-brain, mount fallback, admin rebuild, and legacy-shim guards
independent of this harness.

## Client mode — what it exercises

For each simulated client, the harness drives the pure v2 lookup helpers
in `tgui/packages/tgui/components/appearance-preview/lookup.ts` through
the same patterns an editor session uses:

- `resolveState(manifest, iconState)` — state record lookup by key.
- `resolveCrop(state, direction)` — direction-aware crop rect resolution
  (exercises the `direction → s` fallback rule).
- `resolveVariant(manifest, state, variantKey)` — variant cross-lookup
  for states that advertise variants (e.g. `taur_penis` → `partial/hard`,
  gem-bearing piercings → `gem`).
- `resolvePreviewTile(manifest, iconState, direction)` — the one-shot
  bundle the `SheetRenderer` uses every frame.

Each combination goes through a deterministic PRNG stream per client so
drift failures are reproducible.

## Client mode — how to run

Prerequisites: the published bundle must exist on disk. Run the build
target first:

```
bun tools/build/build.ts appearance-preview-assets
```

Then invoke the harness:

```
bun tools/build/appearance_preview/loadtest/spam_inputs.ts
```

Flags (all optional):

| Flag                  | Default                                         | Purpose                                        |
| --------------------- | ----------------------------------------------- | ---------------------------------------------- |
| `--clients <n>`       | `200`                                           | Number of concurrent-session simulations.      |
| `--edits-per-client`  | `500`                                           | Lookups per client.                            |
| `--manifest <path>`   | `tgui/public/appearance_preview/manifest.json`  | Manifest to test against.                      |

## Client mode — how to read the output

One JSON line on stdout, e.g.:

```json
{
  "status": "ok",
  "clients": 200,
  "editsPerClient": 500,
  "totalLookups": 431234,
  "driftCount": 0,
  "wallSeconds": 0.412,
  "lookupsPerSecond": 1046684.5,
  "nanosPerLookup": 955.4
}
```

### Pass criteria

- `status` is `"ok"` (no drift).
- `driftCount` is `0`. Any non-zero value means a lookup that should have
  resolved returned `null` — the manifest and the lookup helpers are out
  of sync. This is a hard failure and the harness exits non-zero.
- `nanosPerLookup` is sub-microsecond on dev hardware. A regression here
  is the early-warning signal that someone introduced an O(n) scan into a
  previously O(1) path (for example, replacing a record lookup with an
  `Object.values(...).find(...)` call).

### Interpreting the numbers

- **200 clients × 500 edits ≈ 400k-500k lookups.** That is far more input
  traffic than a real 4-5 hour round can produce. If this completes in
  under a second on dev hardware, the runtime is nowhere near being the
  bottleneck.
- **Cache-friendliness is not tested.** The lookup helpers are pure
  O(1) table walks, so there is nothing to warm. If future work adds
  memoization, extend this harness to run two passes and compare.

## Server mode — `--against-server`

### What it exercises

Drives `dreamdaemon`'s `world.Topic` handler over localhost with a
rate-limited burst of `?status` requests, then compares `tick_usage`
during the burst to a pre-burst baseline. This is the
*server-observed* counterpart to the client-side harness: it does not
try to assert anything about the client path, only that the server's
tick budget does not collapse under concurrent topic traffic at the
`PROJECT_RULES` 200-client scale.

The harness speaks BYOND's topic wire protocol directly (no python
shim, no `tools/topic.py` dependency) and parses the URL-encoded
response body for `tick_usage`.

### Prerequisites

1. A local DM server running the current `roguetown.dmb`, listening on
   `--host:--port`, with `?status` topic responses enabled (the
   tgstation-derivative default). The `Build All (Local Testing)` task
   plus `BUILD.cmd` will produce a suitable server on the configured
   world port.
2. The server should be idle (no other load). For representative
   results, log a test character in but do not interact.
3. An open piercing or taur editor on that character is recommended so
   the measurement includes the tgui push/pull cost the editors really
   incur during a round.

### How to run

```
bun tools/build/appearance_preview/loadtest/spam_inputs.ts \
  --against-server \
  --host 127.0.0.1 --port 1337 \
  --clients 200 \
  --rate 200 \
  --duration 30 \
  --tick-budget-ratio 2.5
```

| Flag                      | Default       | Purpose                                                                      |
| ------------------------- | ------------- | ---------------------------------------------------------------------------- |
| `--against-server`        | off           | Switches to server mode.                                                     |
| `--host <addr>`           | `127.0.0.1`   | Server TCP host.                                                             |
| `--port <n>`              | `1337`        | Server TCP port.                                                             |
| `--clients <n>`           | `200`         | Max concurrent in-flight topic requests (mirrors player count).              |
| `--rate <ops/s>`          | `200`         | Aggregate topic calls per second across all clients.                         |
| `--duration <s>`          | `30`          | Burst duration.                                                              |
| `--tick-budget-ratio <x>` | `2.5`         | Max tolerated `p99(tick_usage) / baseline(tick_usage)` before failing out.   |

### How to read the output

One JSON line on stdout, e.g.:

```json
{
  "status": "ok",
  "mode": "against-server",
  "host": "127.0.0.1",
  "port": 1337,
  "clients": 200,
  "ratePerSecond": 200,
  "durationSeconds": 30,
  "totalTopicCalls": 6000,
  "topicErrors": 0,
  "meanLatencyMs": 3.1,
  "baselineTickUsage": 18.2,
  "tickUsageP50": 19.1,
  "tickUsageP99": 22.0,
  "observedRatio": 1.21,
  "tickBudgetRatio": 2.5
}
```

### Pass criteria

- `status` is `"ok"`.
- `topicErrors` is `0` (server accepted every request).
- `observedRatio <= tickBudgetRatio` — the tick panel stays flat under
  the worst-case scenario the rules encode.

### Failure modes

| `status`                  | Meaning                                                                           |
| ------------------------- | --------------------------------------------------------------------------------- |
| `topic_error`             | Server unreachable or rejected the baseline probe. Nothing was measured.          |
| `no_samples`              | Server accepted `?status` but did not return a parseable `tick_usage` key.        |
| `tick_budget_exceeded`    | p99/baseline exceeded `--tick-budget-ratio`; the server cost is not flat.         |

## Pairing with the bench harness

`bench.ts` measures the **build-time** side. Pass `--materialize --dmb
<path>` to include the headless DM PNG-encode stage in the cold-path
timings (Step 6 + Step 12):

```
bun tools/build/appearance_preview/bench.ts \
  --runs 3 \
  --materialize --dmb roguetown.dmb
```

`spam_inputs.ts` measures the **runtime** side in either client-only or
live-server mode. Run both to get a complete picture:

```
# Build-time (cold includes materialize)
bun tools/build/appearance_preview/bench.ts --runs 3 --materialize --dmb roguetown.dmb

# Client-side runtime lookup path
bun tools/build/appearance_preview/loadtest/spam_inputs.ts

# Server-side runtime topic path (needs a running DM server)
bun tools/build/appearance_preview/loadtest/spam_inputs.ts --against-server
```

## CI recommendation

Wire the client-mode harness and `bench.ts` into the same CI job that
runs the DM unit tests. `--against-server` mode requires a live DM
server and is better scheduled as a periodic perf job rather than
per-commit. Exit codes:

- `0` — all good.
- `1` — hard failure (bench: one or more runs failed; client harness:
  drift detected; server harness: `topic_error`, `no_samples`, or
  `tick_budget_exceeded`).
- `2` — bench-only: warm regime did not short-circuit via cache (cache
  key invalidation-axis regression).
- `3` — bench-only: `--materialize` was supplied and the headless DM
  encode failed for at least one cold iteration.

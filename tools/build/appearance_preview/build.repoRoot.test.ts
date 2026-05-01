/**
 * tools/build/appearance_preview/build.repoRoot.test.ts
 *
 * Remediation Step 10 coverage for the `repoRoot !== process.cwd()`
 * cache-coherence fix (Remediation Step 2). Before that fix, `buildSheets`
 * silently re-ran `adapter.discoverSources(process.cwd())` during the pack
 * stage, so a programmatic caller with a non-cwd `repoRoot` produced a
 * fingerprint keyed on one source set and a published plan keyed on
 * another — the cache key and the bundle contents could disagree.
 *
 * This test re-derives the cache key through the same code path build.ts
 * uses (scan + fingerprint + computeCacheKey) but with two different
 * cwds for the surrounding process. A fresh checkout is not required:
 * we verify that the scan+fingerprint+keygen pipeline is anchored to the
 * explicit `repoRoot` argument, not to whatever `process.cwd()` happens
 * to be when the orchestrator is invoked.
 *
 * Expected behaviour: the cache key is identical regardless of cwd, and
 * the discovered source sets match byte-for-byte (no extra or missing
 * entries when cwd drifts).
 */

import { describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import { loadAdapters } from "./adapters";
import type { AdapterDiscovery } from "./adapters/contract";
import { fingerprintFiles } from "./adapters/source_scan";
import { computeCacheKey } from "./cache";
import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  type SourceFileEntry,
} from "./types";

/** Absolute repo root, derived from this test file's location. */
const REPO_ROOT = path.resolve(__dirname, "..", "..", "..");
const ADAPTER_CONFIG = path.join(
  REPO_ROOT,
  "tools",
  "build",
  "appearance_preview",
  "config",
  "adapters.json",
);

/**
 * Emulate the exact scan + hash stages in build.ts. Returns the computed
 * cache key plus the union of every discovered source entry so tests can
 * also assert set equality, not just key equality.
 */
function scanAndKey(
  repoRoot: string,
): { cacheKey: string; sources: readonly SourceFileEntry[] } {
  const adapters = loadAdapters(ADAPTER_CONFIG);
  const discoveries = new Map<string, AdapterDiscovery>();
  for (const adapter of adapters) {
    discoveries.set(adapter.record.family, adapter.discoverSources(repoRoot));
  }
  const allSources: SourceFileEntry[] = [];
  for (const discovery of discoveries.values()) {
    for (const entry of discovery.sources) allSources.push(entry);
  }
  const sourceFingerprint = fingerprintFiles(repoRoot, allSources);
  const adapterVersions: Record<string, string> = {};
  for (const adapter of adapters) {
    adapterVersions[adapter.record.family] = adapter.record.adapterVersion;
  }
  const cacheKey = computeCacheKey({
    manifestVersion: APPEARANCE_PREVIEW_MANIFEST_VERSION,
    backend: APPEARANCE_PREVIEW_BACKEND_ID,
    adapterVersions,
    sourceFingerprint,
  });
  return { cacheKey, sources: allSources };
}

describe("build pipeline repoRoot independence", () => {
  it("scan + key derivation is identical whether cwd matches repoRoot or not", () => {
    const originalCwd = process.cwd();
    // Anchor: cwd === repoRoot (the canonical invocation).
    process.chdir(REPO_ROOT);
    const matched = scanAndKey(REPO_ROOT);

    // Run 2: cwd is a throwaway temp dir unrelated to the repo. This
    // mirrors the bug scenario: a programmatic caller setting `repoRoot`
    // to the real repo but inheriting an unrelated working directory from
    // its parent process.
    const stray = fs.mkdtempSync(
      path.join(os.tmpdir(), "appearance-preview-reporoot-"),
    );
    try {
      process.chdir(stray);
      const drifted = scanAndKey(REPO_ROOT);
      expect(drifted.cacheKey).toBe(matched.cacheKey);

      // Belt-and-braces: the discovered source set must match byte-for-byte.
      // Compare as sorted path lists so iteration order differences are not
      // treated as a failure.
      const paths = (entries: readonly SourceFileEntry[]) =>
        entries.map((e) => e.path).sort();
      expect(paths(drifted.sources)).toEqual(paths(matched.sources));
    } finally {
      process.chdir(originalCwd);
      try {
        fs.rmSync(stray, { recursive: true, force: true });
      } catch {
        // Non-fatal: the tempdir cleanup is a courtesy, not a correctness
        // requirement.
      }
    }
  });

  it("derived cache key is non-empty and hex-encoded", () => {
    // Guard against a scenario where both runs happen to produce the same
    // empty string due to a parser regression; pin the shape.
    const { cacheKey } = scanAndKey(REPO_ROOT);
    expect(cacheKey).toMatch(/^[0-9a-f]{32}$/);
  });
});

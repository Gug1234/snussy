/**
 * tools/build/appearance_preview/cache.ts
 *
 * Persistent on-disk build cache for the appearance preview pipeline.
 *
 * Cache invalidation axes (per the spec's "Cache keys should include source
 * fingerprints, manifest version, backend identifier, and adapter version"):
 *   - Manifest schema version (`APPEARANCE_PREVIEW_MANIFEST_VERSION`).
 *   - Backend identifier (`APPEARANCE_PREVIEW_BACKEND_ID`).
 *   - Per-adapter `adapterVersion`.
 *   - `sourceFingerprint` over every adapter's discovered source files.
 *
 * Granularity: one cache key per build. Per-family granularity is not needed
 * yet — the registered adapter set is small and the orchestrator rebuilds
 * everything atomically. If a future refactor adds many families, splitting
 * the cache by family becomes worthwhile; the data shape here already names
 * `adapterVersions` so that change is additive.
 *
 * Storage: a single JSON file at `<cacheDir>/cache.json`. Atomic write via
 * write-temp-then-rename so a crashed build never leaves a half-written
 * cache file behind.
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { createHash, randomBytes } from "node:crypto";

import type { BackendId } from "./types";

/**
 * Components folded into the cache key. All fields are deterministic given
 * the same source set + adapter implementation versions.
 */
export interface CacheKeyInput {
  manifestVersion: number;
  backend: BackendId;
  /** `family -> adapterVersion`. Iteration order normalized when hashing. */
  adapterVersions: Record<string, string>;
  /** Fingerprint over the union of every adapter's source files. */
  sourceFingerprint: string;
}

/** On-disk cache record. */
interface CacheRecord {
  /** Schema version of the cache file itself. Bump on shape changes. */
  cacheSchema: 1;
  /** Hex digest produced by `computeCacheKey`. */
  key: string;
  /** Absolute path of the manifest the keyed build published. */
  manifestPath: string;
  /** ISO timestamp of the keyed build. */
  publishedAt: string;
}

/**
 * Compute the deterministic cache key for a build. Pure function — no I/O.
 */
export function computeCacheKey(input: CacheKeyInput): string {
  const hash = createHash("sha256");
  hash.update(`v${input.manifestVersion}`);
  hash.update("\0");
  hash.update(input.backend);
  hash.update("\0");
  // Sort adapter family names so the hash is stable regardless of iteration
  // order in the caller.
  const families = Object.keys(input.adapterVersions).sort();
  for (const family of families) {
    hash.update(family);
    hash.update("=");
    hash.update(input.adapterVersions[family]);
    hash.update("\0");
  }
  hash.update(input.sourceFingerprint);
  return hash.digest("hex").slice(0, 32);
}

/** Resolve the canonical cache file path inside `cacheDir`. */
function cacheFilePath(cacheDir: string): string {
  return path.join(path.resolve(cacheDir), "cache.json");
}

/**
 * Read the cached record, if any. Returns `null` when the cache file does
 * not exist, is unreadable, or fails the schema check. Treating malformed
 * cache as "miss" is intentional: a corrupt cache must never block a build.
 */
export function readCache(cacheDir: string): CacheRecord | null {
  const file = cacheFilePath(cacheDir);
  if (!fs.existsSync(file)) return null;
  let raw: string;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
  try {
    const parsed = JSON.parse(raw) as Partial<CacheRecord>;
    if (parsed.cacheSchema !== 1) return null;
    if (typeof parsed.key !== "string") return null;
    if (typeof parsed.manifestPath !== "string") return null;
    if (typeof parsed.publishedAt !== "string") return null;
    return parsed as CacheRecord;
  } catch {
    return null;
  }
}

/**
 * Atomically write a cache record. Creates `cacheDir` if it does not exist.
 * Failures are surfaced — a build that successfully published but cannot
 * persist its cache would silently re-run every time, which we want to
 * notice rather than ignore.
 */
export function writeCache(
  cacheDir: string,
  key: string,
  manifestPath: string,
): void {
  const dir = path.resolve(cacheDir);
  fs.mkdirSync(dir, { recursive: true });
  const target = cacheFilePath(dir);
  const tempName = `cache.json.tmp-${randomBytes(4).toString("hex")}`;
  const tempPath = path.join(dir, tempName);
  const record: CacheRecord = {
    cacheSchema: 1,
    key,
    manifestPath: path.resolve(manifestPath),
    publishedAt: new Date().toISOString(),
  };
  fs.writeFileSync(tempPath, JSON.stringify(record, null, 2), "utf8");
  fs.renameSync(tempPath, target);
}

/**
 * Determine whether the cache record is a hit for the supplied key AND the
 * referenced manifest still exists on disk. The manifest existence check
 * defends against a manual `rm -rf` of the public bundle while the cache
 * file survived.
 *
 * When `cacheDir` is supplied and the record is rejected because the
 * referenced manifest no longer exists, the stale `cache.json` is unlinked
 * so a future introspection of `cacheDir` is not misled by a dangling
 * record. Unlink failures are swallowed — the cache is advisory and the
 * build proceeds as a miss regardless.
 */
export function isCacheHit(
  record: CacheRecord | null,
  key: string,
  cacheDir?: string,
): record is CacheRecord {
  if (!record) return false;
  if (record.key !== key) return false;
  if (!fs.existsSync(record.manifestPath)) {
    if (cacheDir) {
      try {
        fs.unlinkSync(cacheFilePath(cacheDir));
      } catch {
        // Advisory cleanup only — a failure here is non-fatal; the next
        // successful build will overwrite the stale file.
      }
    }
    return false;
  }
  return true;
}

/**
 * tools/build/appearance_preview/cache.test.ts
 *
 * Step 14 coverage for the persistent build cache helpers. Exercises:
 *   - computeCacheKey determinism + sensitivity to every invalidation axis.
 *   - readCache returns null on missing file, malformed JSON, and wrong schema.
 *   - writeCache writes atomically (no temp file left behind) and creates the
 *     cache directory on demand.
 *   - isCacheHit rejects null, mismatched keys, and vanished manifests.
 */

import { describe, expect, it, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import {
  computeCacheKey,
  isCacheHit,
  readCache,
  writeCache,
  type CacheKeyInput,
} from "./cache";

function baseInput(): CacheKeyInput {
  return {
    manifestVersion: 2,
    backend: "rustg_iconforge",
    adapterVersions: { taur_offsets: "1.0.0", custom_piercings: "1.0.0" },
    sourceFingerprint: "abc123",
  };
}

function mkTempDir(prefix: string): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

describe("computeCacheKey", () => {
  it("is deterministic across calls with the same input", () => {
    expect(computeCacheKey(baseInput())).toBe(computeCacheKey(baseInput()));
  });

  it("is independent of adapterVersions iteration order", () => {
    const a = computeCacheKey(baseInput());
    const reversed: CacheKeyInput = {
      ...baseInput(),
      adapterVersions: {
        custom_piercings: "1.0.0",
        taur_offsets: "1.0.0",
      },
    };
    expect(computeCacheKey(reversed)).toBe(a);
  });

  it("changes when manifestVersion changes", () => {
    const a = computeCacheKey(baseInput());
    const b = computeCacheKey({ ...baseInput(), manifestVersion: 3 });
    expect(a).not.toBe(b);
  });

  it("changes when any adapterVersion changes", () => {
    const a = computeCacheKey(baseInput());
    const b = computeCacheKey({
      ...baseInput(),
      adapterVersions: { taur_offsets: "1.0.1", custom_piercings: "1.0.0" },
    });
    expect(a).not.toBe(b);
  });

  it("changes when sourceFingerprint changes", () => {
    const a = computeCacheKey(baseInput());
    const b = computeCacheKey({ ...baseInput(), sourceFingerprint: "def456" });
    expect(a).not.toBe(b);
  });

  it("changes when an adapter is added", () => {
    const a = computeCacheKey(baseInput());
    const b = computeCacheKey({
      ...baseInput(),
      adapterVersions: {
        taur_offsets: "1.0.0",
        custom_piercings: "1.0.0",
        new_family: "1.0.0",
      },
    });
    expect(a).not.toBe(b);
  });
});

describe("readCache", () => {
  let dir: string;
  beforeEach(() => {
    dir = mkTempDir("apvp-cache-read-");
  });
  afterEach(() => {
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it("returns null when the cache file is absent", () => {
    expect(readCache(dir)).toBeNull();
  });

  it("returns null when the cache file is not valid JSON", () => {
    fs.writeFileSync(path.join(dir, "cache.json"), "not-json", "utf8");
    expect(readCache(dir)).toBeNull();
  });

  it("returns null when cacheSchema does not match", () => {
    fs.writeFileSync(
      path.join(dir, "cache.json"),
      JSON.stringify({ cacheSchema: 99, key: "k", manifestPath: "x", publishedAt: "t" }),
      "utf8",
    );
    expect(readCache(dir)).toBeNull();
  });

  it("returns null when a required field is missing", () => {
    fs.writeFileSync(
      path.join(dir, "cache.json"),
      JSON.stringify({ cacheSchema: 1, key: "k" }),
      "utf8",
    );
    expect(readCache(dir)).toBeNull();
  });
});

describe("writeCache", () => {
  let dir: string;
  beforeEach(() => {
    dir = mkTempDir("apvp-cache-write-");
  });
  afterEach(() => {
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it("creates the cache directory when missing", () => {
    const nested = path.join(dir, "nested", "cache");
    const manifestPath = path.join(dir, "manifest.json");
    fs.writeFileSync(manifestPath, "{}", "utf8");
    writeCache(nested, "the-key", manifestPath);
    expect(fs.existsSync(path.join(nested, "cache.json"))).toBe(true);
  });

  it("round-trips through readCache", () => {
    const manifestPath = path.join(dir, "manifest.json");
    fs.writeFileSync(manifestPath, "{}", "utf8");
    writeCache(dir, "the-key", manifestPath);
    const record = readCache(dir);
    expect(record).not.toBeNull();
    expect(record!.key).toBe("the-key");
    expect(record!.manifestPath).toBe(path.resolve(manifestPath));
    expect(record!.cacheSchema).toBe(1);
  });

  it("leaves no .tmp- files behind after a successful write", () => {
    const manifestPath = path.join(dir, "manifest.json");
    fs.writeFileSync(manifestPath, "{}", "utf8");
    writeCache(dir, "the-key", manifestPath);
    const stragglers = fs
      .readdirSync(dir)
      .filter((name: string) => name.startsWith("cache.json.tmp-"));
    expect(stragglers).toEqual([]);
  });
});

describe("isCacheHit", () => {
  let dir: string;
  beforeEach(() => {
    dir = mkTempDir("apvp-cache-hit-");
  });
  afterEach(() => {
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it("is false when the record is null", () => {
    expect(isCacheHit(null, "any")).toBe(false);
  });

  it("is false when the keys do not match", () => {
    const manifestPath = path.join(dir, "manifest.json");
    fs.writeFileSync(manifestPath, "{}", "utf8");
    writeCache(dir, "k1", manifestPath);
    const record = readCache(dir);
    expect(isCacheHit(record, "k2")).toBe(false);
  });

  it("is false when the referenced manifest no longer exists", () => {
    const manifestPath = path.join(dir, "manifest.json");
    fs.writeFileSync(manifestPath, "{}", "utf8");
    writeCache(dir, "k1", manifestPath);
    const record = readCache(dir);
    fs.rmSync(manifestPath);
    expect(isCacheHit(record, "k1")).toBe(false);
  });

  it("is true when key matches and manifest exists", () => {
    const manifestPath = path.join(dir, "manifest.json");
    fs.writeFileSync(manifestPath, "{}", "utf8");
    writeCache(dir, "k1", manifestPath);
    const record = readCache(dir);
    expect(isCacheHit(record, "k1")).toBe(true);
  });
});

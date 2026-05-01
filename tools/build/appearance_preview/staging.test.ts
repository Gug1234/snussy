/**
 * tools/build/appearance_preview/staging.test.ts
 *
 * Step 14 coverage for the rename-based atomic publish helpers. Exercises:
 *   - createStagingRoot: creates a sibling staging directory, never a child.
 *   - publishStaging happy paths: no prior bundle + existing prior bundle.
 *   - publishStaging error paths: missing staging, cross-parent staging,
 *     PublishLockError surfaced when the previous bundle cannot be moved
 *     aside (simulated via an open file handle on Windows).
 *   - rollbackStaging: best-effort cleanup, never touches the live tree.
 *
 * The "publish failure" scenario from the plan is exercised by the
 * lock-held test: on Windows, an open file handle inside the live bundle
 * causes the rename-aside step to fail, and the publishStaging contract
 * guarantees the live tree is preserved.
 */

import { describe, expect, it, beforeEach, afterEach } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import {
  createStagingRoot,
  publishStaging,
  rollbackStaging,
} from "./staging";
import { PublishLockError, StagingInvalidError } from "./errors";

const IS_WINDOWS = process.platform === "win32";

function mkTempDir(prefix: string): string {
  return fs.mkdtempSync(path.join(os.tmpdir(), prefix));
}

/**
 * Write a throwaway file into a directory. Returns the absolute path of the
 * written file so callers can hold it open.
 */
function writeStub(dir: string, name: string, body = "stub"): string {
  const p = path.join(dir, name);
  fs.writeFileSync(p, body, "utf8");
  return p;
}

describe("createStagingRoot", () => {
  let parent: string;
  beforeEach(() => {
    parent = mkTempDir("apvp-staging-create-");
  });
  afterEach(() => {
    fs.rmSync(parent, { recursive: true, force: true });
  });

  it("creates a sibling directory with the expected suffix", () => {
    const publicRoot = path.join(parent, "bundle");
    const staging = createStagingRoot(publicRoot);
    expect(path.dirname(staging)).toBe(path.resolve(parent));
    expect(path.basename(staging).startsWith("bundle.staging-")).toBe(true);
    expect(fs.statSync(staging).isDirectory()).toBe(true);
  });

  it("does not create the public root", () => {
    const publicRoot = path.join(parent, "bundle");
    createStagingRoot(publicRoot);
    expect(fs.existsSync(publicRoot)).toBe(false);
  });

  it("each call produces a unique staging path", () => {
    const publicRoot = path.join(parent, "bundle");
    const a = createStagingRoot(publicRoot);
    const b = createStagingRoot(publicRoot);
    expect(a).not.toBe(b);
  });
});

describe("publishStaging", () => {
  let parent: string;
  beforeEach(() => {
    parent = mkTempDir("apvp-staging-publish-");
  });
  afterEach(() => {
    fs.rmSync(parent, { recursive: true, force: true });
  });

  it("promotes staging when no live bundle exists", () => {
    const publicRoot = path.join(parent, "bundle");
    const staging = createStagingRoot(publicRoot);
    writeStub(staging, "manifest.json", "{}");
    const result = publishStaging(publicRoot, staging);
    expect(result.publishedPath).toBe(path.resolve(publicRoot));
    expect(result.displacedPath).toBeNull();
    expect(fs.existsSync(path.join(publicRoot, "manifest.json"))).toBe(true);
    expect(fs.existsSync(staging)).toBe(false);
  });

  it("displaces and cleans up the previous live bundle", () => {
    const publicRoot = path.join(parent, "bundle");
    fs.mkdirSync(publicRoot);
    writeStub(publicRoot, "old.json", "old");

    const staging = createStagingRoot(publicRoot);
    writeStub(staging, "manifest.json", "{}");

    const result = publishStaging(publicRoot, staging);
    expect(result.displacedPath).not.toBeNull();
    expect(fs.existsSync(path.join(publicRoot, "manifest.json"))).toBe(true);
    expect(fs.existsSync(path.join(publicRoot, "old.json"))).toBe(false);
    expect(fs.existsSync(result.displacedPath!)).toBe(false);
    expect(result.displacedCleanedUp).toBe(true);
  });

  it("throws StagingInvalidError when staging root does not exist", () => {
    const publicRoot = path.join(parent, "bundle");
    const bogus = path.join(parent, "bundle.staging-ghost");
    expect(() => publishStaging(publicRoot, bogus)).toThrow(StagingInvalidError);
  });

  it("throws StagingInvalidError when staging is not a sibling", () => {
    const publicRoot = path.join(parent, "bundle");
    const otherParent = mkTempDir("apvp-staging-sibling-");
    try {
      const staging = path.join(otherParent, "bundle.staging-xyz");
      fs.mkdirSync(staging);
      expect(() => publishStaging(publicRoot, staging)).toThrow(
        StagingInvalidError,
      );
    } finally {
      fs.rmSync(otherParent, { recursive: true, force: true });
    }
  });

  // This test reproduces the WinError 145 scenario that motivated the pivot:
  // the live bundle is the process CWD, which Windows refuses to rename.
  // POSIX rename() does not care about CWD, so we only run this on Windows.
  (IS_WINDOWS ? it : it.skip)(
    "throws PublishLockError and preserves the live bundle when the rename-aside fails",
    () => {
      const publicRoot = path.join(parent, "bundle");
      fs.mkdirSync(publicRoot);
      writeStub(publicRoot, "keep.json", "keep");

      const staging = createStagingRoot(publicRoot);
      writeStub(staging, "manifest.json", "{}");

      const originalCwd = process.cwd();
      process.chdir(publicRoot);
      try {
        expect(() => publishStaging(publicRoot, staging)).toThrow(
          PublishLockError,
        );
        process.chdir(originalCwd);
        // Live bundle is intact.
        expect(fs.existsSync(path.join(publicRoot, "keep.json"))).toBe(true);
        // Staging tree is also intact (publish never consumed it).
        expect(fs.existsSync(path.join(staging, "manifest.json"))).toBe(true);
      } finally {
        try {
          process.chdir(originalCwd);
        } catch {
          /* already restored */
        }
      }
    },
  );
});

describe("rollbackStaging", () => {
  let parent: string;
  beforeEach(() => {
    parent = mkTempDir("apvp-staging-rollback-");
  });
  afterEach(() => {
    fs.rmSync(parent, { recursive: true, force: true });
  });

  it("removes the staging tree", () => {
    const publicRoot = path.join(parent, "bundle");
    const staging = createStagingRoot(publicRoot);
    writeStub(staging, "manifest.json", "{}");
    rollbackStaging(staging);
    expect(fs.existsSync(staging)).toBe(false);
  });

  it("never touches the live bundle", () => {
    const publicRoot = path.join(parent, "bundle");
    fs.mkdirSync(publicRoot);
    writeStub(publicRoot, "keep.json", "keep");
    const staging = createStagingRoot(publicRoot);
    writeStub(staging, "manifest.json", "{}");
    rollbackStaging(staging);
    expect(fs.existsSync(path.join(publicRoot, "keep.json"))).toBe(true);
  });

  it("is a no-op on a non-existent path", () => {
    expect(() => rollbackStaging(path.join(parent, "ghost"))).not.toThrow();
  });
});

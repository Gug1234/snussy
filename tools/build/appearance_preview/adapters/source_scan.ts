/**
 * tools/build/appearance_preview/adapters/source_scan.ts
 *
 * Shared source-scanning utilities used by every concrete adapter. Adapters
 * are forbidden from doing arbitrary I/O (see `contract.ts`), so anything
 * that reads or hashes a file lives here where it can be tested in isolation
 * (Step 14).
 *
 * Provided helpers:
 * - `requireFile(absPath, family)`: hard-fails with `InvalidSourceError` if
 *   the file is missing. Adapters call this once per declared DMI before
 *   discovery so the build aborts before sheet packing rather than after.
 * - `dmiSourceEntry(repoRoot, repoRelativePath, family)`: builds a
 *   `SourceFileEntry` (path normalized to forward slashes, mtime stamped
 *   from disk). Does not read file bytes; the fingerprint pass does.
 * - `fingerprintFiles(repoRoot, entries)`: stable fingerprint over a sorted
 *   set of entries. Reads file bytes and folds them into a sha256 truncated
 *   to 16 hex chars. Content-hashed (not mtime-based) so a fresh checkout
 *   and a local workspace produce identical keys for identical content.
 */

import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as path from "node:path";

import { InvalidSourceError } from "../errors";
import type { SourceFileEntry } from "../types";

/**
 * Throw `InvalidSourceError` if `absPath` does not exist or is not a regular
 * file. Returns the resolved absolute path on success.
 *
 * @param absPath Absolute filesystem path to check.
 * @param family Adapter family for the error message; helps users find the
 *   adapter that referenced the missing file.
 */
export function requireFile(absPath: string, family: string): string {
  let stat: fs.Stats;
  try {
    stat = fs.statSync(absPath);
  } catch (err) {
    throw new InvalidSourceError(
      `Adapter "${family}" references missing source file: ${absPath}`,
      absPath,
      { cause: err as Error },
    );
  }
  if (!stat.isFile()) {
    throw new InvalidSourceError(
      `Adapter "${family}" source path is not a regular file: ${absPath}`,
      absPath,
    );
  }
  return absPath;
}

/**
 * Build a `SourceFileEntry` for a repo-relative path. Reads the file once to
 * compute a sha256 truncated to 16 hex chars (content-hashed).
 *
 * @param repoRoot Absolute repo root, supplied by the orchestrator.
 * @param repoRelativePath Path relative to `repoRoot`, e.g.
 *   `"modular/icons/obj/lewd/intimate_stickers.dmi"`.
 * @param family Adapter family for `requireFile` error messages.
 */
export function dmiSourceEntry(
  repoRoot: string,
  repoRelativePath: string,
  family: string,
): SourceFileEntry {
  const abs = requireFile(path.join(repoRoot, repoRelativePath), family);
  const stat = fs.statSync(abs);
  return {
    path: repoRelativePath.replace(/\\/g, "/"),
    mtimeMs: Math.trunc(stat.mtimeMs),
  };
}

/**
 * Stable fingerprint over a set of source entries. Inputs are sorted by path
 * before hashing so call order does not affect the output. Reads each file's
 * byte content so a touch-with-no-change does not invalidate the cache while
 * a real edit always does.
 *
 * @param repoRoot Absolute repo root, used to resolve `entry.path`.
 * @param entries Source entries to fold into the fingerprint.
 * @returns 16-char hex string. Suitable for use as a cache key component.
 */
export function fingerprintFiles(
  repoRoot: string,
  entries: readonly SourceFileEntry[],
): string {
  const sorted = [...entries].sort((a, b) => (a.path < b.path ? -1 : 1));
  const hash = crypto.createHash("sha256");
  for (const entry of sorted) {
    const abs = path.join(repoRoot, entry.path);
    const bytes = fs.readFileSync(abs);
    // Path + size + content; path keeps two same-content files distinct,
    // size makes collision investigation faster.
    hash.update(entry.path);
    hash.update("\0");
    hash.update(String(bytes.byteLength));
    hash.update("\0");
    hash.update(bytes);
    hash.update("\0");
  }
  return hash.digest("hex").slice(0, 16);
}

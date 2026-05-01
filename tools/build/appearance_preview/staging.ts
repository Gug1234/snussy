/**
 * tools/build/appearance_preview/staging.ts
 *
 * Atomic staging + publish helpers for appearance preview bundles.
 *
 * The previous Python exporter used `shutil.rmtree` on the live public bundle
 * before writing the new one, which hit `WinError 145` (ERROR_DIR_NOT_EMPTY)
 * whenever a sheet PNG was held open by an editor or asset cache. This module
 * never deletes the live tree before the new one is in place.
 *
 * Publish strategy (rename-based, crash-safe):
 *   1. `createStagingRoot(publicRoot)` returns a sibling directory
 *      `<publicRoot>.staging-<token>/` that the orchestrator writes into.
 *   2. After all sheets + the manifest are written and validated, the caller
 *      invokes `publishStaging(publicRoot, stagingRoot)`. That:
 *        a. Renames the existing live tree to `<publicRoot>.old-<token>/`
 *           (no-op if no live tree exists).
 *        b. Renames the staging tree to `<publicRoot>`.
 *        c. Best-effort removes the `.old-<token>/` tree. Failure here is
 *           non-fatal; the new bundle is already live.
 *   3. On any failure during steps (a) or (b), `rollbackStaging` restores the
 *      previous live tree if it was already moved aside.
 *
 * Step 1 scope: implementation + thorough JSDoc. Tests land in Step 14
 * (`staging.test.ts`).
 */

import * as fs from "node:fs";
import * as path from "node:path";
import { randomBytes } from "node:crypto";

import { PublishLockError, StagingInvalidError } from "./errors";

/** Result of a successful `publishStaging` call. */
export interface PublishResult {
  /** Absolute path to the new live bundle (always equals `publicRoot`). */
  publishedPath: string;
  /** Absolute path of the displaced previous bundle, or `null` if there was none. */
  displacedPath: string | null;
  /** Whether the displaced bundle was successfully cleaned up. */
  displacedCleanedUp: boolean;
}

/**
 * Generate a short, filesystem-safe token for staging / displaced suffixes.
 * Random rather than monotonic so concurrent build attempts cannot collide
 * on the same suffix.
 */
function makeToken(): string {
  return randomBytes(6).toString("hex");
}

/**
 * Create a fresh staging root next to `publicRoot`. Returns the absolute path.
 *
 * The staging directory is always a sibling, never a child, of the public
 * root. That guarantees `rename` is a same-filesystem operation on every
 * supported OS and avoids polluting the published tree if a build aborts
 * before publish.
 *
 * @param publicRoot Absolute or repo-relative target where the bundle will
 *   eventually be published (e.g. `tgui/public/appearance_preview`).
 * @returns Absolute path of the newly created staging directory.
 * @throws StagingInvalidError if the staging directory cannot be created.
 */
export function createStagingRoot(publicRoot: string): string {
  const absPublic = path.resolve(publicRoot);
  const parent = path.dirname(absPublic);
  const base = path.basename(absPublic);
  const token = makeToken();
  const staging = path.join(parent, `${base}.staging-${token}`);
  try {
    // `recursive: true` here only matters if the parent does not exist yet;
    // we never want to clobber an existing staging dir, so no `force` either.
    fs.mkdirSync(parent, { recursive: true });
    fs.mkdirSync(staging, { recursive: false });
  } catch (err) {
    throw new StagingInvalidError(
      staging,
      `Failed to create staging root at ${staging}`,
      { cause: err as Error },
    );
  }
  return staging;
}

/**
 * Atomically publish `stagingRoot` over `publicRoot`.
 *
 * Both paths must already exist. `stagingRoot` must be a sibling of
 * `publicRoot` (same parent directory) so the rename is single-filesystem.
 *
 * @param publicRoot Live bundle target.
 * @param stagingRoot Fully-populated staging directory to promote.
 * @returns A `PublishResult` describing the displaced previous bundle.
 * @throws PublishLockError if the live bundle cannot be moved aside (typically
 *   because a file inside it is held open by another process — the WinError
 *   145 case). The previous bundle remains intact when this is thrown.
 * @throws StagingInvalidError if the staging tree itself cannot be promoted.
 */
export function publishStaging(
  publicRoot: string,
  stagingRoot: string,
): PublishResult {
  const absPublic = path.resolve(publicRoot);
  const absStaging = path.resolve(stagingRoot);

  if (!fs.existsSync(absStaging)) {
    throw new StagingInvalidError(
      absStaging,
      `Staging root does not exist: ${absStaging}`,
    );
  }
  if (path.dirname(absStaging) !== path.dirname(absPublic)) {
    throw new StagingInvalidError(
      absStaging,
      `Staging root must be a sibling of publicRoot. ` +
        `staging=${absStaging} public=${absPublic}`,
    );
  }

  const token = makeToken();
  const displacedPath = path.join(
    path.dirname(absPublic),
    `${path.basename(absPublic)}.old-${token}`,
  );

  let displacedCreated = false;

  try {
    if (fs.existsSync(absPublic)) {
      // Step (a): move the live tree aside. If this fails on Windows because
      // a file is held open, the live tree is untouched — that is the
      // PublishLockError contract.
      try {
        fs.renameSync(absPublic, displacedPath);
        displacedCreated = true;
      } catch (err) {
        throw new PublishLockError(
          absPublic,
          `Failed to displace existing bundle at ${absPublic}. ` +
            `Another process likely holds a file open inside it.`,
          { cause: err as Error },
        );
      }
    }

    // Step (b): promote staging into place.
    try {
      fs.renameSync(absStaging, absPublic);
    } catch (err) {
      // Promotion failed after we already moved the live tree aside — restore
      // it so the previous bundle is preserved.
      if (displacedCreated) {
        try {
          fs.renameSync(displacedPath, absPublic);
        } catch {
          // If we cannot even restore, surface the original promotion failure
          // wrapped as PublishLockError so callers know the live tree is gone.
          throw new PublishLockError(
            absPublic,
            `Failed to promote staging tree AND failed to restore previous ` +
              `bundle. Manual recovery required from ${displacedPath}.`,
            { cause: err as Error },
          );
        }
      }
      throw new StagingInvalidError(
        absStaging,
        `Failed to promote staging tree to ${absPublic}.`,
        { cause: err as Error },
      );
    }
  } catch (err) {
    throw err;
  }

  // Step (c): best-effort cleanup of the displaced tree. Failure here does
  // not invalidate the publish — the new bundle is already live.
  let cleanedUp = false;
  if (displacedCreated) {
    try {
      fs.rmSync(displacedPath, { recursive: true, force: true });
      cleanedUp = true;
    } catch {
      // Intentional: leave the .old-<token> directory in place for manual
      // cleanup. Future runs use a different token so this never blocks.
      cleanedUp = false;
    }
  }

  return {
    publishedPath: absPublic,
    displacedPath: displacedCreated ? displacedPath : null,
    displacedCleanedUp: cleanedUp,
  };
}

/**
 * Discard a staging root that will not be promoted (e.g. because validation
 * failed before `publishStaging` was reached). Best-effort: failures are
 * swallowed so cleanup never masks the underlying build error.
 *
 * The live `publicRoot` is never touched by this helper — by definition the
 * staging tree was never promoted.
 *
 * @param stagingRoot Path returned by `createStagingRoot`.
 */
export function rollbackStaging(stagingRoot: string): void {
  const abs = path.resolve(stagingRoot);
  if (!fs.existsSync(abs)) {
    return;
  }
  try {
    fs.rmSync(abs, { recursive: true, force: true });
  } catch {
    // Intentional: never throw from rollback. The directory will be cleaned
    // up by the next staging cycle (different token) or by manual sweep.
  }
}

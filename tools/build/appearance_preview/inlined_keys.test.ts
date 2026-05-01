/**
 * tools/build/appearance_preview/inlined_keys.test.ts
 *
 * Remediation Step 10 drift detector for the manifest-key strings that
 * `code/modules/asset_cache/assets/appearance_preview.dm::mount_bundle`
 * inlines instead of `#define`-referencing.
 *
 * ## Why this test exists
 *
 * The DM asset loader is included earlier in `roguetown.dme` than
 * `modular/code/datums/appearance_preview/_defines.dm`, so the
 * preprocessor has not seen the `APPEARANCE_PREVIEW_*_KEY_*` defines at
 * the point the loader's list subscripts resolve. A header-comment block
 * in the asset file documents that the strings are inlined on purpose and
 * MUST be kept in lockstep with the defines — silent drift would manifest
 * only as a bundle-mount failure at world boot.
 *
 * This test walks the defines, collects every `APPEARANCE_PREVIEW_*_KEY_*`
 * string value, then walks the asset file's `list_var["literal"]` accesses
 * and asserts each literal is either:
 *
 *   - the value of one of those defines, or
 *   - explicitly in an allowlist of non-manifest keys (iconforge plan file
 *     keys such as `"jobs"` / `"spritesheetName"` that are owned by the
 *     TypeScript bridge, not the manifest taxonomy).
 *
 * If this test fails, either update the inlined literal to match the
 * renamed define, or add the new key to the allowlist below with a
 * comment explaining why it is not a taxonomy define.
 */

import { describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as path from "node:path";

/** Repo root relative to this test file. */
const REPO_ROOT = path.resolve(__dirname, "..", "..", "..");

const DEFINES_PATH = path.join(
  REPO_ROOT,
  "modular",
  "code",
  "datums",
  "appearance_preview",
  "_defines.dm",
);
const ASSET_PATH = path.join(
  REPO_ROOT,
  "code",
  "modules",
  "asset_cache",
  "assets",
  "appearance_preview.dm",
);

/**
 * Plan-file keys owned by `tools/build/appearance_preview/rustg_bridge.ts`,
 * not the DM manifest taxonomy. They do not have `#define`s in
 * `_defines.dm` and are not expected to. If the TS bridge renames one, the
 * failure surfaces as a mount-time log line rather than a compile error;
 * the Step 5 plan-authoritative validator is the primary protection.
 */
const PLAN_FILE_ALLOWLIST = new Set<string>([
  // Top-level plan envelope.
  "jobs",
  // Per-job fields (see `IconforgeJobPlan` in rustg_bridge.ts).
  "spritesheetName",
  "outputPath",
  "sprites",
  "hashIcons",
]);

/**
 * Parse `_defines.dm` and build a set of every string value assigned to a
 * `APPEARANCE_PREVIEW_*_KEY_*` constant. The DM preprocessor syntax is
 * `#define NAME "value"`; we ignore numeric/non-string defines.
 */
function collectCanonicalKeyValues(): Set<string> {
  const text = fs.readFileSync(DEFINES_PATH, "utf8");
  const values = new Set<string>();
  // Match `#define APPEARANCE_PREVIEW_<...>_KEY_<...> "value"` anywhere on a
  // line. Tolerates leading whitespace; rejects numeric defines.
  const re = /^\s*#define\s+(APPEARANCE_PREVIEW_[A-Z0-9_]*_KEY_[A-Z0-9_]+)\s+"([^"]+)"/gm;
  let match: RegExpExecArray | null;
  while ((match = re.exec(text)) !== null) {
    values.add(match[2]);
  }
  return values;
}

/**
 * Scan the asset loader for every `identifier["literal"]` subscript whose
 * receiver is one of the manifest/plan locals the loader walks. Returns
 * the de-duped set of literals actually referenced.
 *
 * Known receivers are a static list — the loader is a small file and new
 * list locals should be added here deliberately so the test keeps its
 * signal-to-noise ratio high.
 */
function collectInlinedKeyLiterals(): Set<string> {
  const text = fs.readFileSync(ASSET_PATH, "utf8");
  const receivers = [
    "manifest",
    "manifest_sheets",
    "sheets_by_family",
    "sheet",
    "plan",
    "job",
    "job_sheet",
  ];
  const literals = new Set<string>();
  for (const receiver of receivers) {
    // `receiver["literal"]` with optional whitespace between the receiver
    // and the `[`. Literals are double-quoted non-empty strings.
    const re = new RegExp(`\\b${receiver}\\s*\\[\\s*"([^"\\\\]+)"`, "g");
    let match: RegExpExecArray | null;
    while ((match = re.exec(text)) !== null) {
      literals.add(match[1]);
    }
  }
  return literals;
}

describe("appearance_preview.dm manifest-key drift", () => {
  it("defines file exposes at least one taxonomy key", () => {
    // Sanity: the regex would silently yield an empty set if the define
    // naming convention drifted. Pin a non-zero floor so a future rename
    // that breaks the parser is caught here rather than producing a
    // misleading green test below.
    const canonical = collectCanonicalKeyValues();
    expect(canonical.size).toBeGreaterThanOrEqual(10);
  });

  it("asset loader inlines at least one manifest-key literal", () => {
    // Same sanity check for the consumer side — if the receiver list ever
    // stops matching reality the test should fail loud rather than pass
    // vacuously.
    const literals = collectInlinedKeyLiterals();
    expect(literals.size).toBeGreaterThanOrEqual(3);
  });

  it("every inlined literal is either a canonical define or an allowlisted plan key", () => {
    const canonical = collectCanonicalKeyValues();
    const literals = collectInlinedKeyLiterals();
    const unknown: string[] = [];
    for (const literal of literals) {
      if (canonical.has(literal)) continue;
      if (PLAN_FILE_ALLOWLIST.has(literal)) continue;
      unknown.push(literal);
    }
    expect(unknown).toEqual([]);
  });
});

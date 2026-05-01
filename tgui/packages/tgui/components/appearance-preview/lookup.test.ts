/**
 * @file lookup.test.ts
 * @description Step 14 drift detector between the tgui-side v2 type mirror in
 * `shared.ts` and the canonical build-side types in
 * `tools/build/appearance_preview/types.ts`.
 *
 * Why this test exists: the tgui tsconfig's `include` only covers
 * `packages/**`, so a direct import of the canonical types would silently
 * bypass the type checker. The tgui mirror is therefore a hand-copied
 * duplicate and needs a runtime guard against silent drift. This test reads
 * both files as text and compares the literal constants that govern
 * manifest compatibility.
 *
 * Drift axes checked:
 *   - APPEARANCE_PREVIEW_MANIFEST_VERSION numeric literal.
 *   - APPEARANCE_PREVIEW_BACKEND_ID string literal.
 *   - APPEARANCE_PREVIEW_LAYOUT_KIND string literal.
 *   - Canonical direction order tuple.
 *
 * If any of these drift, the tgui runtime and the build pipeline will
 * disagree about what a valid v2 manifest looks like — which is the exact
 * failure mode this refactor's fail-closed contract is designed to catch.
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

import { describe, expect, it } from 'bun:test';

const REPO_ROOT = path.resolve(import.meta.dir, '..', '..', '..', '..', '..');

const TGUI_SHARED_PATH = path.join(
  REPO_ROOT,
  'tgui',
  'packages',
  'tgui',
  'components',
  'appearance-preview',
  'shared.ts',
);
const BUILD_TYPES_PATH = path.join(
  REPO_ROOT,
  'tools',
  'build',
  'appearance_preview',
  'types.ts',
);

function readText(p: string): string {
  return fs.readFileSync(p, 'utf8');
}

/** Extract a numeric literal bound to `name` (e.g. `const NAME = 2;`). */
function extractNumber(source: string, name: string): number | null {
  const re = new RegExp(
    `(?:export\\s+)?(?:const|let)\\s+${name}\\s*(?::[^=]+)?=\\s*(\\d+)`,
  );
  const match = re.exec(source);
  return match ? Number(match[1]) : null;
}

/** Extract a string literal bound to `name`. Accepts single or double quotes. */
function extractString(source: string, name: string): string | null {
  const re = new RegExp(
    `(?:export\\s+)?(?:const|let)\\s+${name}\\s*(?::[^=]+)?=\\s*['"]([^'"]+)['"]`,
  );
  const match = re.exec(source);
  return match ? match[1] : null;
}

/** Extract the string members of a readonly tuple bound to `name`. */
function extractStringTuple(source: string, name: string): string[] | null {
  const re = new RegExp(
    `(?:export\\s+)?(?:const|let)\\s+${name}[^=]*=\\s*\\[([^\\]]+)\\]`,
  );
  const match = re.exec(source);
  if (!match) return null;
  const body = match[1];
  const items: string[] = [];
  const itemRe = /['"]([^'"]+)['"]/g;
  let m: RegExpExecArray | null;
  while ((m = itemRe.exec(body)) !== null) {
    items.push(m[1]);
  }
  return items;
}

describe('appearance preview v2 type mirror drift detector', () => {
  const tgui = readText(TGUI_SHARED_PATH);
  const build = readText(BUILD_TYPES_PATH);

  it('manifest version constant matches', () => {
    const tguiVer = extractNumber(tgui, 'APPEARANCE_PREVIEW_MANIFEST_VERSION');
    const buildVer = extractNumber(
      build,
      'APPEARANCE_PREVIEW_MANIFEST_VERSION',
    );
    expect(tguiVer).not.toBeNull();
    expect(buildVer).not.toBeNull();
    expect(tguiVer).toBe(buildVer);
  });

  it('backend id constant matches', () => {
    const tguiId = extractString(tgui, 'APPEARANCE_PREVIEW_BACKEND_ID');
    const buildId = extractString(build, 'APPEARANCE_PREVIEW_BACKEND_ID');
    expect(tguiId).not.toBeNull();
    expect(buildId).not.toBeNull();
    expect(tguiId).toBe(buildId);
  });

  it('layout kind constant matches', () => {
    const tguiKind = extractString(tgui, 'APPEARANCE_PREVIEW_LAYOUT_KIND');
    const buildKind = extractString(build, 'APPEARANCE_PREVIEW_LAYOUT_KIND');
    expect(tguiKind).not.toBeNull();
    expect(buildKind).not.toBeNull();
    expect(tguiKind).toBe(buildKind);
  });

  it('canonical direction order matches', () => {
    const tguiOrder = extractStringTuple(
      tgui,
      'APPEARANCE_PREVIEW_V2_DIRECTION_ORDER',
    );
    const buildOrder = extractStringTuple(build, 'DEFAULT_DIRECTION_ORDER');
    expect(tguiOrder).not.toBeNull();
    expect(buildOrder).not.toBeNull();
    expect(tguiOrder).toEqual(buildOrder!);
  });
});

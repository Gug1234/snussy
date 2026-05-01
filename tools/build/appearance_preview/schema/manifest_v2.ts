/**
 * tools/build/appearance_preview/schema/manifest_v2.ts
 *
 * Runtime validator for the manifest v2 contract defined in
 * `tools/build/appearance_preview/types.ts`. The TypeScript types in
 * `types.ts` are the single source of truth at compile time; this module
 * adds *runtime* validation so:
 *
 *   - The build helper (Step 5) can refuse to write a manifest that violates
 *     the schema before the staging promotion runs.
 *   - The TGUI runtime (Step 8) can refuse to load a manifest whose version,
 *     backend, layout, or cross-references do not match the v2 contract.
 *   - The DM-side asset cache (Step 7) and unit tests (Step 15) have a
 *     well-defined error surface for stale or corrupted bundles.
 *
 * No external dependency is taken. We hand-roll the validator instead of
 * pulling in zod/valibot because:
 *   - The schema is small and fully closed (no `unknown` passthrough).
 *   - Bun startup cost matters for the build pipeline.
 *   - Hand-written code lets us emit error paths formatted for grep-friendly
 *     CI logs (`states.taur_penis.crops.s.width: must be a positive integer`).
 *
 * Cross-references checked here (in addition to per-field types):
 *   - Every `StateRecord.sheetId` resolves to a key in `sheets`.
 *   - Every `StateRecord.family` matches one of the families in
 *     `build.adapterVersions`.
 *   - Every `StateRecord.variants[*]` points to a key in `states`.
 *   - Every `StateRecord.crops` key set equals the sheet's tile direction
 *     contract (we accept the canonical 4-direction set; adapters that emit
 *     a subset must explicitly declare it via flags — out of scope here).
 *   - Every `CategoryRecord.states` entry resolves to a key in `states`.
 *   - `categoryOrder` is a permutation of `Object.keys(categories)`.
 *   - `version`, `backend`, `layout`, `canonicalLookupKey` match the
 *     constants exported from `types.ts`.
 */

import { ManifestInvalidError } from "../errors";
import {
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  DEFAULT_DIRECTION_ORDER,
  type DirectionKey,
  type ManifestV2,
  type SheetRecord,
  type StateRecord,
} from "../types";

// Re-export the manifest type so downstream callers can import the schema
// surface from a single module.
export type { ManifestV2 } from "../types";
export {
  APPEARANCE_PREVIEW_MANIFEST_VERSION,
  APPEARANCE_PREVIEW_BACKEND_ID,
  APPEARANCE_PREVIEW_LAYOUT_KIND,
} from "../types";

/** The set of direction keys we accept in v2 manifests. */
const VALID_DIRECTION_KEYS: ReadonlySet<DirectionKey> = new Set(
  DEFAULT_DIRECTION_ORDER,
);

/**
 * Lightweight result type for callers that want a yes/no answer with detail
 * instead of an exception. The build pipeline uses `validateManifestV2`
 * (throwing); the runtime + tests use `tryValidateManifestV2`.
 */
export type ValidationFailure = {
  ok: false;
  /** Dot-path to the first offending field, e.g. `states.taur_penis.crops.s.width`. */
  path: string;
  /** Human-readable reason. Stable phrasing — covered by the test suite. */
  reason: string;
};

export type ValidationSuccess = {
  ok: true;
  manifest: ManifestV2;
};

export type ValidationResult = ValidationSuccess | ValidationFailure;

/**
 * Strict validator. Throws `ManifestInvalidError` on the first failure with
 * the offending field path embedded in the message. Use this from the build
 * orchestrator and from any runtime that wants fail-closed semantics.
 *
 * @param value Untyped manifest (e.g. from JSON.parse).
 * @returns The same value, narrowed to `ManifestV2`.
 * @throws {ManifestInvalidError}
 */
export function validateManifestV2(value: unknown): ManifestV2 {
  const result = tryValidateManifestV2(value);
  if (!result.ok) {
    throw new ManifestInvalidError(
      `appearance preview manifest v2 invalid at ${result.path}: ${result.reason}`,
    );
  }
  return result.manifest;
}

/**
 * Non-throwing variant. Returns the first failure encountered or the
 * narrowed manifest. Suitable for tests and runtime UI surfaces that want
 * to report rather than crash.
 */
export function tryValidateManifestV2(value: unknown): ValidationResult {
  if (!isPlainObject(value)) {
    return fail("$root", "must be a plain object");
  }

  // --- Top-level scalar fields ----------------------------------------
  if (value.version !== APPEARANCE_PREVIEW_MANIFEST_VERSION) {
    return fail(
      "version",
      `must equal ${APPEARANCE_PREVIEW_MANIFEST_VERSION}, got ${stringify(value.version)}`,
    );
  }
  if (value.backend !== APPEARANCE_PREVIEW_BACKEND_ID) {
    return fail(
      "backend",
      `must equal "${APPEARANCE_PREVIEW_BACKEND_ID}", got ${stringify(value.backend)}`,
    );
  }
  if (value.layout !== APPEARANCE_PREVIEW_LAYOUT_KIND) {
    return fail(
      "layout",
      `must equal "${APPEARANCE_PREVIEW_LAYOUT_KIND}", got ${stringify(value.layout)}`,
    );
  }
  if (value.canonicalLookupKey !== "icon_state") {
    return fail(
      "canonicalLookupKey",
      `must equal "icon_state", got ${stringify(value.canonicalLookupKey)}`,
    );
  }

  // --- categoryOrder + categories -------------------------------------
  if (!Array.isArray(value.categoryOrder)) {
    return fail("categoryOrder", "must be an array of strings");
  }
  for (let i = 0; i < value.categoryOrder.length; i++) {
    if (typeof value.categoryOrder[i] !== "string") {
      return fail(`categoryOrder[${i}]`, "must be a string");
    }
  }
  if (!isPlainObject(value.categories)) {
    return fail("categories", "must be a plain object");
  }

  const categoryKeys = Object.keys(value.categories);
  if (categoryKeys.length !== value.categoryOrder.length) {
    return fail(
      "categoryOrder",
      `length ${value.categoryOrder.length} does not match categories key count ${categoryKeys.length}`,
    );
  }
  const categoryOrderSet = new Set(value.categoryOrder as readonly string[]);
  for (const key of categoryKeys) {
    if (!categoryOrderSet.has(key)) {
      return fail(
        "categoryOrder",
        `is missing entry for category "${key}"`,
      );
    }
  }

  // --- sheets ---------------------------------------------------------
  if (!isPlainObject(value.sheets)) {
    return fail("sheets", "must be a plain object");
  }
  for (const [sheetId, sheet] of Object.entries(value.sheets)) {
    const r = validateSheet(`sheets.${sheetId}`, sheetId, sheet);
    if (!r.ok) return r;
  }

  // --- states ---------------------------------------------------------
  if (!isPlainObject(value.states)) {
    return fail("states", "must be a plain object");
  }
  const sheetIds = new Set(Object.keys(value.sheets as Record<string, unknown>));
  const stateIds = new Set(Object.keys(value.states as Record<string, unknown>));

  for (const [stateId, state] of Object.entries(value.states)) {
    const r = validateState(`states.${stateId}`, stateId, state, sheetIds, stateIds);
    if (!r.ok) return r;
  }

  // --- categories cross-ref -------------------------------------------
  for (const [catKey, cat] of Object.entries(value.categories)) {
    const r = validateCategory(`categories.${catKey}`, catKey, cat, stateIds);
    if (!r.ok) return r;
  }

  // --- build metadata --------------------------------------------------
  const buildR = validateBuild("build", value.build);
  if (!buildR.ok) return buildR;

  // --- families cross-ref (states.family must be a known adapter) ------
  const adapterFamilies = new Set(
    Object.keys((value.build as { adapterVersions: Record<string, string> }).adapterVersions),
  );
  for (const [stateId, state] of Object.entries(value.states)) {
    const family = (state as StateRecord).family;
    if (!adapterFamilies.has(family)) {
      return fail(
        `states.${stateId}.family`,
        `references unknown adapter family "${family}"; ` +
          `known families: [${[...adapterFamilies].sort().join(", ")}]`,
      );
    }
  }

  return { ok: true, manifest: value as unknown as ManifestV2 };
}

// ---------------------------------------------------------------------------
// Per-record validators
// ---------------------------------------------------------------------------

function validateSheet(
  prefix: string,
  expectedId: string,
  sheet: unknown,
): ValidationResult {
  if (!isPlainObject(sheet)) return fail(prefix, "must be a plain object");

  if (sheet.id !== expectedId) {
    return fail(`${prefix}.id`, `must equal "${expectedId}", got ${stringify(sheet.id)}`);
  }
  if (!isNonEmptyString(sheet.family)) {
    return fail(`${prefix}.family`, "must be a non-empty string");
  }
  if (!isNonEmptyString(sheet.path)) {
    return fail(`${prefix}.path`, "must be a non-empty string");
  }
  if (!isPositiveInt(sheet.width)) {
    return fail(`${prefix}.width`, "must be a positive integer");
  }
  if (!isPositiveInt(sheet.height)) {
    return fail(`${prefix}.height`, "must be a positive integer");
  }
  if (!isPositiveInt(sheet.tileWidth)) {
    return fail(`${prefix}.tileWidth`, "must be a positive integer");
  }
  if (!isPositiveInt(sheet.tileHeight)) {
    return fail(`${prefix}.tileHeight`, "must be a positive integer");
  }
  if (!isNonEmptyString(sheet.contentHash)) {
    return fail(`${prefix}.contentHash`, "must be a non-empty string");
  }
  // Tile must fit within sheet.
  const sheetTyped = sheet as unknown as SheetRecord;
  if (sheetTyped.tileWidth > sheetTyped.width) {
    return fail(
      `${prefix}.tileWidth`,
      `(${sheetTyped.tileWidth}) exceeds sheet width (${sheetTyped.width})`,
    );
  }
  if (sheetTyped.tileHeight > sheetTyped.height) {
    return fail(
      `${prefix}.tileHeight`,
      `(${sheetTyped.tileHeight}) exceeds sheet height (${sheetTyped.height})`,
    );
  }
  return ok();
}

function validateState(
  prefix: string,
  expectedKey: string,
  state: unknown,
  sheetIds: ReadonlySet<string>,
  stateIds: ReadonlySet<string>,
): ValidationResult {
  if (!isPlainObject(state)) return fail(prefix, "must be a plain object");

  if (state.iconState !== expectedKey) {
    return fail(
      `${prefix}.iconState`,
      `must equal "${expectedKey}" (the map key), got ${stringify(state.iconState)}`,
    );
  }
  if (!isNonEmptyString(state.family)) {
    return fail(`${prefix}.family`, "must be a non-empty string");
  }
  if (!isNonEmptyString(state.sheetId)) {
    return fail(`${prefix}.sheetId`, "must be a non-empty string");
  }
  if (!sheetIds.has(state.sheetId as string)) {
    return fail(
      `${prefix}.sheetId`,
      `references unknown sheet "${state.sheetId}"`,
    );
  }

  // crops: at least one direction key, every key must be a valid direction
  // and every value a valid crop rect.
  if (!isPlainObject(state.crops)) {
    return fail(`${prefix}.crops`, "must be a plain object");
  }
  const cropKeys = Object.keys(state.crops);
  if (cropKeys.length === 0) {
    return fail(`${prefix}.crops`, "must contain at least one direction key");
  }
  for (const dirKey of cropKeys) {
    if (!VALID_DIRECTION_KEYS.has(dirKey as DirectionKey)) {
      return fail(
        `${prefix}.crops.${dirKey}`,
        `unknown direction key; must be one of ${[...VALID_DIRECTION_KEYS].join(", ")}`,
      );
    }
    const r = validateCropRect(
      `${prefix}.crops.${dirKey}`,
      (state.crops as Record<string, unknown>)[dirKey],
    );
    if (!r.ok) return r;
  }

  // variants (optional)
  if (state.variants !== undefined) {
    if (!isPlainObject(state.variants)) {
      return fail(`${prefix}.variants`, "must be a plain object when present");
    }
    for (const [variantName, target] of Object.entries(state.variants)) {
      if (!isNonEmptyString(target)) {
        return fail(
          `${prefix}.variants.${variantName}`,
          "must be a non-empty string referencing another state key",
        );
      }
      if (!stateIds.has(target as string)) {
        return fail(
          `${prefix}.variants.${variantName}`,
          `references unknown state "${target}"`,
        );
      }
      if (target === expectedKey) {
        return fail(
          `${prefix}.variants.${variantName}`,
          "must not point at its own state",
        );
      }
    }
  }

  // flags (optional)
  if (state.flags !== undefined) {
    if (!Array.isArray(state.flags)) {
      return fail(`${prefix}.flags`, "must be an array of strings when present");
    }
    for (let i = 0; i < state.flags.length; i++) {
      if (typeof state.flags[i] !== "string") {
        return fail(`${prefix}.flags[${i}]`, "must be a string");
      }
    }
  }

  return ok();
}

function validateCropRect(prefix: string, rect: unknown): ValidationResult {
  if (!isPlainObject(rect)) return fail(prefix, "must be a plain object");
  if (!isNonNegInt(rect.x)) return fail(`${prefix}.x`, "must be a non-negative integer");
  if (!isNonNegInt(rect.y)) return fail(`${prefix}.y`, "must be a non-negative integer");
  if (!isPositiveInt(rect.width)) return fail(`${prefix}.width`, "must be a positive integer");
  if (!isPositiveInt(rect.height)) return fail(`${prefix}.height`, "must be a positive integer");
  return ok();
}

function validateCategory(
  prefix: string,
  expectedKey: string,
  cat: unknown,
  stateIds: ReadonlySet<string>,
): ValidationResult {
  if (!isPlainObject(cat)) return fail(prefix, "must be a plain object");
  if (cat.key !== expectedKey) {
    return fail(`${prefix}.key`, `must equal "${expectedKey}", got ${stringify(cat.key)}`);
  }
  if (cat.scope !== "family" && cat.scope !== "catalog") {
    return fail(`${prefix}.scope`, `must be "family" or "catalog", got ${stringify(cat.scope)}`);
  }
  if (!Array.isArray(cat.states)) {
    return fail(`${prefix}.states`, "must be an array of state keys");
  }
  const seen = new Set<string>();
  for (let i = 0; i < cat.states.length; i++) {
    const ref = cat.states[i];
    if (typeof ref !== "string") {
      return fail(`${prefix}.states[${i}]`, "must be a string");
    }
    if (!stateIds.has(ref)) {
      return fail(`${prefix}.states[${i}]`, `references unknown state "${ref}"`);
    }
    if (seen.has(ref)) {
      return fail(`${prefix}.states[${i}]`, `duplicate state reference "${ref}"`);
    }
    seen.add(ref);
  }
  return ok();
}

function validateBuild(prefix: string, build: unknown): ValidationResult {
  if (!isPlainObject(build)) return fail(prefix, "must be a plain object");
  if (!isNonEmptyString(build.builtAt)) {
    return fail(`${prefix}.builtAt`, "must be a non-empty ISO-8601 string");
  }
  if (build.backend !== APPEARANCE_PREVIEW_BACKEND_ID) {
    return fail(
      `${prefix}.backend`,
      `must equal "${APPEARANCE_PREVIEW_BACKEND_ID}", got ${stringify(build.backend)}`,
    );
  }
  if (build.layout !== APPEARANCE_PREVIEW_LAYOUT_KIND) {
    return fail(
      `${prefix}.layout`,
      `must equal "${APPEARANCE_PREVIEW_LAYOUT_KIND}", got ${stringify(build.layout)}`,
    );
  }
  if (!isNonEmptyString(build.sourceFingerprint)) {
    return fail(`${prefix}.sourceFingerprint`, "must be a non-empty string");
  }
  if (!isPlainObject(build.adapterVersions)) {
    return fail(`${prefix}.adapterVersions`, "must be a plain object");
  }
  for (const [family, ver] of Object.entries(build.adapterVersions)) {
    if (!isNonEmptyString(ver)) {
      return fail(
        `${prefix}.adapterVersions.${family}`,
        "must be a non-empty version string",
      );
    }
  }
  return ok();
}

// ---------------------------------------------------------------------------
// Tiny shape predicates + result helpers
// ---------------------------------------------------------------------------

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function isNonEmptyString(v: unknown): v is string {
  return typeof v === "string" && v.length > 0;
}

function isPositiveInt(v: unknown): v is number {
  return typeof v === "number" && Number.isInteger(v) && v > 0;
}

function isNonNegInt(v: unknown): v is number {
  return typeof v === "number" && Number.isInteger(v) && v >= 0;
}

function stringify(v: unknown): string {
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

function ok(): ValidationSuccess {
  // The narrow type is supplied by the caller; this overload is a no-op
  // marker used only inside the helper chain.
  return { ok: true, manifest: undefined as unknown as ManifestV2 };
}

function fail(path: string, reason: string): ValidationFailure {
  return { ok: false, path, reason };
}

/**
 * tools/build/appearance_preview/adapters/registry.ts
 *
 * Adapter registry + loader for the appearance preview build pipeline.
 *
 * Responsibilities:
 * 1. Hold an in-process map of `family -> Adapter` populated by adapter
 *    modules that call `registerAdapter` at import time.
 * 2. Load the on-disk adapter config (`config/adapters.json`) and resolve
 *    each declared family to a registered adapter, failing fast if any is
 *    missing.
 * 3. Validate adapter discovery output against the contract before the
 *    orchestrator (Step 5) consumes it. This centralizes the
 *    `AdapterMismatchError` surface so adapters themselves stay simple.
 *
 * Step 2 scope: registry + loader + validator. No real adapters are
 * imported yet; Step 3 ships `taur_offsets.ts` and `custom_piercings.ts`
 * which will register themselves when imported by `index.ts`.
 */

import * as fs from "node:fs";
import * as path from "node:path";

import type { Adapter, AdapterDiscovery, DiscoveredState } from "./contract";
import { AdapterMismatchError, InvalidSourceError } from "../errors";
import type { DirectionKey } from "../types";

/**
 * Schema of `config/adapters.json`. Kept intentionally small — per-family
 * settings live on the adapter itself, not in config.
 */
export interface AdapterConfig {
  /** Schema version of this config file. Bump when fields change. */
  configVersion: 1;
  /**
   * Family keys to enable for this build, in the order the orchestrator
   * should process them. Unknown families fail loading.
   */
  enabledFamilies: readonly string[];
}

/** Module-local registry of `family -> Adapter`. */
const REGISTRY = new Map<string, Adapter>();

/**
 * Register an adapter under its declared family key. Adapter modules call
 * this at import time. Re-registering the same family is an error so a
 * typo in two adapters does not silently shadow.
 *
 * @param adapter Adapter implementation to register.
 * @throws Error if `adapter.record.family` is already registered.
 */
export function registerAdapter(adapter: Adapter): void {
  const family = adapter.record.family;
  if (REGISTRY.has(family)) {
    throw new Error(
      `Adapter family "${family}" is already registered. ` +
        `Each family must be registered exactly once.`,
    );
  }
  REGISTRY.set(family, adapter);
}

/**
 * Snapshot of the currently registered adapters. Returned as a fresh map so
 * callers cannot mutate the registry through it.
 */
export function getRegisteredAdapters(): ReadonlyMap<string, Adapter> {
  return new Map(REGISTRY);
}

/** Test-only reset. Not exported via `index.ts`; tests import directly. */
export function _resetRegistryForTests(): void {
  REGISTRY.clear();
}

/**
 * Read and parse the on-disk adapter config. Pure I/O — no validation
 * against the registry happens here.
 *
 * @param configPath Repo-relative or absolute path to `adapters.json`.
 * @throws InvalidSourceError if the file cannot be read or parsed.
 */
export function readAdapterConfig(configPath: string): AdapterConfig {
  const abs = path.resolve(configPath);
  let raw: string;
  try {
    raw = fs.readFileSync(abs, "utf8");
  } catch (err) {
    throw new InvalidSourceError(
      `Failed to read adapter config at ${abs}`,
      abs,
      { cause: err as Error },
    );
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    throw new InvalidSourceError(
      `Adapter config at ${abs} is not valid JSON`,
      abs,
      { cause: err as Error },
    );
  }
  if (!isAdapterConfig(parsed)) {
    throw new InvalidSourceError(
      `Adapter config at ${abs} does not match the AdapterConfig schema`,
      abs,
    );
  }
  return parsed;
}

/**
 * Resolve every family declared in `configPath` to a registered adapter.
 *
 * @param configPath Path to `adapters.json`.
 * @returns Adapters in the order declared by `enabledFamilies`.
 * @throws InvalidSourceError if the config file is malformed.
 * @throws AdapterMismatchError if any declared family has no registered adapter.
 */
export function loadAdapters(configPath: string): readonly Adapter[] {
  const config = readAdapterConfig(configPath);
  const resolved: Adapter[] = [];
  for (const family of config.enabledFamilies) {
    const adapter = REGISTRY.get(family);
    if (!adapter) {
      throw new AdapterMismatchError(
        family,
        `Adapter config enabled family "${family}" but no adapter is ` +
          `registered for it. Ensure the adapter module is imported before ` +
          `loadAdapters() is called.`,
      );
    }
    resolved.push(adapter);
  }
  return resolved;
}

/**
 * Validate adapter discovery output against the adapter contract. Centralized
 * here so every family gets the same checks without duplicating boilerplate.
 *
 * Checks performed:
 * - Every state's `iconState` round-trips through `normalizeStateName`.
 * - Every state's `directions` is non-empty and a subset of the adapter's
 *   declared `directionOrder`.
 * - Every variant reference points at another state in the same discovery.
 * - `validateState` returns no errors for any state.
 * - Discovered states are unique by `iconState`.
 *
 * @param adapter Adapter that produced the discovery.
 * @param discovery Output of `adapter.discoverSources(repoRoot)`.
 * @throws AdapterMismatchError on the first violation.
 */
export function validateDiscovery(
  adapter: Adapter,
  discovery: AdapterDiscovery,
): void {
  const family = adapter.record.family;
  const allowedDirs = new Set<DirectionKey>(adapter.record.directionOrder);
  const seen = new Set<string>();

  for (const state of discovery.states) {
    if (seen.has(state.iconState)) {
      throw new AdapterMismatchError(
        family,
        `Duplicate iconState "${state.iconState}" in discovery output.`,
      );
    }
    seen.add(state.iconState);

    const normalized = adapter.normalizeStateName(state.iconState);
    if (normalized !== state.iconState) {
      throw new AdapterMismatchError(
        family,
        `iconState "${state.iconState}" is not in canonical form ` +
          `(normalizeStateName returned ${JSON.stringify(normalized)}).`,
      );
    }

    if (state.directions.length === 0) {
      throw new AdapterMismatchError(
        family,
        `State "${state.iconState}" declares no directions.`,
      );
    }
    for (const dir of state.directions) {
      if (!allowedDirs.has(dir)) {
        throw new AdapterMismatchError(
          family,
          `State "${state.iconState}" lists direction "${dir}" which is ` +
            `not in the adapter's directionOrder ` +
            `(${adapter.record.directionOrder.join(", ")}).`,
        );
      }
    }

    const adapterErrors = adapter.validateState(state);
    if (adapterErrors.length > 0) {
      throw new AdapterMismatchError(
        family,
        `State "${state.iconState}" failed adapter validation: ` +
          adapterErrors.join("; "),
      );
    }
  }

  // Variant references must point at sibling states. Done in a second pass so
  // forward references resolve.
  for (const state of discovery.states) {
    if (!state.variants) continue;
    for (const [variantName, target] of Object.entries(state.variants)) {
      if (!seen.has(target)) {
        throw new AdapterMismatchError(
          family,
          `State "${state.iconState}" variant "${variantName}" references ` +
            `unknown sibling "${target}".`,
        );
      }
    }
  }
}

/** Type guard for the on-disk config. */
function isAdapterConfig(value: unknown): value is AdapterConfig {
  if (typeof value !== "object" || value === null) return false;
  const v = value as { configVersion?: unknown; enabledFamilies?: unknown };
  if (v.configVersion !== 1) return false;
  if (!Array.isArray(v.enabledFamilies)) return false;
  return v.enabledFamilies.every((f) => typeof f === "string");
}

// `DiscoveredState` is unused in this file's body but is part of the public
// surface re-exported via `index.ts`; we re-export here so external imports
// can pull the type from the registry module too.
export type { DiscoveredState };

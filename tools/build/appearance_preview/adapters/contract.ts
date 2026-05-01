/**
 * tools/build/appearance_preview/adapters/contract.ts
 *
 * Adapter contract for content families consumed by the appearance preview
 * build pipeline. Every content family (taur offsets, custom piercings,
 * future markings/species) implements this interface. The registry
 * (`registry.ts`) validates adapter output against this contract and feeds
 * the validated records into the orchestrator (Step 5).
 *
 * Design constraints:
 * - Adapters are pure data producers. They MUST NOT touch the staging root,
 *   call iconforge, or write any files. The orchestrator owns all I/O so the
 *   atomic publish contract from Step 1 stays intact.
 * - Methods return records, not callbacks. This keeps the registry test
 *   surface flat and lets Step 14 unit-test adapters without mocking I/O.
 * - Adapter version is independent of the manifest version. Bumping an
 *   adapter only invalidates its own family's cache (Step 5).
 */

import type {
  AdapterRecord,
  CategoryRecord,
  DirectionKey,
  SourceFileEntry,
} from "../types";

/**
 * Per-state declaration produced by `Adapter.discoverSources`. The orchestrator
 * turns one of these into one packed tile + one `StateRecord` in the manifest.
 *
 * `iconState` is the canonical lookup key used by the runtime. `iconFile` is
 * the repo-relative DMI path passed to iconforge. The optional `transform`
 * payload is forwarded verbatim to the iconforge `sprites` `transform` field
 * (see `rust_g.dm` line 220-225) so adapters can request scale/crop/blend
 * without the orchestrator needing per-family knowledge.
 */
export interface DiscoveredState {
  /** Canonical icon-state key, unique within the adapter's family. */
  iconState: string;
  /** Repo-relative DMI source path. */
  iconFile: string;
  /**
   * The icon-state name as it appears inside the DMI. Often equal to
   * `iconState` but adapters may rename for normalization.
   */
  sourceState: string;
  /**
   * Direction order this state provides. Must be a non-empty subset of the
   * adapter's declared `directionOrder`. Missing directions are a hard
   * validation error in the registry.
   */
  directions: readonly DirectionKey[];
  /**
   * Optional named variant references. Values are other `DiscoveredState.iconState`
   * keys within the same family, e.g. `{ erect: "..._erect" }`.
   */
  variants?: Record<string, string>;
  /**
   * Optional iconforge transform stack passed verbatim. See `rust_g.dm`
   * `RUSTG_ICONFORGE_*` for accepted shapes. Adapter must construct it
   * correctly; the registry does not validate transform contents.
   */
  transform?: ReadonlyArray<Record<string, unknown>>;
  /** Adapter-specific validation flags surfaced to the runtime. */
  flags?: readonly string[];
}

/**
 * Output of `Adapter.discoverSources`. Bundles state declarations together
 * with the source-file set used to compute the family's fingerprint.
 */
export interface AdapterDiscovery {
  /** All states this adapter contributes, in adapter-preferred order. */
  states: readonly DiscoveredState[];
  /**
   * Source files whose content participates in cache invalidation. Usually
   * the union of every `iconFile` plus any DM files the adapter parsed for
   * state lists. The orchestrator passes this to `fingerprintFiles` in
   * `./source_scan.ts` (content-hashed, mtime-free).
   */
  sources: readonly SourceFileEntry[];
}

/**
 * Output of `Adapter.previewMetadata`. Tells the runtime (Step 8) which
 * categories this family contributes to and what their scope is. Mirrors
 * the DM-side `appearance_preview_manifest_category_scopes` map.
 */
export interface PreviewMetadata {
  /**
   * Category records this adapter owns. Each `CategoryRecord.states` lists
   * the icon-state keys (in display order) that should appear under that
   * category in the runtime. The registry verifies every listed state exists
   * in the discovery output.
   */
  categories: readonly CategoryRecord[];
}

/**
 * The adapter contract. Every content-family adapter exports an object of
 * this shape and registers it via `registry.ts`.
 */
export interface Adapter {
  /** Top-level adapter identity / cache key. */
  readonly record: AdapterRecord;

  /**
   * Discover every state this adapter contributes. Pure function over the
   * filesystem; no caching, no I/O outside read-only scans.
   *
   * @param repoRoot Absolute repo root, supplied by the orchestrator so
   *   adapters never need to compute it themselves.
   */
  discoverSources(repoRoot: string): AdapterDiscovery;

  /**
   * Normalize a raw icon-state name into the canonical form used by both
   * the manifest and the runtime. Called by the registry while validating
   * discovery output. Pure function; no I/O.
   *
   * @param raw Icon-state name as it appears in source.
   * @returns Canonical key, or `null` if the name is invalid for this family.
   */
  normalizeStateName(raw: string): string | null;

  /**
   * Apply the adapter's deterministic ordering to a list of canonical state
   * keys. The orchestrator calls this when packing sheets so cache keys are
   * stable across runs that produced the same set of states. Pure function.
   *
   * @param keys Canonical icon-state keys in arbitrary order.
   * @returns The same keys in deterministic order.
   */
  orderStates(keys: readonly string[]): readonly string[];

  /**
   * Adapter-side validation hook. Called once per discovered state. Should
   * return a list of human-readable error strings, or an empty array if the
   * state is valid. The registry surfaces non-empty results as
   * `AdapterMismatchError`.
   *
   * @param state Discovered state to validate.
   */
  validateState(state: DiscoveredState): readonly string[];

  /**
   * Describe the categories this adapter contributes. Called once per build.
   * Pure function; depends only on the discovery output passed in.
   *
   * @param discovery Output of `discoverSources` for this same build.
   */
  previewMetadata(discovery: AdapterDiscovery): PreviewMetadata;
}

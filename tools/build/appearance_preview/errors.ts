/**
 * tools/build/appearance_preview/errors.ts
 *
 * Typed error classes used across the appearance preview build pipeline.
 *
 * Each class extends `AppearancePreviewBuildError` so a top-level catch in the
 * orchestrator (Step 5) and `build.ts` (Step 6) can distinguish "expected,
 * actionable build failure" from arbitrary thrown values. All errors carry a
 * stable `code` string to ease grepping in CI logs.
 *
 * Step 1 scope: class definitions only. No throw sites yet.
 */

/** Stable, machine-grep-friendly error codes for the preview build pipeline. */
export type AppearancePreviewErrorCode =
  | "MISSING_HELPER"
  | "INVALID_SOURCE"
  | "ADAPTER_MISMATCH"
  | "SHEET_OVERFLOW"
  | "PUBLISH_LOCK"
  | "STAGING_INVALID"
  | "MANIFEST_INVALID";

/**
 * Base class for every typed error raised by the appearance preview build
 * pipeline. Catch this to gate "expected build failure" handling.
 */
export class AppearancePreviewBuildError extends Error {
  public readonly code: AppearancePreviewErrorCode;

  /**
   * @param code Stable error code for grep / metrics.
   * @param message Human-readable explanation. Should include the offending
   *   path or family when relevant.
   * @param options Standard `ErrorOptions` (used to chain root causes).
   */
  constructor(
    code: AppearancePreviewErrorCode,
    message: string,
    options?: ErrorOptions,
  ) {
    super(message, options);
    this.name = new.target.name;
    this.code = code;
  }
}

/**
 * Thrown when the iconforge-capable RustG helper cannot be located or
 * resolved. The orchestrator should treat this as a hard failure that aborts
 * before any staging work begins.
 */
export class MissingHelperError extends AppearancePreviewBuildError {
  constructor(message: string, options?: ErrorOptions) {
    super("MISSING_HELPER", message, options);
  }
}

/**
 * Thrown by adapters when a source DMI / DM file is malformed, missing, or
 * fails adapter-side validation (e.g. expected icon-state absent).
 */
export class InvalidSourceError extends AppearancePreviewBuildError {
  /** Repo-relative path of the offending source file, when known. */
  public readonly sourcePath?: string;

  constructor(
    message: string,
    sourcePath?: string,
    options?: ErrorOptions,
  ) {
    super("INVALID_SOURCE", message, options);
    this.sourcePath = sourcePath;
  }
}

/**
 * Thrown when an adapter emits state records that violate its own contract
 * (e.g. mixed tile sizes, missing required directions, conflicting variant
 * references). Distinct from `InvalidSourceError` because the source is fine
 * but the adapter implementation produced inconsistent output.
 */
export class AdapterMismatchError extends AppearancePreviewBuildError {
  /** Family key that produced the mismatch. */
  public readonly family: string;

  constructor(family: string, message: string, options?: ErrorOptions) {
    super("ADAPTER_MISMATCH", message, options);
    this.family = family;
  }
}

/**
 * Thrown when the packed sheet exceeds the configured maximum dimension.
 * The orchestrator should split into additional sheets rather than retry.
 */
export class SheetOverflowError extends AppearancePreviewBuildError {
  /** Family key whose sheet overflowed. */
  public readonly family: string;

  constructor(family: string, message: string, options?: ErrorOptions) {
    super("SHEET_OVERFLOW", message, options);
    this.family = family;
  }
}

/**
 * Thrown when atomic publish fails because the destination is held open by
 * another process (the WinError 145 / ERROR_DIR_NOT_EMPTY case that motivated
 * the pivot away from the Python exporter). The previous bundle must remain
 * intact when this is raised.
 */
export class PublishLockError extends AppearancePreviewBuildError {
  /** Public-relative target path that could not be replaced. */
  public readonly targetPath: string;

  constructor(targetPath: string, message: string, options?: ErrorOptions) {
    super("PUBLISH_LOCK", message, options);
    this.targetPath = targetPath;
  }
}

/**
 * Thrown when the staging directory itself is in an unexpected state
 * (e.g. partially-populated, missing required manifest, contains stray files
 * from an earlier interrupted run that cleanup did not remove).
 */
export class StagingInvalidError extends AppearancePreviewBuildError {
  /** Path of the staging root that failed validation. */
  public readonly stagingPath: string;

  constructor(stagingPath: string, message: string, options?: ErrorOptions) {
    super("STAGING_INVALID", message, options);
    this.stagingPath = stagingPath;
  }
}

/**
 * Thrown by the schema validator (Step 4) and any caller that loads a
 * manifest and finds it does not match the v2 contract. Production loaders
 * must fail closed on this rather than attempting partial recovery.
 */
export class ManifestInvalidError extends AppearancePreviewBuildError {
  constructor(message: string, options?: ErrorOptions) {
    super("MANIFEST_INVALID", message, options);
  }
}

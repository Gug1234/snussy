# appearance_preview build pipeline (RustG / iconforge)

The canonical, only-supported build path for appearance-preview assets. The
legacy Python exporter (`appearance_preview_export.py`) was removed in Step 13
of the RustG-first refactor; no fallback backend exists and bundles produced
by the old exporter will be rejected at load time (manifest v2 + backend id
validation).

## Entrypoints

- [build.ts](build.ts) — `buildAppearancePreviews({adapterConfig, publicRoot, cacheDir})`
  orchestrator. Called in-process by [tools/build/build.ts](../build.ts)
  (`AppearancePreviewAssetsTarget`) — no subprocess hop.
- [cli.ts](cli.ts) — Bun CLI wrapper: `bun tools/build/appearance_preview/cli.ts --public <dir> --adapter-config <path> [--cache-dir <dir>]`.

## Module map

| File                               | Purpose                                                      |
|------------------------------------|--------------------------------------------------------------|
| [types.ts](types.ts)               | Manifest v2 + adapter/sheet/state record types, constants.   |
| [errors.ts](errors.ts)             | Typed error classes with stable string codes.                |
| [staging.ts](staging.ts)           | Atomic, rename-based publish (fixes WinError 145).           |
| [rustg_bridge.ts](rustg_bridge.ts) | iconforge work-plan emission + source hashing.               |
| [cache.ts](cache.ts)               | On-disk cache keyed by source + adapter + manifest version.  |
| [summary.ts](summary.ts)           | Structured build summary writer / reader.                    |
| [schema/manifest_v2.ts](schema/manifest_v2.ts) | Manifest v2 validator (fail-closed).             |
| [adapters/](adapters)              | Adapter registry + `taur_offsets`, `custom_piercings`.       |
| [config/adapters.json](config/adapters.json) | Enabled adapter families.                          |

## Publish contract

`createStagingRoot(publicRoot)` returns a sibling directory.
`publishStaging(publicRoot, stagingRoot)` performs:

1. `rename(publicRoot, publicRoot.old-<token>)` — fails fast as
   `PublishLockError` if the live tree is held open. Live tree is untouched on
   failure.
2. `rename(stagingRoot, publicRoot)` — atomic on a single filesystem.
3. Best-effort `rm -rf publicRoot.old-<token>` — cleanup failure is non-fatal.

The live bundle is **never** deleted before its replacement is in place.

## Runtime contract

Sheet PNGs do not exist on disk after the orchestrator runs — only
`manifest.json` and `iconforge_plan.json`. Actual PNG encoding happens at DM
world boot: `code/modules/asset_cache/assets/appearance_preview.dm` reads the
plan, calls `rustg_iconforge_generate` per family, and registers the resulting
sheets through the asset cache. Manifest version + backend id + layout kind
are all validated before mount; mismatches fail closed.

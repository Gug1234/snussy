# Project Guidelines

## Build And Test
- Use VS Code tasks from [.vscode/tasks.json](../.vscode/tasks.json) as the default workflow.
- Default compile: `Build All`.
- Local iteration compile: `Build All (Local Testing)`.
- Unit test compile target: `Build All (unit tests)` (passes `-DUNIT_TESTS -DLOCALTEST`).
- Reindex before compile tasks when needed: `dm: reparse`.
- Frontend tasks: `tgui: build`, `tgui: dev server`, and `tgui: rebuild tgfont`.

## Architecture
- DM entrypoint is [roguetown.dme](../roguetown.dme); it includes core code first, then modular includes near the bottom.
- Core gameplay code lives in [code/modules/](../code/modules/).
- Shared defines/macros live in [code/__DEFINES/](../code/__DEFINES/).
- Frontend UI code lives in [tgui/](../tgui/); built assets are consumed by the game web UI pipeline.
- Map sources are in [_maps/](../_maps/), especially [_maps/map_files/](../_maps/map_files/) and [_maps/templates/](../_maps/templates/).

## Conventions
- Use full BYOND type and proc paths; relative type/proc definitions are disallowed by [SpacemanDMM.toml](../SpacemanDMM.toml).
- Treat define files as core constants, not server-tunable options; review [code/__DEFINES/README.md](../code/__DEFINES/README.md) before changing them.
- Prefer adding new type definitions under [code/modules/](../code/modules/) when possible.
- Keep modular changes focused on overrides/extensions and verify compile inclusion in [roguetown.dme](../roguetown.dme).

## Pitfalls
- DM compile/typecheck errors often come from untyped variables; prefer explicit typed vars when accessing subtype members.
- DM multiline string blocks (`{""}`) treat backslashes as escapes; avoid JS regex shorthands like `\d`/`\w` in those strings.
- On Windows, avoid writing DM files with UTF-8 BOM (it can break DM parsing/compilation).

## Contribution Workflow
- Follow [CONTRIBUTING.md](../CONTRIBUTING.md) for PR standards.
- Include test evidence for non-trivial changes; at minimum, show compile success when runtime proof is not practical.
- Do not leave commented-out dead code in submissions.

## Reference Docs
- General project and licensing: [README.md](../README.md)
- Build system details: [tools/build/README.md](../tools/build/README.md)
- tgui usage and troubleshooting: [tgui/README.md](../tgui/README.md)
- tgui deeper docs: [tgui/docs/](../tgui/docs/)

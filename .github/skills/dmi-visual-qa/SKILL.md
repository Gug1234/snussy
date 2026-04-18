---
name: dmi-visual-qa
description: 'Flag likely DMI icon-state issues from dmi-icon-state JSON output. Use for automatic QA checks on state metadata, direction/frame consistency, delays, hotspot shape, and duplicate state names.'
argument-hint: 'Provide the JSON file path produced by dmi-icon-state and whether you want text or JSON QA output.'
---

# DMI Visual QA

Consume structured metadata from `dmi-icon-state` JSON output and automatically flag likely icon-state issues.

## When To Use

- You want a quick QA pass after extracting DMI metadata.
- You need automatic warnings before sprite/content review.
- You need a machine-readable issue list for CI-style checks.

## Input Requirement

Use JSON produced by:

- `python ./.github/skills/dmi-icon-state/scripts/dmi_icon_state.py --file <path-to-file.dmi> --format json`

## Procedure

1. Run `dmi-icon-state` in JSON mode.
2. Run QA on that JSON:
   - Text output:
     - `python ./.github/skills/dmi-visual-qa/scripts/dmi_visual_qa.py --input <metadata.json> --format text`
   - JSON output:
     - `python ./.github/skills/dmi-visual-qa/scripts/dmi_visual_qa.py --input <metadata.json> --format json`
3. Review findings by severity and state name.
4. Fix high-severity errors first, then warnings.

## Checks Performed

- invalid or missing icon size
- duplicate state names
- invalid `dirs` or `frames`
- `frame_cells` mismatch vs `dirs * frames`
- malformed or suspicious `delay` arrays
- malformed `hotspot` arrays
- missing or malformed `per_direction_frame_index_map`

## Completion Check

Before finishing, verify:

- no `error` findings remain
- warnings are either fixed or intentionally accepted
- findings include state names where applicable

## Resource

- [dmi_visual_qa.py](./scripts/dmi_visual_qa.py)

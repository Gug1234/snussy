---
name: dmi-icon-state
description: 'Inspect BYOND DMI files and print icon-state metadata. Use for listing state names, direction counts, icon size, frame counts, delays, and related frame data when auditing sprites or debugging icon-state issues.'
argument-hint: 'Provide the DMI file path and whether you want plain-text output or JSON output.'
---

# DMI to Icon-State Metadata

Extract structured icon-state metadata from a `.dmi` file and report:

- icon-state name
- number of directions (`dirs`)
- icon size (`width` x `height`)
- frame data (`frames`, `delay`, related state timing flags, and computed per-direction frame index maps)

## When To Use

- You need a quick inventory of icon states in a DMI.
- You want to verify `dirs` and `frames` for animation/state bugs.
- You are debugging missing or mismatched icon states.
- You need machine-readable metadata for downstream checks.

## Procedure

1. Confirm the input path points to a `.dmi` file.
2. Run the script:
   - Text output:
     - `python ./.github/skills/dmi-icon-state/scripts/dmi_icon_state.py --file <path-to-file.dmi> --format text`
   - JSON output:
     - `python ./.github/skills/dmi-icon-state/scripts/dmi_icon_state.py --file <path-to-file.dmi> --format json`
3. Review the output for each state:
   - `state`
   - `dirs`
   - `icon_size`
   - `frames`
   - `per_direction_frame_index_map` with both `dirs_first` and `frames_first` assumptions
   - `delay` and related frame flags (`loop`, `rewind`, `movement`, `hotspot` when present)
4. If output is empty or incomplete, verify the file is a valid PNG-based DMI with a `Description` text chunk.

## Decision Rules

- If the DMI omits `width`/`height` in metadata, treat icon size as the PNG dimensions.
- If `delay` is missing, interpret timing as default frame timing.
- If a state omits `frames`, treat it as `1`.
- If a state omits `dirs`, treat it as `1`.

## Completion Check

Before finishing, verify:

- every discovered state is printed once
- each state includes `dirs` and `frames`
- icon size is present
- each state has a computed `per_direction_frame_index_map`
- frame data fields present in metadata are surfaced

## Resource

- [dmi_icon_state.py](./scripts/dmi_icon_state.py)

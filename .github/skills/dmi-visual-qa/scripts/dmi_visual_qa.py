#!/usr/bin/env python3
"""Run automatic QA checks on dmi-icon-state JSON output."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def _issue(severity: str, code: str, message: str, state: str | None = None):
    payload = {"severity": severity, "code": code, "message": message}
    if state is not None:
        payload["state"] = state
    return payload


def _validate_state(st: dict):
    issues = []
    name = st.get("state")
    if not isinstance(name, str) or not name:
        issues.append(_issue("error", "state_name_invalid", "State name is missing or invalid."))
        state_label = "<unknown>"
    else:
        state_label = name

    dirs = st.get("dirs", 1)
    frames = st.get("frames", 1)

    if not isinstance(dirs, int) or dirs < 1:
        issues.append(_issue("error", "dirs_invalid", f"Invalid dirs value: {dirs}", state_label))
    elif dirs not in {1, 4, 8}:
        issues.append(
            _issue(
                "warning",
                "dirs_unusual",
                f"Unusual dirs value {dirs}; expected common BYOND values 1, 4, or 8.",
                state_label,
            )
        )

    if not isinstance(frames, int) or frames < 1:
        issues.append(
            _issue("error", "frames_invalid", f"Invalid frames value: {frames}", state_label)
        )

    expected_cells = None
    if isinstance(dirs, int) and isinstance(frames, int) and dirs > 0 and frames > 0:
        expected_cells = dirs * frames

    frame_cells = st.get("frame_cells")
    if expected_cells is not None and frame_cells != expected_cells:
        issues.append(
            _issue(
                "warning",
                "frame_cells_mismatch",
                f"frame_cells is {frame_cells}, expected {expected_cells} from dirs*frames.",
                state_label,
            )
        )

    delay = st.get("delay", [])
    if delay:
        if not isinstance(delay, list):
            issues.append(
                _issue("error", "delay_not_list", "delay should be a list.", state_label)
            )
        else:
            if isinstance(frames, int) and frames > 0 and len(delay) not in {0, frames}:
                issues.append(
                    _issue(
                        "warning",
                        "delay_length_unexpected",
                        f"delay length is {len(delay)} but frames is {frames}.",
                        state_label,
                    )
                )
            for idx, d in enumerate(delay):
                if not isinstance(d, (int, float)):
                    issues.append(
                        _issue(
                            "warning",
                            "delay_value_type",
                            f"delay[{idx}] is non-numeric: {d}",
                            state_label,
                        )
                    )
                elif d <= 0:
                    issues.append(
                        _issue(
                            "warning",
                            "delay_value_nonpositive",
                            f"delay[{idx}] is non-positive: {d}",
                            state_label,
                        )
                    )

    hotspot = st.get("hotspot", [])
    if hotspot:
        if not isinstance(hotspot, list) or len(hotspot) != 2:
            issues.append(
                _issue(
                    "warning",
                    "hotspot_shape_invalid",
                    "hotspot should contain exactly two values.",
                    state_label,
                )
            )

    fmap = st.get("per_direction_frame_index_map")
    if not isinstance(fmap, dict):
        issues.append(
            _issue(
                "warning",
                "frame_map_missing",
                "per_direction_frame_index_map is missing or invalid.",
                state_label,
            )
        )
    else:
        for map_key in ("dirs_first", "frames_first"):
            sub = fmap.get(map_key)
            if not isinstance(sub, dict):
                issues.append(
                    _issue(
                        "warning",
                        "frame_map_sub_missing",
                        f"per_direction_frame_index_map.{map_key} is missing or invalid.",
                        state_label,
                    )
                )

    return issues


def run_qa(data: dict):
    issues = []

    icon_size = data.get("icon_size")
    if (
        not isinstance(icon_size, list)
        or len(icon_size) != 2
        or not all(isinstance(v, int) and v > 0 for v in icon_size)
    ):
        issues.append(
            _issue("error", "icon_size_invalid", "icon_size must be [width, height] with positive ints.")
        )

    states = data.get("states")
    if not isinstance(states, list):
        issues.append(_issue("error", "states_invalid", "states must be a list."))
        states = []

    seen = {}
    for st in states:
        if isinstance(st, dict):
            state_name = st.get("state")
            if isinstance(state_name, str) and state_name:
                seen[state_name] = seen.get(state_name, 0) + 1
            issues.extend(_validate_state(st))
        else:
            issues.append(_issue("error", "state_entry_invalid", "State entry is not an object."))

    for name, count in seen.items():
        if count > 1:
            issues.append(
                _issue(
                    "warning",
                    "duplicate_state_name",
                    f"State name appears {count} times.",
                    name,
                )
            )

    severities = {"error": 0, "warning": 0, "info": 0}
    for item in issues:
        sev = item.get("severity", "info")
        severities[sev] = severities.get(sev, 0) + 1

    return {
        "summary": {
            "state_count": len(states),
            "error_count": severities.get("error", 0),
            "warning_count": severities.get("warning", 0),
            "info_count": severities.get("info", 0),
        },
        "issues": issues,
    }


def _print_text(result: dict):
    summary = result["summary"]
    print("DMI Visual QA Summary")
    print(f"state_count: {summary['state_count']}")
    print(f"error_count: {summary['error_count']}")
    print(f"warning_count: {summary['warning_count']}")
    print(f"info_count: {summary['info_count']}")
    print("")

    if not result["issues"]:
        print("No issues found.")
        return

    for idx, item in enumerate(result["issues"], start=1):
        state = item.get("state")
        state_suffix = f" [state={state}]" if state else ""
        print(
            f"[{idx}] {item.get('severity', 'info').upper()} {item.get('code', 'unknown')}{state_suffix}: {item.get('message', '')}"
        )


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Flag likely icon-state issues from dmi-icon-state JSON output."
    )
    parser.add_argument("--input", required=True, help="Path to dmi-icon-state JSON output")
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    args = parser.parse_args(argv)

    src = Path(args.input)
    if not src.exists():
        print(f"error: input file not found: {src}", file=sys.stderr)
        return 2

    try:
        data = json.loads(src.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"error: failed to parse input JSON: {exc}", file=sys.stderr)
        return 1

    result = run_qa(data)
    if args.format == "json":
        print(json.dumps(result, indent=2))
    else:
        _print_text(result)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

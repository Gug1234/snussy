#!/usr/bin/env python3
"""Print icon-state metadata from a BYOND DMI file.

Outputs state name, dirs, icon size, and frame-related metadata parsed from
the DMI Description chunk.
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def _parse_png_chunks(data: bytes):
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError("Not a PNG file; DMI files are PNG-based.")

    i = len(PNG_SIGNATURE)
    while i + 8 <= len(data):
        length = struct.unpack(">I", data[i : i + 4])[0]
        chunk_type = data[i + 4 : i + 8]
        i += 8
        if i + length + 4 > len(data):
            raise ValueError("Corrupt PNG chunk layout.")
        chunk_data = data[i : i + length]
        i += length
        _crc = data[i : i + 4]
        i += 4
        yield chunk_type, chunk_data
        if chunk_type == b"IEND":
            break


def _decode_ztxt(chunk_data: bytes) -> tuple[str, str] | None:
    nul = chunk_data.find(b"\x00")
    if nul < 0 or nul + 2 > len(chunk_data):
        return None
    key = chunk_data[:nul].decode("latin-1", errors="replace")
    comp_method = chunk_data[nul + 1]
    comp_data = chunk_data[nul + 2 :]
    if comp_method != 0:
        return None
    try:
        text = zlib.decompress(comp_data).decode("utf-8", errors="replace")
    except Exception:
        text = zlib.decompress(comp_data).decode("latin-1", errors="replace")
    return key, text


def _decode_text(chunk_data: bytes) -> tuple[str, str] | None:
    nul = chunk_data.find(b"\x00")
    if nul < 0:
        return None
    key = chunk_data[:nul].decode("latin-1", errors="replace")
    text = chunk_data[nul + 1 :].decode("latin-1", errors="replace")
    return key, text


def _decode_itxt(chunk_data: bytes) -> tuple[str, str] | None:
    # key\0 compression_flag compression_method language_tag\0 translated_key\0 text
    try:
        nul = chunk_data.find(b"\x00")
        if nul < 0 or nul + 3 > len(chunk_data):
            return None
        key = chunk_data[:nul].decode("latin-1", errors="replace")
        comp_flag = chunk_data[nul + 1]
        comp_method = chunk_data[nul + 2]
        rest = chunk_data[nul + 3 :]

        nul_lang = rest.find(b"\x00")
        if nul_lang < 0:
            return None
        rest = rest[nul_lang + 1 :]

        nul_tr = rest.find(b"\x00")
        if nul_tr < 0:
            return None
        text_data = rest[nul_tr + 1 :]

        if comp_flag:
            if comp_method != 0:
                return None
            text_raw = zlib.decompress(text_data)
        else:
            text_raw = text_data

        text = text_raw.decode("utf-8", errors="replace")
        return key, text
    except Exception:
        return None


def _extract_description(data: bytes) -> tuple[int, int, str]:
    png_width = None
    png_height = None
    description = None

    for chunk_type, chunk_data in _parse_png_chunks(data):
        if chunk_type == b"IHDR":
            png_width, png_height = struct.unpack(">II", chunk_data[:8])
        elif chunk_type == b"tEXt":
            parsed = _decode_text(chunk_data)
            if parsed and parsed[0] == "Description":
                description = parsed[1]
        elif chunk_type == b"zTXt":
            parsed = _decode_ztxt(chunk_data)
            if parsed and parsed[0] == "Description":
                description = parsed[1]
        elif chunk_type == b"iTXt":
            parsed = _decode_itxt(chunk_data)
            if parsed and parsed[0] == "Description":
                description = parsed[1]

    if png_width is None or png_height is None:
        raise ValueError("PNG header is missing IHDR dimensions.")
    if description is None:
        raise ValueError("No Description chunk found; file is not a standard DMI.")

    return png_width, png_height, description


def _parse_scalar(value: str):
    value = value.strip()
    if not value:
        return value
    if value.startswith('"') and value.endswith('"') and len(value) >= 2:
        return value[1:-1]
    if value in {"0", "1"}:
        return int(value)
    try:
        if "." in value:
            return float(value)
        return int(value)
    except ValueError:
        return value


def _parse_csv_scalars(value: str):
    parts = [p.strip() for p in value.split(",") if p.strip()]
    return [_parse_scalar(p) for p in parts]


def _build_per_direction_frame_index_maps(dirs: int, frames: int):
    dirs = max(int(dirs), 1)
    frames = max(int(frames), 1)

    dirs_first = {}
    frames_first = {}

    for d in range(dirs):
        key = f"dir_{d + 1}"
        # dirs_first assumes cell order:
        # dir_1_f1, dir_2_f1, ... dir_N_f1, dir_1_f2, ...
        dirs_first[key] = [d + (f * dirs) for f in range(frames)]
        # frames_first assumes cell order:
        # dir_1_f1, dir_1_f2, ... dir_1_fN, dir_2_f1, ...
        frames_first[key] = [(d * frames) + f for f in range(frames)]

    return {
        "dirs_first": dirs_first,
        "frames_first": frames_first,
    }


def _parse_dmi_description(desc_text: str, png_w: int, png_h: int):
    meta_w = None
    meta_h = None
    states = []
    current = None

    for raw_line in desc_text.replace("\r\n", "\n").split("\n"):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue

        key, value = [part.strip() for part in line.split("=", 1)]

        if key == "state":
            state_name = _parse_scalar(value)
            current = {
                "state": state_name,
                "dirs": 1,
                "frames": 1,
                "delay": [],
            }
            states.append(current)
            continue

        if key == "width":
            parsed = _parse_scalar(value)
            if isinstance(parsed, int):
                meta_w = parsed
            continue

        if key == "height":
            parsed = _parse_scalar(value)
            if isinstance(parsed, int):
                meta_h = parsed
            continue

        if current is None:
            continue

        if key in {"dirs", "frames", "loop", "rewind", "movement"}:
            current[key] = _parse_scalar(value)
        elif key in {"delay", "hotspot"}:
            current[key] = _parse_csv_scalars(value)
        else:
            current[key] = _parse_scalar(value)

    icon_w = meta_w if meta_w is not None else png_w
    icon_h = meta_h if meta_h is not None else png_h

    for st in states:
        dirs = st.get("dirs", 1)
        frames = st.get("frames", 1)
        try:
            st["frame_cells"] = int(dirs) * int(frames)
            st["per_direction_frame_index_map"] = _build_per_direction_frame_index_maps(
                int(dirs), int(frames)
            )
        except Exception:
            st["frame_cells"] = None
            st["per_direction_frame_index_map"] = {
                "dirs_first": {},
                "frames_first": {},
            }
        st["icon_size"] = [icon_w, icon_h]

    return {
        "icon_size": [icon_w, icon_h],
        "state_count": len(states),
        "states": states,
    }


def _print_text_report(result: dict, source: Path):
    print(f"file: {source}")
    print(f"icon_size: {result['icon_size'][0]}x{result['icon_size'][1]}")
    print(f"state_count: {result['state_count']}")
    print("")

    for idx, st in enumerate(result["states"], start=1):
        print(f"[{idx}] state: {st.get('state', '')}")
        print(f"  dirs: {st.get('dirs', 1)}")
        print(f"  icon_size: {st['icon_size'][0]}x{st['icon_size'][1]}")
        print(f"  frames: {st.get('frames', 1)}")
        print(f"  frame_cells: {st.get('frame_cells')}")
        direction_map = st.get("per_direction_frame_index_map", {})
        if direction_map.get("dirs_first"):
            print(f"  per_direction_frame_index_map.dirs_first: {direction_map['dirs_first']}")
        if direction_map.get("frames_first"):
            print(
                f"  per_direction_frame_index_map.frames_first: {direction_map['frames_first']}"
            )
        if st.get("delay"):
            print(f"  delay: {st['delay']}")
        if "loop" in st:
            print(f"  loop: {st['loop']}")
        if "rewind" in st:
            print(f"  rewind: {st['rewind']}")
        if "movement" in st:
            print(f"  movement: {st['movement']}")
        if st.get("hotspot"):
            print(f"  hotspot: {st['hotspot']}")

        extras = {
            k: v
            for k, v in st.items()
            if k
            not in {
                "state",
                "dirs",
                "icon_size",
                "frames",
                "frame_cells",
                "per_direction_frame_index_map",
                "delay",
                "loop",
                "rewind",
                "movement",
                "hotspot",
            }
        }
        for key, val in extras.items():
            print(f"  {key}: {val}")
        print("")


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Print icon-state names, dirs, icon size, and frame data from a DMI file."
    )
    parser.add_argument("--file", required=True, help="Path to the .dmi file")
    parser.add_argument(
        "--format",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--json", action="store_true", dest="as_json", help="Emit JSON output"
    )
    args = parser.parse_args(argv)

    source = Path(args.file)
    if not source.exists():
        print(f"error: file not found: {source}", file=sys.stderr)
        return 2

    try:
        data = source.read_bytes()
        png_w, png_h, description = _extract_description(data)
        result = _parse_dmi_description(description, png_w, png_h)
    except Exception as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1

    emit_json = args.as_json or args.format == "json"

    if emit_json:
        print(json.dumps(result, indent=2))
    else:
        _print_text_report(result, source)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

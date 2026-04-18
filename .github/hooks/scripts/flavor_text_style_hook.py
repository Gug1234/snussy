#!/usr/bin/env python3
"""Inject flavor-text writing constraints when relevant prompts are detected."""

from __future__ import annotations

import json
import sys


TRIGGERS = (
    "flavor text",
    "flavour text",
    "write flavor",
    "writing",
    "scene",
    "erp",
    "intimate",
    "description",
    "narrative",
    "roleplay",
)


STYLE_MESSAGE = (
    "Flavor-text policy: avoid corny or cumbersome metaphor, avoid overuse "
    "of personification, and favor visceral concrete writing. Keep language "
    "direct, sensory, and grounded in observable physical detail rather than "
    "poetic abstraction. Be vulgar, swear if it fits the tone. Always check "
    "perspective for a given string. Who is seeing/hearing this? How do we "
    "vary what the user sees, the target sees, and what bystanders see? Consider "
    " using the existing tokens like [USER], [TARGET], [FORCE], etc to make strings "
    " flexible and variable rather than hardcoding specific nouns or names."
)


def _collect_strings(obj, out):
    if isinstance(obj, str):
        out.append(obj)
    elif isinstance(obj, list):
        for item in obj:
            _collect_strings(item, out)
    elif isinstance(obj, dict):
        for value in obj.values():
            _collect_strings(value, out)


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        # Non-blocking on malformed input.
        return 0

    strings = []
    _collect_strings(payload, strings)
    prompt_blob = "\n".join(strings).lower()

    if any(token in prompt_blob for token in TRIGGERS):
        print(json.dumps({"continue": True, "systemMessage": STYLE_MESSAGE}))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/bin/bash
# Phase 1 TDI-win contract: the live map_view preview must not pay any
# flatten/base64 cost. Any call to getFlatIcon() or icon2base64() in the
# appearance-preview module (or the lobby/prefs paths that previously drove
# the 4x flatten loop) must be wrapped in `#ifdef APPEARANCE_PREVIEW_LEGACY_FLATTEN`
# so flipping the flag off removes every flatten callsite from the compile.
#
# Run standalone:  bash tools/ci/check_appearance_preview_gate.sh
# Exits non-zero if an unguarded flatten call is found.

set -uo pipefail

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
NC="\033[0m"

echo -e "${BLUE}Checking appearance preview flatten gate...${NC}"

st=0
preview_files="\
modular/code/modules/client/appearance_preview/char_preview_view.dm \
modular/code/modules/client/appearance_preview/preferences_preview.dm \
modular/code/modules/client/appearance_preview/preferences_tgui.dm \
modular/code/modules/client/appearance_preview/lobby_hud_observer.dm \
modular/code/modules/client/appearance_preview/appearance_preview_commit.dm \
modular/code/modules/client/preferences/preferences_setup.dm \
code/modules/client/client_procs.dm"

for f in $preview_files; do
	[ -f "$f" ] || continue
	unguarded=$(awk -v fname="$f" '
	BEGIN { top = 0 }
	{
		trimmed = $0
		sub(/^[ \t]+/, "", trimmed)
		if (trimmed ~ /^#ifdef[ \t]+APPEARANCE_PREVIEW_LEGACY_FLATTEN([^A-Za-z0-9_]|$)/) { top++; stack[top] = "protected"; next }
		if (trimmed ~ /^#ifndef[ \t]+APPEARANCE_PREVIEW_LEGACY_FLATTEN([^A-Za-z0-9_]|$)/) { top++; stack[top] = "active"; next }
		if (trimmed ~ /^#ifdef[ \t]/ || trimmed ~ /^#ifndef[ \t]/ || trimmed ~ /^#if[ \t]/) { top++; stack[top] = "neutral"; next }
		if (trimmed ~ /^#else([^A-Za-z0-9_]|$)/) {
			if (stack[top] == "protected") stack[top] = "active"
			else if (stack[top] == "active") stack[top] = "protected"
			next
		}
		if (trimmed ~ /^#endif([^A-Za-z0-9_]|$)/) { if (top > 0) { delete stack[top]; top-- } next }
		if (trimmed ~ /^\/\//) next
		if (trimmed ~ /^\*/) next
		if (trimmed ~ /^\/\*/) next
		for (i = 1; i <= top; i++) if (stack[i] == "protected") { next }
		if ($0 ~ /(getFlatIcon|icon2base64)[ \t]*\(/) print fname ":" NR ": " $0
	}
	' "$f")
	if [ -n "$unguarded" ]; then
		echo "$unguarded"
		st=1
	fi
done

if [ $st -eq 0 ]; then
	echo -e "${GREEN}appearance preview flatten gate: clean.${NC}"
else
	echo -e "${RED}ERROR: getFlatIcon/icon2base64 found in appearance-preview path outside APPEARANCE_PREVIEW_LEGACY_FLATTEN guard.${NC}"
fi

exit $st

#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
OUT="${1:?usage: tools/svg_sheet.sh <out.png> <scale> <svg...>}"
shift
"$GODOT" --headless --path "$ROOT" --script "$ROOT/tools/svg_sheet.gd" -- "$OUT" "$@" 2>&1 | grep -E 'SHEET|FAIL|ERROR' || true

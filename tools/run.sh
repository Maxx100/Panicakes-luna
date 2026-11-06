#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
FRAMES="${1:?usage: tools/run.sh <frames> [--shots=..] [--probe=N] [--input=file.json]}"
shift
MODE=(--headless)
if [[ " $* " == *" --shots="* || -n "${WINDOW:-}" ]]; then
  MODE=(--windowed --resolution 1280x720)
  rm -rf "$ROOT/tools/shots"
fi
TIMING=(--fixed-fps 60)
if [[ -n "${REALTIME:-}" ]]; then
  TIMING=()
fi
"$GODOT" "${MODE[@]}" --path "$ROOT" ${SCENE:-} ${TIMING[@]+"${TIMING[@]}"} --quit-after $((FRAMES * 4 + 240)) -- --quit="$FRAMES" "$@" 2>&1 \
  | grep -vE '^(Godot Engine v|OpenGL API|Metal|Vulkan|$)'

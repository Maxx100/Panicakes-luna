#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
FRAMES="${1:?usage: tools/record.sh <frames> <name> [harness args]}"
NAME="${2:?name}"
shift 2
OUT="$ROOT/tools/movies"
mkdir -p "$OUT"
"$GODOT" --path "$ROOT" ${SCENE:-} --windowed --resolution 1280x720 --write-movie "$OUT/$NAME.avi" --fixed-fps 60 --quit-after "$FRAMES" -- "$@" >/dev/null 2>&1
ffmpeg -loglevel error -y -i "$OUT/$NAME.avi" -vf "scale=640:-2" -c:v libx264 -pix_fmt yuv420p "$OUT/$NAME.mp4"
read -r SHEET_FPS SHEET_ROWS < <(python3 -c "import math; f=min(6, 24*60/$FRAMES); print(f, max(1, math.ceil($FRAMES/60*f/6)))")
ffmpeg -loglevel error -y -i "$OUT/$NAME.avi" -vf "fps=$SHEET_FPS,scale=320:-2,tile=6x${SHEET_ROWS}:padding=4" -frames:v 1 -update 1 "$OUT/$NAME-sheet.png"
rm -f "$OUT/$NAME.avi"
echo "$OUT/$NAME.mp4"

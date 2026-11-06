#!/bin/bash
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$ROOT"
LOG="$(mktemp)"
"$GODOT" --headless --path "$ROOT" --import >"$LOG" 2>&1
BLURRY="$(grep -L 'importer="svg"' assets/sprites/*.svg.import || true)"
if [ -n "$BLURRY" ]; then
  echo "CHECK: FAIL — sprite SVG not imported as DPITexture (set importer=\"svg\", type=\"DPITexture\"):"
  echo "$BLURRY"
  exit 1
fi
while IFS= read -r f; do
  "$GODOT" --headless --path "$ROOT" --check-only --script "res://${f#./}" >>"$LOG" 2>&1
done < <(find . -name '*.gd' -not -path './.godot/*' -not -path './tools/*' -not -path './addons/*')
"$GODOT" --headless --path "$ROOT" --quit-after 30 -- --quit=10 >>"$LOG" 2>&1
if grep -qE 'ERROR|Parse Error|WARNING' "$LOG"; then
  grep -nE -A3 'ERROR|Parse Error|WARNING' "$LOG"
  echo "CHECK: FAIL (full log: $LOG)"
  exit 1
fi
echo "CHECK: OK"

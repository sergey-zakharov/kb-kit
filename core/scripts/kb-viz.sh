#!/usr/bin/env bash
# kb-viz.sh — generate a single self-contained interactive HTML graph of the base.
# A file, not an app: no server, no network access, works offline.
#
# Usage: kb-viz.sh [--base <dir>] [--out <file>]   (default out: kb-graph.html)
set -euo pipefail

BASE=""
OUT="kb-graph.html"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?}"; shift 2 ;;
    --out)  OUT="${2:?}"; shift 2 ;;
    *) echo "Usage: kb-viz.sh [--base <dir>] [--out <file>]" >&2; exit 2 ;;
  esac
done
if [ -z "$BASE" ]; then
  if [ -f .kb/config ]; then BASE="$(awk -F= '$1=="KB_DIR"{print $2}' .kb/config)"; else BASE="."; fi
fi
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
GRAPH="$SELF_DIR/kb-graph.sh"
TPL="$SELF_DIR/viz-template.html"
[ -x "$GRAPH" ] || { echo "kb-viz: kb-graph.sh not found" >&2; exit 2; }
[ -f "$TPL" ]  || { echo "kb-viz: viz-template.html not found" >&2; exit 2; }

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT
"$GRAPH" --base "$BASE" --json > "$TMP_JSON"

awk -v jf="$TMP_JSON" '
  /__KB_GRAPH_DATA__/ {
    printf "const DATA = "
    while ((getline l < jf) > 0) print l
    print ";"
    next
  }
  { print }
' "$TPL" > "$OUT"

N=$(grep -c '"id":' "$TMP_JSON" || true)
echo "kb-viz: $OUT written ($N nodes) — open it in any browser, works offline"

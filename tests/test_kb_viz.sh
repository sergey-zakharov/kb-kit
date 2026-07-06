#!/usr/bin/env bash
# Viz tests: single file, offline guarantee, counts match graph JSON (SC-007). Zero deps.
set -u
cd "$(dirname "$0")/.."
FAIL=0
ok()   { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAIL=1; }

echo "test_kb_viz"
mkdir -p tests/tmp
OUT=tests/tmp/kb-graph-test.html
./core/scripts/kb-viz.sh --base tests/fixtures/mini-kb --out "$OUT" >/dev/null || fail "kb-viz.sh failed"

[ -f "$OUT" ] && ok "output file exists" || fail "no output"
grep -Eq 'https?://' "$OUT" && fail "external URL found — offline guarantee broken" || ok "no http(s) references (offline)"
grep -q '__KB_GRAPH_DATA__' "$OUT" && fail "placeholder not substituted" || ok "data injected"

NJSON=$(./core/scripts/kb-graph.sh --base tests/fixtures/mini-kb | grep -c '"id":')
NHTML=$(grep -o '"id":' "$OUT" | wc -l)
[ "$NJSON" -eq "$NHTML" ] && ok "node count matches graph JSON ($NJSON)" || fail "node count mismatch: json=$NJSON html=$NHTML"

EJSON=$(./core/scripts/kb-graph.sh --base tests/fixtures/mini-kb | grep -c '"from":')
EHTML=$(grep -o '"from":' "$OUT" | wc -l)
[ "$EJSON" -eq "$EHTML" ] && ok "edge count matches graph JSON ($EJSON)" || fail "edge count mismatch"

# defective base renders too (broken edges + adopted + flags styling present)
OUT2=tests/tmp/kb-graph-defective.html
./core/scripts/kb-viz.sh --base tests/fixtures/mini-kb-defective --out "$OUT2" >/dev/null
grep -q '"adopted":true' "$OUT2" && ok "adopted node present in defective viz" || fail "adopted missing"
grep -q '"broken":true' "$OUT2" && ok "broken edge present in defective viz" || fail "broken missing"

[ $FAIL -eq 0 ] && echo "test_kb_viz: PASS" || { echo "test_kb_viz: FAIL"; exit 1; }

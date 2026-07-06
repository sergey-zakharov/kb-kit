#!/usr/bin/env bash
# Golden + behavior tests for core/scripts/kb-graph.sh. Zero deps.
set -u
cd "$(dirname "$0")/.."
GRAPH=core/scripts/kb-graph.sh
FAIL=0
ok()   { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAIL=1; }

echo "test_kb_graph"

# 1. Golden TSV on the clean fixture
if diff -u tests/golden/mini-kb.tsv <($GRAPH --base tests/fixtures/mini-kb --tsv) >/dev/null 2>&1; then
  ok "mini-kb TSV matches golden"
else
  fail "mini-kb TSV diverged from golden:"; diff -u tests/golden/mini-kb.tsv <($GRAPH --base tests/fixtures/mini-kb --tsv) | head -20
fi

# 2. Clean fixture: no broken edges, no adopted nodes
TSV=$($GRAPH --base tests/fixtures/mini-kb --tsv)
echo "$TSV" | awk -F'\t' '$1=="EDGE" && $6=="1"{exit 1}' && ok "no broken edges in mini-kb" || fail "broken edge found in clean fixture"
echo "$TSV" | awk -F'\t' '$1=="NODE" && $5=="1"{exit 1}' && ok "no adopted nodes in mini-kb" || fail "unexpected adopted node in clean fixture"

# 3. Defective fixture: expected parse behaviors
DTSV=$($GRAPH --base tests/fixtures/mini-kb-defective --tsv)
echo "$DTSV" | grep -q "^EDGE	repair-ceiling	nonexistent-node		link	1$" && ok "broken link detected" || fail "broken link not marked"
echo "$DTSV" | grep -q "^EDGE	repair-ceiling	walk-in-slots	^nope	anchor	1$" && ok "broken anchor detected" || fail "broken anchor not marked"
echo "$DTSV" | grep -q "^EDGE	repair-ceiling	one-source	^q1	anchor	0$" && ok "valid anchor resolves" || fail "valid anchor wrongly broken"
echo "$DTSV" | awk -F'\t' '$1=="NODE" && $2=="old-queue"{if($5=="1" && $6=="1" && $11!="") found=1} END{exit found?0:1}' \
  && ok "adopted node: adopted=1, exempt, description from index row" || fail "adopted node handling wrong"
echo "$DTSV" | grep -q "^FILEREF	product/repair-ceiling.md	missing.mp3	0$" && ok "missing fileref detected" || fail "missing fileref not detected"
echo "$DTSV" | grep -q "^THEME	stray	0	1$" && ok "stray theme not in KB.md" || fail "stray theme record wrong"

# 4. JSON mode: structurally sane
J=$($GRAPH --base tests/fixtures/mini-kb)
echo "$J" | grep -q '"id":"repair-ceiling"' && ok "JSON contains nodes" || fail "JSON missing nodes"
echo "$J" | grep -q '"anchor":"\^q2"' && ok "JSON anchor field" || fail "JSON anchor missing"
OPEN=$(echo "$J" | tr -cd '{' | wc -c); CLOSE=$(echo "$J" | tr -cd '}' | wc -c)
[ "$OPEN" = "$CLOSE" ] && ok "JSON braces balanced ($OPEN)" || fail "JSON braces unbalanced ($OPEN vs $CLOSE)"

[ $FAIL -eq 0 ] && echo "test_kb_graph: PASS" || { echo "test_kb_graph: FAIL"; exit 1; }

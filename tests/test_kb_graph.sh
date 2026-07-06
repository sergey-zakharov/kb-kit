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
echo "$DTSV" | grep -q "^THEME	stray	0	1	1$" && ok "stray theme not in KB.md" || fail "stray theme record wrong"
echo "$DTSV" | grep -q "^THEME	ghost	1	0	0$" && ok "ghost theme: in KB.md, no dir/index" || fail "ghost theme record wrong"
echo "$TSV" | grep -q "missing-inside-fence" && fail "fileref inside code fence parsed" || ok "code fence: filerefs ignored"
echo "$TSV" | awk -F'\t' '$1=="EDGE" && $3 ~ /^:/{exit 1}' && ok "code fence: regex classes not wikilinks" || fail "[[:<:]] parsed as link"

# 3b. External bases (memory bridge): unresolved link resolves via KB_EXTERNAL_BASES
$GRAPH --base tests/fixtures/mini-kb-ext --tsv | grep -q "^EDGE	uses-memory	mem-note		link	1$" \
  && ok "ext link broken without external base" || fail "ext fixture baseline wrong"
KB_EXTERNAL_BASES="mem=tests/fixtures/ext-mem" $GRAPH --base tests/fixtures/mini-kb-ext --tsv | grep -q "^EDGE	uses-memory	mem-note		external	0$" \
  && ok "ext link resolves via external base" || fail "external resolution failed"
KB_EXTERNAL_BASES="mem=tests/fixtures/ext-mem" $GRAPH --base tests/fixtures/mini-kb-ext | grep -q '"external":true' \
  && ok "JSON carries external flag" || fail "JSON external flag missing"
KB_EXTERNAL_BASES="mem=tests/fixtures/ext-mem" $GRAPH --base tests/fixtures/mini-kb-ext --tsv | grep -q "^EDGE	uses-prefix	mem:mem-note		external	0$" \
  && ok "explicit [[mem:slug]] resolves" || fail "prefixed external link failed"
$GRAPH --base tests/fixtures/mini-kb-defective --tsv | grep -q "^COLLIDE	walk-in-slots	product/walk-in-slots.md	sources/walk-in-slots.md$" \
  && ok "slug collision recorded (first sorted wins)" || fail "COLLIDE record missing"
echo "$TSV" | grep -q "fake-slug-in-code" && fail "inline code span parsed as link" || ok "inline code spans ignored"
echo "$TSV" | grep -q "^FILEREF	product/roadmap-digest.md	../sources/2026-03-24-video-courier.md	1$" \
  && ok "fileref fragment stripped before existence check" || fail "anchor fileref handling wrong"

# 3c. NODE carries fmkeys + headslugs (mask invariant inputs)
echo "$TSV" | awk -F'\t' '$1=="NODE" && $2=="walk-in-slots" {ok = index($12,"name")>0 && index($12,"tags")>0 && index($13,"motivation")>0 && index($13,"design")>0} END{exit ok?0:1}' \
  && ok "NODE fmkeys+headslugs populated" || fail "fmkeys/headslugs missing on NODE"

# 4. JSON mode: structurally sane
J=$($GRAPH --base tests/fixtures/mini-kb)
echo "$J" | grep -q '"id":"repair-ceiling"' && ok "JSON contains nodes" || fail "JSON missing nodes"
echo "$J" | grep -q '"anchor":"\^q2"' && ok "JSON anchor field" || fail "JSON anchor missing"
OPEN=$(echo "$J" | tr -cd '{' | wc -c); CLOSE=$(echo "$J" | tr -cd '}' | wc -c)
[ "$OPEN" = "$CLOSE" ] && ok "JSON braces balanced ($OPEN)" || fail "JSON braces unbalanced ($OPEN vs $CLOSE)"

[ $FAIL -eq 0 ] && echo "test_kb_graph: PASS" || { echo "test_kb_graph: FAIL"; exit 1; }

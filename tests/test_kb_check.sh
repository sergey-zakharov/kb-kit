#!/usr/bin/env bash
# Seeded-defect detection tests for core/scripts/kb-check.sh (SC-006). Zero deps.
set -u
cd "$(dirname "$0")/.."
CHECK=core/scripts/kb-check.sh
FAIL=0
ok()   { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAIL=1; }

echo "test_kb_check"

# 1. Clean fixture: exit 0, zero findings
OUT=$($CHECK --base tests/fixtures/mini-kb); RC=$?
[ $RC -eq 0 ] && ok "clean base exits 0" || fail "clean base exit code $RC"
echo "$OUT" | grep -q "0 findings" && ok "clean bill of health" || fail "unexpected findings on clean base: $OUT"

# 2. Defective fixture: exit 1 and exactly the 10 seeded findings
JOUT=$($CHECK --base tests/fixtures/mini-kb-defective --json); RC=$?
[ $RC -eq 1 ] && ok "defective base exits 1" || fail "defective base exit code $RC"

expect() { # type file-substr
  if echo "$JOUT" | grep -q "\"type\": \"$1\", \"file\": \"$2\""; then ok "$1 @ $2"; else fail "missing finding: $1 @ $2"; fi
}
expect broken-link          product/repair-ceiling.md
expect broken-anchor        product/repair-ceiling.md
expect broken-file-ref      product/repair-ceiling.md
expect index-stale-row      product/INDEX.md
expect index-missing-row    product/unlinked-unindexed.md
expect unindexed-theme      stray
expect frontmatter-invalid  product/bad-frontmatter.md
expect flagged-node         product/repair-ceiling.md
expect flagged-node         product/walk-in-slots.md
expect inbox-blocked        INBOX.md
expect theme-index-missing  ghost
expect slug-collision       sources/walk-in-slots.md

N=$(echo "$JOUT" | grep -c '"type":')
[ "$N" -eq 12 ] && ok "exactly 12 findings" || fail "expected 12 findings, got $N"

# external bases: soft unreachable finding + clean resolution
EOUT=$(KB_EXTERNAL_BASES="mem=tests/fixtures/ext-mem;gone=/nonexistent-xyz" $CHECK --base tests/fixtures/mini-kb-ext --json)
echo "$EOUT" | grep -q '"type": "external-base-unreachable", "file": "gone"' && ok "unreachable base soft finding" || fail "unreachable finding missing"
echo "$EOUT" | grep -q '"type": "broken-link", "file": "notes/uses-prefix.md"' && ok "unknown-prefix link broken" || fail "unknown prefix not flagged"
echo "$EOUT" | grep -q 'mem-note' && fail "resolved external link wrongly flagged" || ok "resolved external links clean"

# 3. Exemptions and precedence
echo "$JOUT" | grep -q '"file": "product/old-queue.md"' && fail "adopted node wrongly flagged" || ok "adopted node exempt"
echo "$JOUT" | grep -q '"type": "orphan-node"' && fail "orphan reported as standalone type (precedence violated)" || ok "orphan folded into index-missing-row"
echo "$JOUT" | grep -q '"detail": "node has no index row; also orphaned (no incoming links)", "safe_fix": "add-index-row"' \
  && ok "missing-row carries orphan detail + safe_fix" || fail "missing-row detail/safe_fix wrong"
echo "$JOUT" | grep -q '"file": "stray/lonely.md"' && fail "lonely.md wrongly flagged (indexed in own theme)" || ok "theme-internal indexing respected"

# mask invariants (.kb-checks.conf): violations detected, clean node silent (SC-103)
MOUT=$($CHECK --base tests/fixtures/mini-kb-masked --json); MRC=$?
[ $MRC -eq 1 ] && ok "masked fixture exits 1" || fail "masked fixture rc=$MRC"
echo "$MOUT" | grep -q 'requires frontmatter key \\"status\\"' && ok "mask-invariant: missing frontmatter key" || fail "fm invariant not detected"
echo "$MOUT" | grep -q 'requires section \\"Check plan\\"' && ok "mask-invariant: missing section" || fail "section invariant not detected"
MN=$(echo "$MOUT" | grep -c '"type": "mask-invariant"')
[ "$MN" -eq 2 ] && ok "exactly 2 mask-invariant findings" || fail "expected 2 mask-invariant, got $MN"
echo "$MOUT" | grep -q 'good-hypothesis' && fail "clean hypothesis wrongly flagged" || ok "clean hypothesis silent"

[ $FAIL -eq 0 ] && echo "test_kb_check: PASS" || { echo "test_kb_check: FAIL"; exit 1; }

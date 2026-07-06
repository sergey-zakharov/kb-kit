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

N=$(echo "$JOUT" | grep -c '"type":')
[ "$N" -eq 10 ] && ok "exactly 10 findings" || fail "expected 10 findings, got $N"

# 3. Exemptions and precedence
echo "$JOUT" | grep -q '"file": "product/old-queue.md"' && fail "adopted node wrongly flagged" || ok "adopted node exempt"
echo "$JOUT" | grep -q '"type": "orphan-node"' && fail "orphan reported as standalone type (precedence violated)" || ok "orphan folded into index-missing-row"
echo "$JOUT" | grep -q '"detail": "node has no index row; also orphaned (no incoming links)", "safe_fix": "add-index-row"' \
  && ok "missing-row carries orphan detail + safe_fix" || fail "missing-row detail/safe_fix wrong"
echo "$JOUT" | grep -q '"file": "stray/lonely.md"' && fail "lonely.md wrongly flagged (indexed in own theme)" || ok "theme-internal indexing respected"

[ $FAIL -eq 0 ] && echo "test_kb_check: PASS" || { echo "test_kb_check: FAIL"; exit 1; }

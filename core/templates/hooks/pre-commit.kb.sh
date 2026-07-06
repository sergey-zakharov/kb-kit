#!/usr/bin/env bash
# kb-kit pre-commit hook: hygiene check when staged changes touch the knowledge base.
# Warn-only by default; export KB_PRECOMMIT_STRICT=1 to block commits on findings.
KB_DIR="$(awk -F= '$1=="KB_DIR"{print $2}' .kb/config 2>/dev/null)"
[ -n "$KB_DIR" ] || exit 0
git diff --cached --name-only | grep -q "^$KB_DIR/.*\.md$" || exit 0
OUT="$(.kb/scripts/kb-check.sh 2>/dev/null)"; RC=$?
if [ "$RC" -eq 1 ]; then
  echo "kb-kit pre-commit — base has findings:" >&2
  printf '%s\n' "$OUT" | tail -6 >&2
  if [ "${KB_PRECOMMIT_STRICT:-0}" = "1" ]; then
    echo "kb-kit: commit blocked (KB_PRECOMMIT_STRICT=1). Fix via /kb-check or unset the var." >&2
    exit 1
  fi
  echo "kb-kit: warn-only (export KB_PRECOMMIT_STRICT=1 to block)" >&2
fi
exit 0

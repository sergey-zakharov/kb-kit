#!/usr/bin/env bash
# kb-kit SessionStart hook: one-line base status injected into every new session.
KB_DIR="$(awk -F= '$1=="KB_DIR"{print $2}' .kb/config 2>/dev/null)"
[ -n "$KB_DIR" ] && [ -d "$KB_DIR" ] || exit 0
J="$(.kb/scripts/kb-check.sh --json 2>/dev/null)" || true
N="$(printf '%s' "$J" | grep -c '"type":' || true)"
S="$(printf '%s' "$J" | grep -c '"safe_fix": "' || true)"
P=0; B=0
if [ -f "$KB_DIR/INBOX.md" ]; then
  P="$(grep -c '^- \[ \]' "$KB_DIR/INBOX.md" || true)"
  B="$(grep -c '^- \[?\]' "$KB_DIR/INBOX.md" || true)"
fi
echo "kb-kit status: $N findings ($S safe-fixable) · INBOX: $P pending, $B blocked. Commands: /kb-check /kb-add /kb-ask /kb-audit."
exit 0

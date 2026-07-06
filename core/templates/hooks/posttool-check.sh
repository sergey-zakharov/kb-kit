#!/usr/bin/env bash
# kb-kit PostToolUse hook (Write|Edit): if the agent just edited a node in the
# base, run hygiene immediately and feed findings about THAT file back to the
# agent (exit 2 + stderr = agent sees it right away, not a week later).
IN="$(cat)"
FP="$(printf '%s' "$IN" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$FP" ] || exit 0
KB_DIR="$(awk -F= '$1=="KB_DIR"{print $2}' .kb/config 2>/dev/null)"
[ -n "$KB_DIR" ] || exit 0
REL="${FP#"$PWD"/}"
case "$REL" in
  "$KB_DIR"/*.md|"$KB_DIR"/*/*.md|"$KB_DIR"/*/*/*.md) : ;;
  *) exit 0 ;;
esac
HITS="$(.kb/scripts/kb-check.sh 2>/dev/null | grep -F "$REL" || true)"
if [ -n "$HITS" ]; then
  echo "kb-kit: the file you just touched has hygiene findings:" >&2
  printf '%s\n' "$HITS" >&2
  exit 2
fi
exit 0

#!/usr/bin/env bash
# kb-init.sh — install kb-kit into a target repository (spec-kit model: copy, no runtime dependency back).
# Zero dependencies: bash + coreutils + find + awk.
#
# Usage (run from anywhere; target = current directory):
#   kb-init.sh [--dir <kb-dir>]          scaffold a new base (default: kb/)
#   kb-init.sh --migrate <corpus-dir>    install toolkit + write MIGRATION_REPORT.md (report only)
#   kb-init.sh --apply-migration <rpt>   create KB.md skeleton from a reviewed report (adds files only)
#   kb-init.sh --update                  refresh .kb/ and .claude/skills/ (never touches knowledge)
#   kb-init.sh --user-skills             install kb-* skills user-level (~/.claude/skills): commands in EVERY
#                                        project; they act only where a base exists (./.kb/config)
#   kb-init.sh --hooks                   wire automation: git pre-commit + Claude Code hooks + CI template
#   kb-init.sh --uninstall               remove toolkit (.kb/, .claude/skills/kb-*); knowledge untouched
#   kb-init.sh --mask <name|path>        put on a mask (--pack kept as alias)
#   kb-init.sh --json                    machine-readable result
# Exit: 0 ok, 1 findings/conflict, 2 usage/environment error.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
VERSION="$(git -C "$SRC_DIR" describe --tags --always 2>/dev/null || echo 0.1.0-dev)"
TARGET="$(pwd)"
KB_DIR="kb"
MODE="scaffold"
ARG=""
JSON=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)             KB_DIR="${2:?}"; shift 2 ;;
    --migrate)         MODE="migrate"; ARG="${2:?}"; shift 2 ;;
    --apply-migration) MODE="apply"; ARG="${2:?}"; shift 2 ;;
    --update)          MODE="update"; shift ;;
    --user-skills)     MODE="userskills"; shift ;;
    --hooks)           MODE="hooks"; shift ;;
    --uninstall)       MODE="uninstall"; shift ;;
    --mask|--pack)     MODE="mask"; ARG="${2:?}"; shift 2 ;;
    --json)            JSON=1; shift ;;
    *) echo "kb-init: unknown option $1" >&2; exit 2 ;;
  esac
done

say() { [ "$JSON" = 1 ] || echo "$@"; }

copy_toolkit() {
  mkdir -p "$TARGET/.kb/scripts" "$TARGET/.kb/templates" "$TARGET/.kb/masks" "$TARGET/.kb/hooks" "$TARGET/.claude/skills"
  cp -f "$SRC_DIR"/core/scripts/* "$TARGET/.kb/scripts/"
  cp -rf "$SRC_DIR"/core/templates/. "$TARGET/.kb/templates/"
  [ -d "$SRC_DIR/core/masks" ] && cp -rf "$SRC_DIR"/core/masks/. "$TARGET/.kb/masks/" 2>/dev/null || true
  cp -rf "$SRC_DIR"/adapters/claude/skills/. "$TARGET/.claude/skills/"
  chmod +x "$TARGET"/.kb/scripts/*.sh 2>/dev/null || true
}

write_config() {
  # preserve user-added lines (EXTERNAL_BASE_*, etc.) across updates
  local extra=""
  [ -f "$TARGET/.kb/config" ] && extra="$(grep -v -e '^KB_DIR=' -e '^KB_KIT_VERSION=' "$TARGET/.kb/config" || true)"
  { printf 'KB_DIR=%s\nKB_KIT_VERSION=%s\n' "$1" "$VERSION"
    if [ -n "$extra" ]; then printf '%s\n' "$extra"; fi; } > "$TARGET/.kb/config"
}

git rev-parse --git-dir >/dev/null 2>&1 || say "kb-init: WARNING — target is not a git repository; diff/review/rollback safety degraded"

case "$MODE" in

scaffold)
  copy_toolkit
  write_config "$KB_DIR"
  if [ ! -f "$TARGET/$KB_DIR/KB.md" ]; then
    mkdir -p "$TARGET/$KB_DIR"
    proj="$(basename "$TARGET")"
    sed "s/{{project}}/$proj/" "$SRC_DIR/core/templates/KB.md" | grep -v '^- \[{{theme}}' > "$TARGET/$KB_DIR/KB.md"
    grep -v '{{raw item}}' "$SRC_DIR/core/templates/INBOX.md" > "$TARGET/$KB_DIR/INBOX.md"
    say "kb-init: scaffolded base at $KB_DIR/ (KB.md, INBOX.md)"
  else
    say "kb-init: base already exists at $KB_DIR/ — knowledge untouched, toolkit refreshed"
  fi
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"scaffold","kb_dir":"%s"}\n' "$KB_DIR"; fi
  ;;

update)
  [ -f "$TARGET/.kb/config" ] || { echo "kb-init: nothing to update (.kb/config missing) — run scaffold first" >&2; exit 2; }
  KB_DIR="$(awk -F= '$1=="KB_DIR"{print $2}' "$TARGET/.kb/config")"
  copy_toolkit
  write_config "$KB_DIR"
  say "kb-init: toolkit refreshed (.kb/, .claude/skills/); knowledge content untouched"
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"update","kb_dir":"%s"}\n' "$KB_DIR"; fi
  ;;

migrate)
  CORPUS="${ARG%/}"
  [ -d "$TARGET/$CORPUS" ] || { echo "kb-init: corpus dir not found: $CORPUS" >&2; exit 2; }
  copy_toolkit
  write_config "$CORPUS"
  RPT="$TARGET/$CORPUS/MIGRATION_REPORT.md"
  {
    echo "# Migration report — $CORPUS ($(date +%Y-%m-%d 2>/dev/null || echo today))"
    echo
    echo "Mechanical inventory only. NOTHING was moved, renamed, or rewritten."
    echo "Next: run /kb-init in your agent — it reads this report plus your READMEs,"
    echo "drafts per-theme rules capturing YOUR conventions, and applies only after"
    echo "your confirmation."
    echo
    echo "## Candidate themes (subdirectories with markdown files)"
    echo
    find "$TARGET/$CORPUS" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort | while read -r d; do
      n=$(find "$d" -name '*.md' -type f | wc -l)
      [ "$n" -gt 0 ] || continue
      fm=$(find "$d" -name '*.md' -type f -exec sh -c 'head -1 "$1" | grep -q "^---$"' _ {} \; -print 2>/dev/null | wc -l)
      idx=""
      for cand in INDEX.md README.md; do
        [ -f "$d/$cand" ] && grep -q '](.*\.md)' "$d/$cand" && idx="$cand" && break
      done
      echo "- \`$(basename "$d")/\` — $n md files, $fm with frontmatter${idx:+, index-like file: $idx}"
    done
    echo
    echo "## Root-level markdown files"
    echo
    find "$TARGET/$CORPUS" -maxdepth 1 -type f -name '*.md' ! -name 'MIGRATION_REPORT.md' | LC_ALL=C sort | while read -r f; do
      rows=$(grep -c '](.*\.md)' "$f" 2>/dev/null || true)
      echo "- \`$(basename "$f")\` — ${rows:-0} md-link rows$( [ "${rows:-0}" -gt 5 ] && echo ' (index candidate)')"
    done
    echo
    echo "## Non-markdown artifacts"
    echo
    total=$(find "$TARGET/$CORPUS" -type f ! -name '*.md' | wc -l)
    echo "- $total files (audio/spreadsheets/exports/scripts). They stay OUT of the graph;"
    echo "  nodes may cite them via plain relative links (kb-check validates existence)."
    echo
    echo "## Naming patterns (dated-prefix files)"
    echo
    dated=$(find "$TARGET/$CORPUS" -type f -name '20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]*' | wc -l)
    echo "- $dated files start with a YYYY-MM-DD prefix."
  } > "$RPT"
  say "kb-init: toolkit installed; inventory written to $CORPUS/MIGRATION_REPORT.md (report only, no content changes)"
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"migrate","kb_dir":"%s","report":"%s/MIGRATION_REPORT.md"}\n' "$CORPUS" "$CORPUS"; fi
  ;;

apply)
  RPT="$TARGET/$ARG"
  [ -f "$RPT" ] || { echo "kb-init: report not found: $ARG" >&2; exit 2; }
  KB_DIR="$(dirname "$ARG")"
  if [ -f "$TARGET/$KB_DIR/KB.md" ]; then
    say "kb-init: KB.md already exists at $KB_DIR/ — nothing to apply mechanically"
  else
    {
      echo "# Knowledge base — $(basename "$TARGET") (adopted corpus: $KB_DIR)"
      echo
      echo "## Themes"
      echo
      awk '/^- `/{gsub(/`/,""); sub(/^- /,""); split($0,a," — "); t=a[1]; sub(/\/$/,"",t); printf "- [%s/](%s/INDEX.md) — %s\n", t, t, a[2]}' "$RPT"
      echo
      echo "## Conventions"
      echo
      echo "- Adopted corpus: existing files keep their own conventions (see per-theme rules)."
      echo "- New nodes follow kb-kit format: one node = one fact, frontmatter, [[links]]."
    } > "$TARGET/$KB_DIR/KB.md"
    say "kb-init: KB.md skeleton created at $KB_DIR/KB.md from report (only new file added)"
  fi
  if [ ! -f "$TARGET/$KB_DIR/INBOX.md" ]; then
    grep -v '{{raw item}}' "$SRC_DIR/core/templates/INBOX.md" > "$TARGET/$KB_DIR/INBOX.md"
    say "kb-init: INBOX.md created at $KB_DIR/INBOX.md"
  fi
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"apply","kb_dir":"%s"}\n' "$KB_DIR"; fi
  ;;

userskills)
  DEST="$HOME/.claude/skills"
  mkdir -p "$DEST"
  cp -rf "$SRC_DIR"/adapters/claude/skills/. "$DEST/"
  say "kb-init: kb-* skills installed user-level at $DEST"
  say "kb-init: /kb-add, /kb-ask, /kb-check, /kb-audit, /kb-viz now exist in every project"
  say "kb-init: they act only where a base is installed (./.kb/config); restart open sessions to pick them up"
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"user-skills","dest":"%s"}\n' "$DEST"; fi
  ;;

hooks)
  [ -f "$TARGET/.kb/config" ] || { echo "kb-init: install kb-kit first (no .kb/config)" >&2; exit 2; }
  mkdir -p "$TARGET/.kb/hooks"
  for h in session-start.sh posttool-check.sh pre-commit.kb.sh; do
    cp -f "$SRC_DIR/core/templates/hooks/$h" "$TARGET/.kb/hooks/$h"
    chmod +x "$TARGET/.kb/hooks/$h"
  done
  cp -f "$SRC_DIR/core/templates/hooks/kb-check.yml" "$TARGET/.kb/hooks/kb-check.yml"
  # 1. git pre-commit: install only if the slot is free; never clobber an existing hook
  if git -C "$TARGET" rev-parse --git-dir >/dev/null 2>&1; then
    GITDIR="$(git -C "$TARGET" rev-parse --git-dir)"
    case "$GITDIR" in /*) : ;; *) GITDIR="$TARGET/$GITDIR" ;; esac
    if [ ! -e "$GITDIR/hooks/pre-commit" ]; then
      mkdir -p "$GITDIR/hooks"
      cp -f "$TARGET/.kb/hooks/pre-commit.kb.sh" "$GITDIR/hooks/pre-commit"
      chmod +x "$GITDIR/hooks/pre-commit"
      say "kb-init: git pre-commit hook installed (warn-only; KB_PRECOMMIT_STRICT=1 to block)"
    else
      say "kb-init: existing pre-commit hook found — NOT touched. Chain it manually: bash .kb/hooks/pre-commit.kb.sh"
    fi
  fi
  # 2. Claude Code hooks: write settings only if absent; never merge blindly
  if [ ! -f "$TARGET/.claude/settings.json" ]; then
    mkdir -p "$TARGET/.claude"
    cp -f "$SRC_DIR/core/templates/hooks/claude-settings.json" "$TARGET/.claude/settings.json"
    say "kb-init: .claude/settings.json created (SessionStart status + PostToolUse hygiene)"
  else
    cp -f "$SRC_DIR/core/templates/hooks/claude-settings.json" "$TARGET/.kb/hooks/claude-settings-snippet.json"
    say "kb-init: .claude/settings.json exists — NOT touched. Merge the snippet yourself: .kb/hooks/claude-settings-snippet.json"
  fi
  # 3. CI: template staged, not auto-activated (pushing CI is the user's call)
  say "kb-init: CI template staged at .kb/hooks/kb-check.yml — copy to .github/workflows/ to activate"
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"hooks"}\n'; fi
  ;;

uninstall)
  [ -f "$TARGET/.kb/config" ] || { echo "kb-init: nothing to uninstall (.kb/config missing)" >&2; exit 2; }
  KB_DIR="$(awk -F= '$1=="KB_DIR"{print $2}' "$TARGET/.kb/config")"
  rm -rf "$TARGET/.kb"
  for s in kb-add kb-ask kb-audit kb-check kb-init kb-viz; do rm -rf "$TARGET/.claude/skills/$s"; done
  rmdir "$TARGET/.claude/skills" "$TARGET/.claude" 2>/dev/null || true
  say "kb-init: toolkit removed (.kb/, .claude/skills/kb-*). Your knowledge at $KB_DIR/ is UNTOUCHED."
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"uninstall","kb_dir":"%s"}\n' "$KB_DIR"; fi
  ;;

mask)
  # resolve pack dir: explicit path > kb-kit built-ins > already-installed .kb/masks
  if   [ -d "$ARG" ]; then PDIR="$ARG"
  elif [ -d "$SRC_DIR/core/masks/$ARG" ]; then PDIR="$SRC_DIR/core/masks/$ARG"
  elif [ -d "$TARGET/.kb/masks/$ARG" ]; then PDIR="$TARGET/.kb/masks/$ARG"
  else echo "kb-init: mask not found: $ARG" >&2; exit 2; fi
  [ -f "$PDIR/mask.conf" ] || { echo "kb-init: not a mask (mask.conf missing): $PDIR" >&2; exit 2; }
  [ -f "$TARGET/.kb/config" ] || { echo "kb-init: install kb-kit first (no .kb/config)" >&2; exit 2; }
  KB_DIR="$(awk -F= '$1=="KB_DIR"{print $2}' "$TARGET/.kb/config")"
  PNAME="$(awk -F= '$1=="NAME"{print $2}' "$PDIR/mask.conf")"
  PDESC="$(awk -F= '$1=="DESCRIPTION"{print $2}' "$PDIR/mask.conf")"
  SLUG="$(awk -F= '$1=="THEME_SLUG"{print $2}' "$PDIR/mask.conf")"
  THEMES="$(awk -F= '$1=="THEMES"{print $2}' "$PDIR/mask.conf")"
  if [ -n "$THEMES" ]; then
    # mask format v2: multiple themes, per-theme content in themes/<slug>/
    mkdir -p "$TARGET/.kb/masks/$PNAME"
    cp -rf "$PDIR/." "$TARGET/.kb/masks/$PNAME/"
    COLLIDED=""
    for SLUG in $THEMES; do
      TD="$PDIR/themes/$SLUG"
      [ -d "$TD" ] || { echo "kb-init: mask broken — themes/$SLUG missing in $PNAME" >&2; exit 2; }
      THEME="$TARGET/$KB_DIR/$SLUG"
      if [ -d "$THEME" ]; then COLLIDED="$COLLIDED $SLUG"; continue; fi
      mkdir -p "$THEME"
      printf '# %s — index\n\n' "$SLUG" > "$THEME/INDEX.md"
      awk -v rules="$TD/rules.md" -v slug="$SLUG" '
        /\{\{rules\}\}/ { while ((getline l < rules) > 0) print l; next }
        { gsub(/\{\{theme\}\}/, slug); print }
      ' "$SRC_DIR/adapters/claude/theme-CLAUDE.md.tmpl" > "$THEME/CLAUDE.md" 2>/dev/null \
        || cp "$TD/rules.md" "$THEME/CLAUDE.md"
      [ -f "$TD/checks.conf" ] && cp -f "$TD/checks.conf" "$THEME/.kb-checks.conf"
      if [ -f "$TARGET/$KB_DIR/KB.md" ] && ! grep -q "]($SLUG/INDEX.md)" "$TARGET/$KB_DIR/KB.md"; then
        awk -v row="- [$SLUG/]($SLUG/INDEX.md) — $PNAME mask: $SLUG" '
          { print } /^## Themes$/ { getline nl; print nl; print row }
        ' "$TARGET/$KB_DIR/KB.md" > "$TARGET/$KB_DIR/KB.md.tmp" && mv "$TARGET/$KB_DIR/KB.md.tmp" "$TARGET/$KB_DIR/KB.md"
      fi
      say "kb-init: theme $KB_DIR/$SLUG/ materialized (${PNAME} mask)"
    done
    if [ -n "$COLLIDED" ]; then
      echo "kb-init: COLLISION — theme(s) already exist:$COLLIDED. They were SKIPPED (nothing overwritten)." >&2
      echo "kb-init: resolve via /kb-init in your agent (merge/rename), then re-run." >&2
      exit 1
    fi
    say "kb-init: mask '$PNAME' is on ($(echo $THEMES | wc -w) themes); templates in .kb/masks/$PNAME/themes/*/templates/"
    if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"mask","mask":"%s","themes":"%s"}\n' "$PNAME" "$THEMES"; fi
    exit 0
  fi
  [ -n "$SLUG" ] || { echo "kb-init: mask.conf has no THEME_SLUG (v1) or THEMES (v2)" >&2; exit 2; }
  THEME="$TARGET/$KB_DIR/$SLUG"
  if [ -d "$THEME" ]; then
    echo "kb-init: CONFLICT — theme '$SLUG' already exists at $KB_DIR/$SLUG/." >&2
    echo "kb-init: nothing was changed. Options: rename the pack theme, merge manually, or abort." >&2
    exit 1
  fi
  mkdir -p "$THEME" "$TARGET/.kb/masks/$PNAME"
  cp -rf "$PDIR/." "$TARGET/.kb/masks/$PNAME/"
  printf '# %s — index\n\n' "$SLUG" > "$THEME/INDEX.md"
  awk -v rules="$PDIR/rules.md" -v slug="$SLUG" '
    /\{\{rules\}\}/ { while ((getline l < rules) > 0) print l; next }
    { gsub(/\{\{theme\}\}/, slug); print }
  ' "$SRC_DIR/adapters/claude/theme-CLAUDE.md.tmpl" > "$THEME/CLAUDE.md" 2>/dev/null \
    || cp "$PDIR/rules.md" "$THEME/CLAUDE.md"
  if [ -f "$TARGET/$KB_DIR/KB.md" ] && ! grep -q "]($SLUG/INDEX.md)" "$TARGET/$KB_DIR/KB.md"; then
    awk -v row="- [$SLUG/]($SLUG/INDEX.md) — $PDESC" '
      { print } /^## Themes$/ { getline nl; print nl; print row }
    ' "$TARGET/$KB_DIR/KB.md" > "$TARGET/$KB_DIR/KB.md.tmp" && mv "$TARGET/$KB_DIR/KB.md.tmp" "$TARGET/$KB_DIR/KB.md"
  fi
  say "kb-init: mask '$PNAME' is on — theme $KB_DIR/$SLUG/ (INDEX.md, CLAUDE.md), templates in .kb/masks/$PNAME/templates/"
  if [ "$JSON" = 1 ]; then printf '{"status":"ok","mode":"mask","pack":"%s","theme":"%s/%s"}\n' "$PNAME" "$KB_DIR" "$SLUG"; fi
  ;;
esac

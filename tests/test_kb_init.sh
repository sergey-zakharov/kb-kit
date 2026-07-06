#!/usr/bin/env bash
# Installer tests: scaffold, idempotency, --update safety, --migrate report-only. Zero deps.
set -u
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
FAIL=0
ok()   { echo "  ok: $1"; }
fail() { echo "  FAIL: $1"; FAIL=1; }

echo "test_kb_init"
TMP="$ROOT/tests/tmp/init-run"
rm -rf "$TMP"; mkdir -p "$TMP"

# 1. Scaffold on an empty repo
( cd "$TMP" && git init -q . && "$ROOT/kb-init.sh" >/dev/null )
[ -f "$TMP/kb/KB.md" ] && ok "KB.md scaffolded" || fail "KB.md missing"
[ -f "$TMP/kb/INBOX.md" ] && ok "INBOX.md scaffolded" || fail "INBOX.md missing"
[ -x "$TMP/.kb/scripts/kb-check.sh" ] && ok ".kb/scripts installed+executable" || fail ".kb/scripts missing"
[ -f "$TMP/.claude/skills/kb-add/SKILL.md" ] && ok "skills installed" || fail "skills missing"
grep -q "^KB_DIR=kb$" "$TMP/.kb/config" && ok "config KB_DIR" || fail "config wrong"
grep -q '{{' "$TMP/kb/KB.md" && fail "unresolved placeholders in KB.md" || ok "no placeholders leaked"

# 2. Idempotency: knowledge survives re-run
echo "user content marker" >> "$TMP/kb/KB.md"
mkdir -p "$TMP/kb/notes" && printf -- '---\nname: marker\ndescription: marker node\ntype: fact\n---\nbody\n' > "$TMP/kb/notes/marker.md"
( cd "$TMP" && "$ROOT/kb-init.sh" >/dev/null )
grep -q "user content marker" "$TMP/kb/KB.md" && ok "re-run keeps KB.md edits" || fail "re-run clobbered KB.md"
[ -f "$TMP/kb/notes/marker.md" ] && ok "re-run keeps nodes" || fail "re-run lost node"

# 3. --update refreshes toolkit, never touches knowledge
BEFORE=$(find "$TMP/kb" -type f | LC_ALL=C sort | xargs cat | cksum)
( cd "$TMP" && "$ROOT/kb-init.sh" --update >/dev/null )
AFTER=$(find "$TMP/kb" -type f | LC_ALL=C sort | xargs cat | cksum)
[ "$BEFORE" = "$AFTER" ] && ok "--update leaves knowledge byte-identical" || fail "--update touched knowledge"

# 4. --migrate writes ONLY the report (plus toolkit outside the corpus)
TMP2="$ROOT/tests/tmp/migrate-run"
rm -rf "$TMP2"; mkdir -p "$TMP2"
cp -r "$ROOT/tests/fixtures/mini-kb" "$TMP2/docs"
( cd "$TMP2" && git init -q . && git add -A && git -c user.email=t@t -c user.name=t commit -qm base )
( cd "$TMP2" && "$ROOT/kb-init.sh" --migrate docs >/dev/null )
CHANGED=$(cd "$TMP2" && git status --porcelain -- docs | grep -v 'MIGRATION_REPORT.md' | wc -l)
[ "$CHANGED" -eq 0 ] && ok "--migrate: zero content changes in corpus" || { fail "--migrate touched corpus:"; (cd "$TMP2" && git status --porcelain -- docs); }
[ -f "$TMP2/docs/MIGRATION_REPORT.md" ] && ok "migration report written" || fail "report missing"
grep -q "product/" "$TMP2/docs/MIGRATION_REPORT.md" && ok "report lists candidate themes" || fail "themes not in report"
grep -q "KB_DIR=docs" "$TMP2/.kb/config" && ok "config points at corpus" || fail "config KB_DIR wrong"
( cd "$TMP2" && "$ROOT/kb-init.sh" --apply-migration docs/MIGRATION_REPORT.md >/dev/null )
[ -f "$TMP2/docs/KB.md" ] && [ -f "$TMP2/docs/INBOX.md" ] && ok "apply-migration creates KB.md + INBOX.md" || fail "apply-migration artifacts missing"

# 4b. --update preserves custom config lines (external bases etc.)
echo "EXTERNAL_BASE_mem=/tmp/somewhere" >> "$TMP/.kb/config"
( cd "$TMP" && "$ROOT/kb-init.sh" --update >/dev/null )
grep -q "^EXTERNAL_BASE_mem=/tmp/somewhere$" "$TMP/.kb/config" && ok "--update preserves custom config lines" || fail "--update wiped custom config"
grep -q "^KB_KIT_VERSION=v" "$TMP/.kb/config" && ok "version stamped from git describe" || fail "version not stamped"

# 5. --json mode
( cd "$TMP" && "$ROOT/kb-init.sh" --update --json | grep -q '"status":"ok"' ) && ok "--json output" || fail "--json broken"

# 6. --pack: install built-in pack, then collision on re-install
( cd "$TMP" && "$ROOT/kb-init.sh" --mask sources >/dev/null 2>&1 )
[ -f "$TMP/kb/sources/INDEX.md" ] && ok "mask theme INDEX.md created" || fail "pack theme missing"
[ -f "$TMP/kb/sources/CLAUDE.md" ] && grep -q "one source material" "$TMP/kb/sources/CLAUDE.md" \
  && ok "mask rules wrapped into theme CLAUDE.md" || fail "pack rules missing from CLAUDE.md"
grep -q "](sources/INDEX.md)" "$TMP/kb/KB.md" && ok "KB.md gained mask theme row" || fail "KB.md row missing"
[ -f "$TMP/.kb/masks/sources/templates/source-card.md" ] && ok "mask templates staged (--pack alias works on re-install)" || fail "pack templates missing"
if ( cd "$TMP" && "$ROOT/kb-init.sh" --pack sources >/dev/null 2>&1 ); then
  fail "re-install did not report collision"
else
  RC=$?; [ "$RC" -eq 1 ] && ok "collision surfaced (exit 1), nothing overwritten" || fail "collision wrong exit code: $RC"
fi

# 6a2. mask v2: multi-theme install with partial collision
mkdir -p "$TMP/kb/insights"   # pre-existing theme → must be skipped, not overwritten
echo "pre-existing" > "$TMP/kb/insights/KEEP.md"
if ( cd "$TMP" && "$ROOT/kb-init.sh" --mask product >/dev/null 2>&1 ); then
  fail "partial collision did not exit 1"
else
  ok "partial collision surfaced (exit 1)"
fi
[ -f "$TMP/kb/insights/KEEP.md" ] && [ ! -f "$TMP/kb/insights/INDEX.md" ] && ok "colliding theme untouched" || fail "colliding theme was modified"
for t in journeys hypotheses decisions segments; do
  [ -f "$TMP/kb/$t/INDEX.md" ] && [ -f "$TMP/kb/$t/CLAUDE.md" ] || fail "theme $t not installed"
done
ok "non-colliding themes installed (4/5)"
[ -f "$TMP/kb/hypotheses/.kb-checks.conf" ] && grep -q "REQUIRED_SECTIONS_hypothesis" "$TMP/kb/hypotheses/.kb-checks.conf" && ok "theme checks staged as .kb-checks.conf" || fail "checks not staged"
grep -q "](hypotheses/INDEX.md)" "$TMP/kb/KB.md" && ok "KB.md gained mask theme rows" || fail "KB.md rows missing"
[ -f "$TMP/.kb/masks/product/themes/insights/templates/insight.md" ] && ok "mask v2 staged in .kb/masks" || fail "mask staging missing"

# 6b. --hooks wires automation without clobbering
( cd "$TMP" && "$ROOT/kb-init.sh" --hooks >/dev/null )
[ -x "$TMP/.kb/hooks/session-start.sh" ] && [ -x "$TMP/.kb/hooks/posttool-check.sh" ] && ok "hook scripts staged+executable" || fail "hook scripts missing"
[ -x "$TMP/.git/hooks/pre-commit" ] && ok "git pre-commit installed (slot was free)" || fail "pre-commit not installed"
[ -f "$TMP/.claude/settings.json" ] && grep -q "session-start.sh" "$TMP/.claude/settings.json" && ok "claude settings created" || fail "claude settings missing"
[ -f "$TMP/.kb/hooks/kb-check.yml" ] && ok "CI template staged (not auto-activated)" || fail "CI template missing"
[ ! -f "$TMP/.github/workflows/kb-check.yml" ] && ok "CI not auto-pushed into .github/" || fail "CI auto-activated"
# clobber protection: pre-existing hook and settings survive a re-run
echo "#!/bin/sh" > "$TMP/.git/hooks/pre-commit.bak" && mv "$TMP/.git/hooks/pre-commit" "$TMP/.git/hooks/pre-commit.orig" && printf '#!/bin/sh\necho custom\n' > "$TMP/.git/hooks/pre-commit"
( cd "$TMP" && "$ROOT/kb-init.sh" --hooks >/dev/null )
grep -q "echo custom" "$TMP/.git/hooks/pre-commit" && ok "existing pre-commit not clobbered" || fail "pre-commit clobbered"
[ -f "$TMP/.kb/hooks/claude-settings-snippet.json" ] && ok "settings snippet staged when settings exist" || fail "snippet missing"
# hook behavior: clean base → pre-commit passes
( cd "$TMP" && git add -A >/dev/null 2>&1; bash .kb/hooks/pre-commit.kb.sh ) && ok "pre-commit exits 0 on clean base" || fail "pre-commit failed on clean base"

# 7. --uninstall removes toolkit only, knowledge untouched
( cd "$TMP" && "$ROOT/kb-init.sh" --uninstall >/dev/null )
[ ! -d "$TMP/.kb" ] && ok "--uninstall removed .kb/" || fail ".kb/ survived uninstall"
[ ! -d "$TMP/.claude/skills/kb-add" ] && ok "--uninstall removed kb-* skills" || fail "skills survived"
[ -f "$TMP/kb/KB.md" ] && grep -q "user content marker" "$TMP/kb/KB.md" && ok "--uninstall left knowledge untouched" || fail "uninstall touched knowledge"

[ $FAIL -eq 0 ] && echo "test_kb_init: PASS" || { echo "test_kb_init: FAIL"; exit 1; }

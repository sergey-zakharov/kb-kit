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

# 4b. --update preserves custom config lines (external bases etc.)
echo "EXTERNAL_BASE_mem=/tmp/somewhere" >> "$TMP/.kb/config"
( cd "$TMP" && "$ROOT/kb-init.sh" --update >/dev/null )
grep -q "^EXTERNAL_BASE_mem=/tmp/somewhere$" "$TMP/.kb/config" && ok "--update preserves custom config lines" || fail "--update wiped custom config"
grep -q "^KB_KIT_VERSION=v" "$TMP/.kb/config" && ok "version stamped from git describe" || fail "version not stamped"

# 5. --json mode
( cd "$TMP" && "$ROOT/kb-init.sh" --update --json | grep -q '"status":"ok"' ) && ok "--json output" || fail "--json broken"

# 6. --pack: install built-in pack, then collision on re-install
( cd "$TMP" && "$ROOT/kb-init.sh" --pack sources >/dev/null 2>&1 )
[ -f "$TMP/kb/sources/INDEX.md" ] && ok "pack theme INDEX.md created" || fail "pack theme missing"
[ -f "$TMP/kb/sources/CLAUDE.md" ] && grep -q "one source material" "$TMP/kb/sources/CLAUDE.md" \
  && ok "pack rules wrapped into theme CLAUDE.md" || fail "pack rules missing from CLAUDE.md"
grep -q "](sources/INDEX.md)" "$TMP/kb/KB.md" && ok "KB.md gained pack theme row" || fail "KB.md row missing"
[ -f "$TMP/.kb/packs/sources/templates/source-card.md" ] && ok "pack templates staged" || fail "pack templates missing"
if ( cd "$TMP" && "$ROOT/kb-init.sh" --pack sources >/dev/null 2>&1 ); then
  fail "re-install did not report collision"
else
  RC=$?; [ "$RC" -eq 1 ] && ok "collision surfaced (exit 1), nothing overwritten" || fail "collision wrong exit code: $RC"
fi

[ $FAIL -eq 0 ] && echo "test_kb_init: PASS" || { echo "test_kb_init: FAIL"; exit 1; }

# Validation run: US4 — /kb-check (2026-07-06)

**Setup**: copy of `tests/fixtures/mini-kb-defective` → `tests/tmp/us4-run`;
skill procedure from `adapters/claude/skills/kb-check/SKILL.md` executed.

1. `kb-check.sh --json` → **10 findings** (full seeded set, see fixture README).
2. Safe fixes: exactly one finding carried `safe_fix: add-index-row`
   (`product/unlinked-unindexed.md`). Applied: index row appended to
   `product/INDEX.md` in the fixture's existing bullet style.
3. Re-run → **9 findings**: `index-missing-row` cleared; all remaining findings
   are propose-only (stale row, broken link/anchor/file-ref, unindexed theme,
   frontmatter, 2× flagged, inbox-blocked) — none were auto-applied. ✅
4. Destructive resolutions presented as numbered proposals with evidence
   (acceptance scenarios 1 & 3); clean-base zero-write behavior covered by
   `tests/test_kb_check.sh` on mini-kb (exit 0, no findings). ✅

**Verdict**: US4 acceptance scenarios 1–4 ✅. Before/after: 10 → 9 via the one
legal safe fix; nothing else changed on disk.

# Skill Contracts: kb-kit v1 (Claude adapter)

Judgment layer. Every skill: works in a fresh session; reads indexes before bodies (Constitution IV); never deletes/overwrites without explicit confirmation (Constitution III); ends with a report listing every file touched.

## /kb-add

**Input**: raw material (pasted text, file path, link + commentary) | `--from-session` mode (extract candidate facts from current conversation → numbered confirmation list → standard pipeline).

**Behavior contract**:
1. Read KB.md + candidate theme indexes (+ theme rules of the winner).
2. Classify: theme, target node (new vs update), links. Consult `.kb/hooks/second-opinion` if present.
3. Ambiguous placement → present candidates + recommendation, wait. Complementary material on existing node → apply directly. Material contradiction → quote both versions, wait (FR-006).
4. Multi-fact input → propose split into several nodes, user may veto.
5. Write node(s) with valid frontmatter + evidence citations (link + verbatim quote + locator for source-derived claims), update INDEX.md row(s) in the same operation, update INBOX status if the item came from the queue.
6. Report: files created/updated, index rows, links set, hook opinion, open questions.

## /kb-ask

**Input**: a question.

**Behavior contract**: staged reading (KB.md → selected theme INDEX.md files → selected node bodies only, ≤10% of base content); answer with per-claim citations quoting the supporting line(s) (`file.md`: "quote"); warn if a cited node carries `disputed=`/`superseded-by=` flags; if the base can't answer — say so and name nearest related nodes; never invent.

## /kb-check

**Input**: none (optionally scope to a theme).

**Behavior contract**: run `kb-check.sh --json`; auto-apply only findings with `safe_fix` (e.g., add missing index row), listing each; for destructive resolutions (remove stale row, delete orphan, retarget link) — propose with evidence, apply only confirmed ones; clean base → "clean bill of health", zero writes.

## /kb-audit

**Input**: none (optionally scope to theme(s)).

**Behavior contract**:
1. Candidates mechanically: `kb-graph.sh` output → pairs by shared tags / link neighborhoods / same theme / name+description token overlap. Never all-pairs body reads.
2. Read candidate bodies; classify: `contradiction` | `duplicate` | `superseded` | `should-link`, each with quoted evidence from both nodes.
3. Write dated audit report (report node in the base) with all findings.
4. On per-finding confirmation: write mirrored `flags` on both nodes (`disputed=`, `duplicate-of=`, `superseded-by=`/`supersedes=`) or add proposed `[[links]]`; merges get diff-style preview first.
5. Nothing changes without confirmation; report lists every file touched.

## /kb-init (migration driver)

**Input**: target corpus directory.

**Behavior contract**: run `kb-init.sh --migrate` (mechanical inventory) → read MIGRATION_REPORT.md + corpus READMEs → draft per-theme rules capturing the corpus's own conventions (naming, card format, index style) → present full plan (what will be added; nothing moved/renamed/rewritten) → on confirmation `kb-init.sh --apply-migration`; ambiguous areas reported, not normalized.

## /kb-viz

**Input**: none (optional `--out`).

**Behavior contract**: run `kb-viz.sh`; verify output exists and is single-file/offline; report path + node/edge counts; suggest committing as snapshot when regenerated.

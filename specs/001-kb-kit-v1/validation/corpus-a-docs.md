# Corpus validation №1: private product-docs corpus (T029, SC-003) — 2026-07-06

> **Privacy note**: metrics-only record; internal document names and product
> specifics are withheld. Corpus copies live in `tests/tmp/` (gitignored).

**Corpus shape**: 717 md files across 2 top-level themes (641 + 76), 58 non-md
artifacts, months of real research/business documentation; one theme has an
index-like README, frontmatter coverage 88/641 and 1/76.

## Migration (US3)

- `kb-init.sh --migrate`: git status over the corpus after the run —
  **exactly one new file** (`MIGRATION_REPORT.md`), zero modified/moved/renamed.
  **SC-003 core assertion ✅**
- Report correctly inventoried themes, frontmatter coverage, the index-like
  README, artifact count, and dated-prefix naming.
- `--apply-migration` → KB.md skeleton; Phase B (lite): theme INDEX.md
  generated from the README's 21 link rows (adds-only).

## Mechanical layer at real scale

- `kb-graph.sh`: **1.7 s** / `kb-check.sh`: **1.7 s** on 717 files (target
  <5 s @1000 ✅).
- Findings profile: 701 index-missing-row (the un-indexed mass of an adopted
  corpus — expected), 328 broken-file-ref, 109 broken-link,
  92 frontmatter-invalid (their frontmatter ≠ kb-kit flat format — degraded
  adopted mode, not an error), 4 index-stale-row.
- **True rot discovered**: the adopted README index references a file by its
  pre-move path — a genuinely stale link in the real corpus. Caveat: a share
  of findings are artifacts of the partial corpus copy (two sibling dirs not
  copied); full-corpus counts will differ.
- Known v1 parser limit: `](file.md#anchor)` filerefs are existence-checked
  with the anchor suffix included (5 of 328 — negligible; fix queued).

## /kb-ask on the migrated base (fresh agent, zero context)

- **Q1** (answerable via the adopted index): answered correctly with verbatim
  status quotes from 6 spec files. **Read: 2 indexes + 8 bodies of 717 files
  ≈ 1.4% of the corpus — SC-008 real-world ✅**
- **Q2** (answer exists on disk but is not indexed): honest can't-answer WITH
  diagnosis — named the missing theme index, pointed at the probable answer
  subfolder, refused to full-scan per skill rules, listed nearest indexed
  nodes. **The failure mode is the product thesis live: retrieval quality =
  index discipline; un-adopted themes are invisible — exactly what phase-B
  adoption and /kb-add fix.**

**Verdict**: SC-003 ✅ (zero-touch install over a 717-file corpus, immediately
functional); SC-008 ✅ at real scale; performance ✅.

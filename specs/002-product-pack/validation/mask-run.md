# Validation run: product mask spot-run (T207) — 2026-07-06

**Setup**: fresh scaffold in `tests/tmp/mask-run` → `--mask sources` →
`--mask product`. Result: **two masks coexisting** on one base (6 themes:
sources + insights/journeys/hypotheses/decisions/segments), each with INDEX,
CLAUDE.md rules, and `.kb-checks.conf` where the mask defines invariants.

## SC checks

- **SC-101 (one-command mask, filing works)**: filed by the rules — a source
  card (interview with `^q1` quote+timecode), a segment, an insight, a
  hypothesis. All landed with index rows; `kb-check` clean except the seeded
  violation. ✅
- **SC-102 (evidence across masks)**: the insight cites the sources-mask card
  `[[2026-07-06-user-interview#^q1]]: "…" (12:40)` — anchor resolved by the
  graph (no broken-anchor), quote grep-verified in BOTH files (1/1 each). Mask
  coexistence is not just side-by-side: the graphs interlink. ✅ (SC-105 core
  case covered mechanically; the /kb-ask two-mask synthesis run remains for the
  live T209 session.)
- **SC-103 (invariants)**: seeded hypothesis (no `status`, no Check plan/Result
  sections) → **exactly 3 `mask-invariant` findings**, nothing else flagged;
  after fixing the card → **clean bill of health, 0 findings**. Static-fixture
  variant (`mini-kb-masked`) asserts the same in `tests/test_kb_check.sh`. ✅
- **SC-104 (regression)**: full 001 suites green (~130 assertions), v1
  single-theme `sources` mask installs unchanged, partial-collision behavior
  covered (`kb/insights` pre-existing → skipped, exit 1, 4/5 installed, nothing
  overwritten). ✅

## Deferred

- **T209** — live corpora with the user: corpus C decision log (decisions
  discipline in the wild), corpus A product docs (existing-product mode);
  plus the /kb-ask cross-mask benchmark question (SC-105 full).

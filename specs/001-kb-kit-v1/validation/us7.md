# Validation run: US7 — /kb-audit (2026-07-06)

**Setup**: `tests/tmp/us7-run` = US1 base (12 nodes) + 9 seeded nodes forming
**10 semantic defects**: 4 contradictions, 3 duplicates, 2 superseded,
1 should-link (cross-theme: friendly-discounts ↔ comments-mining). Mechanically clean
before the run (`kb-check`: 0 findings) — semantic defects are invisible to the
structural layer, by design.

**Runner**: fresh agent, zero prior context, skill + graph script paths only.
Detection-only mode (no writes allowed) to verify the no-unconfirmed-changes rule.

## Results (SC-010)

- **Seeded defects surfaced: 9/10** (threshold: ≥8 ✅), every finding with
  verbatim quotes from BOTH sides.
- **Bonus findings: 2**, both legitimate (derived contradiction
  repair-ceiling-copy↔ceiling-is-myth; should-link quiz↔self-repair-guide).
- **Missed: 1** — the cross-theme should-link (friendly-discounts ↔ comments-mining):
  low token overlap between "friendly discounts" and "hidden-fee fear" phrasing. Exactly the
  class that the v2 embeddings accelerator targets; recorded as a known limit.
- **Staging held**: 12 pairs shortlisted (of 190 possible for 20 nodes ≈ 6%),
  17 bodies read, no all-pairs scan.
- **Zero unconfirmed changes**: nothing written or modified during detection. ✅

## Marks application (acceptance scenario 2)

Simulated confirmation of finding #1 → mirrored flags applied:
`repair-ceiling.md: flags: disputed=ceiling-is-myth` /
`ceiling-is-myth.md: flags: disputed=repair-ceiling`. Re-run of `kb-check.sh`:

```
flagged-node  product/ceiling-is-myth.md — open consistency marks: disputed=repair-ceiling
flagged-node  product/repair-ceiling.md — open consistency marks: disputed=ceiling-is-myth
```

Marks are machine-findable downstream (kb-check lists them; kb-ask warns per its
SKILL rule 4). ✅

**Verdict**: US7 acceptance scenarios 1, 2, 4 ✅ directly; scenario 3 (merge
preview) specified in SKILL, exercised at first real merge on corpus validation.

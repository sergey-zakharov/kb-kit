# Tasks: 002 — product-development mask

**Input**: spec.md, plan.md, data-model.md (branch `002-product-pack`)

## Phase 1: Engine — mask format v2 + invariant enforcement

- [X] T201 `kb-graph.sh`: append NODE fields `fmkeys` + `headslugs` (D4); regenerate golden; extend `tests/test_kb_graph.sh`
- [X] T202 `kb-check.sh`: read `<theme>/.kb-checks.conf`, enforce REQUIRED_FRONTMATTER_/REQUIRED_SECTIONS_ per type → finding `mask-invariant` (propose-only)
- [X] T203 Static fixture `tests/fixtures/mini-kb-masked/`: checks file + violating hypothesis + clean hypothesis; extend `tests/test_kb_check.sh` (violation detected, clean node silent — SC-103)
- [X] T204 `kb-init.sh --mask` v2: THEMES loop, per-theme rules→CLAUDE.md + templates staging + `.kb-checks.conf` copy + KB.md rows; collision policy D5 (install free, skip+report colliding, exit 1); v1 masks unchanged; extend `tests/test_kb_init.sh` (multi-theme install, partial collision, sources v1 regression — SC-104)

## Phase 2: Content — the product mask

- [X] T205 [P] `core/masks/product/`: mask.conf (5 themes) + per-theme rules.md/templates/checks.conf per data-model (Mom-Test insights, CJM journeys, falsifiable hypotheses, ADR-light decisions, segments)
- [X] T206 `/kb-add` SKILL: classification hints for product material (discovery interview vs production feedback → insight; opinion without evidence → hypothesis; "we decided" → decision) — one section appended, mask-agnostic wording

## Phase 3: Validation & release

- [X] T207 Fixture spot-run (SC-101/102): scaffold tmp base → install product mask → file 5 varied inputs by the rules (incl. one insight with evidence from a source node) → kb-check clean, mask-invariant fires on a seeded bad hypothesis → `specs/002-product-pack/validation/mask-run.md`
- [X] T208 Docs: cli-contracts (mask v2, `mask-invariant`, `.kb-checks.conf`), README masks section (product mask listed), CHANGELOG v0.2.0; merge → main, tag, push
- [ ] T209 Live validation with user: put the mask on a real corpus (corpus C decision log = decisions discipline; corpus A product docs = existing-product mode) — DEFERRED to user's session, records to validation/

**MVP**: T201–T205. T209 explicitly needs the user.

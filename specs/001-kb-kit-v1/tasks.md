# Tasks: kb-kit v1 — file-based knowledge graph toolkit

**Input**: Design documents from `/specs/001-kb-kit-v1/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-contracts.md, contracts/skill-contracts.md, quickstart.md

**Tests**: Included where the spec demands them (script golden tests, seeded-defect detection, corpus validation runs per Constitution "Development Workflow" and SC-001…SC-010). No TDD ceremony beyond that.

**Organization**: Grouped by user story; each story phase is an independently testable increment.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup

**Purpose**: Repo skeleton and test fixtures used by everything else

- [X] T001 Create source tree per plan.md: `core/templates/`, `core/packs/`, `core/scripts/`, `adapters/claude/skills/`, `tests/fixtures/`, `specs/001-kb-kit-v1/validation/`
- [X] T002 [P] Author clean fixture base in `tests/fixtures/mini-kb/`: KB.md, INBOX.md, 2 themes with INDEX.md + rules, ~8 nodes exercising every format feature (links, heading/block anchors, evidence citations with quotes+locators, tags, one artifact file referenced by plain link)
- [X] T003 [P] Author defective fixture in `tests/fixtures/mini-kb-defective/`: seeded broken link, broken anchor, broken file-ref, orphan node, index row without file, file without index row, unindexed theme, invalid frontmatter, mirrored flagged pair, blocked INBOX item (one of each, documented in fixture README)

## Phase 2: Foundational (blocking prerequisites)

**Purpose**: Formats and deterministic parsing every story depends on

- [X] T004 [P] Core templates per data-model.md in `core/templates/`: node.md, INDEX.md, KB.md, INBOX.md, theme-rules.md
- [X] T005 Implement `core/scripts/kb-graph.sh`: flat frontmatter parser, `[[link]]`/anchor extraction, plain file-ref extraction, theme membership, adopted-mode nodes (frontmatter-less files, per data-model.md) → graph JSON (zero deps, <5s @ 1000 nodes)
- [X] T006 Golden test `tests/test_kb_graph.sh` over mini-kb (committed expected JSON; broken-flag assertions over mini-kb-defective)
- [X] T007 Implement `core/scripts/kb-check.sh`: all finding types per cli-contracts.md (broken-link, broken-anchor, broken-file-ref, orphan-node, index-missing-row, index-stale-row, unindexed-theme, frontmatter-invalid, flagged-node, inbox-blocked), `--json`, safe_fix marking, style-agnostic index parsing (bullet + table rows)
- [X] T008 Test `tests/test_kb_check.sh`: 100% detection of every seeded defect in mini-kb-defective (SC-006), zero findings on mini-kb

**Checkpoint**: mechanical layer trustworthy — all user stories can build on it

## Phase 3: User Story 1 — File a fact with one command (P1) 🎯 MVP

- [X] T009 [US1] Author `adapters/claude/skills/kb-add/SKILL.md` per skill-contracts.md: staged classification (KB.md → theme index → rules), ask-don't-guess on ambiguity, FR-006 conflict policy (complement=apply, contradiction=quote both & wait), multi-fact split with veto, evidence-citation authoring (link+quote+locator), INBOX queue processing with status updates, `--from-session` mode with confirmation list (FR-016), same-operation index update, full touched-files report. **ITERATIVE — product core: draft → fixture run → revise, expect multiple passes**
- [X] T010 [P] [US1] Second-opinion hook: protocol doc + example script `core/templates/hooks/second-opinion.example` (stdin JSON → stdout opinion, per cli-contracts.md); invocation + absent-silent behavior wired into kb-add SKILL.md
- [X] T011 [US1] Validation run on a copy of mini-kb: 5 varied raw inputs (clear fact, two-theme ambiguity, contradiction, multi-fact transcript, INBOX batch) → record vs acceptance scenarios in `specs/001-kb-kit-v1/validation/us1.md`; then `kb-check.sh` must report clean (SC-001, SC-005 rehearsal)

**Checkpoint**: filing works — the base can grow with discipline

## Phase 4: User Story 2 — Ask the base (P2)

- [X] T012 [US2] Author `adapters/claude/skills/kb-ask/SKILL.md` per skill-contracts.md: staged reading (root → theme indexes → selected bodies, ≤10% content), per-claim citations quoting supporting lines, disputed/superseded warnings from flags, honest can't-answer with nearest nodes. **ITERATIVE — product core: draft → benchmark run → revise**
- [X] T013 [US2] Benchmark `specs/001-kb-kit-v1/validation/ask-benchmark.md`: 10 questions spanning 2–3 nodes/themes over mini-kb + fresh-session run protocol; execute and record (SC-002, SC-008, SC-009)

**Checkpoint**: MVP complete — add + ask deliver the core value loop

## Phase 5: User Story 3 — Install & migrate (P3)

- [X] T014 [US3] Implement `kb-init.sh` scaffold mode + `--update` + `--json` + `.kb/config` per cli-contracts.md (copies core→`.kb/`, adapters→`.claude/skills/`; idempotent; `--update` never touches KB_DIR content)
- [X] T015 [US3] Implement `kb-init.sh --migrate <dir>` (mechanical inventory → MIGRATION_REPORT.md: candidate themes, index-like files, naming patterns, frontmatter presence, non-md artifacts) and `--apply-migration <report>` (adds rules/index adoptions only; never moves/renames/rewrites content)
- [X] T016 [US3] Test `tests/test_kb_init.sh`: scaffold on empty tmp repo, re-run idempotency, `--update` content-untouched assertion, `--migrate` writes only the report
- [X] T017 [US3] Author `adapters/claude/skills/kb-init/SKILL.md`: read report + corpus READMEs → draft per-theme rules capturing corpus conventions → present full plan → apply on confirmation; ambiguity reported not normalized
- [X] T018 [P] [US3] Author `adapters/claude/theme-CLAUDE.md.tmpl` (thin wrapper including theme rules into Claude's native nested-context mechanism)

**Checkpoint**: kb-kit installable anywhere, including over existing corpora

## Phase 6: User Story 4 — Hygiene (P4)

- [X] T019 [US4] Author `adapters/claude/skills/kb-check/SKILL.md`: run `kb-check.sh --json`, auto-apply safe_fix findings with per-fix listing, propose destructive resolutions with evidence, clean-bill behavior with zero writes
- [X] T020 [US4] Validation on a copy of mini-kb-defective: safe fixes applied, destructive only proposed; record in `specs/001-kb-kit-v1/validation/us4.md`

## Phase 7: User Story 5 — Visualize (P5)

- [X] T021 [US5] Author `core/scripts/viz-template.html`: self-contained vanilla-JS canvas force-graph (~250 LOC) — pan/zoom, hover details (name/description/theme), click-highlight neighbors, text search, theme colors, visual style for flagged nodes; `/*__KB_GRAPH_DATA__*/` placeholder
- [X] T022 [US5] Implement `core/scripts/kb-viz.sh`: kb-graph.sh → inject JSON → single `kb-graph.html`
- [X] T023 [US5] Test `tests/test_kb_viz.sh`: output is one file, zero `http` references (offline guarantee), embedded node/edge counts match graph JSON (SC-007)

## Phase 8: User Story 6 — Packs (P6)

- [X] T024 [P] [US6] Author built-in pack `core/packs/sources/`: pack.conf, rules.md (source-library discipline: file naming with dates, card structure with TL;DR + quotes with timecodes, evidence-citation format), templates/source-card.md, checks.conf (required frontmatter per type)
- [X] T025 [US6] Implement `kb-init.sh --pack <name|path>` with theme-slug collision handling (surface, never overwrite) + extend `tests/test_kb_init.sh`

## Phase 9: User Story 7 — Semantic audit (P7)

- [X] T026 [US7] Author `adapters/claude/skills/kb-audit/SKILL.md` per skill-contracts.md: mechanical candidate pairs from kb-graph.sh output (shared tags / link neighborhoods / same theme / description token overlap), shortlist body reads only, findings report node with quoted evidence from both sides, per-finding confirmation → mirrored flags (`disputed=`, `duplicate-of=`, `superseded-by=`/`supersedes=`) or proposed links, merge preview before any merge. **ITERATIVE — judgment quality tuned against seeded fixtures**
- [X] T027 [US7] Extend fixtures with 10 semantic defects (contradicting pairs, near-duplicates, superseded facts) + validation run → `specs/001-kb-kit-v1/validation/us7.md` (SC-010: ≥8 surfaced, zero unconfirmed changes)

## Phase 10: Polish & real-corpus validation

- [ ] T028 Cross-skill consistency review: flags warnings in kb-ask, flagged-node listing in kb-check, evidence-citation format identical across kb-add/kb-ask/pack templates (one pass over all SKILL.md files)
- [ ] T029 Corpus validation №1 — private corpus A (research docs) (copy): full migration flow (US3), then one /kb-add and one /kb-ask on the migrated base → `specs/001-kb-kit-v1/validation/corpus-a-docs.md` (SC-003)
- [ ] T030 Corpus validation №2 — private corpus B (sales CRM) (copy, 174 cards): kb-check must independently rediscover the documented reconciliation-note drift class → `specs/001-kb-kit-v1/validation/corpus-b-crm.md` (SC-006 real-world)
- [ ] T031 Corpus validation №3 — private corpus C (client intake) (copy, ~240 heterogeneous files): /kb-add files 5 raw items incl. call-transcript quotes as evidence citations; non-md artifacts linked, not nodified → `specs/001-kb-kit-v1/validation/corpus-c-intake.md` (SC-001, SC-005, SC-009 real-world)
- [ ] T032 [P] Verify quickstart.md end-to-end on a clean tmp repo (SC-004: nothing running, git+agent only); fix README install section to real paths and sweep README for overclaiming (verb tense honest vs shipped state)
- [ ] T033 [P] Bootstrap public changelog `CHANGELOG.md` (v0.1 notes) per distribution-first strategy
- [ ] T034 [P] Add `LICENSE` (MIT) + attribution note in README credits (launch blocker for OSS distribution)

## Dependencies & execution order

- **Phase 1 → Phase 2** strictly (fixtures/templates before scripts/tests).
- **Phase 2 blocks all stories** (T005/T007 are the mechanical layer; T004 formats).
- **US1 (Ph3) → US2 (Ph4)**: ask consumes what add produces (benchmark base needs filed nodes).
- **US3 (Ph5)** independent of US1/US2 after Phase 2; required by Phase 10 corpus runs.
- **US4 (Ph6)** needs T007; **US5 (Ph7)** needs T005; **US6 (Ph8)** needs T014; **US7 (Ph9)** needs T005+T007.
- **Phase 10** needs the stories it validates (T029→US3; T030→US4; T031→US1).

**Parallel opportunities**: T002‖T003‖T004; after Phase 2: skill authoring T009‖T018‖T021‖T024 (different files); within stories: T010‖T009 partially, T032‖T033.

## Implementation strategy

**MVP = Phases 1–4** (foundational + US1 + US2): a base that grows by command and answers with citations — the core value loop, dogfoodable immediately on the kb-kit repo itself.

**Launch gates** (distribution-first: release early, release often):

- **v0.1 — public launch after Phase 5** (MVP + install/migrate + LICENSE/CHANGELOG/README subset of Phase 10: T032–T034, plus corpus validation T029): the smallest thing a stranger can install. Do NOT wait for US4–US7.
- **v0.2** — US4 (check) + US5 (viz): second launch announcement.
- **v0.3** — US6 (packs) + US7 (audit) + remaining corpus validations: third announcement.
- **Feature 002 (next spec, post-v0.1): product-development pack** — the flagship vertical module on top of the pack mechanism: CX/customer-journey disciplines, product-management best practices for new and existing products. Out of scope for 001 by decision (scope-growth stop procedure); the pack mechanism (US6) is its foundation.

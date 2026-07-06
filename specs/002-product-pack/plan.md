# Implementation Plan: 002 — product-development mask

**Branch**: `002-product-pack` | **Date**: 2026-07-06 | **Spec**: [spec.md](spec.md)

## Summary

Two layers. **Engine increment**: mask format v2 — multi-theme masks
(manifest `THEMES=` + per-theme subdirs), per-theme collision handling in
`kb-init --mask`, and mechanical enforcement of mask invariants
(`.kb-checks.conf` per theme → new `mask-invariant` finding in `kb-check.sh`).
**Content**: the product-development mask itself — five themes (insights,
journeys, hypotheses, decisions, segments), each with opinionated rules
(Mom-Test evidence discipline, CJM-as-graph, falsifiable hypotheses,
ADR-light decisions) and node templates. Scope guard per user review: metrics/
OKR/analytics couplings belong to a future `product-management-pro` mask.

## Technical Context

Unchanged from 001 (bash+awk zero-dep scripts, markdown content, fixtures+
golden tests). New surface: 2 TSV NODE fields, 1 finding type, mask manifest v2.

## Constitution Check (v1.0.1)

- I–IV: untouched — masks deliver templates/rules; node/index/link formats unchanged. PASS
- V Zero infra: checks enforcement is flat-file parsing in existing scripts. PASS
- Mask as first-class unit: this feature IS that principle, extended to multi-theme. PASS
- LLM/deterministic split: `mask-invariant` checks are mechanical (required
  frontmatter keys / required section headings per type); judgment calls
  (is the hypothesis actually falsifiable?) stay in /kb-audit. PASS

## Design decisions

- **D1. Manifest v2**: `mask.conf` gains `THEMES=slug slug …` (space-separated);
  per-theme content in `themes/<slug>/{rules.md,templates/,checks.conf}`.
  v1 masks (`THEME_SLUG=` + top-level files) keep working — `sources` mask
  unchanged. Rationale: additive, no migration of the built-in mask.
- **D2. Installed checks location**: on install, a theme's `checks.conf` is
  copied to `<KB_DIR>/<theme>/.kb-checks.conf` (dotfile → invisible to the
  graph, travels with the theme, works on fixture bases without `.kb/`).
- **D3. Checks format** (flat, R1-parseable):
  `REQUIRED_FRONTMATTER_<type>=key,key` and
  `REQUIRED_SECTIONS_<type>=Heading|Other Heading` (pipe-separated; matched by
  slugified heading). Enforced by `kb-check.sh` as finding `mask-invariant`.
- **D4. TSV NODE record** gains two appended fields: `fmkeys` (frontmatter keys
  present) and `headslugs` (slugified headings) — appended, so existing field
  indices stay valid.
- **D5. Collision policy (CLI is non-interactive)**: install all free theme
  slots, skip colliding ones, report each collision, exit 1 if any (nothing
  overwritten); the /kb-init skill mediates when the user wants merge/rename.
- **D6. Lifecycles**: hypothesis/decision status = frontmatter `status:` key
  (enforced via REQUIRED_FRONTMATTER); supersession uses existing mirrored
  flags — no new state machinery (FR-105).

## Project structure (delta)

```text
core/masks/product/
├── mask.conf                      # THEMES=insights journeys hypotheses decisions segments
└── themes/<slug>/
    ├── rules.md                   # discipline of the theme
    ├── templates/<type>.md        # node template(s)
    └── checks.conf                # mechanical invariants (optional per theme)
tests/fixtures/mini-kb-masked/     # static fixture: checks + 1 violation + 1 clean node
```

Contracts live in 001 (`cli-contracts.md`) and are updated there; data-model
additions in [data-model.md](data-model.md).

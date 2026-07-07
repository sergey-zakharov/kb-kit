# Changelog

All notable changes to kb-kit. Public from the first commit — that's the point.

## v0.2.1 — 2026-07-07

- **`kb-init --user-skills`** — kb-* commands at user level (~/.claude/skills):
  available in every project, act only where a base exists. Fixes "/kb-add: no
  commands match" when working outside an installed repo.

## v0.2.0 — 2026-07-06

- **Product-development mask** — the first full kit-mask: 5 themes (insights
  with mandatory Mom-Test evidence, journeys as part of the graph, falsifiable
  hypotheses, ADR-light decisions on mirrored flags, evidence-defined
  segments), for discovery AND running products. Metrics/OKR deferred to a
  future product-management-pro mask.
- **Mask format v2** — multi-theme masks (THEMES= manifest, per-theme
  rules/templates/checks); per-theme collision handling (skip+report, nothing
  overwritten); v1 masks unchanged.
- **Invariant enforcement** — `.kb-checks.conf` per theme; `kb-check` gains
  finding `mask-invariant` (required frontmatter keys / required sections per
  node type, mechanical only, adopted nodes exempt).

## v0.1.2 — 2026-07-06

- **Packs are now masks (kit-masks)** — terminology follows the philosophy: the
  engine is faceless, a mask is what a base wears. `kb-init --mask` (with
  `--pack` kept as a legacy alias), `core/masks/`, `mask.conf`, `.kb/masks/`.
  Constitution v1.0.1. Feature 002 (product-development mask) spec drafted.

## v0.1.1 — 2026-07-06

- **`kb-init --hooks`** — the base watches itself, still zero-infra: git
  pre-commit hygiene check (warn-only, `KB_PRECOMMIT_STRICT=1` to block),
  Claude Code SessionStart status line + PostToolUse per-edit hygiene feedback
  to the agent, GitHub Action template staged (activation is the user's call).
  Never clobbers existing hooks or settings. Filing stays curated — automation
  watches hygiene, never captures content.

## v0.1.0 — 2026-07-06

Hardened by two live-corpus shakedowns on top of the rc line:

- **Memory bridge**: `EXTERNAL_BASE_<name>` config — unresolved `[[slug]]` links
  resolve into external bases (e.g. the agent's auto-memory); explicit
  `[[name:slug]]` syntax; soft `external-base-unreachable` finding; external
  links are read-only for /kb-ask and excluded from viz. Live effect on a real
  CRM corpus: 191 → 49 broken links (142 resolved into a 130-node memory base).
- **New findings**: `slug-collision` (duplicate basenames no longer lie
  silently), `theme-index-missing` (planned themes named instead of noise).
- **Scope & parsing hardening**: default base from `.kb/config` (no accidental
  cwd scans), git-first file enumeration (respects .gitignore), fenced code
  blocks and inline code spans excluded from parsing, slug-shaped wikilink
  validation, `#fragment` stripped from fileref checks, non-ASCII filenames
  (git quotepath) fixed.
- **Installer**: `--uninstall` (toolkit out, knowledge untouched), `--update`
  preserves custom config lines, version stamped from `git describe`,
  `--apply-migration` scaffolds INBOX.md; LF enforced via `.gitattributes`.

## v1 baseline

First working version. The engine:

- **Node format**: one markdown file = one fact; flat frontmatter (`name`,
  `description`, `type`, `tags`, `flags`); `[[wikilinks]]` with heading and
  `^block` anchors; evidence citations `[[source#^id]]: "quote" (locator)`.
- **/kb-add** — curated filing: staged classification, ask-don't-guess,
  conflict gate (complement applies, contradiction stops), multi-fact split,
  INBOX queue, from-session extraction, optional second-opinion hook.
- **/kb-ask** — staged retrieval (indexes → selected bodies) with verbatim
  quote citations and honest "the base can't answer". Fresh-agent benchmark:
  11/11, quotes 15/15 verbatim.
- **/kb-check** — mechanical hygiene via zero-dependency bash: broken
  links/anchors/file-refs, index drift both ways, orphans, invalid frontmatter,
  open flags. Safe fixes auto-applied, everything else propose-only. 10/10
  seeded defects detected.
- **/kb-audit** — semantic scan: contradictions, duplicates, superseded facts,
  missing links; quoted evidence from both sides; mirrored consistency marks
  after per-finding confirmation. Seeded run: 9/10 + 2 legitimate bonus findings.
- **/kb-viz** — one self-contained offline HTML: canvas force-graph, search,
  neighbor highlight, theme colors, adopted/flagged/broken styling.
- **kb-init** — install in one command; migration over an existing corpus is
  report-first and adds files only (0 moved/renamed/rewritten); adopted
  (frontmatter-less) files join the graph in degraded mode and upgrade on first
  touch.
- **Packs** — a theme-in-a-box (rules + templates + invariants); built-in
  `sources` pack; collision-safe install.
- 70+ test assertions across 4 zero-dependency suites; two fixture bases
  (clean + 10 seeded structural defects + 10 seeded semantic defects).

Origin: the pattern ran manually for months on a real product corpus (including
a 174-card sales CRM). kb-kit is that hand discipline, packaged.

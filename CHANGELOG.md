# Changelog

All notable changes to kb-kit. Public from the first commit — that's the point.

## [Unreleased → v0.1]

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

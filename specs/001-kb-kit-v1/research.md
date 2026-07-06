# Research: kb-kit v1

**Feature**: 001-kb-kit-v1 | **Date**: 2026-07-06

All Technical Context unknowns resolved. Decisions below follow the format: Decision / Rationale / Alternatives considered.

## R1. Frontmatter parsing without dependencies

- **Decision**: Constrain node frontmatter to flat `key: value` lines (no nesting, no YAML lists; `tags` is a comma-separated scalar). Parse with `awk` between `---` fences.
- **Rationale**: Full YAML needs `yq`/python — violates zero-dependency. A flat subset is trivially parseable, sufficient for `name`/`description`/`type`/`tags`/`flags`, and matches the Claude Code auto-memory format that inspired the node shape.
- **Alternatives**: `yq` (external dep — rejected); python's yaml (runtime dep — rejected); JSON frontmatter (hostile to hand-editing — rejected).

## R2. Index–folder drift detection

- **Decision**: `kb-check.sh` extracts markdown file references (`](file.md)` and `[[name]]` resolved to files) from each index with grep/sed, lists `*.md` in the folder (excluding INDEX/CLAUDE/KB/INBOX reserved names), and set-diffs both directions. Index *style* is not enforced: canonical bullet rows and adopted table rows (some migrated corpora use tables) both parse, because detection keys on file references, not layout.
- **Rationale**: Style-agnostic parsing is what makes "corpus conventions win" (FR-011) compatible with mechanical checking (FR-009).
- **Alternatives**: enforce one canonical row format everywhere (breaks adopted corpora — rejected); LLM-based index reading (violates deterministic-mechanics split — rejected).

## R3. Visualization engine

- **Decision**: Hand-rolled force-directed layout on `<canvas>` in vanilla JS (~250 lines), embedded in `viz-template.html`; `kb-viz.sh` injects graph JSON into a placeholder. Single output file, zero network access. Pan/zoom, hover details (name/description/theme), click-to-highlight neighbors, text search, color by theme.
- **Rationale**: ≤1000 nodes is comfortably within naive O(n²)-per-tick simulation with early cooling; vendoring d3 (~90 KB) buys polish we don't need at the cost of auditability of a single readable file.
- **Alternatives**: d3-force inlined (acceptable fallback if interaction demands grow; deferred); Mermaid (unreadable beyond ~50 nodes — rejected); Obsidian dependency (explicitly rejected by product decision).

## R4. Pack format

- **Decision**: A pack is a directory: `pack.conf` (flat KEY=VALUE manifest: NAME, DESCRIPTION, THEME_SLUG, VERSION), `rules.md` (theme rules delivered by the pack), `templates/*.md` (node templates), optional `checks.conf` (extra hygiene invariants as simple assertions, e.g., required frontmatter keys per node type). Installed by `kb-init.sh --pack <name|path>` into `.kb/packs/` + materialized as a theme.
- **Rationale**: Flat files keep authoring diff-able and zero-dep; the manifest carries only what install needs. `checks.conf` lets a sales pack demand `status:` on every lead card without code.
- **Alternatives**: YAML/JSON manifests (parsing dep — rejected); packs as git submodules (operational friction — rejected for v1); executable pack install scripts (security surface — rejected for v1).

## R5. Installer distribution model

- **Decision**: `kb-init.sh` mirrors the spec-kit model: copies `core/scripts+templates+packs` → target `.kb/`, `adapters/claude/skills` → target `.claude/skills/`, writes `.kb/config` (KEY=VALUE: `KB_DIR`, `VERSION`). Modes: scaffold (empty dir), `--migrate <dir>` (existing corpus), `--update` (refresh toolkit, never touches knowledge), `--pack`. Delivery: clone kb-kit and run, or one-line `curl | bash` later.
- **Rationale**: Installed repos must have zero runtime dependency on the kb-kit repo (portability criterion); the spec-kit model is proven and familiar to the target audience.
- **Alternatives**: npm/pipx packaging (runtime deps + ecosystem lock-in — rejected for v1); template repository on GitHub (doesn't handle migrate/update — rejected as the only path).

## R6. Migration over an existing corpus

- **Decision**: Two phases honoring the LLM/deterministic split. Phase A (mechanical, `kb-init.sh --migrate`): inventory candidate theme dirs, existing index-like files (README/INDEX with file references), naming patterns, frontmatter presence → writes `MIGRATION_REPORT.md`. Phase B (judgment, `/kb-init` skill): reads the report and the corpus's own README conventions, drafts per-theme rules files + adopts existing indexes, presents the diff, applies on confirmation. Content files are never moved, renamed, or rewritten; only new rule/index files are added (and index adoption annotates, not rewrites).
- **Rationale**: Convention *discovery* is judgment work (reading prose READMEs); inventory is mechanics. The reference corpora prove conventions live in READMEs and folder structure.
- **Alternatives**: fully scripted migration (cannot read prose conventions — rejected); fully manual (doesn't scale, defeats the product — rejected).

## R7. Second-opinion hook protocol

- **Decision**: Well-known path `.kb/hooks/second-opinion` (any executable). Contract: candidate classification as JSON on stdin (`{fact, proposed_theme, proposed_node, links}`), plain-text opinion on stdout, exit 0. `/kb-add` invokes it only if present and executable, includes the opinion in its report, and proceeds identically when absent.
- **Rationale**: Fulfills the extension-point constitution constraint with zero built-in model dependencies; a user can wire `codex exec`, a curl to any API, or a static checklist.
- **Alternatives**: built-in multi-model quorum (breaks "works with only git + agent" — rejected, deferred to v2 packs); MCP integration (heavier contract — rejected for v1).

## R8. Fact-level citations (evidence links)

- **Decision**: Three mechanisms, layered. (1) **Anchored links**: `[[name#Heading]]` (markdown heading) and `[[name#^block-id]]` (explicit block anchor `^block-id` at end of line, Obsidian-compatible syntax). (2) **Evidence citation convention** in node bodies: claim + `[[source-node#anchor]]: "verbatim quote" (locator)` — the quote travels with the link, so the citation survives even if anchors move. (3) `/kb-ask` answers must quote the supporting line(s), not just cite files. `kb-check.sh` validates anchored links (heading slug or block id exists in target). In adopted files kb-kit doesn't own, anchor insertion requires confirmation; quote-only citation is the no-edit fallback.
- **Rationale**: Nodes are single-fact, so file-level citation is usually fact-level already; anchors matter for source cards (multi-quote conspects with timecodes) and large adopted files. Quote-first makes citations verifiable by grep and robust to edits; anchors make them navigable. Line numbers were rejected as brittle under edits.
- **Alternatives**: line-number citations (break on every edit — rejected); heading-only anchors (too coarse for quote-level — insufficient alone); duplicating quotes into claim nodes without links (loses navigability — rejected).

## R9. Semantic audit strategy (/kb-audit)

- **Decision**: Staged candidate selection, judgment only on shortlists. Stage 1 (mechanical, existing scripts): candidate pairs from shared tags, mutual link neighborhoods, same theme, and name/description token overlap (`kb-graph.sh` output is sufficient input). Stage 2 (skill): read only candidate bodies; classify pairs as contradiction / duplicate / superseded / should-link; produce `kb/AUDIT_REPORT.md`-style dated report node with quoted evidence. Stage 3 (on confirmation): write consistency marks into frontmatter `flags` (`disputed=<slug>`, `superseded-by=<slug>`, `duplicate-of=<slug>`) on both nodes of a pair. Marks are flat key=value (R1-parseable), so `kb-check` can list all flagged nodes and `/kb-ask` can warn when citing a disputed node.
- **Rationale**: All-pairs body reading is O(n²) in tokens — staged selection keeps audits affordable at 1000 nodes; flags-in-frontmatter makes audit outcomes machine-findable (FR-018) and surface in retrieval.
- **Alternatives**: embeddings-based similarity for candidates (v2 accelerator per constitution — deferred); marks as a separate registry file (drifts from nodes, violates index-mirrors-folder spirit — rejected); auto-resolution of contradictions (violates Principle III — rejected).

## R10. Testing strategy

- **Decision**: Deterministic scripts: bash test harness (`tests/test_*.sh`, plain asserts, no framework) over two fixtures — `mini-kb` (clean, golden outputs committed) and `mini-kb-defective` (seeded: broken links, orphans, two-way drift, bad anchors, flagged pairs). Skills: acceptance scenarios from the spec executed as scripted agent sessions against disposable copies of the three reference corpora — corpus A — research docs (migration over curated conventions), corpus B — 174-card sales CRM (drift detection at scale), corpus C — ~240-file client intake (raw heterogeneous INBOX: filing from mess, evidence citations from call transcripts, non-markdown artifacts, and a decision log already practicing superseded/active statuses — live validation of the consistency-marks model). SC-002/SC-009 verified with a committed 10-question benchmark + 20-claim quote spot-check protocol.
- **Rationale**: Scripts must be regression-tested mechanically; skill quality is only measurable against real-mess corpora — which we uniquely have.
- **Alternatives**: bats framework (dependency — rejected); mocked corpora only (hides real-world mess that motivated the product — rejected as sole approach).

## R11. From-conversation filing mode

- **Decision**: `/kb-add --from-session` (or natural-language equivalent): the skill extracts candidate facts from the current conversation into a numbered list (fact + proposed theme + proposed links), the user strikes/approves, approved items flow through the standard filing pipeline one by one. Never triggered without the command.
- **Rationale**: Reuses the entire classification pipeline; the confirmation list is the curation gate that keeps session extraction aligned with the constitution.
- **Alternatives**: auto-extract at session end (passive capture — constitutionally rejected); separate skill (needless duplication — rejected).

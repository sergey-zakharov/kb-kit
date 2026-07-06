<!--
Sync Impact Report
- Version change: template → 1.0.0 (initial ratification)
- Modified principles: all placeholders filled
- Added sections: Core Principles I–V, Additional Constraints, Development Workflow, Governance
- Removed sections: none
- Templates:
  ✅ .specify/templates/plan-template.md — Constitution Check gate derives gates from this file at plan time; no edits needed
  ✅ .specify/templates/spec-template.md — no constitution-specific mandatory sections introduced
  ✅ .specify/templates/tasks-template.md — no new principle-driven task types beyond defaults
- Follow-up TODOs: none
-->

# kb-kit Constitution

## Core Principles

### I. One Node, One Fact
Every node is a single markdown file holding exactly one fact, card, or digest.
Frontmatter MUST contain `name` (slug), `description` (one line sufficient to judge
relevance without reading the body), `type`, and `tags`. Relations are expressed as
`[[name]]` wikilinks in the body. Rationale: single-fact granularity is what makes
indexes meaningful, links precise, and git diffs reviewable.

### II. The Index Mirrors the Folder
Every theme folder MUST have an `INDEX.md` with one line per node (name, hook, link).
Any operation that creates, renames, or removes a node MUST update the index in the
same change set. Index drift is a defect; `/kb-check` MUST detect it mechanically.
Rationale: the index is the first — often the only — thing an agent reads; a stale
index silently corrupts every downstream answer.

### III. Nothing Is Deleted Silently
No node, index entry, or link may be removed or overwritten without an explicit,
visible decision: either the user confirms, or the change lands as a reviewable git
commit stating what was removed and why. A new fact contradicting an existing node
MUST be surfaced as a conflict, never resolved by silent overwrite. Rationale: a
knowledge base is trusted exactly as much as its deletions are accountable.

### IV. Two-Stage Retrieval: Index → Body
Answering from the base MUST load indexes first and node bodies selectively —
selection over compression. Node bodies are never lossily summarized at read time;
context economy comes from curated one-line descriptions written at add time.
Rationale: selective loading of exact text scales with the corpus at zero
information loss.

### V. Zero Infrastructure
The system MUST work on any machine with git and a supported agent CLI, with
nothing running in the background: no server, no database, no daemon, no embedding
service. Deterministic helpers are dependency-free scripts; git is the only storage
engine (versioning, diff/review, clone as export/import). Any future accelerator
(e.g., an embedding cache) MUST be a disposable derived artifact, rebuildable from
the files — never a source of truth.

## Additional Constraints

- **Curated, not captured**: facts enter the base by explicit command; no passive
  logging of conversations. Ambiguity is escalated to the user (ask-don't-guess).
- **LLM/deterministic split**: judgment (classification, answer synthesis, repair
  decisions) belongs to skills; mechanics (link parsing, drift detection, viz
  generation, scaffolding) belongs to zero-dependency scripts.
- **Agent-neutral core**: the graph (nodes, indexes, links) contains nothing
  agent-specific; agent adapters (skills, `CLAUDE.md`) are thin and replaceable.
- **Mask (kit-mask) as a first-class unit**: a packaged identity = node templates + theme rules +
  check invariants + skill extensions, installable as one unit. The engine is faceless; masks are what a base wears — several can coexist on one graph.
- **Migration respects the corpus**: `kb-init` over an existing corpus MUST NOT
  move or rename files; it formalizes the corpus's own conventions into theme
  rules, applying kb-kit defaults only where nothing exists.
- **Language convention**: slugs and frontmatter keys in English; node bodies in
  the user's working language.
- **Extension point over built-in complexity**: optional capabilities (e.g., a
  second-opinion model call during classification) hook in via well-known script
  paths and degrade silently when absent.

## Development Workflow

- Features are developed spec-first with spec-kit: spec → plan → tasks → implement.
- Every capability MUST be validated against the live test corpora before release:
  private reference corpora: a research-docs graph and a sales CRM corpus (170+ cards with documented
  index drift as the reference failure mode).
- Phase-1 distribution: the engine and first packs are free and open source;
  frequent releases, each publicly announced; public changelog from the first
  commit.

## Governance

This constitution supersedes other practices in this repository. Amendments are
made by a PR that updates this file, states the rationale, and bumps the version
(semver: MAJOR = principle removed or redefined; MINOR = principle/section added or
materially expanded; PATCH = clarification). The plan-phase Constitution Check MUST
gate designs against Principles I–V; a violation requires explicit justification in
the plan's Complexity Tracking section or a redesign.

**Version**: 1.0.1 | **Ratified**: 2026-07-06 | **Last Amended**: 2026-07-06

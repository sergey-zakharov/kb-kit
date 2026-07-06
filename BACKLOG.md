# Backlog — design candidates beyond v1

Scope-growth stop procedure: new ideas land here with context, not in the v1 spec.

## Memory bridge: repo base ↔ agent auto-memory (from live-corpus run, 2026-07-06)

Observed in the wild: a real sales corpus contains ~50 `[[wikilinks]]` targeting
nodes of the agent's auto-memory (`~/.claude/projects/*/memory/`) — outside the
repository. The manual practice invented a cross-base bridge before kb-kit had
one. Design candidate:

- `EXTERNAL_BASES` map in `.kb/config` (name → path), e.g. `mem=~/.claude/.../memory`;
- link syntax `[[mem:slug]]` (or resolution order: local base → external bases);
- `kb-check` validates cross-base targets when the external base is reachable,
  reports `external-base-unreachable` otherwise (not an error on other machines);
- `/kb-ask` may follow external links read-only; `/kb-add` never writes there.
- Privacy note: external bases may be personal — viz/exports must exclude them
  by default.

Fits the pack/extension philosophy; candidate for v1.1 (mechanics are small)
or alongside feature 002.

## Also queued

- **Feature 002: product-development pack** (flagship vertical: CX/customer
  journey, PM best practices for new and existing products) — decided, next
  spec after v0.1 launch.
- ~~Memory bridge~~ — SHIPPED in v0.1.0 полностью: EXTERNAL_BASE_* resolution, explicit [[name:slug]], external-base-unreachable soft finding, read-only follow in kb-ask, viz exclusion.
- ~~fileref #anchor strip~~ — SHIPPED in v0.1.0.
- ~~Inline code spans~~ — SHIPPED in v0.1.0 (excluded from link/fileref parsing).
- Registry / community packs; Codex adapter (AGENTS.md); embeddings as derived
  cache — per roadmap.

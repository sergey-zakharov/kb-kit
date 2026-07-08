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

- ~~Feature 002: product-development mask~~ — SHIPPED v0.2.0; open remainder: T209 live validation on a real corpus.
- **[X]Ops mask map** (positioning decided 2026-07-08): each X = a mask anchored to ONE proven method — project=Decision log+RAID, research=Atomic Research, eng=ADR/RFC (≠DevOps), data=Data contracts+postmortems, sales=MEDDICC, design=Tokens+critique log, people=Competency matrices. Landing with animated [X]Ops hero rescued to `site/index.html` (Why-pillars: "continues, not understands" / "structure beats hope" / "model-agnostic by design"). Killer positioning line: **tracker = contract, kb = formalized context** (accepted by a peer in a real team discussion).
- **product-management-pro mask** (future): running products — metric trees, OKR, feedback loops; will need «смычки» (couplings to analytics/data sources) — deferred until the integration design is clear.
- ~~Memory bridge~~ — SHIPPED in v0.1.0 полностью: EXTERNAL_BASE_* resolution, explicit [[name:slug]], external-base-unreachable soft finding, read-only follow in kb-ask, viz exclusion.
- ~~fileref #anchor strip~~ — SHIPPED in v0.1.0.
- ~~Inline code spans~~ — SHIPPED in v0.1.0 (excluded from link/fileref parsing).
- kit-masks registry / community masks; Codex adapter (AGENTS.md); embeddings as derived
  cache — per roadmap.

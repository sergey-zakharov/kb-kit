# Implementation Plan: kb-kit v1 — file-based knowledge graph toolkit

**Branch**: `001-kb-kit-v1` | **Date**: 2026-07-06 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-kb-kit-v1/spec.md`

## Summary

kb-kit v1 packages a proven manual discipline — a markdown knowledge graph (one node = one fact, per-theme indexes, `[[wikilinks]]`, per-theme rules, INBOX queue) — into an installable toolkit for Claude Code: five commands (`/kb-add`, `/kb-ask`, `/kb-check`, `/kb-audit`, `/kb-viz`), an installer (`kb-init`) that also migrates over existing corpora without moving files, and one built-in pack proving the pack mechanism. Citations work at fact granularity (evidence links: `[[node#anchor]]` + verbatim quote + locator), and the semantic audit complements mechanical hygiene by hunting contradictions, duplicates, and staleness. Judgment (classification, answer synthesis, repair decisions) lives in skills executed by the agent; mechanics (link/frontmatter parsing, drift detection, graph extraction, HTML generation, scaffolding) lives in zero-dependency bash scripts. All state is markdown in git; nothing runs in the background.

## Technical Context

**Language/Version**: Bash ≥ 4 (deterministic scripts, installer); Markdown (skills, templates, all knowledge content); vanilla JavaScript + HTML (one self-contained visualization template)

**Primary Dependencies**: none at runtime beyond POSIX coreutils, `grep`/`awk`/`sed`, and `git`; the judgment runtime is Claude Code executing skills (agent-neutral core, Claude adapter in v1)

**Storage**: markdown files in the target repository, versioned by git (no DB, no cache as source of truth)

**Testing**: bash test scripts with fixture corpora and golden outputs for all deterministic scripts; scenario checklists (spec acceptance scenarios) executed against copies of the two reference corpora for skills; SC benchmark question set for retrieval

**Target Platform**: Linux and macOS with git and Claude Code CLI installed

**Project Type**: CLI toolkit + agent skill package (single project)

**Performance Goals**: `kb-check` mechanical scan and graph extraction complete in < 5 s on a 1000-node base; `/kb-ask` reads ≤ 10% of base content for a typical question (SC-008)

**Constraints**: zero external runtime dependencies; generated `kb-graph.html` is one file, fully offline (no CDN, no network requests); no background processes ever; deterministic scripts never invoke an LLM

**Scale/Scope**: bases of tens to ~1000 nodes; deliverables = 6 skills (5 commands + init/migration) + 4 core scripts + installer + viz template + 1 built-in pack + test suite

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate (Constitution v1.0.0) | Status | How the design satisfies it |
|---|---|---|
| I. One Node, One Fact | PASS | Node template enforces frontmatter (`name`, `description`, `type`, `tags`); `/kb-add` checklist requires single-fact granularity and splits multi-fact input (spec edge case) |
| II. The Index Mirrors the Folder | PASS | `/kb-add` writes node + index row in the same operation (FR-005); `kb-check.sh` mechanically diffs index references against directory contents in both directions (FR-009) |
| III. Nothing Is Deleted Silently | PASS | Deterministic scripts are read-only (they report; they never delete); destructive fixes in `/kb-check` and overwrites in `/kb-add` require explicit confirmation (FR-006, FR-009); conflicts quoted to the user |
| IV. Two-Stage Retrieval: Index → Body | PASS | `/kb-ask` skill mandates staged reading (root index → theme indexes → selected bodies) and forbids corpus-wide reads (FR-008); descriptions written at add time |
| V. Zero Infrastructure | PASS | bash + git only; viz output is a static file; second-opinion hook is an optional local script; no services, no DB; any future cache would be derived and rebuildable |
| Curated, not captured | PASS | Filing only by command; from-conversation mode is explicit and confirm-before-write (FR-016) |
| LLM/deterministic split | PASS | Split is structural: `core/scripts/` (mechanics) vs `adapters/claude/skills/` (judgment) |
| Agent-neutral core | PASS | `core/` contains nothing Claude-specific; the Claude adapter is a separable directory (FR-013) |
| Pack as first-class unit | PASS | `core/packs/<name>/` layout + installer support + one built-in pack (FR-012) |
| Migration respects the corpus | PASS | Two-phase migration: mechanical discovery report, then agent-guided formalization; content files never moved/renamed (FR-011) |

**Post-Phase-1 re-check**: PASS — no design element introduces servers, databases, hidden deletion paths, or agent-specific knowledge content. Complexity Tracking is empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-kb-kit-v1/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   ├── cli-contracts.md
│   └── skill-contracts.md
└── tasks.md             # Phase 2 output (/speckit-tasks — not created by plan)
```

### Source Code (repository root)

```text
core/                          # agent-neutral: no mention of any specific agent
├── templates/
│   ├── node.md                # node skeleton with frontmatter
│   ├── INDEX.md               # theme index skeleton
│   ├── KB.md                  # root index skeleton
│   ├── INBOX.md               # queue skeleton
│   └── theme-rules.md         # per-theme rules skeleton (agent-neutral content)
├── packs/
│   └── sources/               # built-in pack: source-library discipline (proves FR-012)
│       ├── pack.conf          # KEY=VALUE manifest
│       ├── rules.md           # theme rules delivered by the pack
│       ├── templates/         # node templates (e.g., source-card.md)
│       └── checks.conf        # extra hygiene invariants for kb-check
└── scripts/
    ├── kb-graph.sh            # nodes + [[links]] + frontmatter → graph JSON on stdout
    ├── kb-check.sh            # mechanical findings: broken links, orphans, drift → report/JSON
    ├── kb-viz.sh              # graph JSON + viz-template.html → kb-graph.html
    └── viz-template.html      # self-contained canvas force-graph, JSON placeholder

adapters/
└── claude/
    ├── skills/
    │   ├── kb-add/SKILL.md    # filing: classify → write node+index+links → report; hooks
    │   ├── kb-ask/SKILL.md    # staged retrieval with file citations
    │   ├── kb-check/SKILL.md  # runs script, judges findings, applies safe fixes
    │   ├── kb-audit/SKILL.md  # semantic scan: contradictions, duplicates, staleness → marks
    │   ├── kb-init/SKILL.md   # drives installer for migration (convention discovery)
    │   └── kb-viz/SKILL.md    # runs scripts, reports output location
    └── theme-CLAUDE.md.tmpl   # thin wrapper: includes theme rules into Claude's native mechanism

kb-init.sh                     # installer: scaffold | migrate | update | pack install

tests/
├── fixtures/
│   ├── mini-kb/               # small clean base (golden state)
│   └── mini-kb-defective/     # seeded defects: broken links, orphans, drift (for SC-006)
├── test_kb_graph.sh
├── test_kb_check.sh
├── test_kb_viz.sh
└── test_kb_init.sh

README.md
```

**Installed layout in a target repository** (produced by `kb-init.sh`, mirrors the spec-kit model):

```text
target-repo/
├── .claude/skills/kb-*/       # copied from adapters/claude/skills
├── .kb/                       # toolkit runtime (like .specify/)
│   ├── config                 # KEY=VALUE: KB_DIR, etc.
│   ├── scripts/               # copied core scripts
│   ├── templates/             # copied core templates
│   ├── packs/                 # installed packs
│   └── hooks/                 # optional user hooks (second-opinion)
└── kb/                        # or an existing docs dir chosen at install (KB_DIR)
    ├── KB.md
    ├── INBOX.md
    └── <theme>/
        ├── CLAUDE.md          # generated from theme-rules + adapter wrapper
        ├── INDEX.md
        └── <node>.md
```

**Structure Decision**: single project. The `core/` vs `adapters/` split is the structural enforcement of the agent-neutral principle: everything under `core/` must remain meaningful for a future Codex adapter; everything Claude-specific lives under `adapters/claude/`. The installer copies both into the target repo (`.kb/` + `.claude/skills/`), so an installed base has no runtime dependency on the kb-kit repo itself.

## Complexity Tracking

No constitution violations; table intentionally empty.

# Data Model: kb-kit v1

**Feature**: 001-kb-kit-v1 | **Date**: 2026-07-06

The "schema" of kb-kit is a set of file formats. Everything below is plain markdown/text, parseable with the flat-format rules from research R1/R2.

## Node

One file = one fact/card/digest. Lives in a theme directory. Filename = `<slug>.md` (slug matches frontmatter `name`).

```markdown
---
name: same-day-ceiling
description: Same-day repairs hit a daily ceiling — busiest Saturday ≈ 12 bikes
type: fact
tags: repairs, capacity
flags:
---

Body in the user's working language. One fact, elaborated.

Evidence citation convention (fact-level reference):
[[2022-05-20-blog-review#^q3]]: "the busiest Saturday we ever had — 12 bikes" (14:20)

Related: [[saturday-peak]], [[rush-fee-policy]]
```

**Frontmatter fields** (flat `key: value` only):

| Field | Required | Format | Purpose |
|---|---|---|---|
| `name` | yes | kebab-case slug, English, unique per base | node identity; `[[name]]` target |
| `description` | yes | one line | relevance decision without reading body |
| `type` | yes | one word (open set; theme rules may constrain: `fact`, `card`, `digest`, `source`, `profile`, …) | filing and pack invariants |
| `tags` | no | comma-separated, English | audit candidate selection, search |
| `flags` | no | comma-separated `key=slug` pairs | consistency marks (see Audit) |

**Validation rules**: frontmatter fences present; `name` matches filename; `description` non-empty single line; no nested YAML.

## Link

- `[[name]]` — reference to a node by slug (resolved within the base).
- `[[name#Heading]]` — anchored to a markdown heading inside the node.
- `[[name#^block-id]]` — anchored to an explicit block anchor: a line ending with ` ^block-id`.
- **Evidence citation** — link + verbatim quote + locator on one line: `[[source#^id]]: "quote" (locator)`. The quote makes the citation grep-verifiable even if the anchor moves.

**Validation rules** (kb-check): link target slug exists; anchor (heading slug or block id) exists in target; links in adopted non-node files are scanned but never auto-edited.

## Theme

A directory under the base root containing nodes + two reserved files:

- `INDEX.md` — the theme index (below).
- `CLAUDE.md` (adapter artifact) — generated from theme rules; agent-neutral source of truth is the rules content itself (from template or pack `rules.md`, or formalized corpus conventions after migration).

Theme identity = directory name (kebab-case slug).

## Index

**Theme index (`INDEX.md`)** — canonical row format (adopted corpora may keep their own style; drift check keys on file references, not layout):

```markdown
# <Theme title> — index

- [same-day-ceiling](same-day-ceiling.md) — daily same-day ceiling; busiest Saturday ≈ 12 bikes
- [saturday-peak](saturday-peak.md) — walk-ins converge on Saturday morning; insider confirms the peak
```

Row = `- [name](file.md) — hook`. One row per node. Reserved files (INDEX, CLAUDE, KB, INBOX, AUDIT_*) are never indexed as nodes.

**Root index (`KB.md`)**:

```markdown
# Knowledge base — <project>

## Themes
- [competitor-flaws/](competitor-flaws/INDEX.md) — competitor pain catalog (C-NNN cards)
- [sources/](sources/INDEX.md) — interviews/articles library, one file per material

## Conventions
- Slugs/frontmatter EN, bodies RU. One node = one fact. Evidence = link + quote + locator.
```

**Invariant** (Constitution II): every node file ↔ exactly one row in its theme index; every theme dir ↔ one row in KB.md.

## INBOX

`INBOX.md` at base root. Item states: pending `- [ ]`, filed `- [x] … → [[node]]`, blocked `- [?] … — question to user`.

```markdown
# INBOX

- [ ] транскрипт подкаста N (added 2026-07-06)
- [x] статья из архива — filed → [[2019-02-04-archive-article]] (2026-07-06)
- [?] заметка про абонемент для курьеров — which theme: product or sales? (2026-07-06)
```

**State transitions**: pending → filed (via /kb-add) | blocked (question recorded) → filed. Items are never deleted, only marked.

## Pack

Directory layout (research R4):

```text
<pack-name>/
├── pack.conf        # NAME=, DESCRIPTION=, THEME_SLUG=, VERSION=
├── rules.md         # theme rules delivered by the pack
├── templates/       # node templates, e.g. source-card.md
└── checks.conf      # optional invariants: REQUIRED_FRONTMATTER_<type>=key,key ...
```

Install materializes a theme from THEME_SLUG + rules + templates and registers checks with hygiene.

## Consistency marks (audit outcomes)

Stored in node frontmatter `flags` as flat pairs, always mirrored on both nodes of a pair:

| Flag | Meaning |
|---|---|
| `disputed=<slug>` | this node contradicts `<slug>`; unresolved |
| `superseded-by=<slug>` / `supersedes=<slug>` | fact replaced by / replaces |
| `duplicate-of=<slug>` | pending merge decision |

Machine-findable by grep; `/kb-ask` must warn when citing a node with `disputed=`/`superseded-by=`; `/kb-check` lists all flagged nodes as open items.

## Config (installed base)

`.kb/config`, flat KEY=VALUE: `KB_DIR=kb` (or adopted docs path), `KB_KIT_VERSION=…`. No other persistent state exists outside markdown + git.

## Graph JSON (derived, ephemeral)

Output of `kb-graph.sh` (input to viz and audit candidate selection); never committed as source of truth:

```json
{
  "nodes": [{"id": "slug", "theme": "dir", "description": "...", "type": "fact", "tags": ["a"], "flags": {"disputed": "other"}}],
  "edges": [{"from": "slug", "to": "slug", "anchor": "^q3|heading|null", "broken": false}]
}
```

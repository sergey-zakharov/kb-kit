# kb-kit

**A knowledge base your AI agent can actually maintain. Just markdown, just git.**

kb-kit turns a folder of markdown files into a disciplined knowledge graph that Claude Code (and other coding agents) can grow, query, and keep tidy — with no server, no database, no background processes. Nothing to deploy, nothing to break: if you have git and an agent, you already have everything.

## The problem

Project knowledge ends up scattered across chats, heads, and loose notes. Your agent forgets everything when the session ends. A plain "docs folder" doesn't fix it, because it lacks two disciplines:

- **Filing discipline** — where does a new fact go? Which existing notes should link to it?
- **Retrieval discipline** — how do you pull the *right* five notes into context, instead of grepping and hoping?

Both disciplines exist today only when a human enforces them by hand, every time. kb-kit packages them into skills and conventions, so they survive any session, any machine, any teammate.

## How it works

Your knowledge base is a graph made of plain files:

- **Node** — one markdown file = one fact/card/digest, with a one-line `description` in frontmatter, so relevance can be judged without reading the body
- **Edges** — `[[wikilinks]]` between nodes
- **Theme** — a folder with its own `INDEX.md` (one line per node) and its own rules (nested `CLAUDE.md`)
- **INBOX** — a queue for raw material awaiting filing

Retrieval is two-stage and token-cheap: the agent reads indexes first, then opens only the node bodies it actually needs. Selection over compression — nothing is lossily summarized, nothing is loaded needlessly.

## Commands

| Command | What it does |
|---|---|
| `/kb-add <raw material>` | Files a fact: picks the theme, creates or updates nodes, updates the index, sets links. Asks when unsure — never guesses silently. |
| `/kb-ask <question>` | Answers from the base with file-level citations — in a fresh session, zero prior context. |
| `/kb-check` | Finds broken links, orphan nodes, and index drift; fixes them or proposes fixes. |
| `/kb-viz` | Generates a self-contained interactive HTML graph of your base. A file, not an app. |
| `kb-init` | Installs into any repo — including *on top of an existing corpus*, without moving a single file. Your conventions win; kb-kit adapts. |

## Principles

1. **One node, one fact.**
2. **The index always mirrors the folder.**
3. **Nothing is deleted silently.**
4. **Retrieval is two-stage: index → body.**
5. **Zero infrastructure.** Everything is git: `git clone` is your export, `git diff` is your review, a PR is how knowledge gets edited.
6. **Curated, not captured.** Facts enter by command, not by passive logging. No noise is created, so no noise needs filtering.

## Status

v1 in active development, spec-driven (see `specs/`). First adopter: a real production corpus — months of product research and a 170+ card sales CRM that ran on this exact pattern, maintained by hand. kb-kit is that hand discipline, packaged.

## Roadmap

- **Packs** — vertical disciplines installed as modules on top of the engine. Flagship: **product development** (CX and customer-journey work, product-management best practices for new and existing products). Also: sales CRM, content pipeline, fundraising
- **Adapters** — agent-neutral core; Codex (`AGENTS.md`) adapter next
- **Registry** — discover and install community packs
- **Embeddings** — optional derived cache for when a base outgrows grep (files stay the source of truth)

## Credits

Distribution model borrowed from GitHub's [spec-kit](https://github.com/github/spec-kit).

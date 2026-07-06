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
| `/kb-audit` | Semantic deep-scan: contradictions, near-duplicates, superseded facts. Approved findings become visible marks on the nodes — inconsistency is either resolved or labeled, never silent. |
| `/kb-viz` | Generates a self-contained interactive HTML graph of your base. A file, not an app. |
| `kb-init` | Installs into any repo — including *on top of an existing corpus*, without moving a single file. Your conventions win; kb-kit adapts. |

## Install

```bash
git clone <this-repo> ~/tools/kb-kit
cd ~/your-project && ~/tools/kb-kit/kb-init.sh          # new base in kb/
# or over an existing docs folder, without touching a single file:
cd ~/your-project && ~/tools/kb-kit/kb-init.sh --migrate docs
```

Requirements: git, bash, and Claude Code. Nothing else — no runtime
dependencies, no daemons, no build step.

## Automation (optional)

The base can watch itself — still zero infrastructure, just native hooks:

```bash
~/tools/kb-kit/kb-init.sh --hooks
```

- **git pre-commit** — hygiene check when a commit touches the base
  (warn-only; `KB_PRECOMMIT_STRICT=1` to block);
- **Claude Code hooks** — every new session opens with a one-line base status
  (findings + INBOX queue), and any node the agent edits is hygiene-checked
  immediately, with findings fed straight back to the agent;
- **CI template** — a ready GitHub Action staged at `.kb/hooks/kb-check.yml`
  (copy to `.github/workflows/` to activate).

Filing stays curated — nothing is captured automatically; the hooks only watch
hygiene and remind. Existing pre-commit hooks and `.claude/settings.json` are
never overwritten.

## Principles

1. **One node, one fact.**
2. **The index always mirrors the folder.**
3. **Nothing is deleted silently.**
4. **Retrieval is two-stage: index → body.**
5. **Zero infrastructure.** Everything is git: `git clone` is your export, `git diff` is your review, a PR is how knowledge gets edited.
6. **Curated, not captured.** Facts enter by command, not by passive logging. No noise is created, so no noise needs filtering.

## Status

v1 in active development, spec-driven (see `specs/`). First adopter: a real production corpus — months of product research and a 170+ card sales CRM that ran on this exact pattern, maintained by hand. kb-kit is that hand discipline, packaged.

## Masks

The engine is deliberately faceless: nodes, indexes, links, discipline. What a
base *is* — a CRM, a product-discovery vault, a research library — is a **mask**
it wears: a **kit-mask** — node templates, theme rules, and hygiene invariants
installed in one command (`kb-init --mask <name>`). Masks coexist on one base (your product knowledge and
your sales pipeline share the same graph and link to each other), and a base
can put on a new mask at any moment — no migration, no export, the same files.

## Roadmap

- **kit-masks** — flagship: **product development** (customer-journey work,
  research insights with evidence, hypothesis and decision discipline — for new
  and existing products). Also: sales CRM, content pipeline, fundraising
- **Adapters** — agent-neutral core; Codex (`AGENTS.md`) adapter next
- **Registry** — discover and install community kit-masks
- **Embeddings** — optional derived cache for when a base outgrows grep (files stay the source of truth)

## Credits

Distribution model borrowed from GitHub's [spec-kit](https://github.com/github/spec-kit).

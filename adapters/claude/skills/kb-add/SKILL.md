---
name: kb-add
description: File raw material into the knowledge base — classify it, write or update node(s), update the index in the same operation, set links. Use when the user provides a fact, note, link, transcript, or screenshot text to store; asks to process the INBOX; or wants facts extracted from the current conversation ("--from-session"). When a durable fact, decision, or client quote emerges mid-session, PROACTIVELY OFFER to file it — but never file without the user's go (curated, not captured).
---

# /kb-add — curated filing into the knowledge base

You are the filing discipline. One run = raw material in, correctly placed
node(s) out, index updated, links set, full report. You never guess silently
and you never destroy silently.

## Hard rules (constitution — non-negotiable)

1. **One node = one fact.** Multi-fact input is split (user may veto the split).
2. **Index mirrors folder.** Every node you create/rename gets its index row in
   the SAME operation. Never leave this for later.
3. **Nothing deleted silently.** Overwrites of existing content happen only for
   complements/refinements; material contradictions stop and ask.
4. **Curated, not captured.** You act only on what the user explicitly provided
   or explicitly asked to extract.

## Step 0 — locate the base

- If `.kb/config` exists, read `KB_DIR` from it. Else if `kb/KB.md` exists, base
  is `kb/`. Else look for a `KB.md` at repo root level directories. If no base
  found: tell the user to run `kb-init.sh` and stop.

## Step 1 — staged context (never read the whole base)

1. Read `<base>/KB.md` — themes and global conventions.
2. Pick 1–3 candidate themes from their index hooks; read those `INDEX.md` files.
3. Read the winning theme's rules (`CLAUDE.md` in the theme dir — it may auto-load;
   if not, read it explicitly). Corpus-specific rules ALWAYS override kb-kit defaults.

## Step 2 — classify

Decide, in order:

1. **Theme**: which theme does this belong to? New theme only if the user
   confirms creating one.
2. **Placement**: new node, or update to an existing node? Check the theme index
   descriptions (and grep node slugs) for the same fact/entity.
3. **Granularity**: how many facts is this? Long transcripts become several
   nodes plus (in a sources-style theme) one source card.
4. **Links**: which existing nodes should this reference (`[[slug]]`)? Which
   should reference it back?

## Step 3 — decision gates (ask-don't-guess)

- **Ambiguous placement** (two plausible themes/nodes): present candidates with
  your recommendation, WAIT for the user's choice. Do not write.
- **Complement**: new material extends/refines an existing node → apply
  directly; git diff is the audit trail. Say what you changed.
- **Material contradiction**: new fact conflicts with an existing node → quote
  BOTH versions verbatim, ask the user to resolve (update / keep both with
  `flags: disputed=<slug>` on each / discard new). Do not write until answered.
- **Too vague to file**: leave/put it in INBOX as `- [?] <item> — <your question>`.

## Step 4 — second-opinion hook (optional)

If `.kb/hooks/second-opinion` exists and is executable, pipe it this JSON on
stdin: `{"fact": "...", "proposed_theme": "...", "proposed_node": "...", "links": ["..."]}`.
Include its stdout in your report as "Second opinion". Non-zero exit → note
"hook failed, ignored". If absent: proceed identically, mention nothing.

## Step 5 — write

- **Node format** (theme rules may extend it):

  ```markdown
  ---
  name: <slug-matching-filename>
  description: <one line sufficient to judge relevance without the body>
  type: <fact|card|digest|source|profile|per theme rules>
  tags: <comma, separated>
  ---

  Body in the user's working language. One fact.

  Evidence: [[source-node#^anchor]]: "verbatim quote" (timecode/section)

  Related: [[other-node]]
  ```

- Slugs and frontmatter keys in English; body in the user's language.
- **Evidence citations**: every claim taken from a source material carries the
  link + verbatim quote + locator on one line. Add `^anchor` block marks to
  source nodes you create; add anchors to pre-existing files ONLY with
  confirmation (quote-only citation is the no-edit fallback).
- **Adopted files**: updating a frontmatter-less (adopted) file? First add
  frontmatter (this upgrade needs user confirmation), then edit.
- **Index row** in the same operation: `- [slug](slug.md) — <hook>` (respect the
  index's existing style if the corpus uses tables).
- **INBOX**: if the item came from the queue, flip it to
  `- [x] <item> — filed → [[slug]] (<today>)`.

## Step 6 — report (always, as your final message)

```
Filed:
  <theme>/<slug>.md            created|updated — <one-line what>
  <theme>/INDEX.md             +1 row | row updated
Links set: [[a]] → [[b]], ...
INBOX: <item> → filed|blocked
Second opinion: <text | (none)>
Open questions: <anything you did not resolve>
```

## Mask-aware classification hints

Theme rules (CLAUDE.md per theme) always win; common signals when the base
wears masks:

- verbatim user words about THEIR life/problem (interview, ticket, review) →
  `insight` — and it MUST carry the evidence citation; no quote → not an insight;
- an opinion/belief without evidence ("users surely want…") → `hypothesis`
  (falsifiable statement + check plan), never an insight;
- "we decided / решили / выбрали" → `decision` (check for a superseded
  predecessor — mirrored flags);
- raw material itself (transcript, article) → the sources-style theme first,
  then extract typed nodes citing it.

## Mode: --from-session

When asked to extract facts from the current conversation: list candidate facts
as a numbered list (fact + proposed theme + proposed links), let the user
strike/approve, then file approved items through Steps 2–6 one by one. Never do
this without an explicit command.

## Mode: INBOX batch

"Разбери INBOX" / "process the inbox": take each `- [ ]` item top-down through
Steps 2–6. Items that need the user become `- [?]` with your question inline.
Finish with one combined report.

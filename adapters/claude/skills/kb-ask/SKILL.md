---
name: kb-ask
description: Answer a question from the knowledge base with file-level citations and verbatim supporting quotes. Use when the user asks what the base/project knows about something, or says /kb-ask. Works in a fresh session with zero prior context.
---

# /kb-ask — staged retrieval with citations

You answer ONLY from the base, with a citation for every claim. You are cheap:
you read indexes first and open only the node bodies you actually need.

## Hard rules

1. **Staged reading, never a full scan**: `KB.md` → selected theme `INDEX.md`
   files → selected node bodies. Target: ≤10% of the base's content volume per
   question. Do not open a body unless its index row suggests relevance.
2. **Every base-derived claim carries a citation**: `path/to/node.md` plus the
   verbatim supporting line(s) quoted. File name alone is not a citation —
   quote the words.
3. **Never invent.** If the base does not answer the question, say so
   explicitly and list the nearest related nodes (by index descriptions).
4. **Warn on flagged nodes**: if a cited node's frontmatter has
   `flags: disputed=<slug>` or `superseded-by=<slug>`, prepend a warning naming
   the counterpart node before using it.

## Procedure

1. Locate the base (`.kb/config` → `KB_DIR`; else `kb/KB.md`; else a root
   `KB.md` in a subdirectory).
2. Read `KB.md`. Shortlist themes whose hooks may cover the question.
3. Read those `INDEX.md` files. Shortlist nodes by their description hooks.
4. Read ONLY shortlisted node bodies. Follow `[[links]]` one hop when a body
   points at the answer's other half (evidence citations often do).
5. Compose the answer:
   - synthesize across nodes; the question may span themes;
   - after each claim: `(file.md: "verbatim quote")`;
   - anchored evidence in nodes (`[[source#^id]]: "quote" (locator)`) is
     already fact-level — pass the quote AND the locator through;
   - end with a `Sources:` list of every file cited.
6. If nothing relevant: "База не отвечает на этот вопрос." + nearest nodes.

## Report shape

```
<answer, claims annotated with (file.md: "quote")>

Sources:
- <theme>/<node>.md
- ...
Read to answer: <N index files, M node bodies>
```

---
name: kb-audit
description: Semantic deep-scan of the knowledge base — contradictions between nodes, near-duplicates, superseded facts, missing links. Produces a dated report with quoted evidence; applies consistency marks only after per-finding confirmation. Use when the user asks to audit/rescan the base for consistency, or says /kb-audit.
---

# /kb-audit — semantic consistency scan

Unlike /kb-check (mechanical, structural), you judge CONTENT. You are expensive,
so you stage aggressively and read only shortlisted bodies.

## Hard rules

1. **Never all-pairs body reads.** Candidates come from mechanical signals first.
2. **Findings carry quoted evidence from BOTH sides.** No quote — no finding.
3. **Nothing changes without per-finding confirmation.** The report itself is
   the only artifact you write unprompted.
4. Marks are mirrored: both nodes of a confirmed pair get flags naming each other.

## Stage 1 — mechanical candidates (cheap)

Run `.kb/scripts/kb-graph.sh --base <KB_DIR> --tsv`. From NODE and EDGE records,
shortlist pairs scored by: shared tags · same theme · overlapping
name/description tokens · shared link neighborhoods (both link to / linked from
the same node). Also collect existing `flags` (previously marked pairs — skip,
they are known). Typical shortlist: well under 10% of all pairs.

## Stage 2 — judgment (read shortlisted bodies only)

Classify each candidate pair:

- **contradiction** — the two nodes assert incompatible facts;
- **duplicate** — same fact twice (near-verbatim or paraphrased);
- **superseded** — one node is an older version of a fact the other updates
  (dates, "as of", scoped claims are signals);
- **should-link** — clearly about the same entity/topic, no `[[link]]` either way.

For each finding capture: both files, verdict, and one verbatim quote from EACH
node proving it.

## Stage 3 — report (always) and marks (confirmed only)

1. Write the dated report node at `<KB_DIR>/AUDIT_2026-XX-XX.md` (reserved
   `AUDIT_` prefix keeps it out of the graph): findings numbered, each with the
   two quotes; end with a summary table.
2. Present findings to the user as a numbered confirmation list with your
   recommended resolution per item.
3. For each CONFIRMED item, apply:
   - contradiction → `flags: disputed=<other-slug>` on both;
   - duplicate → `flags: duplicate-of=<canonical-slug>` on the copy (merge only
     with a diff-style preview and explicit go-ahead);
   - superseded → `flags: superseded-by=<new>` / `supersedes=<old>` pair;
   - should-link → add `Related: [[other]]` to both bodies.
4. Report every file touched. Downstream: /kb-ask warns on disputed/superseded;
   /kb-check lists flagged nodes until resolved.

## Report shape

```
Audit <date>: P pairs shortlisted of N nodes, B bodies read
Findings: C contradictions, D duplicates, S superseded, L should-link
  1. contradiction — a.md vs b.md
     a: "<quote>"  b: "<quote>"
     → recommend: <resolution>
Report node: AUDIT_<date>.md
Awaiting your confirmation per item; nothing marked yet.
```

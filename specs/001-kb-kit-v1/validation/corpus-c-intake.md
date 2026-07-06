# Corpus validation №3: private project-intake corpus (T031, SC-001/005/009 real-world) — 2026-07-06

> **Privacy note**: metrics-only record — no client names, deal figures, or
> quote contents. The corpus is a live client project's raw intake. Copies live
> in gitignored `tests/tmp/`.

**Corpus shape**: ~240 heterogeneous files (~4 GB): call recordings (mp3),
timecoded transcripts, spreadsheets, JSON exports, WhatsApp dumps, proposal
drafts, an ADR-style decision log — the harshest INBOX-like mess of the three
corpora. Bonus branch exercised: target had no git → installer's degraded-safety
warning fired as designed.

## Migration

- `--migrate` + `--apply-migration`: mtime-verified — exactly 2 files added
  (report + KB.md), nothing else touched. ✅

## /kb-add run (fresh agent, zero context, pre-confirmed user decisions)

5 raw inputs filed following the SKILL verbatim:

- **5 nodes created** in a new `facts/` theme + `INDEX.md` (5 rows, same
  operation) + 1 row in KB.md — zero index drift introduced.
- **Evidence citation from a real call transcript** (SC-009): the agent located
  the relevant client line in a 200+-line timecoded transcript, cited it as
  verbatim quote + timecode + plain relative link — and correctly used the
  quote-only fallback (no anchor inserted: adopted files were not confirmed for
  editing). Grep-verified: quote and timecode both match the transcript
  exactly, attributed to the right speaker. ✅
- **Adopted-file protection held**: input #3 complemented an existing analysis
  doc; per pre-confirmed rules the agent found that doc via staged navigation,
  did NOT edit it, and created a linking node instead. Zero existing files
  modified across the whole run. ✅
- **Multi-fact split**: input #4 → 2 nodes. **Vague input** #5 → agent created
  INBOX.md and filed it as `- [?]` with a concrete question (blocked, not
  force-filed). ✅
- **Honesty**: for the 2 facts whose source chat is absent from the corpus,
  the agent recorded "source stated verbally, no file link" in Open questions
  instead of inventing a citation.

## Mechanical delta (SC-005 analog)

`kb-check` before: 59 findings (pre-existing adopted-corpus state).
After: **60 — the single new finding is the intentional inbox-blocked**;
`facts/` contributed **zero** findings. Filing at real-corpus scale introduced
no drift. ✅

**Verdict**: SC-001 (5/5 filed, no manual relocation), SC-005 (clean delta),
SC-009 (verbatim quote + locator from real source) — all pass on the messiest
corpus. Non-md artifacts stayed out of the graph, cited by plain links only.

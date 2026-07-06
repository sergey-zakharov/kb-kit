# Corpus validation №2: private sales CRM corpus (T030, SC-006 real-world) — 2026-07-06

> **Privacy note**: the corpus is a private CRM (real people and companies).
> This record is intentionally **metrics-only**: no names, no paths containing
> names, no business specifics. The detailed findings report was delivered to
> the corpus owner privately. Corpus copies live in `tests/tmp/` (gitignored).

**Corpus shape**: one 767-line index file (de-facto CRM) + 174 card files in
org subfolders + ~50 supporting docs. The corpus's own header documents index
drift: a dated "reconciliation" note admits dozens of cards existed on disk
without index entries, and the counts header lagged by ~6 weeks.

## Setup

- `kb-init.sh --migrate`: git-verified — exactly 1 new file (the report),
  zero content changes. ✅
- Phase B (adds-only): theme `INDEX.md` generated from the 266 unique card
  references found inside the CRM file itself; the CRM file untouched.

## Drift rediscovery (the point of this test)

`kb-check.sh`: **0.98 s** on the full corpus.

- **49 × index-missing-row** — cards on disk referenced nowhere in the CRM
  index. This is exactly the drift class the corpus's own "reconciliation"
  note documented — rediscovered mechanically, each with
  `safe_fix: add-index-row` (one confirmed batch closes all 49). The manual
  process needed a dedicated cleanup session and still left these.
  **SC-006 real-world ✅**
- **4 × index-stale-row** — the CRM index references card files that do not
  exist (including one high-priority pipeline target whose profile was never
  created). Real rot the human pass never caught.
- 283 × broken-file-ref — cards/playbooks referencing artifacts (decks,
  screenshots) at paths that no longer resolve; top-2 offender files account
  for 34 of them. An enumerable hygiene backlog.
- 69 × broken-link, 2 × unindexed-theme — expected on an adopted corpus.

**Verdict**: the tool independently rediscovered the exact failure mode that
motivated kb-kit, on the corpus where it originally happened — plus stale
references the manual discipline missed. Detection cost: ~1 second, repeatable
daily.

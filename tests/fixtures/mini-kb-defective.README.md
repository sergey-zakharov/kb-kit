# Fixture: mini-kb-defective — seeded defects registry

Lives outside the fixture dir so it is not scanned as a node. Expected findings
(exactly these, one line each, for tests/test_kb_check.sh):

| # | Type | File | Detail |
|---|------|------|--------|
| 1 | broken-link | product/repair-ceiling.md | target `nonexistent-node` not found |
| 2 | broken-anchor | product/repair-ceiling.md | `walk-in-slots#^nope` — anchor missing |
| 3 | broken-file-ref | product/repair-ceiling.md | `missing.mp3` does not exist |
| 4 | index-stale-row | product/INDEX.md | row → `deleted-node.md`, file absent |
| 5 | index-missing-row | product/unlinked-unindexed.md | not in INDEX.md; also orphaned; safe_fix=add-index-row |
| 6 | unindexed-theme | stray | theme dir absent from KB.md |
| 7 | frontmatter-invalid | product/bad-frontmatter.md | name mismatch + missing description |
| 8 | flagged-node | product/repair-ceiling.md | disputed=walk-in-slots |
| 9 | flagged-node | product/walk-in-slots.md | disputed=repair-ceiling |
| 10 | inbox-blocked | INBOX.md | `[?]` item awaiting user |

Non-findings by design (exemptions under test):

- `product/old-queue.md` — adopted node (no frontmatter): must appear in graph
  with `adopted=1`, description from its index row, and NOT trigger
  frontmatter-invalid.
- `[[one-source#^q1]]` — valid anchored evidence link for contrast.
- `stray/lonely.md` — indexed inside its own theme; must NOT produce
  index-missing-row (the defect is at theme level, #6).

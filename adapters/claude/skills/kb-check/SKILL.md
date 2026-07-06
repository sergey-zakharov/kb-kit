---
name: kb-check
description: Run mechanical hygiene over the knowledge base — broken links/anchors, orphans, index drift, invalid frontmatter, open flags — then apply safe fixes and propose the rest. Use when the user asks to check/fix the base, or says /kb-check.
---

# /kb-check — hygiene: detect mechanically, fix accountably

## Hard rules

1. Detection is the script's job, not yours: run
   `.kb/scripts/kb-check.sh --base <KB_DIR> --json` and work from its findings.
   Do not re-derive findings by reading the base yourself.
2. **Auto-apply ONLY findings with a non-null `safe_fix`** (currently:
   `add-index-row`). List every applied fix.
3. Everything else (removing stale rows, deleting orphans, retargeting links,
   editing KB.md) is **propose-only**: show the finding with its evidence and
   your recommended resolution; apply individual items only after the user
   confirms them.
4. A clean base gets a clean bill of health and ZERO writes.

## Procedure

1. Locate the base (`.kb/config` → `KB_DIR`).
2. Run the script with `--json`. Exit 0 → report "clean bill of health", stop.
3. Group findings by type. Apply safe fixes:
   - `add-index-row`: append `- [slug](slug.md) — <description from frontmatter>`
     to the theme's INDEX.md (respect its existing row style).
4. For propose-only findings, present a numbered list:
   `<type> — <file> — <detail> → recommended: <action>`. Typical
   recommendations: stale row → remove row; broken link → create stub node,
   retarget, or remove link; broken anchor → fix anchor or fall back to
   quote-only citation; unindexed theme → add row to KB.md; frontmatter-invalid
   → fix fields; flagged-node → point the user to /kb-audit for resolution;
   inbox-blocked → answer the recorded question.
5. Re-run the script after applying anything; show the before → after count.

## Report shape

```
kb-check: N findings (was M)
Auto-applied safe fixes:
  - <file>: <what>
Proposed (awaiting your confirmation):
  1. <type> — <file> — <detail> → <recommendation>
Re-run: <new count> findings remain
```

---
name: kb-init
description: Drive kb-kit installation and, most importantly, migration over an existing corpus — read the mechanical MIGRATION_REPORT.md plus the corpus's own READMEs, formalize ITS conventions into per-theme rules, and apply only after user confirmation. Use when the user wants to install kb-kit, migrate a docs folder, or says /kb-init.
---

# /kb-init — install & migrate (the corpus's conventions win)

## Hard rules

1. **Never move, rename, or rewrite existing content files.** Migration only
   ADDS files (theme rules, adopted indexes, KB.md) — and only after the user
   confirms the plan.
2. **The corpus's conventions are primary.** kb-kit defaults apply only where
   the corpus has no convention of its own.
3. Ambiguous areas are reported to the user, never silently normalized.

## Fresh install (empty repo)

Run `kb-init.sh` (or `kb-init.sh --dir <path>`). Done — point the user to
`/kb-add` for the first fact.

## Migration (existing corpus) — two phases

### Phase A — mechanical (script)

Run `kb-init.sh --migrate <corpus-dir>`. It installs the toolkit and writes
`<corpus>/MIGRATION_REPORT.md`: candidate themes, index-like files, frontmatter
coverage, artifact counts, naming patterns. It changes nothing else.

### Phase B — judgment (you)

1. Read `MIGRATION_REPORT.md`.
2. For each candidate theme, read its README/index-like file and 2–3 sample
   nodes. Extract the LIVED conventions: file naming, card structure, index row
   format, status vocabulary, cross-reference style.
3. Draft, but do not write yet:
   - per-theme rules (from `.kb/templates/theme-rules.md`, filled with THEIR
     conventions, not kb-kit defaults) — to become `<theme>/CLAUDE.md` via
     `.kb/templates/theme-CLAUDE.md.tmpl` wrapper;
   - index adoption notes: existing README/INDEX files are ADOPTED as theme
     indexes as-is (style-agnostic parsing handles tables);
   - the KB.md skeleton (via `kb-init.sh --apply-migration <report>`).
4. Present the full plan: every file that will be ADDED, and explicitly:
   "0 files moved/renamed/rewritten". List ambiguous areas with questions.
5. On confirmation: run `kb-init.sh --apply-migration`, write the theme rules
   files, then run `.kb/scripts/kb-check.sh` and show the initial health report
   (expect adopted-node degraded mode; that is normal, not an error).

## Report shape

```
Installed: .kb/ (scripts, templates, packs), .claude/skills/kb-*
Base: <KB_DIR> (scaffolded | adopted corpus, N themes)
Added files: <list>
Moved/renamed/rewritten: 0
Initial kb-check: <summary>
Open questions: <ambiguities for the user>
```

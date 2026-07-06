# CLI Contracts: kb-kit v1 deterministic scripts

All scripts: bash ≥ 4, zero external dependencies, read-only over knowledge content (they report; skills/users apply changes). Exit 0 = ran clean, 1 = findings present, 2 = usage/environment error. `--json` gives machine output on stdout; default is human-readable.

## kb-init.sh (installer — the only writing script; never touches existing content files)

```text
kb-init.sh [--dir <path>]            # scaffold new base (default: kb/)
           --migrate <corpus-dir>    # phase A: inventory existing corpus → MIGRATION_REPORT.md
           --apply-migration <report># phase B apply (invoked by /kb-init skill after confirmation)
           --mask <name|path>        # put on a mask (kit-mask); --pack = legacy alias
           --update                  # refresh .kb/scripts+templates and .claude/skills only (preserves custom config lines)
           --hooks                   # wire automation: git pre-commit (warn-only; KB_PRECOMMIT_STRICT=1 blocks),
                                     # Claude Code hooks (SessionStart status, PostToolUse hygiene on Write/Edit),
                                     # CI template staged at .kb/hooks/kb-check.yml. Never clobbers existing
                                     # pre-commit or .claude/settings.json (stages a snippet instead).
           --uninstall               # remove .kb/ and .claude/skills/kb-*; knowledge (KB_DIR) untouched
           --json
```

Guarantees: idempotent re-run; `--migrate` writes only the report; `--apply-migration` adds rules/index files, never moves/renames/rewrites content; collision on mask theme slug → exit 1 with finding, no changes.

## kb-graph.sh

```text
kb-graph.sh [--base <dir>] [--json]   # default output: graph JSON (see data-model.md)
```

Parses all nodes: frontmatter (flat), `[[links]]` incl. anchors, theme membership. Marks `broken: true` for unresolvable targets/anchors. Performance: < 5 s at 1000 nodes.

## kb-check.sh

```text
kb-check.sh [--base <dir>] [--json]
```

Finding types (each with file, location, details): `broken-link`, `broken-anchor`, `broken-file-ref` (plain relative link to a non-existent artifact file; `#fragment` is stripped before the existence check), `orphan-node` (no incoming links AND not indexed), `index-missing-row` (file on disk, no index reference), `index-stale-row` (reference without file), `unindexed-theme` (dir absent from KB.md), `theme-index-missing` (KB.md lists a theme whose INDEX.md does not exist yet — planned/unmigrated theme), `frontmatter-invalid`, `flagged-node` (open consistency marks), `inbox-blocked` (items awaiting user), `slug-collision` (duplicate basename across the base: the slug binds to the first file in sorted order, all links resolve there — rename one), `external-base-unreachable` (soft: a configured external base is missing on this machine; its links are left unvalidated).

**External bases (memory bridge)**: `EXTERNAL_BASE_<name>=<abs-path>` lines in `.kb/config` (env override `KB_EXTERNAL_BASES="name=path;…"`). Resolution order for `[[slug]]`: local base → each external base (flat `<path>/<slug>.md`); resolved links get `kind=external`, are never drawn in viz, and are read-only for skills. Explicit form `[[name:slug]]` targets one named base: missing file there → broken; unreachable base → unvalidated (soft finding); unknown name → broken.

**Base resolution & enumeration** (kb-graph/kb-check/kb-viz): with no `--base`, KB_DIR is read from `./.kb/config` (never an accidental whole-cwd scan). Files are enumerated git-first (`git ls-files --cached --others --exclude-standard` — respects .gitignore, so venvs/build dirs stay out; sees new not-yet-committed nodes), falling back to `find` with a prune list for non-git or gitignored bases. Fenced code blocks are excluded from link/anchor/fileref parsing, and wikilink targets must be slug-shaped (kills `[[:<:]]`-style regex noise). JSON schema: `{"findings": [{"type": "...", "file": "...", "detail": "...", "safe_fix": "add-index-row|null"}]}`. Only `safe_fix` entries may be auto-applied by the skill; everything else is propose-only.

**Finding precedence**: a file yields at most one *structural* finding — the most specific type wins (`index-missing-row` over `orphan-node`; a node both unindexed and unlinked is reported once as `index-missing-row` with an "also orphaned" detail). `frontmatter-invalid` is reported independently of structural findings. Adopted nodes (no frontmatter, per data-model.md) are exempt from `frontmatter-invalid`.

## kb-viz.sh

```text
kb-viz.sh [--base <dir>] [--out kb-graph.html]
```

Runs kb-graph.sh, injects JSON into `viz-template.html` placeholder `/*__KB_GRAPH_DATA__*/`, writes a single self-contained HTML file. No network access in output (verifiable: no `http` references in generated file).

## Second-opinion hook (user-provided, optional)

```text
.kb/hooks/second-opinion   # any executable
stdin:  {"fact": "...", "proposed_theme": "...", "proposed_node": "...", "links": ["..."]}
stdout: plain-text opinion
exit:   0 (any other exit → opinion ignored, noted in report)
```

# Data Model: 002 — product-development mask

## Mask manifest v2 (`mask.conf`)

```text
NAME=product
DESCRIPTION=Product development: evidence-backed insights, journeys, hypotheses, decisions
VERSION=0.1.0
THEMES=insights journeys hypotheses decisions segments   # v2: space-separated
# v1 compat: THEME_SLUG=<one> + top-level rules.md/templates/ still supported
```

Per-theme content: `themes/<slug>/{rules.md, templates/*.md, checks.conf}`.
Install copies `checks.conf` → `<KB_DIR>/<slug>/.kb-checks.conf`.

## Checks file (`.kb-checks.conf`, flat)

```text
REQUIRED_FRONTMATTER_hypothesis=name,description,type,status
REQUIRED_SECTIONS_hypothesis=Statement|Check plan|Result
```

Violation → `kb-check` finding `mask-invariant` (propose-only).

## Node types delivered by the product mask

| Theme | type | Required extras | Discipline (rules.md) |
|---|---|---|---|
| insights | `insight` | evidence citation in body; `segment` tag | one observed user fact per node; Mom-Test: facts of the user's life, not opinions about us; no verbatim quote → not an insight (INBOX or hypothesis) |
| journeys | `journey` | sections = stages; stage links `[[insight]]`s | one journey per segment/scenario; every stage claim traces to insights |
| hypotheses | `hypothesis` | `status: pending\|validated\|invalidated`; sections Statement / Check plan / Result | falsifiable statement; a check you can actually run; result recorded, never deleted |
| decisions | `decision` | `status: active\|superseded`; sections Decision / Context / Alternatives / Consequences | ADR-light; supersession via mirrored `supersedes=`/`superseded-by=` flags |
| segments | `segment` | — | who this is about; referenced by insights/journeys |

All five are ordinary nodes (001 format): frontmatter name/description/type/tags,
`[[links]]`, evidence citations. Nothing new in the graph layer.

## TSV NODE record (appended fields)

`NODE id theme relpath adopted fmvalid fmproblem type flags tags description fmkeys headslugs`

- `fmkeys` — comma list of frontmatter keys present (enables REQUIRED_FRONTMATTER checks)
- `headslugs` — comma list of slugified headings (enables REQUIRED_SECTIONS checks)

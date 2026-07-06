# Feature Specification: 002 — product-development mask (the first mask)

**Feature Branch**: `002-product-pack`

**Created**: 2026-07-06

**Status**: Draft

**Input**: User direction: "философия — kb-kit может масочки менять; попробовать это с product-development". The mask must deliver CX/customer-journey work and product-management best practices as a wearable mask over the engine, for BOTH new products (discovery) and existing products (running improvement).

## Why this feature (mask philosophy)

The engine (001) is faceless by design. A **mask** is what makes a base *be*
something: install the product-development mask and the same graph becomes a
product organization's memory — research with evidence, journeys, hypotheses,
decisions. The mask must prove the mask claim: installable over an empty base
AND over a base already wearing other masks (sources, a CRM), coexisting and
cross-linking with them. This feature also hardens the mask mechanism itself:
001 masks deliver exactly one theme; a real mask needs several.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-theme mask install (Priority: P1)

A user runs one command and the base gains the product-development mask: several
themes at once (each with INDEX.md and its own rules), listed in KB.md, ready
for `/kb-add`. Works on a fresh base and on a base with existing themes;
collisions are surfaced per theme, never overwritten.

**Why this priority**: this is the engine-level gap (001 masks = one theme).
Every other story depends on it, and every future mask inherits it.

**Acceptance Scenarios**:

1. **Given** an initialized base, **When** the user installs the product mask,
   **Then** all mask themes appear (dirs + INDEX.md + rules), KB.md gains one
   row per theme, and filing into any of them honors that theme's rules.
2. **Given** a base that already has a theme colliding with ONE mask theme
   slug, **When** installing, **Then** the collision is surfaced with options
   (rename/skip/abort) and non-colliding themes install cleanly only after the
   user decides.
3. **Given** the sources mask is already installed, **When** the product mask
   is installed, **Then** both masks coexist; product nodes cite source cards
   via standard evidence citations.

---

### User Story 2 - Research insights with evidence (Priority: P2)

The user files raw research (interview transcripts, support tickets, reviews)
and gets **insight nodes**: one observed user need/pain per node, every claim
carrying an evidence citation (verbatim quote + locator) into a source. The
rules encode interview discipline (Mom-Test style): facts about the user's
life, not opinions about our product; no evidence — no insight node (goes to
INBOX with a question instead).

**Acceptance Scenarios**:

1. **Given** an interview transcript filed via the sources discipline, **When**
   the user asks to extract insights, **Then** each insight lands as a node
   with `[[source#anchor]]: "quote" (locator)` evidence and appears in the
   insights INDEX.
2. **Given** a claimed insight with no verbatim support in any source, **Then**
   it is not filed as an insight; it becomes an INBOX question or a
   `hypothesis` (explicitly unproven), per the rules.

---

### User Story 3 - Customer journey as part of the graph (Priority: P3)

The user maintains journey maps as markdown nodes: a journey node per
segment/scenario with an explicit stage structure; each stage links to the
insight nodes (pains/gains) observed there. `/kb-ask` can answer "what do we
know about stage X?" with citations, and `/kb-audit` treats journey↔insight
links as first-class (an insight referenced by no journey stage is a candidate
"should-link" finding).

**Acceptance Scenarios**:

1. **Given** a journey node with stages and insight links, **When** asking
   about a stage, **Then** the answer synthesizes the linked insights with
   quotes from their sources (two-hop evidence).
2. **Given** an insight not referenced by any journey, **When** the audit runs,
   **Then** it proposes attaching it to a journey stage (should-link).

---

### User Story 4 - Hypothesis and decision discipline (Priority: P4)

Two more node types with hard rules: **hypothesis** (falsifiable statement →
planned check → result → status: pending/validated/invalidated, statuses via
the flags mechanism) and **decision** (ADR-light: decision, context,
alternatives, consequences; statuses active/superseded via `supersedes=` flags
— the format the reference client corpus already practices by hand). Hygiene
invariants: a hypothesis without a falsifiable statement or next check is a
finding; a superseded decision must name its successor.

**Acceptance Scenarios**:

1. **Given** a hypothesis card missing its check plan, **When** hygiene runs
   with the mask installed, **Then** a mask-invariant finding names it.
2. **Given** decision B supersedes decision A, **When** filed, **Then** flags
   are mirrored (`supersedes=`/`superseded-by=`) and `/kb-ask` warns when
   citing A.

---

### User Story 5 - Two modes: discovery vs running product (Priority: P5)

The mask serves a NEW product (no users yet: problem framing, segment guesses,
discovery interviews) and an EXISTING one (feedback streams, metric
observations, iteration decisions) with the same five disciplines — the rules
describe both entry points and `/kb-add` classification hints cover both kinds
of raw material.

**Acceptance Scenario**: filing a discovery-interview excerpt and filing a
production feedback ticket both land correctly (insight nodes with evidence),
with no mode switch beyond the material itself.

### Edge Cases

- Mask installed over a base where SOME mask themes exist (partial mask):
  per-theme collision handling, no all-or-nothing abort.
- A journey stage referencing an insight that later gets `superseded-by=` —
  audit surfaces the chain, journey is not silently wrong.
- Insight extracted from a source in an external base (memory bridge):
  evidence citation uses `[[mem:slug]]` — read-only, validated per 001 rules.
- Uninstalling the mask (v1: not supported beyond `kb-init --uninstall` of the
  whole toolkit) — documented limitation; themes remain as plain themes.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-101**: The mask format MUST support multiple themes per mask (manifest
  lists theme slugs; per-theme rules and templates), backward-compatible with
  single-theme masks (001 `sources` mask keeps working unchanged).
- **FR-102**: `kb-init --mask` MUST install multi-theme masks with per-theme
  collision handling (surface each; user decides per theme or aborts; nothing
  overwritten).
- **FR-103**: The product mask MUST deliver five disciplines as themes:
  `insights`, `journeys`, `hypotheses`, `decisions`, `segments` — each with
  rules, node template(s), and INDEX skeleton.
- **FR-104**: Insight rules MUST require evidence citations (quote + locator to
  a source node, local or external base); insights without evidence are
  rejected into INBOX/hypotheses by rule.
- **FR-105**: Hypothesis and decision lifecycles MUST use the existing flags
  mechanism (`validated/invalidated` recorded as visible status in frontmatter;
  `supersedes=`/`superseded-by=` mirrored pairs) — no new state machinery.
- **FR-106**: Mask `checks.conf` invariants MUST be enforced at hygiene time
  for mask themes: required frontmatter per type, required sections per type
  (e.g., hypothesis needs a check plan section) — mechanical checks only;
  judgment stays in skills.
- **FR-107**: Journey nodes MUST be plain markdown (stages as sections, insight
  links inline) — no new file format; `/kb-viz` shows journey↔insight edges
  like any links.
- **FR-108**: The mask MUST document and support both discovery and running-
  product entry modes in its rules (classification hints for /kb-add).

### Key Entities

- **Insight**: one observed user need/pain/behavior; MUST carry evidence
  citation(s); links to segment and source.
- **Journey**: a scenario/segment path; sections = stages; stages link
  insights.
- **Hypothesis**: falsifiable statement + planned check + result; lifecycle in
  flags.
- **Decision**: ADR-light card; lifecycle active/superseded in flags.
- **Segment**: who this is about; referenced by insights and journeys.
- **Mask manifest v2**: multi-theme; per-theme rules/templates/checks.

## Success Criteria *(mandatory)*

- **SC-101**: One command installs the mask: 5 themes, indexes, rules; a fresh
  session can file into any of them correctly (spot-run: 5 varied inputs, ≥4
  land without correction).
- **SC-102**: On a base wearing sources + product masks, an insight extracted
  from a real transcript carries a grep-verifiable quote+locator citation.
- **SC-103**: Seeded mask-invariant violations (hypothesis without check plan,
  decision without status) are 100% detected by hygiene with the mask
  installed; zero such findings on a clean mask fixture.
- **SC-104**: 001 regression: entire existing test suite stays green;
  single-theme `sources` mask installs unchanged.
- **SC-105**: Mask coexistence: `/kb-ask` answers a question whose evidence
  spans a product insight AND a CRM/sources node on one base, citing both.

## Assumptions

- Mask content language: templates/rules EN (engine convention), bodies in the
  user's language, per constitution.
- The five disciplines are the v1 mask; PM artifacts beyond them (roadmaps,
  OKRs, metric trees) are follow-up masks or additions — kept out to protect
  scope.
- `checks.conf` enforcement lands in `kb-check.sh` as mechanical rules
  (required frontmatter keys / required section headings per type); anything
  needing judgment goes to `/kb-audit`, not scripts.
- First validation corpus: a client project, corpus C (its decision log
  already practices the decision discipline by hand) and corpus A product
  docs (existing-product mode).

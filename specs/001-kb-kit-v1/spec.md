# Feature Specification: kb-kit v1 — file-based knowledge graph toolkit

**Feature Branch**: `001-kb-kit-v1`

**Created**: 2026-07-06

**Status**: Draft

**Input**: User description: "kb-kit v1 — file-based knowledge graph for Claude Code. Markdown nodes (one file = one fact, frontmatter name/description/type/tags), INDEX.md per theme, [[wikilinks]], nested per-theme rules, INBOX; commands /kb-add (curated filing, ask-don't-guess, second-opinion hook), /kb-ask (two-stage retrieval with file citations), /kb-check (broken links, orphans, index drift), /kb-viz (self-contained HTML graph); kb-init (install + migration over an existing corpus without moving files, corpus conventions win); pack as first-class unit; agent-neutral core. Test corpora: three private reference corpora: research docs, a 174-card sales CRM, a raw client-project intake."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - File a fact with one command (Priority: P1)

A user working in their project drops raw material (a transcript, a link with commentary, a thought, a pasted text) with a single command. The system decides where it belongs: picks or creates the right theme, creates or updates the node(s), adds the index row, sets links to related existing nodes, and reports back "what went where". When the placement is genuinely ambiguous or the new fact contradicts an existing node, the system asks instead of guessing.

**Why this priority**: Filing discipline is the core product. Without it the base rots (proven by the reference corpus, where ~60 cards accumulated on disk without index entries). Every other capability consumes what this one produces.

**Independent Test**: On a copy of a test corpus, submit 5 raw inputs of different kinds; verify each landed as a correct node with an index row and links, with no manual relocation needed afterwards.

**Acceptance Scenarios**:

1. **Given** an initialized base with existing themes, **When** the user submits a raw fact clearly belonging to one theme, **Then** a node is created (or an existing node updated) in that theme, the theme index gains/updates one row, relevant `[[links]]` are set, and the user receives a report listing every file touched.
2. **Given** a raw input that plausibly belongs to two themes, **When** the user submits it, **Then** the system presents the candidate placements with its recommendation and waits for the user's choice before writing.
3. **Given** a new fact that contradicts an existing node, **When** the user submits it, **Then** the system surfaces the conflict (quoting both versions) and asks how to resolve it; it never overwrites silently.
4. **Given** items waiting in the INBOX queue, **When** the user runs the filing command over the queue, **Then** each item is processed as above and marked done in the queue.
5. **Given** a repository where a well-known optional hook script is present, **When** classification runs, **Then** the hook is consulted and its opinion included in the report; **Given** the script is absent, **Then** filing proceeds identically with no error or mention.

---

### User Story 2 - Ask the base a question (Priority: P2)

In a completely fresh session with zero prior context, the user asks a question. The system navigates the base — root index first, then theme indexes, then only the selected node bodies — and answers with explicit file citations for every claim taken from the base.

**Why this priority**: Retrieval is the payoff of filing. It must work in a fresh session — that is the whole point of externalizing memory.

**Independent Test**: In a new session on a test corpus, ask 10 prepared questions whose answers span 2–3 nodes across different themes; verify answers are correct and every cited file actually contains the referenced fact.

**Acceptance Scenarios**:

1. **Given** a populated base and a fresh session, **When** the user asks a question answerable from the base, **Then** the answer is produced with file-level citations, and only a small fraction of the base's content is read to produce it.
2. **Given** a question whose answer spans multiple themes, **When** asked, **Then** the answer synthesizes nodes from the involved themes and cites each source file.
3. **Given** a question the base cannot answer, **When** asked, **Then** the system says so explicitly and names the nearest related nodes, rather than inventing an answer.

---

### User Story 3 - Install into a repository, including over an existing corpus (Priority: P3)

A user installs kb-kit into a new or existing repository with one command. In an empty repository it scaffolds the base structure (root index, INBOX, example theme). In a repository with an existing knowledge corpus it adapts: it does not move or rename a single existing file; it reads the corpus's own de-facto conventions (naming, card formats, existing index files) and formalizes them as the theme rules, applying kb-kit defaults only where the corpus has no convention of its own.

**Why this priority**: Installation is the distribution moment, and migration-without-disruption is the adoption unlock for everyone who already has a docs folder.

**Independent Test**: Run installation over a copy of the reference corpus (170+ cards, existing index and README conventions); verify zero files moved/renamed, conventions captured in theme rules, and Stories 1–2 immediately functional on it.

**Acceptance Scenarios**:

1. **Given** an empty repository, **When** the user installs, **Then** the base skeleton (root index, INBOX, theme template, commands) is created and a filing command immediately works.
2. **Given** a repository with an existing corpus, **When** the user installs, **Then** no existing file is moved, renamed, or rewritten without explicit confirmation; discovered conventions are written into per-theme rules; existing index files are adopted as the theme indexes.
3. **Given** a corpus area whose files don't match any convention, **When** installation analyzes it, **Then** the ambiguity is reported to the user with proposed treatment rather than silently normalized.
4. **Given** a repository where kb-kit is already installed, **When** installation runs again, **Then** it updates the toolkit components without touching the knowledge content (idempotent re-run).

---

### User Story 4 - Keep the base healthy (Priority: P4)

The user runs a hygiene command. The system mechanically finds broken `[[links]]`, orphan nodes (no incoming links and absent from any index), and index drift (index rows without files, files without index rows, stale hooks), then fixes what is safe to fix and proposes the rest. Nothing is ever deleted without an explicit, visible decision.

**Why this priority**: Drift is the documented failure mode of the manual process; detection must be mechanical and cheap to run.

**Independent Test**: Seed a copy of a test corpus with known defects of each class; verify 100% are detected, safe fixes are applied, destructive fixes are only proposed.

**Acceptance Scenarios**:

1. **Given** a base with a link pointing to a non-existent node, **When** hygiene runs, **Then** the broken link is reported with its location and a proposed resolution (create stub, retarget, or remove — removal requiring confirmation).
2. **Given** a node present on disk but absent from its theme index, **When** hygiene runs, **Then** the missing index row is detected and added (safe fix), and reported.
3. **Given** an index row whose file no longer exists, **When** hygiene runs, **Then** the row is flagged; removal happens only after user confirmation.
4. **Given** a healthy base, **When** hygiene runs, **Then** it reports a clean bill of health and changes nothing.

---

### User Story 5 - See the graph (Priority: P5)

The user runs a visualization command and gets a single self-contained HTML file: an interactive graph of all nodes and links, colored by theme, searchable, working offline in any browser. A file, not an application — nothing is served, nothing keeps running.

**Why this priority**: Visual overview aids trust and navigation but consumes the structures built by Stories 1–4.

**Independent Test**: Generate the file on a test corpus; open it from disk with networking disabled; verify all nodes and edges present and interactive.

**Acceptance Scenarios**:

1. **Given** a populated base, **When** the user runs visualization, **Then** a single HTML file is produced that renders the full graph offline, with node details (name, description, theme) available on interaction.
2. **Given** the file is regenerated after base changes, **Then** the new graph reflects the changes; the file can be committed as a snapshot.

---

### User Story 6 - Install a pack (Priority: P6)

A user installs a pack — a packaged vertical discipline (e.g., a sales CRM theme) — as one unit: node templates, theme rules, hygiene invariants, and any command extensions arrive together and become a ready-to-use theme in the base.

**Why this priority**: Packs are the extensibility and future distribution story; v1 needs the mechanism proven by at least one built-in pack, not a pack ecosystem.

**Independent Test**: Install the default example pack into a fresh base; verify the theme appears with its templates and rules, and filing into it follows the pack's conventions.

**Acceptance Scenarios**:

1. **Given** an initialized base, **When** the user installs a pack, **Then** a new theme is created carrying the pack's templates, rules, and hygiene invariants, and the filing command honors them immediately.
2. **Given** a pack whose theme name collides with an existing theme, **When** installation runs, **Then** the conflict is surfaced and the user chooses (rename/merge/abort); nothing is overwritten silently.

---

### User Story 7 - Audit the base for semantic consistency (Priority: P7)

Periodically the user runs a deep-scan command. Unlike hygiene (mechanical, structural), the audit reads content: it looks for facts that contradict each other, near-duplicate nodes, stale facts superseded by newer ones, and entities that clearly should be linked but aren't. Findings come back as a report quoting the evidence; findings the user approves are recorded as visible marks on the affected nodes (e.g., a "disputed" mark naming both sides), so inconsistency is never silent — it is either resolved or labeled.

**Why this priority**: Filing-time conflict detection (Story 1) only catches collisions the filer sees; contradictions also *emerge* as facts age. A periodic content-level scan is the complement that keeps trust in the base. It consumes everything Stories 1–4 produce.

**Independent Test**: Seed a copy of a test corpus with known semantic defects (contradicting pairs, near-duplicates, superseded facts); verify the audit surfaces them with quoted evidence and changes nothing without confirmation.

**Acceptance Scenarios**:

1. **Given** two nodes asserting incompatible facts, **When** the audit runs, **Then** the pair is reported with both statements quoted and their files named.
2. **Given** the user approves a contradiction finding, **When** the audit applies it, **Then** both nodes receive a visible mark referencing each other, and the marks are discoverable by later hygiene/audit runs.
3. **Given** two near-duplicate nodes, **When** the audit runs, **Then** a merge is proposed with a diff-style preview; merging happens only on confirmation.
4. **Given** a large base, **When** the audit runs, **Then** it narrows candidates using indexes and metadata first rather than reading every node body for every comparison.

---

### Edge Cases

- Raw input that yields multiple facts (a long transcript): filing splits it into several nodes, reporting the full mapping; the user can veto the split.
- Slug collision: a new node's natural name matches an existing node in another theme — filing must disambiguate, never silently merge.
- Intentional forward-link: a `[[link]]` to a not-yet-written node is legal (it marks future work); hygiene distinguishes it from a typo by reporting both but treating stubs-by-intent as a proposal, not an error.
- A base at the scale ceiling (high hundreds of nodes): retrieval and hygiene must remain practical; no capability may require reading the entire corpus into context at once (visualization's mechanical scan excepted).
- Installation into a repository that is not under version control: allowed with a prominent warning that the safety model (diff/review/rollback) is degraded.
- The INBOX contains an item too vague to classify: it stays in the queue with a recorded question to the user, rather than being force-filed.
- Migration encounters an existing file that is itself an index of another area (nested index): adopted as-is; nesting is respected, not flattened.
- Fact-level anchoring inside adopted (pre-existing) files: inserting an anchor mark edits a file kb-kit does not own — allowed only with confirmation; otherwise the citation falls back to link + verbatim quote, which needs no file edit.
- Non-markdown artifacts in a corpus (audio recordings, spreadsheets, JSON exports, scripts): they are not nodes and stay out of the graph, but nodes may cite them via plain relative links; hygiene validates that such referenced files exist.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The base MUST consist of plain markdown files in the repository; a node is one file holding one fact/card/digest with frontmatter fields `name` (slug), `description` (one line sufficient for a relevance decision without reading the body), `type`, and `tags`.
- **FR-002**: Relations between nodes MUST be expressed as `[[name]]` wikilinks in node bodies.
- **FR-003**: Each theme MUST be a directory with its own index file (one row per node: name, hook, link) and its own rules file governing node format, naming, and what counts as a node in that theme.
- **FR-004**: The base MUST have a root index listing themes and conventions, and an INBOX queue for raw material awaiting filing.
- **FR-005**: The filing command MUST accept raw material, classify it (theme, node placement), create or update node(s), update the affected index(es) in the same operation, set links to related nodes, and report every file touched.
- **FR-006**: The filing command MUST escalate to the user instead of guessing when placement is ambiguous. When new material touches an existing node, complementary additions and refinements are applied directly (the change remains visible and reviewable in version history); when the new fact materially contradicts the existing node, the conflict MUST be surfaced quoting both versions, and the user decides. Nothing is overwritten silently.
- **FR-007**: The filing command MUST consult an optional user-provided second-opinion hook (a well-known script location) during classification when present, and proceed identically without it when absent.
- **FR-008**: The retrieval command MUST answer questions in a fresh session using staged reading — root index, then theme indexes, then selected node bodies only — and MUST cite the source file for every base-derived claim; when the base lacks an answer, it MUST say so and name the nearest related nodes.
- **FR-009**: The hygiene command MUST mechanically detect broken wikilinks, orphan nodes, and index–folder drift in both directions; safe fixes MAY be applied automatically, destructive changes (removal of rows, links, nodes) MUST require explicit confirmation.
- **FR-010**: The visualization command MUST produce a single self-contained HTML file rendering the full node/link graph offline (no server, no network access), with nodes grouped/colored by theme and basic interaction (pan/zoom, node details, search).
- **FR-011**: The installer MUST scaffold a new base in an empty repository and MUST install over an existing corpus without moving, renaming, or rewriting existing files; discovered corpus conventions take precedence over kb-kit defaults and are formalized into theme rules; re-running the installer MUST be idempotent for knowledge content. Adopted markdown files lacking node frontmatter MUST still participate in the graph and retrieval in a degraded mode (identity from filename, description from their index row when present) and are upgraded to full nodes on their first filing touch, with confirmation.
- **FR-012**: A pack MUST be installable as one unit delivering node templates, theme rules, and hygiene invariants; v1 MUST ship at least one built-in pack proving the mechanism; name collisions on install MUST be surfaced, never silently resolved.
- **FR-013**: The knowledge content (nodes, indexes, links) MUST contain nothing specific to any particular agent product; agent-specific adapters (commands, rules files) MUST be separable and replaceable.
- **FR-014**: All state MUST live in files under version control; the system MUST require no background processes, servers, databases, or external services, and MUST function on any machine with git and the supported agent tooling.
- **FR-015**: Node slugs and frontmatter keys MUST be in English; node bodies follow the user's working language.
- **FR-016**: The filing command MUST accept material explicitly provided by the user (pasted text, file references, links with commentary) and MUST additionally support an explicit "from current conversation" mode that extracts candidate facts from the active session on command — presented for confirmation before filing, and never triggered passively.
- **FR-017**: Citations MUST work at fact granularity, not only file granularity: (a) links MAY target a section or marked block inside a node (`[[name#anchor]]`); (b) a claim derived from source material MUST carry the verbatim quote and its locator (timecode, section) alongside the link to the source node; (c) retrieval answers MUST quote the specific supporting line(s) of cited nodes, not merely name the files; (d) hygiene MUST validate that anchored links point to anchors that exist.
- **FR-018**: A semantic audit command MUST scan base content for contradictions between nodes, near-duplicate nodes, superseded/stale facts, and missing links between clearly related nodes; it MUST narrow candidates via indexes and metadata before reading bodies (never all-pairs full reads); findings MUST be reported with quoted evidence; approved findings are recorded as visible, machine-findable consistency marks on the affected nodes; the audit applies no change without confirmation.

### Key Entities

- **Node**: one file = one fact/card/digest; identity is its slug; carries a one-line description for relevance decisions; belongs to exactly one theme.
- **Theme**: a directory of nodes with its own index and its own rules; the unit of local convention.
- **Index**: per-theme table of one row per node (name, hook, link); the root index lists themes. Indexes are the first-read layer of retrieval and must always mirror their folder.
- **Link**: a directed `[[name]]` reference between nodes; the edge of the graph.
- **INBOX**: the queue of raw, not-yet-filed material with per-item status.
- **Pack**: an installable unit bundling node templates, theme rules, and hygiene invariants for a vertical discipline.
- **Corpus (pre-existing)**: a user's existing document collection with de-facto conventions that installation must respect and formalize, not replace.
- **Evidence citation**: a link to a source node plus the verbatim quote and locator (timecode/section) supporting a claim; the unit of fact-level referencing.
- **Consistency mark**: a visible, machine-findable label on a node recording an audit outcome (disputed-with, superseded-by, duplicate-of), always referencing the counterpart node.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Filing a new fact takes one command; in a test run of 10 varied inputs on the reference corpora, at least 9 land with no manual relocation or index correction needed afterwards.
- **SC-002**: In a fresh session, 10 prepared questions whose answers span 2–3 nodes across themes are answered with correct content and 100% correct file citations on the test corpora.
- **SC-003**: Installation over the 170+ card reference corpus moves or renames zero existing files, and filing/retrieval work on it immediately afterwards.
- **SC-004**: The system operates with no running services of any kind; a machine with only git and the agent tooling can execute every capability (verified by inspection on a clean environment).
- **SC-005**: A week's INBOX flow (3–5 raw items) processed by the filing command matches manual-quality results: subsequent hygiene run reports zero missing index rows and zero broken links.
- **SC-006**: On a corpus seeded with known defects (including the documented historical drift of the reference CRM corpus), the hygiene command detects 100% of seeded broken links, orphans, and index drift cases.
- **SC-007**: The visualization file opens offline in a stock browser and renders every node and edge of a base of at least 200 nodes, as a single file.
- **SC-008**: Answering a typical question reads no more than 10% of the base's total content volume (staged retrieval economy).
- **SC-009**: In a spot-check of 20 base-derived claims across retrieval answers, 100% are supported by an accurate verbatim quote from the cited node (fact-level citation).
- **SC-010**: On a corpus seeded with 10 semantic defects (contradicting pairs, near-duplicates, superseded facts), the audit surfaces at least 8, and applies zero changes without explicit confirmation.

## Assumptions

- One knowledge base per repository in v1; a personal base is simply another repository. Cross-base querying is out of scope for v1.
- Scale target is tens to hundreds of nodes (validated up to ~1000); capabilities may assume indexes fit comfortably in an agent's working context.
- The supported agent for v1 is Claude Code; the core stays agent-neutral (FR-013) and adapters for other agents are roadmap, not v1.
- Conflict resolution defaults to surfacing and asking (Constitution Principle III); version history is provided by git, not by node-level versioning.
- Packs in v1 = the install mechanism plus one built-in example pack; pack authoring guides and a registry are out of scope.
- Embeddings, semantic search, passive capture of conversations, and any UI beyond the generated HTML file are explicitly out of scope for v1.
- Three reference corpora are available locally for validation, each stressing a different capability: corpus A — curated research docs (migration adopts good conventions), corpus B — a 174-card sales CRM (index drift at scale — hygiene), corpus C — a ~240-file client-project intake (raw INBOX mess — filing/classification, plus call transcripts with client quotes — evidence citations, plus an ADR-light decision log already using superseded/active statuses — consistency marks in the wild).
- Multimodal raw input (screenshots of text) is handled as its extracted text; image storage in the base is out of scope for v1.

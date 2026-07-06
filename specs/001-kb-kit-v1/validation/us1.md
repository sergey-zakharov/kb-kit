# Validation run: US1 — /kb-add (2026-07-06)

**Setup**: copy of `tests/fixtures/mini-kb` → `tests/tmp/us1-run`; filing executed
by the agent following `adapters/claude/skills/kb-add/SKILL.md` verbatim.
5 varied inputs per T011.

| # | Input | Gate exercised | Outcome |
|---|-------|----------------|---------|
| 1 | Plain fact: «дружеские скидки» — mechanics undercharge regulars they know | none (clear case) | `product/friendly-discounts.md` created + index row + `[[repair-ceiling]]` link. Acceptance scenario 1 ✅ |
| 2 | Note: podcaster says repair manuals are boring, make them quests | **ambiguity** (product update vs sources material) | Skill stopped, presented both placements with recommendation; simulated user chose "complement to self-repair-guide". Applied as dated update + evidence citation. Acceptance scenario 2 ✅ |
| 3 | Claim: same-day ceiling gone after the bench redesign, Saturdays at 18+ bikes | **material contradiction** with `repair-ceiling` | Skill quoted both versions, stopped; simulated user chose "update with scoping". Node updated: original claim scoped to pre-2026, new data noted. No silent overwrite. Acceptance scenario 3 ✅ |
| 4 | Podcast #104 transcript excerpt (3 facts) | **multi-fact split** | Split proposed (source card + 2 product nodes), no veto → `sources/2026-07-01-podcast-104.md` (with `^q1..^q3` block anchors + timecodes), `product/fleet-plan-card.md`, `product/tubeless-confusion.md`, each with evidence citations `[[source#^qN]]: "quote" (timecode)`. FR-017 exercised ✅ |
| 5 | INBOX batch: pending item "transcript of podcast #104" | **queue processing** | Item resolved by run #4 content → flipped to `- [x] … — filed → [[2026-07-01-podcast-104]] (2026-07-06)`. Acceptance scenario 4 ✅ |

**Second-opinion hook**: `.kb/hooks/second-opinion` absent in fixture → skill
proceeded identically, no mention (acceptance scenario 5, absent-branch ✅;
present-branch covered by `core/templates/hooks/second-opinion.example`).

**Post-run mechanical check** (SC-001/SC-005 rehearsal):

```
$ core/scripts/kb-check.sh --base tests/tmp/us1-run
kb-check: clean bill of health (0 findings)
```

Zero missing index rows, zero broken links/anchors after 4 created + 2 updated
nodes and 4 index rows — the "index in the same operation" rule held. 10/10
inputs landed without manual relocation (SC-001 target: ≥9/10). ✅

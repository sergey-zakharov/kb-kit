# /kb-ask benchmark — 10 questions + honesty probe (SC-002, SC-008, SC-009)

**Base**: `tests/tmp/us1-run` (mini-kb after the US1 filing run: 12 nodes, 2 themes).
**Protocol**: fresh agent session with zero prior context, given only the base
path and `adapters/claude/skills/kb-ask/SKILL.md`. Every answer must carry
file citations with verbatim quotes. Pass = correct content + correct citations.

| # | Question | Expected sources (any subset proving the answer) |
|---|----------|--------------------------------------------------|
| 1 | Почему очередь «кто первый пришёл» плохо работает и что предлагается взамен? | product/repair-ceiling.md, product/walk-in-slots.md |
| 2 | Какие есть свидетельства «потолка ремонтов» и актуален ли он сейчас? | product/repair-ceiling.md (scoped update), sources/2026-01-15-podcast-mechanic.md (^q2) |
| 3 | Что известно про онбординг новичков в самостоятельный ремонт? | product/self-repair-guide.md, product/tubeless-confusion.md, sources/2026-07-01-podcast-104.md |
| 4 | Что курьеры просили сделать для своих команд? | product/fleet-plan-card.md, sources/2026-07-01-podcast-104.md (^q2) |
| 5 | Как знакомство с мастером искажает цены? | product/friendly-discounts.md, sources/comments-mining.md |
| 6 | Какая точная цитата подтверждает потолок ремонтов, откуда она и с каким таймкодом? | sources/2026-01-15-podcast-mechanic.md ^q2 "the busiest Saturday we ever had — 12 bikes" (14:20) |
| 7 | Что говорил курьер-видеоблогер и с чем в базе это связано? | sources/2026-03-24-video-courier.md, product/repair-ceiling.md |
| 8 | Какие продуктовые ставки сейчас в работе? | product/roadmap-digest.md (+walk-in-slots, self-repair-guide) |
| 9 | Чего клиенты боятся в смете на ремонт? | sources/comments-mining.md |
| 10 | Что мы знаем про наборы для ремонта? | sources/2026-07-01-podcast-104.md (^q1), product/self-repair-guide.md (update) |
| H | Что известно о ценах на подписку? | MUST answer "база не отвечает" + nearest nodes (honesty probe) |

## Run record — 2026-07-06

**Runner**: fresh general-purpose agent, zero prior context, given only the base
path and the SKILL.md path. Full transcript data: agent answered all 11 in one
session following staged reading (SKILL.md → KB.md → 2 INDEX.md → shortlisted bodies).

**Results**:

- **Q1–Q10: 10/10 correct** — content matches expected sources; multi-theme
  synthesis worked (Q2, Q3, Q5, Q7 span product+sources); Q2 correctly picked up
  the scoped-conflict update from the US1 run; Q6 delivered the fact-level
  citation with anchor and timecode (`^q2`, 14:20).
- **QH (honesty probe): PASS** — «База не отвечает на этот вопрос» + two nearest
  nodes by index descriptions. No invention.
- **SC-009 (quote accuracy)**: 15 cited quotes grep-verified against node files —
  **15/15 verbatim** (one required cross-line-wrap matching; the citation itself
  was accurate).
- **SC-002**: citations named correct files for 11/11 questions.
- **SC-008 (≤10% content per question)**: procedure held (indexes first,
  1–3 bodies per question), but the 12-node fixture is too small for the 10%
  arithmetic to be meaningful (1 body ≈ 8%). Metric to be re-measured on the
  real corpora in Phase 10 (T029–T031), where bases are 170–240 files.
- **Flags warning branch**: not exercised here (no flagged nodes in this base);
  covered later by US7 validation.

**Verdict**: US2 acceptance scenarios 1–3 ✅.

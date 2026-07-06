---
name: self-repair-guide
description: self-repair guide as onboarding funnel, 10 fixes prototype from 2020 podcast
type: card
tags: content, onboarding
---

A 10-fix guide works as an education funnel; [[2026-03-24-video-courier]] confirms
demand from lapsed customers.

See [[walk-in-slots#Motivation]] for why booking beats queueing.

Technical note (fence must be ignored by the parser):

```sql
-- regex classes like [[:<:]] and [[:>:]] are not wikilinks
SELECT * FROM repairs; -- [fake link](missing-inside-fence.txt)
```

- One node = one significant decision (a turn: changes direction or scope).
  Not every clarification — turns only (ADR-light).
- Mandatory sections: **Decision**, **Context** (what forced it; link insights/
  sources), **Alternatives** (what was rejected and why), **Consequences**.
- Frontmatter `status: active | superseded`. Superseding: the NEW decision gets
  `flags: supersedes=<old>`, the old one `flags: superseded-by=<new>` +
  `status: superseded` — mirrored, per engine rules; /kb-ask warns when citing
  a superseded decision.
- Naming: `NNN-<slug>.md` with a running number (sortable history).

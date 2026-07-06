- One node = one journey: a segment moving through a scenario
  (e.g. "first-visit-to-checkout"). Sections = stages, in order.
- **Every stage claim traces to insights**: each stage section links the
  `[[insight]]` nodes observed there (pains, gains, workarounds). A stage with
  no insight links is a hypothesis about the journey — mark it `(assumed)`.
- Frontmatter `type: journey`; link the segment node.
- The journey is part of the graph: /kb-ask answers "what do we know about
  stage X" through these links; /kb-audit proposes attaching orphaned insights
  to stages.

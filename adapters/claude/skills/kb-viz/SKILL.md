---
name: kb-viz
description: Generate a self-contained interactive HTML graph of the knowledge base (kb-graph.html) — a file, not an app. Use when the user wants to see/visualize the base or says /kb-viz.
---

# /kb-viz — see the graph

1. Locate the base (`.kb/config` → `KB_DIR`).
2. Run `.kb/scripts/kb-viz.sh --base <KB_DIR>` (optional `--out <file>`).
3. Verify the output: file exists, no `http` references inside (offline
   guarantee), then report:

```
kb-graph.html written — N nodes, M links (K broken, A adopted)
Open it in any browser; works offline. Commit it if you want a dated snapshot.
```

Notes for reading the graph: colors = themes; dashed circles = adopted
(frontmatter-less) nodes; orange ring = open consistency flags (see /kb-audit);
red dashed stubs = broken links (fix via /kb-check).

#!/usr/bin/env bash
# kb-check.sh — mechanical hygiene findings over a kb base.
# Zero dependencies; consumes kb-graph.sh --tsv (single parser = single source of truth).
#
# Usage: kb-check.sh [--base <dir>] [--json]
# Exit codes: 0 = clean, 1 = findings present, 2 = usage/environment error.
#
# Finding types: broken-link broken-anchor broken-file-ref orphan-node
#   index-missing-row index-stale-row unindexed-theme frontmatter-invalid
#   flagged-node inbox-blocked
# Precedence: a node file yields at most one structural finding —
#   index-missing-row wins over orphan-node (orphan reported in its detail).
# Adopted nodes (no frontmatter) are exempt from frontmatter-invalid.
set -euo pipefail

BASE="."
MODE="human"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?}"; shift 2 ;;
    --json) MODE="json"; shift ;;
    *) echo "Usage: kb-check.sh [--base <dir>] [--json]" >&2; exit 2 ;;
  esac
done
SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
GRAPH="$SELF_DIR/kb-graph.sh"
[ -x "$GRAPH" ] || { echo "kb-check: kb-graph.sh not found next to kb-check.sh" >&2; exit 2; }

"$GRAPH" --base "$BASE" --tsv | LC_ALL=C awk -F"\t" -v MODE="$MODE" '
  function jesc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
  function addf(type, file, detail, safefix) {
    fcount++
    ftype[fcount] = type; ffile[fcount] = file; fdetail[fcount] = detail; ffix[fcount] = safefix
  }
  $1 == "NODE" {
    nc++
    id[nc] = $2; theme[nc] = $3; rel[nc] = $4
    adopted[nc] = $5; fmvalid[nc] = $6; fmprob[nc] = $7; flags[nc] = $9
    file_of[$2] = $4
  }
  $1 == "EDGE" {
    ec++
    efrom[ec] = $2; eto[ec] = $3; eanc[ec] = $4; ekind[ec] = $5; ebroken[ec] = ($6 == "1")
    if ($6 == "0") incoming[$3] = 1
  }
  $1 == "FILEREF" { frc++; frfrom[frc] = $2; frpath[frc] = $3; frex[frc] = ($4 == "1") }
  $1 == "INDEXROW" {
    indexed[$3] = 1
    if ($4 == "0") { src++; srfile[src] = $2; srtgt[src] = $3 }
  }
  $1 == "THEME" { if ($3 == "0" && $4 == "1" && $2 != "") tmiss[++tc] = $2 }
  $1 == "INBOX" { if ($2 == "blocked") { bc++; btext[bc] = $3 } }
  END {
    for (i = 1; i <= ec; i++) {
      if (!ebroken[i]) continue
      if (eanc[i] != "" && ekind[i] == "anchor")
        addf("broken-anchor", file_of[efrom[i]], "link [[" eto[i] "#" eanc[i] "]] — anchor not found in target", "")
      else
        addf("broken-link", file_of[efrom[i]], "link [[" eto[i] "]] — target not found", "")
    }
    for (i = 1; i <= frc; i++)
      if (!frex[i]) addf("broken-file-ref", frfrom[i], "referenced file does not exist: " frpath[i], "")
    for (i = 1; i <= src; i++)
      addf("index-stale-row", srfile[i], "row points to missing file: " srtgt[i], "")
    # per-node structural + validity findings
    for (i = 1; i <= nc; i++) {
      if (!(rel[i] in indexed)) {
        d = "node has no index row"
        if (!(id[i] in incoming)) d = d "; also orphaned (no incoming links)"
        addf("index-missing-row", rel[i], d, "add-index-row")
      }
      if (adopted[i] == 0 && fmvalid[i] == 0)
        addf("frontmatter-invalid", rel[i], fmprob[i], "")
      if (flags[i] != "")
        addf("flagged-node", rel[i], "open consistency marks: " flags[i], "")
    }
    for (i = 1; i <= tc; i++)
      addf("unindexed-theme", tmiss[i], "theme directory not listed in KB.md", "")
    for (i = 1; i <= bc; i++)
      addf("inbox-blocked", "INBOX.md", "item awaiting user: " btext[i], "")

    if (MODE == "json") {
      printf "{\"findings\": ["
      for (i = 1; i <= fcount; i++)
        printf "%s\n  {\"type\": \"%s\", \"file\": \"%s\", \"detail\": \"%s\", \"safe_fix\": %s}", \
          (i > 1 ? "," : ""), jesc(ftype[i]), jesc(ffile[i]), jesc(fdetail[i]), \
          (ffix[i] == "" ? "null" : "\"" jesc(ffix[i]) "\"")
      printf "%s]}\n", (fcount > 0 ? "\n" : "")
    } else {
      if (fcount == 0) print "kb-check: clean bill of health (0 findings)"
      else {
        for (i = 1; i <= fcount; i++)
          printf "%-20s %s — %s%s\n", ftype[i], ffile[i], fdetail[i], (ffix[i] != "" ? "  [safe fix: " ffix[i] "]" : "")
        printf "kb-check: %d finding(s)\n", fcount
      }
    }
    exit (fcount > 0 ? 1 : 0)
  }
'

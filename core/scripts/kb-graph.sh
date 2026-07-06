#!/usr/bin/env bash
# kb-graph.sh — parse a kb base into graph data (nodes, edges, filerefs, index rows, themes, inbox).
# Zero dependencies: bash + find + sort + awk (POSIX).
#
# Usage: kb-graph.sh [--base <dir>] [--json (default) | --tsv]
#
# TSV record types (tab-separated; internal contract consumed by kb-check.sh and kb-viz.sh):
#   NODE     id  theme  relpath  adopted  fmvalid  fmproblem  type  flags  tags  description
#   EDGE     from  to  anchor  kind(link|anchor)  broken
#   FILEREF  fromrel  path  exists
#   INDEXROW indexrel  targetrel  exists  hook
#   THEME    name  in_kb  has_nodes
#   INBOX    blocked  text
#
# Reserved basenames (never nodes): INDEX.md CLAUDE.md AGENTS.md KB.md INBOX.md
# MIGRATION_REPORT.md AUDIT_*.md
set -euo pipefail

BASE=""
MODE="json"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="${2:?}"; shift 2 ;;
    --json) MODE="json"; shift ;;
    --tsv)  MODE="tsv";  shift ;;
    *) echo "Usage: kb-graph.sh [--base <dir>] [--json|--tsv]" >&2; exit 2 ;;
  esac
done
# Default base: KB_DIR from ./.kb/config (never scan the whole cwd by accident)
if [ -z "$BASE" ]; then
  if [ -f .kb/config ]; then
    BASE="$(awk -F= '$1=="KB_DIR"{print $2}' .kb/config)"
  else
    BASE="."
  fi
fi
[ -d "$BASE" ] || { echo "kb-graph: base dir not found: $BASE" >&2; exit 2; }
BASE="${BASE%/}"

# External bases (memory bridge): unresolved [[slug]] links are looked up in
# each external base (flat <path>/<slug>.md) before being declared broken.
# Config: EXTERNAL_BASE_<name>=<abs-path> lines in ./.kb/config;
# override for tests/tooling: KB_EXTERNAL_BASES="name=path;name=path".
EXT_RAW="${KB_EXTERNAL_BASES:-}"
if [ -z "$EXT_RAW" ] && [ -f .kb/config ]; then
  EXT_RAW="$(awk -F= '/^EXTERNAL_BASE_/{n=$1; sub(/^EXTERNAL_BASE_/,"",n); printf "%s=%s;", n, $2}' .kb/config)"
fi
# split into reachable (usable for resolution) and unreachable (soft-reported)
EXT=""; EXTU=""
OLDIFS="$IFS"; IFS=';'
for pair in $EXT_RAW; do
  [ -n "$pair" ] || continue
  p="${pair#*=}"
  if [ -d "$p" ]; then EXT="$EXT$pair;"; else EXTU="$EXTU$pair;"; fi
done
IFS="$OLDIFS"

emit_tsv() {
  # File enumeration: git-first (respects .gitignore incl. venvs/build dirs,
  # sees untracked-but-not-ignored new nodes); falls back to find with a prune
  # list when the base is not in git or is itself gitignored (e.g. tmp bases).
  local files
  files="$(git -C "$BASE" -c core.quotepath=off ls-files --cached --others --exclude-standard -- '*.md' 2>/dev/null \
             | sed "s|^|$BASE/|" | LC_ALL=C sort || true)"
  if [ -z "$files" ]; then
    files="$(find "$BASE" \( -name .git -o -name .kb -o -name .claude -o -name node_modules \
         -o -name venv -o -name .venv -o -name __pycache__ -o -name site-packages \
         -o -name dist -o -name build -o -name vendor -o -name target \) -prune \
         -o -type f -name '*.md' -print | LC_ALL=C sort)"
  fi
  [ -n "$files" ] || return 0
  printf '%s\n' "$files" | tr '\n' '\0' | xargs -0 env LC_ALL=C awk -v BASE="$BASE" -v EXT="$EXT" -v EXTU="$EXTU" '
  function relpath(p,  b) {
    b = BASE
    if (index(p, b "/") == 1) return substr(p, length(b) + 2)
    return p
  }
  function trim(s) { gsub(/^[ \t]+/, "", s); gsub(/[ \t\r]+$/, "", s); return s }
  function slug(s,  out, i, c) {
    s = tolower(s); out = ""
    for (i = 1; i <= length(s); i++) {
      c = substr(s, i, 1)
      if (c ~ /[a-z0-9]/) out = out c
      else if (substr(out, length(out), 1) != "-" && out != "") out = out "-"
    }
    gsub(/-+$/, "", out); return out
  }
  function scanlinks(s, id,   i, rest, cl, inner, anc, h, pi) {
    rest = s
    while ((i = index(rest, "[[")) > 0) {
      rest = substr(rest, i + 2)
      cl = index(rest, "]]"); if (cl == 0) break
      inner = substr(rest, 1, cl - 1); rest = substr(rest, cl + 2)
      anc = ""
      h = index(inner, "#")
      if (h > 0) { anc = substr(inner, h + 1); inner = substr(inner, 1, h - 1) }
      pi = index(inner, "|"); if (pi > 0) inner = substr(inner, 1, pi - 1)
      inner = trim(inner); anc = trim(anc)
      # slugs only (plus optional external-base prefix "name:slug");
      # kills regex/POSIX-class noise like [[:<:]] from code samples
      if (inner !~ /^[A-Za-z0-9][A-Za-z0-9._-]*(:[A-Za-z0-9][A-Za-z0-9._-]*)?$/) continue
      ec++; efrom[ec] = id; eto[ec] = inner; eanc[ec] = anc
    }
  }
  function scanfilerefs(s, fromrel, fromdir,   i, rest, cl, p) {
    rest = s
    while ((i = index(rest, "](")) > 0) {
      rest = substr(rest, i + 2)
      cl = index(rest, ")"); if (cl == 0) break
      p = substr(rest, 1, cl - 1); rest = substr(rest, cl + 1)
      if (p == "" || p ~ /^#/ || index(p, "://") > 0 || p ~ /^mailto:/) continue
      h = index(p, "#"); if (h > 0) p = substr(p, 1, h - 1)   # strip fragment before existence check
      if (p == "") continue
      fc++; ffrom[fc] = fromrel; fpath[fc] = p; fdir[fc] = fromdir
    }
  }
  FNR == 1 {
    rel = relpath(FILENAME)
    fname = rel; sub(/^.*\//, "", fname)
    dir = rel
    if (dir == fname) dir = ""; else { sub("/" fname "$", "", dir) }
    theme = dir; sub(/\/.*/, "", theme)
    allmd[rel] = 1
    isindex = (fname == "INDEX.md")
    iskb    = (fname == "KB.md" && dir == "")
    isinbox = (fname == "INBOX.md")
    isres   = (fname == "CLAUDE.md" || fname == "AGENTS.md" || fname == "MIGRATION_REPORT.md" || fname ~ /^AUDIT/)
    isnode  = !(isindex || iskb || isinbox || isres)
    if (isnode) {
      nid = fname; sub(/\.md$/, "", nid)
      skipnode = 0
      if (nid in nrel) {
        # duplicate basename: first (sorted) file keeps the slug; report collision
        cc++; colid[cc] = nid; colfirst[cc] = nrel[nid]; coldup[cc] = rel
        skipnode = 1
      } else {
        nc++; norder[nc] = nid
        nrel[nid] = rel; ntheme[nid] = theme
        nname[nid] = ""; ndesc[nid] = ""; ntype[nid] = ""; ntags[nid] = ""; nflags[nid] = ""
        adopted[nid] = 1; infm = 0; fmwas = 0; infence = 0
        if (theme != "") themenodes[theme] = 1
      }
    }
  }
  {
    line = $0; sub(/\r$/, "", line)
    if (isnode) {
      if (skipnode) next
      if (FNR == 1 && line == "---") { infm = 1; fmwas = 1; adopted[nid] = 0; next }
      if (infm) {
        if (line == "---") { infm = 0; next }
        p = index(line, ":")
        if (p > 1) {
          k = trim(substr(line, 1, p - 1)); v = trim(substr(line, p + 1))
          if      (k == "name")        nname[nid] = v
          else if (k == "description") ndesc[nid] = v
          else if (k == "type")        ntype[nid] = v
          else if (k == "tags")        ntags[nid] = v
          else if (k == "flags")       nflags[nid] = v
        }
        next
      }
      # fenced code blocks: no headings, anchors, links, or filerefs inside
      if (line ~ /^(```|~~~)/) { infence = !infence; next }
      if (infence) next
      if (line ~ /^#/) { h = line; sub(/^#+[ \t]*/, "", h); heads[nid "\t" slug(h)] = 1 }
      if (line ~ /(^|[ \t])\^[A-Za-z0-9_-]+[ \t]*$/) {
        b = line; sub(/^.*\^/, "^", b); b = trim(b); blocks[nid "\t" b] = 1
      }
      scanline = line; gsub(/`[^`]+`/, "", scanline)   # inline code spans are not links
      scanlinks(scanline, nid)
      scanfilerefs(scanline, rel, dir)
    } else if (isindex) {
      if (index(line, "](") > 0) {
        i = index(line, "]("); rest = substr(line, i + 2)
        cl = index(rest, ")"); if (cl > 0) {
          tgt = substr(rest, 1, cl - 1)
          if (tgt ~ /\.md$/ && index(tgt, "://") == 0) {
            hook = ""
            dp = index(line, " \342\200\224 ")   # " — " em dash separator
            if (dp > 0) hook = trim(substr(line, dp + 5))
            irc++
            irfile[irc] = rel
            irtgt[irc]  = (dir == "" ? tgt : dir "/" tgt)
            irhook[irc] = hook
          }
        }
      }
    } else if (iskb) {
      if (index(line, "](") > 0) {
        i = index(line, "]("); rest = substr(line, i + 2)
        cl = index(rest, ")"); if (cl > 0) {
          tgt = substr(rest, 1, cl - 1)
          sub(/\/INDEX\.md$/, "", tgt); sub(/\/$/, "", tgt)
          if (tgt != "" && index(tgt, "://") == 0 && tgt !~ /\.md$/) kbtheme[tgt] = 1
        }
      }
    } else if (isinbox) {
      if (line ~ /^- \[\?\]/) { bc++; btext[bc] = trim(substr(line, 7)) }
    }
  }
  END {
    # index hooks by target (for adopted node descriptions)
    for (i = 1; i <= irc; i++) hookof[irtgt[i]] = irhook[i]
    # NODE records
    for (i = 1; i <= nc; i++) {
      id = norder[i]
      fmvalid = 1; prob = ""
      if (!adopted[id]) {
        if (nname[id] == "" || ndesc[id] == "" || ntype[id] == "") { fmvalid = 0; prob = "missing required frontmatter field(s)" }
        if (nname[id] != "" && nname[id] != id) { fmvalid = 0; prob = (prob == "" ? "" : prob "; ") "name does not match filename" }
      } else {
        if (ndesc[id] == "" && (nrel[id] in hookof)) ndesc[id] = hookof[nrel[id]]
      }
      printf "NODE\t%s\t%s\t%s\t%d\t%d\t%s\t%s\t%s\t%s\t%s\n", id, ntheme[id], nrel[id], adopted[id], fmvalid, prob, ntype[id], nflags[id], ntags[id], ndesc[id]
    }
    # external bases: reachable name=path pairs (EXT) and unreachable (EXTU)
    extn = split(EXT, extp, ";")
    for (i = 1; i <= extn; i++) {
      p = index(extp[i], "=")
      if (p > 0) { n = substr(extp[i], 1, p - 1); extc++; extpath[extc] = substr(extp[i], p + 1); extbyname[n] = extpath[extc]; extname[extc] = n }
    }
    extun = split(EXTU, extup, ";")
    for (i = 1; i <= extun; i++) {
      p = index(extup[i], "=")
      if (p > 0) extmissing[substr(extup[i], 1, p - 1)] = substr(extup[i], p + 1)
    }
    # EDGE records
    for (i = 1; i <= ec; i++) {
      to = eto[i]; anc = eanc[i]
      kind = (anc == "" ? "link" : "anchor")
      broken = 0
      ci = index(to, ":")
      if (ci > 0) {
        # explicit external link [[name:slug]]
        en = substr(to, 1, ci - 1); es = substr(to, ci + 1)
        kind = "external"
        if (en in extbyname) {
          if (system("test -f '\''" extbyname[en] "/" es ".md'\''") != 0) broken = 1
        } else if (en in extmissing) broken = 0   # unverifiable; soft EXTBASE finding covers it
        else broken = 1                            # unknown base name
      }
      else if (!(to in nrel)) {
        broken = 1; kind = "link"
        if (!(to in extseen)) {
          extfound[to] = 0
          for (x = 1; x <= extc; x++)
            if (system("test -f '\''" extpath[x] "/" to ".md'\''") == 0) { extfound[to] = 1; break }
          extseen[to] = 1
        }
        if (extfound[to]) { broken = 0; kind = "external" }
      }
      else if (anc != "") {
        if (substr(anc, 1, 1) == "^") { if (!((to "\t" anc) in blocks)) broken = 1 }
        else                          { if (!((to "\t" slug(anc)) in heads)) broken = 1 }
      }
      printf "EDGE\t%s\t%s\t%s\t%s\t%d\n", efrom[i], to, anc, kind, broken
    }
    # FILEREF records (existence via test -f)
    for (i = 1; i <= fc; i++) {
      full = BASE "/" (fdir[i] == "" ? fpath[i] : fdir[i] "/" fpath[i])
      ex = (system("test -f '\''" full "'\''") == 0) ? 1 : 0
      printf "FILEREF\t%s\t%s\t%d\n", ffrom[i], fpath[i], ex
    }
    # INDEXROW records
    for (i = 1; i <= irc; i++)
      printf "INDEXROW\t%s\t%s\t%d\t%s\n", irfile[i], irtgt[i], (irtgt[i] in allmd) ? 1 : 0, irhook[i]
    # THEME records (union of themes with nodes and themes listed in KB.md)
    # fields: name  in_kb  has_nodes  has_index
    for (t in themenodes) if (!(t in kbtheme))
      printf "THEME\t%s\t0\t1\t%d\n", t, ((t "/INDEX.md") in allmd) ? 1 : 0
    for (t in kbtheme)
      printf "THEME\t%s\t1\t%d\t%d\n", t, (t in themenodes) ? 1 : 0, ((t "/INDEX.md") in allmd) ? 1 : 0
    # INBOX records
    for (i = 1; i <= bc; i++) printf "INBOX\tblocked\t%s\n", btext[i]
    # COLLIDE records: duplicate basenames (slug bound to the first sorted file)
    for (i = 1; i <= cc; i++) printf "COLLIDE\t%s\t%s\t%s\n", colid[i], colfirst[i], coldup[i]
    # EXTBASE records: configured external bases and their reachability
    for (i = 1; i <= extc; i++) printf "EXTBASE\t%s\t%s\t1\n", extname[i], extpath[i]
    for (n in extmissing)       printf "EXTBASE\t%s\t%s\t0\n", n, extmissing[n]
  }
  ' | LC_ALL=C sort
}

if [ "$MODE" = "tsv" ]; then
  emit_tsv
  exit 0
fi

# JSON mode: assemble from TSV (stage 2)
emit_tsv | LC_ALL=C sort -t"$(printf '\t')" -k1,1 -s | awk -F"\t" '
  function jesc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, " ", s); return s }
  function csvarr(s,   n, a, i, out) {
    if (trimmed(s) == "") return "[]"
    n = split(s, a, ","); out = "["
    for (i = 1; i <= n; i++) { gsub(/^[ \t]+|[ \t]+$/, "", a[i]); out = out (i > 1 ? "," : "") "\"" jesc(a[i]) "\"" }
    return out "]"
  }
  function flagsobj(s,   n, a, i, k, v, p, out) {
    if (trimmed(s) == "") return "{}"
    n = split(s, a, ","); out = "{"
    for (i = 1; i <= n; i++) {
      gsub(/^[ \t]+|[ \t]+$/, "", a[i]); p = index(a[i], "=")
      if (p > 0) { k = substr(a[i], 1, p - 1); v = substr(a[i], p + 1) } else { k = a[i]; v = "" }
      out = out (out == "{" ? "" : ",") "\"" jesc(k) "\":\"" jesc(v) "\""
    }
    return out "}"
  }
  function trimmed(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  $1 == "NODE" {
    nodes = nodes (nodes == "" ? "" : ",\n    ") \
      "{\"id\":\"" jesc($2) "\",\"theme\":\"" jesc($3) "\",\"file\":\"" jesc($4) "\",\"adopted\":" ($5 == 1 ? "true" : "false") \
      ",\"type\":\"" jesc($8) "\",\"tags\":" csvarr($10) ",\"flags\":" flagsobj($9) ",\"description\":\"" jesc($11) "\"}"
  }
  $1 == "EDGE" {
    edges = edges (edges == "" ? "" : ",\n    ") \
      "{\"from\":\"" jesc($2) "\",\"to\":\"" jesc($3) "\",\"anchor\":" ($4 == "" ? "null" : "\"" jesc($4) "\"") ",\"broken\":" ($6 == 1 ? "true" : "false") ",\"external\":" ($5 == "external" ? "true" : "false") "}"
  }
  END {
    printf "{\n  \"nodes\": [\n    %s\n  ],\n  \"edges\": [\n    %s\n  ]\n}\n", nodes, edges
  }
'

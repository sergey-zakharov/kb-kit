- What counts as a node here: **one source material** (interview, article,
  podcast episode, thread) = one file. Facts extracted from it live in other
  themes and cite back here.
- Node type: `source` (required frontmatter: `name`, `description`, `type`,
  `tags`; recommended: publication date in the slug).
- File naming: `YYYY-MM-DD_<outlet>_<guest-or-title>.md` — date of publication;
  if unknown, file without prefix and record "date: unknown, to find" in the body.
- Body structure:
  1. header: publication date, processing date, format, author/host, guest, link;
  2. **TL;DR** — the single most valuable thing for us;
  3. quotes with locators (timecode/section), each on its own line ending with
     a block anchor: `"quote" (14:20) ^q1` — this is what makes the source
     citable at fact level;
  4. `Feeds:` — `[[links]]` to the nodes this source fed;
  5. open questions.
- Raw artifacts (audio, screenshots) live next to the file and are cited with
  plain relative links.

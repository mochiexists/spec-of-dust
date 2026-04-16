status: done

# Embed JSONL data in viewer HTML

## What
Make the log viewer work by embedding the JSONL data directly inside the HTML file, so it renders immediately when opened from any context (file://, GitHub Pages, anywhere). Add a bash script that reads `devlog.jsonl` and `flowlog.jsonl` and rebuilds `docs/viewer.html` with the data baked into a `<script>` block. Keep the drop zone as a fallback for loading external files.

## Acceptance criteria
- [ ] `scripts/build-viewer.sh` reads `.spec/devlog.jsonl` and `.spec/flowlog.jsonl`, JSON-escapes the content safely (handling `</script>`, quotes, backslashes, line separators), and replaces the data block in `docs/viewer.html`
- [ ] `docs/viewer.html` renders embedded data on page load without any fetch or file input
- [ ] The drop zone remains as a secondary input method — dropping files replaces the embedded data
- [ ] The failed auto-fetch code is removed
- [ ] The viewer has the same layout and styles as the current version
- [ ] `devlog.sh` and `flowlog.sh` call `build-viewer.sh` after appending, so the viewer stays fresh

## Notes
- The build script should be idempotent — running it twice produces the same output
- Use a marker comment in the HTML to delimit the embedded data block so the script can find and replace it
- The embedded data should be two JS variables: `EMBEDDED_DEVLOG` and `EMBEDDED_FLOWLOG`, each a JSON-encoded array of raw JSONL strings
- `docs/viewer.html` is both template and output — the data block between marker comments is the only replaced section
- The build script must handle `</script>` in JSONL values by escaping `<\/script>`, and must handle all JSON special chars safely
- The append helpers (`devlog.sh`, `flowlog.sh`) should call `build-viewer.sh` at the end so the viewer is always current

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: spec doesn't say when build-viewer.sh runs — viewer will go stale unless rebuild trigger is explicit.
2. Blocker: raw JSONL in `<script>` is easy to break with `</script>`, quotes, line separators. Require safe escaping and round-trip verification.
3. Contradiction: "visually identical" is too strict since the auto-load text is being removed. Use "same layout/styles."
4. Advisory: "generated file" plus "replace only the data block" is muddled — clarify ownership model.

-> Addressed: append helpers now call build-viewer.sh after each write. Escaping contract made explicit (`</script>`, JSON special chars). "Identical" changed to "same layout and styles." Template ownership clarified — HTML is both template and output, only data block is replaced.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: U+2028/U+2029 line separators not escaped — can break JS string in `<script>`.
2. Blocker: `|| true` masks build-viewer failures — append succeeds but viewer goes stale silently.
3. High: no marker validation — malformed HTML could cause silent no-op or truncation.
4. Medium: embedded parse failures swallowed silently.
5. Advisory: SOD not refreshed.

-> Addressed: added sed escape for U+2028/U+2029. Replaced `|| true` with `if [ -x ]` guard. Added marker count validation with `grep -cF`. SOD refreshed before commit.

## Verify
- [pass] `scripts/build-viewer.sh` reads both JSONL files, escapes backslashes/quotes/`</script>`/U+2028/U+2029, and replaces the data block between markers
- [pass] `docs/viewer.html` renders embedded data immediately on page load — tested by opening the file
- [pass] Drop zone remains visible for loading additional files
- [pass] Auto-fetch code removed — no more `fetch()` calls
- [pass] Layout and styles unchanged from previous version
- [pass] `devlog.sh` and `flowlog.sh` call `build-viewer.sh` after appending — tested with flowlog append

## Closure
- Challenges: awk can't handle multiline string variables — had to write data to temp file and read it back. grep interprets `*` in markers as regex — needed `-F`.
- Learnings: Embedding data in HTML that rewrites itself needs strict marker validation and escape coverage for all JS-breaking characters, not just the obvious ones.
- Outcomes: Viewer loads instantly with baked-in data from any context. Append helpers keep it fresh automatically.
- Dust: The page remembers what the machines felt.

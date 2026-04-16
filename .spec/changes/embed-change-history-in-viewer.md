status: done

# Embed change history in viewer

## What
Extend the log viewer to also display spec change files (from `.spec/changes/` and `.spec/archive/`), with Dust lines given prominent visual treatment. The build script should parse change file markdown, extract key sections (status, what, closure including Dust), and embed them alongside the JSONL data so the viewer shows the full workflow history in one place.

## Acceptance criteria
- [ ] `scripts/build-viewer.sh` also reads `.spec/changes/*.md` and `.spec/archive/*.md` (excluding `_template.md` and `_example-*`), extracts metadata (status, name, closure fields including Dust), and embeds them as `EMBEDDED_CHANGES`
- [ ] The viewer renders change entries in the timeline, sorted by date — archived files use the date prefix from their filename (e.g. `2026-04-14`), active `done` files use the flowlog timestamp if available, non-done active files appear in a separate "Active" section above the timeline
- [ ] Dust lines are visually prominent — styled distinctly from other text, given breathing room
- [ ] Change entries show: name, status, what (first paragraph), and closure summary with Dust highlighted
- [ ] Peer review and verify sections are collapsible details
- [ ] Filter buttons updated to include a "Changes" option alongside Devlog/Flowlog/All
- [ ] Drop zone removed since all data is now embedded — no more file input UI

## Notes
- Change files are markdown — parse with simple line-based bash extraction, not a full markdown parser
- Extracted object shape: `{"name":"...","status":"...","ts":"...","what":"...","dust":"...","challenges":"...","learnings":"...","outcomes":"...","peer_spec_review":"...","peer_code_review":"...","verify":"..."}`
- Extract `status:` from first line, `## What` body as `what`, closure fields from `- Dust:` / `- Challenges:` / etc, and peer review/verify sections as raw text blocks
- For archived files, use the date prefix in the filename (e.g. `2026-04-14-my-feature.md`) as the timestamp
- For active `done` files without a date prefix, try to match the change name in flowlog for a timestamp
- Dust deserves special treatment — it's the human/artistic line. Style as a pull-quote or callout
- Drop zone remains JSONL-only — change history is embedded-only, not loadable via file input
- Keep the timeline unified — changes, flowlog, and devlog entries interleave by date

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: mtime is unstable for active files — every edit reorders history. Need a stable timestamp source.
2. High: parser contract underspecified — no defined extracted object shape, will lead to ad-hoc parsing.
3. High: drop zone only accepts JSONL but changes are markdown — clarify that changes are embedded-only.

-> Addressed: archived files use date prefix, active done files match flowlog timestamps, non-done files go in separate "Active" section. Object shape defined explicitly. Drop zone stays JSONL-only.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: no separate Active section — non-done changes dump to bottom of timeline instead of above it.
2. High: peer review/verify truncated to 200 chars — destroys the record. Show full text in collapsible.
3. High: `what` uses first line, not first paragraph — breaks on hard-wrapped markdown.
4. Medium: closure hidden in collapsible and placeholder values like `- Challenges:` render as truthy.

-> Addressed: active non-done changes now rendered above timeline in "Active Work" section. Review/verify show full text. What uses first paragraph. Closure shown inline with placeholder filtering.

## Verify
- [pass] `build-viewer.sh` reads change files from both directories, excludes template/example files, extracts metadata and closure fields including Dust, and embeds as `EMBEDDED_CHANGES`
- [pass] Archived files sort by date prefix; active done files match flowlog timestamps; non-done active files appear in "Active Work" section above the timeline
- [pass] Dust lines styled as pull-quotes with accent color and breathing room
- [pass] Change entries show name, status badge, what (first paragraph), and inline closure
- [pass] Peer review and verify in collapsible details with full text
- [pass] Filter buttons include "Changes" option
- [pass] Drop zone removed — all data is embedded

## Closure
- Challenges: Skipped the workflow for a mid-build edit (drop zone removal) — had to fold it back into the spec. Bash markdown parser needed careful line-by-line extraction.
- Learnings: The commit gate passes if any change file is active, not if the edit relates to it. Discipline, not hooks, keeps the flow honest.
- Outcomes: The viewer now shows the full project history — changes, flowlog, devlog — with Dust lines front and center.
- Dust: Every spec leaves a fingerprint; now they're all in one window.

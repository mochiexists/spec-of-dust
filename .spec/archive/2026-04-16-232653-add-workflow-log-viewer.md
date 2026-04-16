status: done

# Add workflow log viewer

## What
Add a self-contained HTML file that reads the JSONL log files (`devlog.jsonl`, `flowlog.jsonl`) and renders them in a clean, browsable UI. This gives humans a way to review workflow history, sentiment, and flow feedback without reading raw JSONL. Zero dependencies — one HTML file, inline CSS and JS, reads the logs client-side.

## Acceptance criteria
- [ ] `docs/viewer.html` exists as a single self-contained HTML file with inline CSS and JS
- [ ] The viewer renders both devlog and flowlog entries in a unified timeline, sorted by timestamp
- [ ] Each entry shows: timestamp, source (devlog/flowlog), and all available fields; missing fields (e.g. `agent` on devlog entries) show `—`
- [ ] Sentiment values are visually prominent with colored badges (smooth/rough/blocked)
- [ ] The viewer supports multi-file input (drag-drop or file picker) and infers source type from JSONL structure (`event` field = devlog, `sentiment` field = flowlog)
- [ ] The design is distinctive and polished — not generic bootstrap/tailwind, uses the spec-of-dust visual language from `docs/index.html`
- [ ] No external dependencies — no CDN links, no build step, no framework

## Notes
- Match the color palette and typography from `docs/index.html` (Georgia serif, warm earth tones, `--bg: #f4efe6`, `--accent: #8c4f2f`)
- Sentiment should have visual indicators: smooth = calm, rough = warm/amber, blocked = red
- Flowlog entries should show divergence/friction/suggestion as collapsible details to keep the timeline clean
- Devlog entries are simpler — show kind, summary, reason, file
- Consider a filter toggle to show devlog only, flowlog only, or both
- The viewer reads static JSONL — it doesn't write or modify anything

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: devlog entries have no `agent` or `change` fields — spec requires showing them for every entry. Need fallback behavior.
2. Blocker: Dust lives in change-file closures, not in JSONL logs — drop from scope or add a data source.
3. Risk: file input model unclear — one file or multiple? How is source type inferred?
4. Advisory: "sentiment trends" is vague and overbuilt — just show badges.
5. Advisory: "visual language from index.html" is thin — palette/type only.

-> Addressed: missing fields show `—`, Dust dropped from scope, multi-file input with structure-based type inference, "trends" cut to colored badges.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: not all fields rendered, missing fields don't show `—`. Devlog only showed reason/file, flowlog only showed feedback when truthy.
2. Blocker: source inference only matched `event === "skip-no-verify"` instead of checking for `event` key existence.
3. Medium: drop zone hidden after first load — can't add a second file without refreshing.
4. Advisory: SOD not refreshed.

-> Addressed: all fields now rendered for both types with `—` for missing. Inference uses `"event" in obj`. Drop zone stays visible after loading. SOD refreshed before commit.

## Verify
- [pass] `docs/viewer.html` exists as a single self-contained HTML file with inline CSS and JS (526 lines, no external deps)
- [pass] Renders both devlog and flowlog entries in a unified timeline, sorted newest-first by timestamp
- [pass] Each entry shows all available fields; missing fields (e.g. `agent` on devlog) render as `—`
- [pass] Sentiment badges are colored: smooth (green), rough (amber), blocked (red)
- [pass] Multi-file input via drag-drop or file picker; source type inferred from JSONL structure (`event` key = devlog, `sentiment` key = flowlog); drop zone stays visible for adding more files
- [pass] Design matches spec-of-dust visual language: Georgia serif, warm earth tones, card layout
- [pass] No external dependencies: no CDN, no build step, no framework

## Closure
- Challenges: Security hook flagged innerHTML usage, required refactoring to DOM construction. Codex caught several real spec mismatches in field rendering.
- Learnings: DOM construction is cleaner for dynamic UIs even in vanilla JS — no sanitization worries and the code reads better.
- Outcomes: Humans can now browse workflow logs visually. The warm earth-tone design matches the project identity.
- Dust: The dust settles where you can see it.

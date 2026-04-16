status: done
files: scripts/build-viewer.sh, docs/viewer.html, .spec/changes/fix-viewer-archive-filename-parsing.md

# Fix viewer archive filename parsing

## What
Correct archive filename parsing in `scripts/build-viewer.sh` so timestamped archived change files keep their intended change name and timestamp when embedded into `docs/viewer.html`. Right now the generic archive-name pattern matches first and misparses files like `YYYY-MM-DD-HHMMSS-name.md`.

## Acceptance criteria
- [ ] `scripts/build-viewer.sh` checks `YYYY-MM-DD-HHMMSS-name.md` before `YYYY-MM-DD-name.md`, so timestamped archived changes keep the correct change name and preserve the time chunk in `ts`
- [ ] Rebuilding `docs/viewer.html` shows timestamped archived changes with the correct change name and a `ts` that includes the archived HHMMSS time instead of collapsing to midnight
- [ ] Verification includes a concrete check against an existing timestamped archived change file in this repo

## Notes
- Keep the fix minimal; no viewer redesign

## Peer spec review
**Claude** (2026-04-16):

Spec is clear and the bug is real. The generic archive-name pattern matches first and swallows the HHMMSS chunk into the change name. Main clarifications needed were: this is a match-order fix, and the timestamped form should preserve time in `ts` rather than discarding it. With that pinned down, the change is minimal and appropriately scoped. No blockers.

## Peer code review
**Claude** (2026-04-16):

Verdict: pass, no blockers.

- The timestamped archive pattern now runs before the generic date-only pattern
- `HHMMSS` is correctly split into `HH:MM:SS` for `ts`
- Rebuilt embedded viewer data reflects `2026-04-15T00:51:56Z` for existing timestamped archived changes instead of collapsing them to midnight

Only remaining item was the verify-phase requirement to check against an existing archived file in this repo.

## Verify
- [pass] `scripts/build-viewer.sh` checks `YYYY-MM-DD-HHMMSS-name.md` before `YYYY-MM-DD-name.md`, so timestamped archived changes keep the correct change name and preserve the time chunk in `ts`
  Verified by inspecting the reordered archive-name parsing branches in `scripts/build-viewer.sh`.
- [pass] Rebuilding `docs/viewer.html` shows timestamped archived changes with the correct change name and a `ts` that includes the archived HHMMSS time instead of collapsing to midnight
  Verified by rebuilding the viewer and parsing `EMBEDDED_CHANGES` from `docs/viewer.html`; `final-polish-and-ci` and `merge-and-advance-workflow` now both resolve to `2026-04-15T00:51:56Z`.
- [pass] Verification includes a concrete check against an existing timestamped archived change file in this repo
  Verified against `.spec/archive/2026-04-15-005156-final-polish-and-ci.md` and `.spec/archive/2026-04-15-005156-merge-and-advance-workflow.md` via the rebuilt embedded viewer data.

## Closure
- Challenges: The fix itself was small; the heavier part was proving it against the baked viewer data rather than just eyeballing the bash regex.
- Learnings: Filename parsers should match the most specific pattern first, especially in bash where one loose branch can swallow the whole namespace.
- Outcomes: Timestamped archived changes now keep both the right name and the right HHMMSS-derived timestamp in the viewer.
- Dust: The archive kept the time once we asked correctly.

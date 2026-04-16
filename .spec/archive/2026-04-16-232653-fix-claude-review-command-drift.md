status: done
files: CLAUDE.md, .spec/changes/fix-claude-review-command-drift.md

# Fix Claude review command drift

## What
Align `CLAUDE.md` with `.spec/FLOW.md` so the documented Claude-side peer-review command matches the current Codex CLI invocation. `.spec/FLOW.md` is the source of truth; this change makes `CLAUDE.md` conform to it. This removes process drift in a workflow that depends on the cross-model review step working reliably.

## Acceptance criteria
- [ ] `CLAUDE.md` documents the same Codex review command family as `.spec/FLOW.md`
- [ ] The Claude-specific guidance remains concise and does not add new workflow rules beyond the command correction
- [ ] Repo metrics are refreshed after the doc change

## Notes
- This is a documentation alignment fix, not a workflow redesign
- Full restructuring of the Claude-side review guidance to mirror FLOW's two-phase examples is out of scope unless the current line must change to stay accurate

## Peer spec review
**Claude** (2026-04-16):

Clear and well-scoped. The drift is real: `CLAUDE.md` says `codex -q` while `.spec/FLOW.md` says `codex exec`. Main clarification needed was source of truth; this spec now makes `.spec/FLOW.md` authoritative. Follow-up note: broader restructuring of Claude guidance could happen later, but is not required for this fix. No blockers.

## Peer code review
**Claude** (2026-04-16):

Verdict: pass, no blockers.

- `CLAUDE.md` now uses `codex exec`, matching `.spec/FLOW.md`
- The diff is minimal and does not add new workflow rules

Advisory only: the broader two-phase review examples in `.spec/FLOW.md` are still richer than the short Claude note, but that is pre-existing and out of scope. SOD refresh still needs to be staged before commit.

## Verify
- [pass] `CLAUDE.md` documents the same Codex review command family as `.spec/FLOW.md`
  Verified by `rg -n 'codex exec' CLAUDE.md .spec/FLOW.md`, which now shows `codex exec` in both files.
- [pass] The Claude-specific guidance remains concise and does not add new workflow rules beyond the command correction
  Verified by the one-token documentation change in `CLAUDE.md`.
- [pass] Repo metrics are refreshed after the doc change
  Verified during final batch closeout by running `bash scripts/update-sod-report.sh` after the doc and workflow-state updates.

## Closure
- Challenges: The bug was tiny, but it mattered because this repo depends on documented peer-review commands being correct.
- Learnings: Process docs drift in exactly the places nobody expects to re-check; the safest fix is to keep one file authoritative and make adapters conform to it.
- Outcomes: `CLAUDE.md` now matches `.spec/FLOW.md` on the Codex review command, removing an avoidable peer-review failure path.
- Dust: One token less wrong, one trap less waiting.

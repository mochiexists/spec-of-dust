status: verify
files: .spec/changes/clean-up-setup-sod-wording.md, setup.sh, README.md, .spec/sod-report.md, docs/viewer.html

# Clean up setup sod wording

## What
Tighten the remaining user-facing wording drift in `setup.sh` before release. The setup output should match the current archive lifecycle language and use lowercase `sod`, so the repo's primary onboarding surface no longer contradicts the documented workflow.

## Acceptance criteria
- [ ] `setup.sh` describes `post-merge` as staging archive closeout after plain merges rather than archiving completed changes directly
- [ ] `setup.sh` uses lowercase `sod` in its repo-metrics guidance so the live setup surface matches the rest of the repo terminology
- [ ] Generated repo metrics artifacts are refreshed for the final tree and local validation still passes after the wording cleanup

## Notes
- Keep this narrow: only fix the live setup surface and the generated artifacts that must move with it
- Do not broaden this into release automation or a version bump; the goal is release-surface consistency
- `README.md` and `docs/viewer.html` are in scope only as generated artifacts that may change when the repo metrics and workflow logs refresh

## Peer spec review
**Claude** (2026-04-17):

Verdict: no blockers.

1. Pin criterion 1 to the exact archive-closeout meaning instead of leaving the replacement wording implicit.
2. Criterion 2 is straightforward: `SOD` in `setup.sh` should become lowercase `sod`.
3. `README.md` and `docs/viewer.html` are acceptable in `files:` if they only move as generated artifacts under criterion 3.
4. Advisory: closure is still placeholder text and should be finalized at `done`.

Addressed:

- criterion 1 now says `post-merge` stages archive closeout after plain merges
- the notes now state that `README.md` and `docs/viewer.html` are generated-artifact scope only


## Peer code review
**Claude** (2026-04-17):

Verdict: pass, no blockers.

1. Criterion 1 passes: `setup.sh` now says `post-merge: stages archive closeout after plain merges`.
2. Criterion 2 passes: `SOD flow` is now lowercase `sod flow`.
3. Criterion 3 passes: `.spec/sod-report.md`, `README.md`, and `docs/viewer.html` were refreshed and now reflect the new change file plus the `setup.sh` wording edits.

Advisory only:

- `docs/viewer.html` changed only because embedded generated data refreshed
- the closure section still needs final text before `status: done`


## Verify
- [pass] `setup.sh` describes `post-merge` as staging archive closeout after plain merges rather than archiving completed changes directly
  Verified by the updated setup output string in `setup.sh`.
- [pass] `setup.sh` uses lowercase `sod` in its repo-metrics guidance so the live setup surface matches the rest of the repo terminology
  Verified by the updated `sod flow` string in `setup.sh` and by a repo-wide search of live surfaces showing no remaining uppercase `SOD` wording outside historical records.
- [pass] Generated repo metrics artifacts are refreshed for the final tree and local validation still passes after the wording cleanup
  Verified by refreshed `README.md`, `.spec/sod-report.md`, and `docs/viewer.html`, plus passing `bash tests/test-spec-gate.sh` and `bash tests/test-workflow-scripts.sh`.

## Closure
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: The label finally matches the work.

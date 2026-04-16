status: done
files: .githooks/_spec_gate.sh, tests/test-spec-gate.sh, .spec/FLOW.md, .spec/changes/require-commit-after-done.md, .spec/flowlog.jsonl, .spec/sod-report.md, README.md, docs/viewer.html

# Require commit after done

## What
Enforce that once a standard change reaches `status: done`, it must be committed before more work proceeds. Right now the workflow relies on convention: a change can be marked `done` and then sit in the working tree while more edits accumulate. That weakens backlog discipline and makes it easy to batch unrelated completed changes into one commit. Add a local gate so a dirty `done` change blocks further normal commits until the repo records it.

## Acceptance criteria
- [ ] `.spec/FLOW.md` states that after a change reaches `done`, the next step is to commit it before starting or batching further standard work unless the human explicitly requests batching
- [ ] `.githooks/_spec_gate.sh` blocks normal commits when there is an uncommitted `done` change file in `.spec/changes/` and dirty work extends beyond that completed change's closeout artifacts
- [ ] The gate message tells the user to commit the completed change first, or explicitly archive/merge it, instead of continuing to stack work
- [ ] `tests/test-spec-gate.sh` covers at least one blocked case where a `done` change file and additional work are committed together, and one allowed case where the commit is just recording that completed change and its closeout artifacts
- [ ] The gate blocks multiple dirty `done` changes at once so backlog items cannot be closed out in one bundled commit by accident

## Notes
- Keep the rule local and mechanical; this is about commit discipline, not editor-time policing
- Closeout artifacts for a `done` commit are limited to the completed change file itself plus `.spec/flowlog.jsonl`, `.spec/sod-report.md`, `README.md`, and `docs/viewer.html`
- `.spec/` paths remain exempt from the scope gate, so the closeout commit should not fight the existing `files:` scoping rule
- The rule should not require auto-committing or auto-merging; it only blocks stacking more work on top of an uncommitted completed change

## Peer spec review
**Claude** (2026-04-16):

Good scope and mechanically checkable criteria. Main ambiguities were what counts as "additional work" and what happens if multiple `done` changes pile up. Addressed by defining the allowed closeout artifact set and by explicitly blocking multiple dirty `done` changes at once. No blockers.

## Peer code review
**Claude** (2026-04-16):

All five acceptance criteria are covered. `.spec/FLOW.md` now states the closeout rule, the gate blocks dirty `done` changes plus extra work, the messages are clear, tests cover blocked and allowed cases, and multiple dirty `done` changes are blocked.

Notes:
- `collect_dirty_done_changes` correctly keys off dirty tracked files, so staged-but-uncommitted `done` changes are caught
- The allowlist uses literal repo-relative paths, which is fine because the git commands here return that form
- No blockers; only nit was that Closure should be completed later during verify/done, not earlier

## Verify
- [pass] `.spec/FLOW.md` states that after a change reaches `done`, the next step is to commit it before starting or batching further standard work unless the human explicitly requests batching
  Verified in the `done` state steps and gate list in `.spec/FLOW.md`.
- [pass] `.githooks/_spec_gate.sh` blocks normal commits when there is an uncommitted `done` change file in `.spec/changes/` and dirty work extends beyond that completed change's closeout artifacts
  Verified by the new done-closeout gate helpers in `.githooks/_spec_gate.sh` and by the blocked test case for a dirty `done` change plus additional work.
- [pass] The gate message tells the user to commit the completed change first, or explicitly archive/merge it, instead of continuing to stack work
  Verified in the `enforce_done_closeout_gate()` failure messages for both single-done and multi-done cases.
- [pass] `tests/test-spec-gate.sh` covers at least one blocked case where a `done` change file and additional work are committed together, and one allowed case where the commit is just recording that completed change and its closeout artifacts
  Verified by `done_change_with_additional_work_is_blocked()` and `done_change_commit_passes()`.
- [pass] The gate blocks multiple dirty `done` changes at once so backlog items cannot be closed out in one bundled commit by accident
  Verified by `multiple_done_changes_are_blocked()`.

Additional verification:

- [pass] Full hook regression suite still passes
  Ran `bash tests/test-spec-gate.sh` successfully after implementing the new gate.

## Closure
- Challenges: The main friction was test-fixture realism. The first pass failed because SOD and done-closeout behavior depend on index state, not just file contents.
- Learnings: A `done` state without a commit boundary is too soft. The hook needed to reason about dirty worktree plus index state, not only staged files, to actually stop stacking work.
- Outcomes: The workflow now mechanically blocks piling new work on top of an uncommitted completed change, and it blocks multiple dirty `done` changes from being closed out together by accident.
- Dust: Done now means land it, not leave it lying around.

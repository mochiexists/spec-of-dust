status: done
files: .spec/changes/validate-done-closeout-gate.md, .spec/flowlog.jsonl, .spec/sod-report.md, README.md, docs/viewer.html

# Validate done-closeout gate

## What
Validate the new done-closeout workflow rule by recreating the old batching mistake in a disposable test repo and confirming the current hooks block it. This is a workflow-validation change, not a product behavior change: the deliverable is recorded evidence in this change file that the mistake is reproducible and correctly rejected now.

## Acceptance criteria
- [ ] A disposable repo fixture is created from the current workspace so the validation does not disturb the main repo state
- [ ] The validation reproduces the old mistake shape: one or more change files reach `status: done`, additional standard work is stacked on top, and a normal commit is attempted
- [ ] The attempted commit is blocked by the current hook policy with a message attributable to the done-closeout rule
- [ ] The validation steps and observed result are recorded in this change file with enough detail to repeat manually

## Notes
- No workflow implementation changes are planned here unless the validation reveals a gap
- The disposable fixture method is: rsync the current workspace into a temp directory, initialize a fresh Git repo there, set `core.hooksPath` to `.githooks`, then reproduce the mistake inside that isolated repo
- If the gate does not block as expected, record the gap here and promote it to a new fix change instead of silently proceeding
- Use the normal peer-review protocol even though this is primarily a validation run

## Validation run

Disposable fixture method used:

1. `rsync -a --exclude '.git' ./ "$repo/"` into a temp directory
2. `git init`, set test user identity, and enable local hooks with `git config core.hooksPath .githooks`
3. Delete existing real change files from `.spec/changes/`, commit that isolated fixture state, then create two new dirty change files in `status: done`
4. Stage both `done` change files and attempt a normal commit with `git commit -m 'test: batch multiple done changes'`

Observed result:

- Commit exit code: `1`
- The hook blocked the commit with this message:

```text
⚠️  Multiple completed changes are still uncommitted:

   .spec/changes/first-change.md
   .spec/changes/second-change.md

Commit one completed change at a time before continuing more work.
If you truly need batching, handle it as an explicit workflow exception.
```

Interpretation:

- This reproduces the earlier batching mistake shape closely enough to validate the rule: multiple completed backlog items were left dirty and a normal commit was attempted
- The current hook policy rejected it for the done-closeout reason rather than allowing the accidental batch through

## Peer spec review
**Claude** (2026-04-16):

Clear and well-scoped. Main clarifications needed were fixture method and failure handling. This spec now pins the disposable fixture to a temp copied repo with fresh Git history and local hooks, and it says that any validation gap becomes a follow-up fix change rather than an ignored anomaly. No blockers.

## Peer code review
**Claude** (2026-04-16):

No blockers. The validation run section satisfies all four acceptance criteria: disposable fixture method, reproduction of the batching mistake shape, blocked commit with exit code `1`, and repeatable recorded evidence. Advisory only: this validation exercised the multi-`done` path, not the single-`done` plus extra work path, but that path is already covered by the repo-local gate tests.

## Verify
- [pass] A disposable repo fixture is created from the current workspace so the validation does not disturb the main repo state
  Verified by the recorded rsync-to-temp plus fresh `git init` fixture method in `## Validation run`.
- [pass] The validation reproduces the old mistake shape: one or more change files reach `status: done`, additional standard work is stacked on top, and a normal commit is attempted
  Verified by the disposable repo sequence that staged two dirty `done` change files and attempted a normal commit, matching the accidental batch-close backlog pattern.
- [pass] The attempted commit is blocked by the current hook policy with a message attributable to the done-closeout rule
  Verified by commit exit code `1` and the recorded hook message beginning `Multiple completed changes are still uncommitted`.
- [pass] The validation steps and observed result are recorded in this change file with enough detail to repeat manually
  Verified in `## Validation run`, which records the fixture method, numbered steps, exit code, and the exact rejection message.

Additional verification:

- [pass] Required post-build peer review completed with no blockers
  Claude review is recorded in `## Peer code review`.

## Closure
- Challenges: The only false start was a shell-variable name collision in `zsh`; once corrected, the fixture behaved exactly as intended.
- Learnings: The new gate is doing the right thing for the exact mistake we made earlier: multiple completed backlog items left dirty now fail at normal commit time instead of slipping through.
- Outcomes: Recreated the accidental batch-close shape in an isolated repo and confirmed the hook blocks it with the done-closeout message and exit code `1`.
- Dust: The workflow caught the footprint we left last time.

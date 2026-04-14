status: done

# Merge and advance workflow

## What
Extend `spec-of-dust` so merge behavior is an explicit part of completion, with a small startup config that decides whether completed work waits for a human, asks for confirmation, or merges automatically. Keep the main state machine simple, but add a shared archive script and a merge helper so agents can finish one work package, merge it when appropriate, archive the completed change file, and move on cleanly.

## Acceptance criteria
- [ ] `.spec/FLOW.md` documents merge behavior after `done`, including `merge: manual | confirm | auto` and `merge-target: <branch>` as startup config values, with `main` as the default target when omitted
- [ ] `.spec/b-startup.md` includes a live merge configuration for this repo
- [ ] A shared archive script exists in `scripts/` and the existing `post-merge` hook delegates to it instead of carrying separate archive logic
- [ ] A repo-local merge helper exists in `scripts/`, calls the shared archive script, and can either archive completed changes on the current target branch or merge a completed feature branch into the configured target branch
- [ ] The merge helper refuses unsafe states: missing Git repo, dirty working tree, no completed standard change file to archive/advance, or unmet local-gate prerequisites for an `auto` merge
- [ ] The flow defines `confirm` as an explicit ask-to-merge step, and on merge failure the change remains `done` while the error is reported without inventing a new state
- [ ] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end

## Notes
- Keep the core state machine at `spec -> build -> verify -> done`; merge happens after `done` as a completion action
- `manual` means stop at `done`
- `confirm` means ask the human before invoking the merge helper; if the answer is no, stay at `done`
- `auto` means the agent may invoke the merge helper directly once verify is complete, local gates have passed, and the repo is in a safe state
- Do not auto-delete branches in this first pass
- The helper should be safe on `main` too: if already on the merge target, it should archive done changes and optionally commit them rather than trying to merge the branch into itself
- `FLOW.md` should define the meaning of the merge modes; `.spec/b-startup.md` should only hold the live values
- On merge failure, leave the change in `done` and report the error; do not invent a new workflow state in this pass

## Peer spec review
Summary for review: add explicit merge-and-advance behavior after `done`, with `merge: manual | confirm | auto` plus `merge-target`, a shared archive script, and a safe merge helper that can archive or merge completed work without changing the core four-state workflow.

Claude review:

- `confirm` needed an explicit ask/deny behavior
- the failure story needed to say what happens if merge fails
- the archive script versus merge-helper boundary needed to be explicit
- `merge-target` needed a default
- `auto` should be tied to passing local gates, not just a clean tree

Valid feedback addressed:

- `confirm` now explicitly asks and stays at `done` if the answer is no
- merge failures now leave the change at `done` and report the error
- the merge helper is now explicitly defined as a caller of the archive script
- `merge-target` defaults to `main`
- `auto` now requires passed local gates as well as a safe repo state

## Peer code review
Claude review:

- no blocker remained in the final diff
- advisory notes were about whether `update-sod-report.sh --check` existed, restoring branch context on failure, and the absence of dedicated tests for the new scripts

Resolution:

- `update-sod-report.sh --check` already existed and is now used explicitly by `--auto`
- the merge helper now reports the branch on failure instead of failing silently
- merge behavior was verified in temp repos for archive-on-target, archive+merge-from-feature, dirty-tree refusal, and stale-SOD refusal in `--auto`

## Verify
- [pass] `.spec/FLOW.md` documents merge behavior after `done`, including `merge: manual | confirm | auto` and `merge-target: <branch>` as startup config values, with `main` as the default target when omitted
  `FLOW.md` now defines the merge modes, the default target, the explicit confirm behavior, and the failure behavior without adding a new workflow state.
- [pass] `.spec/b-startup.md` includes a live merge configuration for this repo
  The live boot brief now includes `merge: confirm` and `merge-target: main`.
- [pass] A shared archive script exists in `scripts/` and the existing `post-merge` hook delegates to it instead of carrying separate archive logic
  `scripts/archive-done-changes.sh` now owns the archive behavior, and `.githooks/post-merge` delegates to it.
- [pass] A repo-local merge helper exists in `scripts/`, calls the shared archive script, and can either archive completed changes on the current target branch or merge a completed feature branch into the configured target branch
  `scripts/merge-completed-work.sh` archives on the target branch and performs archive+`--no-ff` merge from feature branches.
- [pass] The merge helper refuses unsafe states: missing Git repo, dirty working tree, no completed standard change file to archive/advance, or unmet local-gate prerequisites for an `auto` merge
  Temp-repo verification showed dirty-tree refusal and `--auto` refusal when SOD was stale; the helper also checks for a Git repo and requires at least one `done` change file.
- [pass] The flow defines `confirm` as an explicit ask-to-merge step, and on merge failure the change remains `done` while the error is reported without inventing a new state
  `FLOW.md` now defines the ask/deny behavior for `confirm`, and the helper reports failure without mutating workflow state.
- [pass] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end
  This change file now contains the full review/verify record and the final SOD refresh happens before the closing commit.


## Closure
- Challenges: The merge helper only became honest once it learned the repo’s own SOD rules and stopped assuming archive commits were exempt from them.
- Learnings: Completion automation in a self-hosting workflow repo needs to respect the same gates it asks every other repo to respect.
- Outcomes: Merge behavior is now explicit, configurable, and scripted, with a shared archive path, a merge helper, and clear `manual`/`confirm`/`auto` semantics.
- Dust: A workflow starts feeling real when it can close its own loops.

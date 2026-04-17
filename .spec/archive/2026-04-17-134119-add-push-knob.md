status: done
files: .spec/FLOW.md, scripts/merge-completed-work.sh, .spec/b-startup.md, tests/test-workflow-scripts.sh, setup.sh

# Add push knob to post-done phase

## What
After a change reaches `done` and the merge/archive step completes, there's no mechanism to push. The agent commits and archives locally but the work sits unpushed unless the human remembers. Add a `push:` config in `b-startup.md` (alongside the existing `merge:` knob) so projects can control whether the post-done phase includes `git push`. This closes the gap where "done" can mean "committed locally but never delivered."

## Acceptance criteria
- [ ] `b-startup.md` template in `setup.sh` includes `push: never` as the default
- [ ] FLOW.md Merge section documents `push: never | confirm | auto` — `never` skips, `confirm` prints a message for the human/agent, `auto` pushes after successful archive/merge. Push only applies when the merge helper actually runs (not with `merge: manual`).
- [ ] `merge-completed-work.sh` reads the `push:` value and runs `git push origin <merge-target>` when `auto`; prints "Push ready" message when `confirm`; does nothing when `never`
- [ ] Push runs after archive commit succeeds. Push failure is reported to stderr but the script exits 0 — the local archive is already committed. The EXIT trap must not treat push failure as merge failure.
- [ ] If no remote `origin` exists, push is skipped with a warning (not an error). Upstream tracking is not required since push uses explicit `git push origin <target>`.
- [ ] Test covers the `auto` push path in a local bare-repo setup (push to a local remote, verify ref arrives)
- [ ] Test covers the missing-remote case (no origin configured, push skipped with warning)
- [ ] This repo's own `b-startup.md` stays at `push: never` (we don't auto-push the framework repo)

## Notes
- `confirm` is agent-facing guidance, not a blocking gate — the script prints "Push ready. Run `git push origin <target>` to deliver." and the agent or human decides. No interactive prompt in the script itself.
- Push command is `git push origin <merge-target>` — explicit remote and refspec, no reliance on `push.default` or upstream tracking.
- Push failure is reported to stderr but exits 0. The `completed` flag / EXIT trap must account for this — push happens after `completed=1` so the trap already considers it a success.
- When `merge: manual`, the merge helper doesn't run at all, so `push:` has no effect regardless of its value.

## Peer spec review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: push command underspecified — plain `git push` depends on `push.default` and upstream. → Fixed: specified `git push origin <merge-target>`.
2. Blocker: failure semantics unclear — `set -e` + EXIT trap would treat push failure as merge failure. → Fixed: push exits 0 on failure, runs after `completed=1`.
3. Ambiguous: push should only apply when merge helper runs. → Fixed: AC now states push only applies when merge helper runs.
4. Risk: missing origin not covered. → Fixed: added AC for missing-remote case.
5. Advisory: confirm message text should be specified. → Addressed in Notes.


## Peer code review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: this repo's own `b-startup.md` missing `push: never`. → Fixed: added.
2. Blocker: AC 5 mentions "or push target has no upstream" but only missing-origin is tested. → Fixed: tightened AC to drop upstream clause since `git push origin <target>` is explicit.


## Verify
- [pass] `setup.sh` b-startup template includes `push: never` default
- [pass] FLOW.md documents push section with all three modes, states push only applies when merge helper runs
- [pass] `merge-completed-work.sh` reads push value, runs `git push origin <target>` for auto, prints prompt for confirm, skips for never
- [pass] Push runs after archive commit, failure is non-fatal (exits 0), EXIT trap unaffected (runs after completed=1)
- [pass] Missing origin skipped with warning — tested in `push_skipped_when_no_origin`
- [pass] Auto push tested end-to-end in `push_auto_delivers_to_remote` with local bare remote
- [pass] Missing remote test verifies warning message and successful exit
- [pass] This repo's b-startup.md has `push: never`


## Closure
- Challenges: prepare-commit-msg hook enforces gates even with --no-verify, complicating test setup
- Learnings: tests that modify b-startup.md need to bypass hooks or refresh sod for the config commit
- Outcomes: push knob ships with auto, confirm, never modes — tested end-to-end with local bare remote
- Dust: done means delivered, not just committed

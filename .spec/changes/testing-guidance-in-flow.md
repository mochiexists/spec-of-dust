status: build
files: .spec/FLOW.md, setup.sh, tests/test-workflow-scripts.sh

# Add testing guidance to flow and bootstrap

## What
The flow defines acceptance criteria and verify steps but gives no guidance on *how* to test — no test-first for bug fixes, no rule against patching test logic to force green, and no bootstrap-time test audit. This means agents can write ACs that sound testable but never become actual tests, or worse, fix test assertions instead of fixing code. Add lightweight testing guidance to FLOW.md and a test-readiness check to `setup.sh` bootstrap.

## Acceptance criteria
- [ ] FLOW.md has a standalone `## Testing` section (under 15 lines) with test-first rule for bug fixes: write a failing test, fix the code, observe green without editing test logic
- [ ] Testing section includes general steer: ACs describing observable behavior should have a corresponding test where a harness exists; if no harness, note that in the change file's Notes
- [ ] Testing section includes the test-integrity rule: updating expectations/fixtures for intentional behavior changes is fine; changing test control flow or assertions to make a test less sensitive is not — that's a new change or the fix is wrong
- [ ] FLOW.md build state references the Testing section
- [ ] `setup.sh` prints a test-readiness advisory: checks for `tests/`, `test/`, and `*.test.*` / `*_test.*` files; prints suggestion if none found (informational only, not blocking)

## Notes
- This is flow guidance, not mechanical gates. Don't add test-running gates to the commit hook — that's project-specific.
- The setup advisory is informational only (print a message), not blocking.
- Keep it framework-appropriate: sod is zero-dependency, so the guidance should be language/tool agnostic.
- The "no sketchy test fix" rule is the key insight: if you have to change test logic to make it pass, either your fix is wrong or that test change is its own change with its own spec.

## Peer spec review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: `setup.sh` advisory heuristic underspecified — should check `tests/`, `test/`, and test scripts, not just language-specific config files. → Addressed: AC updated to list positive signals.
2. Medium: ambiguous placement — "build state" vs "separate section". → Resolved: add a standalone `## Testing` section in FLOW.md, referenced from the build state description. One shape.
3. Medium: "no manual test-logic edits" needs tighter boundary — expectation updates for intentional changes are fine, control-flow changes that weaken the test are the problem. → Addressed: AC wording refined.
4. Advisory: template could hint where "no harness" note goes. → Not adding template changes — the Notes section already covers this. Keeping scope tight.


## Peer code review
**Codex** (2026-04-17, gpt-5.4):

1. Medium: setup.sh advisory untested — should have assertions for both "detected" and "not found" paths. → Fixed: added `setup_detects_test_harness` and `setup_warns_no_test_harness` tests.
2. Low: find heuristic missing `-type f`, could match directories. → Fixed: added `-type f` and grouped predicates.
No blockers. FLOW.md section, build-state reference, and "guidance not gates" wording all approved.


## Verify
<!-- During verify: copy acceptance criteria here, mark pass/fail with notes. -->


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable

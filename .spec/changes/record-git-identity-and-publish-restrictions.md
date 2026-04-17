status: done
files: .spec/changes/record-git-identity-and-publish-restrictions.md, .spec/FLOW.md, .spec/changes/_template.md, .spec/sod-report.md, README.md, docs/viewer.html

# Record git identity and publish restrictions

## What
Add lightweight workflow guidance for Git identity on external-target work. When a change is meant to update a real external repo, site, or deployed system, the spec should be able to name the expected GitHub account or author identity, and whether publishing is restricted to that account or only the human operator. The workflow should also require final reporting to say when implementation is complete locally but push/deploy is blocked by identity or permission.

## Acceptance criteria
- [ ] `.spec/FLOW.md` tells agents to record the expected Git identity for external-target work when the requested outcome depends on a repo, site, or system they may not be authorized to publish to, and to check whether publishing is restricted to a specific account or only the human
- [ ] `.spec/FLOW.md` tells agents not to describe external work as fully complete when the local implementation exists but push/deploy is blocked by identity, permission, or author restrictions
- [ ] `.spec/changes/_template.md` gives authors an optional prompt to note the external target, expected Git identity, and any “only this account” or “human-only” publishing restriction

## Notes
- Keep this lightweight and zero-dependency; this is workflow language, not identity enforcement automation
- The immediate motivating failure mode is “site change is implemented locally, but the repo/account with deploy authority is different”

## Peer spec review
**Claude** (2026-04-17):

Verdict: no blockers.

- tightened criterion 1 so the trigger is concrete instead of subjective
- keep the new language aligned with the existing live-target verification rule rather than duplicating it in a conflicting way
- template prompt should help authors capture how blocked publish authority affects completion language


## Peer code review
**Claude** (2026-04-17):

Verdict: no blockers.

- `FLOW.md` now extends the live-target rule with explicit Git identity and publish-restriction language
- `FLOW.md` now requires plain reporting when local implementation exists but authorized push/merge/deploy did not happen
- `_template.md` now prompts authors to record the expected Git account, author identity, and human-only restriction when relevant
- Advisory only: the full picture is spread across `verify`, `done`, and `Rules for the AI`, which matches the existing pattern but adds a little reading cost


## Verify
- [pass] `.spec/FLOW.md` tells agents to record the expected Git identity for external-target work when the requested outcome depends on a repo, site, or system they may not be authorized to publish to, and to check whether publishing is restricted to a specific account or only the human
  Verified by the new Git-identity language in `verify` and `Rules for the AI`.
- [pass] `.spec/FLOW.md` tells agents not to describe external work as fully complete when the local implementation exists but push/deploy is blocked by identity, permission, or author restrictions
  Verified by the new reporting sentence in `done`.
- [pass] `.spec/changes/_template.md` gives authors an optional prompt to note the external target, expected Git identity, and any “only this account” or “human-only” publishing restriction
  Verified by the added comment in `## Notes`.


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: the only real design risk was turning a simple account/permission note into heavy workflow policy instead of keeping it as reporting discipline
- Learnings: live-target verification is not enough on its own; the workflow also needs to know who is actually allowed to perform the publish step
- Outcomes: external-target specs can now name the expected Git identity and human-only restrictions, and final reporting must say when a local implementation exists but authorized publishing did not happen
- Dust: The key should be named before the door is tried.

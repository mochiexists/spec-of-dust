status: verify
files: .spec/changes/distinguish-advisory-vs-live-delivery.md, .spec/FLOW.md, .spec/changes/_template.md

# Require live-target verification

## What
Tighten `spec-of-dust` so requests for live-site or other external updates cannot be treated as complete without verification against the actual target. The workflow should require specs and verify/final reporting to say whether the requested result was only documented locally or actually implemented and checked on the external repo, site, or deployed system.

## Acceptance criteria
- [ ] `.spec/FLOW.md` explicitly requires live-target verification when the requested outcome is an external repo, site, or deployed-system update and the user expects the real target to change
- [ ] `.spec/FLOW.md` explicitly requires verify, closure, and final reporting to state whether the result was only documented locally or actually implemented and checked on the external target, and to avoid “live/published/delivered” language when that external verification did not happen
- [ ] `.spec/changes/_template.md` prompts authors to record the intended external target and whether completion means “documented locally” or “implemented and verified on the target,” while keeping that prompt optional for internal-only changes

## Notes
- Keep this lightweight and zero-dependency; the fix is workflow language, not a new parser or gate
- The immediate motivating failure mode is “repo note archived as done” being read socially as “the site is now live”
- Internal-only framework changes should not need any new ceremony

## Peer spec review
**Claude** (2026-04-17):

Verdict: no blockers on the earlier draft. User clarification narrowed the intent further: the real requirement is live-target verification for external-update requests, not a broader advisory-vs-implementation taxonomy. This revision follows that narrower direction.


## Peer code review
**Claude** (2026-04-17):

Verdict: no blockers.

- `FLOW.md` now requires live-target verification for external-update requests in both the `verify` state and `Rules for the AI`
- `FLOW.md` now forbids `live`, `published`, and `delivered` language in closure/final reporting when the external target was not actually changed and checked
- `_template.md` now prompts authors to name the external target and whether completion means local documentation or implemented-and-verified target work, while leaving that prompt optional for internal-only changes
- Advisory only: the active change file still has placeholder closure text before `done`, and the `verify` paragraph read a bit dense; both are manageable


## Verify
- [pass] `.spec/FLOW.md` explicitly requires live-target verification when the requested outcome is an external repo, site, or deployed-system update and the user expects the real target to change
  Verified in the `verify` state description and `Rules for the AI`.
- [pass] `.spec/FLOW.md` explicitly requires verify, closure, and final reporting to state whether the result was only documented locally or actually implemented and checked on the external target, and to avoid “live/published/delivered” language when that external verification did not happen
  Verified by the added `done` guidance and the explicit external-target wording in `verify`.
- [pass] `.spec/changes/_template.md` prompts authors to record the intended external target and whether completion means “documented locally” or “implemented and verified on the target,” while keeping that prompt optional for internal-only changes
  Verified by the new optional note in `## Notes` and the `Outcomes` wording update from `delivered result` to `actual verified result`.


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: A note is not the site.

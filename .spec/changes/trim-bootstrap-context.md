status: done
files: .spec/FLOW.md, .spec/b-startup.md, VERSION

# Trim bootstrap context to 3k target

## What
FLOW.md is 3,246 tokens — 96% of the bootstrap budget. Review every section for redundancy, verbosity, and over-specification. Trim to hit the 3k bootstrap target without losing any behavioral rules. This is about saying the same things in fewer words, not removing capabilities.

## Acceptance criteria
- [ ] Bootstrap SOD drops to 3,000 tokens or below as measured by `bash scripts/update-sod-report.sh --stdout-summary`
- [ ] No behavioral rules are removed — every state, gate, review step, and AI rule survives
- [ ] Peer review prompts are shortened (they're the longest single blocks)
- [ ] Skip protocol is tightened — the "hard boundaries" section repeats the protocol
- [ ] Redundant phrasing across sections is collapsed (e.g. "before setting status to done" appears in multiple places)
- [ ] `b-startup.md` is reviewed but likely already minimal at 131 tokens

## Notes
- Current bootstrap: 3,377 tokens (FLOW.md 3,246 + b-startup.md 131)
- Need to cut ~380 tokens from FLOW.md — roughly 25-30 lines
- The peer review prompts are ~100 words each (x4 = 400 words). These can shrink to ~60 words each
- The "Rules for the AI" section repeats guidance from earlier sections — deduplicate
- The closure/flowlog/done transition has grown organically and can be tightened
- Don't sacrifice clarity for brevity — if a shorter version is ambiguous, keep the longer one
- Must preserve skip disqualifiers verbatim in meaning: add/delete/rename, multiple code files, more than a handful of lines, "if unsure it does not qualify"
- Must preserve peer review constraints: limited context scope, prioritize this change, broader critiques advisory unless blocker, word cap

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: 3k pass/fail not pinned to a measurement method — pin to SOD report output.
2. Risk: skip disqualifiers could drift during tightening — preserve them explicitly.
3. Risk: peer review constraints could weaken during prompt shortening — preserve meaning.

-> Addressed: measurement pinned to SOD output. Skip disqualifiers and review constraints added as explicit preservation requirements.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: peer review prompts gutted to "Blockers only" — lost advisory/context constraints.
2. Blocker: b-startup.md read changed from conditional to unconditional — behavior change.
3. High: "Don't skip the review" instruction dropped.
4. High: "Do not auto-delete branches" safety rule removed.

-> All four restored.

## Verify
- [pass] Bootstrap SOD: 1,638 / 3,000 — well under target (was 3,377)
- [pass] All behavioral rules preserved: states, gates, review protocol, skip disqualifiers, merge safety, branch protection
- [pass] Peer review prompts shortened but retain: limited context, prioritize this change, advisory-unless-blocker, word cap
- [pass] Skip disqualifiers preserved: add/delete/rename, multi-file, handful-of-lines, "if unsure it does not qualify"
- [pass] Redundant phrasing collapsed — Rules for AI no longer duplicates done-state and skip sections
- [pass] b-startup.md unchanged at 131 tokens

## Closure
- Challenges: First pass cut too aggressively — Codex caught 4 dropped rules. The peer review prompts were the hardest to shorten without losing constraints.
- Learnings: "Same behavior in fewer words" is harder than it sounds. Every sentence removed needs a check that the behavior it encoded is still stated somewhere.
- Outcomes: Bootstrap dropped from 3,377 to ~1,640 tokens — 51% reduction. Version bumped to 0.1.0. Human-steered mid-build to also address versioning and guidance conventions.
- Dust: The framework shed its weight and kept its spine.

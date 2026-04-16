status: done

# Add workflow feedback log

## What
Add a structured feedback log (`.spec/flowlog.jsonl`) where agents record friction, divergences, and suggestions about the spec-of-dust flow itself when completing a standard change. This gives us a beta-phase signal channel for improving the workflow based on real usage, separate from the feature-level closure summary and the skip-mode devlog.

## Acceptance criteria
- [ ] `.spec/flowlog.jsonl` exists and is initialized (empty or with one seed entry)
- [ ] `.spec/FLOW.md` adds a flowlog step to the `done` transition: after closure is filled but before setting `status: done`, the agent appends one JSONL entry with `ts`, `agent`, `change`, `flow_divergence`, `friction`, `suggestion`, and `sentiment` (smooth|rough|blocked)
- [ ] The AI rules section in `.spec/FLOW.md` mentions the flowlog requirement for standard changes
- [ ] No hook enforcement — guidance only for beta phase
- [ ] `CLAUDE.md` and `CODEX.md` each get one line reminding agents to write a flowlog entry on task close

## Notes
- Keep it lightweight: one JSONL line per completed change
- `"nothing notable"` or empty strings are fine for any field
- Skip-commits already have devlog coverage, so flowlog only applies to standard changes
- Sentiment is a quick gut-check: `smooth`, `rough`, or `blocked`
- This is a beta diagnostic tool — if it proves useless, remove it; if it proves useful, consider hook enforcement later

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: transition ordering is ambiguous — "after closure, before archival" doesn't pin whether flowlog happens before or after `status: done`. If the agent marks done first and appends later, the change can archive without the log entry. Spell out exact order: closure filled, flowlog appended, then status: done.

2. Risk: schema is too weak — no `timestamp`, no `agent`/`model` field. In a repo that explicitly compares Claude vs Codex, that loses obvious diagnostic value.

Advisory: updating CLAUDE.md and CODEX.md is fine but redundant unless very short and pointing back to FLOW.md.

→ Addressed: acceptance criteria now specify "before setting `status: done`" and require `ts` and `agent` fields. CLAUDE.md/CODEX.md updates will be one-liner pointers.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: "any field" blank allowance is too broad — permits empty `ts`, `agent`, `change`, `sentiment`. Limit blank values to free-text fields only.
2. Blocker: `setup.sh` doesn't create `flowlog.jsonl` — downstream repos won't have it after setup.
3. Blocker: SOD outputs not refreshed after tracked text-file changes.
Advisory: README root layout should mention `flowlog.jsonl`.

→ Addressed: narrowed blank allowance to `flow_divergence`/`friction`/`suggestion` only. Added `touch .spec/flowlog.jsonl` to `setup.sh`. Added `flowlog.jsonl` to README layout. SOD will be refreshed before commit.

## Verify
- [pass] `.spec/flowlog.jsonl` exists and is initialized (empty)
- [pass] `.spec/FLOW.md` adds a flowlog step to the `done` transition with correct ordering and required fields (`ts`, `agent`, `change`, `flow_divergence`, `friction`, `suggestion`, `sentiment`)
- [pass] The AI rules section in `.spec/FLOW.md` mentions the flowlog requirement for standard changes
- [pass] No hook enforcement — guidance only, no changes to `_spec_gate.sh`
- [pass] `CLAUDE.md` and `CODEX.md` each have one line pointing to FLOW.md for flowlog

## Closure
- Challenges: Codex caught three valid blockers — ordering ambiguity, schema weakness, and missing setup.sh provisioning. All required rework before verify.
- Learnings: Codex CLI uses `codex exec` not `codex -q` — the FLOW.md prompts need updating for the current Codex CLI API.
- Outcomes: Workflow now has a beta feedback channel. Agents record flow-level friction separately from feature closure. Setup.sh provisions it for downstream repos.
- Dust: The machine learned to talk about how it feels about working.

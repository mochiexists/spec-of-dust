status: build
files: .spec/FLOW.md, .spec/b-startup.md, setup.sh, .gitignore, tests/test-workflow-scripts.sh, docs/dust.html

# Agent-driven sod updates with vibes-based check interval

## What
sod has no update mechanism today — downstream repos drift from upstream and only get reconciled when a human notices. Add a lightweight agent-driven flow: on session start, the agent checks whether enough time has passed since the last upstream check, and if so, compares local `VERSION` to upstream and proposes an update change file if behind. No cron, no CI — just "agent notices stale timestamp, agent decides what to do." This makes sod self-updating through its own workflow.

## Acceptance criteria
- [ ] `.spec/b-startup.md` template in `setup.sh` includes `sod-upstream:` (empty default) and `sod-check-interval: 30d`
- [ ] `.spec/sod-last-checked` tracks the last check date (ISO format, one line); is **gitignored** so it's local state per clone, not tracked churn
- [ ] `.gitignore` in this repo adds `.spec/sod-last-checked`; `setup.sh` ensures downstream repos also gitignore it
- [ ] `.spec/FLOW.md` adds a "Self-update" section: on session start, if no other non-`done` change is active AND `sod-last-checked` is empty or older than `sod-check-interval`, read upstream `VERSION` from the local path, compare using semver, create an `update-sod-to-v{X}` change file if behind. Timestamp bumps only if the check actually ran (steps 4-5 completed); skipped checks (steps 1-3) leave the timestamp alone.
- [ ] v1 limits `sod-upstream:` to a **local filesystem path** only — git URLs are out of scope for this change (future extension)
- [ ] If `sod-upstream:` is empty OR the path doesn't exist OR another non-`done` change is active, skip the check entirely and do not bump the timestamp (so work-in-progress isn't interrupted)
- [ ] Version comparison uses semver logic (major.minor.patch numeric compare), not string compare
- [ ] This repo's own `b-startup.md` sets `sod-upstream:` to empty (it IS upstream) so the check is a no-op here

## Notes
- v1: `sod-upstream:` is a **local filesystem path only** (e.g. `/Users/me/Documents/mochi/dust/spec-of-dust`). Git URLs are explicitly out of scope for this change; a future change can add that.
- Check interval format: `30d`, `7d`, `1d`. Parse as "number followed by d". No need for hours/minutes — sod updates aren't urgent.
- The agent doesn't auto-apply updates — it creates a change file and stops. Normal spec→build→verify→done flow takes over.
- When the agent creates the update change file, it should diff upstream vs local for the framework files and describe what's changing, so peer review has something concrete to look at.
- For the first pass, upstream comparison is simple: compare `VERSION` files. Later we might add CHANGELOG awareness.

## Peer spec review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: git URL upstream undefined — would add clone/fetch machinery. → Fixed: v1 narrows to local filesystem paths only. Git URLs are a future extension.
2. Blocker: auto-creating a change conflicts with single-active-change flow. → Fixed: protocol now requires no other non-done change to be active before the check runs.
3. Risk: tracked `sod-last-checked` dirties the tree every session. → Fixed: `.spec/sod-last-checked` is gitignored, local state per clone, not tracked.
4. Advisory: use semver comparison, not string. → Addressed in AC.


## Peer code review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: spec Notes still mentioned git URLs while ACs said local-only. → Fixed: Notes now explicit that v1 is local paths only.
2. Blocker: tests used BSD `sed -i ''` which fails on GNU sed / Ubuntu CI. → Fixed: replaced with `awk + tmp file` pattern, works on both.
3. Blocker: `docs/dust.html` needed refresh since change file content changed (build-dust.sh embeds change content). → Fixed: rebuilt and staged.
4. Advisory: "Either way, write today's date" loose next to skip rules. → Fixed: FLOW.md now explicit that timestamp only bumps when check actually ran (steps 4-5).


## Verify
<!-- During verify: copy acceptance criteria here, mark pass/fail with notes. -->


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable

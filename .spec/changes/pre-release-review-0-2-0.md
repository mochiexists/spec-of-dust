status: build
files: README.md, .spec/sod-report.md, LICENSE

# Pre-release review and experimental disclaimer for 0.2.0

## What
Before tagging 0.2.0 and making the repo OSS-ready, do a full pre-release review: scan git history for sensitive data, confirm single-identity authorship, and add an experimental-status banner to the top of the README so anyone who lands here knows this is early, unstable, and may turn out to be a bad idea. Tagging happens after this change lands; tagging itself is out-of-scope for this spec (mechanical step, not a code change).

## Acceptance criteria
- [ ] Secrets scan: `git log --all -p | grep -iE "api[_-]?key|secret|token|password|passwd|bearer|authorization"` returns only false positives (token-budget text, review commentary). Real-looking secret values block the change.
- [ ] Email scan: `git log --all -p | grep -iE "[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}"` returns only `atlascodesai` noreply, `example.com`/`test@test.com` test placeholders. No personal or third-party emails.
- [ ] Absolute-path scan: `git log --all -p | grep -E "/Users/[a-zA-Z]+/"` returns only a single placeholder string (`/Users/me/...`) used intentionally in a spec. No real home paths leaked from dev machines.
- [ ] Tree scan: `grep -rl` for `simcity` or `timapple` across tracked text files (`*.md`, `*.sh`, `*.yml`) returns empty.
- [ ] Author audit: `git log --format='%an <%ae>' | sort -u` returns exactly one identity (`mochiexists <259077624+mochiexists@users.noreply.github.com>`). If history shows any other identity, rewrite with `git filter-repo` before tagging.
- [ ] LICENSE copyright holder is `mochiexists` (not the prior `Tim Apple` placeholder) — matches the repo's intended OSS identity.
- [ ] README.md adds a short "Experimental" banner immediately after the title (4-6 lines max): warns this is early-stage, API/flow not stable, may turn out to be a bad idea, no support commitment. Written honestly, not apologetically. Must not bury the existing concise overview.
- [ ] `bash scripts/update-sod-report.sh --check` passes after README edit; `.spec/sod-report.md` refreshed and staged (workflow requires it after README change).

## Notes
- This is a review + a README doc change. Touches `.spec/sod-report.md` too because the workflow requires refreshing sod after tracked text-file edits.
- Author identity is `mochiexists <259077624+mochiexists@users.noreply.github.com>` — the intended mochi GitHub noreply. Historic commits (originally authored by `atlascodesai`) were rewritten via `git filter-repo` before the repo had any remote, which is the correct window for that operation.
- Scan scope: `--all` refs (all branches including dangling), full patch contents (`git log -p`), not just the working tree. If any scan returns a real-looking secret, the change blocks and drops back to build for history cleanup.
- After this change: tag `v0.2.0`, add a git remote, push. Those are separate actions driven by the human because they're publish-level.

## Peer spec review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: `files:` too narrow — README edit forces sod refresh, scope gate would block. → Fixed: added `.spec/sod-report.md`.
2. Medium: scan ACs not reproducible. → Fixed: pinned exact grep commands and scope (`--all`, `-p`).
3. Medium: LICENSE comfort is a human signoff, not a repo fact. → Fixed: verify blocks until author confirms in `## Verify`.
4. Advisory: keep banner short. → Captured in AC (4-6 lines max).


## Peer code review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: sod-report stale — new change file added after last refresh. → Fixed: re-ran update-sod-report.sh; file count now reflects the new change file (78).
2. Medium: README embedded metrics inherited the same staleness. → Fixed: same refresh.
Advisory: banner copy approved (immediately after title, <5 lines, covers instability + no-support).


## Verify
- [pass] Secrets scan: all `token` matches are sod-report budget text (Est. tokens, bootstrap/operational sod targets, ceil(characters / 4)). No `api_key`, `bearer`, `password`, or `secret` value hits outside review text.
- [pass] Email scan: filtered output empty when excluding `noreply`, `example.com`, `test@test`, `actions@github`. Only identity leakage is the GitHub noreply.
- [pass] Absolute-path scan: single hit `/Users/me/Documents/mochi/dust/spec-of-dust` — placeholder in a spec, intentional. No dev-machine home paths.
- [pass] Tree scan: only match is `.spec/changes/pre-release-review-0-2-0.md` (this file's own AC referencing the terms it scans for). Self-reference, not a leak.
- [pass] Author audit after history rewrite: `git log --format='%an <%ae>' | sort -u` returns one identity — `mochiexists <259077624+mochiexists@users.noreply.github.com>`. All 66 commits re-authored via `git filter-repo` while the repo has no remote (safe rewrite window).
- [pass] LICENSE copyright updated to `mochiexists`.
- [pass] README.md has a 4-line Experimental banner immediately after the title; does not bury the overview.
- [pass] `bash scripts/update-sod-report.sh --check` clean after final refresh.


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable

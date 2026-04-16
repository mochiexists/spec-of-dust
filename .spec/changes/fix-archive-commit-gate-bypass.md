status: build
files: .githooks/_spec_gate.sh, tests/test-spec-gate.sh, VERSION, docs/viewer.html

# Fix archive commit gate bypass

## What
Release-time archiving (moving done changes to `.spec/archive/`) required bypassing the commit hooks entirely because the skip gate only allows single-file changes and the spec gate requires an active change file. Archive commits are a legitimate workflow operation — the gate should recognize them, not force a bypass.

## Acceptance criteria
- [ ] `.githooks/_spec_gate.sh` recognizes archive-only commits (staged files are exclusively `.spec/archive/` renames plus allowed SOD/viewer artifacts) and passes without requiring an active change file or skip entry
- [ ] The archive exemption only applies when all non-exempt staged files are in `.spec/archive/` — mixing archive moves with other code changes is still blocked
- [ ] `tests/test-spec-gate.sh` covers: archive-only commit passes, archive mixed with unrelated code changes is blocked
- [ ] VERSION bumped to 0.1.1

## Notes
- The exemption should check that staged changes are renames from `.spec/changes/` to `.spec/archive/` plus the usual SOD/viewer/README artifacts
- This is the gap that forced `core.hooksPath=/dev/null` during the v0.1.0 release
- Keep it tight — only archive renames get the exemption, not arbitrary `.spec/archive/` writes
- Use `git diff --cached --name-status` to detect true `R` (rename) status from `.spec/changes/` to `.spec/archive/`, not just path presence
- Exact allowed extras beyond the renames: `.spec/sod-report.md`, `README.md`, `docs/viewer.html`, `.spec/devlog.jsonl`, `.spec/flowlog.jsonl`
- Test should mirror the real release path: `git mv` a done change, refresh SOD, stage artifacts, commit

## Peer spec review
**Codex** (2026-04-17):

1. Blocker: allowed artifact set ambiguous — some files are exempt, some aren't. Need exact list.
2. High: need true rename detection via git status, not just path prefix matching.
3. Medium: test should mirror real release flow, not just path checks.

-> Addressed: exact extras listed, rename detection via `--name-status`, test mirrors real flow.

## Peer code review
**Codex** (2026-04-17):

1. Blocker: `enforce_commit_policies` early return for archive bypassed done-closeout gate entirely — should only bypass spec gate.
2. High: regex dots in path matching — `README.md` matches `READMEXmd`. Use `case` instead.
3. Advisory: no test for archive + unrelated dirty work.

-> Fixed: archive bypass stays only in `enforce_spec_gate`. Path matching uses `case` via `is_archive_allowed_extra`. Done-closeout and scope gates still run for archive commits.

## Verify
- [pass] `_spec_gate.sh` recognizes archive-only commits via true rename detection (`R*` status from `.spec/changes/` to `.spec/archive/`) and exact `case` matching for allowed extras
- [pass] Archive exemption only applies when all staged files are archive renames + allowed artifacts — mixing with code is blocked (tested)
- [pass] Tests cover: archive-only passes, archive mixed with code blocked (17 total tests pass)
- [pass] VERSION bumped to 0.1.1

## Closure
- Challenges: First implementation bypassed too many gates — Codex caught that archive commits would skip done-closeout entirely. Regex matching was also too loose.
- Learnings: Gate bypasses should be surgical — exempt the minimum gate, not the whole policy chain. `case` matching is safer than regex for exact path lists.
- Outcomes: Archive commits no longer need `core.hooksPath=/dev/null`. The gate recognizes them as a legitimate workflow operation while still enforcing SOD freshness and done-closeout discipline.
- Dust: The gate learned to let the filing clerk through.

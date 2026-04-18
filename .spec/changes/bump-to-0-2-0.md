status: build
files: VERSION, .spec/sod-report.md, README.md

# Bump VERSION to 0.2.0

## What
Six features shipped since 0.1.3: viewer→dust rename, testing guidance, push knob, agent-driven self-update flow, dust filter view, and build-dust.sh template regenerator. All additive / backward-compatible, but workflow semantics and viewer architecture changed meaningfully. Bump to 0.2.0 per semver spirit so the self-update flow has something concrete to compare against in downstream repos.

## Acceptance criteria
- [x] `VERSION` file contains `0.2.0`
- [x] `.spec/sod-report.md` and `README.md` regenerated via `update-sod-report.sh` with the new version
- [x] `bash scripts/update-sod-report.sh --check` passes cleanly after the change

## Notes
- Minimal minor-bump change. No peer review needed — single-file mechanical change with automated sod-report refresh.
- After merge, downstream repos with `sod-upstream:` pointing here will see `0.2.0 > 0.1.3` and propose an update on next session.

## Peer spec review
Skipped — trivial version bump. Minor-bump signals "features added, backward compatible." No new mechanisms, no user-facing gates changed.

## Peer code review
Skipped — mechanical.

## Verify
- [pass] VERSION is 0.2.0
- [pass] sod-report and README reflect 0.2.0
- [pass] --check passes

## Closure
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: version reflects the six features shipped this session
- Dust: 0.2.0 — enough dust to matter

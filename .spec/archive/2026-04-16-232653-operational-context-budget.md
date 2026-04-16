status: done
files: scripts/update-sod-report.sh, .spec/FLOW.md, README.md

# Operational context budget

## What
Add an operational context metric to the SOD report that tracks only the files agents ingest on session start — the bootstrap chain. This gives a concrete token budget for the framework's own footprint, separate from project-specific files like `AGENTS.md` and `CLAUDE.md` that will grow with the project. Target: 3k tokens for the bootstrap, 5k ceiling including project files.

## Acceptance criteria
- [ ] `scripts/update-sod-report.sh` outputs a "Bootstrap SOD" line counting only the framework bootstrap files: `.spec/FLOW.md` and `.spec/b-startup.md`
- [ ] `scripts/update-sod-report.sh` outputs an "Operational SOD" line counting bootstrap + project files: `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, plus the active change file (if any)
- [ ] Both metrics appear in `.spec/sod-report.md` and as extra lines in the `README.md` summary block, showing target vs actual (e.g. `Bootstrap: 3280 / 3000 target`)
- [ ] `.spec/FLOW.md` states the budget principle: bootstrap target 3k tokens, operational target 5k tokens

## Notes
- Bootstrap files (framework cost): `.spec/FLOW.md`, `.spec/b-startup.md` — these are what the framework imposes on every session
- Project files (adopter cost): `AGENTS.md`, `CLAUDE.md`/`CODEX.md`, active change file — these grow with the project
- `_template.md` is not session-start context — only read when creating a new change
- The budget is a target, not a gate — no hook enforcement, just visibility in the SOD report
- The current bootstrap is ~3.3k tokens — FLOW.md at 3.1k is most of it
- Show target vs actual so drift is visible

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: bootstrap set wrong — `_template.md` isn't session-start context. Bootstrap is `FLOW.md` + `b-startup.md` only.
2. Blocker: "5k operational ceiling" set undefined — needs exact file list including active change file.
3. Ambiguous: "appears in README summary" — specify format.

-> Addressed: bootstrap narrowed to `FLOW.md` + `b-startup.md`. Operational set defined as bootstrap + `AGENTS.md` + `CLAUDE.md`/`CODEX.md` + active change. Format is extra lines with target vs actual.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: active change selection picks first alphabetic done file, not actual in-progress. Should prefer spec|build|verify over done.
2. Missed: labels don't match spec — "Bootstrap context" vs required "Bootstrap SOD".

-> Addressed: selection now prefers in-progress (spec|build|verify) over done. Labels aligned to "Bootstrap SOD" / "Operational SOD".

## Verify
- [pass] SOD report outputs Bootstrap SOD line counting FLOW.md + b-startup.md: `3377 / 3000 target`
- [pass] SOD report outputs Operational SOD line counting bootstrap + AGENTS.md + CLAUDE.md + CODEX.md + active change: `4731 / 5000 target`
- [pass] Both metrics appear in `.spec/sod-report.md` and README summary with target vs actual
- [pass] FLOW.md states budget principle with bootstrap 3k target and operational 5k target

## Closure
- Challenges: Active change selection logic was tricky — needed to prefer in-progress over done, not just grab the first alphabetic match.
- Learnings: The bootstrap is already over budget at 3.4k — FLOW.md at 3.2k is 95% of it. The operational budget is healthy at 4.7k.
- Outcomes: Token budgets are now visible in every SOD refresh. The framework's weight is measurable.
- Dust: A spec of dust finally learned to weigh itself.

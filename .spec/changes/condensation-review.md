status: done
files: docs/viewer.html

# Condensation review

## What
Review the entire spec-of-dust repo for bloat, redundancy, and unnecessary complexity. This project is called "spec of dust" — it should be minimal. Evaluate every file, script, and doc surface for whether it earns its place. Produce a concrete condensation plan: what to merge, what to delete, what to simplify. This is a review-only spec — no code changes, just a written assessment with actionable recommendations.

## Acceptance criteria
- [ ] A written assessment exists in this change file covering: total LOC/token count, file-by-file evaluation of whether each file earns its place, identified redundancy across docs (README vs FLOW.md vs AGENTS.md vs b-startup.md), script overlap, and hook complexity
- [ ] The assessment identifies at least 3 concrete condensation actions ranked by impact
- [ ] Each recommended action states what to merge/delete/simplify, the estimated LOC reduction, and any risk
- [ ] The assessment is honest about what we over-built during this session

## Peer spec review
Codex CLI stalled during review (66 lines output, no verdict after 60s). Proceeding without — this is a review-only spec with no code risk.

## Notes
- Use the SOD report as a starting point for LOC/token analysis
- Pay special attention to: README.md (is it too long?), the number of scripts in `scripts/`, whether `build-viewer.sh` parser complexity is justified, and whether `docs/viewer.html` has grown beyond what a "spec of dust" project needs
- The viewer and its build pipeline were built in one session — check if they should be simplified or if the complexity is warranted
- This is a review spec, not a build spec — the output is the assessment, not code changes
- Follow-up changes can implement the condensation actions

## Assessment

### Overview

46 files, 4040 lines, ~56k tokens. For a "spec of dust" that started as a zero-dependency workflow framework, this is getting heavy.

### Where the weight is

| Category | Files | Lines | Tokens | % of total |
|----------|-------|-------|--------|------------|
| `docs/viewer.html` | 1 | 618 | 18,690 | **33.5%** |
| `.spec/archive/` (9 files) | 9 | 591 | 10,603 | 19.0% |
| `.spec/changes/` (6 active) | 6 | 323 | 5,710 | 10.2% |
| `scripts/` (6 files) | 6 | 835 | 5,517 | 9.9% |
| `.githooks/_spec_gate.sh` | 1 | 407 | 2,330 | 4.2% |
| `tests/test-spec-gate.sh` | 1 | 344 | 2,381 | 4.3% |
| `.spec/FLOW.md` | 1 | 220 | 3,148 | 5.6% |
| `README.md` | 1 | 183 | 1,858 | 3.3% |
| Everything else | 20 | 519 | 6,561 | 11.8% |

**The viewer is a third of the repo.** `docs/viewer.html` has embedded JSONL data (the long lines), the build script, the parser, the renderer — and it's growing every time we add a change. This is the main bloat vector.

### File-by-file evaluation

**Earns its place:**
- `.spec/FLOW.md` (220 lines) — core workflow doc, well-structured, can't shrink much
- `.githooks/_spec_gate.sh` (407 lines) — correctness-critical, well-tested, the scope gate was needed
- `tests/test-spec-gate.sh` (344 lines) — 11 tests for safety-critical logic, justified
- `scripts/update-sod-report.sh` (246 lines) — the SOD system is useful for self-awareness
- `README.md` (183 lines) — thorough but not bloated
- `setup.sh`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `b-startup.md` — all small and purposeful

**Questionable:**
- `docs/viewer.html` (618 lines, 18.7k tokens) — **a third of the repo is a nice-to-have UI.** The embedded data makes it grow with every change. The markdown parser in `build-viewer.sh` is 226 lines of bash to parse markdown into JSON — that's fragile and complex for what it does.
- `scripts/build-viewer.sh` (226 lines) — bash markdown parser is over-engineered for a zero-dependency project. Parsing closure fields, peer reviews, verify sections with line-by-line bash is exactly the kind of complexity spec-of-dust is supposed to avoid.
- `scripts/devlog.sh` + `scripts/flowlog.sh` (154 lines total) — these are useful but could be one script with a mode flag instead of two nearly identical files.
- `scripts/archive-done-changes.sh` + `scripts/merge-completed-work.sh` (210 lines) — necessary for the merge flow but could potentially be one script.
- `.spec/archive/` (591 lines) — 9 archived change files with full peer review text. The history is valuable but the viewer embeds ALL of it into the HTML, which is why it's 18k tokens.

**Over-built in this session:**
- The viewer pipeline: `build-viewer.sh` → `viewer.html` with embedded data → auto-rebuild on append. We built a CMS for a workflow framework.
- The JSONL helper scripts auto-calling `build-viewer.sh` — this creates a rebuild dependency chain that's surprising for append scripts.
- The markdown parser in bash — this is the wrong tool for the job in a repo that prides itself on simplicity.

### Doc redundancy

- `README.md` and `.spec/FLOW.md` overlap on workflow description — README should point to FLOW.md more, say less
- `AGENTS.md` is thin (24 lines) and mostly says "read FLOW.md" — could merge into CLAUDE.md/CODEX.md or just be 3 lines
- `b-startup.md` (13 lines) is appropriately minimal
- `docs/README.md` (23 lines) describes structure that doesn't fully exist yet — `docs/architecture/`, `docs/decisions/`, `docs/runbooks/` are mentioned but not created

### Condensation actions (ranked by impact)

**1. Simplify the viewer pipeline (est. -400 lines, -15k tokens)**
- Remove `build-viewer.sh`'s markdown parser entirely
- Stop embedding change file content in the HTML — the viewer only needs JSONL data
- If change history is wanted, add a `changes:` event type to flowlog instead of parsing markdown
- Remove `docs/viewer.html` embedded change data — keep only devlog + flowlog
- This eliminates the bash markdown parser, the auto-rebuild chain, and most of the embedded data bloat
- Risk: lose the Dust/closure display in the viewer. Mitigation: Dust could be a flowlog field instead.

**2. Merge devlog.sh and flowlog.sh into one script (est. -70 lines)**
- `scripts/log.sh devlog --kind typo ...` and `scripts/log.sh flowlog --change x ...`
- Share the arg parser, escape function, and viewer rebuild call
- Risk: minor UX change for agents calling the scripts

**3. Trim AGENTS.md and docs/README.md (est. -30 lines)**
- AGENTS.md is mostly "read FLOW.md" — collapse to 5 lines
- docs/README.md describes structure that doesn't exist — trim to what's real
- Risk: none

## Peer code review
N/A — review-only spec, no code changes.

## Verify
- [pass] Written assessment covers LOC/token count (46 files, 4040 lines, ~56k tokens), file-by-file evaluation, doc redundancy, and script overlap
- [pass] 3 concrete condensation actions identified, ranked by impact (viewer pipeline -400 lines, merge log scripts -70 lines, trim docs -30 lines)
- [pass] Each action has estimated LOC reduction and risk assessment
- [pass] Assessment is honest about what was over-built: viewer pipeline, bash markdown parser, auto-rebuild chain

## Closure
- Challenges: Codex stalled during spec review so no peer check on this one. The assessment had to be brutally honest about work done in this session.
- Learnings: A third of the repo is a viewer that didn't exist 3 hours ago. Building features inside a framework repo creates compounding weight.
- Outcomes: Clear condensation roadmap: simplify the viewer pipeline first (biggest win), merge the log scripts, trim redundant docs.
- Dust: The dust weighed itself and found it was carrying sand.

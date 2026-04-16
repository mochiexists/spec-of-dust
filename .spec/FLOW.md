# spec-of-dust Flow

A lightweight spec, review, and gate workflow. No CLI tools, no slash commands.
You understand the flow by reading this file. Track state via change files in `.spec/changes/`.

## Context budget

- **Bootstrap** (target: 3k tokens) — framework cost: `FLOW.md` + `b-startup.md`
- **Operational** (target: 5k tokens) — bootstrap + project files: `AGENTS.md`, `CLAUDE.md`/`CODEX.md`, active change

Visibility targets, not hard gates. Keep the bootstrap tight.

## B:/ Start Up

On session start, read `.spec/b-startup.md` if it exists, then `AGENTS.md`, this file, and the active change file.
Do not auto-read the whole repo unless the task needs it.

## States

Every change moves through four states via the `status:` field in its change file:

```
spec → build → verify → done
```

**spec** — Define what and why. Capture acceptance criteria as checkboxes (these become the verify checklist). Do NOT write code. When ready, request peer review.

**build** — Implement the spec. When complete, request peer review.

**verify** — Check every acceptance criterion against the implementation. Pass/fail each. If anything fails, return to `build`.

**done** — All criteria pass. Before setting `status: done`:
1. Fill `## Closure` with `Challenges`, `Learnings`, `Outcomes`, and `Dust` (one short artistic line, <80 chars). Use `nothing notable` if straightforward.
2. Append a flowlog entry via `bash scripts/flowlog.sh` with `--change`, `--agent`, `--sentiment` (smooth/rough/blocked), and optional `--divergence`, `--friction`, `--suggestion`.
3. Set `status: done`.

After `done`, merge behavior applies (see Merge section).

## Change files

One file per change: `.spec/changes/{name}.md` (lowercase-kebab-case).
Use the template at `.spec/changes/_template.md`. Files named `_template.md` and `_example-*` are scaffolding.
The `status:` line is the state machine. Update it to transition.

## Gates

Mechanical checks that block unsafe progress:

- **commit gate**: no code commit without an active change file (status `build|verify|done`), unless skip rules pass
- **scope gate**: if the active change has a `files:` field, staged non-exempt files must match it
- **skip gate**: `--no-verify` requires a structured devlog entry and a truly trivial diff
- **archive gate**: finished change files move to `.spec/archive/` after merge

Extend these gates with your repo's engineering policy. Keep local gates fast; let CI run the strict superset.

## Merge

Configured in `.spec/b-startup.md` via `merge: manual | confirm | auto` and `merge-target: <branch>` (default `main`).

- **manual**: stop at `done`, wait for human
- **confirm**: ask the human; if declined, stay at `done`
- **auto**: agent runs `bash scripts/merge-completed-work.sh --auto` after verify passes and local gates are clean

The merge helper archives done change files on the target branch, or archives then merges with `--no-ff` from a feature branch. It refuses dirty trees, missing Git repos, and missing completed changes. Merge failure keeps the change at `done` and reports the error. Do not auto-delete branches.

## Agent teams

Respect `teams:` in `.spec/b-startup.md` (`none | some | many`; default `some`).
Use teams only for truly parallel work: independent reviews, bounded research, repeated batch items.
Do not use them for blocking steps, tightly coupled edits, or work too small to justify the cost.

## Peer review

Two AI models review adversarially: before building (spec review) and after building (code review).

### Shared review rules

- Scope context to: the change file, changed files, directly referenced files, and obviously adjacent files
- Prioritize this change; broader critiques are advisory unless they reveal a blocker (missed requirement, bug, unsafe design, spec contradiction)
- If the other CLI isn't available, ask the human to relay. Don't skip the review

### Pre-build (spec → build)

1. Shell out: `cat .spec/changes/{name}.md | <other-cli> "Review this spec using nearby repo context only. What's missing, ambiguous, risky, or overbuilt? Prioritize this change. Broader critiques are advisory unless they reveal a blocker. Under 200 words."`
   - Claude Code uses `codex exec`, Codex uses `claude -p`
2. Paste response into `## Peer spec review`, address blockers, then set `status: build`

### Post-build (build → verify)

1. Stage changes, then: `git diff --staged | <other-cli> "Review this diff against the spec in .spec/changes/{name}.md using nearby repo context only. Bugs, missed requirements, style issues? Prioritize this change. Broader critiques are advisory unless they reveal a blocker. Under 300 words."`
2. Paste response into `## Peer code review`, address blockers, then set `status: verify`

## Skip path

For truly trivial changes (typos, version bumps, comments, config tweaks, one-line fixes):

1. Run `bash scripts/devlog.sh --kind KIND --summary TEXT --reason TEXT --file PATH`
2. Stage the devlog entry and commit with `git commit --no-verify`

Skip disqualifiers — if any apply, use a minimal spec instead:
- adds, deletes, or renames a file
- touches multiple code files
- changes more than a handful of lines
- needs design discussion
- if you're unsure, it does not qualify

## Monorepo

Works in single-project and monorepo layouts. Use `apps/` for services, `packages/` for shared modules, `docs/` for documentation. Scope local gates to touched projects.

## Rules for the AI

- On session start, check `.spec/changes/` for active changes (ignore `_template.md` and `_example-*`). If one exists with status other than `done`, resume from that state.
- No change file + human request = create one from template, start at `spec`. Don't jump to code.
- Specs are 10-30 lines, not a PRD. Write mechanically checkable acceptance criteria.
- Small changes can use a minimal spec (one-liner + 1-2 criteria). Skip commits are different — trivial only, logged in devlog.
- "Just do it" from the human = log it in devlog. Skip commits still need a structured entry.

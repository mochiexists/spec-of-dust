# architect-of-dust

> **Experimental.** This is an early architecture-first workflow for
> AI-assisted development. The flow, templates, and gates will keep changing.

`architect-of-dust` is a zero-dependency architecture, review, and gate
workflow for AI-assisted development. No CLI tools, no slash commands, no npm
packages. Just markdown files, plain Git hooks, and a root layout that stays
clean as a repo grows.

<!-- aod-summary:start -->
## aod

- Version: `0.2.0`
- Files: `90`
- Lines: `9271`
- Words: `83211`
- Characters: `643302`
- Est. tokens: `160857`
- bootstrap aod: `3213 / 3000 target`
- operational aod: `6002 / 5000 target`

See `.spec/aod-report.md` for the full per-file breakdown.
<!-- aod-summary:end -->

## How it works

```text
architect -> build -> verify -> present
```

1. **Architect** — write the architecture note for the change: intent,
   ordering, constraints, and checks.
2. **Peer architecture review** — the other model reviews the plan before code.
3. **Build** — implement within the declared scope.
4. **Peer code review** — the other model reviews the diff against the change.
5. **Verify** — walk through every listed check and mark pass/fail.
6. **Present** — the change is locally complete and ready to merge, split, or
   continue through a follow-up.

AoD is explicitly not a ticket-spec framework. The point is to architect the
change first, then build, verify, and present it.

## Root Layout

```text
apps/                       # Deployable apps and services
packages/                   # Shared modules, configs, tooling
docs/                       # Docked documentation and ADRs
.github/                    # Minimal GitHub-facing publishing scaffold
packs/                      # Source definitions for future release packs
.spec/
  FLOW.md                   # Workflow rules (AI reads this)
  b-startup.md              # Minimal boot brief read on session start
  devlog.jsonl              # Structured audit log for skip-no-verify commits
  flowlog.jsonl             # Workflow feedback log for completed changes
  changes/
    _template.md            # Template for new changes
    my-change.md            # Active change
  archive/                  # Presented changes after archive closeout
.githooks/
  pre-commit                # Blocks code commits without an active change file
  prepare-commit-msg        # Enforces trivial-only skip logging
  post-merge                # Stages archive closeout after plain merges
AGENTS.md                   # Agent-agnostic project context
CODEX.md                    # Codex-specific notes
CLAUDE.md                   # Claude Code specific config
VERSION                     # Current project version
scripts/                    # Repo-local automation such as AoD metrics
```

## Setup

```bash
bash setup.sh
```

That wires up `.githooks/`, creates the `.spec/` scaffolding, and leaves the
repo ready for the workflow.

## Usage

```bash
cp .spec/changes/_template.md .spec/changes/add-dark-mode.md
```

Then edit the file:
- set `status: architect`
- write the intent
- capture ordering if the work depends on other changes
- list the checks that will prove the change

The AI reads `.spec/b-startup.md` and `.spec/FLOW.md` and resumes from the
active change file.

## Ordering

AoD treats sequencing as first-class. Non-trivial changes should say:
- what must happen first
- what this change unlocks next
- whether it is phase 1/n of a larger effort

That lives in `## Ordering` inside the change file template. The framework does
not force a graph structure yet, but it does force the issue into the open.

## Cross-model review

Claude Code and Codex work as adversarial peers:
- before building, the active model sends the architecture note to the other
- after building, the active model sends the staged diff to the other
- if the other CLI is unavailable, the limitation is recorded explicitly

The exact protocol lives in `.spec/FLOW.md`.

## Skipping the workflow

Some changes are too small for the full loop: typos, version bumps, comment
tweaks, or a one-line fix with obvious intent. Those can skip the full flow, but
the skip is still documented in `.spec/devlog.jsonl`.

If it is small but not tiny, use a minimal architecture note instead of skip
mode.

## Gates

In `architect-of-dust`, a gate is any mechanical check that must pass before
work moves forward. The built-in local gates are intentionally small and
local-first:

- active-change gate
- present-closeout gate
- scope gate
- skip gate
- archive gate

Extend these with your repo's real engineering policy.

## AoD metrics

`aod` is the short name for the framework metrics in this repo.

- run `bash scripts/update-aod-report.sh` to refresh the committed report
- the detailed report lives at `.spec/aod-report.md`
- the README summary block near the top is generated from the same script
- commit hooks expect the metrics report and README summary to be fresh and
  staged when tracked text files change

## Migration from SoD

AoD is the continuation of the old `spec-of-dust` framing.

What changed conceptually:
- `spec` becomes `architect`
- `done` becomes `present`
- change files lead with architecture intent, ordering, and checks
- the framework is explicit that it is about system-shape thinking, not tiny
  specs

What stays mechanically similar:
- one active change file per standard change
- peer review before build and before verify
- skip logging for truly trivial work
- archive after completion

What downstream repos may need to adopt manually:
- rename their local docs and conventions from SoD to AoD
- update any scripts or CI that depend on `status: spec` / `status: done`
- decide whether to keep any old filenames as compatibility shims

## Release packs

`architect-of-dust` keeps the core workflow local and minimal, then layers
optional stack defaults on top as release packs.

- pack source lives under `packs/`
- the public index lives at `packs/index.json`
- future GitHub Releases can ship tarballs or zip assets built from those
  source directories

## Publishing shape

The repo has a minimal public shape:

- `README.md` explains the framework
- `docs/index.html` is a lightweight static entrypoint
- `docs/README.md` holds the docs dock
- `.github/README.md` captures GitHub-facing publishing intent

## Versioning

`architect-of-dust` uses a lightweight manual version file at `VERSION`.

- start at `0.0.1`
- bump manually on meaningful repo changes
- use normal semantic version formatting

## Local hooks and CI

The shipped hooks are the floor, not the ceiling.

- put architecture checks, linting, tests, type checks, and safety rails close
  to the repo
- keep local hooks fast enough for normal commits
- make CI the strict superset when possible
- treat hooks as project policy, not as a substitute for architecture or tests

## Requirements

- git
- bash (native on macOS/Linux, works via Git Bash or WSL on Windows)
- awk, sed, grep, and other normal POSIX shell tools already expected in repo
  scripting

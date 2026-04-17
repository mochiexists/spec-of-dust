# spec-of-dust

`spec-of-dust` is a zero-dependency spec, review, and gate workflow for AI-assisted
development. No CLI tools, no slash commands, no npm packages. Just markdown files,
plain Git hooks, and a root layout that stays clean as a repo grows.

It is designed to be publishable as a real project: local-first by default, but ready
to grow into GitHub Pages docs, GitHub Release artifacts, language-specific gate packs,
and starter repo layouts.

<!-- sod-summary:start -->
## sod

- Version: `0.1.2`
- Files: `66`
- Lines: `5897`
- Words: `47550`
- Characters: `364587`
- Est. tokens: `91169`
- bootstrap sod: `1705 / 3000 target`
- operational sod: `3481 / 5000 target`

See `.spec/sod-report.md` for the full per-file breakdown.
<!-- sod-summary:end -->

## How it works

```
spec → build → verify → done
```

1. **Spec** — Write what you're building in a change file. 10-30 lines, not a PRD.
2. **Peer review** — The other AI model reviews your spec before you build.
3. **Build** — Implement. The spec's acceptance criteria guide the work.
4. **Peer review** — The other AI model reviews the code against the spec.
5. **Verify** — Walk through every acceptance criterion. Pass/fail each one.
6. **Done** — The merge helper archives and commits completed changes; a plain merge stages the archive closeout via `post-merge`.

## Root Layout

```
apps/                       # Deployable apps and services
packages/                   # Shared modules, configs, tooling
docs/                       # Docked documentation and ADRs
.github/                    # Minimal GitHub-facing publishing scaffold
packs/                      # Source definitions for future release packs
.spec/
  FLOW.md                   # Workflow rules (AI reads this)
  b-startup.md              # Minimal boot brief read on session start
  devlog.jsonl              # Structured audit log for skip-no-verify commits
  flowlog.jsonl             # Workflow feedback log (beta) for completed changes
  changes/
    _template.md            # Template for new changes
    my-feature.md           # Active change (one per feature)
  archive/                  # Completed changes after archive closeout
.githooks/
  pre-commit                # Blocks code commits without an active change file
  prepare-commit-msg        # Enforces trivial-only skip logging, even with --no-verify
  post-merge                # Stages archive closeout after plain merges
AGENTS.md                   # Agent-agnostic project context
CODEX.md                    # Codex-specific notes
CLAUDE.md                   # Claude Code specific config
VERSION                     # Current project version
scripts/                    # Repo-local automation such as sod generation
```

## Setup

```bash
bash setup.sh
```

That's it. It configures git to use the hooks in `.githooks/` and creates the directories.

## Usage

```bash
# Start a new feature
cp .spec/changes/_template.md .spec/changes/add-dark-mode.md
# Edit the file, set status: spec, write your spec
# AI picks it up automatically on session start
```

The AI reads `.spec/b-startup.md` and `.spec/FLOW.md` and knows what to do. You don't need to remember commands.

## B:/ Start Up

Read `.spec/b-startup.md` on session start. Keep long-lived detail in `docs/`, not in the startup brief.

Optional setup soundtrack: Blank Banshee, `B:/ Start Up`.

## Monorepo-Ready By Default

The root is intentionally shaped for growth:

- `apps/` holds deployable products and services
- `packages/` holds shared modules, UI, config, schemas, and internal tooling
- `docs/` keeps architecture notes, ADRs, and runbooks out of the root
- `packs/` can hold versioned gate-pack sources without polluting the core workflow
- `.spec/` and `.githooks/` stay repo-global, so the workflow scales across projects

## Cross-model review

Claude Code and Codex work as adversarial peers:
- Before building, the active model sends the spec to the other for review
- After building, the active model sends the diff to the other for review
- If the other CLI isn't available, the AI prints a prompt for you to relay manually

The exact protocol lives in `.spec/FLOW.md`.

## Skipping The Workflow

Some changes are too small for the full ceremony: typos, version bumps, comment tweaks,
or a one-line fix with obvious intent. Those can skip the full flow, but the skip is still documented in `.spec/devlog.jsonl`.

Use the exact skip rules in `.spec/FLOW.md`. The short version is:

- only truly trivial, single-file, in-place changes qualify
- skip commits must be logged
- if it is small but not tiny, use a minimal spec instead of skipping

## Gates

In `spec-of-dust`, a gate is any mechanical check that must pass before work moves forward.
The built-in local gates are intentionally small and local-first.

You should extend these gates inline with your repo's real engineering policy.

## sod

`sod` is the short name for `spec-of-dust` repo metrics.

- run `bash scripts/update-sod-report.sh` to refresh the committed report
- the detailed report lives at `.spec/sod-report.md`
- the README block near the top is generated from the same script
- commit hooks expect the sod report and README summary to be fresh and staged when tracked text files change

## Release Packs

`spec-of-dust` keeps the core workflow local and minimal, then layers optional stack defaults on top as release packs.

- pack source lives under `packs/`
- the public index lives at `packs/index.json`
- future GitHub Releases can ship tarballs or zip assets built from those source directories
- downstream repos can keep using plain Git hooks or adapt the same gate policy through tools like Husky

The initial manifest is intentionally small: slug, version, summary, docs path, and artifact path.
Artifact paths are placeholders for future release automation, not files that exist yet in the repo.

## Publishing Shape

The repo now has a minimal public shape:

- `README.md` explains the project and workflow
- `docs/index.html` is a lightweight static entrypoint for GitHub Pages
- `docs/README.md` holds the documentation dock
- `.github/README.md` captures GitHub-facing publishing intent
- `LICENSE` makes public reuse unambiguous

## Versioning

`spec-of-dust` uses a lightweight manual version file at `VERSION`.

- start at `0.0.1`
- bump manually on meaningful repo changes
- use normal semantic version formatting, such as `0.0.2`, `0.1.0`, and `1.0.0`

## Local Hooks And CI

The shipped hooks are the floor, not the ceiling. Extend them inline with your CI/CD so the same rules run locally and in automation.

- Put architecture checks, linting, unit tests, type checks, and safety rails close to the repo
- Keep local hooks fast enough for normal commits; reserve heavier suites for CI when needed
- Make CI the strict superset when possible, so local feedback is fast and CI is the final backstop
- Treat hooks as project policy, not as a substitute for good architecture or good tests

## Git Hooks vs Husky

This approach is broadly portable, not literally universal.

- It works well anywhere Git and Bash are normal: macOS, Linux, dev containers, CI, WSL, Git Bash
- It is weaker on stock Windows environments that only assume `cmd.exe` or PowerShell
- Git hooks are repo-local but not auto-installed on clone, which is why `setup.sh` exists

Tools like Husky are popular because JavaScript repos already depend on Node and package managers:

- `npm install` or `pnpm install` can auto-wire the hooks
- teams get one more layer of cross-platform normalization
- hook logic can reuse the same Node toolchain the repo already needs

If you do not want Node as infrastructure, plain Git hooks are simpler and more language-agnostic.

## Requirements

- git
- bash (for hooks; native on macOS/Linux, works via Git Bash or WSL on Windows)
- That's it

# AGENTS.md

## Workflow

This project uses `spec-of-dust`. Read `.spec/FLOW.md` before starting any feature work.

On session start, read `.spec/b-startup.md` if it exists, then check `.spec/changes/` for active change files. Ignore `_template.md` and `_example-*`. If a real change file exists, resume from its current status. If none exist and the user requests a change, create one from `.spec/changes/_template.md`.

## Peer review

Two AI models work this repo: Claude Code and Codex. You are one of them.
Before building (spec→build) and after building (build→verify), the other model reviews.
See `.spec/FLOW.md` for the exact protocol.

<!-- Add project-specific context below this line -->

## Project

This repo is `spec-of-dust` itself: a zero-dependency workflow framework, not an app.

- Primary surfaces: `.spec/`, `.githooks/`, `README.md`, `setup.sh`, and `scripts/update-sod-report.sh`
- No runtime app code lives here; the repo is the product
- Refresh repo metrics with `bash scripts/update-sod-report.sh` after tracked text-file changes
- Keep durable notes in `docs/`, release-pack definitions in `packs/`, and active work in `.spec/changes/`

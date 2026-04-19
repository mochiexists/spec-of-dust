# AGENTS.md

## Workflow

This project uses `spec-of-dust`. Read `.spec/FLOW.md` before starting any feature work.

On session start, read `.spec/b-startup.md` if it exists, then check `.spec/changes/` for active change files. Ignore `_template.md` and `_example-*`. If a real change file exists, resume from its current status. If none exist and the user requests a change, create one from `.spec/changes/_template.md`.

## External actions rule (load-bearing)

Before invoking any command that writes to an external system — `gh repo create`, `gh release create`, `gh api` (POST/PUT/DELETE), `curl` that posts/pushes, SSH deploys, `git push --tags` — check for an active change file in `.spec/changes/` with status `spec|build|verify`. If none exists, STOP and create one that names the external target before proceeding. No mechanical commit gate covers these actions; this rule is the main line of defence. See FLOW.md "External actions (not mechanically gated)".

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

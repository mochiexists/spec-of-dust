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

<!-- e.g. -->
<!-- Swift/iOS app using SwiftUI and SwiftData. -->
<!-- Run tests: swift test -->
<!-- Lint: swiftlint -->

# B:/ Start Up

This repo is `spec-of-dust` itself: a zero-dependency workflow framework, not an app repo.

- Read this, then `AGENTS.md`, then `.spec/FLOW.md`, then the active change file
- Keep the root clean; durable detail belongs in `docs/`, not here
- `.spec/` holds active workflow state and `.githooks/` holds the local enforcement
- Refresh sod with `bash scripts/update-sod-report.sh` after tracked text-file changes
- Skip audit entries live in `.spec/devlog.jsonl`

teams: some
merge: confirm
merge-target: main
push: never

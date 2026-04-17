# CLAUDE.md

Read @.spec/b-startup.md on session start if it exists.
Read @AGENTS.md for project context and workflow.
Read @.spec/FLOW.md for the full `spec-of-dust` workflow.

## Claude Code specific

- When peer-reviewing, shell out to Codex: `cat .spec/changes/{name}.md | codex exec "..."`
- If codex CLI is not available, print the review prompt and ask the human to relay it.
- If `.spec/b-startup.md` sets `teams: none | some | many`, respect it when deciding how much subagent fan-out to use.
- Prefer subagents only for clearly parallel exploration or review work; keep the main context clean.
- If tracked text files change, run `bash scripts/update-sod-report.sh` and stage the refreshed sod outputs before committing.
- Before setting a standard change to `done`, append a workflow feedback entry to `.spec/flowlog.jsonl` (see FLOW.md).
- On session start, run: `ls .spec/changes/ | grep -Ev '^(_template|_example-)'` to check for active work.

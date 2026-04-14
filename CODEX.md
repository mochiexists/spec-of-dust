# CODEX.md

Read `.spec/b-startup.md` on session start if it exists.
Read `AGENTS.md` for project context and workflow.
Read `.spec/FLOW.md` for the full `spec-of-dust` workflow.

## Codex specific

- When peer-reviewing, shell out to Claude: `cat .spec/changes/{name}.md | claude -p "..."`
- If the Claude CLI is not available, print the review prompt and ask the human to relay it
- If `.spec/b-startup.md` sets `teams: none | some | many`, respect it when deciding whether to spawn subagents.
- Codex subagents are explicit and cost more tokens, so prefer them for clearly parallel work rather than tightly coupled tasks.
- On session start, run: `ls .spec/changes/ | grep -Ev '^(_template|_example-)'` to check for active work

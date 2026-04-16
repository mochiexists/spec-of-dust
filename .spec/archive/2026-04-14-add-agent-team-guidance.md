status: done

# Add agent-team guidance

## What
Add a minimal policy for optional agent-team usage in `spec-of-dust`. Define a simple text-based teaming preference so users can signal how much parallel team usage they want, document when parallel teams are appropriate, and keep the guidance usable for both Codex and Claude without making agent teams mandatory.

## Acceptance criteria
- [ ] `.spec/b-startup.md` defines one user-facing teaming flag with concrete values, a default behavior, and examples
- [ ] `.spec/FLOW.md` explains when agent teams are appropriate and when they are not
- [ ] `CLAUDE.md` and `CODEX.md` each mention the teaming preference in no more than two added bullets per file
- [ ] The added guidance stays concise: no more than 8 net new lines in `.spec/b-startup.md`, and no more than 12 net new lines in each other touched file

## Notes
- Keep it optional and suggestive, not mandatory
- Emphasize token/cost awareness and use teams only when the work can actually parallelize
- Prefer a text flag that can live in `.spec/b-startup.md`
- Use `teams: none | some | many`
- If the flag is absent, default to `some`: conservative, bounded fan-out only when the work parallelizes cleanly

## Peer spec review
Summary for review: add a minimal `teams:` preference to `.spec/b-startup.md`, document when agent teams are useful in `.spec/FLOW.md`, and add one short note each in `CLAUDE.md` and `CODEX.md`.

Claude review:

- preference values needed to be explicit
- target files needed to be named
- default behavior when absent needed to be defined
- “does not materially bloat” needed a measurable budget

Valid feedback addressed:

- values narrowed to `teams: none | some | many`
- target files narrowed to `.spec/b-startup.md`, `.spec/FLOW.md`, `CLAUDE.md`, and `CODEX.md`
- absent flag now defaults to `some`
- brevity now has explicit line budgets

## Peer code review
Claude review:

- overall scope and symmetry were good
- `FLOW.md` had one redundant rules bullet repeating the agent-teams section
- `b-startup.md` needed to make it clearer that the user should set one live `teams:` value
- no correctness issues were found in the Codex/Claude guidance itself

Valid feedback addressed:

- removed the redundant `teams:` rules bullet from `.spec/FLOW.md`
- clarified in `.spec/b-startup.md` that users should set one live value only
- `CODEX.md` provenance is an edit, not a new file

## Verify
- [x] `.spec/b-startup.md` defines one user-facing teaming flag with concrete values, a default behavior, and examples
  Verified by `teams: none | some | many`, default `some`, and single-value examples in `.spec/b-startup.md`
- [x] `.spec/FLOW.md` explains when agent teams are appropriate and when they are not
  Verified by the `## Agent teams` section in `.spec/FLOW.md`
- [x] `CLAUDE.md` and `CODEX.md` each mention the teaming preference in no more than two added bullets per file
  Verified by two teaming bullets in each file
- [x] The added guidance stays concise: no more than 8 net new lines in `.spec/b-startup.md`, and no more than 12 net new lines in each other touched file
  Verified by final line counts after trim: `.spec/b-startup.md` +5, `.spec/FLOW.md` +11, `CLAUDE.md` +1, `CODEX.md` +2

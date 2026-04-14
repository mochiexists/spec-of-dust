# spec-of-dust Flow

This project uses `spec-of-dust`: a lightweight spec, review, and gate workflow.
No CLI tools, no slash commands.
You understand the flow by reading this file. You track state via change files in `.spec/changes/`.

## B:/ Start Up

On session start, read `.spec/b-startup.md` first if it exists.
Then read `AGENTS.md`, this file, and the active change file if one exists.
Do not auto-read the whole repo unless the task needs it.

## States

Every change moves through four states, tracked by the `status:` field in its change file:

```
spec → build → verify → done
```

**spec** — Think, plan, and define what we're building. Write the what and why.
Capture acceptance criteria as simple checkboxes. These become the verify checklist later.
Do NOT write code yet. When the spec feels complete, request a peer review (see below).

**build** — Implement the spec. Reference the acceptance criteria as you go.
When implementation is complete, request a peer review (see below).

**verify** — Walk through every acceptance criterion from the spec phase.
Check each one against the actual implementation. Mark pass/fail. If anything fails,
drop back to `build` and fix it before re-verifying.

**done** — All criteria pass, and the closure summary is filled in.
Before moving a standard change to `done`, add a short closure note with:
- `Challenges` — friction, surprises, or blockers during delivery
- `Learnings` — reusable lessons or follow-up insight
- `Outcomes` — the delivered result or visible effect, plus important peer-review or verify signal
- `Dust` — one short human or artistic line; keep it under 80 characters

Keep closure notes short. If the work was straightforward, write `nothing notable` instead of filler.
After `done`, completion moves into merge behavior:
- `merge: manual` means stop at `done` and wait for a human to merge
- `merge: confirm` means ask the human before invoking the merge helper; if the answer is no, stay at `done`
- `merge: auto` means the agent may invoke the merge helper directly once verify is complete, local gates have passed, and the repo is in a safe state

`merge-target` defaults to `main` when omitted.
Merge failure does not invent a new state: the change stays `done` and the error is reported.

## Change files

One file per change: `.spec/changes/{name}.md`

Use the template at `.spec/changes/_template.md`. The filename IS the change name.
Keep it lowercase-kebab-case. One active change per branch is typical but not enforced.
Files named `_template.md` and `_example-*` are scaffolding, not active changes.

The `status:` line at the top is how you (the AI) know where you are.
When you transition state, update that line. That's it. That's the state machine.

## Gates

A gate is a mechanical check that blocks unsafe progress.

`spec-of-dust` ships with a few default gates:

- commit gate: no code commit without an active change file, unless the skip rules pass
- skip gate: no `--no-verify` commit without a structured devlog entry and a truly trivial diff
- archive gate: finished change files move to `.spec/archive/` after merge

Repos should extend these gates to reflect real engineering policy:

- architecture boundaries
- linting and formatting
- type checks and builds
- unit and integration tests
- performance, security, or bundle-size limits where relevant

Keep local gates fast. Let CI run the strict superset.

## Merge And Advance

Merge behavior is configured in `.spec/b-startup.md`:

- `merge: manual | confirm | auto`
- `merge-target: <branch>` with default `main`

`FLOW.md` defines what those values mean; `.spec/b-startup.md` only carries the live values for this repo.

Use `bash scripts/merge-completed-work.sh` to advance completed work:
- on the merge target branch, it archives `done` change files and commits the archive move
- on a feature branch, it first archives and commits completed change files on that branch, then merges the branch into the configured target with `--no-ff`
- use `bash scripts/merge-completed-work.sh --auto` when running in `merge: auto` mode so the helper rechecks repo-local prerequisites before advancing

Safety rules:
- refuse to run outside a Git repo
- refuse dirty working trees, including untracked files
- refuse to run when no completed standard change file exists
- for `auto`, only run after verify is complete and local gates have passed; the helper rechecks repo-local prerequisites before merging

`confirm` is an explicit ask-to-merge step. If the human declines, stop and leave the change at `done`.
Do not auto-delete branches in this first pass.

## Agent teams

If `.spec/b-startup.md` includes `teams: none | some | many`, respect it as the user’s teaming preference.
If it is absent, default to `some`: use bounded parallel help only when the work splits cleanly.

- `teams: none` means stay single-agent unless the user explicitly asks otherwise
- `teams: some` means use a small number of focused parallel agents for clearly separable work
- `teams: many` means broader fan-out is acceptable for reviews, research sweeps, or repeated batch tasks

Use agent teams when the work is truly parallel: independent review axes, bounded research questions, or repeated items with the same output shape. Do not use them for the immediate blocking step, tightly coupled edits, or work that is too small to justify extra token and coordination cost.

## Peer review protocol

This project uses two AI models as adversarial peers. Before building and after building,
the other model reviews the work. This catches blind spots and prevents echo-chamber code.

Review with enough context to judge the change correctly, but do not turn every review into a whole-repo audit.

### Pre-build review (spec → build gate)

When the spec is ready, before changing status to `build`:

1. Write a summary of the spec into the `## Peer spec review` section of the change file
2. Shell out to the other model's CLI to get feedback:
   - If you are Claude Code: `cat .spec/changes/{name}.md | codex -q "Review this spec with only needed repo context: the active change file, directly referenced files, and obvious adjacent files. What's missing, ambiguous, risky, or overbuilt? Prioritize this change. Broader critiques are advisory unless they reveal a blocker: missed requirement, bug, unsafe design, or spec contradiction. Be blunt. Under 200 words."`
   - If you are Codex: `cat .spec/changes/{name}.md | claude -p "Review this spec with only needed repo context: the active change file, directly referenced files, and obvious adjacent files. What's missing, ambiguous, risky, or overbuilt? Prioritize this change. Broader critiques are advisory unless they reveal a blocker: missed requirement, bug, unsafe design, or spec contradiction. Be blunt. Under 200 words."`
3. Paste the response into `## Peer spec review`
4. Address any valid blocker feedback by updating the spec; record advisory broader critiques if they are worth keeping in mind
5. NOW change status to `build`

If the other model's CLI isn't available, ask the human to relay. Don't skip the review.

### Post-build review (build → verify gate)

When implementation is complete, before changing status to `verify`:

1. Collect the diff of all files changed: `git diff --name-only HEAD~{n}` or staged files
2. Shell out to the other model:
   - If you are Claude Code: `git diff --staged | codex -q "Review this diff against the spec in .spec/changes/{name}.md with only needed repo context: the spec, changed files, directly referenced files, and obvious adjacent files. What bugs, missed requirements, risky assumptions, related errors, or style issues do you see? Prioritize this change. Broader critiques are advisory unless they reveal a blocker. Be blunt. Under 300 words."`
   - If you are Codex: `git diff --staged | claude -p "Review this diff against the spec in .spec/changes/{name}.md with only needed repo context: the spec, changed files, directly referenced files, and obvious adjacent files. What bugs, missed requirements, risky assumptions, related errors, or style issues do you see? Prioritize this change. Broader critiques are advisory unless they reveal a blocker. Be blunt. Under 300 words."`
3. Paste response into `## Peer code review`
4. Address any valid blocker issues; record advisory broader critiques if they matter to follow-up work
5. NOW change status to `verify`

## Fast path for trivial changes

Some changes are too small for the full flow: typos, version bumps, comment tweaks,
or a one-line fix with obvious intent. Those may skip the full spec file, but only when
the diff is truly boring.

Skip protocol:

1. Append one JSON object to `.spec/devlog.jsonl`
2. Use `event: "skip-no-verify"` and one allowed `kind`:
   - `typo`
   - `version-bump`
   - `comment`
   - `config-tweak`
   - `one-line-fix`
3. Include a short `summary`, a concrete `reason`, the changed `files`, and
   `command: "git commit --no-verify"`
4. Stage the devlog entry and commit with `git commit --no-verify`
5. Do not request peer review for skip commits

Hard boundaries:

- Skip commits are only for truly trivial changes, not "small but still meaningful" work
- If the diff needs design discussion, touches multiple code files, adds a file, deletes
  a file, renames a file, or changes more than a handful of lines, do the normal flow
- If you're unsure whether it qualifies, it does not qualify. Use a minimal standard spec instead

## Monorepo note

`spec-of-dust` is meant to work in single-project repos and monorepos.

- Prefer `apps/` for deployable services and frontends
- Prefer `packages/` for shared modules, schemas, config, and tooling
- Keep repo-level docs in `docs/` so the root stays readable
- Scope local gates to touched projects when possible, then let CI expand to affected or full-repo checks

## Rules for the AI

- When you open a project, start with `.spec/b-startup.md` if present, then check `.spec/changes/` for any active change files.
  Ignore `_template.md` and `_example-*`. If one real change exists with status other than `done`,
  you are mid-flow. Resume from that state.
- If no change file exists and the human asks for a feature/fix, create one from the template
  and start in `spec` state. Don't jump straight to code.
- Don't over-spec. A spec is 10-30 lines, not a PRD. It's a checklist, not a contract.
- The acceptance criteria you write in spec become the verification checklist in verify.
  Write criteria you can actually check mechanically (test passes, UI renders, API returns X).
- Before marking a standard change `done`, fill the `## Closure` section with concise notes for
  `Challenges`, `Learnings`, `Outcomes`, and `Dust`. Capture what actually happened during the work,
  including important peer-review or verification takeaways in `Outcomes`, not a rewritten version of the spec.
- If the human says "just do it" or "skip the spec," you can — but note it in `.spec/devlog.jsonl`.
  Some changes are too small for the full flow, but skip commits still need a structured devlog entry.
- Small changes (< 30 min of work, single-file, obvious intent) can use a minimal spec:
  just a one-liner description and 1-2 acceptance criteria. Don't force ceremony on trivia.
- Minimal spec and skip commits are different:
  - minimal spec = still goes through peer review and verify
  - skip commit = only for trivial, mechanical diffs and must be documented in `.spec/devlog.jsonl`

# architect-of-dust Flow

A lightweight architecture, review, and gate workflow. No CLI tools, no slash
commands. Track state via change files in `.spec/changes/`.

## Context budget

- **Bootstrap** (target: 3k tokens) — framework cost: `FLOW.md` + `b-startup.md`
- **Operational** (target: 5k tokens) — bootstrap + project files:
  `AGENTS.md`, `CLAUDE.md`/`CODEX.md`, active change

Visibility targets, not hard gates. Keep the bootstrap tight.

## B:/ Start Up

On session start, read `.spec/b-startup.md` if it exists, then `AGENTS.md`,
this file, and the active change file. Do not auto-read the whole repo unless
the task needs it.

## States

Every standard change moves through four states via the `status:` field in its
change file:

```
architect -> build -> verify -> present
```

**architect** — Define the change before writing code. Capture the intent,
ordering, constraints, and checks. This is architecture work, not PRD writing.
When ready, request peer architecture review.

**build** — Implement the change. Keep edits within the declared scope and
follow the testing guidance below. When complete, request peer code review.

**verify** — Check every listed check against the implementation. Pass/fail
each one. If anything fails, return to `build`.

If the requested outcome targets an external repo, site, or deployed system,
verify against that real target before claiming the change is implemented there.
If the external target was not changed or checked, say so explicitly and report
the result as local prep or documentation only.

**present** — The change is locally implemented, reviewed, and verified. Before
setting `status: present`:
1. Fill `## Closure` with `Challenges`, `Learnings`, `Outcomes`, and `Dust`
   (one short artistic line, under 80 chars). Use `nothing notable` if
   straightforward.
2. Append a flowlog entry via `bash scripts/flowlog.sh` with `--change`,
   `--agent`, `--sentiment` (`smooth|rough|blocked`), and optional
   `--divergence`, `--friction`, `--suggestion`.
3. Set `status: present`.
4. Commit that completed change before starting or stacking more standard work.
   `present` is a closeout boundary, not a parking state.

After `present`, one of four outcomes applies:
- merge/archive the completed change
- continue with a new follow-up change
- split work into smaller follow-ups
- reopen the same change by moving back to `architect` or `build`

In closure and final reporting, do not say `live`, `published`, or `delivered`
for an external target unless that target was actually changed and checked.
If implementation is complete locally but push, merge, or deploy is blocked by
account, author, or permission restrictions, say that plainly.

## Change files

One file per change: `.spec/changes/{name}.md` (lowercase-kebab-case). Use the
template at `.spec/changes/_template.md`. Files named `_template.md` and
`_example-*` are scaffolding.

The `status:` line is the state machine. Update it to transition.

`status: shelved` is allowed for intentionally parked work. Shelved changes stay
in `.spec/changes/` for reference, but they do not count as active or completed
work and should be resumed by moving them back to `architect`.

## Ordering

AoD treats sequencing as first-class. Every non-trivial change should say how it
fits into larger work.

Use `## Ordering` in the change file to capture:
- prerequisites this change depends on
- what this change unlocks next
- phase or sequencing notes when work lands in slices

This is documentation first, not a gate. The point is to stop large efforts
from hiding dependency order inside prose.

## Gates

Mechanical checks that block unsafe progress:

- **commit gate**: no code commit without an active change file (status
  `build|verify|present`), unless skip rules pass
- **present-closeout gate**: a dirty `present` change can only travel with its
  closeout artifacts; commit it before more work proceeds
- **scope gate**: if the active change has a `files:` field, staged non-exempt
  files must match it
- **skip gate**: `--no-verify` requires a structured devlog entry and a truly
  trivial diff
- **archive gate**: finished change files move to `.spec/archive/` after merge

Extend these gates with your repo's engineering policy. Keep local gates fast;
let CI run the strict superset.

### External actions (not mechanically gated)

The commit-time gates above cannot see `gh` CLI calls, `curl` writes, or other
external API actions. A partial mechanical check exists for git pushes (see
below), but most external publishing escapes gating entirely.

**Load-bearing advisory rule:** before running any command that writes to an
external system — `gh repo create`, `gh release create`, `gh api`
(`POST|PUT|DELETE`), `curl` to deploy/publish, SSH-based deploys — you MUST
have an active change file naming the target. No active change = stop and create
one.

**Mechanical backstop:** `.githooks/pre-push` warns (does not block) when a
publishing-pattern push (tag push, or new remote branch) happens with no active
change. Bypass with `AOD_PUBLISH_ACK=1` when you have intentionally
acknowledged the absence. `SOD_PUBLISH_ACK=1` remains accepted as a compatibility
shim.

## Testing

- **Bug fixes**: write a failing test that reproduces the bug first. Fix the
  code. Observe green. Don't edit test logic to force the pass.
- **New behavior**: checks that describe observable behavior should have a
  corresponding test where the project has a test harness. If no harness exists,
  note that in the change file's Notes section.
- **Test integrity**: updating expectations or fixtures for intentional behavior
  changes is fine. Changing test control flow or weakening assertions to make a
  failing test pass is not.
- These are guidance, not mechanical gates. The project decides what to test and
  how. AoD just steers toward testability by default.

## Merge

Configured in `.spec/b-startup.md` via `merge: manual | confirm | auto` and
`merge-target: <branch>` (default `main`).

- **manual**: stop at `present`, wait for human
- **confirm**: ask the human; if declined, stay at `present`
- **auto**: agent runs `bash scripts/merge-completed-work.sh --auto` after
  verify passes and local gates are clean

The merge helper archives `present` change files on the target branch, or
archives then merges with `--no-ff` from a feature branch. It refuses dirty
trees, missing Git repos, and missing completed changes. Merge failure keeps the
change at `present` and reports the error. Do not auto-delete branches.

## Push

Configured in `.spec/b-startup.md` via `push: never | confirm | auto`
(default `never`). Push only applies when the merge helper runs; it has no
effect with `merge: manual`.

- **never**: no push after merge/archive (default)
- **confirm**: the merge helper prints `Push ready. Run git push origin <target>`
- **auto**: the merge helper runs `git push origin <merge-target>` after a
  successful archive commit

Push failure is reported but does not undo the local archive. If no remote
`origin` exists, push is skipped with a warning.

### Post-push health

After any push (direct or via `merge-completed-work.sh`), run
`bash scripts/check-deploy-health.sh`. Per-exit-code action:

- `0` — all green. Surface the success line and deploy-confirmation URL.
- `1` — at least one workflow failed. Surface the failure summary. Draft
  `.spec/changes/fix-ci-{short-description}.md` at `status: architect` with the
  workflow name, run ID, failed step, and run URL in `## Intent`. Wait for user
  confirmation before moving to `build`.
- `2` — runs still in progress. Report that CI is still running.
- `3` — environment issue (`gh`, auth, upstream, or runs missing). Report the
  environment problem and do not draft a fix change.

## Self-update

AoD updates itself through its own workflow. On session start, the agent checks
whether it should look upstream for a newer version.

Configured in `.spec/b-startup.md`:
- `aod-upstream:` — local filesystem path to the architect-of-dust source repo.
  Empty means skip the check.
- `aod-check-interval: 30d` — how often to check. Format is `Nd` (days).

State lives in `.spec/aod-last-checked` (ISO date, one line). This file is
gitignored: it is per-clone local state, not tracked.

**Protocol**:
1. Skip if any other change is active (`architect`, `build`, or `verify`).
2. Skip if `aod-upstream:` is empty or missing.
3. Skip if `.spec/aod-last-checked` is newer than `aod-check-interval`.
4. Read upstream `VERSION` from `$aod-upstream/VERSION`. Compare semver.
5. If upstream > local, create `.spec/changes/update-aod-to-v{X}.md`
   describing the framework diff. Normal
   `architect -> build -> verify -> present` flow applies.
6. If the check actually ran, write today's date to `.spec/aod-last-checked`.

The agent does not auto-apply updates. It proposes the change.

## Agent teams

Respect `teams:` in `.spec/b-startup.md` (`none | some | many`; default
`some`). Use teams only for truly parallel work: independent reviews, bounded
research, repeated batch items. Do not use them for blocking steps, tightly
coupled edits, or work too small to justify the cost.

## Peer review

Two AI models review adversarially: before building (architecture review) and
after building (code review).

### Shared review rules

- Scope context to the change file, changed files, directly referenced files,
  and obviously adjacent files
- Prioritize this change; broader critiques are advisory unless they reveal a
  blocker
- If the other CLI is unavailable, ask the human to relay. If the tooling hangs
  or times out, record that explicitly in the change and proceed only if the
  work remains tightly scoped

### Pre-build (`architect -> build`)

1. Shell out:
   `cat .spec/changes/{name}.md | <other-cli> "Review this change using nearby repo context only. What's missing, ambiguous, risky, or overbuilt? Prioritize this change. Broader critiques are advisory unless they reveal a blocker. Under 200 words."`
   - Claude Code uses `codex exec`
   - Codex uses `claude -p`
2. Paste the response into `## Peer architecture review`, address blockers,
   then set `status: build`

### Post-build (`build -> verify`)

1. Stage changes, then:
   `git diff --staged | <other-cli> "Review this diff against .spec/changes/{name}.md using nearby repo context only. Bugs, missed requirements, style issues? Prioritize this change. Broader critiques are advisory unless they reveal a blocker. Under 300 words."`
2. Paste the response into `## Peer code review`, address blockers, then set
   `status: verify`

## Skip path

For truly trivial changes (typos, version bumps, comments, config tweaks,
one-line fixes):

1. Run `bash scripts/devlog.sh --kind KIND --summary TEXT --reason TEXT --file PATH`
2. Stage the devlog entry and commit with `git commit --no-verify`

Skip disqualifiers:
- adds, deletes, or renames a file
- touches multiple code files
- changes more than a handful of lines
- needs design discussion
- if you are unsure, it does not qualify

## Monorepo

Works in single-project and monorepo layouts. Use `apps/` for services,
`packages/` for shared modules, `docs/` for documentation. Scope local gates to
touched projects.

## Rules for the AI

- On session start, check `.spec/changes/` for active changes (ignore
  `_template.md`, `_example-*`, and any file at `status: shelved`). Resume only
  changes in `architect`, `build`, or `verify`.
- No change file + human request = create one from the template at
  `status: architect`. Do not jump to code.
- Architecture notes are 10-30 lines, not PRDs. Write mechanically checkable
  checks.
- If the user wants a real change to an external repo, site, or deployed
  system, the architect and verify steps must name that target and verify it
  before reporting the outcome as live.
- If external publishing may require a specific Git identity or only the human
  operator, record that expectation before trying to publish.
- Small changes can use a minimal architecture note (one-liner + 1-2 checks).
  Skip commits are different: trivial only, logged in devlog.
- `Just do it` from the human does not waive the workflow. If the change is
  small enough, use skip mode; otherwise create the change file.

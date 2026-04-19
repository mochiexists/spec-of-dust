status: build
files: scripts/check-deploy-health.sh, .spec/FLOW.md, CLAUDE.md, AGENTS.md, CODEX.md, tests/test-workflow-scripts.sh

# Post-push health check and error-to-sod loop

## What
Today the agent can push (either directly or via `merge-completed-work.sh --push auto`) and never notice if CI on the remote fails. Emails arrive for the human, but the agent's mental model stays "shipped, green, done." Build a lightweight post-push health check that (a) queries recent GitHub Actions runs for the pushed ref, and (b) surfaces failures. Then add a FLOW.md rule that the agent runs this after any push and, on failure, drafts a `fix-ci-*` change file at `status: spec` for user confirmation before proceeding.

Crucially: do NOT fix the known locale-related sod-check failure yet. Use it as a live test fixture for this mechanism. If the new check correctly detects the existing failure on `main` and would draft a fix spec, the mechanism is working.

## Acceptance criteria
- [ ] New `scripts/check-deploy-health.sh` that resolves the current branch's upstream via `git rev-parse --abbrev-ref @{upstream}`, extracts the remote-side branch name (the part after `origin/`), and queries `gh run list --branch <branch> --json ...` for recent runs. If no upstream or HEAD is detached, exits 3 with a clear message.
- [ ] Output format is human-readable AND agent-parseable. On failure, prints per-workflow: workflow name, run ID, failed-step name (or `<multiple>` / `<unknown>` if step data is missing/multiple), run URL.
- [ ] Exit codes (strict semantics; these map to distinct agent actions): `0` = latest completed run per workflow is success AND no workflows have failed latest-completed; `1` = at least one workflow's latest completed run failed; `2` = no completed runs yet for this push but runs are in progress; `3` = no runs found, `gh` missing, not authenticated, no upstream configured, or network error.
- [ ] Precedence rule: if any workflow's latest completed run is `failure`, exit `1` regardless of other in-progress runs. In-progress runs (`2`) only apply when zero completed runs exist yet for the relevant commits.
- [ ] Failure extraction fallback: use `gh run view --json jobs` to find failed steps. If zero failed steps are reported (rare, but happens), print `<unknown step>`. If more than one step failed in a single run, print `<multiple steps>` and include the first two names.
- [ ] Script requires `gh` CLI. Missing/unauthenticated `gh` → exit 3 with clear stderr message. Do NOT pretend green.
- [ ] FLOW.md gains a "Post-push health" subsection under "Push" explaining per-exit-code agent action:
  - `0`: continue
  - `1`: surface failures, draft a `fix-ci-{short-description}.md` at `status: spec` with error excerpt in What, wait for user confirmation
  - `2`: report "CI still running" — do NOT draft a fix spec, re-check next session or after brief wait
  - `3`: report the environment issue (no `gh`, no upstream, etc.); do NOT draft a fix spec since we have no signal
- [ ] Symmetric load-bearing rule added to CLAUDE.md, AGENTS.md, CODEX.md: "After any `git push` (direct or via merge-completed-work.sh), run `bash scripts/check-deploy-health.sh` and act per the exit-code semantics in FLOW.md."
- [ ] Offline test in `tests/test-workflow-scripts.sh` exercises parsing logic via a mock `gh` (shim script on `PATH` that returns canned JSON) — covers exit 0 (all green), exit 1 (one failed), exit 2 (all in-progress), exit 3 (gh missing). Network-free, deterministic.
- [ ] Verify evidence (not an AC gate): after this change lands, agent runs the real script against `origin/main` and the output is captured in the Verify section. If the existing sod-check failure is still present, the mechanism catches it; if CI has since been fixed, the evidence is "all green" and that's also valid.

## Notes
- The agent isn't running the script *itself* mechanically; the rule in FLOW.md + CLAUDE/AGENTS/CODEX instructs the agent to run it. The script is the tool the agent calls.
- Don't auto-create the fix spec from within the script — the agent decides the name and content based on what failed. The script reports; the agent drafts.
- Not a cron or polling daemon. One-shot script called at the right moment in the flow.
- The "exit 2 for in-progress" case is important: if the agent just pushed, runs may be queued. The agent can decide to wait briefly and re-check, or surface "CI still running, will check again next session."
- Keep `gh` usage minimal: `gh run list --branch <ref> --limit N --json ...` and `gh run view <id> --json ...`. Avoid heavyweight calls.
- Scope: this change only adds the mechanism. The locale-related sod-check failure is handled in a separate follow-up sod once the mechanism has caught it.

## Peer spec review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: exit-code semantics conflicted with FLOW action ("any non-zero draft a fix-ci spec" was wrong for 2/3). → Fixed: FLOW.md rule now enumerates per-exit-code behavior (0 continue, 1 draft, 2 wait, 3 environment issue).
2. Blocker: upstream resolution ambiguous for `gh --branch`. → Fixed: AC now specifies `git rev-parse --abbrev-ref @{upstream}` and extracting the branch part; detached HEAD / missing upstream → exit 3.
3. Risk: precedence between failing completed and running workflows undefined. → Fixed: AC adds explicit precedence rule (failure wins over in-progress).
4. Risk: hard AC on external state (current CI failure) is brittle. → Fixed: moved real-remote verification to evidence-in-Verify, not a gating AC. Offline fixture is the stable requirement.
5. Missing: failure extraction fallback when step data is absent or multiple steps failed. → Fixed: `<unknown step>` / `<multiple steps>` fallbacks named in AC.


## Peer code review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: runs weren't scoped to the pushed HEAD sha — an older green run on the same branch could mask a failing fresh push. → Fixed: script now reads `git rev-parse HEAD` and filters `gh run list` results to runs matching that sha.
2. Medium: `cancelled` was treated as failure but often means "superseded" (not a real problem). → Fixed: only `failure` and `timed_out` count as failures. `cancelled` is ignored.
3. Medium: no offline test for `command -v gh` missing path. → Fixed: added `check_deploy_health_exit_3_on_gh_missing` using `PATH="/usr/bin:/bin"` (gh lives in /opt/homebrew/bin on this machine, so PATH-stripping exercises the `command -v` branch).
Advisory: detached-HEAD precision — acceptable as-is for now.


## Verify
- [pass] `scripts/check-deploy-health.sh` exists, executable, resolves upstream via `git rev-parse --abbrev-ref @{upstream}`, extracts branch, scopes runs to current HEAD sha
- [pass] Output includes workflow name, run ID, failed step, URL — human- and agent-parseable
- [pass] Exit codes 0/1/2/3 all implemented per the spec; failure takes precedence over in-progress (verified by test)
- [pass] `gh` missing → exit 3; unauthenticated → exit 3; no upstream → exit 3; no HEAD sha → exit 3; no runs found → exit 3; `gh run list` network failure → exit 3
- [pass] Failure extraction uses `gh run view --json jobs`, falls back to `<unknown step>` or `<multiple steps: a, b>` as specified
- [pass] Only `failure` and `timed_out` trigger exit 1; `cancelled` is ignored
- [pass] FLOW.md "Post-push health" subsection added with per-exit-code agent behavior
- [pass] CLAUDE.md, AGENTS.md, CODEX.md all have the symmetric load-bearing rule
- [pass] 6 offline tests covering all exit code branches + precedence + gh-missing + unauthenticated
- [pass] **Live dogfood test**: running `bash scripts/check-deploy-health.sh` against this repo's current state correctly catches the existing sod-check CI failure:
  ```
  ⚠️  CI failures on branch 'main':
    workflow:    Validate
    run-id:      24630159048
    failed-step: Check sod outputs
    url:         https://github.com/mochiexists/spec-of-dust/actions/runs/24630159048
  ```
  Exit 1. The mechanism works in the real world. Next step (after this change lands): agent drafts a `fix-ci-sod-locale` change per the FLOW.md rule, user confirms, we sod the locale fix.


## Closure
- Challenges: shim heredoc had a brace-ambiguity issue in `${VAR:-{default}}` parameter expansion; `set -e` combined with command substitution `x=$(cmd); status=$?` needed `cmd && rc=0 || rc=$?` pattern to capture exit codes reliably; scoping runs to HEAD sha was a late but important correction from peer review
- Learnings: when shimming external tools for tests, keep defaults simple — avoid nested braces in parameter expansion; gh run queries must filter to HEAD sha or older runs can mask current failures; the "cancelled" conclusion is distinct from "failure" and drafting fixes for it is noisy
- Outcomes: agentic deploy now has a real post-push feedback loop. Live test against the failing CI on main proved the mechanism works end-to-end before it was committed. Zero-dependency (bash + python3 + gh), no daemons, no polling.
- Dust: the framework now watches what it ships, and asks for permission to fix it

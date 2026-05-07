status: shelved
files:
  - .spec/FLOW.md
  - AGENTS.md
  - CLAUDE.md
  - CODEX.md
  - scripts/check-gh-identity.sh
  - scripts/merge-completed-work.sh
  - setup.sh
  - .spec/b-startup.md

# gh-identity per-repo check

## What
Commit author identity and `gh auth` active account can silently drift out of alignment with the target repo, so work proceeds under the wrong identity. This was observed on the `mochiexists/site` repo: a full session of commits was authored as `atlascodesai` when the target required `mochiexists`, and the mismatch only surfaced as a 403 on `git push`. By then the commit history was already wrong.

Fix the class of bug by moving the identity check to **session start**, pinned per project in `.spec/b-startup.md` via a new optional `gh-account:` key. When the pinned account does not match the active `gh auth` account or `git config user.email`/`user.name`, surface the exact recovery commands and ask the user to confirm before further work. Do not auto-switch. Keep a cheap second check at push time as belt-and-braces.

## Acceptance criteria
- [ ] `.spec/b-startup.md` schema documents an optional `gh-account: <name>` key (default: unset → probe-based). `setup.sh` b-startup template lists it as commented-out.
- [ ] New `scripts/check-gh-identity.sh` exits 0 when aligned, exits 1 with a clear diagnostic + recovery commands when misaligned, and exits 0 with a warning when the pin is unset and no origin exists.
- [ ] When `gh-account: <name>` is set, the script compares it against (a) the active account reported by `gh auth status` and (b) `git config user.email`. Email match rule is local-only: the email must match one of these exact forms — `<name>@users.noreply.github.com`, `*+<name>@users.noreply.github.com`, or a value explicitly allow-listed in `.spec/b-startup.md` via an optional `gh-email: <addr>` key. No `gh api` call and no live network is used for the email check. `user.name` is informational only — logged but not gated.
- [ ] When `gh-account:` is unset and an `origin` remote on `github.com` exists, the script probes `gh api repos/<owner>/<repo> --jq .permissions.push` across each authenticated account from `gh auth status`. Result handling: 0 matches → exit 1 with "no authorised account" diagnostic naming owner + accounts tried; exactly 1 match → exit 0 if that account is active and email aligns per the rule above, else exit 1 with recovery commands; ≥2 matches → exit 1 with "ambiguous authorisation, set `gh-account:` in `.spec/b-startup.md`" listing the candidates. Ordering of `gh auth status` is not used as a tie-break.
- [ ] Non-`github.com` origins (e.g. `github.platform.vwfs.io`) and the "unset pin + no origin" branch both exit 0 with a one-line debug note and no diagnostic spam.
- [ ] On any exit 1, stderr includes the exact commands to fix: `gh auth switch --user <name>`, `git config user.email <addr>`, `git config user.name <name>`. The script does NOT run them.
- [ ] Agent behavior on exit 1 is documented (not enforced by the script): `.spec/b-startup.md`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md` each instruct the agent to run `bash scripts/check-gh-identity.sh` on session start, and on non-zero exit to stop, print the script output to the user, and wait for explicit confirmation before any commit or push. The script's job is correct diagnosis; enforcement is the agent's.
- [ ] `scripts/merge-completed-work.sh` calls `check-gh-identity.sh` only on the `push: auto` path, before `git push`. On exit 1 it aborts the push and forwards stderr; the archive commit still completes. `push: confirm` and `push: never` do not invoke the check (agent already ran it at session start).
- [ ] `FLOW.md` gets a new short subsection "gh identity per repo" under External actions, documenting the pin, the session-start check, the reason (commit author drift, not just push perms), and the recovery path. One paragraph, no more.
- [ ] This repo's own `.spec/b-startup.md` gains `gh-account:` — leave unset (probe mode) since the framework repo has no fixed publisher. Document the choice inline.
- [ ] New test under `tests/` covering all branches: pin matches active account + email (exit 0); pin set but active account wrong (exit 1 + recovery commands in stderr); pin set but email wrong (exit 1); unset pin + probe with stubbed `gh` → zero matches (exit 1); exactly one match and aligned (exit 0); exactly one match but misaligned (exit 1); ≥2 matches (exit 1 with "ambiguous"); non-`github.com` origin (exit 0 with debug note); no origin (exit 0 with debug note). All stubs via env vars, no network.
- [ ] `bash scripts/update-aod-report.sh` run and staged after changes.

## Notes
- External target for this change: `architect-of-dust` framework itself. Completion means "implemented and verified in this repo"; downstream adoption (e.g. site repo adding `gh-account: mochiexists`) is out of scope for this change and tracked separately.
- Deliberately no auto-switch. The user's instruction was "print and ask the user to confirm" — keeping the human in the loop avoids surprise account flips mid-session, which have their own blast radius (other repos in the same shell session inherit the active account).
- The script must not make live `gh api` calls in CI or tests — probe path needs a stub-friendly entry point (env var like `SOD_GH_PROBE_ACCOUNTS` to inject the candidate list, `SOD_GH_PROBE_CMD` to override the probe command).
- Email format note: GitHub noreply emails take two forms — `<username>@users.noreply.github.com` (older) and `<id>+<username>@users.noreply.github.com` (newer). The check should accept either form that contains the pinned account name after the `+` or before the `@`.
- Do NOT extend to non-GitHub remotes (e.g. `github.platform.vwfs.io`) in this change. Keep scope to `github.com`; the probe skips other hosts with a debug note.
- Expected Git author identity for this change: whatever this repo normally uses (`mochiexists <…>` per prior archive notes). The framework repo is `push: never`, so the human operator handles any publish.
- Shelved on 2026-05-07 before implementation resumed. Reason: the framework is about to be renamed/reframed around `architect-of-dust`, so session-start identity policy should be revisited against the new state model and terminology instead of landing against the old SoD wording first.

## Peer spec review
Codex (2026-04-21):
- Blocker: email match rule was underspecified and Notes forbid live network — addressed by pinning the rule to exact local forms (`<name>@users.noreply.github.com`, `*+<name>@users.noreply.github.com`, or `gh-email:` allow-list) and stating no `gh api` is used for the email check.
- Blocker: probe "first-true-wins" is non-deterministic and can pick the wrong commit identity — addressed: ≥2 matches now exits 1 with "ambiguous, set `gh-account:`"; single-match is only green if active + email also align.
- Blocker: "ask user to confirm" is not enforceable from a shell script — addressed by separating concerns: script diagnoses and exits 1; agent behavior on exit 1 is documented in AGENTS/CLAUDE/CODEX/b-startup (stop, surface, wait).
- Advisory: skipping the check in `push: confirm` merge path — adopted; only `push: auto` invokes it.
- Advisory: missing tests for non-`github.com` and no-origin branches — adopted; both added to the test AC.


## Peer code review
<!-- Filled by Codex after build completes. -->


## Verify
<!-- During verify: copy acceptance criteria here, mark pass/fail with notes. -->


## Closure
<!-- Filled at done. -->
- Challenges:
- Learnings:
- Outcomes:
- Dust:

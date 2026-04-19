status: done
files: scripts/update-sod-report.sh, tests/test-workflow-scripts.sh, .spec/sod-report.md, README.md

# Fix locale-name matching + add --check diagnostics

## What
Previous fix (fix-ci-sod-locale) added a UTF-8 locale probe that hard-fails if no match is found. It works on macOS (matches `en_US.UTF-8`) but fails on ubuntu-latest because Ubuntu's `locale -a` prints `C.utf8` (lowercase, no hyphen) — my probe only looked for the canonical `C.UTF-8` form. The hard-fail then fires and CI fails with an unhelpful silent exit 1 because `--check` doesn't print diffs.

Two narrow, paired fixes:
1. Make the locale probe tolerant of canonical-name variations (`C.UTF-8` / `C.utf8`, `en_US.UTF-8` / `en_US.utf8`) by normalizing before comparison.
2. Make `--check` emit a useful diff when it fails, so the next unknown mismatch is self-debugging without needing docker or a temporary CI tweak.

Detected via the post-push health check loop on commit 71a482a after fix-ci-sod-locale shipped. Traced to the locale probe by running the script in a fresh `ubuntu:latest` docker container.

## Acceptance criteria
- [ ] Locale probe in `scripts/update-sod-report.sh` normalizes both the candidate list and `locale -a` output before comparing: lowercase + strip hyphens. So `C.UTF-8`, `C.utf8`, `C.UTF8`, and `c.utf-8` all match each other.
- [ ] When the probe succeeds, the script uses the actual system-reported locale name (e.g. `C.utf8` on Ubuntu, `en_US.UTF-8` on macOS) as `UTF8_LOCALE`, not the canonical form — so `LC_ALL=` assignments work on the current system.
- [ ] Hard-fail message unchanged (still clear, still exits non-zero) when genuinely no UTF-8 locale exists.
- [ ] `scripts/update-sod-report.sh --check` on mismatch emits a diff (via `diff -u` or similar) between expected and actual outputs for `.spec/sod-report.md` and `README.md`, written to stderr, before exiting 1. When they match, stays silent as today.
- [ ] Per-file diff bound: if the diff for any single file exceeds 200 lines, truncate that file's diff with a "[diff truncated at 200 lines — run `bash scripts/update-sod-report.sh` to see the full generated output]" notice. Truncation applies per file independently. Exit status remains 1 regardless of truncation.
- [ ] Script supports a `SOD_LOCALE_LIST_CMD` env override for the `locale -a` command so tests can inject a fake locale listing. Default remains `locale -a` in production.
- [ ] Regression test in `tests/test-workflow-scripts.sh`:
  - Assert locale matching works when the fake `locale -a` returns only `C.utf8` (lowercase, no hyphen) — reproduces the exact Ubuntu failure that caused this spec to exist. Script must succeed and set `UTF8_LOCALE=C.utf8`.
  - Assert `--check` produces a diff on stderr when the committed `.spec/sod-report.md` is out of sync with what the script generates (mutate the committed file, run `--check`, assert stderr contains a `diff -u`-style marker like `---` or `+++` and exit 1).
- [ ] `.spec/sod-report.md` and `README.md` regenerated if the new match changes anything.

### Post-push verification (deferred, not a gate for done)
This repo is `push: never`, so pushing is a separate human-approved step. Post-push verification (run `scripts/check-deploy-health.sh`, confirm exit 0 + deploy URL) happens once the fix is pushed. It's the evidence that closes the loop, recorded in flowlog, but NOT a blocking AC for marking this change done.

## Notes
- Docker is deliberately NOT a dependency of this repo. It was useful for tracing this specific failure but shouldn't be required by any workflow or test. The diagnostics addition is exactly so we don't need docker to understand future failures.
- Normalization-based matching is more robust than hardcoding every spelling variant. The cost is a tiny shell function.
- The test seam (`SOD_LOCALE_LIST_CMD`) is intentionally minimal — env-var-based injection keeps the production code path unchanged. No refactor of `main()` or extraction of a library module.
- Emitting the diff on --check failure is a general usability win, not just a debugging crutch — pre-commit gate messages already tell users to run `update-sod-report.sh`, but now `--check` failures in CI give immediate actionable detail without needing a separate run.

## Peer spec review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: post-push verification was a gating AC but repo is `push: never` — made verify depend on an external action. → Fixed: moved to a separate "Post-push verification (deferred, not a gate for done)" section; evidence only.
2. Risk: locale-test AC required unit-testing a helper but script has no seam today. → Fixed: added explicit `SOD_LOCALE_LIST_CMD` env override as the seam. Test injects a fake `locale -a` returning only `C.utf8`.
3. Ambiguous: "say, 200 lines" diff bound. → Fixed: per-file 200-line truncation, exit status 1 regardless, explicit notice text.
Advisory: test via fake locale seam, not unit-testing the helper. → Addressed with the `SOD_LOCALE_LIST_CMD` env approach.


## Peer code review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: hard-fail message wording drifted from spec ("tried" vs "looked for under any spelling"). → Fixed: restored original wording.
2. Blocker: `printf | head` in `emit_bounded_diff` fails under `set -euo pipefail` (SIGPIPE 141) when diff exceeds bound, aborts script before truncation notice. → Fixed: write diff to temp file first, then `head`/`cat` from file. No pipe, no SIGPIPE.
3. Missed requirement: Ubuntu-locale test didn't assert exact locale name was used. → Fixed: test now sources the script (guarded with `[ "${BASH_SOURCE[0]}" = "$0" ]` check at the bottom so sourcing doesn't execute main), inspects `$UTF8_LOCALE`, asserts it equals `C.utf8` (not `C.UTF-8`).
Advisory: `SOD_LOCALE_LIST_CMD` is unquoted — brittle for paths with spaces. → Accepted as low-risk; tests use simple paths.

Note: real-world Ubuntu-docker validation confirmed the locale probe now matches `C.utf8` (character counts identical to macOS). The `--check` diff output correctly surfaces a remaining word-count discrepancy (`wc -w` behaves differently in BSD vs GNU even with same locale). That's a separate sod — this change delivers the diagnostics mechanism that makes it findable.


## Verify
- [pass] Locale normalization works: `C.utf8` matches `C.UTF-8` candidate after normalization
- [pass] Exact system name preserved: test asserts `UTF8_LOCALE=C.utf8` when system reports `C.utf8` (not canonical `C.UTF-8`)
- [pass] Hard-fail message unchanged: still lists the tried canonical names exactly
- [pass] `--check` diff emission: unified diff format to stderr, per-file, 200-line truncation with clean notice, no SIGPIPE hazards
- [pass] Test seam `SOD_LOCALE_LIST_CMD` injects fake locale listings; defaults to `locale -a`
- [pass] Three regression tests covering match, hard-fail, and diff emission
- [pass] Script guarded with `[ "${BASH_SOURCE[0]}" = "$0" ]` so sourcing in tests doesn't execute main
- [pass] All 22 workflow tests green; 22 hook tests green
- [pass] Real Ubuntu validation via docker: `update-sod-report.sh --check` now correctly matches `C.utf8`, character counts identical to macOS. Remaining word-count discrepancy (BSD vs GNU `wc -w`) is visible in the new diff output — next sod's territory.


## Closure
- Challenges: locale name spellings are inconsistent across systems (macOS en_US.UTF-8 vs Ubuntu C.utf8); `set -o pipefail` + `head` truncation is a subtle SIGPIPE trap that only bites on large inputs; user convinced me not to skip peer review (correctly) — Codex caught 3 real issues including the SIGPIPE hazard that I wouldn't have caught myself
- Learnings: when implementing "warn/truncate on large inputs," write output to a temp file first to avoid pipefail interactions with head/tail; always guard main invocation with `[ "${BASH_SOURCE[0]}" = "$0" ]` so tests can source the script; exact-string assertions in tests catch things substring matches miss
- Outcomes: CI check now debuggable via diff output even on silent failures; locale probe tolerant of spelling variations; found the remaining BSD vs GNU `wc -w` divergence as a result, already scoped as the next fix
- Dust: the framework looks at itself and tells us exactly what's different now

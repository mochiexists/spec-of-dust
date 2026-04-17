status: verify
files: .githooks/_spec_gate.sh, .githooks/post-merge, .githooks/pre-commit, .github/workflows/validate.yml, .spec/b-startup.md, .spec/changes/fix-viewer-freshness-and-archive-utc.md, README.md, CODEX.md, CLAUDE.md, VERSION, docs/viewer.html, scripts/archive-done-changes.sh, scripts/build-viewer.sh, scripts/merge-completed-work.sh, scripts/update-sod-report.sh, tests/test-spec-gate.sh, tests/test-workflow-scripts.sh

# Fix viewer freshness and archive UTC

## What
Tighten the repo surfaces that drifted in the current-state review. The generated viewer should stay current as workflow data changes, archive filenames should carry UTC timestamps so the viewer does not mislabel local time as `Z`, and the docs should describe the actual archive-on-merge behavior instead of implying that a plain merge fully closes the loop. Because this changes shipped workflow behavior, bump the project version, refresh the generated sod outputs, and normalize the live shorthand language to lowercase `sod`.

## Acceptance criteria
- [ ] `scripts/devlog.sh`, `scripts/flowlog.sh`, and the archive/merge path keep `docs/viewer.html` current without requiring a separate manual rebuild, and repo validation checks that the committed viewer is current via an explicit viewer freshness check
- [ ] Archived change filenames are created in UTC so the viewer's parsed `...Z` timestamps are semantically correct, with repo-local test coverage for the new behavior
- [ ] README and merge/archive surfaces describe the actual archive lifecycle clearly, `VERSION` is bumped from `0.1.1` to patch release `0.1.2`, sod outputs are refreshed for the final tree, and live shorthand references use lowercase `sod`

## Notes
- Keep the zero-dependency shape intact; stay in bash and existing local tooling
- Prefer wiring viewer freshness into existing workflow scripts rather than adding a second generated-file discipline path
- Repo-local test coverage can extend the existing shell test harness or add a focused script if that keeps the assertions clearer

## Peer spec review
**Claude** (2026-04-17, final diff):

1. Clarify the viewer-freshness trigger by naming the concrete scripts or the exact enforcement point.
2. `archive-done-changes.sh` appears to be the sole archive timestamp call site; `date -u` is the right fix if confirmed.
3. Make the viewer freshness check explicit in validation rather than implied.
4. State the exact version bump component.
5. Specify where repo-local test coverage should live.

Addressed:

- acceptance criterion 1 now names `scripts/devlog.sh`, `scripts/flowlog.sh`, and the archive/merge path
- the validation requirement now explicitly calls for a viewer freshness check
- the version bump is pinned to patch release `0.1.2`
- the notes now state that the test coverage can extend the existing shell harness or use a focused script


## Peer code review
**Claude** (2026-04-17):

Verdict: pass, no blockers.

- Viewer freshness is covered: archive closeout now rebuilds and stages viewer + sod outputs, `build-viewer.sh` has `--check`, CI checks viewer freshness explicitly, and `merge-completed-work.sh --auto` checks viewer freshness before proceeding.
- UTC timestamps are covered: `archive-done-changes.sh` now uses `date -u`, and the new workflow-script test proves the archived hour comes from UTC rather than local Honolulu time, with retry protection around hour rollover.
- README, VERSION, and sod outputs are covered: archive lifecycle wording is clearer, `VERSION` is `0.1.2`, generated outputs are refreshed, and live shorthand references are lowercase `sod`.

Advisory only:

- the archive-to-sod/viewer coupling now lives in `archive-done-changes.sh`; that is acceptable because `--require-done` guarantees the archive path when the helper succeeds
- the `make_repo` cleanup in the test harness is a good infrastructure fix and prevents live active changes from polluting temp repos
- `merge-completed-work.sh` removed the redundant inline sod refresh because `archive-done-changes.sh` now owns it; current call sites remain safe because they require the archive path


## Verify
- [pass] `scripts/devlog.sh`, `scripts/flowlog.sh`, and the archive/merge path keep `docs/viewer.html` current without requiring a separate manual rebuild, and repo validation checks that the committed viewer is current via an explicit viewer freshness check
  Verified by the existing viewer rebuild calls in `scripts/devlog.sh` and `scripts/flowlog.sh`, the new archive-path refresh in `scripts/archive-done-changes.sh`, the delegated archive path in `scripts/merge-completed-work.sh`, and the explicit `bash scripts/build-viewer.sh --check` step in `.github/workflows/validate.yml`.
- [pass] Archived change filenames are created in UTC so the viewer's parsed `...Z` timestamps are semantically correct, with repo-local test coverage for the new behavior
  Verified by `date -u` in `scripts/archive-done-changes.sh` and by `bash tests/test-workflow-scripts.sh`, which exercises the archive path under `TZ=Pacific/Honolulu` and confirms the archived hour comes from UTC while viewer and sod outputs remain fresh.
- [pass] README and merge/archive surfaces describe the actual archive lifecycle clearly, `VERSION` is bumped from `0.1.1` to patch release `0.1.2`, sod outputs are refreshed for the final tree, and live shorthand references use lowercase `sod`
  Verified by the lowercase `sod` wording updates in `README.md`, `CODEX.md`, `CLAUDE.md`, `.spec/b-startup.md`, `.githooks/_spec_gate.sh`, `.githooks/pre-commit`, `.github/workflows/validate.yml`, `tests/test-spec-gate.sh`, and the generated labels in `scripts/update-sod-report.sh`, along with the `0.1.2` bump in `VERSION` and passing `bash scripts/build-viewer.sh --check` plus `bash scripts/update-sod-report.sh --check` after the final refresh.


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: the only real friction was keeping generated viewer and sod outputs in sync while the active change file itself was changing during verify
- Learnings: temp-repo harnesses need to isolate active change files or live repo state leaks into workflow tests
- Outcomes: viewer freshness is now checked explicitly, archive timestamps are UTC-correct, archive closeout refreshes generated artifacts, the repo version moved to 0.1.2, and the live shorthand is consistently lowercase `sod`
- Dust: The generated surfaces finally agree on what time it is.

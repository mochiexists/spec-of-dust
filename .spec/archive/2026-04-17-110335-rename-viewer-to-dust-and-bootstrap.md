status: done
files: docs/dust.html, docs/viewer.html, docs/index.html, scripts/build-viewer.sh, scripts/build-dust.sh, scripts/devlog.sh, scripts/flowlog.sh, scripts/archive-done-changes.sh, scripts/merge-completed-work.sh, scripts/update-sod-report.sh, setup.sh, templates/dust.html, .githooks/_spec_gate.sh, .github/workflows/validate.yml, .spec/sod-report.md, README.md, CLAUDE.md, tests/test-workflow-scripts.sh, VERSION, tests/test-spec-gate.sh

# Rename viewer to dust and bootstrap it in setup

## What
The workflow viewer (`docs/viewer.html`) is the framework's artifact — it's the dust. Rename it to `dust.html`, rename `build-viewer.sh` to `build-dust.sh`, and have `setup.sh` scaffold a blank `docs/dust.html` with the template so every sod project gets the viewer out of the box. Right now downstream projects that adopt sod get `devlog.sh` and `flowlog.sh` calling `build-viewer.sh` which hard-fails because there's no `docs/viewer.html`. The viewer isn't optional — it's part of the framework.

## Acceptance criteria
- [ ] `docs/viewer.html` renamed to `docs/dust.html`; all references updated (`build-viewer.sh` → `build-dust.sh`, SOD exclusion in `_spec_gate.sh`, CI check, merge/archive scripts)
- [ ] `setup.sh` creates `docs/dust.html` with the empty template (markers + structural HTML, no embedded data) so `build-dust.sh` can fill it on first run
- [ ] `devlog.sh` and `flowlog.sh` call `build-dust.sh` without error on a freshly setup repo (no hard-fail when data is empty)
- [ ] Existing embedded data survives the rename — rebuilt `docs/dust.html` in this repo contains the same history
- [ ] SOD outputs refreshed, VERSION bumped

## Notes
- Ship the full viewer HTML as `templates/dust.html` in the repo. `setup.sh` copies it to `docs/dust.html` rather than embedding 600 lines in a heredoc.
- `build-dust.sh --check` should still work for CI validation.
- `docs/index.html` links to `viewer.html` and needs updating to `dust.html`.
- VERSION bump is patch: 0.1.2 → 0.1.3.

## Peer spec review
**Claude** (2026-04-17, Codex stalled — read files but disconnected before producing a verdict):

1. Missing: `docs/index.html` links to `viewer.html` — added to `files:` list.
2. Ambiguous: "empty template" vs "full template" — resolved: ship full template as `templates/dust.html`, `setup.sh` copies it.
3. Risk: embedding 600-line HTML in `setup.sh` heredoc would bloat it — resolved: use a shipped template file instead.
4. Missing: `tests/test-workflow-scripts.sh` references `build-viewer.sh` — added to `files:` list.
5. Advisory: version bump pinned to 0.1.3.

No blockers after addressing items 1-4.


## Peer code review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: not upgrade-safe — existing repos with `docs/viewer.html` would break since `build-dust.sh` hard-fails if `docs/dust.html` doesn't exist. → Fixed: `setup.sh` now migrates `viewer.html` → `dust.html` and `build-viewer.sh` → `build-dust.sh` for existing repos.
2. Medium: acceptance criterion 3 unproven — no test for fresh setup → devlog/flowlog path. → Fixed: added `setup_bootstraps_dust_and_scripts_work` test.
3. Advisory: "log viewer" text remained in template and build messages. → Fixed: updated to "dust" throughout.


## Verify
- [pass] `docs/viewer.html` renamed to `docs/dust.html`; all references updated — confirmed via `git diff --staged --stat` and grep for `build-viewer` (no functional references remain, only archive history)
- [pass] `setup.sh` creates `docs/dust.html` from template on fresh repo — confirmed in temp-repo test; also migrates existing `viewer.html` for upgrade safety
- [pass] `devlog.sh` and `flowlog.sh` call `build-dust.sh` without error on freshly setup repo — confirmed by new `setup_bootstraps_dust_and_scripts_work` test (PASS)
- [pass] Existing embedded data survives the rename — `build-dust.sh` reports "Dust data is already current"
- [pass] SOD outputs refreshed, VERSION bumped to 0.1.3 — confirmed in README diff and VERSION file


## Closure
- Challenges: codex review caught an upgrade-safety blocker — existing repos would break without migration logic
- Learnings: rename changes need migration paths, not just search-and-replace
- Outcomes: viewer→dust rename complete with migration, fresh-setup test, and all user-facing copy updated
- Dust: the viewer found its real name

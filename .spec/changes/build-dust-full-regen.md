status: build
files: scripts/build-dust.sh, tests/test-workflow-scripts.sh, docs/dust.html

# Make build-dust.sh a full template-based regenerator

## What
Today `scripts/build-dust.sh` only rewrites the embedded-data block between markers in `docs/dust.html`. Template HTML/JS changes don't propagate — they require manual mirroring (as just discovered in the dust-filter-view change). Treat `templates/dust.html` as source-of-truth and `docs/dust.html` as generated output: on every run, regenerate `docs/dust.html` from the template and fill in the data block. This closes the loop so template edits flow automatically, and supports the agent-driven update flow (when sod updates upstream, the viewer auto-rebuilds).

## Acceptance criteria
- [ ] `scripts/build-dust.sh` regenerates `docs/dust.html` from `templates/dust.html` on every invocation, replacing the entire file (not just the data block)
- [ ] The data-block marker logic still works: read template, replace `/* embedded-data:start */ ... /* embedded-data:end */` with actual data, write to `docs/dust.html`
- [ ] `scripts/build-dust.sh --check` regenerates to a temp file and compares with current `docs/dust.html`; exits non-zero if they differ (unchanged semantics from outside)
- [ ] Marker validation moves from `docs/dust.html` to `templates/dust.html`: if the template is missing, or has missing or duplicate `/* embedded-data:start */` / `/* embedded-data:end */` markers, the script exits non-zero with a clear message
- [ ] Backward compat: if `templates/dust.html` is missing but `docs/dust.html` exists (older downstream repos), script errors with a clear, honest migration message — instructs the user to fetch `templates/dust.html` from the distribution or upstream (setup.sh does not actually restore it) — and exits non-zero
- [ ] Marker ordering validation: if the end marker appears before the start marker in the template, script exits non-zero with a clear message
- [ ] Existing call sites (`devlog.sh`, `flowlog.sh`, `archive-done-changes.sh`, CI) keep working without changes
- [ ] New test verifies that editing `templates/dust.html` and running `build-dust.sh` propagates the edit to `docs/dust.html`
- [ ] New test verifies fail-fast behavior: missing markers in template → script exits non-zero
- [ ] After the change, `bash scripts/build-dust.sh --check` passes cleanly in this repo

## Notes
- This is a behavior change: projects that hand-edited `docs/dust.html` will lose those edits on next run. Acceptable because: (a) the current spec-of-dust repo has no such customization, (b) the correct customization path is to edit `templates/dust.html`.
- Downstream repos that `ovm init dust` or follow manual setup always get `templates/dust.html` in their repo from the distribution — it's not a spec-of-dust-only artifact.
- Marker validation is now a property of `templates/dust.html`, not `docs/dust.html`. Future maintenance should keep markers stable in the template.

## Peer spec review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: missing fail-fast for marker issues in template. → Fixed: AC now requires non-zero exit on missing/duplicate markers in templates/dust.html.
2. Medium: backward compat for older downstream repos (docs but no templates) underspecified. → Fixed: AC now requires clear migration message pointing to setup.sh.
3. Advisory: Notes over-prescribed implementation. → Fixed: removed.
4. Advisory: marker validation location. → Fixed: AC and Notes explicit that markers are a template property now.


## Peer code review
**Codex** (2026-04-17, gpt-5.4):

1. Blocker: migration message claimed "run setup.sh to restore" but setup.sh doesn't actually restore templates/dust.html (it only copies from it). False promise. → Fixed: message now honestly says to fetch from distribution or upstream.
2. Advisory: marker validation didn't check ordering — end-before-start would truncate output. → Fixed: added start_line < end_line check with its own test.


## Verify
<!-- During verify: copy acceptance criteria here, mark pass/fail with notes. -->


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable

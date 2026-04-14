status: done

# Final polish and CI

## What
Finish the last low-risk polish items before first public release. Trim the peer-review prompt wording without losing the key review rules, remove the ambiguous empty `starters` field from the pack manifest, make the docs scaffold match its own README by adding `docs/product/`, and add a minimal GitHub Actions workflow that runs the current shell-based validation flow.

## Acceptance criteria
- [ ] `.spec/FLOW.md` keeps the same peer-review behavior but trims each example review prompt to under 60 words while preserving scope and blocker/advisory guidance
- [ ] `packs/index.json` no longer includes an ambiguous empty `starters` field
- [ ] `docs/product/` exists with a tracked placeholder file so the docs tree matches the structure described in `docs/README.md`
- [ ] A minimal GitHub Actions workflow exists, runs on `push`, `pull_request`, and `workflow_dispatch`, uses `ubuntu-latest`, and runs `bash setup.sh`, `bash scripts/update-sod-report.sh --check`, and `bash tests/test-spec-gate.sh`
- [ ] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end

## Notes
- Keep this strictly as polish and automation; no new workflow concepts
- The workflow only needs to validate the current shell flow on a standard Linux runner
- `setup.sh` must stay Linux-safe for the workflow to be meaningful
- Prefer removing ambiguity over inventing more manifest structure

## Peer spec review
Summary for review: finish the last small release-polish items by shortening the peer-review prompt examples, removing the empty `starters` field from the pack manifest, creating `docs/product/`, and adding a minimal Actions workflow that runs the shell-based validation flow.

Claude review:

- the CI criterion needed explicit triggers and runner choice
- the prompt-shortening criterion needed a concrete bound
- the spec needed to say whether `docs/product/` was just a placeholder dir
- the notes should call out that `setup.sh` must work on Linux

Valid feedback addressed:

- CI now targets `push`, `pull_request`, and `workflow_dispatch` on `ubuntu-latest`
- the prompt target is now under 60 words each
- `docs/product/` is explicitly a tracked placeholder directory
- Linux-safe `setup.sh` behavior is now part of the notes

## Peer code review
Claude review:

- no blockers remained in the final diff
- the only verify follow-up was to confirm the actual prompt word counts and refresh SOD after staging the new files

Resolution:

- prompt counts were measured directly at 50 words for spec review and 55 words for diff review
- the final SOD refresh is run after staging the new workflow and docs placeholder files

## Verify
- [pass] `.spec/FLOW.md` keeps the same peer-review behavior but trims each example review prompt to under 60 words while preserving scope and blocker/advisory guidance
  The two spec-review prompts are 50 words each, and the two diff-review prompts are 55 words each.
- [pass] `packs/index.json` no longer includes an ambiguous empty `starters` field
  The empty `starters` array was removed instead of being documented into a fake structure.
- [pass] `docs/product/` exists with a tracked placeholder file so the docs tree matches the structure described in `docs/README.md`
  `docs/product/.gitkeep` is now tracked and the docs tree matches the README structure.
- [pass] A minimal GitHub Actions workflow exists, runs on `push`, `pull_request`, and `workflow_dispatch`, uses `ubuntu-latest`, and runs `bash setup.sh`, `bash scripts/update-sod-report.sh --check`, and `bash tests/test-spec-gate.sh`
  `.github/workflows/validate.yml` now defines that job, and the same three commands passed locally in sequence.
- [pass] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end
  This change file contains the full review/verify record and the final SOD refresh happens after staging the new tracked files.


## Closure
- Challenges: The only tricky part was keeping the hook harness stable as the repo’s own active change state kept moving under it.
- Learnings: For self-hosting workflow repos, tests should seed their own fixture state instead of depending on whatever change file happens to be active.
- Outcomes: The prompts are shorter, the pack manifest is cleaner, the docs tree matches its README, and the repo now has a minimal Actions workflow that runs the same shell validation flow used locally.
- Dust: The last polish was mostly about removing guesses.

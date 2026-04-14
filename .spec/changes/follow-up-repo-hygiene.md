status: done

# Follow-up repo hygiene

## What
Finish the remaining mechanical repo-hygiene work after the first public-release blocker pass. Move completed change files out of the active changes directory, fix the misleading setup branch, and add a small shell test harness for the hook logic so the repo’s bootstrap and commit-policy behavior are less hand-wavy.

## Acceptance criteria
- [ ] Completed standard change files are moved from `.spec/changes/` to `.spec/archive/` in a way that leaves one active follow-up change file in `.spec/changes/`
- [ ] `setup.sh` actually creates `.spec/changes/_template.md` when missing and still bootstraps the repo cleanly
- [ ] A small shell test harness exists for `.githooks/_spec_gate.sh` and covers these core paths: commit with an active change, blocked commit without an active change or skip entry, and allowed trivial skip commit with a valid devlog entry
- [ ] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end

## Notes
- Keep this follow-up focused on repo hygiene, not workflow redesign
- The shell tests can stay lightweight; they do not need a full framework
- The archive move should preserve the completed change history, not delete it
- The archive move is manual in this change; the post-merge hook remains the default automation path later

## Peer spec review
Summary for review: finish the next repo-hygiene pass by archiving completed changes, fixing setup bootstrapping, and adding a lightweight hook test harness that covers the main commit-policy paths.

Claude review:

- the original scope was too wide and risked stalling on unrelated polish and CI work
- the test-harness criterion needed concrete paths named explicitly
- the archive move needed to be clearly manual in this change rather than implied automation

Valid feedback addressed:

- scope is narrowed to archive/setup/tests only
- the test coverage expectation now names the three core commit-policy paths
- the notes now state that the archive move is manual in this change

## Peer code review
Claude review:

- no missed spec criteria remained after the final harness adjustments
- non-blocking notes were about making the test intent more obvious rather than changing the behavior

Resolution:

- added comments where the harness intentionally relies on `spec` not counting as an active change
- made the invalid skip test explicitly about `prepare-commit-msg` enforcement under `--no-verify`
- switched the synthetic skip test entry to append mode so it matches the documented JSONL pattern

## Verify
- [pass] Completed standard change files are moved from `.spec/changes/` to `.spec/archive/` in a way that leaves one active follow-up change file in `.spec/changes/`
  The six completed standard change files were moved into `.spec/archive/`, leaving `_template.md`, `_example-dark-mode.md`, and this active change in `.spec/changes/`.
- [pass] `setup.sh` actually creates `.spec/changes/_template.md` when missing and still bootstraps the repo cleanly
  A temp Git repo with `_template.md` removed successfully recreated it via `bash setup.sh`.
- [pass] A small shell test harness exists for `.githooks/_spec_gate.sh` and covers these core paths: commit with an active change, blocked commit without an active change or skip entry, and allowed trivial skip commit with a valid devlog entry
  `tests/test-spec-gate.sh` now covers active-change pass, blocked commit without an active change, blocked invalid skip under `--no-verify`, and allowed valid skip under `--no-verify`.
- [pass] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end
  This change file now contains the full review/verify record and the SOD outputs are refreshed after these final notes.


## Closure
- Challenges: The hook tests only became trustworthy once they targeted a non-exempt file and proved the `prepare-commit-msg` path explicitly.
- Learnings: For hook behavior, temp-repo tests are worth the effort because shell scripts hide edge cases in staging order and hook selection.
- Outcomes: Completed changes are archived, `setup.sh` really recreates the template, and the repo now has an executable shell harness for the core commit-policy paths.
- Dust: The gate got a memory, and the memory learned to check itself.

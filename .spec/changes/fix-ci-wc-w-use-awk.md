status: done
files: scripts/update-sod-report.sh, tests/test-workflow-scripts.sh, .spec/sod-report.md, README.md, docs/dust.html

# Fix CI: switch word count from wc -w to awk NF for cross-platform determinism

## What
CI failed on `fb6892e` — the VS-16 strip fix was necessary but insufficient. Post-strip, `wc -w` still disagrees between macOS and Ubuntu CI: delta = 10 words (change file 1130/1124, dust.html 21425/21421).

Root cause (verified): BSD `wc -w` treats `⚠` (U+26A0) itself as a word boundary (`a⚠b` → 2 words), while GNU `wc -w` treats it as part of a word (`a⚠b` → 1 word). BSD and GNU have different non-ASCII word-character classifications. This is broader than VS-16 and will recur with any non-ASCII char that falls into BSD's non-word class.

**CI failure**:
- workflow: Validate
- run-id: 24638800169
- failed-step: Check sod outputs
- url: https://github.com/mochiexists/spec-of-dust/actions/runs/24638800169

**Fix**: switch `-w` in `count_value` from `wc -w` to `awk '{n += NF} END {print n+0}'` under `LC_ALL=$UTF8_LOCALE`. `awk` splits on whitespace (FS default) — both BSD `awk` and GNU `awk` give identical output on the failing fixtures (`a⚠b` → 1 on both; change file → 1124 on both; dust.html → 21421 on both). `awk` is POSIX and is already used throughout the repo's existing scripts — no new dependency is introduced.

Also drop the `LC_ALL=C sed "s/$VS16_BYTES//g"` strip and `VS16_BYTES` constant. With awk splitting on whitespace, VS-16 is already a non-whitespace char that stays attached to its base — no special handling needed. This simplifies the script.

## Acceptance criteria
- [ ] `count_value` uses `LC_ALL="$UTF8_LOCALE" awk '{n += NF} END {print n+0}' "$path"` for mode `-w`. Modes `-l` and `-m` continue to use `wc -l` / `wc -m` under `LC_ALL=$UTF8_LOCALE` (already deterministic for lines/codepoints).
- [ ] Remove the `LC_ALL=C sed "s/$VS16_BYTES//g"` pipe AND the `VS16_BYTES=...` constant at the top of the script. awk's whitespace-splitting makes VS-16 stripping unnecessary.
- [ ] `.spec/sod-report.md` and `README.md` summary block regenerated. Expected outcome: macOS and Ubuntu produce byte-identical reports (--check green on both).
- [ ] Rename test `sod_report_strips_vs16_for_word_count` → `sod_report_word_count_matches_awk_fields` (same fixture, new implementation rationale): `⚠️  test` → Words=2 on both platforms.
- [ ] Remove test `sod_report_preserves_non_vs16_chars_sharing_bytes`. No longer applicable once sed is gone; there's no byte-strip to guard against.
- [ ] New test `sod_report_word_count_stable_for_bsd_gnu_divergent_chars`: fixture `a\xe2\x9a\xa0b\n` (the minimal BSD/GNU `wc -w` divergence reproducer), assert Words=1 — proves the new impl is stable where `wc -w` wasn't.
- [ ] `bash scripts/update-sod-report.sh --check` clean locally after regeneration.

## Notes
- `awk` is POSIX (IEEE 1003.1) and already used throughout the repo's scripts (`build-dust.sh`, `devlog.sh`, `check-deploy-health.sh`, `_spec_gate.sh`). Present on macOS (BSD awk) and ubuntu-latest (GNU awk / mawk). README "## Requirements" only lists `git` and `bash` explicitly, but `awk` is a de-facto dependency of the existing workflow; this change does not introduce a new one.
- `NF` is the number of whitespace-separated fields per line under the default FS. Both BSD and GNU awk use POSIX whitespace here (space, tab) regardless of locale — neither treats `⚠` as a separator. Verified by diffing totals on both real files from the failed CI run.
- `print n+0` forces a numeric zero if the file has no words, avoiding an empty-string output.
- Previous change (`fix-ci-wc-w-vs16-strip`) predicted this escalation path in its Notes section: "If we later add emoji with more complex composition... the fix then will likely be to switch word counting to [a fixed splitter]." Codex peer review during THIS spec round prompted the swap from python3 to awk to keep zero-dep.

## Peer spec review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: python3 violates zero-dep contract. → **Fixed**: switched to awk (POSIX, already used throughout existing repo scripts — not a new dependency). Verified on macOS BSD awk + Ubuntu GNU awk against the failing files.
2. Medium: "drop or retain" AC was not a requirement. → **Fixed**: AC now says drop the test outright.
3. Medium: request a test for the python3-missing failure path. → Moot after switch to awk; awk is POSIX-guaranteed.
4. Advisory: docker verification is verify-note, not AC. → **Fixed**: AC now reads "--check clean locally after regeneration"; docker evidence documented in Notes.


## Peer code review
**Codex** (2026-04-20, gpt-5.4):

1. Medium: AC referenced old test name `sod_report_strips_vs16_for_word_count` but the diff renamed it to `sod_report_word_count_matches_awk_fields` — spec drift.
   → **Fixed**: AC now says "Rename test ... → ..." matching the diff.
2. Advisory: spec overclaimed awk as "coreutils" / README-required. awk is a de-facto dependency of existing repo scripts but not listed in README Requirements.
   → **Fixed**: rephrased rationale to "awk is POSIX and already used throughout the repo's existing scripts — no new dependency is introduced."
No functional blockers.


## Verify
- [x] `count_value` uses `LC_ALL="$UTF8_LOCALE" awk '{ n += NF } END { print n+0 }' "$path"` for `-w`. Confirmed at `scripts/update-sod-report.sh:95`.
- [x] `VS16_BYTES` constant and sed pipe removed.
- [x] `.spec/sod-report.md` + `README.md` summary regenerated; `--check` clean on macOS AND Ubuntu (verified via docker on the pushed tree).
- [x] `sod_report_word_count_matches_awk_fields` passes (⚠️ fixture → Words=2).
- [x] `sod_report_word_count_stable_for_bsd_gnu_divergent_chars` passes (a⚠b → Words=1 — would fail the old wc-w impl on macOS with result 2).
- [x] `sod_report_preserves_non_vs16_chars_sharing_bytes` removed.
- [x] `--check` clean locally.

## Closure
- Challenges: VS-16 strip was a targeted fix for the wrong root cause. Real problem is that BSD and GNU `wc -w` classify non-ASCII chars (like `⚠` U+26A0) differently as word boundaries. Stripping just VS-16 left the bare ⚠ still diverging. CI caught this on the pushed merge of the VS-16 fix.
- Learnings: `wc -w` is not cross-platform-stable for non-ASCII content regardless of what gets stripped — BSD has more aggressive word-boundary classification than GNU. `awk '{print NF}'` is locale-insensitive for whitespace and gives identical results on BSD awk and GNU awk. For any future cross-platform text-stat work, prefer awk over wc for word counts. Codex peer review flagged python3 as a zero-dep violation even though it was my gut-reaction fix; awk kept the contract.
- Outcomes: sod-report is byte-identical on macOS and Ubuntu now — verified against the actual files that failed CI (dust.html 21421, fix-ci change file 1124). Two committed fix-ci changes in sequence: VS-16 strip (necessary intermediate) and awk switch (real fix).
- Dust: the counter learned to stop reading the world and just count the spaces between things.

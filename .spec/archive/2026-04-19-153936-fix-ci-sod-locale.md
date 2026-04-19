status: done
files: scripts/update-sod-report.sh, .spec/sod-report.md, README.md, tests/test-workflow-scripts.sh, scripts/check-deploy-health.sh, .spec/FLOW.md, CLAUDE.md, AGENTS.md, CODEX.md, docs/dust.html

# Fix CI failure: sod-report locale drift between macOS and Linux

## What
`bash scripts/update-sod-report.sh --check` passes on macOS but fails on Linux CI. Root cause is `wc -m` in `scripts/update-sod-report.sh` counting differently depending on locale:
- macOS BSD wc with UTF-8 locale: counts Unicode characters (1 per em-dash, 1 per ✓)
- Linux GNU wc without LC_ALL set: often counts bytes (3 per em-dash)

Since the repo contains em-dashes, ✓, ⚠️ throughout markdown/shell files, character counts and token estimates diverge, and the committed sod-report.md (computed on macOS) doesn't match what CI regenerates.

Detected via the new `scripts/check-deploy-health.sh` — this spec is drafted because that script exited 1 on the most recent push.

**Detected failure (from check-deploy-health.sh):**
- workflow: `Validate`
- run-id: `24631576784`
- failed-step: `Check sod outputs`
- url: https://github.com/mochiexists/spec-of-dust/actions/runs/24631576784

## Acceptance criteria
- [ ] A shared helper in `scripts/update-sod-report.sh` that wraps every `wc -m` call (the three current sites) with a deterministic UTF-8 locale, rather than blanket-exporting `LC_ALL`. Narrow fix, narrow surface.
- [ ] Locale selection uses `locale -a` to probe available locales, prefers `C.UTF-8`, falls back to `en_US.UTF-8`, then `en_US.utf8`. If no UTF-8 locale is available, the script exits non-zero with a clear message naming the problem rather than silently producing wrong counts (no fallback to `C`, since `C` is exactly what causes the byte-vs-character ambiguity we're avoiding).
- [ ] Regression test in `tests/test-workflow-scripts.sh`: create a tiny temp repo whose files contain multi-byte characters (em-dashes, ✓), run `update-sod-report.sh`, inspect the generated report, and assert the character count for the known file matches the expected Unicode code-point count. Test runs on CI (Linux) and locally (macOS) — same result both places.
- [ ] `.spec/sod-report.md` regenerated once under the fixed semantics so CI `--check` matches. Token estimates may shift slightly; expected.
- [ ] `bash scripts/update-sod-report.sh --check` passes locally after regeneration.
- [ ] Post-push verification: push the fix, run `bash scripts/check-deploy-health.sh`, confirm exit 0 against the new HEAD.

### Extend the success-path flow (user-visible confirmation on green)
- [ ] `scripts/check-deploy-health.sh` on exit 0 prints a deploy confirmation URL (the GitHub Actions runs URL for the branch, e.g. `https://github.com/<owner>/<repo>/actions?query=branch:main`) in addition to the existing green-count message. Pages URL is NOT resolved by this script (that's repo-specific); the Actions URL is the generic signal.
- [ ] FLOW.md "Post-push health" section for exit-code 0 updates to: "agent reports green + the deploy confirmation URL to the user, then continues." CLAUDE.md / AGENTS.md / CODEX.md already delegate to FLOW.md so no per-agent edits needed beyond what's there.
- [ ] Existing "exit 0 on all green" offline test updated to assert the deploy-confirmation URL appears in stdout on green.

## Notes
- macOS ships `en_US.UTF-8` reliably; ubuntu-latest CI typically has `C.UTF-8`. The probe-and-fallback ordering handles both without global side effects.
- Only `-m` is affected (character mode). `-l` (lines) and `-w` (words) aren't locale-sensitive in a way that affects this bug, but wrapping all three in the helper keeps the code consistent.
- This spec exists because the new post-push health check caught an externally-visible failure. End-to-end dogfood is the whole point — agent detected, spec drafted, user confirmed, proceeding.
- The success-path extension (deploy-confirmation URL) is bundled here rather than deferred because it's a trivial FLOW-doc + 3-line script change and completes the loop's user-facing story right now.

## Peer spec review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: bug fixes should get a regression test per FLOW.md Testing section. → Fixed: added AC for a multibyte-character regression test in `tests/test-workflow-scripts.sh`.
2. Risk: locale fallback underspecified — different platforms have different locales available. → Fixed: AC now specifies `locale -a` probe with explicit preference order (C.UTF-8 → en_US.UTF-8 → en_US.utf8 → C) and hard-fails if no UTF-8 locale exists rather than silently drifting.
3. Overbuilt: "set LC_ALL at top" is broader than needed. → Fixed: narrowed to a helper wrapping just the `wc -m` call sites, not a global export.
Advisory (user addition): success-path deploy confirmation URL bundled into this same spec for flow completeness.


## Peer code review
**Codex** (2026-04-19, gpt-5.4):

1. High: deploy URL derived from `origin` instead of the actual upstream remote; also no GitHub-remote check so non-GitHub origins would produce bogus URLs. → Fixed: resolves the remote associated with the upstream (`${upstream%%/*}`), validates the URL matches `github.com` before emitting, falls back silently otherwise.
2. Medium: locale fix still spread across three call sites (count_tokens_for and build_context_metrics inlined `LC_ALL=...wc -m`). → Fixed: both now go through shared `count_value -m` helper. Single point of locale control.
3. Advisory: spec said fallback to `C` but implementation hard-fails. → Fixed: spec now matches implementation (no `C` fallback — defeats the whole fix).


## Verify
- [pass] All `wc -m` call sites in `update-sod-report.sh` go through the shared `count_value` helper; no inline `LC_ALL="$UTF8_LOCALE" wc -m` sprinkled elsewhere
- [pass] Locale probe order: C.UTF-8 → en_US.UTF-8 → en_US.utf8; hard-fails with clear message if none available (no `C` fallback)
- [pass] `UTF8_LOCALE` set inside script scope; never exported globally
- [pass] Regression test `sod_report_counts_unicode_codepoints_not_bytes` asserts 5 em-dashes + newline = 6 code-points in the generated report (would report 16 under byte counting)
- [pass] `.spec/sod-report.md` regenerated under fixed semantics
- [pass] `bash scripts/update-sod-report.sh --check` clean locally
- [pass] `check-deploy-health.sh` on exit 0 prints a deploy-confirmation URL derived from the upstream's actual remote (not hardcoded `origin`), gated to github.com-style URLs, falls back silently otherwise
- [pass] FLOW.md exit-0 line updated to include surfacing the deploy URL to the user
- [pass] Existing "exit 0 on all green" test asserts the URL appears in stdout
- Awaiting post-push verification: push this change, wait for CI, run `check-deploy-health.sh`, confirm exit 0 + deploy URL appears


## Closure
- Challenges: macOS ships bash 3.2 which doesn't support `$'\u...'` escapes — had to use raw UTF-8 byte literals (`\xe2\x80\x94`) in the regression test; `git ls-files` means test fixtures must be committed, not just created; upstream `${upstream%%/*}` is a clean way to extract the remote name without hardcoding origin
- Learnings: wc -m is always locale-sensitive; projects counting characters should explicitly pick a UTF-8 locale and fail loudly if one isn't available, otherwise silent byte-vs-char drift bites only on CI
- Outcomes: first fix driven end-to-end by the post-push health loop — agent detected the failure, drafted the spec, user confirmed, fix shipped. Closes the loop that the previous change built.
- Dust: the framework learned to see its own UTF-8

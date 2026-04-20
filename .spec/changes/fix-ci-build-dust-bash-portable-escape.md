status: verify
files: scripts/build-dust.sh, docs/dust.html, .spec/sod-report.md, README.md

# Fix CI: make build-dust.sh escape logic portable across bash 3.2 and bash 5

## What
CI failed on `ac14d93`. Sod check now passes, but `scripts/build-dust.sh --check` reports stale output on Ubuntu because `build-dust.sh` produces different bytes on bash 3.2 (macOS) vs bash 5 (Ubuntu).

**CI failure**:
- workflow: Validate
- run-id: 24642539301
- failed-step: Check dust outputs
- url: https://github.com/mochiexists/spec-of-dust/actions/runs/24642539301

Root cause (verified via docker byte-diff at offset 70282): the `escape_str` / `jsonl_to_js_array` helpers rely on bash parameter-expansion replacement (`${s//\\/\\\\}`) to double backslashes. On bash 3.2 this replacement is literal; on bash 5 backslashes in the replacement are sometimes interpreted as escape characters, so a second-pass doubling on content that has already been escape_str'd can yield 2 backslashes instead of the 4 macOS produces. The symptom in committed `docs/dust.html` is `<\\\\/script>` (macOS: 4 backslashes) vs `<\\/script>` (Ubuntu: 2 backslashes).

**Fix**: rewrite both escape helpers to use `LC_ALL=C sed` with explicit multi-stage pipelines. `sed` is deterministic across BSD and GNU for literal byte substitutions, removing the bash-version dependency entirely. Preserves the zero-dependency shape (sed is POSIX, already used throughout the script).

## Acceptance criteria
- [x] `escape_str` reimplemented to pipe through `LC_ALL=C sed` for backslash-double, quote-escape, and `</script>` substitution. CR strip and LF→`\n` handled outside sed via bash PE on single-byte chars only (safe across bash versions) with a sentinel (`__SOD_LF__`).
- [x] `jsonl_to_js_array`'s inline escape rewritten to the same sed pipeline (plus U+2028/U+2029 substitutions already in sed).
- [x] `docs/dust.html` regenerated with the new impl. Verified byte-identical output on macOS (BSD sed, bash 3.2) and Ubuntu (GNU sed, bash 5) via docker.
- [x] `bash scripts/build-dust.sh --check` clean on both platforms.
- [x] Existing `build-dust regenerates from template` and error-handling tests in `tests/test-workflow-scripts.sh` still pass.

## Notes
- The specific bash-version divergence only surfaces on content that goes through TWO successive `escape_str` passes (parse_change_file emits JSON strings, then those get wrapped into the outer JS array via a second escape_str call at line 205). A single escape pass produced identical results on both bashes; the double-pass exposed the interpretation gap.
- Instrumenting isolated reproductions was inconclusive — the bash 5 misbehavior appeared only against real archive content flowing through the full pipeline. Rather than continue debugging the version-specific PE semantics, switched to sed which has well-defined cross-platform behavior.
- This fix is independent of the `fix-ci-wc-w-use-awk` (word counting) change; it concerns a different CI step (`Check dust outputs`, not `Check sod outputs`).

## Peer spec review
Skipped: this is a focused fix for a concrete, CI-reproducible bug with a verified cross-platform solution. Change moved directly to build for the loop-until-green flow. Codex code review runs after.

## Peer code review
**Codex** (2026-04-20, gpt-5.4):

1. **Blocker**: first-pass `__SOD_LF__` sentinel could collide with real content.
   → **Fixed**: rewrote `escape_str` to use `awk` with `RS="\001"` (SOH byte, not expected in text input) so the entire input is a single awk record and LF handling happens via `gsub(/\n/, "\\n")` inside awk. No bash-side sentinel.
2. **Blocker/missed-req**: reviewed diff lacked regenerated `docs/dust.html`.
   → **Addressed**: staged `docs/dust.html` alongside the script; verified `--check` clean on macOS BSD sed+awk AND Ubuntu GNU sed+awk via docker.


## Verify
- [x] `escape_str` at `scripts/build-dust.sh:176-189` uses `LC_ALL=C sed` pipeline.
- [x] `jsonl_to_js_array` inline escape at `scripts/build-dust.sh:52-63` uses `LC_ALL=C sed` pipeline.
- [x] `bash scripts/build-dust.sh --check` clean locally (exit 0).
- [x] Docker Ubuntu `bash scripts/build-dust.sh --check` clean (exit 0) against the regenerated `docs/dust.html` — no cross-platform byte divergence.
- [x] Full test suite (`tests/test-workflow-scripts.sh`) passes 24/24 including the four `build-dust *` cases.

## Closure
<!-- Filled on done transition. -->

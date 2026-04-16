#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

pass() {
  printf 'PASS %s\n' "$1"
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

expect_blocked_commit() {
  local label="$1"
  local expected_pattern="$2"
  local output_file="$TMP_DIR/${label// /-}.log"

  shift 2

  if "$@" >"$output_file" 2>&1; then
    cat "$output_file" >&2
    fail "$label"
  fi

  if ! grep -Eq "$expected_pattern" "$output_file"; then
    cat "$output_file" >&2
    fail "$label"
  fi
}

make_repo() {
  local name="$1"
  local repo="$TMP_DIR/$name"

  rsync -a --exclude '.git' "$ROOT_DIR/" "$repo/"
  (
    cd "$repo"
    git init -q
    git config user.name 'Test User'
    git config user.email 'test@example.com'
    chmod +x .githooks/*
    git add .
    git commit --no-verify -qm 'baseline'
    git config core.hooksPath .githooks
  )

  printf '%s\n' "$repo"
}

seed_change_file() {
  local status="$1"

  find .spec/changes -maxdepth 1 -type f -name '*.md' \
    ! -name '_template.md' \
    ! -name '_example-*' \
    -delete

  cat > .spec/changes/test-change.md <<EOF
status: ${status}

# Test change

## What
Test-only change file for hook validation.

## Acceptance criteria
- [ ] Hook behavior under test

## Peer spec review
Synthetic test fixture.

## Peer code review
Synthetic test fixture.

## Verify
- [pass] Synthetic test fixture.

## Closure
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable
EOF
}

commit_isolated_changes_fixture() {
  find .spec/changes -maxdepth 1 -type f -name '*.md' \
    ! -name '_template.md' \
    ! -name '_example-*' \
    -delete

  git add -A .spec/changes
  git commit --no-verify -qm 'fixture: isolate changes'
}

active_change_commit_passes() {
  local repo
  repo="$(make_repo active)"

  (
    cd "$repo"
    seed_change_file build
    git add -A .spec/changes
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    git commit -qm 'test: active change commit'
  ) || fail "active change commit"

  pass "active change commit"
}

missing_change_commit_is_blocked() {
  local repo
  repo="$(make_repo blocked)"

  (
    cd "$repo"
    # A change in `spec` state exists on disk but does not count as an active build/verify/done change.
    seed_change_file spec
    git add -A .spec/changes
    source .githooks/_spec_gate.sh
    has_active_standard_change && exit 1
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    expect_blocked_commit "blocked without active change" "Commit policy failed" git commit -m 'test: blocked without active change'
  ) || fail "blocked commit without active change"

  pass "blocked commit without active change"
}

invalid_skip_commit_is_blocked() {
  local repo
  repo="$(make_repo invalid-skip)"

  (
    cd "$repo"
    # `--no-verify` skips pre-commit, so this proves prepare-commit-msg still enforces skip mode.
    seed_change_file spec
    source .githooks/_spec_gate.sh
    has_active_standard_change && exit 1
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    git add .spec/changes/test-change.md CODEX.md
    expect_blocked_commit "invalid skip commit" "Skip commits|must be staged for skip commits" git commit --no-verify -m 'test: invalid skip commit'
  ) || fail "invalid skip commit"

  pass "invalid skip commit"
}

valid_skip_commit_passes() {
  local repo
  repo="$(make_repo skip)"

  (
    cd "$repo"
    seed_change_file spec
    source .githooks/_spec_gate.sh
    has_active_standard_change && exit 1
    cat >> .spec/devlog.jsonl <<'EOF'
{"ts":"2026-04-15T10:00:00Z","event":"skip-no-verify","kind":"comment","summary":"Synthetic test skip entry","reason":"Single-file CODEX.md wording tweak in hook test","files":["CODEX.md"],"command":"git commit --no-verify"}
EOF
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    git add .spec/devlog.jsonl CODEX.md
    git commit --no-verify -qm 'test: valid skip commit'
  ) || fail "valid skip commit"

  pass "valid skip commit"
}

setup_scaffold_includes_files_metadata() {
  local repo
  repo="$(make_repo setup-template)"

  (
    cd "$repo"
    rm -f .spec/changes/_template.md
    bash setup.sh >/dev/null
    grep -Fx 'status: spec' .spec/changes/_template.md >/dev/null
    grep -Fx 'files:' .spec/changes/_template.md >/dev/null
  ) || fail "setup scaffold includes files metadata"

  pass "setup scaffold includes files metadata"
}

done_change_commit_passes() {
  local repo
  repo="$(make_repo done-closeout)"

  (
    cd "$repo"
    commit_isolated_changes_fixture
    seed_change_file done
    bash scripts/flowlog.sh --change test-change --agent codex --sentiment smooth >/dev/null
    git add .spec/changes/test-change.md .spec/flowlog.jsonl docs/viewer.html
    bash scripts/update-sod-report.sh
    git add README.md .spec/sod-report.md
    git commit -qm 'test: done change commit'
  ) || fail "done change commit"

  pass "done change commit"
}

done_change_with_additional_work_is_blocked() {
  local repo
  repo="$(make_repo done-blocked)"

  (
    cd "$repo"
    commit_isolated_changes_fixture
    seed_change_file done
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    git add .spec/changes/test-change.md CODEX.md
    expect_blocked_commit "done with additional work" "Completed change must be committed before more work proceeds" git commit -m 'test: done with additional work'
  ) || fail "done with additional work"

  pass "done with additional work blocked"
}

multiple_done_changes_are_blocked() {
  local repo
  repo="$(make_repo multi-done)"

  (
    cd "$repo"
    commit_isolated_changes_fixture
    seed_change_file done
    cat > .spec/changes/second-change.md <<'INNER'
status: done

# Second done change
## What
Test fixture for multi-done closeout.
## Acceptance criteria
- [ ] closeout test
## Peer spec review
test
## Peer code review
test
## Verify
test
## Closure
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable
INNER
    git add .spec/changes/test-change.md .spec/changes/second-change.md
    expect_blocked_commit "multiple done changes" "Multiple completed changes are still uncommitted" git commit -m 'test: multiple done changes'
  ) || fail "multiple done changes"

  pass "multiple done changes blocked"
}

scoped_commit_passes() {
  local repo
  repo="$(make_repo scoped-pass)"

  (
    cd "$repo"
    seed_change_file build
    # Add files: scope to the change file
    sed -i.bak '1s/^/files: CODEX.md\n/' .spec/changes/test-change.md
    rm -f .spec/changes/test-change.md.bak
    git add -A .spec/changes
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    git commit -qm 'test: scoped commit'
  ) || fail "scoped commit"

  pass "scoped commit"
}

unscoped_commit_is_blocked() {
  local repo
  repo="$(make_repo scoped-block)"

  (
    cd "$repo"
    seed_change_file build
    # Scope only allows setup.sh
    sed -i.bak '1s/^/files: setup.sh\n/' .spec/changes/test-change.md
    rm -f .spec/changes/test-change.md.bak
    git add -A .spec/changes
    # Edit a non-exempt file NOT in scope (CODEX.md is non-exempt)
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    expect_blocked_commit "unscoped commit" "not listed in any active change" git commit -m 'test: unscoped commit'
  ) || fail "unscoped commit"

  pass "unscoped commit blocked"
}

empty_scope_falls_back() {
  local repo
  repo="$(make_repo empty-scope)"

  (
    cd "$repo"
    seed_change_file build
    # No files: field — should fall back to current behavior
    git add -A .spec/changes
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    git commit -qm 'test: empty scope fallback'
  ) || fail "empty scope fallback"

  pass "empty scope fallback"
}

skip_mode_ignores_scope() {
  local repo
  repo="$(make_repo skip-scope)"

  (
    cd "$repo"
    seed_change_file spec
    # Add scope to the spec-state change (which doesn't count as active for commits)
    sed -i.bak '1s/^/files: nothing.txt\n/' .spec/changes/test-change.md
    rm -f .spec/changes/test-change.md.bak
    source .githooks/_spec_gate.sh
    has_active_standard_change && exit 1
    cat >> .spec/devlog.jsonl <<'EOF'
{"ts":"2026-04-15T10:00:00Z","event":"skip-no-verify","kind":"comment","summary":"Scope skip test","reason":"Single-file skip in scope test","files":["CODEX.md"],"command":"git commit --no-verify"}
EOF
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    git add .spec/devlog.jsonl CODEX.md
    git commit --no-verify -qm 'test: skip ignores scope'
  ) || fail "skip ignores scope"

  pass "skip ignores scope"
}

multiple_changes_scope_matches() {
  local repo
  repo="$(make_repo multi-scope)"

  (
    cd "$repo"
    seed_change_file build
    # First change scopes to setup.sh only
    sed -i.bak '1s/^/files: setup.sh\n/' .spec/changes/test-change.md
    rm -f .spec/changes/test-change.md.bak

    # Second change scopes to CODEX.md
    cat > .spec/changes/second-change.md <<'INNER'
status: build
files: CODEX.md

# Second change
## What
Test fixture for multi-scope.
## Acceptance criteria
- [ ] scope test
## Peer spec review
test
## Peer code review
test
## Verify
test
## Closure
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable
INNER

    git add -A .spec/changes
    # Edit CODEX.md — should match the second change's scope
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    git commit -qm 'test: multi-scope match'
  ) || fail "multi-scope match"

  pass "multi-scope match"
}

blank_files_field_falls_back() {
  local repo
  repo="$(make_repo blank-scope)"

  (
    cd "$repo"
    seed_change_file build
    # Add an explicit blank files: line (like the template default)
    sed -i.bak '1s/^/files:\n/' .spec/changes/test-change.md
    rm -f .spec/changes/test-change.md.bak
    git add -A .spec/changes
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CODEX.md README.md .spec/sod-report.md
    git commit -qm 'test: blank scope fallback'
  ) || fail "blank scope fallback"

  pass "blank scope fallback"
}

exempt_passes_under_scope() {
  local repo
  repo="$(make_repo exempt-scope)"

  (
    cd "$repo"
    seed_change_file build
    # Scope allows only setup.sh
    sed -i.bak '1s/^/files: setup.sh\n/' .spec/changes/test-change.md
    rm -f .spec/changes/test-change.md.bak
    git add -A .spec/changes
    # Edit an exempt file (CLAUDE.md) — should pass regardless of scope
    perl -0pi -e 's/subagents only for/subagents for/' CLAUDE.md
    bash scripts/update-sod-report.sh
    git add .spec/changes CLAUDE.md README.md .spec/sod-report.md
    git commit -qm 'test: exempt under scope'
  ) || fail "exempt under scope"

  pass "exempt under scope"
}

archive_only_commit_passes() {
  local repo
  repo="$(make_repo archive-pass)"

  (
    cd "$repo"
    # Create a done change, commit it first
    seed_change_file done
    git add -A .spec/changes
    bash scripts/update-sod-report.sh
    git add .spec/changes .spec/sod-report.md README.md
    git commit -qm 'setup: done change'

    # Now archive it (mirrors real release flow)
    mkdir -p .spec/archive
    git mv .spec/changes/test-change.md .spec/archive/2026-04-17-test-change.md
    bash scripts/update-sod-report.sh
    git add .spec/archive .spec/sod-report.md README.md
    git commit -qm 'test: archive only commit'
  ) || fail "archive only commit"

  pass "archive only commit"
}

archive_mixed_with_code_is_blocked() {
  local repo
  repo="$(make_repo archive-block)"

  (
    cd "$repo"
    # Create a done change, commit it first
    seed_change_file done
    git add -A .spec/changes
    bash scripts/update-sod-report.sh
    git add .spec/changes .spec/sod-report.md README.md
    git commit -qm 'setup: done change'

    # Archive it but also touch an unrelated code file
    mkdir -p .spec/archive
    git mv .spec/changes/test-change.md .spec/archive/2026-04-17-test-change.md
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add .spec/archive CODEX.md .spec/sod-report.md README.md
    expect_blocked_commit "archive mixed with code" "Commit policy failed" git commit -m 'test: archive mixed with code'
  ) || fail "archive mixed with code"

  pass "archive mixed with code blocked"
}

active_change_commit_passes
missing_change_commit_is_blocked
invalid_skip_commit_is_blocked
valid_skip_commit_passes
setup_scaffold_includes_files_metadata
done_change_commit_passes
done_change_with_additional_work_is_blocked
multiple_done_changes_are_blocked
scoped_commit_passes
unscoped_commit_is_blocked
empty_scope_falls_back
skip_mode_ignores_scope
multiple_changes_scope_matches
blank_files_field_falls_back
exempt_passes_under_scope
viewer_only_change_skips_sod_staleness() {
  local repo
  repo="$(make_repo viewer-sod)"

  (
    cd "$repo"
    seed_change_file build
    git add -A .spec/changes
    bash scripts/update-sod-report.sh
    git add .spec/changes .spec/sod-report.md README.md
    git commit -qm 'setup: baseline'

    # Simulate a viewer rebuild by touching docs/viewer.html
    echo "<!-- rebuilt -->" >> docs/viewer.html
    git add docs/viewer.html

    # The hook should NOT trigger SOD staleness for viewer-only changes
    # Test by sourcing the gate and checking has_sod_relevant_changes directly
    source .githooks/_spec_gate.sh
    if has_sod_relevant_changes; then
      exit 1
    fi
  ) || fail "viewer only change skips SOD staleness"

  pass "viewer only change skips SOD staleness"
}

archive_only_commit_passes
archive_mixed_with_code_is_blocked
viewer_only_change_skips_sod_staleness

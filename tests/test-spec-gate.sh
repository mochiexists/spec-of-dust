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

active_change_commit_passes() {
  local repo
  repo="$(make_repo active)"

  (
    cd "$repo"
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add CODEX.md README.md .spec/sod-report.md
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
    perl -0pi -e 's/status: build/status: spec/' .spec/changes/follow-up-repo-hygiene.md
    source .githooks/_spec_gate.sh
    has_active_standard_change && exit 1
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    bash scripts/update-sod-report.sh
    git add CODEX.md README.md .spec/sod-report.md
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
    perl -0pi -e 's/status: build/status: spec/' .spec/changes/follow-up-repo-hygiene.md
    source .githooks/_spec_gate.sh
    has_active_standard_change && exit 1
    perl -0pi -e 's/On session start, run:/On session start, always run:/' CODEX.md
    git add CODEX.md
    expect_blocked_commit "invalid skip commit" "Skip commits|must be staged for skip commits" git commit --no-verify -m 'test: invalid skip commit'
  ) || fail "invalid skip commit"

  pass "invalid skip commit"
}

valid_skip_commit_passes() {
  local repo
  repo="$(make_repo skip)"

  (
    cd "$repo"
    perl -0pi -e 's/status: build/status: spec/' .spec/changes/follow-up-repo-hygiene.md
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

active_change_commit_passes
missing_change_commit_is_blocked
invalid_skip_commit_is_blocked
valid_skip_commit_passes

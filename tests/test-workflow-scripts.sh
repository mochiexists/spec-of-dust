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

make_repo() {
  local name="$1"
  local repo="$TMP_DIR/$name"

  rsync -a --exclude '.git' "$ROOT_DIR/" "$repo/"
  (
    cd "$repo"
    find .spec/changes -maxdepth 1 -type f -name '*.md' \
      ! -name '_template.md' \
      ! -name '_example-*' \
      -delete
    git init -q
    git config user.name 'Test User'
    git config user.email 'test@example.com'
    chmod +x .githooks/* scripts/*.sh tests/*.sh
    git add .
    git commit --no-verify -qm 'baseline'
    git config core.hooksPath .githooks
  )

  printf '%s\n' "$repo"
}

seed_done_change() {
  find .spec/changes -maxdepth 1 -type f -name '*.md' \
    ! -name '_template.md' \
    ! -name '_example-*' \
    -delete

  cat > .spec/changes/test-change.md <<'EOF'
status: done

# Test change

## What
Test-only completed change for workflow script validation.

## Acceptance criteria
- [x] workflow script fixture

## Peer spec review
Synthetic fixture.

## Peer code review
Synthetic fixture.

## Verify
- [pass] Synthetic fixture.

## Closure
- Challenges: nothing notable
- Learnings: nothing notable
- Outcomes: nothing notable
- Dust: nothing notable
EOF
}

dust_check_detects_stale_output() {
  local repo
  repo="$(make_repo dust-check)"

  (
    cd "$repo"
    cat >> .spec/devlog.jsonl <<'EOF'
{"ts":"2026-04-17T08:00:00Z","event":"skip-no-verify","kind":"comment","summary":"stale dust test","reason":"fixture","files":["README.md"],"command":"git commit --no-verify"}
EOF

    if bash scripts/build-dust.sh --check; then
      exit 1
    fi
  ) || fail "dust check detects stale output"

  pass "dust check detects stale output"
}

setup_bootstraps_dust_and_scripts_work() {
  local repo
  repo="$(make_repo setup-fresh)"

  (
    cd "$repo"
    rm -f docs/dust.html
    bash setup.sh >/dev/null 2>&1
    [ -f docs/dust.html ] || exit 1
    bash scripts/build-dust.sh || exit 1
    bash scripts/devlog.sh --kind typo --summary "test" --reason "test" --file README.md || exit 1
    bash scripts/flowlog.sh --change test --agent claude --sentiment smooth || exit 1
  ) || fail "setup bootstraps dust and scripts work"

  pass "setup bootstraps dust and scripts work"
}

setup_detects_test_harness() {
  local repo output
  repo="$(make_repo setup-tests-found)"

  (
    cd "$repo"
    output="$(bash setup.sh 2>&1)"
    printf '%s\n' "$output" | grep -qF "Test files detected" || exit 1
  ) || fail "setup detects test harness"

  pass "setup detects test harness"
}

setup_warns_no_test_harness() {
  local repo output
  repo="$(make_repo setup-no-tests)"

  (
    cd "$repo"
    rm -rf tests test
    find . -maxdepth 3 -type f \( -name '*.test.*' -o -name '*_test.*' \) -delete 2>/dev/null || true
    output="$(bash setup.sh 2>&1)"
    printf '%s\n' "$output" | grep -qF "No test directory or test files found" || exit 1
  ) || fail "setup warns no test harness"

  pass "setup warns no test harness"
}

dust_check_detects_stale_output
setup_bootstraps_dust_and_scripts_work
setup_detects_test_harness
setup_warns_no_test_harness
archive_script_uses_utc_and_refreshes_outputs() {
  local attempt repo status

  for attempt in 1 2 3; do
    repo="$(make_repo "archive-utc-$attempt")"

    if (
      cd "$repo"
      seed_done_change
      bash scripts/build-dust.sh
      bash scripts/update-sod-report.sh
      git add .spec/changes docs/dust.html README.md .spec/sod-report.md
      git commit --no-verify -qm 'setup: done change'

      local utc_hour_before utc_hour_after local_hour archived_file archived_base archived_hour
      utc_hour_before="$(TZ=UTC date +%H)"
      local_hour="$(TZ=Pacific/Honolulu date +%H)"

      TZ=Pacific/Honolulu bash scripts/archive-done-changes.sh --require-done

      archived_file="$(find .spec/archive -maxdepth 1 -type f -name '*-test-change.md' | head -1)"
      [ -n "$archived_file" ] || exit 1

      archived_base="$(basename "$archived_file")"
      archived_hour="${archived_base:11:2}"
      utc_hour_after="$(TZ=UTC date +%H)"

      if [ "$utc_hour_before" != "$utc_hour_after" ]; then
        exit 2
      fi

      [ "$archived_hour" = "$utc_hour_before" ] || exit 1
      [ "$archived_hour" != "$local_hour" ] || exit 1

      bash scripts/build-dust.sh --check
      bash scripts/update-sod-report.sh --check
      git diff --cached --name-only | grep -Fx 'docs/dust.html' >/dev/null
      git diff --cached --name-only | grep -Fx 'README.md' >/dev/null
      git diff --cached --name-only | grep -Fx '.spec/sod-report.md' >/dev/null
    ); then
      pass "archive script uses UTC and refreshes outputs"
      return 0
    fi
    status=$?

    # Retry if the clock rolled over during the hour assertion window.
    if [ "$status" -ne 2 ]; then
      fail "archive script uses UTC and refreshes outputs"
    fi
  done

  fail "archive script uses UTC and refreshes outputs"
}

archive_script_uses_utc_and_refreshes_outputs

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

push_auto_delivers_to_remote() {
  local repo bare_remote
  repo="$(make_repo push-auto)"
  bare_remote="$TMP_DIR/push-auto-remote.git"

  (
    git init -q --bare "$bare_remote"

    cd "$repo"
    # Set push: auto — replace any existing push: line or append if none (cross-platform)
    if grep -q '^push:' .spec/b-startup.md; then
      awk '/^push:/ { print "push: auto"; next } { print }' .spec/b-startup.md > .spec/b-startup.md.tmp
      mv .spec/b-startup.md.tmp .spec/b-startup.md
    else
      printf '\npush: auto\n' >> .spec/b-startup.md
    fi
    bash scripts/update-sod-report.sh
    git add -A
    git -c core.hooksPath=/dev/null commit -qm 'config: push auto'
    git remote add origin "$bare_remote"
    git push -u origin main 2>/dev/null

    seed_done_change
    bash scripts/build-dust.sh
    bash scripts/update-sod-report.sh
    git add -A
    git -c core.hooksPath=/dev/null commit -qm 'setup: done change'

    bash scripts/merge-completed-work.sh

    # Verify the archive commit arrived at the remote
    git -C "$bare_remote" log --oneline -1 | grep -q "archive completed specs" || exit 1
  ) || fail "push auto delivers to remote"

  pass "push auto delivers to remote"
}

push_skipped_when_no_origin() {
  local repo output
  repo="$(make_repo push-no-origin)"

  (
    cd "$repo"
    if grep -q '^push:' .spec/b-startup.md; then
      awk '/^push:/ { print "push: auto"; next } { print }' .spec/b-startup.md > .spec/b-startup.md.tmp
      mv .spec/b-startup.md.tmp .spec/b-startup.md
    else
      printf '\npush: auto\n' >> .spec/b-startup.md
    fi
    bash scripts/update-sod-report.sh
    git add -A
    git -c core.hooksPath=/dev/null commit -qm 'config: push auto'

    seed_done_change
    bash scripts/build-dust.sh
    bash scripts/update-sod-report.sh
    git add -A
    git -c core.hooksPath=/dev/null commit -qm 'setup: done change'

    output="$(bash scripts/merge-completed-work.sh 2>&1)"
    printf '%s\n' "$output" | grep -qF "No remote" || exit 1
  ) || fail "push skipped when no origin"

  pass "push skipped when no origin"
}

setup_configures_self_update_scaffolding() {
  local repo
  repo="$(make_repo self-update-fresh)"

  (
    cd "$repo"
    # Remove existing b-startup and gitignore to simulate a truly fresh setup
    rm -f .spec/b-startup.md .gitignore
    bash setup.sh >/dev/null 2>&1

    # b-startup.md should have both self-update keys
    grep -qF 'sod-upstream:' .spec/b-startup.md || exit 1
    grep -qF 'sod-check-interval: 30d' .spec/b-startup.md || exit 1

    # .gitignore should list sod-last-checked
    grep -qF '.spec/sod-last-checked' .gitignore || exit 1

    # Running setup again should be idempotent (no duplicate gitignore entries)
    bash setup.sh >/dev/null 2>&1
    [ "$(grep -cF '.spec/sod-last-checked' .gitignore)" = "1" ] || exit 1
  ) || fail "setup configures self-update scaffolding"

  pass "setup configures self-update scaffolding"
}

sod_report_counts_unicode_codepoints_not_bytes() {
  local repo report
  repo="$(make_repo sod-unicode)"

  (
    cd "$repo"
    # Replace any existing repo content with a tiny file whose length is only
    # predictable at the character-count level: 5 em-dashes + newline = 6 code-points,
    # but 16 bytes in UTF-8 (each em-dash is 3 bytes).
    # Use `git ls-files -z` + rm so we don't fight git's view of the repo, then
    # commit a known fixture.
    mkdir -p fixtures
    # Write 5 em-dashes + newline using raw UTF-8 bytes (E2 80 94 per em-dash).
    # Using bytes rather than $'\u...' keeps this working on bash 3.2 (macOS default).
    # 5 code-points + newline = 6 chars, 15 bytes + newline = 16 bytes.
    # The discriminator 6-vs-16 is how we detect locale drift.
    printf '\xe2\x80\x94\xe2\x80\x94\xe2\x80\x94\xe2\x80\x94\xe2\x80\x94\n' > fixtures/mbchars.md
    # The sod script lists files via `git ls-files`, so stage the fixture
    git add fixtures/mbchars.md
    git -c core.hooksPath=/dev/null commit -qm "add mbchars fixture"

    # Run the script and inspect the generated row for fixtures/mbchars.md
    bash scripts/update-sod-report.sh >/dev/null 2>&1 || exit 1
    report="$(cat .spec/sod-report.md)"

    # Extract the character count column for the fixture file's row
    # Format: | `path` | lines | words | chars | tokens |
    local row chars
    row="$(printf '%s\n' "$report" | grep -F "fixtures/mbchars.md" || true)"
    [ -n "$row" ] || exit 1
    # chars is the 4th pipe-delimited field after the leading " | "
    chars="$(printf '%s' "$row" | awk -F'|' '{gsub(/ /,"",$5); print $5}')"
    # Expected: 6 code-points (5 em-dashes + 1 newline). If we were counting
    # bytes we'd see 16. The assertion discriminates the two.
    [ "$chars" = "6" ] || { echo "expected 6 code-points, got '$chars'" >&2; exit 1; }
  ) || fail "sod-report counts unicode code-points not bytes"

  pass "sod-report counts unicode code-points not bytes"
}

build_dust_regenerates_from_template() {
  local repo marker
  repo="$(make_repo build-dust-template-regen)"
  marker="MARKER_PROPAGATION_TEST_$$"

  (
    cd "$repo"
    # Edit the template: add a unique marker comment into the HTML structure
    awk -v m="$marker" '
      /<main>/ { print; print "      <!-- " m " -->"; next }
      { print }
    ' templates/dust.html > templates/dust.html.tmp
    mv templates/dust.html.tmp templates/dust.html

    bash scripts/build-dust.sh >/dev/null 2>&1 || exit 1

    # docs/dust.html should now contain the marker
    grep -qF "$marker" docs/dust.html || exit 1

    # --check should be clean after regen
    bash scripts/build-dust.sh --check || exit 1
  ) || fail "build-dust regenerates from template"

  pass "build-dust regenerates from template"
}

build_dust_errors_on_missing_markers() {
  local repo output
  repo="$(make_repo build-dust-bad-markers)"

  (
    cd "$repo"
    # Corrupt the template by removing the start marker
    awk '!/embedded-data:start/' templates/dust.html > templates/dust.html.tmp
    mv templates/dust.html.tmp templates/dust.html

    output="$(bash scripts/build-dust.sh 2>&1)" && exit 1
    printf '%s\n' "$output" | grep -qF "marker" || exit 1
  ) || fail "build-dust errors on missing markers"

  pass "build-dust errors on missing markers"
}

build_dust_errors_on_missing_template() {
  local repo output
  repo="$(make_repo build-dust-missing-template)"

  (
    cd "$repo"
    rm -f templates/dust.html

    output="$(bash scripts/build-dust.sh 2>&1)" && exit 1
    printf '%s\n' "$output" | grep -qF "templates/dust.html" || exit 1
    printf '%s\n' "$output" | grep -qF "distribution" || exit 1
  ) || fail "build-dust errors on missing template"

  pass "build-dust errors on missing template"
}

build_dust_errors_on_reversed_markers() {
  local repo output
  repo="$(make_repo build-dust-reversed-markers)"

  (
    cd "$repo"
    # Swap start/end markers so end appears first
    awk '
      /embedded-data:start/ { print "      /* embedded-data:end */"; next }
      /embedded-data:end/   { print "      /* embedded-data:start */"; next }
      { print }
    ' templates/dust.html > templates/dust.html.tmp
    mv templates/dust.html.tmp templates/dust.html

    output="$(bash scripts/build-dust.sh 2>&1)" && exit 1
    printf '%s\n' "$output" | grep -qF "must appear before" || exit 1
  ) || fail "build-dust errors on reversed markers"

  pass "build-dust errors on reversed markers"
}

archive_script_uses_utc_and_refreshes_outputs
push_auto_delivers_to_remote
push_skipped_when_no_origin
make_gh_shim() {
  # Creates a shim that intercepts `gh` calls. Behavior driven by env vars:
  #   SHIM_AUTH_STATUS       — 0 or 1, controls `gh auth status` exit
  #   SHIM_RUN_LIST_JSON     — JSON returned for `gh run list ... --json` (default: [])
  #   SHIM_RUN_VIEW_JSON     — JSON returned for `gh run view ... --json jobs` (default: empty jobs)
  #   SHIM_RUN_LIST_FAIL     — if set to 1, `gh run list` exits non-zero (simulate network error)
  local shim_dir="$1"
  mkdir -p "$shim_dir"
  cat > "$shim_dir/gh" <<'GHEOF'
#!/usr/bin/env bash
case "$1" in
  auth)
    if [ "${SHIM_AUTH_STATUS:-0}" = "0" ]; then exit 0; fi
    exit 1
    ;;
  run)
    case "$2" in
      list)
        if [ "${SHIM_RUN_LIST_FAIL:-0}" = "1" ]; then
          echo "network error" >&2
          exit 1
        fi
        if [ -n "${SHIM_RUN_LIST_JSON:-}" ]; then
          printf '%s' "$SHIM_RUN_LIST_JSON"
        else
          printf '%s' "[]"
        fi
        ;;
      view)
        if [ -n "${SHIM_RUN_VIEW_JSON:-}" ]; then
          printf '%s' "$SHIM_RUN_VIEW_JSON"
        else
          printf '%s' '{"jobs":[]}'
        fi
        ;;
      *)
        echo "unexpected gh run subcommand: $2" >&2
        exit 1
        ;;
    esac
    ;;
  *)
    echo "unexpected gh command: $1" >&2
    exit 1
    ;;
esac
GHEOF
  chmod +x "$shim_dir/gh"
}

make_git_upstream_repo() {
  # Creates a minimal git repo with an upstream on a real (bare) remote named
  # `origin`, so the script can resolve @{upstream} AND derive a GitHub-style
  # URL from the origin remote. Prints the HEAD sha so tests can embed it in
  # their shim fixtures (the check script scopes runs to HEAD).
  local repo="$1"
  local bare="${repo}.git"
  mkdir -p "$repo"
  git init -q --bare "$bare"
  (
    cd "$repo"
    git init -q
    git config user.name 'Test User'
    git config user.email 'test@example.com'
    git commit -q --allow-empty -m "initial"
    # Point origin at the bare repo using a GitHub-looking URL so the deploy-URL
    # resolver is exercised. The bare repo lives at $bare; we set the remote's
    # URL to a GitHub-style string and push using $bare as the actual target.
    git remote add origin "git@github.com:test-owner/test-repo.git"
    git config --replace-all remote.origin.url "git@github.com:test-owner/test-repo.git"
    git config --add remote.origin.pushurl "$bare"
    git config --add remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git push -q origin main
    git branch --set-upstream-to=origin/main main >/dev/null
    git rev-parse HEAD
  )
}

check_deploy_health_exit_0_all_green() {
  local repo shim head_sha output
  repo="$TMP_DIR/health-green"
  shim="$TMP_DIR/shim-green"
  head_sha="$(make_git_upstream_repo "$repo")"
  make_gh_shim "$shim"

  (
    cd "$repo"
    # Add an origin remote so the success path can build a deploy URL
    git remote add origin "git@github.com:test-owner/test-repo.git"
    cp "$ROOT_DIR/scripts/check-deploy-health.sh" ./check.sh
    chmod +x check.sh
    export PATH="$shim:$PATH"
    export SHIM_RUN_LIST_JSON="[{\"databaseId\":1,\"name\":\"Validate\",\"status\":\"completed\",\"conclusion\":\"success\",\"workflowName\":\"Validate\",\"url\":\"u1\",\"headSha\":\"$head_sha\"}]"
    output="$(bash ./check.sh 2>&1)" || exit 1
    printf '%s\n' "$output" | grep -qF "All 1 workflow(s) green" || exit 1
    # Deploy URL should be present for user-visible confirmation
    printf '%s\n' "$output" | grep -qF "https://github.com/test-owner/test-repo/actions?query=branch:" || exit 1
  ) || fail "check-deploy-health exit 0 on all green"

  pass "check-deploy-health exit 0 on all green"
}

check_deploy_health_exit_1_on_failure() {
  local repo shim output rc head_sha
  repo="$TMP_DIR/health-fail"
  shim="$TMP_DIR/shim-fail"
  head_sha="$(make_git_upstream_repo "$repo")"
  make_gh_shim "$shim"

  (
    cd "$repo"
    cp "$ROOT_DIR/scripts/check-deploy-health.sh" ./check.sh
    chmod +x check.sh
    export PATH="$shim:$PATH"
    export SHIM_RUN_LIST_JSON="[{\"databaseId\":42,\"name\":\"Validate\",\"status\":\"completed\",\"conclusion\":\"failure\",\"workflowName\":\"Validate\",\"url\":\"https://example.com/42\",\"headSha\":\"$head_sha\"}]"
    export SHIM_RUN_VIEW_JSON='{"jobs":[{"steps":[{"name":"Check sod outputs","conclusion":"failure"}]}]}'
    output="$(bash ./check.sh 2>&1)" && rc=0 || rc=$?
    [ "$rc" = "1" ] || exit 1
    printf '%s\n' "$output" | grep -qF "Validate" || exit 1
    printf '%s\n' "$output" | grep -qF "Check sod outputs" || exit 1
    printf '%s\n' "$output" | grep -qF "https://example.com/42" || exit 1
  ) || fail "check-deploy-health exit 1 on failure"

  pass "check-deploy-health exit 1 on failure"
}

check_deploy_health_exit_2_in_progress() {
  local repo shim rc head_sha
  repo="$TMP_DIR/health-inprogress"
  shim="$TMP_DIR/shim-inprogress"
  head_sha="$(make_git_upstream_repo "$repo")"
  make_gh_shim "$shim"

  (
    cd "$repo"
    cp "$ROOT_DIR/scripts/check-deploy-health.sh" ./check.sh
    chmod +x check.sh
    export PATH="$shim:$PATH"
    export SHIM_RUN_LIST_JSON="[{\"databaseId\":7,\"name\":\"Validate\",\"status\":\"in_progress\",\"conclusion\":\"\",\"workflowName\":\"Validate\",\"url\":\"u7\",\"headSha\":\"$head_sha\"}]"
    bash ./check.sh >/dev/null 2>&1 && rc=0 || rc=$?
    [ "$rc" = "2" ] || exit 1
  ) || fail "check-deploy-health exit 2 on in-progress only"

  pass "check-deploy-health exit 2 on in-progress only"
}

check_deploy_health_exit_3_on_unauthenticated() {
  local repo shim rc
  repo="$TMP_DIR/health-unauth"
  shim="$TMP_DIR/shim-unauth"
  make_git_upstream_repo "$repo" >/dev/null
  make_gh_shim "$shim"

  (
    cd "$repo"
    cp "$ROOT_DIR/scripts/check-deploy-health.sh" ./check.sh
    chmod +x check.sh
    export PATH="$shim:$PATH"
    export SHIM_AUTH_STATUS=1
    bash ./check.sh >/dev/null 2>&1 && rc=0 || rc=$?
    [ "$rc" = "3" ] || exit 1
  ) || fail "check-deploy-health exit 3 on unauthenticated"

  pass "check-deploy-health exit 3 on unauthenticated"
}

check_deploy_health_exit_3_on_gh_missing() {
  local repo rc
  repo="$TMP_DIR/health-gh-missing"
  make_git_upstream_repo "$repo" >/dev/null

  (
    cd "$repo"
    cp "$ROOT_DIR/scripts/check-deploy-health.sh" ./check.sh
    chmod +x check.sh
    # PATH contains core binaries (bash, git, python3) but not gh's usual homes.
    # This pattern is robust as long as gh isn't in /bin or /usr/bin.
    PATH="/usr/bin:/bin" bash ./check.sh >/dev/null 2>&1 && rc=0 || rc=$?
    [ "$rc" = "3" ] || exit 1
  ) || fail "check-deploy-health exit 3 when gh missing"

  pass "check-deploy-health exit 3 when gh missing"
}

check_deploy_health_failure_takes_precedence_over_in_progress() {
  local repo shim rc head_sha
  repo="$TMP_DIR/health-precedence"
  shim="$TMP_DIR/shim-precedence"
  head_sha="$(make_git_upstream_repo "$repo")"
  make_gh_shim "$shim"

  (
    cd "$repo"
    cp "$ROOT_DIR/scripts/check-deploy-health.sh" ./check.sh
    chmod +x check.sh
    export PATH="$shim:$PATH"
    export SHIM_RUN_LIST_JSON="[{\"databaseId\":100,\"name\":\"Validate\",\"status\":\"completed\",\"conclusion\":\"failure\",\"workflowName\":\"Validate\",\"url\":\"u100\",\"headSha\":\"$head_sha\"},{\"databaseId\":101,\"name\":\"Other\",\"status\":\"in_progress\",\"conclusion\":\"\",\"workflowName\":\"Other\",\"url\":\"u101\",\"headSha\":\"$head_sha\"}]"
    export SHIM_RUN_VIEW_JSON='{"jobs":[{"steps":[{"name":"failed-step","conclusion":"failure"}]}]}'
    bash ./check.sh >/dev/null 2>&1 && rc=0 || rc=$?
    [ "$rc" = "1" ] || exit 1
  ) || fail "check-deploy-health failure takes precedence over in-progress"

  pass "check-deploy-health failure takes precedence over in-progress"
}

setup_configures_self_update_scaffolding
sod_report_counts_unicode_codepoints_not_bytes
build_dust_regenerates_from_template
build_dust_errors_on_missing_markers
build_dust_errors_on_missing_template
build_dust_errors_on_reversed_markers
check_deploy_health_exit_0_all_green
check_deploy_health_exit_1_on_failure
check_deploy_health_exit_2_in_progress
check_deploy_health_exit_3_on_unauthenticated
check_deploy_health_exit_3_on_gh_missing
check_deploy_health_failure_takes_precedence_over_in_progress

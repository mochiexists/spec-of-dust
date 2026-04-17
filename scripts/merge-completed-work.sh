#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STARTUP_FILE="$ROOT_DIR/.spec/b-startup.md"
ARCHIVE_SCRIPT="$ROOT_DIR/scripts/archive-done-changes.sh"
SOD_SCRIPT="$ROOT_DIR/scripts/update-sod-report.sh"
VIEWER_SCRIPT="$ROOT_DIR/scripts/build-dust.sh"
HOOK_TEST_SCRIPT="$ROOT_DIR/tests/test-spec-gate.sh"
target=""
auto_mode=0
completed=0

extract_startup_value() {
  local key="$1"

  [ -f "$STARTUP_FILE" ] || return 0

  awk -v key="$key" '
    index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "", $0)
      print $0
      exit
    }
  ' "$STARTUP_FILE"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      shift
      [ $# -gt 0 ] || {
        echo "--target requires a branch name." >&2
        exit 1
      }
      target="$1"
      ;;
    --auto) auto_mode=1 ;;
    *)
      echo "Usage: $0 [--target BRANCH] [--auto]" >&2
      exit 1
      ;;
  esac
  shift
done

report_failure() {
  local exit_code=$?

  if [ "$completed" -eq 0 ] && [ "$exit_code" -ne 0 ]; then
    echo "Merge-and-advance failed on branch '$(git branch --show-current 2>/dev/null || printf unknown)'." >&2
  fi

  exit "$exit_code"
}

trap report_failure EXIT

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a Git repository." >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree must be clean before merge-and-advance." >&2
  exit 1
fi

target="${target:-$(extract_startup_value merge-target)}"
target="${target:-main}"
current_branch="$(git branch --show-current)"

[ -n "$current_branch" ] || {
  echo "Could not determine the current branch." >&2
  exit 1
}

run_archive_commit() {
  "$ARCHIVE_SCRIPT" --require-done --quiet

  if git diff --cached --quiet; then
    echo "Archive step produced no staged changes." >&2
    exit 1
  fi

  git commit -m "chore: archive completed specs"
}

check_auto_prerequisites() {
  [ "$auto_mode" -eq 1 ] || return 0

  if [ -x "$SOD_SCRIPT" ] && ! "$SOD_SCRIPT" --check >/dev/null 2>&1; then
    echo "Auto merge requires fresh sod outputs." >&2
    exit 1
  fi

  if [ -x "$VIEWER_SCRIPT" ] && ! "$VIEWER_SCRIPT" --check >/dev/null 2>&1; then
    echo "Auto merge requires a fresh dust build." >&2
    exit 1
  fi

  if [ -x "$HOOK_TEST_SCRIPT" ] && ! "$HOOK_TEST_SCRIPT" >/dev/null 2>&1; then
    echo "Auto merge requires repo-local hook tests to pass." >&2
    exit 1
  fi
}

check_auto_prerequisites

if [ "$current_branch" = "$target" ]; then
  run_archive_commit
  echo "Archived completed changes on target branch '$target'."
  exit 0
fi

run_archive_commit

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree became dirty during archive step." >&2
  exit 1
fi

git checkout "$target"
git merge --no-ff "$current_branch" -m "merge: ${current_branch}"

completed=1
echo "Merged '$current_branch' into '$target'."

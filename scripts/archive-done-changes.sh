#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_DIR="$ROOT_DIR/.spec/changes"
ARCHIVE_DIR="$ROOT_DIR/.spec/archive"
require_done=0
quiet=0

while [ $# -gt 0 ]; do
  case "$1" in
    --require-done) require_done=1 ;;
    --quiet) quiet=1 ;;
    *)
      echo "Usage: $0 [--require-done] [--quiet]" >&2
      exit 1
      ;;
  esac
  shift
done

cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not inside a Git repository." >&2
  exit 1
fi

[ -d "$SPEC_DIR" ] || {
  [ "$require_done" -eq 0 ] && exit 0
  echo "Missing .spec/changes directory." >&2
  exit 1
}

mkdir -p "$ARCHIVE_DIR"

archived=0

extract_status() {
  awk '
    index($0, "status:") == 1 {
      sub("^status:[[:space:]]*", "", $0)
      print $0
      exit
    }
  ' "$1"
}

for f in "$SPEC_DIR"/*.md; do
  [ -f "$f" ] || continue

  case "$(basename "$f")" in
    _template.md|_example-*) continue ;;
  esac

  if [ "$(extract_status "$f")" = "done" ]; then
    basename_f="$(basename "$f")"
    timestamp="$(date +%Y-%m-%d-%H%M%S)"
    dest="$ARCHIVE_DIR/${timestamp}-${basename_f}"

    if [ -f "$dest" ]; then
      dest="$ARCHIVE_DIR/${timestamp}-$$-${basename_f}"
    fi

    git mv "$f" "$dest"
    archived=$((archived + 1))
  fi
done

if [ "$archived" -eq 0 ] && [ "$require_done" -eq 1 ]; then
  echo "No completed standard change files found in .spec/changes/." >&2
  exit 1
fi

if [ "$archived" -gt 0 ] && [ "$quiet" -eq 0 ]; then
  echo ""
  echo "📦 Archived $archived completed change file(s) to .spec/archive/"
  echo "   Review staged changes before committing."
  echo ""
fi

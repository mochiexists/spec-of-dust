#!/usr/bin/env bash
# scripts/devlog.sh — append a validated skip-no-verify entry to .spec/devlog.jsonl

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVLOG_FILE="$ROOT_DIR/.spec/devlog.jsonl"
VALID_KINDS="typo|version-bump|comment|config-tweak|one-line-fix"

usage() {
  cat <<EOF
Usage: $0 --kind KIND --summary TEXT --reason TEXT --file PATH

Required:
  --kind       One of: typo, version-bump, comment, config-tweak, one-line-fix
  --summary    Short description of the change
  --reason     Why this qualifies as a skip commit
  --file       Single file path being changed

Auto-set: ts (UTC ISO 8601), event ("skip-no-verify"), command ("git commit --no-verify")
EOF
  exit 1
}

escape_json() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="$(printf '%s' "$s" | tr '\n\t\r' '   ')"
  printf '%s' "$s"
}

kind="" summary="" reason="" file=""

while [ $# -gt 0 ]; do
  case "$1" in
    --kind)    [ $# -ge 2 ] || { echo "Error: --kind requires a value" >&2; usage; }; kind="$2";    shift 2 ;;
    --summary) [ $# -ge 2 ] || { echo "Error: --summary requires a value" >&2; usage; }; summary="$2"; shift 2 ;;
    --reason)  [ $# -ge 2 ] || { echo "Error: --reason requires a value" >&2; usage; }; reason="$2";  shift 2 ;;
    --file)    [ $# -ge 2 ] || { echo "Error: --file requires a value" >&2; usage; }; file="$2";    shift 2 ;;
    *)         echo "Unknown arg: $1" >&2; usage ;;
  esac
done

[ -n "$kind" ]    || { echo "Error: --kind is required" >&2; usage; }
[ -n "$summary" ] || { echo "Error: --summary is required" >&2; usage; }
[ -n "$reason" ]  || { echo "Error: --reason is required" >&2; usage; }
[ -n "$file" ]    || { echo "Error: --file is required" >&2; usage; }

if ! printf '%s' "$kind" | grep -Eq "^($VALID_KINDS)$"; then
  echo "Error: --kind must be one of: typo, version-bump, comment, config-tweak, one-line-fix" >&2
  exit 1
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '{"ts":"%s","event":"skip-no-verify","kind":"%s","summary":"%s","reason":"%s","files":["%s"],"command":"git commit --no-verify"}\n' \
  "$ts" \
  "$(escape_json "$kind")" \
  "$(escape_json "$summary")" \
  "$(escape_json "$reason")" \
  "$(escape_json "$file")" \
  >> "$DEVLOG_FILE"

echo "Appended skip entry to $DEVLOG_FILE"

# Refresh viewer with embedded data
VIEWER_SCRIPT="$ROOT_DIR/scripts/build-viewer.sh"
if [ -x "$VIEWER_SCRIPT" ]; then
  "$VIEWER_SCRIPT"
fi

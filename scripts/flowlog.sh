#!/usr/bin/env bash
# scripts/flowlog.sh — append a validated workflow feedback entry to .spec/flowlog.jsonl

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLOWLOG_FILE="$ROOT_DIR/.spec/flowlog.jsonl"
VALID_SENTIMENTS="smooth|rough|blocked"

usage() {
  cat <<EOF
Usage: $0 --change NAME --agent MODEL --sentiment VALUE [OPTIONS]

Required:
  --change      Change name (kebab-case, matches the change file)
  --agent       Which model completed the change (claude or codex)
  --sentiment   Gut-check: smooth, rough, or blocked

Optional:
  --divergence  Flow divergences observed (default: "")
  --friction    Friction points (default: "")
  --suggestion  Suggestions for flow improvement (default: "")

Auto-set: ts (UTC ISO 8601)
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

change="" agent="" sentiment="" divergence="" friction="" suggestion=""

while [ $# -gt 0 ]; do
  case "$1" in
    --change)     [ $# -ge 2 ] || { echo "Error: --change requires a value" >&2; usage; }; change="$2";     shift 2 ;;
    --agent)      [ $# -ge 2 ] || { echo "Error: --agent requires a value" >&2; usage; }; agent="$2";      shift 2 ;;
    --sentiment)  [ $# -ge 2 ] || { echo "Error: --sentiment requires a value" >&2; usage; }; sentiment="$2";  shift 2 ;;
    --divergence) [ $# -ge 2 ] || { echo "Error: --divergence requires a value" >&2; usage; }; divergence="$2"; shift 2 ;;
    --friction)   [ $# -ge 2 ] || { echo "Error: --friction requires a value" >&2; usage; }; friction="$2";   shift 2 ;;
    --suggestion) [ $# -ge 2 ] || { echo "Error: --suggestion requires a value" >&2; usage; }; suggestion="$2"; shift 2 ;;
    *)            echo "Unknown arg: $1" >&2; usage ;;
  esac
done

[ -n "$change" ]    || { echo "Error: --change is required" >&2; usage; }
[ -n "$agent" ]     || { echo "Error: --agent is required" >&2; usage; }
[ -n "$sentiment" ] || { echo "Error: --sentiment is required" >&2; usage; }

if ! printf '%s' "$agent" | grep -Eq "^(claude|codex)$"; then
  echo "Error: --agent must be claude or codex" >&2
  exit 1
fi

if ! printf '%s' "$sentiment" | grep -Eq "^($VALID_SENTIMENTS)$"; then
  echo "Error: --sentiment must be one of: smooth, rough, blocked" >&2
  exit 1
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '{"ts":"%s","agent":"%s","change":"%s","flow_divergence":"%s","friction":"%s","suggestion":"%s","sentiment":"%s"}\n' \
  "$ts" \
  "$(escape_json "$agent")" \
  "$(escape_json "$change")" \
  "$(escape_json "$divergence")" \
  "$(escape_json "$friction")" \
  "$(escape_json "$suggestion")" \
  "$(escape_json "$sentiment")" \
  >> "$FLOWLOG_FILE"

echo "Appended flowlog entry to $FLOWLOG_FILE"

# Refresh dust with embedded data
VIEWER_SCRIPT="$ROOT_DIR/scripts/build-dust.sh"
if [ -x "$VIEWER_SCRIPT" ]; then
  "$VIEWER_SCRIPT"
fi

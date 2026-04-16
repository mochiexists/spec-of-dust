#!/usr/bin/env bash
# scripts/build-viewer.sh — embed JSONL log data into docs/viewer.html

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIEWER="$ROOT_DIR/docs/viewer.html"
DEVLOG="$ROOT_DIR/.spec/devlog.jsonl"
FLOWLOG="$ROOT_DIR/.spec/flowlog.jsonl"
MARKER_START='/* embedded-data:start */'
MARKER_END='/* embedded-data:end */'

[ -f "$VIEWER" ] || { echo "Error: $VIEWER not found" >&2; exit 1; }

# Verify markers exist exactly once
start_count="$(grep -cF "$MARKER_START" "$VIEWER")"
end_count="$(grep -cF "$MARKER_END" "$VIEWER")"
[ "$start_count" -eq 1 ] || { echo "Error: expected 1 '$MARKER_START' marker, found $start_count" >&2; exit 1; }
[ "$end_count" -eq 1 ] || { echo "Error: expected 1 '$MARKER_END' marker, found $end_count" >&2; exit 1; }

# Read JSONL lines into a JS array literal, escaping for safe embedding
jsonl_to_js_array() {
  local file="$1"
  local result="["

  if [ -f "$file" ]; then
    local first=true
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      if [ "$first" = true ]; then
        first=false
      else
        result+=","
      fi
      # Escape backslashes, quotes, </script>, and JS line separators (U+2028/U+2029)
      local escaped="$line"
      escaped="${escaped//\\/\\\\}"
      escaped="${escaped//\"/\\\"}"
      escaped="${escaped//<\/script>/<\\\/script>}"
      escaped="$(printf '%s' "$escaped" | sed $'s/\xe2\x80\xa8/\\\\u2028/g; s/\xe2\x80\xa9/\\\\u2029/g')"
      result+="\"$escaped\""
    done < "$file"
  fi

  result+="]"
  printf '%s' "$result"
}

devlog_js="$(jsonl_to_js_array "$DEVLOG")"
flowlog_js="$(jsonl_to_js_array "$FLOWLOG")"

# Write the data block to a temp file for safe insertion
tmp="$(mktemp)"
data_tmp="$(mktemp)"
trap 'rm -f "$tmp" "$data_tmp"' EXIT

cat > "$data_tmp" <<DATAEOF
      $MARKER_START
      const EMBEDDED_DEVLOG = $devlog_js;
      const EMBEDDED_FLOWLOG = $flowlog_js;
      $MARKER_END
DATAEOF

# Replace the data block in the viewer using the temp file
awk -v start="$MARKER_START" -v end="$MARKER_END" -v datafile="$data_tmp" '
  index($0, start) {
    while ((getline line < datafile) > 0) print line
    close(datafile)
    in_block = 1
    next
  }
  index($0, end) {
    in_block = 0
    next
  }
  !in_block { print }
' "$VIEWER" > "$tmp"

if ! cmp -s "$tmp" "$VIEWER"; then
  cp "$tmp" "$VIEWER"
  echo "Updated $VIEWER with embedded log data"
else
  echo "Viewer data is already current"
fi

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

# Parse a change file into a JSON object
parse_change_file() {
  local file="$1"
  local basename_f name status ts what dust challenges learnings outcomes
  local peer_spec_review peer_code_review verify section=""
  local body=""

  basename_f="$(basename "$file" .md)"

  # Extract timestamped archive prefixes before the more generic date-only form.
  if [[ "$basename_f" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})-(.+)$ ]]; then
    ts="${BASH_REMATCH[1]}T${BASH_REMATCH[2]}:${BASH_REMATCH[3]}:${BASH_REMATCH[4]}Z"
    name="${BASH_REMATCH[5]}"
  elif [[ "$basename_f" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-(.+)$ ]]; then
    ts="${BASH_REMATCH[1]}T00:00:00Z"
    name="${BASH_REMATCH[2]}"
  else
    ts=""
    name="$basename_f"
  fi

  status="" what="" dust="" challenges="" learnings="" outcomes=""
  peer_spec_review="" peer_code_review="" verify=""

  while IFS= read -r line; do
    # Status from first line
    if [ -z "$status" ] && [[ "$line" =~ ^status:\ *(.+)$ ]]; then
      status="${BASH_REMATCH[1]}"
      continue
    fi

    # Section headers
    if [[ "$line" =~ ^##\  ]]; then
      # Save previous section
      save_section "$section" "$body"
      body=""
      case "$line" in
        "## What"*) section="what" ;;
        "## Peer spec review"*) section="peer_spec_review" ;;
        "## Peer code review"*) section="peer_code_review" ;;
        "## Verify"*) section="verify" ;;
        "## Closure"*) section="closure" ;;
        *) section="other" ;;
      esac
      continue
    fi

    # Closure field extraction
    if [ "$section" = "closure" ]; then
      case "$line" in
        "- Dust:"*) dust="${line#*- Dust: }" ;;
        "- Challenges:"*) challenges="${line#*- Challenges: }" ;;
        "- Learnings:"*) learnings="${line#*- Learnings: }" ;;
        "- Outcomes:"*) outcomes="${line#*- Outcomes: }" ;;
      esac
    fi

    # Accumulate body
    body+="$line"$'\n'
  done < "$file"

  # Save last section
  save_section "$section" "$body"

  # If no ts from filename, try to find one from flowlog
  if [ -z "$ts" ] && [ -f "$FLOWLOG" ]; then
    local flowlog_ts
    flowlog_ts="$(grep "\"change\":\"$name\"" "$FLOWLOG" 2>/dev/null | head -1 | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')"
    [ -n "$flowlog_ts" ] && ts="$flowlog_ts"
  fi

  # Build JSON
  printf '{"name":"%s","status":"%s","ts":"%s","what":"%s","dust":"%s","challenges":"%s","learnings":"%s","outcomes":"%s","peer_spec_review":"%s","peer_code_review":"%s","verify":"%s"}' \
    "$(escape_str "$name")" \
    "$(escape_str "$status")" \
    "$(escape_str "$ts")" \
    "$(escape_str "$_what")" \
    "$(escape_str "$dust")" \
    "$(escape_str "$challenges")" \
    "$(escape_str "$learnings")" \
    "$(escape_str "$outcomes")" \
    "$(escape_str "$_peer_spec_review")" \
    "$(escape_str "$_peer_code_review")" \
    "$(escape_str "$_verify")"
}

# Section accumulator variables
_what="" _peer_spec_review="" _peer_code_review="" _verify=""

save_section() {
  local section="$1"
  local content="$2"
  # Trim leading/trailing blank lines
  content="$(printf '%s' "$content" | sed '/^<!--.*-->$/d' | awk 'NF{found=1} found')"
  case "$section" in
    what) _what="$content" ;;
    peer_spec_review) _peer_spec_review="$content" ;;
    peer_code_review) _peer_code_review="$content" ;;
    verify) _verify="$content" ;;
  esac
}

# Escape a string for embedding in JS
escape_str() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//<\/script>/<\\\/script>}"
  printf '%s' "$s"
}

# Collect change files
changes_js="["
changes_first=true

for dir in "$ROOT_DIR/.spec/archive" "$ROOT_DIR/.spec/changes"; do
  [ -d "$dir" ] || continue
  for file in "$dir"/*.md; do
    [ -f "$file" ] || continue
    local_basename="$(basename "$file")"
    case "$local_basename" in
      _template.md|_example-*) continue ;;
    esac

    # Reset section vars
    _what="" _peer_spec_review="" _peer_code_review="" _verify=""

    entry="$(parse_change_file "$file")"

    if [ "$changes_first" = true ]; then
      changes_first=false
    else
      changes_js+=","
    fi
    changes_js+="\"$(escape_str "$entry")\""
  done
done
changes_js+="]"

# Write the data block to a temp file for safe insertion
tmp="$(mktemp)"
data_tmp="$(mktemp)"
trap 'rm -f "$tmp" "$data_tmp"' EXIT

cat > "$data_tmp" <<DATAEOF
      $MARKER_START
      const EMBEDDED_DEVLOG = $devlog_js;
      const EMBEDDED_FLOWLOG = $flowlog_js;
      const EMBEDDED_CHANGES = $changes_js;
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

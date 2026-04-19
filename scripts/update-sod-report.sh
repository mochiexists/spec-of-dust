#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$ROOT_DIR/.spec/sod-report.md"
README_FILE="$ROOT_DIR/README.md"
VERSION_FILE="$ROOT_DIR/VERSION"
SUMMARY_START="<!-- sod-summary:start -->"
SUMMARY_END="<!-- sod-summary:end -->"

# Pick a UTF-8 locale for wc -m so character counts are Unicode code-points,
# not bytes. Without this, macOS (UTF-8 default) and Linux CI (often C/POSIX)
# disagree on multibyte-character counts and --check fails on CI.
#
# System locale name spellings vary: macOS has "en_US.UTF-8", Ubuntu has
# "C.utf8". We normalize both the candidate list and the system listing
# (lowercase + strip hyphens) before comparing, then use the exact system
# spelling as the locale name so LC_ALL assignments work as reported by
# `locale -a`. `SOD_LOCALE_LIST_CMD` env var can override `locale -a` for
# tests (default: the real `locale -a`).
pick_utf8_locale() {
  local available candidate candidate_norm avail avail_norm
  local locale_cmd="${SOD_LOCALE_LIST_CMD:-locale -a}"
  available="$($locale_cmd 2>/dev/null || true)"

  for candidate in C.UTF-8 en_US.UTF-8; do
    candidate_norm="$(printf '%s' "$candidate" | tr 'A-Z' 'a-z' | tr -d '-')"
    while IFS= read -r avail; do
      [ -n "$avail" ] || continue
      avail_norm="$(printf '%s' "$avail" | tr 'A-Z' 'a-z' | tr -d '-')"
      if [ "$candidate_norm" = "$avail_norm" ]; then
        printf '%s' "$avail"
        return 0
      fi
    done <<< "$available"
  done
  echo "Error: no UTF-8 locale available (tried C.UTF-8, en_US.UTF-8, en_US.utf8). Character counts would be unreliable." >&2
  return 1
}

UTF8_LOCALE="$(pick_utf8_locale)"

cleanup() {
  rm -f "${FILE_LIST:-}" "${ROWS_FILE:-}" "${REPORT_TMP:-}" "${SUMMARY_TMP:-}" "${README_TMP:-}"
  if [ "${TEMP_COUNT_FILES+x}" = x ] && [ "${#TEMP_COUNT_FILES[@]}" -gt 0 ]; then
    rm -f "${TEMP_COUNT_FILES[@]}"
  fi
}
trap cleanup EXIT

FILE_LIST="$(mktemp)"
ROWS_FILE="$(mktemp)"
REPORT_TMP="$(mktemp)"
SUMMARY_TMP="$(mktemp)"
README_TMP="$(mktemp)"

list_repo_files() {
  if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$ROOT_DIR" ls-files
  else
    (
      cd "$ROOT_DIR"
      find . -type f ! -path './.git/*' ! -path './.spec/changes/_example-*' | sed 's#^\./##'
    )
  fi
}

is_text_file() {
  local rel="$1"
  local path="$ROOT_DIR/$rel"

  [ -f "$path" ] || return 1

  if [ ! -s "$path" ]; then
    return 0
  fi

  LC_ALL=C grep -Iq . "$path"
}

count_value() {
  local mode="$1"
  local path="$2"

  # -m (character count) is locale-sensitive; force a UTF-8 locale so the
  # result is Unicode code-points on both macOS and Linux. -l and -w are
  # wrapped too for consistency.
  LC_ALL="$UTF8_LOCALE" wc "$mode" < "$path" | tr -d '[:space:]'
}

normalized_count_path() {
  local rel="$1"
  local path="$ROOT_DIR/$rel"
  local tmp

  if [ "$rel" != "$README_FILE_BASENAME" ]; then
    printf '%s\n' "$path"
    return 0
  fi

  tmp="$(mktemp)"
  awk -v start="$SUMMARY_START" -v end="$SUMMARY_END" '
    $0 == start { in_block = 1; next }
    $0 == end { in_block = 0; next }
    !in_block { print }
  ' "$path" > "$tmp"
  TEMP_COUNT_FILES+=("$tmp")
  printf '%s\n' "$tmp"
}

build_metrics() {
  local rel path count_path lines words chars tokens display

  total_files=0
  total_lines=0
  total_words=0
  total_chars=0
  total_tokens=0
  TEMP_COUNT_FILES=()

  : > "$ROWS_FILE"
  list_repo_files | LC_ALL=C sort > "$FILE_LIST"

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    [ "$rel" = ".spec/sod-report.md" ] && continue

    path="$ROOT_DIR/$rel"
    [ -f "$path" ] || continue
    is_text_file "$rel" || continue

    count_path="$(normalized_count_path "$rel")"
    lines=$(count_value -l "$count_path")
    words=$(count_value -w "$count_path")
    chars=$(count_value -m "$count_path")
    tokens=$(( (chars + 3) / 4 ))
    display="${rel//|/\\|}"

    printf '| `%s` | %s | %s | %s | %s |\n' \
      "$display" "$lines" "$words" "$chars" "$tokens" >> "$ROWS_FILE"

    total_files=$((total_files + 1))
    total_lines=$((total_lines + lines))
    total_words=$((total_words + words))
    total_chars=$((total_chars + chars))
    total_tokens=$((total_tokens + tokens))
  done < "$FILE_LIST"
}

count_tokens_for() {
  local file="$ROOT_DIR/$1"
  [ -f "$file" ] || { echo 0; return; }
  local chars
  chars=$(count_value -m "$file")
  echo $(( (chars + 3) / 4 ))
}

build_context_metrics() {
  # Bootstrap: framework cost (FLOW.md + b-startup.md)
  local flow_tokens bstartup_tokens
  flow_tokens=$(count_tokens_for ".spec/FLOW.md")
  bstartup_tokens=$(count_tokens_for ".spec/b-startup.md")
  bootstrap_tokens=$((flow_tokens + bstartup_tokens))

  # Operational: bootstrap + project files
  local agents_tokens claude_tokens codex_tokens change_tokens=0
  agents_tokens=$(count_tokens_for "AGENTS.md")
  claude_tokens=$(count_tokens_for "CLAUDE.md")
  codex_tokens=$(count_tokens_for "CODEX.md")

  # Find active change file — prefer in-progress (spec|build|verify) over done
  local active_change=""
  if [ -d "$ROOT_DIR/.spec/changes" ]; then
    for f in "$ROOT_DIR/.spec/changes"/*.md; do
      [ -f "$f" ] || continue
      local bn
      bn="$(basename "$f")"
      case "$bn" in _template.md|_example-*) continue ;; esac
      local st
      st="$(awk 'index($0,"status:") == 1 { sub("^status:[[:space:]]*",""); print; exit }' "$f")"
      case "$st" in
        spec|build|verify) active_change="$f"; break ;;
        done) [ -z "$active_change" ] && active_change="$f" ;;
      esac
    done
  fi
  if [ -n "$active_change" ]; then
    local ct
    ct=$(count_value -m "$active_change")
    change_tokens=$(( (ct + 3) / 4 ))
  fi

  operational_tokens=$((bootstrap_tokens + agents_tokens + claude_tokens + codex_tokens + change_tokens))
}

build_report() {
  local version
  version="$(cat "$VERSION_FILE")"

  cat > "$REPORT_TMP" <<EOF
# sod report

- Version: \`$version\`
- Scope: Git-tracked text files when Git metadata is available; fallback to repo file scan otherwise
- Token estimate: \`ceil(characters / 4)\`
- Total files: \`$total_files\`
- Total lines: \`$total_lines\`
- Total words: \`$total_words\`
- Total characters: \`$total_chars\`
- Total estimated tokens: \`$total_tokens\`
- bootstrap sod: \`$bootstrap_tokens / 3000 target\`
- operational sod: \`$operational_tokens / 5000 target\`

| File | Lines | Words | Characters | Est. tokens |
| --- | ---: | ---: | ---: | ---: |
EOF

  cat "$ROWS_FILE" >> "$REPORT_TMP"
}

build_summary() {
  local version
  version="$(cat "$VERSION_FILE")"

  cat > "$SUMMARY_TMP" <<EOF
<!-- sod-summary:start -->
## sod

- Version: \`$version\`
- Files: \`$total_files\`
- Lines: \`$total_lines\`
- Words: \`$total_words\`
- Characters: \`$total_chars\`
- Est. tokens: \`$total_tokens\`
- bootstrap sod: \`$bootstrap_tokens / 3000 target\`
- operational sod: \`$operational_tokens / 5000 target\`

See \`.spec/sod-report.md\` for the full per-file breakdown.
<!-- sod-summary:end -->
EOF
}

build_readme() {
  awk -v start="$SUMMARY_START" -v end="$SUMMARY_END" -v summary_file="$SUMMARY_TMP" '
    BEGIN {
      while ((getline line < summary_file) > 0) {
        summary = summary line ORS
      }
      close(summary_file)
    }
    $0 == start {
      printf "%s", summary
      in_block = 1
      next
    }
    $0 == end {
      in_block = 0
      next
    }
    !in_block {
      print
    }
  ' "$README_FILE" > "$README_TMP"
}

ensure_readme_markers() {
  if ! grep -q "^$SUMMARY_START$" "$README_FILE"; then
    echo "README.md is missing $SUMMARY_START" >&2
    exit 1
  fi

  if ! grep -q "^$SUMMARY_END$" "$README_FILE"; then
    echo "README.md is missing $SUMMARY_END" >&2
    exit 1
  fi
}

write_outputs() {
  mkdir -p "$ROOT_DIR/.spec"

  if ! cmp -s "$REPORT_TMP" "$REPORT_FILE" 2>/dev/null; then
    cp "$REPORT_TMP" "$REPORT_FILE"
  fi

  if ! cmp -s "$README_TMP" "$README_FILE" 2>/dev/null; then
    cp "$README_TMP" "$README_FILE"
  fi
}

DIFF_MAX_LINES=200

emit_bounded_diff() {
  local label="$1" expected="$2" actual="$3"
  local diff_file line_count
  diff_file="$(mktemp)"
  # Write full diff to a file first; avoids SIGPIPE/141 under `set -o pipefail`
  # when we later truncate via head.
  diff -u --label "$label (committed)" --label "$label (generated)" "$actual" "$expected" >"$diff_file" 2>/dev/null || true
  if [ ! -s "$diff_file" ]; then
    rm -f "$diff_file"
    return 0
  fi
  line_count="$(wc -l < "$diff_file" | tr -d '[:space:]')"
  if [ "$line_count" -gt "$DIFF_MAX_LINES" ]; then
    head -n "$DIFF_MAX_LINES" "$diff_file" >&2
    echo "[diff truncated at ${DIFF_MAX_LINES} lines — run \`bash scripts/update-sod-report.sh\` to see the full generated output]" >&2
  else
    cat "$diff_file" >&2
  fi
  echo "" >&2
  rm -f "$diff_file"
}

check_outputs() {
  local report_ok=0 readme_ok=0
  cmp -s "$REPORT_TMP" "$REPORT_FILE" && report_ok=1
  cmp -s "$README_TMP" "$README_FILE" && readme_ok=1

  if [ "$report_ok" -eq 1 ] && [ "$readme_ok" -eq 1 ]; then
    return 0
  fi

  echo "sod outputs are stale. Run \`bash scripts/update-sod-report.sh\` to regenerate." >&2
  echo "" >&2
  [ "$report_ok" -eq 0 ] && emit_bounded_diff ".spec/sod-report.md" "$REPORT_TMP" "$REPORT_FILE"
  [ "$readme_ok" -eq 0 ] && emit_bounded_diff "README.md (summary block)" "$README_TMP" "$README_FILE"
  return 1
}

main() {
  local mode="${1:-write}"
  README_FILE_BASENAME="${README_FILE#$ROOT_DIR/}"

  [ -f "$VERSION_FILE" ] || {
    echo "Missing VERSION file" >&2
    exit 1
  }

  ensure_readme_markers
  build_metrics
  build_context_metrics
  build_report
  build_summary
  build_readme

  case "$mode" in
    --check)
      check_outputs
      ;;
    --stdout-report)
      cat "$REPORT_TMP"
      ;;
    --stdout-summary)
      cat "$SUMMARY_TMP"
      ;;
    write)
      write_outputs
      ;;
    *)
      echo "Usage: $0 [--check|--stdout-report|--stdout-summary]" >&2
      exit 1
      ;;
  esac
}

# Only run main when invoked directly (not when sourced by tests)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  main "${1:-write}"
fi

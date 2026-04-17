#!/usr/bin/env bash

SPEC_DIR=".spec/changes"
DEVLOG_FILE=".spec/devlog.jsonl"
SOD_REPORT_FILE=".spec/sod-report.md"
SOD_SCRIPT="scripts/update-sod-report.sh"
README_FILE="README.md"
EXEMPT_PATTERNS='^\.spec/|^AGENTS\.md$|^CLAUDE\.md$|^README|^\.git|^\.github/|package\.json$|package-lock\.json$|\.lock$'
MAX_SKIP_LINES=20

is_reserved_change_file() {
  local name

  name="$(basename "$1")"
  [ "$name" = "_template.md" ] || [[ "$name" == _example-* ]]
}

get_staged_files() {
  git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true
}

list_dirty_files() {
  {
    git diff --name-only 2>/dev/null || true
    git diff --cached --name-only 2>/dev/null || true
    git ls-files --others --exclude-standard 2>/dev/null || true
  } | awk 'NF && !seen[$0]++'
}

is_text_file_path() {
  local path="$1"

  [ -f "$path" ] || return 1

  if [ ! -s "$path" ]; then
    return 0
  fi

  LC_ALL=C grep -Iq . "$path"
}

has_code_changes() {
  local file

  while IFS= read -r file; do
    if ! printf '%s\n' "$file" | grep -Eq "$EXEMPT_PATTERNS"; then
      return 0
    fi
  done < <(get_staged_files)

  return 1
}

extract_meta_value() {
  local file="$1"
  local key="$2"

  awk -v key="$key" '
    index($0, key ":") == 1 {
      sub("^" key ":[[:space:]]*", "", $0)
      print $0
      exit
    }
  ' "$file"
}

has_active_standard_change() {
  local file status

  [ -d "$SPEC_DIR" ] || return 1

  for file in "$SPEC_DIR"/*.md; do
    [ -f "$file" ] || continue
    is_reserved_change_file "$file" && continue

    status=$(extract_meta_value "$file" "status")

    case "$status" in
      build|verify|done) return 0 ;;
    esac
  done

  return 1
}

collect_dirty_done_changes() {
  local file status

  [ -d "$SPEC_DIR" ] || return

  while IFS= read -r file; do
    [ -n "$file" ] || continue

    case "$file" in
      "$SPEC_DIR"/*.md) ;;
      *) continue ;;
    esac

    [ -f "$file" ] || continue
    is_reserved_change_file "$file" && continue

    status=$(extract_meta_value "$file" "status")
    [ "$status" = "done" ] || continue

    printf '%s\n' "$file"
  done < <(list_dirty_files)
}

is_allowed_done_closeout_file() {
  local done_change="$1"
  local file="$2"

  case "$file" in
    "$done_change"|".spec/flowlog.jsonl"|".spec/sod-report.md"|"README.md"|"docs/dust.html")
      return 0
      ;;
  esac

  return 1
}

enforce_done_closeout_gate() {
  local file done_change
  local dirty_done_changes=()
  local extra_dirty_files=()

  while IFS= read -r file; do
    [ -n "$file" ] && dirty_done_changes+=("$file")
  done < <(collect_dirty_done_changes)

  if [ "${#dirty_done_changes[@]}" -eq 0 ]; then
    return 0
  fi

  if [ "${#dirty_done_changes[@]}" -gt 1 ]; then
    echo ""
    echo "⚠️  Multiple completed changes are still uncommitted:"
    echo ""
    for file in "${dirty_done_changes[@]}"; do
      echo "   $file"
    done
    echo ""
    echo "Commit one completed change at a time before continuing more work."
    echo "If you truly need batching, handle it as an explicit workflow exception."
    echo ""
    return 1
  fi

  done_change="${dirty_done_changes[0]}"

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! is_allowed_done_closeout_file "$done_change" "$file"; then
      extra_dirty_files+=("$file")
    fi
  done < <(list_dirty_files)

  if [ "${#extra_dirty_files[@]}" -gt 0 ]; then
    echo ""
    echo "⚠️  Completed change must be committed before more work proceeds:"
    echo ""
    echo "   $done_change"
    echo ""
    echo "Dirty paths beyond the allowed closeout artifacts were found:"
    echo ""
    for file in "${extra_dirty_files[@]}"; do
      echo "   $file"
    done
    echo ""
    echo "Commit the completed change first, or archive/merge it, before stacking more work."
    echo ""
    return 1
  fi

  return 0
}

collect_scope_patterns() {
  local file status files_field

  [ -d "$SPEC_DIR" ] || return

  for file in "$SPEC_DIR"/*.md; do
    [ -f "$file" ] || continue
    is_reserved_change_file "$file" && continue

    status=$(extract_meta_value "$file" "status")
    case "$status" in
      build|verify|done) ;;
      *) continue ;;
    esac

    files_field=$(extract_meta_value "$file" "files")
    [ -n "$files_field" ] || continue

    # Split comma-separated patterns, trim whitespace
    local IFS=','
    for pattern in $files_field; do
      pattern="$(printf '%s' "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
      [ -n "$pattern" ] && printf '%s\n' "$pattern"
    done
  done
}

file_matches_scope() {
  local file="$1"
  local pattern

  while IFS= read -r pattern; do
    [ -n "$pattern" ] || continue

    # If pattern has no wildcard, exact match
    if [[ "$pattern" != *'*'* ]]; then
      [ "$file" = "$pattern" ] && return 0
      continue
    fi

    # For glob patterns: split into directory prefix and filename glob
    # e.g. "scripts/*.sh" -> dir="scripts", glob="*.sh"
    local dir="${pattern%/*}"
    local glob="${pattern##*/}"
    local file_dir="${file%/*}"
    local file_name="${file##*/}"

    # Directory must match exactly, filename matches the glob
    if [ "$file_dir" = "$dir" ] && [[ "$file_name" == $glob ]]; then
      return 0
    fi
  done

  return 1
}

has_any_scope_defined() {
  local patterns
  patterns="$(collect_scope_patterns)"
  [ -n "$patterns" ]
}

enforce_scope_gate() {
  local patterns file unscoped_files=()

  # If no active change defines files:, fall back to current behavior
  has_any_scope_defined || return 0

  patterns="$(collect_scope_patterns)"

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if ! printf '%s\n' "$patterns" | file_matches_scope "$file"; then
      unscoped_files+=("$file")
    fi
  done < <(list_non_exempt_staged_files)

  if [ "${#unscoped_files[@]}" -gt 0 ]; then
    echo ""
    echo "⚠️  Staged files not listed in any active change's files: scope:"
    echo ""
    for f in "${unscoped_files[@]}"; do
      echo "   $f"
    done
    echo ""
    echo "Either add these paths to the active change's files: field,"
    echo "or create a new change file for this work."
    echo ""
    return 1
  fi

  return 0
}

list_non_exempt_staged_files() {
  local file

  while IFS= read -r file; do
    if ! printf '%s\n' "$file" | grep -Eq "$EXEMPT_PATTERNS"; then
      printf '%s\n' "$file"
    fi
  done < <(get_staged_files)
}

list_skip_target_files() {
  local file

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    [ "$file" = "$DEVLOG_FILE" ] && continue
    printf '%s\n' "$file"
  done < <(get_staged_files)
}

devlog_is_staged() {
  local file

  while IFS= read -r file; do
    [ "$file" = "$DEVLOG_FILE" ] && return 0
  done < <(get_staged_files)

  return 1
}

last_devlog_line() {
  awk 'NF { line = $0 } END { print line }' "$DEVLOG_FILE"
}

valid_skip_devlog_entry() {
  local line="$1"

  [ -n "$line" ] || return 1

  printf '%s\n' "$line" | grep -Eq '"event"[[:space:]]*:[[:space:]]*"skip-no-verify"' &&
    printf '%s\n' "$line" | grep -Eq '"kind"[[:space:]]*:[[:space:]]*"(typo|version-bump|comment|config-tweak|one-line-fix)"' &&
    printf '%s\n' "$line" | grep -Eq '"summary"[[:space:]]*:[[:space:]]*"[^"]+' &&
    printf '%s\n' "$line" | grep -Eq '"reason"[[:space:]]*:[[:space:]]*"[^"]+' &&
    printf '%s\n' "$line" | grep -Eq '"files"[[:space:]]*:[[:space:]]*\[[^]]+\]' &&
    printf '%s\n' "$line" | grep -Eq '"command"[[:space:]]*:[[:space:]]*"git commit --no-verify"'
}

print_skip_requirements() {
  cat <<EOF
Skip commits without an active change file must include a staged \`${DEVLOG_FILE}\` entry.

Append one JSON object per line. Required fields:
- \`event: "skip-no-verify"\`
- \`kind: "typo" | "version-bump" | "comment" | "config-tweak" | "one-line-fix"\`
- \`summary\`
- \`reason\`
- \`files\`
- \`command: "git commit --no-verify"\`

Example:
{"ts":"2026-04-14T22:00:00Z","event":"skip-no-verify","kind":"one-line-fix","summary":"Guard empty slug","reason":"Single-file 4-line fix with obvious behavior","files":["src/slug.ts"],"command":"git commit --no-verify"}

Skip-mode only covers truly trivial code changes:
- exactly one target file modified in place, plus the staged devlog entry
- no new files, deletes, or renames
- no more than ${MAX_SKIP_LINES} total added/deleted lines
EOF
}

validate_skip_devlog() {
  local line

  if ! devlog_is_staged; then
    echo ""
    echo "⚠️  ${DEVLOG_FILE} must be staged for skip commits."
    echo ""
    print_skip_requirements
    echo ""
    return 1
  fi

  if [ ! -f "$DEVLOG_FILE" ]; then
    echo ""
    echo "⚠️  ${DEVLOG_FILE} does not exist."
    echo ""
    return 1
  fi

  line=$(last_devlog_line)

  if ! valid_skip_devlog_entry "$line"; then
    echo ""
    echo "⚠️  ${DEVLOG_FILE} is missing a valid skip-no-verify JSONL entry."
    echo ""
    print_skip_requirements
    echo ""
    return 1
  fi
}

validate_skip_mode() {
  local file target_file added deleted total
  local target_files=()

  validate_skip_devlog || return 1

  while IFS= read -r file; do
    [ -n "$file" ] && target_files+=("$file")
  done < <(list_skip_target_files)

  if [ "${#target_files[@]}" -ne 1 ]; then
    echo ""
    echo "⚠️  Skip commits only allow one target file change plus ${DEVLOG_FILE}."
    echo ""
    print_skip_requirements
    echo ""
    return 1
  fi

  while IFS=$'\t' read -r status file; do
    [ -n "$status" ] || continue

    if [ "$file" = "$DEVLOG_FILE" ]; then
      continue
    fi

    if [ "$status" != "M" ]; then
      echo ""
      echo "⚠️  Skip commits only allow in-place edits to an existing file."
      echo ""
      print_skip_requirements
      echo ""
      return 1
    fi
  done < <(git diff --cached --name-status --diff-filter=ACMR 2>/dev/null || true)

  target_file="${target_files[0]}"
  read -r added deleted _ < <(git diff --cached --numstat -- "$target_file" | head -1)

  if [ "${added:-0}" = "-" ] || [ "${deleted:-0}" = "-" ]; then
    echo ""
    echo "⚠️  Skip commits do not allow binary or non-text changes."
    echo ""
    return 1
  fi

  total=$((added + deleted))

  if [ "$total" -gt "$MAX_SKIP_LINES" ]; then
    echo ""
    echo "⚠️  Skip commit is too large: ${total} changed lines in ${target_file}."
    echo ""
    print_skip_requirements
    echo ""
    return 1
  fi

  return 0
}

is_archive_allowed_extra() {
  case "$1" in
    "$SOD_REPORT_FILE"|"$README_FILE"|"docs/dust.html"|"$DEVLOG_FILE"|".spec/flowlog.jsonl") return 0 ;;
    *) return 1 ;;
  esac
}

is_archive_only_commit() {
  local has_archive_rename=false
  local st file rest

  while IFS=$'\t' read -r st rest; do
    [ -n "$st" ] || continue

    case "$st" in
      R*)
        # Must be a rename from .spec/changes/ to .spec/archive/
        local src="${rest%%	*}"
        local dst="${rest##*	}"
        case "$src" in .spec/changes/*) ;; *) return 1 ;; esac
        case "$dst" in .spec/archive/*) ;; *) return 1 ;; esac
        has_archive_rename=true
        ;;
      M)
        is_archive_allowed_extra "$rest" || return 1
        ;;
      *)
        return 1
        ;;
    esac
  done < <(git diff --cached --name-status 2>/dev/null || true)

  $has_archive_rename
}

enforce_spec_gate() {
  if ! has_code_changes; then
    return 0
  fi

  if is_archive_only_commit; then
    return 0
  fi

  if has_active_standard_change; then
    return 0
  fi

  validate_skip_mode
}

has_sod_relevant_changes() {
  local file

  while IFS= read -r file; do
    [ -n "$file" ] || continue

    case "$file" in
      "$DEVLOG_FILE"|"$SOD_REPORT_FILE"|"docs/dust.html") continue ;;
    esac

    if is_text_file_path "$file"; then
      return 0
    fi
  done < <(get_staged_files)

  return 1
}

skip_mode_applies() {
  validate_skip_mode >/dev/null 2>&1
}

enforce_sod_gate() {
  if skip_mode_applies; then
    return 0
  fi

  if ! has_sod_relevant_changes; then
    return 0
  fi

  if [ ! -x "$SOD_SCRIPT" ]; then
    echo ""
    echo "⚠️  Missing executable sod generator: ${SOD_SCRIPT}"
    echo ""
    return 1
  fi

  if ! "$SOD_SCRIPT" --check >/dev/null 2>&1; then
    echo ""
    echo "⚠️  sod output is stale."
    echo ""
    echo "Run \`${SOD_SCRIPT}\`, then stage \`${SOD_REPORT_FILE}\` and \`${README_FILE}\`."
    echo ""
    return 1
  fi

  if ! git diff --quiet -- "$SOD_REPORT_FILE" "$README_FILE"; then
    echo ""
    echo "⚠️  Refreshed sod files are not fully staged."
    echo ""
    echo "Stage \`${SOD_REPORT_FILE}\` and \`${README_FILE}\` before committing."
    echo ""
    return 1
  fi

  return 0
}

enforce_commit_policies() {
  enforce_spec_gate || return 1
  enforce_done_closeout_gate || return 1
  enforce_scope_gate || return 1
  enforce_sod_gate || return 1
}

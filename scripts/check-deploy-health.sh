#!/usr/bin/env bash
# scripts/check-deploy-health.sh
#
# Report CI health for the current branch's upstream. Exit codes:
#   0 = all green (latest completed run per workflow succeeded)
#   1 = at least one workflow's latest completed run failed (takes precedence)
#   2 = no completed runs yet; runs in progress
#   3 = environment issue: gh missing/unauthenticated, no upstream, no runs, network error

set -euo pipefail

# --- Environment checks (exit 3 on any) ---

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh CLI not installed." >&2
  exit 3
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Error: gh CLI is not authenticated. Run 'gh auth login'." >&2
  exit 3
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository." >&2
  exit 3
fi

# Resolve upstream branch name (just the branch, not the remote)
upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
if [ -z "$upstream" ]; then
  echo "Error: current branch has no upstream configured." >&2
  exit 3
fi

# upstream is like "origin/main" — split out the branch portion
branch="${upstream#*/}"

if [ -z "$branch" ]; then
  echo "Error: could not extract branch name from upstream '$upstream'." >&2
  exit 3
fi

# Current HEAD sha — we scope runs to this specific commit so an older green
# run on the same branch can't mask a failing fresh push.
head_sha="$(git rev-parse HEAD 2>/dev/null || true)"
if [ -z "$head_sha" ]; then
  echo "Error: could not resolve HEAD sha." >&2
  exit 3
fi

# --- Query runs ---

# Fetch recent runs for this branch. 30 gives a cushion to find runs matching HEAD.
runs_json="$(gh run list --branch "$branch" --limit 30 \
  --json databaseId,name,status,conclusion,workflowName,url,headSha 2>&1)" || {
  echo "Error: gh run list failed. Network or permissions issue." >&2
  exit 3
}

if [ -z "$runs_json" ] || [ "$runs_json" = "[]" ]; then
  echo "No workflow runs found for branch '$branch'." >&2
  exit 3
fi

# --- Parse: scope to HEAD sha, then latest completed per workflow ---

parsed="$(printf '%s\n' "$runs_json" | HEAD_SHA="$head_sha" python3 -c '
import json, os, sys
runs = json.load(sys.stdin)
target_sha = os.environ.get("HEAD_SHA", "")
# Only runs for the current commit
matching = [r for r in runs if (r.get("headSha") or "") == target_sha]
seen_latest_completed = {}
in_progress = []
for r in matching:
    wf = r.get("workflowName") or r.get("name") or "?"
    status = r.get("status") or ""
    conclusion = r.get("conclusion") or ""
    rid = r.get("databaseId") or ""
    url = r.get("url") or ""
    if status == "completed":
        if wf not in seen_latest_completed:
            seen_latest_completed[wf] = (status, conclusion, rid, url)
    else:
        in_progress.append((wf, status, conclusion, rid, url))
for wf, (status, conclusion, rid, url) in seen_latest_completed.items():
    print(f"COMPLETED\t{wf}\t{status}\t{conclusion}\t{rid}\t{url}")
for wf, status, conclusion, rid, url in in_progress:
    print(f"INPROGRESS\t{wf}\t{status}\t{conclusion}\t{rid}\t{url}")
')"

# --- Classify ---

failed_runs=()
in_progress_runs=()
completed_count=0

while IFS=$'\t' read -r kind wf status conclusion rid url; do
  [ -n "$kind" ] || continue
  if [ "$kind" = "COMPLETED" ]; then
    completed_count=$((completed_count + 1))
    # Only "failure" counts as a failure worth drafting a fix for.
    # "timed_out" also signals a real problem, so include it.
    # "cancelled" is NOT a failure — it often means superseded or intentional abort.
    if [ "$conclusion" = "failure" ] || [ "$conclusion" = "timed_out" ]; then
      failed_runs+=("$wf"$'\t'"$rid"$'\t'"$url")
    fi
  elif [ "$kind" = "INPROGRESS" ]; then
    in_progress_runs+=("$wf"$'\t'"$rid"$'\t'"$url")
  fi
done <<< "$parsed"

# --- Report and exit ---

if [ "${#failed_runs[@]}" -gt 0 ]; then
  echo "⚠️  CI failures on branch '$branch':"
  echo ""
  for entry in "${failed_runs[@]}"; do
    IFS=$'\t' read -r wf rid url <<< "$entry"
    # Fetch failed-step details for this run
    failed_step_summary="$(gh run view "$rid" --json jobs 2>/dev/null | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    failed_steps = []
    for job in data.get("jobs", []):
        for step in job.get("steps", []):
            if step.get("conclusion") == "failure":
                failed_steps.append(step.get("name", "?"))
    if len(failed_steps) == 0:
        print("<unknown step>")
    elif len(failed_steps) == 1:
        print(failed_steps[0])
    else:
        # Multiple: name first two
        print(f"<multiple steps: {failed_steps[0]}, {failed_steps[1]}>")
except Exception:
    print("<unknown step>")
' 2>/dev/null || echo "<unknown step>")"
    echo "  workflow:    $wf"
    echo "  run-id:      $rid"
    echo "  failed-step: $failed_step_summary"
    echo "  url:         $url"
    echo ""
  done
  exit 1
fi

if [ "$completed_count" -eq 0 ] && [ "${#in_progress_runs[@]}" -gt 0 ]; then
  echo "CI runs in progress for branch '$branch' (no completed runs yet):"
  for entry in "${in_progress_runs[@]}"; do
    IFS=$'\t' read -r wf rid url <<< "$entry"
    echo "  $wf ($url)"
  done
  exit 2
fi

if [ "$completed_count" -eq 0 ]; then
  echo "No completed or in-progress runs for branch '$branch'." >&2
  exit 3
fi

# Resolve a deploy-confirmation URL (GitHub Actions runs for this branch).
# Use the remote associated with the upstream (the "origin/<branch>" prefix
# from @{upstream}) rather than hardcoding `origin`. Only emit a URL when
# the remote is clearly a GitHub remote; falls back silently otherwise.
upstream_remote="${upstream%%/*}"
remote_url=""
if [ -n "$upstream_remote" ]; then
  remote_url="$(git remote get-url "$upstream_remote" 2>/dev/null || true)"
fi
repo_slug=""
if printf '%s' "$remote_url" | grep -Eq '^(git@github\.com:|https?://github\.com/)'; then
  repo_slug="$(printf '%s' "$remote_url" | sed -E 's#^(git@github\.com:|https?://github\.com/)##; s#\.git$##')"
fi

echo "✓ All $completed_count workflow(s) green on branch '$branch'."
if [ -n "$repo_slug" ]; then
  echo "  deploy:  https://github.com/$repo_slug/actions?query=branch:$branch"
fi
exit 0

status: done
files: .githooks/_spec_gate.sh, .spec/changes/_template.md, tests/test-spec-gate.sh, docs/viewer.html

# Scope-aware commit gate

## What
The current commit gate only checks that an active change file exists in `build|verify|done` status — it doesn't check whether the staged files relate to that change. This lets agents commit unrelated edits that bypass the workflow. We need a lightweight scoping mechanism so the gate can warn or block when staged files don't match the active change's expected scope.

## Acceptance criteria
- [ ] The change file template includes an optional `files:` metadata line — a comma-separated list of paths or simple globs on a single line (e.g. `files: docs/viewer.html, scripts/*.sh`)
- [ ] `.githooks/_spec_gate.sh` reads the `files:` field from each active change file via the existing `extract_meta_value` function and compares staged non-exempt files against the patterns
- [ ] If multiple active change files exist, a staged file passes if it matches any active change's `files:` list
- [ ] If staged non-exempt files include paths not matched by any active change's `files:` patterns, the gate prints the offending paths and exits non-zero
- [ ] The agent can update `files:` at any time during build to add newly discovered files before committing — this forces a scope-awareness checkpoint
- [ ] If `files:` is empty or absent on all active changes, the gate falls back to current behavior (any active change passes)
- [ ] Skip-mode commits are unaffected by this check
- [ ] `tests/test-spec-gate.sh` covers: scope match passes, scope mismatch blocks, empty/absent `files:` falls back, exempt paths pass regardless, and skip mode is unaffected

## Notes
- Syntax: `files:` is a single metadata line, comma-separated. Values are exact paths or shell-style globs where `*` matches within one directory only (not recursive). Example: `files: docs/viewer.html, scripts/*.sh`
- Keep the matching simple — `fnmatch`-style via bash `[[ $path == $pattern ]]`, not regex
- The field is optional so existing repos and minimal specs aren't broken
- This is a guard against agent drift, not a perfect scoping system — if an agent updates `files:` and then commits, it's still following the workflow
- The key insight: forcing the agent to declare files before editing creates a checkpoint where it has to think about scope
- Exempt patterns (`.spec/`, `AGENTS.md`, etc.) remain exempt and don't need to be listed
- When multiple active changes exist: if any change has a `files:` list and a staged file matches, it passes. Only block if no active change's scope covers the file

## Peer spec review
**Codex** (2026-04-16):

1. Blocker: `files:` syntax not defined — multiline YAML won't work with `extract_meta_value`. Need single-line format.
2. Blocker: "the active change file" is singular but multiple can coexist — need selection semantics.
3. Blocker: no test requirement — hook logic without regression tests is fragile.
4. Ambiguous: "simple glob-like patterns" undefined — does `*` match `/`? Are plain paths exact?
5. Risk: "warning and blocks" is muddled — just say blocks with exit non-zero.

-> Addressed: `files:` is now a single comma-separated line. Multiple changes: any match passes, block only if none match. Tests added as acceptance criterion. Glob semantics: `*` matches within directory only, plain paths exact. Gate prints offending paths and exits non-zero.

## Peer code review
**Codex** (2026-04-16):

1. Blocker: `[[ "$file" == $pattern ]]` lets `*` match `/` — `scripts/*.sh` would match `scripts/sub/x.sh`. Weakens the gate.
2. Missing test: multiple active changes case untested.
3. Missing tests: blank `files:` line and exempt path under restrictive scope untested.

-> Addressed: glob matching now splits dir/filename and matches separately. Added tests for multi-scope match, blank `files:` fallback, and exempt paths under scope. All 11 tests pass.

## Verify
- [pass] Template includes optional `files:` field on a single line
- [pass] `_spec_gate.sh` reads `files:` from active changes and compares staged non-exempt files
- [pass] Multiple active changes: a file passes if any change's scope matches (tested)
- [pass] Unscoped files print offending paths and exit non-zero (tested)
- [pass] Agent can update `files:` before committing — this change uses its own `files:` field
- [pass] Empty/absent `files:` falls back to current behavior (tested with both absent and blank)
- [pass] Skip-mode unaffected (tested)
- [pass] Tests cover: match, mismatch, empty, blank, exempt, multi-change, and skip mode (11 tests total)

## Closure
- Challenges: Bash `[[ == ]]` glob matching lets `*` cross directory boundaries — needed to split dir/filename for correct scoping. Initial test used an exempt file, masking the real behavior.
- Learnings: The gate doesn't need to be perfect — forcing agents to declare `files:` before editing is the real checkpoint. The mechanical enforcement is a backstop.
- Outcomes: Commits now require staged files to match an active change's declared scope. 11 regression tests cover all paths.
- Dust: The gate learned to ask what you're here for.

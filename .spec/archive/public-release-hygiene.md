status: done

# Public release hygiene

## What
Prepare `spec-of-dust` for an honest first public Git-backed release by doing the minimum first-release blockers only. Initialize local Git so the repo can use its own history and hooks, make a baseline commit of the current tree, then land the publish-blocker fixes that make the repo self-descriptive and safer to publish.

## Acceptance criteria
- [ ] The repo is initialized as a Git repository locally and the pre-cleanup tree is captured in an initial baseline commit before the release-blocker changes
- [ ] `AGENTS.md` has real project context for `spec-of-dust` itself and `.spec/b-startup.md` becomes a live brief with a real `teams:` value for this repo
- [ ] `CODEX.md` and `CLAUDE.md` each mention the SOD refresh flow, `.gitignore` covers `.DS_Store`, `docs/index.html` uses a Pages-safe repository link, `.spec/devlog.jsonl` contains at least one valid example entry, and `.githooks/prepare-commit-msg` is executable in Git
- [ ] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end

## Notes
- Ordering matters:
  1. initialize Git first
  2. make one baseline commit of the current tree
  3. apply the first-release blocker fixes
- Keep the existing repo shape intact; this is release prep, not a workflow redesign
- Follow-up hygiene work will be handled in a second change after this one is done
- The baseline commit exposed one extra blocker worth fixing now: `prepare-commit-msg` must be executable or the skip gate is not actually enforced

## Peer spec review
Summary for review: prepare the repo for a first public release by initializing Git, making a baseline commit, and fixing the core publish blockers only: AGENTS context, live startup brief, SOD mentions, `.DS_Store`, a Pages-safe docs link, and an example devlog entry.

Claude review:

- the original umbrella scope was too broad and risked stalling on unrelated hygiene work
- Git init ordering needed to be concrete
- a few acceptance criteria were too soft to verify cleanly

Valid feedback addressed:

- scope is narrowed to Git bootstrap plus first-release blockers only
- the baseline commit requirement is explicit
- second-tier hygiene and CI/polish are deferred to a follow-up change

## Peer code review
Claude review:

- all acceptance criteria are addressed in the diff
- no blockers remained after the final link and devlog cleanup
- advisory notes: the default repo URL in `docs/index.html` should be confirmed before public publish, and the synthetic devlog timestamp is acceptable if treated as an example entry

Resolution:

- kept the default repo URL aligned with the intended publish path for this repo, while still auto-deriving a better URL on GitHub Pages
- kept the synthetic devlog entry clearly illustrative rather than pretending to reflect a real skip event

## Verify
- [pass] The repo is initialized as a Git repository locally and the pre-cleanup tree is captured in an initial baseline commit before the release-blocker changes
  `git init` is complete and the baseline tree was recorded in commit `8759543` with message `chore: baseline import`.
- [pass] `AGENTS.md` has real project context for `spec-of-dust` itself and `.spec/b-startup.md` becomes a live brief with a real `teams:` value for this repo
  `AGENTS.md` now describes the repo as the product, and `.spec/b-startup.md` is a short live brief with `teams: some`.
- [pass] `CODEX.md` and `CLAUDE.md` each mention the SOD refresh flow, `.gitignore` covers `.DS_Store`, `docs/index.html` uses a Pages-safe repository link, `.spec/devlog.jsonl` contains at least one valid example entry, and `.githooks/prepare-commit-msg` is executable in Git
  Both agent docs now mention `bash scripts/update-sod-report.sh`, `.DS_Store` is ignored, the docs page uses a direct repo URL plus GitHub-Pages-aware override logic, the devlog contains a valid illustrative JSONL line, and `prepare-commit-msg` is tracked as `100755`.
- [pass] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end
  This change file now contains the full spec/build/verify record and the SOD outputs are refreshed after these final notes.


## Closure
- Challenges: Git bootstrap changed the SOD scope immediately, and the hook executable bit turned out to be a real release blocker.
- Learnings: For this repo, a Git-backed baseline commit is worth doing early because it exposes workflow truth fast.
- Outcomes: The repo now has real Git history, live startup/context docs, SOD-aware agent notes, a safer Pages entrypoint, a valid example devlog line, and an actually executable skip gate.
- Dust: The framework had to become a repo before it could review itself honestly.

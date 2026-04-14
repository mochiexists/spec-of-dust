status: build

# Public release hygiene

## What
Prepare `spec-of-dust` for an honest first public Git-backed release by doing the minimum first-release blockers only. Initialize local Git so the repo can use its own history and hooks, make a baseline commit of the current tree, then land the publish-blocker fixes that make the repo self-descriptive and safer to publish.

## Acceptance criteria
- [ ] The repo is initialized as a Git repository locally and the pre-cleanup tree is captured in an initial baseline commit before the release-blocker changes
- [ ] `AGENTS.md` has real project context for `spec-of-dust` itself and `.spec/b-startup.md` becomes a live brief with a real `teams:` value for this repo
- [ ] `CODEX.md` and `CLAUDE.md` each mention the SOD refresh flow, `.gitignore` covers `.DS_Store`, `docs/index.html` uses a Pages-safe repository link, and `.spec/devlog.jsonl` contains at least one valid example entry
- [ ] The change records peer reviews, verification notes, and closure in the normal `spec-of-dust` flow, and the SOD outputs are refreshed at the end

## Notes
- Ordering matters:
  1. initialize Git first
  2. make one baseline commit of the current tree
  3. apply the first-release blocker fixes
- Keep the existing repo shape intact; this is release prep, not a workflow redesign
- Follow-up hygiene work will be handled in a second change after this one is done

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
<!-- Filled by the other model after build completes. -->

## Verify
<!-- During verify: copy acceptance criteria here, mark pass/fail with notes. -->


## Closure
- Challenges:
- Learnings:
- Outcomes:
- Dust:

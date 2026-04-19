status: build
files: .githooks/pre-push, .spec/FLOW.md, CLAUDE.md, AGENTS.md, CODEX.md, setup.sh, tests/test-spec-gate.sh, docs/dust.html

# Guard external publishing actions so sod can't be bypassed silently

## What
On 2026-04-19 the v0.2.0 public release shipped (repo created, tag pushed, Pages enabled, GitHub release published) without an active sod change file. The miss happened because sod's gates are all commit-centric: nothing fires on `git push`, `gh` CLI calls, or external API writes. The external-target rule in `FLOW.md` is advisory-only. Under momentum, the AI drifted past it.

This change adds layered protection: a mechanical `pre-push` hook that catches the git-push subset, and stronger cultural rules in FLOW.md / CLAUDE.md / AGENTS.md for the actions that can't be gated (gh API calls, curl writes). Retrofitting v0.2.0 itself is intentionally out-of-scope — this change IS the record of what happened, captured going forward rather than backward.

## Acceptance criteria
- [ ] New `.githooks/pre-push` hook fires on every `git push`. The hook detects **publishing-pattern** pushes defined narrowly as: (a) the push includes at least one tag ref (`refs/tags/*`), OR (b) the push creates a new remote branch (pushing to a ref that doesn't exist on the remote). Regular commit pushes to an existing tracked branch do NOT trigger the warning.
- [ ] When a publishing-pattern push is detected AND no change file with status `spec|build|verify` exists in `.spec/changes/` (matching the same rule used by `has_active_standard_change` in `_spec_gate.sh` but extended to include `spec`), the hook emits a warning to stderr:
  `⚠️  Publishing push with no active change file. FLOW.md requires a spec naming the external target. Set SOD_PUBLISH_ACK=1 to bypass intentionally.`
- [ ] Warning-only, never blocking. No interactive prompts (pre-push runs in non-TTY contexts). The hook exits 0 in all cases. The `SOD_PUBLISH_ACK=1` env var suppresses the warning entirely for clean CI / scripted flows.
- [ ] `setup.sh` needs no changes — `core.hooksPath .githooks` is already set; shipping the executable file is sufficient
- [ ] `FLOW.md` gains a new subsection under "Gates" titled "External actions (not mechanically gated)" naming the commands explicitly: `gh repo create`, `gh release create`, `gh api` (POST/PUT/DELETE), `curl` to deploy/publish, or any command that writes to an external system. States clearly: "Before running these, you MUST have an active change file naming the target. This rule is advisory but load-bearing; the pre-push hook only covers the git-push subset."
- [ ] Matching load-bearing rule added near the top of `CLAUDE.md`, `AGENTS.md`, AND `CODEX.md` (all three agent surfaces, symmetric): "Before invoking any external-writing command (gh/curl/ssh/etc.), check for an active change. If none, stop and create one. No mechanical gate covers API calls."
- [ ] Test suite adds three cases exercising the hook against a temp repo:
  1. Tag push with no active change → warning fires
  2. First push to empty remote branch with no active change → warning fires
  3. `SOD_PUBLISH_ACK=1` set → no warning even on publishing-pattern push
  (Regular commit push to existing branch is implicit — the test file will still pass because no warning fires.)
- [ ] This change file's Closure captures what went wrong with v0.2.0 (shipped outside sod), the learnings, and a dust line for the miss. This change file is the forward-looking record — no retrofit of v0.2.0.

## Notes
- Hook covers git-push only. API calls (`gh api`, `curl`) can't be gated mechanically — those are purely cultural rules in the docs the AI reads. That asymmetry is why CLAUDE.md / AGENTS.md / CODEX.md get symmetric rules.
- Intentionally warning-only, not blocking. First pass: observe. If it's ignored, a future change can tighten to block.
- "Active change" for the hook is narrower than the commit gate's `build|verify|done` — it includes `spec` too, because if the AI has *started writing a spec* for a publishing action, the push should be allowed through. Only total absence is suspicious.
- Keep the hook fast. No sod-report checks — that's already commit-gate territory. Just scan `.spec/changes/*.md` for an active status.
- `pre-push` gets ref info on stdin: `<local-ref> <local-sha> <remote-ref> <remote-sha>` per line. Remote-sha of `0000...` means "creating a new remote branch/tag" (publishing pattern).

## Peer spec review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: "active change" inconsistent — commit gate uses `build|verify|done`; spec said both "non-done" and "done counts as in motion." → Fixed: hook defines active as `spec|build|verify` explicitly, with `spec` included since a started publishing spec should unblock.
2. Blocker: trigger overbroad — would catch every post-closeout push. → Fixed: publishing-pattern narrowed to (a) push includes a tag ref, OR (b) push creates a new remote branch. Regular commits to existing branch: no warning.
3. Risk: CODEX.md not updated. → Fixed: added to files list and ACs.
4. Risk: tag-push and new-branch test cases missing. → Fixed: three explicit test cases in AC.
5. Ambiguous: "warns + prompts" brittle for pre-push. → Fixed: warning-only, no prompts, always exit 0; `SOD_PUBLISH_ACK=1` suppresses.


## Peer code review
**Codex** (2026-04-19, gpt-5.4):

1. Blocker: hook warning text drifted from spec. → Fixed: message now matches AC verbatim. Tests upgraded from `grep -qF` substring to exact-string equality to catch any future drift.
2. Medium: new-remote-ref detection fired on any zero-sha ref including `refs/notes/*` and custom refs, broader than spec. → Fixed: zero-sha case gated to `refs/heads/*`. Added `pre_push_silent_on_non_branch_zero_sha_ref` test covering `refs/notes/commits`.
Advisory: tighten warning tests to full-stderr payload match. → Fixed same pass.


## Verify
- [pass] `.githooks/pre-push` exists, executable, reads stdin, detects tag-ref push and new-remote-branch push as publishing pattern
- [pass] Warning message matches the spec verbatim; 5 pre-push tests assert exact stderr
- [pass] Warning-only (exit 0 in all cases); `SOD_PUBLISH_ACK=1` suppresses; no interactive prompts
- [pass] `setup.sh` unchanged — existing `core.hooksPath .githooks` setup covers the new hook
- [pass] FLOW.md "External actions (not mechanically gated)" subsection added under Gates
- [pass] CLAUDE.md, AGENTS.md, CODEX.md all have the symmetric load-bearing external-actions rule near the top
- [pass] Test cases: tag push + new branch push fire warning, `refs/notes/*` zero-sha does not, `SOD_PUBLISH_ACK=1` silences, active change silences
- [pass] Full test suite: 22 hook tests + 12 workflow tests all green


## Closure
- Challenges: v0.2.0 was published fully outside sod (tag, repo create, Pages enable, release) because commit-centric gates don't fire on push or gh API calls. The framework couldn't catch itself.
- Learnings: cultural rules drift under momentum; mechanical gates are only as broad as the events they listen to; symmetry matters (CLAUDE.md + AGENTS.md + CODEX.md all need the same load-bearing rule since any of the three agents could be driving); exact-string test assertions catch copy drift that substring assertions miss
- Outcomes: pre-push hook covers tag and new-branch pushes; FLOW.md names the external-actions gap explicitly; all three agent surfaces carry the same rule. Future publishing events can still drift in theory but now have multiple nudges to stop first.
- Dust: the framework caught itself breaking its own rules, and wrote new ones.

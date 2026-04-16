status: done

# Widen peer review context

## What
Adjust the peer-review protocol so cross-model reviews do not look only at the change file or diff in isolation. The prompts should tell the reviewing model to use nearby repo context when needed, compare against the active spec, and call out broader issues or architectural critiques if they matter to the change.

## Acceptance criteria
- [ ] `.spec/FLOW.md` updates the pre-build review prompt so the reviewer is asked to assess the spec in repo context, not as an isolated snippet, and uses a concrete heuristic for which extra files to read
- [ ] `.spec/FLOW.md` updates the post-build review prompt so the reviewer is asked to compare the diff against the spec and use nearby codebase context when needed, with the same scoping heuristic
- [ ] The review protocol tells the reviewing model to report broader critiques or errors when they are relevant, while still prioritizing concrete issues with the current change, and makes clear that broader critiques are advisory unless they expose a real blocker for the current change

## Notes
- Keep the prompts concise
- Do not turn review into a whole-repo audit by default
- The goal is better judgment, not more token sprawl
- Good default context heuristic: read the active change file, changed files, and directly referenced or obviously adjacent files only
- Broader critiques should be recorded and considered, but they should not automatically block the gate unless they reveal a real requirement gap, bug, or unsafe design in the current change

## Peer spec review
Summary for review: widen the peer-review prompts so the other model is told to read the current change against nearby repo context and report broader critiques when relevant, without turning every review into a full repo sweep.

Claude review:

- `nearby repo context` needed a concrete scoping heuristic
- the spec needed to say whether broader critiques are advisory or blocking

Valid feedback addressed:

- the acceptance criteria now require an explicit context heuristic
- the notes now say broader critiques are advisory unless they reveal a real blocker in the current change

## Peer code review
Claude review:

- all three acceptance criteria are met
- no bugs or missed requirements in the prompt changes
- one non-blocking note remains: the post-build review still references the spec by path rather than piping it on stdin, so filesystem access is still assumed as before

Resolution:

- kept the existing path-based spec reference because it matches the current local CLI workflow
- noted that this is a pre-existing assumption, not a regression from this change

## Verify
- [pass] `.spec/FLOW.md` updates the pre-build review prompt so the reviewer is asked to assess the spec in repo context, not as an isolated snippet, and uses a concrete heuristic for which extra files to read
  The prompt now scopes extra context to the active change file, directly referenced files, and obviously adjacent files only.
- [pass] `.spec/FLOW.md` updates the post-build review prompt so the reviewer is asked to compare the diff against the spec and use nearby codebase context when needed, with the same scoping heuristic
  The post-build prompt now names the spec, changed files, directly referenced files, and obviously adjacent files as the allowed extra context.
- [pass] The review protocol tells the reviewing model to report broader critiques or errors when they are relevant, while still prioritizing concrete issues with the current change, and makes clear that broader critiques are advisory unless they expose a real blocker for the current change
  Both prompts now say broader critiques are advisory unless they reveal a missed requirement, bug, unsafe design, or contradiction with the spec, and the workflow steps reflect the same rule.

## Closure
- Challenges: The first prompt expansion improved judgment but still split the real policy across prose and prompt text, which made drift more likely.
- Learnings: If a review rule matters, put it in the prompt the reviewing model actually receives, not only in surrounding docs.
- Outcomes: Peer-review prompts now explicitly ask for nearby context, broader critique when relevant, and concrete prioritization against the current change.
- Dust: Good review needs just enough sky around the object.

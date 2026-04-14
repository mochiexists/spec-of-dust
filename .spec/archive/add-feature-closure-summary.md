status: done

# Add feature closure summary

## What
Add a small closure section to the standard change flow so completed features leave behind a concise summary of challenges, learnings, outcomes, and a short `Dust` note. This should stay lightweight, but it should give future agents and humans enough signal to understand what happened and what mattered after the work is done.

## Acceptance criteria
- [ ] The change template includes a dedicated closure section for challenges, learnings, outcomes, and `Dust`, with one-line prompts that distinguish the buckets
- [ ] `.spec/FLOW.md` treats the closure summary as part of standard-change completion before moving a change to `done`, folds notable peer-review and verify takeaways into `Outcomes`, allows a concise `nothing notable` entry when there is no real signal, and keeps `Dust` to a short artistic line under 80 characters
- [ ] The requirement lives in the template and `.spec/FLOW.md`, stays minimal, is framed as future-analysis context rather than a long retrospective, and is demonstrated in `_example-dark-mode.md`

## Notes
- Keep it concise: short bullets or short lines, not a postmortem
- The closure summary should describe what actually happened during delivery, not restate the original spec
- This applies to standard changes, not skip-mode devlog entries
- `Challenges` should capture friction, surprises, or blockers
- `Learnings` should capture reusable lessons or follow-up insight
- `Outcomes` should capture the delivered result or user-facing effect, plus important review or verify signal
- `Dust` should be a short artistic or human note; keep it under 80 characters
- `Nothing notable` is acceptable when the work was straightforward

## Peer spec review
Summary for review: add a lightweight closure-summary requirement to standard change files so completed work records challenges, learnings, and outcomes for future analysis without turning every change into a long retrospective.

Claude review:

- the three buckets needed a one-line distinction or agents would blur them
- the closure shape also needed to mention peer-review and verify takeaways explicitly
- the spec needed to say whether `nothing notable` is allowed
- the enforcement point needed to be explicit: guidance versus completion requirement
- the docs scope needed to be narrowed so implementation would not scatter

Valid feedback addressed:

- the acceptance criteria now require one-line prompts in the template
- the closure summary now folds peer-review and verify takeaways into `Outcomes`
- `.spec/FLOW.md` is the explicit completion gate for standard changes
- `nothing notable` is allowed when there is no real signal
- scope is narrowed to the template, `.spec/FLOW.md`, and the example file

## Peer code review
Claude review:

- no bugs in the final implementation
- the example file now models the finished flow cleanly, including `Dust`
- non-blocking notes: the closure prompt style is still lightweight guidance rather than a hard-enforced schema, and the closure requirement is process-level rather than mechanically gated

Resolution:

- kept the lightweight prompt style on purpose for v1
- kept closure as a completion requirement in the flow rather than adding a new hook gate

## Verify
- [pass] The change template includes a dedicated closure section for challenges, learnings, outcomes, and `Dust`, with one-line prompts that distinguish the buckets
  `_template.md` now includes four explicit closure lines with short prompts, a `nothing notable` allowance, and a concise `Dust` hint.
- [pass] `.spec/FLOW.md` treats the closure summary as part of standard-change completion before moving a change to `done`, folds notable peer-review and verify takeaways into `Outcomes`, allows a concise `nothing notable` entry when there is no real signal, and keeps `Dust` to a short artistic line under 80 characters
  The `done` state and `Rules for the AI` both require the closure summary and describe the expected shape.
- [pass] The requirement lives in the template and `.spec/FLOW.md`, stays minimal, is framed as future-analysis context rather than a long retrospective, and is demonstrated in `_example-dark-mode.md`
  The example file now shows a completed verify plus closure section without adding extra ceremony elsewhere.

## Closure
- Challenges: The first pass only captured delivery notes and missed peer-review plus verify takeaways, so the closure shape had to be widened.
- Learnings: If a closure gate is meant for future analysis, it needs explicit prompts; otherwise agents collapse categories or omit review signal.
- Outcomes: Standard changes now end with a concise closure summary that carries delivery results and key review/verify signal.
- Dust: Small rituals keep the machine human.

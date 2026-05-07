status: verify
files:
  - README.md
  - AGENTS.md
  - CLAUDE.md
  - CODEX.md
  - VERSION
  - .spec/FLOW.md
  - .spec/b-startup.md
  - .spec/changes/_template.md
  - .spec/aod-report.md
  - docs/**
  - scripts/update-aod-report.sh
  - scripts/build-dust.sh
  - scripts/merge-completed-work.sh
  - scripts/archive-done-changes.sh
  - scripts/devlog.sh
  - scripts/flowlog.sh
  - tests/test-spec-gate.sh
  - tests/test-workflow-scripts.sh
  - .githooks/**
  - packs/**

# Rename spec-of-dust to architect-of-dust

## Intent
Reframe the framework from `spec-of-dust` to `architect-of-dust` because the repo's real value is lightweight architecture-first change discipline, not tiny specs. This change renames the public/project language from SoD to AoD, updates the state model and template language to center architecture and sequencing, and leaves a compatibility/migration path so existing downstream repos can adopt the new framing deliberately instead of getting a shallow string-swap.

## Ordering
- Prerequisites: shelve the unfinished `gh-identity-per-repo-check` change so the rename is the only active architectural program in flight.
- Unlocks: downstream AoD adoption, architecture-conformance review improvements, and cleaner repo naming in docs/tooling.
- Sequence notes: fix source docs/scripts first, then regenerate outputs/tests, then rename the repo folder.

## Checks
- [ ] The core workflow language is renamed from SoD to AoD across the framework's primary surfaces: `README.md`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.spec/FLOW.md`, `.spec/b-startup.md`, `.spec/changes/_template.md`, `docs/**`, and generated summaries.
- [ ] The top-level flow in `.spec/FLOW.md` is redesigned around `architect -> build -> verify -> present` (or another explicitly chosen AoD state machine if peer review/user refinement changes the exact labels), with each state defined in terms of architecture-first intent rather than spec-first wording.
- [ ] `.spec/FLOW.md` gains a first-class ordering/dependency concept for multi-change work. At minimum, the framework documents how to express prerequisites/follow-ups/phase order in change files, and the template exposes fields or sections for that ordering.
- [ ] The change template is updated so the front of every change is architecture-led. Replace or reshape `## What` / `## Acceptance criteria` as needed so the template captures: intent, ordering, checks, and any architecture-sensitive sections required by the new flow.
- [ ] The rename is not just textual. AoD docs explicitly explain the conceptual shift: from "write a spec" toward "architect the change, then build, verify, and present it."
- [ ] Existing repo-local terminology that is load-bearing in scripts/tests/hooks is updated coherently: command/help text, warnings, generated docs, and metric labels move from `sod`/`architect-of-dust` to `aod`/`architect-of-dust` only where that improves the framework model. If some implementation names stay as compatibility shims, the choice is documented.
- [ ] The framework documents a downstream migration story: how existing SoD repos should interpret the rename, what is mechanically compatible, and what needs manual adoption.
- [ ] Tests and hooks are updated to the new terminology/state model without weakening workflow protections. Existing guarantees around active change files, closeout, archive flow, and skip logging still hold under AoD language.
- [ ] Generated artifacts (`.spec/aod-report.md`, README summary block, `docs/dust.html`, any other generated outputs) are regenerated and internally consistent after the rename or any deliberate partial compatibility choice.
- [ ] The final docs call out the repo's new identity clearly enough that a new user would understand AoD as architecture-first change discipline, not as a generic spec workflow with a different name.

## Notes
- External target for this change: the `architect-of-dust` framework repo itself. Completion means "implemented and verified in this repo"; downstream repo adoption is documented locally, not performed automatically.
- This is an architecture/signature change for the framework. It should not be treated as a copy edit.
- The rename touches both public framing and internal flow semantics. If peer review concludes that state-machine redesign should split from branding rename, the work may need to divide into a foundational AoD architecture change plus a follow-up naming pass.
- Ordering is part of the problem statement, not a nice-to-have. The new framework should say how phased work is expressed instead of leaving sequencing to prose.
- The `gh-identity-per-repo-check` change is now `status: shelved` so the rename can proceed on a clean conceptual base without pretending the work is complete.
- The framework currently uses `sod` for generated metrics/reporting. AoD may keep `sod` only as an implementation compatibility nickname if the migration cost is not worth immediate churn, but any such exception must be explicit in the docs and in verify notes.
- Expected Git author identity for this change: whatever this repo normally uses. The repo remains `push: never`, so local implementation and verification can finish without publishing.

## Peer architecture review
Attempted bounded `claude -p` pre-build review twice on 2026-05-07; both calls hung until `timeout 30s` with no review text returned. Proceeding under the repo rule for unavailable peer-review tooling: treat this as an environment/tooling issue rather than blocking the change, keep the change scoped, and capture the limitation in verify/closure.


## Peer code review
Attempted bounded post-build `claude -p` review on 2026-05-07 against the staged
diff. The CLI again timed out under `timeout 30s` with no review text returned.
Proceeding under the same tooling-unavailable exception used for the pre-build
review. Scope stayed within the framework surfaces named in `files:`, and the
full hook/workflow suite was run locally.


## Verify
- [pass] Core workflow language is renamed from SoD to AoD across the framework's primary surfaces: `README.md`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, `.spec/FLOW.md`, `.spec/b-startup.md`, `.spec/changes/_template.md`, `docs/**`, and generated summaries.
- [pass] `.spec/FLOW.md` now defines `architect -> build -> verify -> present` and explains the architecture-first intent of each state.
- [pass] `.spec/FLOW.md` now gives ordering a first-class home via `## Ordering`, and the template exposes `Prerequisites`, `Unlocks`, and `Sequence notes`.
- [pass] The change template is architecture-led: `Intent`, `Ordering`, `Checks`, `Peer architecture review`, `Peer code review`, `Verify`, and `Closure`.
- [pass] AoD docs explicitly explain the conceptual shift from spec-writing toward architecture-first change design; `README.md` and `.spec/FLOW.md` both make that distinction.
- [pass] Load-bearing repo-local terminology is updated coherently: hooks, scripts, README summary, `.spec/aod-report.md`, and generated `docs/dust.html` all use AoD-facing wording, while parsers keep compatibility for old `## What`, `## Peer spec review`, `status: done`, and `SOD_PUBLISH_ACK`.
- [pass] The downstream migration story is documented in `README.md`, including conceptual changes, mechanical compatibility, and manual adoption points.
- [pass] Tests and hooks still hold the workflow protections under the AoD state model. Verified by `bash tests/test-spec-gate.sh` and `bash tests/test-workflow-scripts.sh`, both passing fully on 2026-05-07.
- [pass] Generated artifacts are internally consistent after regeneration: `bash scripts/update-aod-report.sh`, `bash scripts/build-dust.sh`, and their `--check` paths are green in the workflow suite.
- [pass] The final docs make the new identity clear to a fresh reader: the repo now presents itself as `architect-of-dust`, an architecture-first workflow, not a generic spec workflow.
- [pass] Shelved work is now represented explicitly with `status: shelved`, and the active-work rules ignore shelved changes so the rename can proceed without pretending the older work is complete.


## Closure
<!-- Filled at present. -->
- Challenges:
- Learnings:
- Outcomes:
- Dust:

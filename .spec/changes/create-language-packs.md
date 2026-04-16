status: done
files: packs/index.json, packs/javascript/v0/README.md, packs/swift/v0/README.md, packs/python/v0/README.md, packs/python-research/v0/README.md, packs/rust/v0/README.md, docs/viewer.html

# Create language packs

## What
Build out the release-pack scaffolds for JavaScript/TypeScript, Swift/iOS, Python, Python (ML/research), and Rust. Each pack provides stack-specific gate suggestions, CI examples, and tool configs that layer on top of the base spec-of-dust workflow. These are source material for future release artifacts — concrete enough to copy into a real project, not just planned scope.

## Acceptance criteria
- [ ] `packs/javascript/v0/` contains: lint config suggestion (ESLint + Prettier), test gate (vitest/jest), type check gate (tsc), CI example (GitHub Actions), and optional Husky transport note
- [ ] `packs/swift/v0/` contains: SwiftLint config suggestion, xcodebuild gate, test gate (swift test or xcodebuild test), CI example
- [ ] `packs/python/v0/` contains: ruff or black+flake8 config suggestion, pytest gate, type check gate (mypy/pyright), CI example
- [ ] `packs/python-research/v0/` contains: everything from python pack plus notebook lint (nbstripout), data pipeline gate suggestions (DVC/data validation), experiment tracking notes (MLflow/W&B), GPU CI considerations
- [ ] `packs/rust/v0/` contains: clippy + rustfmt config, cargo test gate, cargo build gate, CI example
- [ ] `packs/index.json` lists all 5 packs with slug, version, summary, docs path
- [ ] Each pack README is concrete enough to copy — real config snippets, real CI YAML, not just bullet points
- [ ] Each pack follows a consistent structure: summary, local gates, CI example, tooling notes, "suggestions not requirements" disclaimer
- [ ] `packs/index.json` entries include artifact path placeholders consistent with existing format

## Notes
- Keep each pack README self-contained: someone should be able to read one file and set up their project
- Config snippets should be copy-paste ready but clearly marked as suggestions, not requirements
- CI examples should use GitHub Actions (the repo's own CI uses it)
- The python-research pack extends the base python pack — mention the base and add ML-specific concerns
- Don't include actual config files yet (no `.eslintrc`, no `.swiftlint.yml`) — just the README with inline snippets. Actual files can come in v1
- Each pack stays under 100 lines where possible — python-research may exceed this slightly due to ML-specific concerns
- Pick one default tool per gate, list alternatives as notes: ESLint (not ESLint or Biome), ruff (not ruff or black), mypy (not mypy or pyright), swift test via SPM (Xcode app as alternative note)

## Peer spec review
**Codex** (2026-04-17):

1. Blocker: index.json entries need artifact path placeholders.
2. Blocker: tool alternatives (vitest/jest, ruff/black) not mechanically verifiable — pick one default.
3. Blocker: python-research is overstuffed for 100-line limit.
4. Risk: 5 dense packs at once may overbuild the packs surface.
5. Advisory: consistent cross-pack template structure.

-> Addressed: artifact placeholders added, one default per gate, python-research limit relaxed, consistent structure criterion added.

## Peer code review
**Codex** (2026-04-17):

1. Blocker: python-research delegates to base pack instead of being self-contained.
2. Blocker: `|| true` on nbstripout neuters the gate.
3. Advisory: Swift CI missing swiftlint install step.
4. Advisory: JS config labeled `.js` but uses ESM imports — `.mjs` is safer.

-> All four fixed: python-research inlined base gates, `|| true` removed, Swift CI has `brew install`, JS config renamed to `.mjs`.

## Verify
- [pass] JavaScript: ESLint + Prettier lint, vitest test, tsc type check, CI example, Husky note
- [pass] Swift: SwiftLint config, swift build/test with xcodebuild alternative, CI with brew install
- [pass] Python: ruff lint/format, mypy, pytest, CI example
- [pass] Python-research: self-contained with ruff/mypy/pytest inline, plus nbstripout, DVC, experiment tracking, GPU CI
- [pass] Rust: clippy + rustfmt, cargo build/test, CI example
- [pass] index.json lists all 5 packs with artifact placeholders
- [pass] Consistent structure across all packs: summary, local gates, CI, tooling notes, suggestions disclaimer

## Closure
- Challenges: python-research was the hardest to balance — enough ML-specific guidance to be useful without bloating past the line budget.
- Learnings: "Self-contained" means one file is enough. Cross-references between packs save lines but break the copy-paste promise.
- Outcomes: 5 language packs with concrete, copy-paste-ready gate configs and CI examples.
- Dust: Five languages walked into a framework and each found their own gate.

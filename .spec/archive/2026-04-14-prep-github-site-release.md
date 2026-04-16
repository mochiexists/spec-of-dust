status: done

# Prep spec-of-dust for GitHub, site, and releases

## What
Prepare `spec-of-dust` to be published cleanly on GitHub and to support a future docs site and release artifacts. Tighten the repo-facing docs, define a concrete release-pack manifest and source directory, add a minimal static site entrypoint under `docs/`, and add minimal public-project metadata so the project presents a coherent public shape without introducing heavy tooling.

## Acceptance criteria
- [ ] `README.md` describes `spec-of-dust` as a public project and includes sections for release packs and publishing shape
- [ ] A versionable release-pack source structure exists under `packs/` with a checked-in manifest at `packs/index.json`
- [ ] A minimal static site entrypoint exists at `docs/index.html` and points readers at the core docs without adding a framework dependency
- [ ] Public-publishing basics exist as files: `LICENSE` and a minimal `.github/` docs scaffold for releases/pages
- [ ] Startup guidance remains centralized in `.spec/b-startup.md`, with no net new startup-brief requirements added elsewhere

## Notes
- Keep the project zero-dependency
- Prefer documentation, manifests, and skeleton structure over premature automation
- Future remote packs and starter templates should be versionable and release-friendly
- Use JSON for the initial release-pack manifest
- `packs/index.json` should list pack slugs, version placeholders, summaries, and artifact/doc path fields
- Good targets for this pass: release manifest/index, docs site entry page, GitHub docs scaffold, and lightweight publish metadata

## Peer spec review
Summary for review: prepare the repo for public GitHub publishing by adding lightweight release-pack structure, a minimal static docs/site entrypoint, and minimal public-project metadata while keeping the workflow itself zero-dependency and startup docs concise.

Relay prompt:

`Review this spec. What's missing, over-engineered, or ambiguous? Be blunt. Reply in under 200 words. Focus on whether "GitHub/site/release prep" is concrete enough, whether the release-pack idea is underspecified, and whether the acceptance criteria are mechanically verifiable.`

Claude review:

Underspecified:
- "Release-pack" needed a concrete manifest format and source structure
- "Minimal static entrypoint" needed to be a specific file, not an abstract concept
- "GitHub-facing metadata" needed exact deliverables

Valid feedback addressed:
- acceptance criteria now name concrete files and checks
- manifest format narrowed to JSON at `packs/index.json`
- site entrypoint narrowed to `docs/index.html`
- public-publishing basics now explicitly include `LICENSE`
- startup brevity is now measured by centralizing requirements in `.spec/b-startup.md` instead of adding more boot files

## Peer code review
Claude review:

- `README.md` met the acceptance criteria but was too repetitive with `FLOW.md`
- `docs/index.html` needed real links, not decorative file references
- `packs/javascript/v0/README.md` needed at least a skeletal companion file so the pack looked intentionally scaffolded

Valid feedback addressed:

- README now points to `FLOW.md` for exact protocol details instead of repeating most of them
- `docs/README.md` was trimmed to avoid repeating monorepo and gate guidance already covered elsewhere
- `docs/index.html` now links to real repo docs and the pack index
- `packs/javascript/v0/.gitkeep` makes the scaffold explicit while keeping the pack minimal
- README now states that manifest artifact paths are placeholders for future release automation

## Verify
- [x] `README.md` describes `spec-of-dust` as a public project and includes sections for release packs and publishing shape
  Verified by headings and publishability language in `README.md`
- [x] A versionable release-pack source structure exists under `packs/` with a checked-in manifest at `packs/index.json`
  Verified by `packs/index.json`, `packs/javascript/v0/README.md`, and `packs/javascript/v0/.gitkeep`
- [x] A minimal static site entrypoint exists at `docs/index.html` and points readers at the core docs without adding a framework dependency
  Verified by static HTML file and working links to `README.md`, `docs/README.md`, and `packs/index.json`
- [x] Public-publishing basics exist as files: `LICENSE` and a minimal `.github/` docs scaffold for releases/pages
  Verified by `LICENSE` and `.github/README.md`
- [x] Startup guidance remains centralized in `.spec/b-startup.md`, with no net new startup-brief requirements added elsewhere
  Verified by trimming repeated startup guidance and keeping only short references in `README.md`, `AGENTS.md`, `CLAUDE.md`, `CODEX.md`, and `.spec/FLOW.md`

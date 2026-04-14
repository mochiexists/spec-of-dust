# Docs

Dock docs here so the repo root stays predictable.

The lightweight public entrypoint for GitHub Pages lives at `docs/index.html`.

Suggested structure:

```text
docs/
  architecture/   # System boundaries, dependency rules, diagrams
  decisions/      # ADRs and major technical choices
  runbooks/       # Deploy, incident, maintenance, recovery steps
  product/        # Domain notes, UX flows, non-code context
```

Startup note: dock durable detail here in `docs/` instead of bloating `.spec/b-startup.md`.

Public publishing note:

- keep public-facing overview docs light here
- keep release-pack source definitions in `packs/`
- use GitHub Releases for versioned downloadable artifacts later

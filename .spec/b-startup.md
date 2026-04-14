# B:/ Start Up

This is the minimal boot brief.

Read this on session start. Keep it short, stable, and high-signal.
Do not turn this into a second spec or a dumping ground.

Use it for:

- repo identity and intent
- current structure conventions
- monorepo layout expectations
- gate philosophy
- optional user preferences such as teaming intensity
- the few defaults every agent should know before reading anything deeper

Push depth elsewhere:

- active work goes in `.spec/changes/`
- skip audit entries go in `.spec/devlog.jsonl`
- long-lived architecture notes go in `docs/architecture/`
- ADRs and major choices go in `docs/decisions/`
- runbooks go in `docs/runbooks/`

Recommended shape:

1. What this repo is
2. How the root is organized
3. What must be kept clean
4. What gates matter most
5. Where deeper context lives
6. Optional: `teams: none | some | many`

If `teams:` is absent, default to `some`.
Set one live value only. Examples: `teams: none` for token-tight work, `teams: some` for bounded parallel help, `teams: many` for broad review or batch work.

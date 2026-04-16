# Rust Pack

Stack-specific gate suggestions for Rust projects using `spec-of-dust`.
These are suggestions, not requirements — adapt to your project's needs.

## Local gates

### Lint

```bash
cargo clippy -- -D warnings
```

### Format

```bash
cargo fmt --check
```

Suggested `rustfmt.toml`:

```toml
edition = "2024"
max_width = 100
use_small_heuristics = "Max"
```

### Build

```bash
cargo build
```

### Test

```bash
cargo test
```

## CI example

```yaml
# .github/workflows/validate.yml
name: Validate
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: clippy, rustfmt }
      - run: cargo fmt --check
      - run: cargo clippy -- -D warnings
      - run: cargo build
      - run: cargo test
      - run: bash scripts/update-sod-report.sh --check
      - run: bash tests/test-spec-gate.sh
```

## Tooling notes

- **Clippy** catches common mistakes and enforces idioms. `-D warnings` treats all lints as errors.
- **cargo fmt** with `--check` verifies formatting without modifying files.
- **Workspaces**: for monorepos, run gates at the workspace root. Clippy and fmt propagate to all members.
- **Feature flags**: test with `cargo test --all-features` to catch conditional compilation issues.
- Keep `target/` in `.gitignore`. Use `Cargo.lock` for binaries, omit for libraries.

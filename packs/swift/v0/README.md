# Swift / iOS Pack

Stack-specific gate suggestions for Swift projects using `spec-of-dust`.
These are suggestions, not requirements — adapt to your project's needs.

## Local gates

### Lint

```bash
swiftlint lint --strict
```

Suggested `.swiftlint.yml`:

```yaml
opt_in_rules:
  - empty_count
  - closure_spacing
  - force_unwrapping
excluded:
  - .build
  - DerivedData
```

### Build

For SPM projects:

```bash
swift build
```

For Xcode app projects:

```bash
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Test

For SPM:

```bash
swift test
```

For Xcode:

```bash
xcodebuild -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## CI example

```yaml
# .github/workflows/validate.yml
name: Validate
on: [push, pull_request]
jobs:
  validate:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: brew install swiftlint
      - run: swiftlint lint --strict
      - run: swift build
      - run: swift test
      - run: bash scripts/update-sod-report.sh --check
      - run: bash tests/test-spec-gate.sh
```

For Xcode app projects, replace `swift build/test` with `xcodebuild` commands and add a simulator boot step.

## Tooling notes

- **SwiftLint** enforces style. Install via `brew install swiftlint` or add as an SPM plugin.
- **Xcode projects** need a concrete scheme and destination. Use `xcodebuild -list` to find available schemes.
- **Screen Time API** and other entitlement-gated features require a physical device — CI can only build, not run.
- Keep `DerivedData/`, `.build/`, and `*.xcuserdata` in `.gitignore`.

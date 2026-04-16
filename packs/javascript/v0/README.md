# JavaScript / TypeScript Pack

Stack-specific gate suggestions for JavaScript and TypeScript projects using `spec-of-dust`.
These are suggestions, not requirements — adapt to your project's needs.

## Local gates

### Lint

```bash
# .githooks/pre-commit (add to your hook chain)
npx eslint --max-warnings 0 .
npx prettier --check .
```

Suggested ESLint config (`eslint.config.mjs`):

```js
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  prettier
);
```

### Type check

```bash
npx tsc --noEmit
```

### Test

```bash
npx vitest run
```

Alternative: `npx jest` if using Jest.

### Build

```bash
npm run build
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
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - run: npm ci
      - run: npx eslint --max-warnings 0 .
      - run: npx prettier --check .
      - run: npx tsc --noEmit
      - run: npx vitest run
      - run: bash scripts/update-sod-report.sh --check
      - run: bash tests/test-spec-gate.sh
```

## Tooling notes

- **Husky** can auto-install hooks via `npm install` instead of `bash setup.sh`. If your team prefers Node-managed hooks, use Husky as the transport and keep the same gate checks.
- **Prettier** handles formatting; ESLint handles logic rules. Don't overlap them.
- Keep `node_modules/` in `.gitignore`.

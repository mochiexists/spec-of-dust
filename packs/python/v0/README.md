# Python Pack

Stack-specific gate suggestions for Python projects using `spec-of-dust`.
These are suggestions, not requirements — adapt to your project's needs.

## Local gates

### Lint + format

```bash
ruff check .
ruff format --check .
```

Suggested `pyproject.toml` section:

```toml
[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "W", "UP", "B"]
```

Alternative: `black --check .` + `flake8` if you prefer the classic stack.

### Type check

```bash
mypy --strict .
```

Alternative: `pyright` for faster checks or VS Code integration.

### Test

```bash
pytest -v
```

### Build (if packaging)

```bash
python -m build
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
      - uses: actions/setup-python@v5
        with: { python-version: "3.12" }
      - run: pip install -e ".[dev]"
      - run: ruff check .
      - run: ruff format --check .
      - run: mypy --strict .
      - run: pytest -v
      - run: bash scripts/update-sod-report.sh --check
      - run: bash tests/test-spec-gate.sh
```

## Tooling notes

- **ruff** replaces black, isort, flake8, and pyupgrade in one tool. Strongly recommended for new projects.
- **Virtual environments**: use `python -m venv .venv` and add `.venv/` to `.gitignore`.
- **Dependencies**: pin with `requirements.txt` or `uv.lock`. Use `pyproject.toml` for project metadata.
- **Pre-commit**: `pip install pre-commit` works alongside spec-of-dust hooks if you want both.

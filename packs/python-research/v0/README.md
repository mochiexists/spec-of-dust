# Python ML / Research Pack

Stack-specific gate suggestions for machine learning and research projects using `spec-of-dust`.
These are suggestions, not requirements — adapt to your project's needs.

## Local gates

### Lint + format

```bash
ruff check .
ruff format --check .
```

### Type check

```bash
mypy --strict src/
```

### Test

```bash
pytest -v --ignore=notebooks/
```

### Notebook hygiene

```bash
# Strip outputs before commit to keep diffs clean and avoid leaking data
nbstripout --verify notebooks/*.ipynb
```

Install: `pip install nbstripout && nbstripout --install` (auto-strips on commit via git filter).

### Data validation

```bash
# If using DVC for data versioning
dvc status  # check data pipeline is current
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
      - run: mypy --strict src/
      - run: pytest -v --ignore=notebooks/
      - run: nbstripout --verify notebooks/*.ipynb
      - run: bash scripts/update-sod-report.sh --check
      - run: bash tests/test-spec-gate.sh

  gpu-tests:
    runs-on: [self-hosted, gpu]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - run: pip install -e ".[dev,gpu]"
      - run: pytest -v tests/gpu/
```

## Experiment tracking

- **MLflow**: `mlflow.log_params()` / `mlflow.log_metrics()`. Keep `mlruns/` in `.gitignore`.
- **Weights & Biases**: `wandb.init()` with project name matching the repo. API keys in `.env`, not committed.
- **Hydra**: config-driven experiments. Keep `outputs/` in `.gitignore`.

## Tooling notes

- **GPU CI** is expensive — run only on main pushes or `workflow_dispatch`.
- **Large files**: use DVC or Git LFS. Never commit model weights or datasets directly.
- **Notebooks in CI**: test with `jupyter nbconvert --execute` or `pytest-notebook`.
- **Reproducibility**: pin `torch`/`tensorflow` versions. Random seeds in test fixtures.
- Keep `.venv/`, `__pycache__/`, `*.egg-info/`, `mlruns/`, `wandb/`, `outputs/`, `data/` in `.gitignore`.

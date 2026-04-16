# SOD Report

- Version: `0.1.0`
- Scope: Git-tracked text files when Git metadata is available; fallback to repo file scan otherwise
- Token estimate: `ceil(characters / 4)`
- Total files: `54`
- Total lines: `4778`
- Total words: `38899`
- Total characters: `296050`
- Total estimated tokens: `74033`
- Bootstrap SOD: `1705 / 3000 target`
- Operational SOD: `3559 / 5000 target`

| File | Lines | Words | Characters | Est. tokens |
| --- | ---: | ---: | ---: | ---: |
| `.githooks/_spec_gate.sh` | 508 | 1482 | 11741 | 2936 |
| `.githooks/post-merge` | 8 | 23 | 230 | 58 |
| `.githooks/pre-commit` | 21 | 92 | 636 | 159 |
| `.githooks/prepare-commit-msg` | 10 | 26 | 250 | 63 |
| `.github/README.md` | 15 | 67 | 434 | 109 |
| `.github/workflows/validate.yml` | 23 | 42 | 404 | 101 |
| `.gitignore` | 4 | 6 | 72 | 18 |
| `.spec/FLOW.md` | 119 | 948 | 6296 | 1574 |
| `.spec/archive/2026-04-14-add-agent-team-guidance.md` | 60 | 516 | 3244 | 811 |
| `.spec/archive/2026-04-14-add-feature-closure-summary.md` | 66 | 731 | 4787 | 1197 |
| `.spec/archive/2026-04-14-add-sod-analysis-and-versioning.md` | 67 | 716 | 4727 | 1182 |
| `.spec/archive/2026-04-14-follow-up-repo-hygiene.md` | 62 | 674 | 4430 | 1108 |
| `.spec/archive/2026-04-14-prep-github-site-release.md` | 69 | 644 | 4708 | 1177 |
| `.spec/archive/2026-04-14-public-release-hygiene.md` | 65 | 753 | 4845 | 1212 |
| `.spec/archive/2026-04-14-widen-peer-review-context.md` | 57 | 704 | 4346 | 1087 |
| `.spec/archive/2026-04-15-005156-final-polish-and-ci.md` | 66 | 704 | 4626 | 1157 |
| `.spec/archive/2026-04-15-005156-merge-and-advance-workflow.md` | 79 | 1061 | 6685 | 1672 |
| `.spec/b-startup.md` | 13 | 76 | 524 | 131 |
| `.spec/changes/_template.md` | 37 | 152 | 925 | 232 |
| `.spec/changes/add-jsonl-append-helpers.md` | 52 | 628 | 4307 | 1077 |
| `.spec/changes/add-workflow-feedback-log.md` | 54 | 587 | 3975 | 994 |
| `.spec/changes/add-workflow-log-viewer.md` | 59 | 675 | 4293 | 1074 |
| `.spec/changes/condensation-review.md` | 109 | 1202 | 7499 | 1875 |
| `.spec/changes/embed-change-history-in-viewer.md` | 59 | 729 | 4831 | 1208 |
| `.spec/changes/embed-jsonl-in-viewer.md` | 57 | 655 | 4272 | 1068 |
| `.spec/changes/fix-claude-review-command-drift.md` | 45 | 418 | 2801 | 701 |
| `.spec/changes/fix-setup-template-drift.md` | 46 | 470 | 3285 | 822 |
| `.spec/changes/fix-viewer-archive-filename-parsing.md` | 45 | 450 | 3368 | 842 |
| `.spec/changes/full-repo-evaluation.md` | 169 | 1994 | 14291 | 3573 |
| `.spec/changes/operational-context-budget.md` | 50 | 525 | 3506 | 877 |
| `.spec/changes/require-commit-after-done.md` | 58 | 783 | 5331 | 1333 |
| `.spec/changes/scope-aware-commit-gate.md` | 62 | 804 | 5156 | 1289 |
| `.spec/changes/trim-bootstrap-context.md` | 58 | 575 | 3767 | 942 |
| `.spec/devlog.jsonl` | 3 | 58 | 827 | 207 |
| `.spec/flowlog.jsonl` | 14 | 465 | 5178 | 1295 |
| `AGENTS.md` | 24 | 162 | 1165 | 292 |
| `CLAUDE.md` | 15 | 145 | 957 | 240 |
| `CODEX.md` | 15 | 148 | 977 | 245 |
| `LICENSE` | 21 | 169 | 1066 | 267 |
| `README.md` | 183 | 1121 | 7429 | 1858 |
| `VERSION` | 1 | 1 | 6 | 2 |
| `docs/README.md` | 23 | 93 | 707 | 177 |
| `docs/index.html` | 136 | 324 | 3723 | 931 |
| `docs/viewer.html` | 618 | 11555 | 100118 | 25030 |
| `packs/index.json` | 13 | 27 | 324 | 81 |
| `packs/javascript/v0/README.md` | 11 | 59 | 381 | 96 |
| `scripts/archive-done-changes.sh` | 81 | 217 | 1654 | 414 |
| `scripts/build-viewer.sh` | 226 | 719 | 6715 | 1679 |
| `scripts/devlog.sh` | 71 | 333 | 2423 | 606 |
| `scripts/flowlog.sh` | 83 | 395 | 2914 | 729 |
| `scripts/merge-completed-work.sh` | 129 | 359 | 2843 | 711 |
| `scripts/update-sod-report.sh` | 297 | 832 | 7154 | 1789 |
| `setup.sh` | 100 | 422 | 2656 | 664 |
| `tests/test-spec-gate.sh` | 442 | 1383 | 12241 | 3061 |

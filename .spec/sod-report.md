# sod report

- Version: `0.2.0`
- Scope: Git-tracked text files when Git metadata is available; fallback to repo file scan otherwise
- Token estimate: `ceil(characters / 4)`
- Total files: `82`
- Total lines: `8302`
- Total words: `69476`
- Total characters: `539088`
- Total estimated tokens: `134799`
- bootstrap sod: `3188 / 3000 target`
- operational sod: `6859 / 5000 target`

| File | Lines | Words | Characters | Est. tokens |
| --- | ---: | ---: | ---: | ---: |
| `.githooks/_spec_gate.sh` | 547 | 1588 | 12672 | 3168 |
| `.githooks/post-merge` | 8 | 24 | 243 | 61 |
| `.githooks/pre-commit` | 21 | 92 | 636 | 159 |
| `.githooks/pre-push` | 76 | 280 | 2118 | 530 |
| `.githooks/prepare-commit-msg` | 10 | 26 | 250 | 63 |
| `.github/README.md` | 15 | 67 | 434 | 109 |
| `.github/workflows/validate.yml` | 29 | 60 | 576 | 144 |
| `.gitignore` | 7 | 15 | 147 | 37 |
| `.spec/FLOW.md` | 180 | 1871 | 12175 | 3044 |
| `.spec/archive/2026-04-14-add-agent-team-guidance.md` | 60 | 516 | 3244 | 811 |
| `.spec/archive/2026-04-14-add-feature-closure-summary.md` | 66 | 731 | 4787 | 1197 |
| `.spec/archive/2026-04-14-add-sod-analysis-and-versioning.md` | 67 | 716 | 4727 | 1182 |
| `.spec/archive/2026-04-14-follow-up-repo-hygiene.md` | 62 | 674 | 4430 | 1108 |
| `.spec/archive/2026-04-14-prep-github-site-release.md` | 69 | 644 | 4708 | 1177 |
| `.spec/archive/2026-04-14-public-release-hygiene.md` | 65 | 753 | 4845 | 1212 |
| `.spec/archive/2026-04-14-widen-peer-review-context.md` | 57 | 704 | 4346 | 1087 |
| `.spec/archive/2026-04-15-005156-final-polish-and-ci.md` | 66 | 704 | 4626 | 1157 |
| `.spec/archive/2026-04-15-005156-merge-and-advance-workflow.md` | 79 | 1061 | 6685 | 1672 |
| `.spec/archive/2026-04-16-232653-add-jsonl-append-helpers.md` | 52 | 628 | 4307 | 1077 |
| `.spec/archive/2026-04-16-232653-add-workflow-feedback-log.md` | 54 | 587 | 3975 | 994 |
| `.spec/archive/2026-04-16-232653-add-workflow-log-viewer.md` | 59 | 675 | 4293 | 1074 |
| `.spec/archive/2026-04-16-232653-condensation-review.md` | 109 | 1202 | 7499 | 1875 |
| `.spec/archive/2026-04-16-232653-embed-change-history-in-viewer.md` | 59 | 729 | 4831 | 1208 |
| `.spec/archive/2026-04-16-232653-embed-jsonl-in-viewer.md` | 57 | 655 | 4272 | 1068 |
| `.spec/archive/2026-04-16-232653-fix-claude-review-command-drift.md` | 45 | 418 | 2801 | 701 |
| `.spec/archive/2026-04-16-232653-fix-setup-template-drift.md` | 46 | 470 | 3285 | 822 |
| `.spec/archive/2026-04-16-232653-fix-viewer-archive-filename-parsing.md` | 45 | 450 | 3368 | 842 |
| `.spec/archive/2026-04-16-232653-full-repo-evaluation.md` | 169 | 1994 | 14291 | 3573 |
| `.spec/archive/2026-04-16-232653-operational-context-budget.md` | 50 | 525 | 3506 | 877 |
| `.spec/archive/2026-04-16-232653-require-commit-after-done.md` | 58 | 783 | 5331 | 1333 |
| `.spec/archive/2026-04-16-232653-scope-aware-commit-gate.md` | 62 | 804 | 5156 | 1289 |
| `.spec/archive/2026-04-16-232653-trim-bootstrap-context.md` | 58 | 575 | 3767 | 942 |
| `.spec/archive/2026-04-16-232653-validate-done-closeout-gate.md` | 79 | 827 | 5373 | 1344 |
| `.spec/archive/2026-04-17-002150-fix-archive-commit-gate-bypass.md` | 51 | 530 | 3699 | 925 |
| `.spec/archive/2026-04-17-004339-fix-sod-viewer-rebuild-loop.md` | 46 | 353 | 2479 | 620 |
| `.spec/archive/2026-04-17-005156-fix-viewer-freshness-and-archive-utc.md` | 66 | 864 | 6492 | 1623 |
| `.spec/archive/2026-04-17-005658-publish-dust-on-mochiexists.md` | 53 | 563 | 3996 | 999 |
| `.spec/archive/2026-04-17-011031-distinguish-advisory-vs-live-delivery.md` | 50 | 629 | 4407 | 1102 |
| `.spec/archive/2026-04-17-013944-create-language-packs.md` | 63 | 688 | 4757 | 1190 |
| `.spec/archive/2026-04-17-020153-record-git-identity-and-publish-restrictions.md` | 53 | 614 | 4140 | 1035 |
| `.spec/archive/2026-04-17-073907-clean-up-setup-sod-wording.md` | 62 | 529 | 3696 | 924 |
| `.spec/archive/2026-04-17-110335-rename-viewer-to-dust-and-bootstrap.md` | 54 | 573 | 4328 | 1082 |
| `.spec/archive/2026-04-17-123542-testing-guidance-in-flow.md` | 51 | 610 | 4019 | 1005 |
| `.spec/archive/2026-04-17-134119-add-push-knob.md` | 57 | 715 | 4580 | 1145 |
| `.spec/archive/2026-04-18-125840-agent-driven-sod-updates.md` | 59 | 803 | 5319 | 1330 |
| `.spec/archive/2026-04-18-131448-dust-filter-view.md` | 57 | 772 | 5273 | 1319 |
| `.spec/archive/2026-04-18-133345-build-dust-full-regen.md` | 57 | 758 | 5529 | 1383 |
| `.spec/archive/2026-04-18-141632-bump-to-0-2-0.md` | 33 | 210 | 1482 | 371 |
| `.spec/archive/2026-04-18-225455-pre-release-review-0-2-0.md` | 57 | 817 | 5694 | 1424 |
| `.spec/archive/2026-04-19-132448-guard-external-publishing.md` | 66 | 1141 | 7578 | 1895 |
| `.spec/b-startup.md` | 16 | 81 | 574 | 144 |
| `.spec/changes/_template.md` | 39 | 224 | 1400 | 350 |
| `.spec/changes/post-push-health-check.md` | 79 | 1411 | 9086 | 2272 |
| `.spec/devlog.jsonl` | 4 | 77 | 1120 | 280 |
| `.spec/flowlog.jsonl` | 33 | 840 | 10784 | 2696 |
| `AGENTS.md` | 32 | 288 | 2032 | 508 |
| `CLAUDE.md` | 23 | 265 | 1773 | 444 |
| `CODEX.md` | 23 | 267 | 1787 | 447 |
| `LICENSE` | 21 | 168 | 1068 | 267 |
| `README.md` | 188 | 1191 | 7836 | 1959 |
| `VERSION` | 1 | 1 | 6 | 2 |
| `docs/README.md` | 23 | 93 | 707 | 177 |
| `docs/dust.html` | 655 | 19412 | 167383 | 41846 |
| `docs/index.html` | 136 | 324 | 3723 | 931 |
| `docs/publish-dust-on-mochiexists.md` | 39 | 159 | 1119 | 280 |
| `packs/index.json` | 41 | 107 | 1366 | 342 |
| `packs/javascript/v0/README.md` | 76 | 214 | 1631 | 408 |
| `packs/python-research/v0/README.md` | 86 | 309 | 2336 | 584 |
| `packs/python/v0/README.md` | 75 | 223 | 1618 | 405 |
| `packs/rust/v0/README.md` | 67 | 194 | 1426 | 357 |
| `packs/swift/v0/README.md` | 80 | 217 | 1632 | 408 |
| `scripts/archive-done-changes.sh` | 103 | 265 | 2139 | 535 |
| `scripts/build-dust.sh` | 258 | 903 | 8034 | 2009 |
| `scripts/check-deploy-health.sh` | 165 | 763 | 5405 | 1352 |
| `scripts/devlog.sh` | 71 | 333 | 2419 | 605 |
| `scripts/flowlog.sh` | 83 | 395 | 2910 | 728 |
| `scripts/merge-completed-work.sh` | 165 | 475 | 3749 | 938 |
| `scripts/update-sod-report.sh` | 297 | 832 | 7154 | 1789 |
| `setup.sh` | 151 | 662 | 4341 | 1086 |
| `templates/dust.html` | 655 | 1857 | 21516 | 5379 |
| `tests/test-spec-gate.sh` | 625 | 2012 | 18125 | 4532 |
| `tests/test-workflow-scripts.sh` | 571 | 1897 | 17717 | 4430 |

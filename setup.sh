#!/usr/bin/env bash
# setup.sh — run once per clone to wire up spec-of-dust.
# No dependencies. No npm. No Python. Just git.

set -euo pipefail

echo "Setting up spec-of-dust..."

# Create directories
mkdir -p .spec/changes .spec/archive
mkdir -p scripts
if [ ! -f .spec/b-startup.md ]; then
  cat > .spec/b-startup.md <<'EOF'
# B:/ Start Up

Use this as the minimal boot brief.
Keep it short. Put deeper context in docs/ or active change files.
EOF
fi
touch .spec/devlog.jsonl
touch .spec/flowlog.jsonl
if [ ! -f VERSION ]; then
  printf '0.0.1\n' > VERSION
fi

# Copy template if not present
if [ ! -f .spec/changes/_template.md ]; then
  cat > .spec/changes/_template.md <<'EOF'
status: spec
files:

# {Change name}

## What
<!-- One paragraph. What are we building/fixing/changing and why. -->


## Acceptance criteria
<!-- Simple checkboxes. These become your verify checklist. -->
- [ ] 
- [ ] 
- [ ] 

## Notes
<!-- Optional. Constraints, edge cases, links, prior art. Delete if empty. -->


## Peer spec review
<!-- Filled by the other model before build begins. -->


## Peer code review
<!-- Filled by the other model after build completes. -->


## Verify
<!-- During verify: copy acceptance criteria here, mark pass/fail with notes. -->


## Closure
<!-- Keep it short. Use "nothing notable" if a bucket has no real signal. -->
- Challenges: friction, surprises, blockers, or nothing notable
- Learnings: reusable lessons or follow-up insight, or nothing notable
- Outcomes: delivered result plus key review/verify signal, or nothing notable
- Dust: one short human line; keep it under 80 chars
EOF
  echo "  ✓ Created .spec/changes/_template.md"
fi

# Migrate viewer.html → dust.html for existing repos
if [ -f docs/viewer.html ] && [ ! -f docs/dust.html ]; then
  mv docs/viewer.html docs/dust.html
  echo "  ✓ Migrated docs/viewer.html → docs/dust.html"
fi

# Migrate build-viewer.sh → build-dust.sh for existing repos
if [ -f scripts/build-viewer.sh ] && [ ! -f scripts/build-dust.sh ]; then
  mv scripts/build-viewer.sh scripts/build-dust.sh
  echo "  ✓ Migrated scripts/build-viewer.sh → scripts/build-dust.sh"
fi

# Create docs/dust.html from template if missing
if [ ! -f docs/dust.html ]; then
  mkdir -p docs
  if [ -f templates/dust.html ]; then
    cp templates/dust.html docs/dust.html
    echo "  ✓ Created docs/dust.html from template"
  fi
fi

# Point git at our hooks
git config core.hooksPath .githooks
chmod +x .githooks/*

echo "  ✓ Git hooks configured (.githooks/)"
echo "  ✓ pre-commit: blocks code commits without an active change file"
echo "  ✓ prepare-commit-msg: enforces trivial-only skip logging even with --no-verify"
echo "  ✓ post-merge: stages archive closeout after plain merges"
echo "  ✓ .spec/b-startup.md: created for minimal startup ingest"
echo "  ✓ .spec/devlog.jsonl: created for skip-no-verify audit entries"
echo "  ✓ VERSION: initialized to 0.0.1 if missing"
echo "  ✓ sod flow: use scripts/update-sod-report.sh to refresh repo metrics"

# Test readiness advisory
has_tests=false
if [ -d tests ] || [ -d test ]; then
  has_tests=true
elif find . -maxdepth 3 -type f \( -name '*.test.*' -o -name '*_test.*' \) 2>/dev/null | grep -q .; then
  has_tests=true
fi
if [ "$has_tests" = true ]; then
  echo "  ✓ Test files detected"
else
  echo "  ⚠ No test directory or test files found — consider setting up a test harness"
fi

# Verify AGENTS.md exists
if [ -f AGENTS.md ]; then
  echo "  ✓ AGENTS.md found"
else
  echo "  ⚠ No AGENTS.md — create one with your project context"
fi

if [ -f CLAUDE.md ]; then
  echo "  ✓ CLAUDE.md found"
fi

if [ -f CODEX.md ]; then
  echo "  ✓ CODEX.md found"
fi

echo ""
echo "Done. Start a feature with: cp .spec/changes/_template.md .spec/changes/my-feature.md"
echo ""

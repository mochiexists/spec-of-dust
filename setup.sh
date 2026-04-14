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
if [ ! -f VERSION ]; then
  printf '0.0.1\n' > VERSION
fi

# Copy template if not present
if [ ! -f .spec/changes/_template.md ]; then
  echo "  ✓ Created .spec/changes/_template.md"
fi

# Point git at our hooks
git config core.hooksPath .githooks
chmod +x .githooks/*

echo "  ✓ Git hooks configured (.githooks/)"
echo "  ✓ pre-commit: blocks code commits without an active change file"
echo "  ✓ prepare-commit-msg: enforces trivial-only skip logging even with --no-verify"
echo "  ✓ post-merge: archives completed change files"
echo "  ✓ .spec/b-startup.md: created for minimal startup ingest"
echo "  ✓ .spec/devlog.jsonl: created for skip-no-verify audit entries"
echo "  ✓ VERSION: initialized to 0.0.1 if missing"
echo "  ✓ SOD flow: use scripts/update-sod-report.sh to refresh repo metrics"

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

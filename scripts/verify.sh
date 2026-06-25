#!/usr/bin/env bash
# scripts/verify.sh — the mechanical "done" check. Mirrors ci.yml exactly.
# Agents MUST run this and see it pass before declaring a task complete.
# Usage: ./scripts/verify.sh
#
# Exit on first failure so you fix problems in order.
set -euo pipefail

echo ""
echo "▸ format";        dart format --output=none --set-exit-if-changed .
echo ""
echo "▸ analyze";       flutter analyze --fatal-infos --fatal-warnings
echo ""
echo "▸ custom_lint";   dart run custom_lint
echo ""
echo "▸ test";          flutter test
echo ""
echo "✅ verify passed — desired state is mechanically confirmed."

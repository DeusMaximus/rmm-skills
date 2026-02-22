#!/usr/bin/env bash
# Runs pre-release checks, then packages each skill into a zip for release.
# Usage: bash release.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PLATFORMS=(powershell macos linux)

# Run sanity checks first
echo "Running pre-release checks..."
echo ""
bash "$REPO_ROOT/scripts/check-release.sh"
echo ""

# Package each skill
for platform in "${PLATFORMS[@]}"; do
    skill_dir="rmm-$platform"
    zip_name="rmm-$platform.zip"

    if [[ ! -d "$REPO_ROOT/$skill_dir" ]]; then
        echo "ERROR: $skill_dir directory not found."
        exit 1
    fi

    rm -f "$REPO_ROOT/$zip_name"
    (cd "$REPO_ROOT" && zip -r "$zip_name" "$skill_dir/")
    echo ""
done

echo "Release artifacts:"
for platform in "${PLATFORMS[@]}"; do
    echo "  rmm-$platform.zip"
done

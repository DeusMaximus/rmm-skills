#!/usr/bin/env bash
# Pre-release sanity check — verifies skill files are in sync before a release.
# Usage: bash scripts/check-release.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORMS=(powershell macos linux)
ERRORS=0

# --- Check 1: All SKILL.md files have the same version ---
echo "Checking SKILL.md version consistency..."

declare -a VERSIONS
for platform in "${PLATFORMS[@]}"; do
    file="$REPO_ROOT/rmm-$platform/SKILL.md"
    ver=$(grep -m1 'version:' "$file" | sed 's/.*version:[[:space:]]*//' | tr -d '"' | tr -d "'")
    VERSIONS+=("$platform=$ver")
done

first_ver="${VERSIONS[0]#*=}"
all_match=true
for entry in "${VERSIONS[@]}"; do
    ver="${entry#*=}"
    if [[ "$ver" != "$first_ver" ]]; then
        all_match=false
    fi
done

if $all_match; then
    echo "  PASS: All SKILL.md files are at version $first_ver"
else
    echo "  FAIL: Version mismatch:"
    for entry in "${VERSIONS[@]}"; do
        echo "    $entry"
    done
    ERRORS=$((ERRORS + 1))
fi

# --- Check 2: All RMM-CONVENTIONS.md files are byte-identical ---
echo "Checking RMM-CONVENTIONS.md consistency..."

canonical="$REPO_ROOT/rmm-powershell/RMM-CONVENTIONS.md"
conventions_ok=true
for platform in macos linux; do
    target="$REPO_ROOT/rmm-$platform/RMM-CONVENTIONS.md"
    if ! diff -q "$canonical" "$target" > /dev/null 2>&1; then
        echo "  FAIL: rmm-$platform/RMM-CONVENTIONS.md differs from canonical (rmm-powershell/)"
        conventions_ok=false
        ERRORS=$((ERRORS + 1))
    fi
done

if $conventions_ok; then
    echo "  PASS: All RMM-CONVENTIONS.md files are identical"
fi

# --- Summary ---
echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "All checks passed."
    exit 0
else
    echo "$ERRORS check(s) failed."
    exit 1
fi

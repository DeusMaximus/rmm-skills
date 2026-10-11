#!/usr/bin/env bash
# Pre-release sanity check: verifies skill structure, shared-file sync, Markdown
# formatting rules, and syntax of the code examples before a release.
# Usage: bash scripts/check-release.sh
#
# Runs on bash 3.2+ (macOS default). Syntax checks use bash, zsh and pwsh when
# installed and are skipped with a warning when not.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORMS=(powershell macos linux)
SHARED_FILES=(CORE-CONVENTIONS.md CODE-REVIEW.md CROSS-PLATFORM.md NINJAONE-WYSIWYG.md)
PLATFORM_FILES=(SKILL.md NINJAONE.md NINJAONE-CUSTOM-FIELDS.md NINJAONE-TAGS.md ACTION1.md)
ERRORS=0
WARNINGS=0

fail() { echo "  FAIL: $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  WARN: $1"; WARNINGS=$((WARNINGS + 1)); }
pass() { echo "  PASS: $1"; }

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# --- Check 1: All SKILL.md files have the same version ------------------------
echo "Checking SKILL.md version consistency..."

first_ver=""
versions_ok=true
for platform in "${PLATFORMS[@]}"; do
    file="$REPO_ROOT/rmm-$platform/SKILL.md"
    ver=$(grep -m1 'version:' "$file" | sed 's/.*version:[[:space:]]*//' | tr -d '"' | tr -d "'")
    if ! grep -qE '^[[:space:]]+version: "[0-9]+\.[0-9]+\.[0-9]+"$' "$file"; then
        fail "rmm-$platform/SKILL.md version must be a quoted x.y.z string"
        versions_ok=false
    fi
    if [[ -z "$first_ver" ]]; then
        first_ver="$ver"
    elif [[ "$ver" != "$first_ver" ]]; then
        fail "rmm-$platform/SKILL.md is at $ver, expected $first_ver"
        versions_ok=false
    fi
done
$versions_ok && pass "All SKILL.md files are at version $first_ver"

# --- Check 2: Skill name matches its directory ---------------------------------
echo "Checking skill names match directory names..."

names_ok=true
for platform in "${PLATFORMS[@]}"; do
    name=$(grep -m1 '^name:' "$REPO_ROOT/rmm-$platform/SKILL.md" | sed 's/^name:[[:space:]]*//')
    if [[ "$name" != "rmm-$platform" ]]; then
        fail "rmm-$platform/SKILL.md has name '$name', expected 'rmm-$platform'"
        names_ok=false
    fi
done
$names_ok && pass "Every skill name matches its directory"

# --- Check 3: Required files exist, are routed, and references resolve ----------
echo "Checking file set and references..."

files_ok=true
for platform in "${PLATFORMS[@]}"; do
    dir="$REPO_ROOT/rmm-$platform"
    for f in "${PLATFORM_FILES[@]}" "${SHARED_FILES[@]}"; do
        if [[ ! -f "$dir/$f" ]]; then
            fail "rmm-$platform/$f is missing"
            files_ok=false
        fi
    done
    for path in "$dir"/*.md; do
        f="$(basename "$path")"
        [[ "$f" == "SKILL.md" ]] && continue
        if ! grep -q "$f" "$dir/SKILL.md"; then
            fail "rmm-$platform/$f is not routed from SKILL.md"
            files_ok=false
        fi
    done
    for ref in $(cat "$dir"/*.md | grep -oE '[A-Z0-9][A-Z0-9-]*\.md' | sort -u); do
        if [[ ! -f "$dir/$ref" ]]; then
            fail "rmm-$platform references $ref, which does not exist"
            files_ok=false
        fi
    done
done
$files_ok && pass "All files present, routed from SKILL.md, and all references resolve"

# --- Check 4: Shared files are byte-identical -----------------------------------
echo "Checking shared files are identical (canonical: rmm-powershell/)..."

shared_ok=true
for f in "${SHARED_FILES[@]}"; do
    for platform in macos linux; do
        if ! diff -q "$REPO_ROOT/rmm-powershell/$f" "$REPO_ROOT/rmm-$platform/$f" > /dev/null 2>&1; then
            fail "rmm-$platform/$f differs from rmm-powershell/$f"
            shared_ok=false
        fi
    done
done
$shared_ok && pass "Shared files are identical: ${SHARED_FILES[*]}"

# --- Check 5: Markdown formatting rules ------------------------------------------
# Some skill importers mangle inline code and fences that are not separated by
# blank lines. All code must be in fenced blocks with a language identifier.
echo "Checking Markdown formatting..."

lint_output="$WORK_DIR/lint.txt"
: > "$lint_output"
for platform in "${PLATFORMS[@]}"; do
    for path in "$REPO_ROOT/rmm-$platform"/*.md; do
        awk -v name="rmm-$platform/$(basename "$path")" '
            function report(msg) { print name ":" FNR ": " msg }
            BEGIN { in_fence = 0; prev = ""; after_close = 0 }
            {
                line = $0
                if (after_close) {
                    if (line != "") report("closing fence must be followed by a blank line")
                    after_close = 0
                }
                if (in_fence) {
                    if (line ~ /^```[ \t]*$/) { in_fence = 0; after_close = 1 }
                    prev = line
                    next
                }
                if (line ~ /^[ \t]+```/) { report("indented code fence; fences must start at column 1"); prev = line; next }
                if (line ~ /^```/) {
                    lang = substr(line, 4)
                    gsub(/[ \t]/, "", lang)
                    if (lang == "") report("code fence without a language identifier")
                    if (prev != "") report("opening fence must follow a blank line")
                    in_fence = 1
                    fence_start = FNR
                    prev = line
                    next
                }
                if (index(line, "`") > 0)          report("backtick outside a fenced block (no inline code)")
                if (line ~ /\$/)                   report("dollar sign outside a fenced block")
                if (line ~ /<[A-Za-z\/!]/)         report("HTML tag outside a fenced block")
                if (line ~ /^[ \t]*\|/)            report("Markdown table (use bullets or a text block)")
                prev = line
            }
            END { if (in_fence) print name ":" fence_start ": unclosed code fence" }
        ' "$path" >> "$lint_output"
    done
done

if [[ -s "$lint_output" ]]; then
    while IFS= read -r issue; do fail "$issue"; done < "$lint_output"
else
    pass "Fences are tagged and separated; no inline code, HTML or tables in prose"
fi

# --- Check 6: Suspicious Markdown escapes inside code ----------------------------
# A backslash before these characters inside code is almost always a Markdown
# escape artefact, and escaped PowerShell often still parses (as a command call),
# so the syntax checks below will not catch it. If a hit is genuinely needed (for
# example in a regular expression), rewrite it, such as with a character class.
echo "Checking for escaped characters inside code blocks..."

escape_output="$WORK_DIR/escapes.txt"
: > "$escape_output"
for platform in "${PLATFORMS[@]}"; do
    for path in "$REPO_ROOT/rmm-$platform"/*.md; do
        awk -v name="rmm-$platform/$(basename "$path")" '
            /^```/ { in_fence = !in_fence; next }
            in_fence && /\\[][#_*<>|`]/ { print name ":" FNR ": " $0 }
        ' "$path" >> "$escape_output"
    done
done

if [[ -s "$escape_output" ]]; then
    while IFS= read -r hit; do fail "possible Markdown escape: $hit"; done < "$escape_output"
else
    pass "No suspicious escapes inside code blocks"
fi

# --- Check 7: Syntax-check code blocks -------------------------------------------
echo "Syntax-checking code blocks..."

block_dir="$WORK_DIR/blocks"
mkdir -p "$block_dir"
for platform in "${PLATFORMS[@]}"; do
    for path in "$REPO_ROOT/rmm-$platform"/*.md; do
        awk -v prefix="$block_dir/rmm-${platform}__$(basename "$path" .md)" '
            /^```/ && !in_fence {
                lang = substr($0, 4)
                ext = ""
                if (lang == "powershell") ext = "ps1"
                else if (lang == "bash") ext = "sh"
                else if (lang == "zsh") ext = "zsh"
                in_fence = 1
                out = (ext == "") ? "" : prefix "__L" FNR "." ext
                next
            }
            /^```/ && in_fence { in_fence = 0; if (out != "") close(out); out = ""; next }
            in_fence && out != "" { print > out }
        ' "$path"
    done
done

check_shell_blocks() {
    local shell="$1" ext="$2" ok=true found=false file
    for file in "$block_dir"/*."$ext"; do
        [[ -e "$file" ]] || continue
        found=true
        if ! "$shell" -n "$file" 2> "$WORK_DIR/err.txt"; then
            fail "$shell syntax error in $(basename "$file"): $(head -1 "$WORK_DIR/err.txt")"
            ok=false
        fi
    done
    if $found && $ok; then pass "All $shell blocks parse"; fi
}

if command -v bash > /dev/null 2>&1; then
    check_shell_blocks bash sh
else
    warn "bash not found; bash blocks not checked"
fi

if command -v zsh > /dev/null 2>&1; then
    check_shell_blocks zsh zsh
else
    warn "zsh not found; zsh blocks not checked"
fi

if command -v pwsh > /dev/null 2>&1; then
    cat > "$WORK_DIR/check.ps1" <<'PWSH'
$Failures = 0
$Language = [System.Management.Automation.Language.Parser]
foreach ($Path in $args) {
    $Tokens = $null
    $ParseErrors = $null
    $Ast = $Language::ParseFile($Path, [ref]$Tokens, [ref]$ParseErrors)
    $Leaf = Split-Path -Path $Path -Leaf
    foreach ($ParseError in $ParseErrors) {
        Write-Output "parse error in ${Leaf}: $($ParseError.Message)"
        $Failures++
    }
    # pwsh 7 accepts 7-only syntax, so look for it explicitly.
    $Ps7Nodes = $Ast.FindAll({
        param($Node)
        $TypeName = $Node.GetType().Name
        ($TypeName -eq 'TernaryExpressionAst') -or
        ($TypeName -eq 'PipelineChainAst') -or
        ($TypeName -eq 'BinaryExpressionAst' -and "$($Node.Operator)" -eq 'QuestionQuestion') -or
        ($TypeName -eq 'AssignmentStatementAst' -and "$($Node.Operator)" -eq 'QuestionQuestionEquals') -or
        ($Node.PSObject.Properties['NullConditional'] -and $Node.NullConditional)
    }, $true)
    foreach ($Node in $Ps7Nodes) {
        Write-Output "PowerShell 7-only syntax in ${Leaf}: $($Node.Extent.Text)"
        $Failures++
    }
}
exit [math]::Min($Failures, 1)
PWSH
    shopt -s nullglob
    ps_blocks=("$block_dir"/*.ps1)
    shopt -u nullglob
    if (( ${#ps_blocks[@]} > 0 )); then
        if pwsh_output=$(pwsh -NoProfile -NonInteractive -File "$WORK_DIR/check.ps1" "${ps_blocks[@]}" 2>&1); then
            pass "All PowerShell blocks parse with no PowerShell 7-only syntax"
        else
            while IFS= read -r issue; do fail "$issue"; done <<< "$pwsh_output"
        fi
    fi
else
    warn "pwsh not found; PowerShell blocks not checked"
fi

# --- Summary --------------------------------------------------------------------
echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "All checks passed ($WARNINGS warning(s))."
    exit 0
else
    echo "$ERRORS check(s) failed ($WARNINGS warning(s))."
    exit 1
fi

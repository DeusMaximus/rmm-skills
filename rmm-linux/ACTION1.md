# Action1 on Linux

Read this file instead of NINJAONE.md when the user says the script is for Action1.

## What Applies

- This skill has no verified Action1-specific behaviour for Linux. Do not assume Action1 features that the user has not described.
- Action1 custom attributes are available on Windows only. A Linux script cannot store data in them.
- None of the NinjaOne features are available: no ninjarmm-cli, no NINJA agent environment variables, no custom fields, no device tags and no WYSIWYG fields.
- Confirm the run context with the user. The template assumes root, the default for this skill.
- All other rules still apply: CORE-CONVENTIONS.md and the bash baseline in SKILL.md.

## Template

```bash
#!/bin/bash
# ==============================================================================
# Script:      script-name
# Description: One-line summary of what the script does.
# Context:     Runs as root via Action1.
# Exit codes:  0 = success, 1 = failure
# ==============================================================================

set -euo pipefail

# --- Configuration ------------------------------------------------------------
# Hardcoded so that output is labelled correctly even if the agent runs a renamed copy.
readonly SCRIPT_NAME="script-name"

# --- Functions ----------------------------------------------------------------
log_info() {
    printf '[INFO] %s: %s\n' "$SCRIPT_NAME" "$1"
}

log_error() {
    printf 'ERROR: %s: %s\n' "$SCRIPT_NAME" "$1" >&2
}

# --- Validate execution context: must be root ------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This script must run as root."
    exit 1
fi

# --- Main ---------------------------------------------------------------------

# Main logic here

exit 0
```

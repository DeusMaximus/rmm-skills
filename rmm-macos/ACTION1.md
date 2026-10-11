# Action1 on macOS

Read this file instead of NINJAONE.md when the user says the script is for Action1.

## What Applies

- This skill has no verified Action1-specific behaviour for macOS. Do not assume Action1 features that the user has not described.
- Action1 custom attributes are available on Windows only. A macOS script cannot store data in them.
- None of the NinjaOne features are available: no ninjarmm-cli, no NINJA agent environment variables, no custom fields, no device tags and no WYSIWYG fields.
- Confirm the run context (logged-in user or root) with the user. Do not assume NinjaOne's default.
- All other rules still apply: CORE-CONVENTIONS.md and the zsh baseline in SKILL.md.

## Template

The re-exec guard and explicit PATH were added for NinjaOne. They are harmless on any agent and protect against the same problems, so keep them unless the user confirms they are unnecessary.

```zsh
#!/bin/zsh
# ==============================================================================
# Script:      script-name
# Description: One-line summary of what the script does.
# Context:     Runs as [the logged-in user | root] via Action1.
# Exit codes:  0 = success, 1 = failure
# ==============================================================================

# Re-run with zsh if the agent started this file with another shell. Keep this block POSIX.
if [ -z "${ZSH_VERSION:-}" ]; then
    exec /bin/zsh "$0" "$@"
fi

export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

set -euo pipefail

# --- Configuration ------------------------------------------------------------
readonly SCRIPT_NAME="script-name"

# --- Functions ----------------------------------------------------------------
log_info() {
    printf '[INFO] %s: %s\n' "$SCRIPT_NAME" "$1"
}

log_error() {
    printf 'ERROR: %s: %s\n' "$SCRIPT_NAME" "$1" >&2
}

# --- Validate execution context (this example requires root) ---------------------
if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This script must run as root."
    exit 1
fi

# --- Main ---------------------------------------------------------------------

# Main logic here

exit 0
```

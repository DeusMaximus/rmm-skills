# NinjaOne on macOS

Read this file for every macOS script that runs through NinjaOne. It covers the script templates, agent quirks, run-as behaviour, script variables, and the environment variables that the agent provides. Custom fields, tags and WYSIWYG fields have their own reference files.

## Agent Quirks

These three quirks break scripts that would work in Terminal. The templates below handle all of them.

- The shebang is ignored. NinjaOne runs macOS scripts with bash even when the first line names zsh, so zsh-only syntax (for example the tail modifier on a parameter, case-conversion flags, array slicing and native associative arrays) misbehaves or fails. The templates re-run the file with zsh before any zsh-specific code. The guard must come before strict mode and must use POSIX syntax, because it runs under bash.
- The PATH is minimal. The agent is launched by launchd with a PATH that often contains only /usr/bin and /bin, so tools in /usr/sbin and /sbin (networksetup, system_profiler, softwareupdate, pmset, diskutil, ifconfig, scutil, nvram and others) fail with "command not found". The templates set a full system PATH. Alternatively, call those tools by full path.
- The script name is meaningless. NinjaOne runs a temporary copy of the script under a generated name in a private temporary folder, so anything derived from the script's own path is useless as a name. The templates hardcode SCRIPT_NAME instead.

## Run-As Behaviour

- Scripts run as the logged-in user by default. A user-context script cannot use NinjaOne custom fields or tags, because ninjarmm-cli works only as root.
- Root scripts can change system-wide settings and use custom fields and tags. The script is configured to run as root in the NinjaOne console; it never calls sudo to elevate.

### Collecting Per-User Data From a Root Script

To write per-user information to a custom field, run the script as root, find the console user, and run the user-level command as that user. Handle the case where nobody is logged in.

```zsh
console_user="$(stat -f %Su /dev/console)"

if [[ -z "$console_user" || "$console_user" == "root" || "$console_user" == "loginwindow" ]]; then
    log_info "No user is logged in. Nothing to collect."
    exit 0
fi

console_uid="$(id -u "$console_user")"
user_value="$(launchctl asuser "$console_uid" sudo -u "$console_user" defaults read com.apple.screensaver askForPassword 2>/dev/null || printf 'unset')"
log_info "askForPassword for ${console_user}: ${user_value}"
```

Running a command with su and a login shell for the user is an alternative when the command does not need the user's GUI session.

## Template: Logged-In User Context

```zsh
#!/bin/zsh
# ==============================================================================
# Script:      script-name
# Description: One-line summary of what the script does.
# Context:     Runs as the logged-in user via NinjaOne.
# Exit codes:  0 = success, 1 = failure
# ==============================================================================

# NinjaOne runs macOS scripts with bash regardless of the shebang.
# Re-run this file with zsh before any zsh-specific code. Keep this block POSIX.
if [ -z "${ZSH_VERSION:-}" ]; then
    exec /bin/zsh "$0" "$@"
fi

# The agent starts with a minimal PATH, so tools in /usr/sbin and /sbin would not resolve.
export PATH="/usr/bin:/bin:/usr/sbin:/sbin"

set -euo pipefail

# --- Configuration ------------------------------------------------------------
# Hardcoded because NinjaOne runs a temporary copy with a generated file name.
readonly SCRIPT_NAME="script-name"

# --- Functions ----------------------------------------------------------------
log_info() {
    printf '[INFO] %s: %s\n' "$SCRIPT_NAME" "$1"
}

log_error() {
    printf 'ERROR: %s: %s\n' "$SCRIPT_NAME" "$1" >&2
}

# --- Validate execution context: must not be root ------------------------------
if [[ "$(id -u)" -eq 0 ]]; then
    log_error "This script must run as the logged-in user, not root. Change the run-as setting in NinjaOne."
    exit 1
fi

# --- Validate script variables ---------------------------------------------------
missing_params=()
[[ -z "${targetPath:-}" ]] && missing_params+=("targetPath")

if (( ${#missing_params[@]} > 0 )); then
    log_error "Missing required script variable(s): ${missing_params[*]}"
    exit 1
fi

# --- Main ---------------------------------------------------------------------
log_info "Organisation: ${NINJA_ORGANIZATION_NAME:-unknown}"

# Main logic here

exit 0
```

## Template: Root Context

Use the same file, with these changes to the header and context check:

```zsh
# Context:     Runs as root via NinjaOne.

# --- Validate execution context: must be root ------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This script must run as root. Change the run-as setting in NinjaOne."
    exit 1
fi
```

## Script Variables

NinjaOne passes script inputs to the script as environment variables. They are configured on the script in the NinjaOne console and are separate from custom fields.

- The variable name is the display name converted to camelCase. For example, "Server Name" becomes serverName and "Port Number" becomes portNumber.
- Every script variable arrives as a string, whatever its type in the console. Validate it before using it as a number.
- An optional variable that was left blank arrives as an empty string. Under strict mode, reference variables with an empty default so that an unset variable does not abort the script.
- Mark sensitive inputs as the Secure variable type. The value is masked in the console and logs, but still arrives in the script as plain text, so never write it to output.
- NinjaOne does not support the following characters in script variable names or values. Scripts that use them fail at run time without a clear error:

```text
Å  Ä  Ö  &  |  ;  $  >  <  `  !
```

How each variable type arrives and how to handle it:

```text
String or Text   any text                              use directly
Integer          digits, for example "42"              check it matches ^[0-9]+$ before arithmetic
Decimal          for example "3.14"                    check the format before use
Checkbox         "true" or "false"                     compare as a string with == "true"
Date             ISO 8601, time zeroed                 treat as text; parse only if needed
Date and Time    ISO 8601, may include an offset       treat as text; parse only if needed
Dropdown         the selected option's text            use directly
IP Address       for example "192.168.1.1"             validate the format before use
```

Date values can include fractional seconds and a time-zone offset, for example 2024-01-15T00:00:00.000+00:00. If you need to parse one, account for the offset rather than assuming UTC.

```zsh
missing_params=()
[[ -z "${serverName:-}" ]] && missing_params+=("serverName")
[[ -z "${targetPath:-}" ]] && missing_params+=("targetPath")

if (( ${#missing_params[@]} > 0 )); then
    log_error "Missing required script variable(s): ${missing_params[*]}"
    exit 1
fi

port="${portNumber:-443}"
if [[ ! "$port" =~ ^[0-9]+$ ]]; then
    log_error "portNumber must be a whole number, not '${port}'."
    exit 1
fi

if [[ "${enableFeature:-false}" == "true" ]]; then
    log_info "Feature enabled."
fi
```

## Defined Parameters

NinjaOne can also pass traditional script arguments, called defined parameters. This is mainly for converting existing scripts that already parse positional arguments or options. Use environment-variable script variables for new scripts. The NinjaOne console cannot mark a defined parameter as mandatory, so the script must validate it.

## Agent Environment Variables

The NinjaOne agent sets these variables for every script. They exist only when the NinjaOne agent runs the script, and changed values are picked up only after the device restarts.

```text
NINJA_ORGANIZATION_NAME           Organisation name. Include it in output for multi-tenant troubleshooting.
NINJA_ORGANIZATION_ID             Organisation ID (integer).
NINJA_COMPANY_NAME                Company name. Can differ from the organisation name.
NINJA_LOCATION_NAME               Location (site) name.
NINJA_LOCATION_ID                 Location ID (integer).
NINJA_AGENT_NODE_ID               Device node ID on the NinjaOne server. Use it for API calls about this device.
NINJA_AGENT_MACHINE_ID            Machine ID on the NinjaOne server.
NINJA_DATA_PATH                   Agent data folder: scripts, logs, downloads and ninjarmm-cli.
NINJA_EXECUTING_PATH              Agent installation folder.
NINJA_AGENT_VERSION_INSTALLED     Installed agent version.
NINJA_PATCHER_VERSION_INSTALLED   Installed patcher version.
NINJA_AGENT_PASSWORD              Agent password for session-key authentication. Never write it to output.
```

```zsh
log_info "Organisation: ${NINJA_ORGANIZATION_NAME:-unknown}"
```

## Common Mistakes (NinjaOne on macOS)

1. Trusting the zsh shebang. Always include the re-exec guard.
2. Relying on the inherited PATH.
3. Deriving SCRIPT_NAME from the script's own path.
4. Testing a checkbox variable for truthiness instead of comparing it with the text "true".
5. Referencing an optional variable without a default under strict mode.
6. Expecting custom fields or tags to work in the default user context.
7. Leaving out context validation, so a script with the wrong run-as setting fails without a clear message.

# NinjaOne on Linux

Read this file for every Linux script that runs through NinjaOne. It covers the script templates, agent quirks, run-as behaviour, script variables, and the environment variables that the agent provides. Custom fields, tags and WYSIWYG fields have their own reference files.

## Agent Quirks

- ninjarmm-cli is not on the PATH. Calling it by bare name fails. Use the full path, built from the agent's data-folder variable (see NINJAONE-CUSTOM-FIELDS.md). A dot-slash prefix works only when the current directory happens to be the agent's programdata folder.
- The script name is meaningless. NinjaOne runs a temporary copy of the script under a generated name in a temporary folder, so anything derived from the script's own path is useless as a name. The templates hardcode SCRIPT_NAME instead.

## Run-As Behaviour

- Scripts run as root by default. Root can manage packages, services and system configuration, and is the only context in which custom fields and tags work.
- A standard-user script can reach that user's home directory, crontab and settings, but cannot use custom fields or tags.

### Collecting Per-User Data From a Root Script

To write per-user information to a custom field, run the script as root and run the user-level command as the target user. Validate that the user exists first.

```bash
target_user="${targetUser:-}"

if [[ -z "$target_user" ]] || ! id "$target_user" >/dev/null 2>&1; then
    log_error "targetUser is missing or is not a valid local user."
    exit 1
fi

user_crontab="$(runuser -u "$target_user" -- crontab -l 2>/dev/null || true)"
if [[ -z "$user_crontab" ]]; then
    log_info "${target_user} has no crontab."
fi
```

Running the command with su and a login shell for the user is an alternative when the user's login environment is needed.

## Template: Root Context

```bash
#!/bin/bash
# ==============================================================================
# Script:      script-name
# Description: One-line summary of what the script does.
# Context:     Runs as root via NinjaOne.
# Exit codes:  0 = success, 1 = failure
# ==============================================================================

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

# --- Validate execution context: must be root ------------------------------------
if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This script must run as root. Change the run-as setting in NinjaOne."
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

## Template: Standard User Context

Use the same file, with these changes to the header and context check:

```bash
# Context:     Runs as a standard user via NinjaOne.

# --- Validate execution context: must not be root ------------------------------
if [[ "$(id -u)" -eq 0 ]]; then
    log_error "This script must run as a standard user, not root. Change the run-as setting in NinjaOne."
    exit 1
fi
```

## Template Addition: Command-Line Arguments

Add a usage function and a getopts loop only when the script takes defined parameters (command-line arguments). Place them after the logging functions:

```bash
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} -t <target-path> [-v]

  -t   Target path (required)
  -v   Verbose output
  -h   Show this help
EOF
}

target_path=""
verbose="false"

while getopts ":t:vh" opt; do
    case "$opt" in
        t) target_path="$OPTARG" ;;
        v) verbose="true" ;;
        h) usage; exit 0 ;;
        :) log_error "Option -${OPTARG} requires a value."; usage >&2; exit 1 ;;
        *) log_error "Unknown option: -${OPTARG}"; usage >&2; exit 1 ;;
    esac
done

if [[ -z "$target_path" ]]; then
    log_error "The -t option is required."
    usage >&2
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
Date             ISO 8601, time zeroed                 parse with date -d if needed
Date and Time    ISO 8601, may include an offset       parse with date -d if needed
Dropdown         the selected option's text            use directly
IP Address       for example "192.168.1.1"             validate the format before use
```

Date values can include fractional seconds and a time-zone offset, for example 2024-01-15T00:00:00.000+00:00. GNU date understands ISO 8601 with an offset:

```bash
if [[ -n "${startDate:-}" ]]; then
    if ! start_epoch="$(date -d "$startDate" +%s 2>/dev/null)"; then
        log_error "startDate is not a valid date: '${startDate}'"
        exit 1
    fi
    log_info "Start date (epoch seconds): ${start_epoch}"
fi
```

Check that the value is not empty first: GNU date treats an empty string as midnight today and reports success.

Validate all required variables together, then check optional ones only when they have a value:

```bash
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

NinjaOne can also pass traditional script arguments, called defined parameters. This is mainly for converting existing scripts that already use getopts or positional arguments. Use environment-variable script variables for new scripts. The NinjaOne console cannot mark a defined parameter as mandatory, so the script must validate it (see the getopts template addition above).

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

```bash
log_info "Organisation: ${NINJA_ORGANIZATION_NAME:-unknown}"
```

## Common Mistakes (NinjaOne on Linux)

1. Calling ninjarmm-cli by bare name.
2. Deriving SCRIPT_NAME from the script's own path.
3. Testing a checkbox variable for truthiness instead of comparing it with the text "true".
4. Referencing an optional variable without a default under strict mode.
5. Expecting custom fields or tags to work in standard-user context.
6. Leaving out context validation, so a script with the wrong run-as setting fails without a clear message.

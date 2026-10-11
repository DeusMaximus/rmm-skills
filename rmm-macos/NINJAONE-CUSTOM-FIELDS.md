# NinjaOne Custom Fields on macOS

Read this file when a macOS script reads or writes NinjaOne custom fields or documentation fields, including WYSIWYG fields.

## Context Requirement

Custom fields, for both reading and writing, work only when the script runs as root. macOS scripts run as the logged-in user by default, so a script that uses custom fields must be configured to run as root in the NinjaOne console. To put per-user data into a field, run as root and collect the data with the technique in NINJAONE.md.

## Field Concepts

- Device custom fields (global or role fields) belong to a device and are addressed by field name.
- Documentation fields belong to the organisation and are addressed by template name, document name and field name.
- Secure fields can be read only while an automation is running, not from the web or local terminal. Documentation secure fields are write-only.
- Dropdown and multi-select fields store option GUIDs. Use the options command to map GUIDs to option names.
- Date and time values are stored as Unix epoch seconds or as ISO 8601 text without a time zone (yyyy-MM-ddTHH:mm:ss).
- The CLI returns raw values. Check the raw format of a field type (for example checkbox values) on a test device before comparing against it.

## Locating the CLI

There is no PowerShell module on macOS. Scripts call the ninjarmm-cli binary, which is not on the PATH. Define its path once, from the agent's data-folder variable with the standard location as a fallback, and check that it exists:

```zsh
readonly NINJA_CLI="${NINJA_DATA_PATH:-/Applications/NinjaRMMAgent/programdata}/ninjarmm-cli"

if [[ ! -x "$NINJA_CLI" ]]; then
    log_error "ninjarmm-cli not found at ${NINJA_CLI}. Is the NinjaOne agent installed?"
    exit 1
fi
```

## Device Custom Field Commands

```zsh
# Read a value
value="$("$NINJA_CLI" get fieldName)"

# Write a value
"$NINJA_CLI" set fieldName "$value"

# List the options of a dropdown or multi-select field
"$NINJA_CLI" options fieldName

# Write multi-line output from standard input
some_command | "$NINJA_CLI" set --stdin fieldName
```

The CLI exits with 0 on success and 1 on error. Check the result so that a failed write fails the script:

```zsh
if ! "$NINJA_CLI" set lastBackupStatus "$backup_status"; then
    log_error "Failed to write lastBackupStatus."
    exit 1
fi
log_info "Wrote lastBackupStatus: ${backup_status}"
```

## Documentation Field Commands

Quote template and document names that contain spaces.

```zsh
# List templates, and the documents for one template
"$NINJA_CLI" templates
"$NINJA_CLI" documents "template name"

# Read and write a field in a specific document
"$NINJA_CLI" get "template name" "document name" fieldName
"$NINJA_CLI" org-set "template name" "document name" fieldName "value"

# Shorthand for templates that have a single document
"$NINJA_CLI" get "template name" fieldName
"$NINJA_CLI" org-set "template name" fieldName "value"

# Clear a field
"$NINJA_CLI" org-clear "template name" "document name" fieldName
```

## Field Size Limits

```text
Text        200 characters
MultiLine   10,000 characters
Secure      200 characters by default (see note)
WYSIWYG     200,000 characters; collapsed in the UI above 10,000
```

Writes over the limit are truncated or rejected. Some NinjaOne versions allow a longer maximum for secure fields; treat 200 characters as the safe limit unless the field is known to allow more.

## Writing WYSIWYG Fields

Read NINJAONE-WYSIWYG.md for the HTML and CSS that NinjaOne renders. On macOS:

- Pipe the HTML to the CLI with the stdin flag. This handles large content and avoids argument-length and quoting problems.
- Use printf rather than echo, because the zsh echo builtin interprets backslashes.
- HTML-encode every dynamic value before inserting it.

```zsh
html_escape() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    text="${text//\"/&quot;}"
    printf '%s' "$text"
}

computer_name="$(html_escape "$(scutil --get ComputerName)")"
checked_at="$(date '+%Y-%m-%d %H:%M:%S')"

html="<div class=\"card flex-grow-1\">
  <div class=\"card-title-box\"><div class=\"card-title\">Status</div></div>
  <div class=\"card-body\">
    <p><b>Computer:</b> ${computer_name}</p>
    <p><b>Last check:</b> ${checked_at}</p>
  </div>
</div>"

if ! printf '%s\n' "$html" | "$NINJA_CLI" set --stdin statusReport; then
    log_error "Failed to write statusReport."
    exit 1
fi
```

## Common Mistakes (Custom Fields on macOS)

1. Using custom fields from the default user context. The script must run as root.
2. Calling ninjarmm-cli by bare name. It is not on the PATH.
3. Using GUIDs from dropdown or multi-select fields as if they were option names. Map them with the options command.
4. Leaving template or document names that contain spaces unquoted.
5. Ignoring the CLI exit code, so a failed write goes unnoticed.
6. Exceeding a field's character limit.

# Shared RMM Script Conventions (NinjaOne / Action1)

These conventions apply to ALL RMM scripts regardless of platform.

## Non-Interactive Execution

Scripts run unattended via the RMM agent. There is no terminal or interactive session available.

- **Data input** MUST come from environment variables, command-line parameters, or configuration files
- **NEVER** use interactive prompts (`Read-Host`, `read`, `select`, `Get-Credential`, `osascript` dialogs)
- **NEVER** create GUI pop-ups or modal dialogs
- Scripts must handle missing input gracefully with clear error messages, not hangs

> **Note:** When running as the logged-in user (not SYSTEM/root), a user session exists on the machine but the script still has no interactive terminal. Do not confuse "user context" with "interactive" — the script is still headless.

## Execution Context Awareness

RMM scripts can run as either the system account (SYSTEM on Windows, root on Linux/macOS) or the logged-in user. The execution context fundamentally changes what the script can and cannot do.

### Context Validation

Scripts SHOULD validate they are running in the expected context and fail fast with a clear error if not. This prevents silent failures when a script is misconfigured in the RMM console.

**Windows (PowerShell):**
```powershell
# Fail if running as SYSTEM when user context is required
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($CurrentUser -match '\\SYSTEM$' -or $CurrentUser -eq 'NT AUTHORITY\SYSTEM') {
    Write-Error "This script must run as the logged-in user, not SYSTEM. Change the execution context in NinjaOne."
    exit 1
}
```

```powershell
# Fail if running as a user when SYSTEM context is required
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
if ($CurrentUser -notmatch '\\SYSTEM$' -and $CurrentUser -ne 'NT AUTHORITY\SYSTEM') {
    Write-Error "This script must run as SYSTEM, not '$CurrentUser'. Change the execution context in NinjaOne."
    exit 1
}
```

**Linux (bash):**
```bash
# Fail if not running as root
if [[ "$(id -u)" -ne 0 ]]; then
    log_error "This script must run as root. Change the execution context in NinjaOne."
    exit 1
fi
```

**macOS (zsh):**
```zsh
# Fail if running as root when user context is required
if [[ "$(id -u)" -eq 0 ]]; then
    log_error "This script must run as the logged-in user, not root. Change the execution context in NinjaOne."
    exit 1
fi
```

### User-Context Limitations (NinjaOne)

When running as the logged-in user:

- **NinjaOne custom fields are NOT accessible.** The `ninjarmm-cli` binary and the PowerShell module (`Get-NinjaProperty`, `Set-NinjaProperty`, etc.) only function under the SYSTEM/root context. This applies to **all platforms** (Windows, macOS, Linux).
- If you need to capture user-specific data (e.g., `whoami /upn`, user environment details) and write it to a custom field, the script must run as SYSTEM and use a "run as user" technique (e.g., PowerShell's `Invoke-Command` with the user's token, or a scheduled task trick) to gather the user-context data, then write to the custom field from the SYSTEM context.
- Mapped drives, Credential Manager, HKCU registry, user profile operations, and printer mappings are all per-user and require user context.
- **Windows Server (RDP) — unreliable user targeting.** On Windows Server with Remote Desktop Services, NinjaOne's "run as logged-in user" does not allow targeting a specific user session. It will pick either the console session or an arbitrary RDP session, meaning user-centric scripts (e.g., clearing app caches, modifying HKCU) may execute against the **wrong user**. Windows user-context scripts should include a Server OS guard that blocks execution on Windows Server unless the user explicitly requests otherwise.

## NinjaOne Script Variables (Environment Variables)

NinjaOne passes ad-hoc inputs to scripts via **environment variables**. These are distinct from Custom Fields and are configured per-script in the NinjaOne UI.

### Naming Convention

NinjaOne uses **camelCase** for environment variable names. The display name in the GUI is converted automatically:

| GUI Display Name | Environment Variable |
|---|---|
| Drive Letter | `$env:driveLetter` (PS) / `$driveLetter` (bash/zsh) |
| Drive Pass | `$env:drivePass` (PS) / `$drivePass` (bash/zsh) |
| Target Path | `$env:targetPath` (PS) / `$targetPath` (bash/zsh) |

### Supported Variable Types

| Type | Value Format | Example |
|---|---|---|
| String / Text | String | `"Hello World"` |
| Integer | Whole number | `42` |
| Decimal | Floating-point number | `3.14` |
| Checkbox | String `"true"` or `"false"` | `"true"` |
| Date | ISO 8601 (time zeroed out) | `"2026-02-09T00:00:00"` |
| Date and Time | ISO 8601 | `"2026-02-09T14:30:00"` |
| Dropdown | String (selected option) | `"Option A"` |
| IP Address | String | `"192.168.1.1"` |

> **Note:** Integer and Decimal arrive as their numeric types. Checkbox arrives as the string `"true"` or `"false"` (not a boolean — compare or cast accordingly). Dates arrive as ISO 8601 strings. Everything else is a string.

### Mandatory vs Optional

NinjaOne allows you to mark script variables as mandatory or optional in the UI. However, scripts should still validate that required inputs are present and non-empty, as a defence-in-depth measure.

```powershell
# Validate required environment variable inputs
$MissingParams = @()
if ([string]::IsNullOrWhiteSpace($env:serverName)) { $MissingParams += 'serverName' }
if ([string]::IsNullOrWhiteSpace($env:targetPath)) { $MissingParams += 'targetPath' }

if ($MissingParams.Count -gt 0) {
    Write-Error "Missing required script variable(s): $($MissingParams -join ', ')"
    exit 1
}
```

### Defined Parameters (Script Arguments)

NinjaOne also supports passing inputs via **defined parameters** (traditional script arguments). This is primarily used when converting pre-existing scripts into NinjaOne automations where the script already uses a `param()` block (PowerShell) or `getopts` (bash/zsh).

- You specify a list of commonly used parameters in the NinjaOne script settings
- These map directly to the script's existing parameter definitions
- You **cannot** mark individual defined parameters as mandatory or optional in the NinjaOne UI — that must be handled by the script itself
- Environment variables and defined parameters can coexist, but environment variables are the preferred approach for new scripts

## NinjaOne Agent Environment Variables (`$env:NINJA_*`)

The NinjaOne agent injects these environment variables on every platform (Windows, macOS, Linux). They are available in all script types (PowerShell, Batch, Shell, VBScript) and require a **device reboot** to refresh if values change.

| Variable | Description | Common Use |
|---|---|---|
| `NINJA_ORGANIZATION_NAME` | Organisation name | Multi-tenant logging, conditional logic |
| `NINJA_ORGANIZATION_ID` | Organisation ID (integer) | API calls, filtering |
| `NINJA_COMPANY_NAME` | Company name | May differ from org name |
| `NINJA_LOCATION_NAME` | Location name | Site-specific logic |
| `NINJA_LOCATION_ID` | Location ID (integer) | API calls, filtering |
| `NINJA_AGENT_NODE_ID` | Node ID on NinjaOne server | API device identification |
| `NINJA_AGENT_MACHINE_ID` | Machine ID on NinjaOne server | Unique device identifier |
| `NINJA_DATA_PATH` | Agent data folder (scripts, logs, downloads) | Locating `ninjarmm-cli` on Linux/macOS |
| `NINJA_EXECUTING_PATH` | Agent install directory | Referencing agent binaries |
| `NINJA_AGENT_VERSION_INSTALLED` | Installed agent version | Version-gated feature checks |
| `NINJA_PATCHER_VERSION_INSTALLED` | Installed patcher version | Patcher compatibility checks |
| `NINJA_AGENT_PASSWORD` | Agent password for session key auth | **NEVER log in plain text** |

### Platform Access Syntax

| Platform | Syntax | Example |
|---|---|---|
| PowerShell | `$env:VARIABLE_NAME` | `$env:NINJA_ORGANIZATION_NAME` |
| Batch | `%VARIABLE_NAME%` | `%NINJA_ORGANIZATION_NAME%` |
| bash / zsh | `$VARIABLE_NAME` | `$NINJA_ORGANIZATION_NAME` |

### Best Practices

- Always include `NINJA_ORGANIZATION_NAME` in log output for multi-tenant environments — this is essential when debugging scripts across 60+ client tenants
- Use `NINJA_DATA_PATH` to locate the `ninjarmm-cli` binary portably (especially on Linux/macOS where the path differs)
- Use `NINJA_AGENT_NODE_ID` when making API calls that target the current device
- Never log or output `NINJA_AGENT_PASSWORD` — use it only where session key auth is required
- These variables are only available when running via the NinjaOne agent — they won't exist in manual terminal sessions or non-NinjaOne RMM platforms

## NinjaOne Device Tags

NinjaOne tags classify devices beyond roles and custom fields. Tags enable device searches, automation conditions, and filtered queries.

**Important constraints:**
- Tag operations **only work within automation scripts** running on the NinjaOne agent — not in manual terminal sessions
- Tags must be **pre-created in the NinjaOne web interface** before scripts can assign them
- Scripts cannot create new tag definitions — only assign/remove existing ones
- Tag names are **case-sensitive**

### PowerShell Module Cmdlets (Windows)

```powershell
# Get all tags on current device (returns string array)
$Tags = Get-NinjaTag

# Assign a tag (throws if tag name doesn't exist in org)
Set-NinjaTag -Name 'Production'

# Remove a tag (throws if tag name doesn't exist in org)
Remove-NinjaTag -Name 'Development'

# Conditional pattern — check before acting
$Tags = Get-NinjaTag
if ($Tags -contains 'Maintenance Approved') {
    # ... do maintenance work ...
    Remove-NinjaTag -Name 'Maintenance Approved'
    Set-NinjaTag -Name 'Maintenance Completed'
}
```

### CLI Commands (All Platforms)

```bash
# Get all tags (one per line)
ninjarmm-cli tag-get

# Assign a tag
ninjarmm-cli tag-set "Production"

# Remove a tag
ninjarmm-cli tag-clear "Development"
```

On Linux, prefix with `./` or use full path. On macOS, use `/Applications/NinjaRMMAgent/programdata/ninjarmm-cli`.

### Tag Best Practices

- Always wrap tag operations in try/catch (PowerShell) or check exit codes (bash/zsh)
- Check current tags with `Get-NinjaTag` / `tag-get` before adding to avoid redundant operations
- Remove temporary tags (e.g., "Maintenance Approved") after the automation completes
- Prefer PowerShell cmdlets over CLI on Windows for better error handling and type safety
- Tag operations require SYSTEM/root context (same as custom fields)

## Security Requirements

- **NEVER** store plain-text credentials in scripts
- If credentials are needed, provide a placeholder with guidance on secure alternatives (encrypted files, vault services, environment variables from RMM, macOS Keychain where appropriate)
- For NinjaOne, use **Secure** script variable types for passwords — these are masked in the UI and logs
- Flag any commands that are overly permissive or risky

## Idempotency

Scripts MUST be safe to run multiple times without adverse effects:

- Check if a resource exists before creating it
- Check if a setting is already applied before changing it
- Check if a file exists before acting on it
- Use conditional logic to avoid duplicate operations

### Safe Replacement vs Refusal

When a resource already exists, determine whether it is **safe to replace** or whether the script should **refuse and exit**:

- If the existing resource is the same type as what the script would create (e.g., an existing network mapping on the same drive letter), it is generally safe to remove and recreate it
- If the existing resource is a different type or could cause data loss (e.g., a physical disk at the requested drive letter, a system directory at the target path), the script MUST refuse with a clear error
- Always validate the nature of an existing resource before overwriting — don't just check "does it exist?"

## Input Validation and Destructive Action Safeguards

User-supplied inputs (whether from environment variables, parameters, or custom fields) should be validated against the current system state before the script takes action. This prevents accidental damage from misconfigured inputs.

Examples:
- Before mapping a network drive to a letter, verify the letter isn't already a physical/fixed disk
- Before deleting a directory, verify it isn't a system path
- Before modifying a service, verify it exists and is the expected service
- Before changing a registry key, verify the path is in the expected hive

The goal is to **fail safely** when inputs would cause unintended consequences, rather than blindly trusting the input.

## Exit Codes

Scripts MUST use consistent exit codes so the RMM platform can determine success or failure:

| Exit Code | Meaning | RMM Behaviour |
|---|---|---|
| `0` | Success | Script marked as successful |
| `1` | General failure | Script marked as failed |
| `2+` | Specific failure codes (optional) | Script marked as failed |

- Always `exit 0` on success (explicitly or implicitly)
- Always `exit 1` (or non-zero) on failure
- NinjaOne uses the exit code to determine pass/fail in automation policies and conditions
- Every `Write-Error` or error path should be followed by a non-zero exit

## Logging for RMM Capture

RMM tools capture stdout as script output and stderr as errors:

- **Success messages** → stdout (`Write-Output` / `echo`)
- **Error messages** → stderr (`Write-Error` / `echo "ERROR: ..." >&2`)
- Messages should be clear, traceable, and include context (what was attempted, what happened)

## Code Review Mode

When the user provides an existing script (rather than asking for a new one), shift to **expert review and critique**:

1. Check platform/version compatibility
2. Check RMM compliance (non-interactive, error handling, logging)
3. Check privilege context (is it running as expected user/root/SYSTEM?)
4. Flag security issues (plain-text credentials, unquoted variables, over-permissive actions)
5. Check for input validation and destructive action safeguards
6. Identify efficiency and readability improvements
7. Check for idempotency issues
8. Verify exit codes are used correctly

Provide the corrected/improved script alongside the analysis.

## RMM Data Storage (Custom Fields / Custom Attributes)

RMM platforms provide mechanisms to store and retrieve per-device data from scripts. When the user's script needs to read or write RMM-managed data, use the correct platform-specific approach.

**IMPORTANT:** On NinjaOne, custom field access (both read and write) is only available when the script runs as **SYSTEM** (Windows) or **root** (Linux/macOS). Scripts running as the logged-in user cannot use custom fields. See "User-Context Limitations" above.

### NinjaOne: Custom Fields & Documentation Fields

NinjaOne provides the `ninjarmm-cli` binary and (on Windows) a PowerShell module for interacting with custom fields. See the platform-specific SKILL.md files for exact syntax — Windows uses PowerShell cmdlets, while macOS and Linux call the CLI binary directly.

Key concepts:
- **Global/Role custom fields** — Per-device fields (get/set by field name)
- **Documentation fields** — Organisational fields stored per-template/per-document (get/set by template + document + field name)
- **Secure fields** — Write-only for documentation; only accessible during automation execution (not via web/local terminal)
- **Field types** — Checkbox, Date, DateTime, Decimal, Dropdown, Email, Integer, IP Address, MultiLine, MultiSelect, Phone, Secure, Text, Time, URL, WYSIWYG, Attachment (read-only via CLI)
- **Dropdown/MultiSelect** — Values are GUIDs unless you use the newer typed PowerShell commands (Windows) or query options first (CLI)
- **Timestamps** — Unix epoch seconds or ISO format (yyyy-MM-ddTHH:mm:ss)
- **Context requirement** — SYSTEM/root only. Will not function under user context.

### Action1: Custom Attributes

Action1 provides up to 10 custom attributes per endpoint (Windows only). Set them from scripts using:

```powershell
Action1-Set-CustomAttribute 'AttributeName' 'Value'
```

There is no `Action1-Get-CustomAttribute` — attributes are write-only from scripts. Reading is done via the Action1 console, API, or reports.

Custom attributes are simpler than NinjaOne custom fields — they're string-only key-value pairs with no type enforcement.

## Response Structure

For every request, provide:

1. **The Script** — Complete, fully commented, production-ready code
2. **Technical Explanation** — Concise paragraph-form explanation of what it does, how it meets RMM/platform constraints, and any security or environmental considerations

For cross-platform translation requests, add:

3. **Cross-Platform Translation Notes** — Explain conceptual differences between platforms, mapping commands and approaches, with special attention to privilege differences

## Common Mistakes (Cross-Platform)

These are recurring errors that affect scripts across all platforms when deployed via NinjaOne/Action1.

1. **Checkbox comparison against the wrong value** — Checkbox script variables send `"true"` or `"false"` as strings, not booleans. In PowerShell, `if ($env:EnableFeature)` is always `$true` for any non-empty string. Use `$env:EnableFeature -eq 'true'` instead. In bash/zsh, use `[[ "$enableFeature" == "true" ]]`.

2. **Not handling empty strings for non-mandatory variables** — Non-mandatory NinjaOne script variables arrive as empty strings `""`, not `$null`. Direct type casts like `[int]$env:Port` throw on empty strings. Always guard with `[string]::IsNullOrWhiteSpace()` (PowerShell) or `[[ -z "${varName:-}" ]]` (bash/zsh) before converting.

3. **Naming conflicts with system environment variables** — If a NinjaOne script variable shares a name with an existing system environment variable (e.g., `PATH`, `TEMP`, `HOME`), the script will fail or use the wrong value. Prefix custom variables to avoid collisions.

4. **Assuming custom fields work in user context** — `ninjarmm-cli`, `Get-NinjaProperty`, and `Set-NinjaProperty` only function under SYSTEM (Windows) or root (Linux/macOS). They silently fail or error when run as the logged-in user. If you need user-context data in a custom field, run as SYSTEM and use a "run as user" technique to gather the data.

5. **Dropdown/MultiSelect returning GUIDs instead of friendly names** — Without the `-Type` parameter on `Get-NinjaProperty` / `Set-NinjaProperty`, dropdown and multi-select fields return raw GUIDs. Always specify `-Type 'Dropdown'` or `-Type 'MultiSelect'` for human-readable values. On Linux/macOS (CLI only), use `ninjarmm-cli options fieldName` to map GUIDs to names.

6. **Forgetting `-Depth` on `ConvertTo-Json`** — PowerShell's `ConvertTo-Json` defaults to depth 2. Nested objects (e.g., API request bodies with sub-objects) are silently truncated to `"System.Collections.Hashtable"`. Use `-Depth 10` for complex structures.

7. **Using `$0` or `$(basename "$0")` for script name on NinjaOne** — NinjaOne copies scripts to a temporary path before execution, so `$0` resolves to a meaningless generated filename. Combined with `set -u` (bash/zsh), an empty `$0` can crash the script immediately. Always hardcode `SCRIPT_NAME` to a descriptive constant.

8. **DateTime parsing without timezone handling** — NinjaOne Date/Time script variables use ISO 8601 with timezone offsets (e.g., `2024-01-15T00:00:00.000+00:00`). Parsing with `[DateTime]::Parse($value)` without `DateTimeStyles.RoundtripKind` loses timezone info and can shift the time. Use `[DateTime]::Parse($value, $null, [System.Globalization.DateTimeStyles]::RoundtripKind)`.

9. **Special characters in script variable names or values** — NinjaOne does not support these characters in script variables: `Å Ä Ö & | ; $ > < \` !`. Scripts using them fail at runtime without a clear error.

10. **Exceeding character limits on custom fields** — Text fields: 200 chars. MultiLine: 10,000 chars. Secure: 200–10,000 chars (configurable). WYSIWYG: 200,000 chars. WYSIWYG fields auto-collapse above 10,000 chars. Writes exceeding limits are silently truncated or rejected.
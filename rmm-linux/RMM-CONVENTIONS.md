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

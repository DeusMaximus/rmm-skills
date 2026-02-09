# Shared RMM Script Conventions (NinjaOne / Action1)

These conventions apply to ALL RMM scripts regardless of platform.

## Non-Interactive Execution

Scripts run unattended in the background via RMM agent. There is no user session, no terminal, no GUI.

- **Data input** MUST come from environment variables, command-line parameters, or configuration files
- **NEVER** use interactive prompts (Read-Host, read, select, Get-Credential, osascript dialogs)
- **NEVER** create GUI pop-ups or modal windows
- Scripts must handle missing input gracefully with clear error messages, not hangs

## Security Requirements

- **NEVER** store plain-text credentials in scripts
- If credentials are needed, provide a placeholder with guidance on secure alternatives (encrypted files, vault services, environment variables from RMM, macOS Keychain where appropriate)
- Flag any commands that are overly permissive or risky

## Idempotency

Scripts MUST be safe to run multiple times without adverse effects:

- Check if a resource exists before creating it
- Check if a setting is already applied before changing it
- Check if a file exists before acting on it
- Use conditional logic to avoid duplicate operations

## Logging for RMM Capture

RMM tools capture stdout as script output and stderr as errors:

- **Success messages** → stdout (Write-Output / echo)
- **Error messages** → stderr (Write-Error / echo "ERROR: ..." >&2)
- Messages should be clear, traceable, and include context (what was attempted, what happened)

## Code Review Mode

When the user provides an existing script (rather than asking for a new one), shift to **expert review and critique**:

1. Check platform/version compatibility
2. Check RMM compliance (non-interactive, error handling, logging)
3. Check privilege context (is it running as expected user/root/SYSTEM?)
4. Flag security issues (plain-text credentials, unquoted variables, over-permissive actions)
5. Identify efficiency and readability improvements
6. Check for idempotency issues

Provide the corrected/improved script alongside the analysis.

## RMM Data Storage (Custom Fields / Custom Attributes)

RMM platforms provide mechanisms to store and retrieve per-device data from scripts. When the user's script needs to read or write RMM-managed data, use the correct platform-specific approach.

### NinjaOne: Custom Fields & Documentation Fields

NinjaOne provides the `ninjarmm-cli` binary and (on Windows) a PowerShell module for interacting with custom fields. See the platform-specific SKILL.md files for exact syntax — Windows uses PowerShell cmdlets, while macOS and Linux call the CLI binary directly.

Key concepts:
- **Global/Role custom fields** — Per-device fields (get/set by field name)
- **Documentation fields** — Organisational fields stored per-template/per-document (get/set by template + document + field name)
- **Secure fields** — Write-only for documentation; only accessible during automation execution (not via web/local terminal)
- **Field types** — Checkbox, Date, DateTime, Decimal, Dropdown, Email, Integer, IP Address, MultiLine, MultiSelect, Phone, Secure, Text, Time, URL, WYSIWYG, Attachment (read-only via CLI)
- **Dropdown/MultiSelect** — Values are GUIDs unless you use the newer typed PowerShell commands (Windows) or query options first (CLI)
- **Timestamps** — Unix epoch seconds or ISO format (yyyy-MM-ddTHH:mm:ss)

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

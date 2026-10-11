# Action1 on Windows

Read this file instead of NINJAONE.md when the user says the script is for Action1.

## Differences From NinjaOne

- Action1 does not support CmdletBinding or param blocks. A script that contains them fails. Omit both, and take input from environment variables or from constants declared at the top of the script.
- None of the NinjaOne features are available: no Ninja cmdlets, no ninjarmm-cli, no NINJA agent environment variables, no device tags and no WYSIWYG fields.
- The template assumes the script runs as SYSTEM, as in the original guidance for this skill. Confirm the run context with the user before writing per-user logic.
- All other rules still apply: CORE-CONVENTIONS.md and the PowerShell 5.1 baseline in SKILL.md.

## Template

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    One-line summary of what the script does.
.DESCRIPTION
    What the script checks or changes, and which inputs it expects.
.NOTES
    Context:    Runs as SYSTEM via Action1.
    Exit codes: 0 = success, 1 = failure.
#>

# Action1 does not support CmdletBinding or param blocks.
# Take input from environment variables or the constants below.

$ErrorActionPreference = 'Stop'

# --- Configuration ---
$TargetPath = 'C:\ProgramData\ExampleVendor'

function Write-LogInfo {
    param([string]$Message)
    Write-Output "[INFO] $Message"
}

function Write-LogError {
    param([string]$Message)
    # -ErrorAction Continue stops Write-Error from throwing under the Stop preference,
    # so the explicit exit code that follows still reaches Action1.
    Write-Error -Message "ERROR: $Message" -ErrorAction Continue
}

# --- Validate execution context ---
if (-not [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    Write-LogError 'This script must run as SYSTEM.'
    exit 1
}

# --- Main ---
try {
    # Main logic here

    exit 0
}
catch {
    Write-LogError "Unexpected failure: $($_.Exception.Message)"
    exit 1
}
```

## Custom Attributes

Action1 provides up to 10 custom attributes per endpoint, on Windows only. They are simple string key-value pairs with no type enforcement.

- Scripts can set attributes but cannot read them. There is no command to get an attribute; read them from the Action1 console, API or reports.
- Values are strings. Convert numbers and booleans to text before setting them.

```powershell
Action1-Set-CustomAttribute 'AttributeName' 'Value'
```

Work out the value first, then set it, so that the logic stays readable and testable:

```powershell
$SystemDrive = Get-PSDrive -Name $env:SystemDrive.Substring(0, 1)
$FreeGB = [math]::Round($SystemDrive.Free / 1GB, 1)

if ($FreeGB -lt 5) { $DriveStatus = 'Low' } else { $DriveStatus = 'Normal' }

Action1-Set-CustomAttribute 'DriveSpaceStatus' $DriveStatus
Write-Output "[INFO] DriveSpaceStatus set to $DriveStatus ($FreeGB GB free)."
```

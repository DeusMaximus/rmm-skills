# NinjaOne on Windows

Read this file for every Windows script that runs through NinjaOne. It covers the script templates, run-as behaviour, script variables, and the environment variables that the agent provides. Custom fields, tags and WYSIWYG fields have their own reference files.

## Run-As Behaviour

NinjaOne runs Windows scripts as SYSTEM (the default for this skill) or as the logged-in user.

- SYSTEM has full administrative rights and is the only context in which custom fields and tags work. It cannot see per-user resources such as HKCU, mapped drives, Credential Manager or the user's profile.
- The logged-in user context can reach those per-user resources, but custom fields and tags do not work. Neither the PowerShell module nor ninjarmm-cli.exe functions in this context.

### Windows Server and Remote Desktop

On Windows Server with Remote Desktop Services, the "run as logged-in user" option cannot target a particular session. NinjaOne picks the console session or an arbitrary RDP session, so a per-user script (for example one that clears an application cache or changes HKCU) can act on the wrong person. User-context scripts must therefore block execution on any server OS unless the user explicitly asks otherwise. The user-context template includes this guard.

### Collecting Per-User Data From a SYSTEM Script

When a script must gather per-user information and write it to a custom field, it has to run as SYSTEM, because only SYSTEM can write the field. Use one of these approaches:

- Register a temporary scheduled task that runs as the interactive user, have it write its result to a file under the ProgramData folder, read that file from the SYSTEM script, then remove the task and the file.
- Split the work into two NinjaOne scripts: a user-context script that writes its result to a shared file, and a SYSTEM script that reads the file and writes the custom field.
- Third-party tools such as PsExec are an option only where they are already approved and deployed in the environment.

## Template: SYSTEM Context

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    One-line summary of what the script does.
.DESCRIPTION
    What the script checks or changes, and which inputs it expects.
.NOTES
    Context:    Runs as SYSTEM via NinjaOne.
    Exit codes: 0 = success, 1 = failure.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-LogInfo {
    param([string]$Message)
    Write-Output "[INFO] $Message"
}

function Write-LogError {
    param([string]$Message)
    # -ErrorAction Continue stops Write-Error from throwing under the Stop preference,
    # so the explicit exit code that follows still reaches NinjaOne.
    Write-Error -Message "ERROR: $Message" -ErrorAction Continue
}

# --- Validate execution context ---
if (-not [System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem) {
    Write-LogError 'This script must run as SYSTEM. Change the run-as setting in NinjaOne.'
    exit 1
}

# --- Validate script variables ---
$MissingVariables = @()
if ([string]::IsNullOrWhiteSpace($env:targetPath)) { $MissingVariables += 'targetPath' }

if ($MissingVariables.Count -gt 0) {
    Write-LogError "Missing required script variable(s): $($MissingVariables -join ', ')"
    exit 1
}

# --- Main ---
try {
    Write-LogInfo "Organisation: $env:NINJA_ORGANIZATION_NAME"

    # Main logic here

    exit 0
}
catch {
    Write-LogError "Unexpected failure: $($_.Exception.Message)"
    exit 1
}
```

## Template: Logged-In User Context

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    One-line summary of what the script does.
.DESCRIPTION
    Runs as the logged-in user because it works with per-user resources
    (for example HKCU, mapped drives or Credential Manager).
    NinjaOne custom fields and tags are not available in this context.
.NOTES
    Context:    Runs as the LOGGED-IN USER via NinjaOne.
    Exit codes: 0 = success, 1 = failure.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-LogInfo {
    param([string]$Message)
    Write-Output "[INFO] $Message"
}

function Write-LogError {
    param([string]$Message)
    Write-Error -Message "ERROR: $Message" -ErrorAction Continue
}

# --- Validate execution context: must not be SYSTEM ---
$CurrentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
if ($CurrentIdentity.IsSystem) {
    Write-LogError "This script must run as the logged-in user, not SYSTEM. Set the run-as option in NinjaOne to 'Logged-in User'."
    exit 1
}

# --- Block server operating systems: NinjaOne cannot choose which RDP session runs this ---
$OperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
if ($OperatingSystem.ProductType -ne 1) {
    Write-LogError "Blocked on a server OS ($($OperatingSystem.Caption)). On RDP servers NinjaOne may run this in the wrong user's session. Remove this guard only after confirming the target user."
    exit 1
}

# --- Main ---
try {
    Write-LogInfo "Running as user: $($CurrentIdentity.Name)"

    # Main logic here

    exit 0
}
catch {
    Write-LogError "Unexpected failure: $($_.Exception.Message)"
    exit 1
}
```

A ProductType of 1 means a workstation operating system; 2 is a domain controller and 3 is a server.

## Script Variables

NinjaOne passes script inputs to the script as environment variables. They are configured on the script in the NinjaOne console and are separate from custom fields.

- The variable name is the display name converted to camelCase. For example, "Target Path" becomes targetPath and "Drive Letter" becomes driveLetter.
- Every script variable arrives as a string, whatever its type in the console. Validate it before converting it.
- An optional variable that was left blank arrives as an empty string. Converting an empty string to a number or date throws an error.
- Mark sensitive inputs as the Secure variable type. The value is masked in the console and logs, but still arrives in the script as plain text, so never write it to output.
- NinjaOne does not support the following characters in script variable names or values. Scripts that use them fail at run time without a clear error:

```text
Å  Ä  Ö  &  |  ;  $  >  <  `  !
```

How each variable type arrives and how to handle it:

```text
String or Text   any text                              use directly
Integer          digits, for example "42"              validate, then convert with [int]
Decimal          for example "3.14"                    validate, then convert with [decimal]
Checkbox         "true" or "false"                     compare with -eq 'true'
Date             ISO 8601, time zeroed                 parse with RoundtripKind (below)
Date and Time    ISO 8601, may include an offset       parse with RoundtripKind (below)
Dropdown         the selected option's text            use directly
IP Address       for example "192.168.1.1"             validate with [ipaddress]::TryParse
```

Checkbox values are strings, so any non-empty value, including "false", is truthy. Always compare the text:

```powershell
$EnableFeature = $env:enableFeature -eq 'true'
```

Validate all required variables together, then convert optional ones only when they have a value:

```powershell
$MissingVariables = @()
if ([string]::IsNullOrWhiteSpace($env:serverName)) { $MissingVariables += 'serverName' }
if ([string]::IsNullOrWhiteSpace($env:targetPath)) { $MissingVariables += 'targetPath' }

if ($MissingVariables.Count -gt 0) {
    Write-LogError "Missing required script variable(s): $($MissingVariables -join ', ')"
    exit 1
}

$Port = 443
if (-not [string]::IsNullOrWhiteSpace($env:portNumber)) {
    if (-not [int]::TryParse($env:portNumber, [ref]$Port)) {
        Write-LogError "portNumber must be a whole number, not '$($env:portNumber)'."
        exit 1
    }
}
```

Date values can include fractional seconds and a time-zone offset, for example 2024-01-15T00:00:00.000+00:00. Parse them with RoundtripKind so that the offset is not lost:

```powershell
$StartDate = [datetime]::Parse($env:startDate, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
```

## Defined Parameters

NinjaOne can also pass traditional script arguments, called defined parameters, into the param block. This is mainly for converting existing scripts. Use environment-variable script variables for new scripts.

- The NinjaOne console cannot mark a defined parameter as mandatory, so the script must validate it.
- Do not use the Mandatory parameter attribute. If the argument is missing, PowerShell tries to prompt for it, which fails in an unattended session. Validate in the script body instead.

```powershell
[CmdletBinding()]
param(
    [string]$ServerName,
    [int]$Port = 443
)

if ([string]::IsNullOrWhiteSpace($ServerName)) {
    Write-Error -Message 'ServerName parameter is required.' -ErrorAction Continue
    exit 1
}
```

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
NINJA_DATA_PATH                   Agent data folder: scripts, logs, downloads and ninjarmm-cli.exe.
NINJA_EXECUTING_PATH              Agent installation folder.
NINJA_AGENT_VERSION_INSTALLED     Installed agent version.
NINJA_PATCHER_VERSION_INSTALLED   Installed patcher version.
NINJA_AGENT_PASSWORD              Agent password for session-key authentication. Never write it to output.
```

```powershell
$Organisation = $env:NINJA_ORGANIZATION_NAME
if ([string]::IsNullOrWhiteSpace($Organisation)) { $Organisation = 'unknown organisation' }
Write-Output "[INFO] Organisation: $Organisation"
```

## Common Mistakes (NinjaOne on Windows)

1. Testing a checkbox variable for truthiness instead of comparing it with the text "true".
2. Converting an optional variable without first checking that it is not empty.
3. Parsing date variables without RoundtripKind, which can shift the time.
4. Using an unsupported special character in a script variable name or value.
5. Running a user-context script on a server without the server guard.
6. Expecting custom fields or tags to work in user context.
7. Leaving out context validation, so a script with the wrong run-as setting fails without a clear message.

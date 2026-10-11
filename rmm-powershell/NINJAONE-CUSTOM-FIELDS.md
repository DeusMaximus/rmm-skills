# NinjaOne Custom Fields on Windows

Read this file when a Windows script reads or writes NinjaOne custom fields or documentation fields, including WYSIWYG fields.

## Context Requirement

Custom fields, for both reading and writing, work only when the script runs as SYSTEM. In the logged-in user context, the PowerShell module cmdlets and ninjarmm-cli.exe do not work. To put per-user data into a field, run as SYSTEM and collect the data with a technique from NINJAONE.md.

## Field Concepts

- Device custom fields (global or role fields) belong to a device and are addressed by field name.
- Documentation fields belong to the organisation and are addressed by template name, document name and field name.
- Secure fields can be read only while an automation is running, not from the web or local terminal. Documentation secure fields are write-only.
- Dropdown and multi-select fields store option GUIDs. Pass the Type parameter to work with option names instead.
- Date and time values are stored as Unix epoch seconds or as ISO 8601 text without a time zone (yyyy-MM-ddTHH:mm:ss).

## Modern Cmdlets (Recommended)

NinjaOne deploys a PowerShell module to Windows agents automatically. Use its cmdlets rather than calling ninjarmm-cli.exe directly.

```powershell
# Read the raw value
$Value = Get-NinjaProperty -Name 'fieldName'

# Read with type conversion (option names for dropdowns, real dates and booleans)
$Choice = Get-NinjaProperty -Name 'fieldName' -Type 'Dropdown'

# Read a documentation field
$DocValue = Get-NinjaProperty -Name 'fieldName' -Type 'Text' -DocumentName 'templateName'

# Write a value
Set-NinjaProperty -Name 'fieldName' -Value 'newValue'

# Write with type conversion (option names to GUIDs, dates to epoch)
Set-NinjaProperty -Name 'fieldName' -Value 'Option1' -Type 'Dropdown'
```

Values accepted by the Type parameter:

```text
Attachment, Checkbox, Date, DateTime, Decimal, Device Dropdown, Device MultiSelect,
Dropdown, Email, Integer, IP Address, MultiLine, MultiSelect, Organization Dropdown,
Organization Location Dropdown, Organization Location MultiSelect,
Organization MultiSelect, Phone, Secure, Text, Time, WYSIWYG, URL
```

Wrap custom-field calls in try/catch. A failed write should be reported and should normally fail the script:

```powershell
try {
    Set-NinjaProperty -Name 'lastBackupStatus' -Value $Status -Type 'Text'
    Write-Output "[INFO] Wrote lastBackupStatus: $Status"
}
catch {
    Write-Error -Message "Failed to write lastBackupStatus: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
```

## Type Behaviour

- Without the Type parameter, dropdown and multi-select fields return GUIDs. Use the Dropdown or MultiSelect type to get option names.
- Without the Type parameter, checkbox fields return 1 or 0 rather than true or false. Use the Checkbox type for a real boolean, or compare against 1.

```powershell
$IsEnabled = Get-NinjaProperty -Name 'featureEnabled' -Type 'Checkbox'
```

## Legacy Commands

These still work and appear in older scripts. Prefer the modern cmdlets in new scripts.

```powershell
# Device custom fields
Ninja-Property-Get $AttributeName
Ninja-Property-Set $AttributeName $Value
Ninja-Property-Options $AttributeName
Ninja-Property-Clear $AttributeName

# Documentation fields
Ninja-Property-Docs-Templates
Ninja-Property-Docs-Names $TemplateId
Ninja-Property-Docs-Names "$TemplateName"
Ninja-Property-Docs-Get $TemplateId "$DocumentName" $AttributeName
Ninja-Property-Docs-Set $TemplateId "$DocumentName" $AttributeName "value"
Ninja-Property-Docs-Get-Single "templateName" "fieldName"
Ninja-Property-Docs-Set-Single "templateName" "fieldName" "new value"
Ninja-Property-Docs-Clear "templateId" "$DocumentName" $AttributeName
Ninja-Property-Docs-Clear-Single "templateName" "fieldName"
Ninja-Property-Docs-Options "templateId" "$DocumentName" $AttributeName
Ninja-Property-Docs-Options-Single "templateName" "fieldName"
```

## The CLI on Windows

The command-line tool is ninjarmm-cli.exe in the agent data folder (the NINJA_DATA_PATH variable). When capturing its output in a variable, add the direct-out flag, which makes standard output reliable at the cost of Unicode support:

```powershell
$NinjaCli = Join-Path -Path $env:NINJA_DATA_PATH -ChildPath 'ninjarmm-cli.exe'
$Value = & $NinjaCli get fieldName --direct-out
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

Read NINJAONE-WYSIWYG.md for the HTML and CSS that NinjaOne renders. On Windows:

- Write with Set-NinjaProperty and the WYSIWYG type.
- HTML-encode every dynamic value with the WebUtility class, which needs no extra assembly in PowerShell 5.1.
- Build HTML in a here-string, with the closing delimiter at the very start of its line.
- For content over 10,000 characters, pipe the HTML to ninjarmm-cli.exe with the stdin flag, or use the legacy Ninja-Property-Set-Piped command.

```powershell
$ComputerName = [System.Net.WebUtility]::HtmlEncode($env:COMPUTERNAME)
$CheckedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$Html = @"
<div class="card flex-grow-1">
  <div class="card-title-box">
    <div class="card-title"><i class="fas fa-server"></i>&nbsp;&nbsp;Status</div>
  </div>
  <div class="card-body">
    <p><b>Computer:</b> $ComputerName</p>
    <p><b>Last check:</b> $CheckedAt</p>
  </div>
</div>
"@

Set-NinjaProperty -Name 'statusReport' -Value $Html -Type 'WYSIWYG'
```

```powershell
$NinjaCli = Join-Path -Path $env:NINJA_DATA_PATH -ChildPath 'ninjarmm-cli.exe'
$Html | & $NinjaCli set --stdin statusReport
if ($LASTEXITCODE -ne 0) {
    Write-Error -Message "ninjarmm-cli failed to write statusReport (exit code $LASTEXITCODE)." -ErrorAction Continue
    exit 1
}
```

## Common Mistakes (Custom Fields on Windows)

1. Reading or writing fields from a user-context script.
2. Reading dropdown or multi-select fields without the Type parameter and getting GUIDs.
3. Testing a checkbox field read without the Type parameter as if it were a boolean. It returns 1 or 0.
4. Exceeding a field's character limit.
5. Writing a field without try/catch, so a failed write goes unnoticed.

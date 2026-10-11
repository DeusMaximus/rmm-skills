# NinjaOne Device Tags on Windows

Read this file when a Windows script reads, assigns or removes NinjaOne device tags. Tags classify devices beyond roles and custom fields, and they can drive device searches, automation conditions and filters.

## Constraints

- Tags work only when the script runs as SYSTEM, the same as custom fields.
- Tag commands work only inside automation scripts run by the NinjaOne agent, not in an interactive terminal session.
- A tag must already exist in the NinjaOne web console. Scripts can assign and remove existing tags, but cannot create new ones.
- Tag names are case-sensitive.

## Cmdlets

Use the PowerShell module cmdlets on Windows. They give better error handling than calling the CLI.

```powershell
# All tags on this device, as an array of strings
$Tags = Get-NinjaTag

# Assign a tag. Throws if the tag does not exist in the organisation.
Set-NinjaTag -Name 'Production'

# Remove a tag. Throws if the tag does not exist in the organisation.
Remove-NinjaTag -Name 'Development'
```

## Pattern

Read the current tags first so that the script only makes the changes it needs, wrap tag operations in try/catch, and remove temporary tags when the work is done.

```powershell
try {
    $Tags = @(Get-NinjaTag)

    if ($Tags -contains 'Maintenance Approved') {
        # Maintenance work here

        Remove-NinjaTag -Name 'Maintenance Approved'
        if ($Tags -notcontains 'Maintenance Completed') {
            Set-NinjaTag -Name 'Maintenance Completed'
        }
        Write-Output '[INFO] Maintenance completed and tags updated.'
    }
    else {
        Write-Output "[INFO] Tag 'Maintenance Approved' not present. No action taken."
    }
    exit 0
}
catch {
    Write-Error -Message "Tag operation failed: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
```

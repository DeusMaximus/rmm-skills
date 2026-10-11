---
name: rmm-powershell
description: Create and review Windows PowerShell 5.1 scripts specifically for NinjaOne or Action1 RMM deployment. ONLY use when the user explicitly mentions RMM, NinjaOne, Action1, or background agent deployment to Windows endpoints. Do NOT use for general PowerShell scripting.
metadata:
  author: DeusMaximus and Claude
  version: "2.0.0"
---

# RMM PowerShell Scripts (Windows)

You are a specialised, senior-level DevOps engineer and PowerShell expert. You write reliable, production-ready Windows PowerShell 5.1 scripts that run unattended on Windows endpoints through NinjaOne or Action1, and you review existing scripts for the same purpose.

This file decides when the skill applies, sets the Windows baseline, and tells you which reference files to read. The detailed rules are in those reference files.

## When This Skill Applies

Use this skill only when the request explicitly involves at least one of:

- NinjaOne, Action1 or another RMM platform by name
- A script described as running through an RMM, as a scheduled agent task, as a background agent job, or as deployed to endpoints
- A review of a script that the user says is for RMM deployment
- Translating an existing RMM script from macOS or Linux to Windows

## When This Skill Does Not Apply

- General PowerShell scripting, such as local automation, file processing or personal tasks
- Scripts the user will run by hand in a console or editor
- One-off commands and snippets
- PowerShell 7 scripts (this skill targets Windows PowerShell 5.1 only)

If it is unclear whether the script is for RMM deployment, ask before applying these rules.

## Reference Routing

Always read:

- CORE-CONVENTIONS.md, which covers unattended execution, security, validation, idempotency, exit codes, output, source integrity and the response structure.
- The RMM file: NINJAONE.md by default, or ACTION1.md when the user names Action1. Each contains the script templates for that RMM.

Read only when the task needs it:

- NINJAONE-CUSTOM-FIELDS.md when the script reads or writes NinjaOne custom fields or documentation fields.
- NINJAONE-WYSIWYG.md when the script writes HTML to a WYSIWYG field. Read NINJAONE-CUSTOM-FIELDS.md as well.
- NINJAONE-TAGS.md when the script reads, assigns or removes NinjaOne device tags.
- CODE-REVIEW.md when the user supplies an existing script to review or fix.
- CROSS-PLATFORM.md when translating a script from or to macOS or Linux.

Do not read references that the task does not need.

## Defaults

- RMM platform: NinjaOne, unless the user names Action1 or another RMM.
- Run context: SYSTEM.
- Language: Windows PowerShell 5.1, run by powershell.exe.

## Choosing the Execution Context

- Use SYSTEM for system-wide work: HKLM registry, services, software installation, machine configuration, and any NinjaOne custom field or tag access.
- Use the logged-in user for per-user resources: HKCU registry, mapped drives, Credential Manager, user profile files, per-user printers and user application settings.
- If the script needs per-user data and must also write a custom field, run it as SYSTEM and collect the user data with the technique in NINJAONE.md.
- User-context scripts must refuse to run on Windows Server by default. NINJAONE.md explains why and includes the guard.
- Every script validates its context at the top. The templates in NINJAONE.md and ACTION1.md include the check.

## PowerShell 5.1 Baseline

All code must run on Windows PowerShell 5.1. Never use PowerShell 6 or 7 features, including:

```text
$a ? $b : $c                        ternary operator
$a ?? $b    and    $a ??= $b        null-coalescing operators
$a?.Property    and    $a?[0]       null-conditional operators
cmd1 && cmd2    and    cmd1 || cmd2 pipeline chain operators
ForEach-Object -Parallel
ConvertFrom-Json -AsHashtable    and    ConvertFrom-Json -Depth
Get-Content -AsByteStream           (5.1 uses -Encoding Byte)
Invoke-WebRequest and Invoke-RestMethod parameters added in 6 or 7, such as
  -SkipCertificateCheck, -Authentication, -Form, -SkipHttpErrorCheck, -StatusCodeVariable
Join-String, Test-Json, Get-Error
$IsWindows, $IsLinux, $IsMacOS
```

Select-Object -Skip and -SkipLast are available in 5.1 and are fine to use. If you are unsure whether something exists in 5.1, use the older equivalent.

Behaviour in 5.1 that catches people out:

- Web requests: call Invoke-WebRequest with -UseBasicParsing every time, because without it the cmdlet depends on the Internet Explorer engine and fails on machines where Internet Explorer has never been run. Before any HTTPS request, enable TLS 1.2, because older systems default to protocols that most servers reject:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
```

- File encoding: Out-File and the redirection operator write UTF-16 LE, Set-Content writes the system ANSI code page, and the UTF8 encoding option writes a byte-order mark. Always pass -Encoding explicitly, and choose the value the consumer of the file expects.
- Native commands: the ErrorActionPreference setting does not apply to executables. Check the LASTEXITCODE automatic variable after every external command.
- Backslash is a literal character in PowerShell strings, not an escape character. The escape and line-continuation character is the backtick.

## Script Structure

Each RMM file contains the full template for that RMM. Every script follows the same structure:

1. A Requires statement for version 5.1 and comment-based help that states the run context and the exit codes.
2. CmdletBinding and param blocks on NinjaOne. Omit both on Action1 (see ACTION1.md).
3. The ErrorActionPreference variable set to Stop.
4. The Write-LogInfo and Write-LogError helper functions from the template.
5. Execution-context validation.
6. Input validation, reporting every missing input at once.
7. Main logic inside try/catch, ending in an explicit exit code.

## Error Handling

- Set the ErrorActionPreference variable to Stop at the start of the script.
- Wrap each critical block in try/catch, and use finally for clean-up. Catch messages must state what was being attempted and include the exception message.
- Report failures with Write-Error -ErrorAction Continue, then call exit with a non-zero code. Under the Stop preference, a plain Write-Error throws a terminating error, so the exit line after it never runs and a specific exit code is lost. The Write-LogError helper in the templates handles this.

```powershell
try {
    Set-Service -Name 'Spooler' -StartupType 'Automatic'
}
catch {
    Write-Error -Message "Failed to configure the Spooler service: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
```

## Coding Standards

- Use full cmdlet and parameter names, never aliases. For example, use Where-Object, ForEach-Object, Select-Object, Get-ChildItem and Remove-Item rather than their aliases.
- Name functions with approved verbs such as Get, Set, New, Remove, Test and Invoke.
- Use splatting for commands with many parameters. Do not chain lines with backticks.
- Do not call Write-Output or Write-LogInfo inside a function whose return value you use, because the message becomes part of the returned data. Return the data, and log in the caller.
- Pass -Depth 10 (or more) to ConvertTo-Json for nested objects. The default depth of 2 silently flattens deeper objects into type names.
- The closing delimiter of a here-string must be at the very start of its line, with nothing before it. An indented closing delimiter is a parse error.

## Source Integrity (PowerShell)

Apply the general rules in CORE-CONVENTIONS.md, plus the PowerShell-specific checks below.

### Display Artefacts

Some agent environments show these reference files, and files that users upload, with a backslash inserted before square brackets, most often before the closing bracket of a type literal. Chat interfaces can then alter that escaped text again when they display it. In one observed case, an escaped string type literal followed by a double colon was displayed as a single colon, which broke the script.

- Real PowerShell never has a backslash directly before the opening or closing bracket of a type literal or attribute. If you see one in a reference or an uploaded file, it is a display artefact. Do not reproduce it.
- Every double colon must come immediately after a closing square bracket, with the complete type name inside the brackets (for example string, int or System.Security.Principal.WindowsIdentity). A double colon, or a colon directly before a method name, with no type literal in front of it means the type literal has been lost.
- Comments start with a plain hash character, and block comments use the angle-bracket and hash pair.
- Keep legitimate backslashes in paths, account names and regular expressions. For example, these are correct as written:

```powershell
$AgentPath = 'C:\ProgramData\NinjaRMMAgent'
$SystemAccount = 'NT AUTHORITY\SYSTEM'
$Domain, $UserName = $AccountName.Split('\', 2)
```

Before presenting a script, read through every type literal, attribute and static call against these rules, even when a validation tool has passed.

### Validating PowerShell

Use the first option that is available:

1. A terminal with Windows PowerShell (powershell.exe) or PowerShell 7 (pwsh): parse the script file. This reports syntax errors only, so it does not replace the 5.1 feature list above, because a PowerShell 7 parser accepts 7-only syntax.
2. A bash sandbox without PowerShell: run the static scan below. It finds escaped brackets and hashes, and lost type literals, which are the faults that display layers introduce. It is not a full parser, so report "static scan only" in the deployment summary.
3. No tools: carry out the read-through above and report that no validation tool was available.

When you can create files, write the script to a .ps1 file, validate that file, and give the user the file as well as showing the script inline. A downloaded file does not pass through the chat display, so it is the authoritative copy.

Parse a script file with PowerShell:

```powershell
$Tokens = $null
$ParseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile('C:\Temp\Script.ps1', [ref]$Tokens, [ref]$ParseErrors) | Out-Null
$ParseErrors | ForEach-Object { $_.ToString() }
```

Static scan in bash, for a sandbox without PowerShell. It avoids square brackets, backslashes and hashes in its own source, so the same display artefacts cannot corrupt it. Review each hit, because a regular expression in the script may legitimately contain an escaped bracket.

```bash
awk '
function report(msg) { print FILENAME ":" FNR ": " msg ": " line; bad = 1 }
BEGIN { bs = sprintf("%c", 92); ob = sprintf("%c", 91); cb = sprintf("%c", 93); hs = sprintf("%c", 35); bad = 0 }
{
    line = $0
    if (index(line, bs ob)) report("backslash before an opening bracket")
    if (index(line, bs cb)) report("backslash before a closing bracket")
    if (index(line, bs hs)) report("backslash before a hash")
    n = length(line)
    for (i = 1; i != n + 1; i++) {
        if (substr(line, i, 1) != ":") continue
        before = (i == 1) ? " " : substr(line, i - 1, 1)
        if (substr(line, i, 2) == "::") {
            if (before != cb) report("double colon without a type literal before it")
            i++
            continue
        }
        after = substr(line, i + 1, 1)
        if (index(" (,=!", before)) {
            if (after != tolower(after)) report("colon before a method name; type literal missing")
        }
    }
}
END { exit bad }
' Script.ps1
```

When no full parse was possible, include this check in the deployment summary so that the operator can parse the script on Windows before pasting it into the RMM console. It reads the script from the clipboard:

```powershell
$ParseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseInput((Get-Clipboard -Raw), [ref]$null, [ref]$ParseErrors)
if ($ParseErrors) { $ParseErrors | ForEach-Object { "Line $($_.Extent.StartLineNumber): $($_.Message)" } } else { 'No syntax errors.' }
```

## Common Mistakes (PowerShell)

1. Using PowerShell 6 or 7 syntax. See the baseline list above.
2. Using aliases such as the question mark, the percent sign, select, gci or rm. They are harder to read in RMM output and depend on alias definitions.
3. Indenting the closing delimiter of a here-string. This often happens when building WYSIWYG HTML inside an if block or function.
4. Calling Invoke-WebRequest without -UseBasicParsing, or making HTTPS requests without enabling TLS 1.2.
5. Following Write-Error with exit while the Stop preference is in force. The exit never runs.
6. Ignoring LASTEXITCODE after running an executable.
7. Leaving out context validation, so a script configured with the wrong run-as setting fails silently.
8. Calling ConvertTo-Json on nested objects without -Depth.
9. Reproducing a display artefact: a backslash before a type-literal bracket, or a static call whose type literal has been lost.

## Example

Bad: aliases, no error handling, no output.

```powershell
gci C:\Temp | ? { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | rm -Force
```

Good: full cmdlet names, error handling, a clear result in the output, and an explicit exit code.

```powershell
$TargetPath = 'C:\Temp'
$CutoffDate = (Get-Date).AddDays(-30)

try {
    $StaleFiles = @(Get-ChildItem -Path $TargetPath -File | Where-Object { $_.LastWriteTime -lt $CutoffDate })

    if ($StaleFiles.Count -eq 0) {
        Write-Output "No files older than 30 days in $TargetPath. No changes needed."
    }
    else {
        foreach ($File in $StaleFiles) {
            Remove-Item -Path $File.FullName -Force
            Write-Output "Removed: $($File.FullName)"
        }
        Write-Output "Removed $($StaleFiles.Count) stale file(s) from $TargetPath."
    }
    exit 0
}
catch {
    Write-Error -Message "Failed to clean ${TargetPath}: $($_.Exception.Message)" -ErrorAction Continue
    exit 1
}
```

## Response

Follow the response structure in CORE-CONVENTIONS.md. For reviews, follow CODE-REVIEW.md. For translations, follow CROSS-PLATFORM.md.

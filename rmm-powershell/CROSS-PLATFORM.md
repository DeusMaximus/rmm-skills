# Cross-Platform Translation

Use this file when the user supplies an RMM script for one operating system and asks for the equivalent on another. It contains enough about every platform to read the source script, even if the skill for the source platform is not installed.

This file is shared and identical in all three skills. The canonical copy is in the rmm-powershell folder.

## Procedure

1. Work out what the source script is for. Describe the outcome it produces, not the commands it runs.
2. Identify differences in context and privilege. The default run context differs by platform (see below), and some tasks that need administrator rights on one platform need the user context on another.
3. Write the target script following the target platform's SKILL.md and RMM file. Do not carry over source-language idioms that the target platform handles differently.
4. Flag any behaviour that has no reliable equivalent on the target platform, instead of approximating it silently.

## Response

1. A one- to three-sentence summary of what the source script does.
2. The complete target script in a single fenced code block.
3. The deployment summary described in CORE-CONVENTIONS.md.
4. Translation notes: the concept mappings used, privilege and context differences, and any behaviour that differs or could not be reproduced.

## Default Run Context on NinjaOne

```text
Windows   SYSTEM
macOS     Logged-in user (root only when explicitly required)
Linux     root
```

On every platform, NinjaOne custom fields and tags work only as SYSTEM or root.

## Concept Mappings

Each entry lists the Windows, macOS and Linux equivalents. They are reference listings, not complete commands.

```text
Language and strict error handling
  Windows  PowerShell 5.1: $ErrorActionPreference = 'Stop' plus try/catch/finally
  macOS    zsh: set -euo pipefail plus explicit exit-code checks
  Linux    bash 4+: set -euo pipefail plus explicit exit-code checks

NinjaOne custom fields
  Windows  Get-NinjaProperty / Set-NinjaProperty (legacy: Ninja-Property-Get / Ninja-Property-Set)
  macOS    /Applications/NinjaRMMAgent/programdata/ninjarmm-cli get|set fieldName
  Linux    /opt/NinjaRMMAgent/programdata/ninjarmm-cli get|set fieldName

NinjaOne tags
  Windows  Get-NinjaTag / Set-NinjaTag / Remove-NinjaTag
  macOS    ninjarmm-cli tag-get | tag-set | tag-clear (full path as above)
  Linux    ninjarmm-cli tag-get | tag-set | tag-clear (full path as above)

Settings storage
  Windows  Registry: Get-ItemProperty / Set-ItemProperty / New-ItemProperty
  macOS    Property lists: defaults read|write, plutil (~/Library/Preferences, /Library/Preferences)
  Linux    Configuration files under /etc

System and hardware information
  Windows  Get-CimInstance (Win32_OperatingSystem, Win32_ComputerSystem, Win32_LogicalDisk)
  macOS    system_profiler, sysctl, sw_vers, diskutil
  Linux    /etc/os-release, /proc, /sys, lsblk, df, lshw, dmidecode

Services and daemons
  Windows  Get-Service / Start-Service / Stop-Service / Set-Service
  macOS    launchctl (print, bootstrap, bootout, kickstart; legacy load/unload)
  Linux    systemctl status|start|stop|enable|disable

Software installation
  Windows  winget, msiexec, vendor installers (choco only if already deployed)
  macOS    installer -pkg <file> -target /, vendor pkg or dmg (Homebrew only if confirmed present)
  Linux    apt-get (Debian/Ubuntu), dnf or yum (RHEL family)

Pending updates and patches
  Windows  Windows Update APIs, Get-HotFix / Win32_QuickFixEngineering
  macOS    softwareupdate --list
  Linux    apt-get -s upgrade, dnf updateinfo list sec

DNS cache flush
  Windows  Clear-DnsClientCache
  macOS    dscacheutil -flushcache and killall -HUP mDNSResponder (needs root)
  Linux    resolvectl flush-caches (systemd-resolved only)

Logs
  Windows  Event Log: Get-WinEvent
  macOS    Unified log: log show --predicate ... --last 1h
  Linux    journalctl, /var/log

Scheduling
  Windows  Task Scheduler: Register-ScheduledTask
  macOS    launchd agents and daemons (plist in ~/Library/LaunchAgents or /Library/LaunchDaemons)
  Linux    cron, systemd timers

Reading and writing files
  Windows  Get-Content / Set-Content / Add-Content
  macOS    cat, sed, tee, printf redirection
  Linux    cat, sed, tee, printf redirection

Current console user
  Windows  (Get-CimInstance Win32_ComputerSystem).UserName
  macOS    stat -f %Su /dev/console
  Linux    loginctl list-sessions or who (servers often have no logged-in user)

Run a command as the logged-in user from a system-context script
  Windows  Scheduled task registered for the interactive user, or a separate user-context RMM script
  macOS    launchctl asuser <uid> sudo -u <user> <command>, or su - <user> -c '<command>'
  Linux    runuser -u <user> -- <command>, or su - <user> -c '<command>'
```

## Translation Pitfalls

- Platform defaults differ. A Windows script that ran as SYSTEM usually becomes a macOS script that runs as the user, unless it changes system-wide state or uses custom fields.
- Do not translate an administrator task to sudo. On every platform, RMM scripts that need elevation are configured to run as the system account in the RMM console; sudo cannot prompt for a password in an unattended script. The exception is a root script using sudo -u to drop to a named user, which does not prompt.
- PowerShell returns objects, while shell commands return text. Parse command output defensively, and prefer machine-readable output options where they exist.
- Windows paths, case-insensitive comparisons and registry types do not carry over. Check case sensitivity when comparing strings and paths on macOS and Linux.
- The target platform's NinjaOne quirks apply. On macOS, NinjaOne ignores the shebang and runs scripts with a minimal PATH. On Linux, ninjarmm-cli is not on the PATH. See the target platform's NINJAONE.md.

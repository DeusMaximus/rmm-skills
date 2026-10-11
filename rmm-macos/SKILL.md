---
name: rmm-macos
description: Create and review zsh scripts specifically for NinjaOne or Action1 RMM deployment to macOS endpoints. ONLY use when the user explicitly mentions RMM, NinjaOne, Action1, or background agent deployment targeting Macs. Do NOT use for general shell scripting.
metadata:
  author: DeusMaximus and Claude
  version: "2.0.0"
---

# RMM macOS Scripts (zsh)

You are a specialised, senior-level macOS administrator and zsh expert. You write reliable, production-ready zsh scripts that run unattended on managed Macs (MacBooks, iMacs, Mac minis) through NinjaOne or Action1, and you review existing scripts for the same purpose.

This file decides when the skill applies, sets the macOS baseline, and tells you which reference files to read. The detailed rules are in those reference files.

## When This Skill Applies

Use this skill only when the request explicitly involves at least one of:

- NinjaOne, Action1 or another RMM platform by name, targeting macOS
- A script described as running through an RMM, as a scheduled agent task, as a background agent job, or as deployed to Mac endpoints
- A review of a script that the user says is for RMM deployment to Macs
- Translating an existing RMM script from Windows or Linux to macOS

## When This Skill Does Not Apply

- General zsh or bash scripting for personal use
- Scripts the user will run by hand in Terminal
- Homebrew automation, dotfile management or local development tasks
- macOS scripts that are not for RMM deployment

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
- CROSS-PLATFORM.md when translating a script from or to Windows or Linux.

Do not read references that the task does not need.

## Defaults

- RMM platform: NinjaOne, unless the user names Action1 or another RMM.
- Run context: the logged-in user, not root. This is the opposite of the Windows and Linux skills.
- Shell: zsh at /bin/zsh, on macOS Catalina (10.15) or later.

## Choosing the Execution Context

- Use the logged-in user for per-user work: user-level defaults domains, files in the user's home folder, and per-user printer mappings. A user-context script must succeed with standard privileges.
- Use root only when the user says so or the task cannot work otherwise: installing software, system-wide defaults or files, flushing DNS, and any NinjaOne custom field or tag access. When a script needs root, say so clearly in the deployment summary.
- Never use sudo to gain privileges. It cannot prompt for a password in an unattended script. If root is needed, the script is configured to run as root in the RMM console. (A root script may use sudo -u to drop to a named user; see NINJAONE.md.)
- If the script needs per-user data and must also write a custom field, run it as root and collect the user data with the technique in NINJAONE.md.
- Every script validates its context at the top. The templates in NINJAONE.md and ACTION1.md include the check.

## zsh Baseline

- Start every script with the zsh shebang, followed by the bash re-exec guard and PATH line from the NINJAONE.md template. NinjaOne ignores the shebang, and the guard is harmless on other RMMs.
- Use built-in macOS tools, such as defaults, plutil, pmset, softwareupdate, system_profiler, dscacheutil, launchctl, diskutil, scutil and networksetup.
- Do not rely on Homebrew or other third-party tools unless the user confirms they are installed. Homebrew is installed per user and is often missing on managed Macs.
- Prefer zsh-native or POSIX constructs over bash-only ones.
- zsh arrays start at index 1, not 0 as in bash. Code that indexes arrays behaves differently if it ever runs under bash, which is one more reason for the re-exec guard.
- Use printf rather than echo for output that may contain backslashes. The zsh echo builtin interprets backslash escape sequences by default.

## Script Structure

Each RMM file contains the full template for that RMM. Every script follows the same structure:

1. The zsh shebang and a header comment stating the purpose, run context and exit codes.
2. The bash re-exec guard, written in POSIX syntax.
3. An explicit PATH.
4. Strict mode, enabled with set -euo pipefail after the guard.
5. A hardcoded SCRIPT_NAME constant and the log_info and log_error functions.
6. Execution-context validation.
7. Input validation, reporting every missing input at once.
8. Main logic, ending in an explicit exit code.

## Error Handling

- Strict mode is mandatory: -e exits on any failing command, -u treats unset variables as errors, and pipefail makes a pipeline fail when any command in it fails.
- Reference optional variables with a default, such as an empty default, so that strict mode does not abort when they are unset.
- When a failure needs a specific message or exit code, test the command explicitly instead of relying on -e:

```zsh
if ! defaults write com.apple.screensaver askForPassword -int 1; then
    log_error "Failed to enable the screen saver password."
    exit 1
fi
```

## Coding Standards

- Double-quote every variable expansion and command substitution.
- Use clear, descriptive variable names, readonly for constants and local for function variables.
- Avoid cryptic one-liners.
- Notifications are acceptable only when non-blocking, through osascript display notification. Modal dialogs are not allowed.

## Source Integrity (zsh)

Apply the general rules in CORE-CONVENTIONS.md, plus:

- Keep the re-exec guard in POSIX form exactly as in the template: single square brackets and a parameter default, so that it works while the script is still running under bash.
- Keep legitimate backslashes, such as line continuations and escapes inside strings or regular expressions. Do not add a backslash before square brackets, hash characters, pipes, angle brackets or other operators.
- When zsh is available, syntax-check the script before presenting it:

```zsh
zsh -n /path/to/script.sh
```

## Common Mistakes (macOS)

1. Assuming root. NinjaOne macOS scripts run as the logged-in user by default.
2. Using sudo in a user-context script. It hangs or fails without a password prompt. Configure the script to run as root instead.
3. Relying on Homebrew without confirmation.
4. Leaving out the re-exec guard, so that zsh-only syntax silently misbehaves under bash.
5. Relying on the inherited PATH, so that tools in /usr/sbin and /sbin fail with "command not found".
6. Using echo for text that may contain backslashes.
7. Unquoted variable expansions, which break on paths with spaces.

## Example

Bad: no strict mode, no guard, not idempotent, assumes root for the pmset line, and no output.

```zsh
#!/bin/zsh
defaults write com.apple.screensaver askForPassword -int 1
pmset -a displaysleep 10
```

Good: the body of a user-context script built from the NINJAONE.md template. It changes only what needs changing and reports the result.

```zsh
current_value="$(defaults read com.apple.screensaver askForPassword 2>/dev/null || printf '0')"

if [[ "$current_value" == "1" ]]; then
    log_info "Screen saver password already enabled. No changes needed."
else
    defaults write com.apple.screensaver askForPassword -int 1
    defaults write com.apple.screensaver askForPasswordDelay -int 0
    log_info "Screen saver password enabled."
fi

exit 0
```

The display sleep setting changes power management for the whole system and needs root, so it belongs in a separate root-context script.

## Response

Follow the response structure in CORE-CONVENTIONS.md. For reviews, follow CODE-REVIEW.md. For translations, follow CROSS-PLATFORM.md.

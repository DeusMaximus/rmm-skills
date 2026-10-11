# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [2.0.0] - Unreleased

Restructure for progressive loading and for compatibility with skill importers that mangle Markdown (notably GitHub Copilot's). See `docs/v2-migration-report.md` for the full record.

### Changed (breaking)
- Skill names now match their folder and zip names: `rmm-powershell-scripts` → `rmm-powershell`, `rmm-macos-scripts` → `rmm-macos`, `rmm-linux-scripts` → `rmm-linux`. Remove the 1.x skills before installing 2.x, or both copies will be active.
- Each skill is split into a short `SKILL.md` router plus references that load only when needed: `CORE-CONVENTIONS.md`, `NINJAONE.md`, `NINJAONE-CUSTOM-FIELDS.md`, `NINJAONE-WYSIWYG.md`, `NINJAONE-TAGS.md`, `ACTION1.md`, `CODE-REVIEW.md`, `CROSS-PLATFORM.md`. Replaces `RMM-CONVENTIONS.md` and `NINJAONE-WYSIWYG-REFERENCE.md`.
- All code is in fenced blocks with a language tag and blank lines around them. Skill files contain no inline code, raw HTML or Markdown tables in prose.
- WYSIWYG reference examples are now language-neutral HTML; the platform-specific write commands are in each skill's `NINJAONE-CUSTOM-FIELDS.md`.
- Response structure now leads with the script, followed by a deployment summary (run context, variables, fields read/written, exit codes, limitations).
- macOS/Linux scripts locate `ninjarmm-cli` through a single `NINJA_CLI` variable built from `NINJA_DATA_PATH`, with a fallback path, instead of mixing bare, `./` and full-path calls.

### Fixed
- PowerShell templates: `Write-Error` under `$ErrorActionPreference = 'Stop'` throws, so the following `exit 1` never ran and custom exit codes were lost. Errors are now written with `-ErrorAction Continue` (via `Write-LogError`) before `exit`.
- PowerShell: `Select-Object -Skip`/`-SkipLast` were wrongly listed as PowerShell 6+ only; both exist in 5.1. The forbidden list now covers other real 6/7-only features.
- PowerShell: contradiction between "avoid Invoke-WebRequest" and "always use -UseBasicParsing" resolved; added TLS 1.2 enablement, explicit `-Encoding`, and `$LASTEXITCODE` checks for native commands.
- Script variables: Integer/Decimal were described as arriving as numeric types; environment variables are always strings. Date guidance unified on ISO 8601 with optional offset, parsed with RoundtripKind.
- Restored the checkbox custom-field note (raw 1/0 without `-Type 'Checkbox'`) that was lost in 1.3.0.
- macOS: the DNS-flush translation used `sudo`, contradicting the no-sudo rule. The "good" example compared with `-eq` against possibly non-numeric output.
- Linux: replaced the "good" example that appended to `/etc/resolv.conf` (unsafe on systemd-resolved systems) with a distro-aware chrony example.
- Markdown defects that importers mangle: fences glued to headings/paragraphs, a fence nested in a list item, untagged fences, inline code in headings, and a broken code span containing a backtick.

### Added
- Source-code integrity rules: treat backslash-escaped brackets/hashes in examples as display artefacts, and parse-check scripts before presenting them.
- Execution-context checks use `WindowsIdentity.IsSystem`; the Windows Server guard uses `ProductType` (locale-independent) instead of matching "Server" in the caption.
- macOS: console-user pattern for collecting per-user data from a root script; note on zsh `echo` interpreting backslashes and 1-based arrays.
- Linux: `/etc/os-release` distro detection, `DEBIAN_FRONTEND=noninteractive`, bash 5.2 pattern-substitution note, HTML-escape helper.
- Display-artefact defence, from testing in GitHub Copilot. Copilot shows the model skill files and uploads with backslashes before brackets; the model sometimes reproduces them, and the chat display can then corrupt the code (an escaped string type literal before a double colon was shown as a single colon, breaking the script).
  - PowerShell skill: names the artefact explicitly, adds a self-check (every double colon must follow a closing bracket), and a validation ladder: parse with powershell.exe or pwsh, else an awk static scan that a bash-only sandbox can run, else a manual read-through.
  - macOS/Linux skills: an awk scan for escaped brackets, because an escaped double-bracket test still passes `zsh -n` and `bash -n`.
  - CORE-CONVENTIONS: deliver scripts as a downloadable file when possible (it bypasses chat rendering), state how the script was validated, and include an operator check (for example a clipboard parse check on Windows) when it was not fully parsed.
  - CODE-REVIEW: treat apparent escape artefacts in uploaded scripts as possible display-layer damage and ask the user to check the original.
- `scripts/check-release.sh` now checks skill names, file set and routing, all shared files, Markdown formatting rules, escape artefacts in code, and syntax of every PowerShell/bash/zsh block (PowerShell also checked for 7-only syntax).

## [1.4.0] - 2026-05-26

### Fixed
- macOS skill: NinjaOne ignores the `#!/bin/zsh` shebang on macOS and invokes scripts under bash, breaking zsh-only syntax (`${0:t}`, native arrays, etc.). Mandatory script template now re-execs under zsh via `exec /bin/zsh "$0" "$@"` before any zsh-specific code runs.
- macOS skill: NinjaOne's launchd-invoked agent inherits a minimal `PATH` (typically `/usr/bin:/bin`), causing standard admin tools under `/usr/sbin` and `/sbin` (`networksetup`, `system_profiler`, `softwareupdate`, `pmset`, `diskutil`, etc.) to fail with `command not found`. Template now sets `export PATH="/usr/bin:/bin:/usr/sbin:/sbin"` at the top.

### Added
- macOS skill: two new entries in "Common Mistakes" covering the shebang and PATH quirks above.

## [1.3.0] - 2026-03-20

### Added
- NinjaOne WYSIWYG Field Reference (`NINJAONE-WYSIWYG-REFERENCE.md`) — complete reference for allowed HTML elements, inline CSS properties, NinjaOne CSS classes, Font Awesome 6 icons, Charts.css, and Bootstrap 5 grid layout in WYSIWYG custom fields.
- NinjaOne agent environment variables (`$env:NINJA_*`) reference table with platform access syntax and best practices.
- NinjaOne device tag operations — PowerShell cmdlets (`Get-NinjaTag`, `Set-NinjaTag`, `Remove-NinjaTag`) and CLI commands (`tag-get`, `tag-set`, `tag-clear`).
- Common mistakes sections — cross-platform (RMM-CONVENTIONS.md) and PowerShell-specific (SKILL.md) covering checkbox comparisons, empty string handling, WYSIWYG gotchas, `ConvertTo-Json` depth, DateTime parsing, and more.
- PowerShell skill: WYSIWYG quick example and device tags section.

### Changed
- Moved checkbox custom field behaviour note from PowerShell SKILL.md inline list to the cross-platform common mistakes section in RMM-CONVENTIONS.md.

## [1.2.2] - 2026-03-16

### Added
- PowerShell skill: document NinjaOne checkbox custom field behaviour — without `-Type 'Checkbox'`, `Get-NinjaProperty` returns `0`/`1` instead of `$true`/`$false`.

## [1.2.1] - 2026-02-24

### Added
- Windows Server (RDP) guard for user-context scripts — NinjaOne's "run as logged-in user" cannot target a specific RDP session on multi-session servers, so user-centric automations now block execution on Windows Server by default.

## [1.2.0] - 2026-02-13

### Fixed
- Linux `SCRIPT_NAME` bug — NinjaOne copies scripts to temp paths, so `basename "$0"` resolved to a meaningless name. All macOS and Linux templates now hardcode `SCRIPT_NAME`.

### Added
- YAML frontmatter metadata (`author`, `version`) to all three SKILL.md files.

## [1.1.1] - 2026-02-13

### Fixed
- YAML frontmatter: quote version string (`version: "1.2.0"`) to prevent YAML parsers treating it as a float.
- Removed unsupported `tags` field from frontmatter metadata — Claude Desktop does not support it.

## [1.1.0] - 2026-02-09

### Changed
- Clarified custom fields usage and environment variable input across all platforms.
- Improved macOS privilege context description.

## [1.0.0] - 2026-02-09

### Added
- Initial release with three platform skills: PowerShell 5.1 (Windows), zsh (macOS), and bash (Linux).
- Shared RMM conventions covering non-interactive execution, security, idempotency, logging, exit codes, input validation, code review mode, and response structure.
- NinjaOne and Action1 platform support.
- README with installation guide for Claude Desktop and Claude Code.

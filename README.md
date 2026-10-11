# RMM Skills for Claude AI

Claude AI Skills for generating production-ready RMM scripts (PowerShell, macOS, Linux) targeting NinjaOne, Action1, and other endpoint management platforms.

## What Are These?

These are [Claude Skills](https://support.claude.com/en/articles/12512176-what-are-skills) — structured instruction sets that teach Claude how to generate, review, and translate scripts specifically for RMM (Remote Monitoring and Management) deployment. They encode the hard-won knowledge of what works (and what breaks) when scripts run unattended on endpoints via an RMM agent.

When a skill is active, Claude will automatically apply it whenever you ask for an RMM script — enforcing version constraints, security practices, correct privilege context, and platform-specific custom field syntax without you having to repeat those requirements every time.

The skills use plain Markdown with every code example in a fenced block, so they also import cleanly into other agents that support skill folders (for example GitHub Copilot).

## Skills Included

- **rmm-powershell** — Windows, PowerShell 5.1. Runs as SYSTEM by default. CmdletBinding is mandatory except on Action1. No PowerShell 6/7 features, full cmdlet names only.
- **rmm-macos** — macOS, zsh, Catalina 10.15+. Runs as the **logged-in user by default** (not root). Strict mode, quoted variables, and guards for NinjaOne's macOS quirks (ignored shebang, minimal PATH).
- **rmm-linux** — Linux, bash 4+. Runs as root by default. Distribution-aware (apt vs dnf).

Each skill includes:

- **Scope boundaries** — Only activates when you mention RMM, NinjaOne, Action1, or endpoint deployment. Won't interfere with general scripting.
- **Templates** — NinjaOne templates for each run context, plus an Action1 template.
- **NinjaOne custom fields** — PowerShell module cmdlets (Windows) and ninjarmm-cli usage (macOS/Linux) for device and documentation fields.
- **NinjaOne WYSIWYG fields** — Allowed HTML elements, inline CSS, NinjaOne CSS classes, Font Awesome 6 icons, Charts.css, and the Bootstrap 5 grid.
- **NinjaOne device tags, script variables and agent environment variables.**
- **Action1** — The CmdletBinding/param incompatibility and custom attributes.
- **Code review mode** — Supply an existing script and get findings ranked by severity plus a corrected script.
- **Cross-platform translation** — Concept mappings between Windows, macOS and Linux, including privilege-context differences.
- **Common mistakes** — Platform and RMM gotchas, each listed next to the topic it belongs to.

## How a Skill Is Organised

Each skill folder is self-contained. SKILL.md is a short router that sets the platform baseline and tells Claude which reference files to read, so only the references a task needs are loaded.

- **SKILL.md** — Scope, defaults, execution-context rules, language baseline, coding standards, common mistakes, and routing. Always loaded.
- **CORE-CONVENTIONS.md** — Unattended execution, security, validation, idempotency, exit codes, output, source integrity, response structure. Always read. *(shared)*
- **NINJAONE.md** — NinjaOne templates, agent quirks, run-as behaviour, script variables, agent environment variables. Read for NinjaOne scripts (the default).
- **ACTION1.md** — Action1 template and constraints. Read instead of NINJAONE.md for Action1.
- **NINJAONE-CUSTOM-FIELDS.md** — Custom and documentation fields, limits, writing WYSIWYG fields. Read when needed.
- **NINJAONE-WYSIWYG.md** — What NinjaOne renders in WYSIWYG fields. Read when needed. *(shared)*
- **NINJAONE-TAGS.md** — Device tags. Read when needed.
- **CODE-REVIEW.md** — Review procedure and response format. Read when needed. *(shared)*
- **CROSS-PLATFORM.md** — Translation procedure and concept mappings. Read when needed. *(shared)*

Files marked *shared* are identical in all three skills.

## Installation

### Claude.ai / Claude Desktop

1. Download the ZIP for the skill(s) you need from [Releases](../../releases)
2. Go to **Settings → Capabilities → Skills**
3. Upload the ZIP file
4. Toggle the skill on
5. Ensure **Code Execution** is enabled

**Upgrading from 1.x:** the skill names changed in 2.0.0 to match the folder and ZIP names (rmm-powershell-scripts became rmm-powershell, and so on). Remove the old 1.x skills before uploading 2.x, or you will have two copies installed.

### Claude Code (CLI)

**Global install** (available in all projects):

```bash
# Clone the repo
git clone https://github.com/DeusMaximus/rmm-skills.git

# Copy into your global skills directory
mkdir -p ~/.claude/skills
cp -r rmm-skills/rmm-powershell ~/.claude/skills/
cp -r rmm-skills/rmm-macos ~/.claude/skills/
cp -r rmm-skills/rmm-linux ~/.claude/skills/
```

**Per-project install** (repo-specific):

```bash
mkdir -p .claude/skills
cp -r /path/to/rmm-skills/rmm-powershell .claude/skills/
```

## Repo Structure

```text
rmm-skills/
├── README.md
├── CHANGELOG.md
├── LICENSE
├── release.sh                 # Runs checks, then builds the release zips
├── scripts/
│   └── check-release.sh       # Structure, sync, formatting and syntax checks
├── docs/
│   └── v2-migration-report.md # What changed in the 2.0 restructure, and why
├── rmm-powershell/            # Each skill folder contains the same file set:
│   ├── SKILL.md               #   router and platform baseline
│   ├── CORE-CONVENTIONS.md    #   shared
│   ├── NINJAONE.md
│   ├── NINJAONE-CUSTOM-FIELDS.md
│   ├── NINJAONE-WYSIWYG.md    #   shared
│   ├── NINJAONE-TAGS.md
│   ├── ACTION1.md
│   ├── CODE-REVIEW.md         #   shared
│   └── CROSS-PLATFORM.md      #   shared
├── rmm-macos/
└── rmm-linux/
```

## Usage Examples

Once installed, just ask Claude naturally:

> "Write a NinjaOne PowerShell script that checks disk space and writes the result to a custom field called diskSpaceStatus"

> "I need a bash script for NinjaOne that collects installed package versions on Ubuntu and Debian and stores them in a multiline custom field"

> "Review this PowerShell script I'm deploying via Action1 — does it have any issues?"

> "Convert this Windows RMM script to macOS"

The skill activates automatically based on keywords like "RMM", "NinjaOne", "Action1", or "deploy to endpoints". For general scripting that isn't RMM-related, the skills stay out of the way.

## RMM Platform Support

### Fully Documented

- **NinjaOne** — Custom fields (PowerShell module + CLI), documentation fields, secure fields, all field types, WYSIWYG field styling, device tags, script variables, agent environment variables
- **Action1** — Custom attributes, CmdletBinding incompatibility, Windows scripting

### Compatible (Generic RMM Patterns)

The core conventions (non-interactive execution, SYSTEM/root context, stdout/stderr logging, exit codes) apply to most RMM platforms. If you use a different RMM, the scripts will still follow best practices — you'll just need to substitute the platform-specific custom field commands.

## Known Platform Quirks

- **Action1 and CmdletBinding** — Action1 does not support CmdletBinding or param blocks. The PowerShell skill has a separate Action1 template.
- **NinjaOne dropdown GUIDs** — Dropdown and multi-select fields return GUIDs by default. Use the Dropdown type parameter (PowerShell) or the options command (CLI) to get option names.
- **NinjaOne secure fields** — Write-only for documentation fields, and readable only during automation execution, not from the web or local terminal.
- **Linux ninjarmm-cli** — Not on the PATH. The skill uses the full path, built from the agent's data-folder variable.
- **macOS shebang and PATH** — NinjaOne runs macOS scripts with bash regardless of the shebang, and with a minimal PATH. The templates re-run under zsh and set a full PATH.
- **macOS run context** — The default is the logged-in user, not root — the opposite of Windows (SYSTEM) and Linux (root). Root can be requested explicitly; sudo is never used.

## Contributing

Found an issue or want to add support for another RMM platform? PRs welcome.

- Platform-specific RMM details go in that skill's RMM file (for example NINJAONE.md), or a new file routed from SKILL.md.
- Shared files (CORE-CONVENTIONS.md, CODE-REVIEW.md, CROSS-PLATFORM.md, NINJAONE-WYSIWYG.md) are edited in rmm-powershell first, then copied to the other two folders.
- All code goes in fenced blocks with a language identifier and a blank line before and after. Don't use inline code, raw HTML, or tables in prose.
- Run `bash scripts/check-release.sh` before opening a PR.

## License

[MIT](LICENSE)

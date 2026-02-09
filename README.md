# RMM Skills for Claude AI

Claude AI Skills for generating production-ready RMM scripts (PowerShell, macOS, Linux) targeting NinjaOne, Action1, and other endpoint management platforms.

## What Are These?

These are [Claude Skills](https://support.claude.com/en/articles/12512176-what-are-skills) — structured instruction sets that teach Claude how to generate, review, and translate scripts specifically for RMM (Remote Monitoring and Management) deployment. They encode the hard-won knowledge of what works (and what breaks) when scripts run unattended on endpoints via an RMM agent.

When a skill is active, Claude will automatically apply it whenever you ask for an RMM script — enforcing version constraints, security practices, correct privilege context, and platform-specific custom field syntax without you having to repeat those requirements every time.

## Skills Included

| Skill | Platform | Key Constraints |
|---|---|---|
| `rmm-powershell` | Windows (PowerShell 5.1) | SYSTEM context, `[CmdletBinding()]` mandatory (except Action1), no PS Core 6.0+ features, full cmdlet names only |
| `rmm-macos` | macOS (zsh, Catalina 10.15+) | **User context by default** (not root), `set -euo pipefail`, all variables quoted |
| `rmm-linux` | Linux (bash 4.x+) | Root context by default, distro-aware (apt vs dnf), `getopts` for parameters |

Each skill includes:

- **Scope boundaries** — Only activates when you mention RMM, NinjaOne, Action1, or endpoint deployment. Won't interfere with general scripting.
- **NinjaOne custom field reference** — PowerShell module commands (Windows) and `ninjarmm-cli` syntax (macOS/Linux) for reading and writing custom fields and documentation fields.
- **Action1 custom attribute reference** — `Action1-Set-CustomAttribute` syntax and known limitations.
- **Cross-platform translation** — Maps concepts between platforms when converting scripts (e.g., `Ninja-Property-Get` ↔ `ninjarmm-cli get`, privilege context differences).
- **Code review mode** — Provide an existing script and get expert analysis for RMM compliance, security, and best practices.

All three skills share `RMM-CONVENTIONS.md` which covers non-interactive execution, security, idempotency, logging, and RMM data storage concepts.

## Installation

### Claude.ai / Claude Desktop

1. Download the ZIP for the skill(s) you need from [Releases](../../releases)
2. Go to **Settings → Capabilities → Skills**
3. Upload the ZIP file
4. Toggle the skill on
5. Ensure **Code Execution** is enabled

### Claude Code (CLI)

**Global install** (available in all projects):

```bash
# Clone the repo
git clone https://github.com/DeusMaximus/rmm-skills.git

# Symlink or copy into your global skills directory
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

```
rmm-skills/
├── README.md
├── LICENSE
├── rmm-powershell/
│   ├── SKILL.md          # PowerShell 5.1 skill definition
│   └── RMM-CONVENTIONS.md  # Shared conventions
├── rmm-macos/
│   ├── SKILL.md          # macOS zsh skill definition
│   └── RMM-CONVENTIONS.md  # Shared conventions
└── rmm-linux/
    ├── SKILL.md          # Linux bash skill definition
    └── RMM-CONVENTIONS.md  # Shared conventions
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

- **NinjaOne** — Custom fields (PowerShell module + CLI), documentation fields, secure fields, all field types
- **Action1** — Custom attributes, `[CmdletBinding()]` incompatibility noted, Windows-only scripting

### Compatible (Generic RMM Patterns)

The shared conventions (non-interactive execution, SYSTEM/root context, stdout/stderr logging) apply to most RMM platforms. If you use a different RMM, the scripts will still follow best practices — you'll just need to substitute the platform-specific custom field commands.

## Known Platform Quirks

| Issue | Details |
|---|---|
| Action1 + `[CmdletBinding()]` | Action1 does not support `[CmdletBinding()]` or `param()` blocks. The PowerShell skill includes a separate template for Action1. |
| NinjaOne Dropdown GUIDs | Dropdown and MultiSelect fields return GUIDs by default. Use `-Type Dropdown` (PowerShell) or the `options` command (CLI) to get friendly names. |
| NinjaOne Secure Fields | Write-only for documentation fields. Only accessible during automation execution — not from web terminal or local terminal. Limited to 200 characters. |
| Linux `ninjarmm-cli` | Must use `./ninjarmm-cli` or the full path `/opt/NinjaRMMAgent/programdata/ninjarmm-cli`. Bare `ninjarmm-cli` won't resolve. |
| macOS Privilege Context | Default is **user context**, not root. This is the opposite of Windows (SYSTEM) and Linux (root), however root level scripts can be explicitly requested (`sudo` not required). |

## Contributing

Found an issue or want to add support for another RMM platform? PRs welcome.

To add a new platform:

1. If it has custom field/attribute commands, add them to the relevant SKILL.md file(s)
2. If it has `[CmdletBinding()]` or other scripting quirks, add to the compatibility table in the PowerShell skill
3. Update `RMM-CONVENTIONS.md` if the platform has unique data storage concepts
4. Update this README

## License

[MIT](LICENSE)

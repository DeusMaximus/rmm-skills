# RMM Skills for Claude — Project Guide

## What This Project Is

A set of Claude Skills (structured instruction sets) that teach Claude to produce production-ready RMM scripts for Windows (PowerShell 5.1), macOS (zsh), and Linux (bash). The target RMM platforms are NinjaOne and Action1. Licensed MIT — designed for easy community adoption.

## Project Structure

```
rmm-skills/
├── CLAUDE.md              # This file — project guide for Claude
├── README.md              # Public-facing docs and installation guide
├── CHANGELOG.md           # Version history (Keep a Changelog format)
├── LICENSE                # MIT
├── .gitignore
├── .github/
│   └── pull_request_template.md  # PR checklist for contributors
├── release.sh             # Build release zips (runs sanity checks first)
├── scripts/
│   └── check-release.sh   # Pre-release checks: versions, names, file set, shared-file sync, Markdown rules, code syntax
├── docs/
│   └── v2-migration-report.md    # Record of the 2.0 restructure (not shipped in zips)
├── rmm-powershell/        # PowerShell 5.1 skill (Windows) — canonical home of the shared files
├── rmm-macos/             # zsh skill (macOS Catalina 10.15+)
└── rmm-linux/             # bash 4.x+ skill (Linux)
```

Every skill folder contains the same nine files:

- `SKILL.md` — short router: scope, defaults, execution-context rules, language baseline, coding standards, source integrity, common mistakes, one good/bad example, and the routing list. Platform-specific.
- `NINJAONE.md` — NinjaOne templates, agent quirks, run-as behaviour, script variables, agent environment variables. Platform-specific.
- `NINJAONE-CUSTOM-FIELDS.md` — custom/documentation fields, limits, how to write WYSIWYG fields. Platform-specific.
- `NINJAONE-TAGS.md` — device tags. Platform-specific.
- `ACTION1.md` — Action1 template and constraints. Platform-specific.
- `CORE-CONVENTIONS.md` — **shared**: unattended execution, security, validation, idempotency, exit codes, output, source integrity, response structure.
- `NINJAONE-WYSIWYG.md` — **shared**: what NinjaOne renders (language-neutral HTML examples).
- `CODE-REVIEW.md` — **shared**: review procedure and response format.
- `CROSS-PLATFORM.md` — **shared**: translation procedure and Windows/macOS/Linux concept mappings.

Each folder is self-contained and distributed as a zip for Claude Desktop, or copied into `~/.claude/skills/` for Claude Code.

**Shared files are byte-identical across all three folders. `rmm-powershell/` holds the canonical copies** — edit there first, then copy to `rmm-macos/` and `rmm-linux/`. `scripts/check-release.sh` fails if they drift.

**One rule, one home.** Each rule is defined in exactly one file (within a skill); other files point to it rather than restating it. Generic rules go in `CORE-CONVENTIONS.md`, language rules in `SKILL.md`, NinjaOne behaviour in the matching `NINJAONE*.md` file. A new reference file must be routed from `SKILL.md` (the check script enforces this).

## Key Conventions

### YAML Frontmatter (SKILL.md files)
- Version numbers **must be quoted**: `version: "1.2.0"` — unquoted YAML treats `1.2.0` as a float and truncates to `1.2`.
- `tags` is **not supported** in Claude Desktop skill metadata. Only `author` and `version` under `metadata:`.
- Keep frontmatter fields to: `name`, `description`, `metadata.author`, `metadata.version`.
- `name` **must match the folder and zip name** (`rmm-powershell`, `rmm-macos`, `rmm-linux`). Changed in 2.0.0; enforced by the check script.

### Skill Content
- Each SKILL.md starts with a persona ("You are a specialised, senior-level...") and scope guards ("When This Skill Applies / Does Not Apply"), then the routing list. Keep it a router — detail belongs in the reference files.
- Keep the language British English for consistency with the existing content (e.g., "specialised", "defence-in-depth", "organisation").

### Markdown Formatting Rules (skill files)
Some skill importers (notably GitHub Copilot's) mangle Markdown: inline code and fences glued to the preceding paragraph get escaped (`\[string\]`, `\#`), and the escaped text leaks into generated scripts. In the skill folders:
- **All code goes in fenced blocks** with a language identifier (`powershell`, `bash`, `zsh`, `html`, `text`), a blank line before and after, starting at column 1 (no fences nested in list items).
- **No inline code at all** in prose — no backticks outside fences. Name identifiers in plain text ("the ErrorActionPreference variable", "the ninjarmm-cli binary").
- **No raw `$`, HTML tags, or Markdown tables in prose.** Use bullets, or a `text` fenced block for matrices and syntax lists.
- No code in headings.
- Never write Markdown escapes inside fences.
- State the rule in prose first, then show the example.
- `scripts/check-release.sh` enforces all of the above and syntax-checks every `powershell`, `bash` and `zsh` block (using `pwsh`, `bash` and `zsh` where installed; `pwsh` also flags PowerShell 7-only syntax). Fenced blocks must parse on their own, so don't use fragments like a bare `catch {}`.
- README.md, CHANGELOG.md, CLAUDE.md and `docs/` are not skill files; normal Markdown is fine there.

### Version Bumping
- All three SKILL.md files share the same version number. Bump all three together.

## Release Workflow

Every release ships **all three zips** regardless of which skills changed — users can grab any single zip from any release and have the latest.

1. Bump version in all three `SKILL.md` frontmatter blocks.
2. Add a new entry to `CHANGELOG.md`.
3. Run `bash release.sh` to build zips — this runs sanity checks automatically, then packages `rmm-powershell.zip`, `rmm-macos.zip`, `rmm-linux.zip`. Have `zsh` and `pwsh` installed so every code block is syntax-checked (missing parsers are reported as warnings, not failures).
4. Zips are gitignored — rebuild from source each release.
5. Create a GitHub release with `gh release create vX.Y.Z *.zip` and attach the zips.

## Known Quirks

- **NinjaOne `$0` / `SCRIPT_NAME` bug:** NinjaOne copies scripts to temp paths before execution, so `basename "$0"` or `${0:t}` resolves to a meaningless name. All macOS/Linux templates hardcode `SCRIPT_NAME` instead.
- **Action1 + `[CmdletBinding()]`:** Action1 does not support `[CmdletBinding()]` or `param()` blocks. The PowerShell skill has a separate Action1 template.
- **NinjaOne custom fields require SYSTEM/root:** Custom field access (read and write) does not work in user context on any platform.
- **macOS shebang and PATH:** NinjaOne runs macOS scripts with bash regardless of the shebang, and with a minimal PATH. The macOS templates re-exec under zsh and export a full system PATH.
- **Write-Error under the Stop preference:** With `$ErrorActionPreference = 'Stop'`, a plain `Write-Error` throws, so a following `exit N` never runs. Templates use `Write-Error -ErrorAction Continue` (via `Write-LogError`) before `exit`.
- **Skill importer escaping:** see "Markdown Formatting Rules" above. Clean source is not enough on its own: Copilot shows the model escaped text (backslash before `]`) even from fenced blocks and uploads, the model sometimes reproduces it, and Copilot's chat rendering can then corrupt it further (`[string\]::` displayed as `:`). The skills defend with explicit artefact rules, validation (parser or the awk scan in each SKILL.md, which deliberately contains no brackets, backslashes or hashes in its own source), and delivering scripts as files. Keep the awk scans free of those characters when editing them.
- **`ninjarmm-cli` not in PATH on Linux/macOS:** Bare `ninjarmm-cli` won't resolve. Skills define `NINJA_CLI` from `NINJA_DATA_PATH` with the standard path as a fallback (`/opt/NinjaRMMAgent/programdata` on Linux, `/Applications/NinjaRMMAgent/programdata` on macOS).

## Development Workflow

Changes to skills are driven by real-world usage feedback: use the skill in Claude, then ask Claude how the skill performed and what could use improvement or clarification. This feedback loop identifies gaps in the instructions that wouldn't be obvious from reading the files alone.

## Commit Messages

Keep it simple — clear, descriptive messages with no strict format required.

## Editing Guidelines

- This is a documentation-only project — no executable code in the repo itself. The skills instruct Claude how to *generate* code.
- When adding support for a new RMM platform, add an RMM file per skill (like `ACTION1.md`), route it from each SKILL.md, update CORE-CONVENTIONS.md only if a generic rule changes, and update README.md. Add the file to `PLATFORM_FILES` in `scripts/check-release.sh`.
- When adding a new platform skill (e.g., `rmm-freebsd/`), follow the existing nine-file structure, copy the shared files, and add the platform to `PLATFORMS` in `release.sh` and `scripts/check-release.sh`.
- Keep examples practical and representative of real RMM deployment scenarios.

## Platform Expansion

- **New RMM platforms:** The maintainer doesn't have access to other RMM platforms, but PRs adding platform-specific quirks are welcome. Current coverage: NinjaOne (full), Action1 (basic).
- **New OS targets:** Currently limited to what NinjaOne and Action1 support (Windows, Linux, macOS). New OS skills would only be added if an RMM platform adds scripting support for that OS (e.g., ChromeOS).

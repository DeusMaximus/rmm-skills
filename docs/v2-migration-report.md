# v2.0.0 Migration Report

Record of the 2.0 restructure: what moved, what changed and why, what still needs a human check, and how it was validated. Not shipped in the release zips.

## Why

1. **Importer mangling.** GitHub Copilot's skill importer rewrote parts of the 1.x skills into an escaped Markdown form (for example `\[string\]`, `\#`), and the escaped text leaked into generated scripts. The 1.x files had several patterns that converters handle badly: fences directly after a heading or bold label with no blank line, a fence nested inside a list item, untagged fences, inline code in headings and tables, and one code span that contained a backtick, which broke its own delimiters.
2. **Context and duplication.** Each skill loaded around 1,250 lines whatever the task. Script variables, context rules and custom-field rules were stated two or three times, sometimes inconsistently.
3. **Name mismatch.** Skill names (`rmm-powershell-scripts`) did not match the folder or zip names (`rmm-powershell`).

The Copilot-generated brief was used as a guide to structure, not as a source of facts. None of its code examples were reused.

## Where This Differs From the Copilot Brief

- **No cross-skill `shared/` folder.** Each skill must stay self-contained to work as a single zip. Shared files are copied into each folder and kept in sync by `check-release.sh`.
- **The same nine files in every skill.** The brief left WYSIWYG and tags out of the macOS and Linux skills, but both work through the CLI there.
- **No inline code at all in skill files.** The brief still allowed identifiers in inline code. Given the importer theory, skill-file prose now names identifiers in plain text, and all syntax lives in fenced blocks. `text` fences hold reference matrices that would otherwise be tables.
- **`CODE-REVIEW.md` and `CROSS-PLATFORM.md` are shared, not per-platform.** A translation needs knowledge of the source platform, which may not be installed, so one shared mapping file covering all three platforms works better.

## Files

Created in each skill: `CORE-CONVENTIONS.md`, `NINJAONE.md`, `NINJAONE-CUSTOM-FIELDS.md`, `NINJAONE-WYSIWYG.md`, `NINJAONE-TAGS.md`, `ACTION1.md`, `CODE-REVIEW.md`, `CROSS-PLATFORM.md`.

Removed: `RMM-CONVENTIONS.md` and `NINJAONE-WYSIWYG-REFERENCE.md`, from all three skills.

Rewritten: all three `SKILL.md`, `README.md`, `CLAUDE.md`, `scripts/check-release.sh`, `.github/pull_request_template.md`.

## Where Content Moved

- Non-interactive execution, security, idempotency, validation, exit codes, logging and response structure: from `RMM-CONVENTIONS.md` to `CORE-CONVENTIONS.md`.
- Code review mode: from `RMM-CONVENTIONS.md` to `CODE-REVIEW.md`, expanded into a checklist and a response format.
- Translation sections, one per SKILL.md: merged into `CROSS-PLATFORM.md` as a single three-way concept map.
- Script variables, defined parameters and agent environment variables: from `RMM-CONVENTIONS.md` and each SKILL.md (stated twice per skill) to each `NINJAONE.md`, in that platform's syntax only.
- Templates and context validation: from SKILL.md and `RMM-CONVENTIONS.md` (stated twice) to `NINJAONE.md` and `ACTION1.md`.
- Windows Server RDP guard: from SKILL.md and `RMM-CONVENTIONS.md` to the PowerShell `NINJAONE.md`.
- Custom fields: from SKILL.md and `RMM-CONVENTIONS.md` to `NINJAONE-CUSTOM-FIELDS.md`.
- Device tags: from `RMM-CONVENTIONS.md` (all platforms mixed together) to a per-platform `NINJAONE-TAGS.md`.
- Action1: from SKILL.md and `RMM-CONVENTIONS.md` to `ACTION1.md`.
- WYSIWYG: from `NINJAONE-WYSIWYG-REFERENCE.md` (PowerShell here-strings) to `NINJAONE-WYSIWYG.md` (plain HTML). The write commands moved to each `NINJAONE-CUSTOM-FIELDS.md`.
- Cross-platform common mistakes: each item moved next to the topic it belongs to (script variables to `NINJAONE.md`, field limits to custom fields, ConvertTo-Json depth to the PowerShell SKILL.md, and so on).

## Duplicates Removed

- Script variable naming, types and validation: previously stated 2× per skill, now once per skill.
- Context validation snippets: previously stated 2×, now once (in the templates).
- "Custom fields need SYSTEM/root": previously stated 4–5× per skill, now owned by `NINJAONE-CUSTOM-FIELDS.md`, with one-line routing pointers elsewhere.
- WYSIWYG limits: previously stated 3× (SKILL.md, the reference file, and the common mistakes), now once.
- Defined parameters and secure variables: previously stated 2×, now once.
- WYSIWYG chart examples: column and bar charts are identical apart from the class, as are line and area charts, so each pair is now one example plus a note.

## Conflicts Resolved

1. **Script variable types.** Integer and Decimal were said to "arrive as numeric types", but casting empty strings was also listed as a common mistake. Environment variables are always strings, so the skills now say so and require validation before conversion.
2. **Date variables.** The type table gave plain ISO 8601, while a common mistake mentioned fractional seconds and an offset, and the PowerShell table suggested a plain datetime cast. Unified on "ISO 8601, may include an offset". PowerShell parses with RoundtripKind and the invariant culture; Linux uses GNU date with an empty-value guard.
3. **Invoke-WebRequest.** It was on the "forbidden" list, yet the common mistakes said to always use -UseBasicParsing. It is allowed in 5.1; always pass -UseBasicParsing, and avoid the parameters that only exist in PowerShell 6 and 7.
4. **Select-Object -Skip and -SkipLast.** Wrongly listed as 6+ only. Both exist in 5.1 (checked against Microsoft Learn). Removed from the list.
5. **CmdletBinding "on every script".** This contradicted the Action1 exception. Now NinjaOne only.
6. **Secure field limit.** Stated as 200 in one place and "200–10,000, configurable" in another. Resolved conservatively: 200 is the safe limit unless the field is known to allow more. *Flagged for review below.*
7. **macOS ninjarmm-cli.** Custom-field commands used the full path while documentation-field and tag commands used the bare name, which fails with the minimal PATH. All now use `NINJA_CLI`.
8. **Linux ninjarmm-cli.** Guidance mixed `./`, the full path and `$NINJA_DATA_PATH`. All now use `NINJA_CLI`, built from `NINJA_DATA_PATH` with a fallback.
9. **macOS DNS-flush translation.** It used sudo, contradicting the no-sudo rule. It now runs as root without sudo.
10. **"Run as user" technique.** `RMM-CONVENTIONS.md` suggested "Invoke-Command with the user's token", which isn't a real technique. Replaced with a scheduled task for the interactive user, or a two-script split.
11. **Linux getopts.** It was mandatory for any parameters, while environment variables were the preferred input. Now getopts and usage are required only for command-line arguments.
12. **WYSIWYG large content.** "Use Ninja-Property-Set-Piped via CLI" conflated two things. The skills now give the module function and CLI stdin piping as separate options.
13. **PowerShell defined parameters.** The example used the Mandatory attribute, which prompts when the argument is missing. Replaced with validation in the script body.

## Behaviour Intentionally Changed

- **Skill names** now match folders and zips. This is breaking: users must remove the 1.x skills.
- **PowerShell error reporting** uses `Write-Error -ErrorAction Continue` before `exit`. Verified with pwsh: a plain Write-Error under the Stop preference terminated the script with exit 1 and skipped `exit 3`.
- **SYSTEM detection** uses `WindowsIdentity.IsSystem` instead of matching the account name.
- **Server detection** uses `Win32_OperatingSystem.ProductType -ne 1` instead of matching "Server" in the caption.
- **HTML encoding** in PowerShell uses `[System.Net.WebUtility]::HtmlEncode`, which needs no assembly load in 5.1. `System.Web.HttpUtility` does.
- **Shell output** uses printf instead of echo. In zsh, echo interprets backslashes.
- **The response format** is now: script, then deployment summary, then notes only if useful. Previously it was script plus a technical explanation. When information is missing, the skill asks one focused question.
- **Examples replaced:** the Linux resolv.conf/nginx example became distro-aware chrony, and the Action1 attribute example was split into compute-then-set.
- **New 5.1 guidance:** enable TLS 1.2, pass -Encoding explicitly, check `$LASTEXITCODE` after native commands, backslash is not an escape character, and don't log with Write-Output inside functions that return values.

## Behaviour Preserved

Default contexts (Windows SYSTEM, macOS user, Linux root), the Action1 CmdletBinding restriction, the RDP server guard, the macOS re-exec guard and PATH fix, the hardcoded SCRIPT_NAME, the custom-field and tag command sets (modern and legacy), the agent environment variables, the WYSIWYG allowlists and component library, the destructive-action and idempotency rules, the exit-code convention, and the scope guards.

## Items Requiring Human Review

1. **Secure field length.** Is 200 the fixed limit, or is it configurable up to 10,000 in current NinjaOne? The skills say "200 unless the field is known to allow more".
2. **Bold in WYSIWYG.** The examples use the b element, which is not on the published allowlist. The skills now say to check that it renders.
3. **CLI checkbox values.** The skills tell Claude to check the raw format on a test device. If you know what ninjarmm-cli returns for checkbox fields on macOS and Linux, state it.
4. **Action1 on macOS and Linux.** No platform-specific behaviour is documented. The templates are defensive, NinjaOne-style ones. Add any known quirks.
5. **Action1 run context.** The template assumes SYSTEM, as 1.x did. Confirm whether Action1 offers a user context.
6. **Windows CLI path.** `NINJA_DATA_PATH\ninjarmm-cli.exe` is carried over from the 1.x WYSIWYG reference. Confirm it on a Windows agent.
7. **Real-world importer test.** Import the 2.0 zips into Copilot and confirm the escaping is gone. If Copilot also escapes inside fenced blocks, the source-integrity rules are the remaining defence.

## Validation Report

Tools: bash 5.2.21, zsh 5.9 and PowerShell 7.4.6 (parser only) on Linux.

- **Structure:** all 27 skill files exist, every reference file is routed from its SKILL.md, every `*.md` reference resolves, and the 4 shared files are byte-identical in all 3 folders.
- **Frontmatter:** versions are quoted and equal (2.0.0), and names match the folders.
- **Markdown:** every fence has a language tag, a blank line before and after, and starts at column 1. There are no backticks, dollar signs, HTML tags or tables in prose, and no unclosed fences.
- **Escapes:** no backslash before square brackets, hash, underscore, asterisk, angle brackets, pipe or backtick inside any fence.
- **Syntax:** every bash block passes `bash -n` and every zsh block passes `zsh -n`. Every PowerShell block parses with no errors, and an AST scan found no ternary, `??`, `??=`, `?.` or `&&`/`||` pipeline chains.
- **Runtime smoke tests:**
  - The macOS user template, launched with bash, re-executed under zsh (proved with a zsh-only builtin), then failed the root check correctly.
  - The Linux root template exits 1 when a variable is missing and 0 when it is supplied.
  - The zsh HTML-escape helper is correct.
  - The bash helper needed quoted replacements under bash 5.2, and this was fixed.
  - GNU date parses NinjaOne ISO values with fractional seconds and an offset. An empty string is silently accepted as "today", so the example guards against it.
- **Negative test:** injected faults (a wrong name, a missing reference, inline code, a glued fence, an untagged fence, a table, a bash syntax error, PS7 operators, and an escaped bracket) were all caught by `check-release.sh`.
- **Not run:** Windows PowerShell 5.1 itself, which isn't available on Linux. The 5.1 check relies on the 7.x parser plus the AST scan for 7-only syntax. Live NinjaOne and Action1 agents were not available.

## Routing Matrix

Every request loads SKILL.md, CORE-CONVENTIONS.md and the RMM file (NINJAONE.md, or ACTION1.md for Action1).

- **Basic NinjaOne script:** nothing else.
- **Script that writes a custom field:** plus NINJAONE-CUSTOM-FIELDS.md.
- **HTML report in a WYSIWYG field:** plus NINJAONE-CUSTOM-FIELDS.md and NINJAONE-WYSIWYG.md.
- **Tag-driven automation:** plus NINJAONE-TAGS.md, and NINJAONE-CUSTOM-FIELDS.md for the CLI path on macOS and Linux.
- **Action1 script:** ACTION1.md instead of NINJAONE.md.
- **Review an existing script:** plus CODE-REVIEW.md, and any feature references the script uses.
- **Translate Windows to macOS (in the macOS skill):** plus CROSS-PLATFORM.md, and any feature references the script uses.

## Post-Restructure Testing in GitHub Copilot

Three test prompts were run in Copilot with the 2.0 skills: a PowerShell WYSIWYG disk report with a custom exit code, a macOS dropdown-to-tag script, and a review of a planted-bug script.

- **Passed:** both generated scripts parsed cleanly, used the 2.0 patterns (Write-LogError before custom exits, TryParse on optional integers, NINJA_CLI for every CLI call, dropdown GUIDs mapped through options), and loaded the routed references. The review found all three planted bugs and did not repeat the old false claim about Select-Object -SkipLast.
- **Failed:** the review's corrected script came back twice with the line containing the string type literal and IsNullOrWhiteSpace shown as a bare colon, which is a parse error. The user saw the raw text stream as the type literal with an escaped closing bracket before the display settled on the colon. When asked, Copilot also listed backslash-escaped type literals in its own earlier output that were not visible in the rendered code.
- **Diagnosis:** Copilot shows the model escaped text, including uploads, and said so itself ("the escapes shown in the retrieved preview are not present in the source"). The model sometimes reproduces the escape, and Copilot's display usually removes it again, but not always. Clean Markdown in the skills cannot prevent this, so the defence moved to the output side.
- **Changes:**
  - The artefact is now named explicitly in the skills.
  - PowerShell has a self-check (every double colon follows a closing bracket).
  - Validation follows a ladder that works without PowerShell: an awk scan that uses no brackets, backslashes or hashes in its own source, so the same artefact cannot corrupt it.
  - Scripts are delivered as files where possible.
  - When a script was not fully parsed, the deployment summary includes an operator check before pasting into NinjaOne.
- **Verified:** the PowerShell scan flagged all 7 corrupted samples with no false positives across 27 clean files, under gawk and mawk. The shell scan flags an escaped double-bracket test, which zsh -n accepts as valid.


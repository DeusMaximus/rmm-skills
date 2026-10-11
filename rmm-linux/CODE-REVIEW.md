# Reviewing Existing RMM Scripts

Use this procedure when the user supplies an existing script and asks for a review, a critique, a fix, or a hardening pass for RMM deployment.

This file is shared and identical in all three skills. The canonical copy is in the rmm-powershell folder.

## Before Reviewing

- Identify the target OS, shell or language version, RMM platform, and the intended run context. If the user has not stated the run context and it changes the verdict, ask.
- Read the platform's SKILL.md and the RMM file (NINJAONE.md or ACTION1.md). Read the custom-field, tag or WYSIWYG references if the script uses those features.

## Review Checklist

Work through each area and record every finding.

1. Language and version compatibility: syntax and commands that do not exist in the target version (see the platform SKILL.md).
2. Unattended operation: interactive prompts, dialogs, or anything that could hang (CORE-CONVENTIONS.md).
3. Execution context: whether the script validates its context, whether the chosen context can reach the resources the script uses, and RMM data access from the wrong context.
4. Security: hardcoded secrets, secrets written to output, unquoted or unvalidated input passed to commands, over-permissive changes, and unverified downloads.
5. Input validation and destructive-action safeguards: whether inputs are checked against system state before anything is changed or removed.
6. Idempotency: whether a second run causes duplicate or harmful side effects.
7. Error handling and exit codes: whether every failure path ends in a non-zero exit, and whether errors can be swallowed silently.
8. Output: whether success and failure output is useful for unattended troubleshooting.
9. RMM platform specifics: script variable handling, custom field types and limits, tag usage, and the platform quirks listed in NINJAONE.md or ACTION1.md.
10. Readability and maintainability: aliases, cryptic one-liners, dead code, and naming.
11. Source integrity: Markdown escape artefacts or other corruption in the supplied source (CORE-CONVENTIONS.md). Uploaded files can be displayed to you with backslashes that are not in the real file. If the supplied script appears to contain escape artefacts, say that the display layer may have added them and ask the user to check the original file, rather than reporting them as defects in the script.

Also check the script against the Common Mistakes list in the platform's SKILL.md and RMM file.

## Review Response

1. Findings, most severe first. For each one, give the location (line number or code fragment), what is wrong, the impact when the script runs unattended, and the fix. Use the severities Critical (will fail or cause damage), Major (incorrect in some realistic conditions) and Minor (style, clarity or efficiency).
2. The complete corrected script in a single fenced code block. Preserve the original intent and behaviour unless a finding requires a change, and say so when it does.
3. The deployment summary described in CORE-CONVENTIONS.md.

If the script is already sound, say so plainly and list only the improvements that are worth making.

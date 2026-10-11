# Core RMM Script Conventions

These rules apply to every RMM script on every platform. This file is the only place they are defined. Platform files add language-specific detail and link back here rather than repeating these rules.

This file is shared and identical in all three skills. The canonical copy is in the rmm-powershell folder.

## Non-Interactive Execution

RMM scripts run unattended through an agent. There is no terminal, no console window and nobody to answer a prompt.

- Never prompt for input. That rules out Read-Host and Get-Credential in PowerShell, read and select in shell scripts, and any dialog box or GUI prompt.
- Never open modal dialogs or windows. A non-blocking notification is acceptable only where the platform skill says so.
- Input must come from RMM script variables, script parameters, environment variables, custom fields or attributes, or constants declared at the top of the script.
- A missing input must produce a clear error and a non-zero exit, never a hang.

Running as the logged-in user does not make a script interactive. A user session exists, but the script is still headless.

## Execution Context

RMM scripts run either as the system account (SYSTEM on Windows, root on macOS and Linux) or as the logged-in user. The context decides what the script can reach.

- Pick the context from what the script touches: system-wide settings need the system account, and per-user resources need the user context.
- Validate the context at the top of the script whenever it affects correctness. Fail fast with a message that names the setting to change in the RMM console.
- Each platform skill sets the default context and provides the validation snippet.
- RMM data access (NinjaOne custom fields and tags) has its own context requirement. See the platform's NINJAONE-CUSTOM-FIELDS.md.

## Input Handling

- Validate every required input before acting, even when the RMM console marks it as mandatory. This is defence in depth.
- Report all missing inputs in one error rather than failing on the first one.
- Treat every value received through an environment variable as a string. Convert it to a number, boolean or date only after checking that it is not empty.
- An optional input that was not supplied usually arrives as an empty string, not as an unset variable. Handle both cases.
- Do not give script variables the same names as system environment variables such as PATH, TEMP or HOME.

## Security

- Never hardcode credentials, API keys, tokens or tenant secrets.
- Take secrets from the RMM's secure variable type or from a secure field, and never write them to output or logs.
- If the user asks for a credential in the script, use a clearly named placeholder and explain the secure alternative.
- Flag commands that are overly permissive, disable security controls, or download and run remote content without verification.

## Input Validation and Destructive-Action Safeguards

Check inputs against the current system state before acting on them, so that a misconfigured input fails safely instead of causing damage. For example:

- Before mapping a drive letter, confirm the letter is not a local or fixed disk.
- Before deleting a directory, confirm it is not a system or profile root.
- Before changing a service, confirm it exists and is the expected service.
- Before changing a registry key or configuration file, confirm the path is in the expected location.

Destructive operations such as deleting, overwriting, uninstalling or resetting need explicit validation, a clearly scoped target, and log output that records what was changed.

## Idempotency

Scripts must be safe to run repeatedly.

- Check whether a resource exists before creating it.
- Check whether a setting already has the desired value before changing it, and log "no change needed" when it does.
- Avoid duplicate side effects such as appending the same line twice or creating a second scheduled task.

When a resource already exists, decide whether to replace it or refuse:

- Replace it when it is the same kind of thing the script would create, such as an existing network mapping on the requested drive letter.
- Refuse with a clear error when it is a different kind of thing or replacing it could lose data, such as a physical disk on the requested letter or a system directory at the target path.
- Always check what an existing resource is, not just whether it exists.

## Error Handling and Exit Codes

- Exit with 0 on success.
- Exit with 1 on a general failure. Codes 2 and above may be used for specific, documented failure cases.
- Every error path must end in a non-zero exit. RMM platforms use the exit code to decide pass or fail in policies and conditions.
- An error message must say what was attempted, what failed, and where possible what to change.
- Each platform skill defines its error-handling mechanics (for example, try/catch in PowerShell and strict mode in shell scripts).

## Output and Logging

RMM agents capture standard output as the script result and the error stream as errors.

- Write progress and success messages to standard output.
- Write failure details to the error stream (standard error).
- Keep output concise and useful for someone troubleshooting after the fact: what was checked, what changed, and what was skipped.
- Include the tenant or organisation identifier in output when the RMM provides one. On NinjaOne, see the agent environment variables in NINJAONE.md.
- Never write secrets to output.

## Source-Code Integrity

Reference files may reach you through a conversion layer that escapes Markdown characters, so examples can arrive with backslashes that are not part of the source. Generated scripts must contain only real source code.

- Put generated source in fenced code blocks with a language identifier. Never put executable code in inline code formatting.
- Never Markdown-escape source code. Do not add a backslash before square brackets, hash characters, underscores, asterisks, angle brackets, pipes or backticks.
- If an example in these references shows a backslash before one of those characters, and the context is not a string, regular expression, path or account name, treat it as a display artefact. Remove the backslash in your output rather than copying it.
- Keep legitimate backslashes: Windows paths, DOMAIN-backslash-user account names, regular expressions, escape sequences inside strings, and shell line continuations.
- Check generated source with the language's parser when one is available. The commands are in each platform's SKILL.md. If the parser reports an error, fix it before presenting the script. If no parser was available, say so in the deployment summary.

## Response Structure

### New Scripts

Start with the script. Do not open with a long preamble.

1. The complete, commented script in a single fenced code block.
2. A deployment summary as a short bullet list covering:
   - Target OS and shell or language version
   - RMM platform
   - Required run context (system account or logged-in user) and why
   - Script variables or parameters, with type and whether each is required
   - Custom fields, attributes or tags read
   - Custom fields, attributes or tags written
   - Exit codes and what each means
   - Environmental limitations, prerequisites, and whether parser validation was performed
3. Technical notes, only where they add operational value, such as a non-obvious design decision or a risk the operator should know about.

If something needed to generate a safe script is missing, ask one focused question that covers every gap before writing the script. Typical gaps are the execution context, the name and type of a custom field to write, the scope of a destructive operation, and credentials or tenant-specific values. Do not invent field names, field types, credentials or tenant values. For minor values that the user can easily change, a clearly labelled constant at the top of the script is acceptable; list it in the deployment summary.

### Reviews and Translations

- For a review of an existing script, follow CODE-REVIEW.md.
- For a translation between platforms, follow CROSS-PLATFORM.md.

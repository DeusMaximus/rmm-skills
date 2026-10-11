---
name: rmm-linux
description: Create and review bash scripts specifically for NinjaOne or Action1 RMM deployment to Linux servers. ONLY use when the user explicitly mentions RMM, NinjaOne, Action1, or background agent deployment targeting Linux. Do NOT use for general shell scripting.
metadata:
  author: DeusMaximus and Claude
  version: "2.0.0"
---

# RMM Linux Scripts (bash)

You are a specialised, senior-level Linux systems administrator and bash expert. You write reliable, production-ready bash scripts that run unattended on Linux servers (Debian, Ubuntu and RHEL-family distributions) through NinjaOne or Action1, and you review existing scripts for the same purpose.

This file decides when the skill applies, sets the Linux baseline, and tells you which reference files to read. The detailed rules are in those reference files.

## When This Skill Applies

Use this skill only when the request explicitly involves at least one of:

- NinjaOne, Action1 or another RMM platform by name, targeting Linux
- A script described as running through an RMM, as a scheduled agent task, as a background agent job, or as deployed to Linux endpoints or servers
- A review of a script that the user says is for RMM deployment to Linux
- Translating an existing RMM script from Windows or macOS to Linux

## When This Skill Does Not Apply

- General bash scripting for personal use or local automation
- Scripts the user will run by hand in a terminal
- Container scripts, CI/CD pipelines or development tooling, unless they are explicitly deployed through an RMM
- Homelab scripting that is not for RMM deployment

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
- CROSS-PLATFORM.md when translating a script from or to Windows or macOS.

Do not read references that the task does not need.

## Defaults

- RMM platform: NinjaOne, unless the user names Action1 or another RMM.
- Run context: root.
- Shell: bash 4.0 or later at /bin/bash.

## Choosing the Execution Context

- Use root for system work: packages, services, files under /etc, system configuration, and any NinjaOne custom field or tag access.
- Use a standard user only for per-user resources: files and configuration in a user's home directory, user crontabs and user-scoped settings. Custom fields and tags do not work in this context.
- If the script needs per-user data and must also write a custom field, run it as root and collect the user data with the technique in NINJAONE.md.
- Never use sudo to gain privileges in an unattended script. Configure the script to run as root in the RMM console.
- Every script validates its context at the top. The templates in NINJAONE.md and ACTION1.md include the check.

## bash Baseline

- Use bash features for clarity and safety: double square-bracket tests, double-parenthesis arithmetic, arrays and parameter expansion.
- Do not use zsh, ksh or other shell-specific syntax.
- Avoid features newer than bash 4.0 unless the target distributions are known to have them.
- In bash 5.2 and later, an ampersand in the replacement part of a pattern substitution inserts the matched text. Quote the pattern and the replacement to make them literal; the HTML-escape function in NINJAONE-CUSTOM-FIELDS.md does this.

## Distribution Awareness

Commands differ between distribution families:

```text
Task                Debian / Ubuntu                          RHEL / Rocky / Alma
Install a package   apt-get install -y <pkg>                 dnf install -y <pkg> (yum on older releases)
Refresh and update  apt-get update && apt-get upgrade -y     dnf upgrade -y
Package installed?  dpkg -s <pkg>                            rpm -q <pkg>
Security updates    apt-get -s upgrade                       dnf updateinfo list sec
Firewall            ufw                                      firewalld (firewall-cmd)
Services            systemctl                                systemctl
```

Set DEBIAN_FRONTEND to noninteractive when running apt-get, so that package configuration never prompts.

When the target distribution is unknown, ask the user, or detect it from /etc/os-release and handle each supported family:

```bash
if [[ ! -r /etc/os-release ]]; then
    log_error "Cannot read /etc/os-release to identify the distribution."
    exit 1
fi

# shellcheck source=/dev/null
. /etc/os-release
distro_family="${ID_LIKE:-$ID}"

case " ${ID} ${distro_family} " in
    *" debian "*|*" ubuntu "*) package_manager="apt" ;;
    *" rhel "*|*" fedora "*|*" centos "*) package_manager="dnf" ;;
    *)
        log_error "Unsupported distribution: ${PRETTY_NAME:-$ID}"
        exit 1
        ;;
esac
```

## Script Structure

Each RMM file contains the full template for that RMM. Every script follows the same structure:

1. The bash shebang and a header comment stating the purpose, run context and exit codes.
2. Strict mode, enabled with set -euo pipefail.
3. A hardcoded SCRIPT_NAME constant and the log_info and log_error functions.
4. Execution-context validation.
5. Input validation, reporting every missing input at once.
6. Main logic, ending in an explicit exit code.

Scripts that take command-line arguments (NinjaOne defined parameters) also need a usage function and a getopts loop that validates required options. Scripts that take their input from environment variables do not.

## Error Handling

- Strict mode is mandatory: -e exits on any failing command, -u treats unset variables as errors, and pipefail makes a pipeline fail when any command in it fails.
- Reference optional variables with a default, such as an empty default, so that strict mode does not abort when they are unset.
- When a failure needs a specific message or exit code, test the command explicitly instead of relying on -e:

```bash
if ! systemctl restart chronyd; then
    log_error "Failed to restart chronyd."
    exit 1
fi
```

## Coding Standards

- Double-quote every variable expansion and command substitution.
- Use clear, descriptive variable names (config_file, not cf), readonly for constants and local for function variables.
- Avoid cryptic one-liners.
- Use printf for output that may contain backslashes or leading dashes.

## Source Integrity (bash)

Apply the general rules in CORE-CONVENTIONS.md, plus:

- Keep legitimate backslashes, such as line continuations and escapes inside strings or regular expressions. Do not add a backslash before square brackets, hash characters, pipes, angle brackets or other operators.
- Some agent environments show reference files and uploaded files with a backslash inserted before square brackets, hash characters and other punctuation. Those backslashes are display artefacts; do not reproduce them.
- When bash is available, write the script to a file and syntax-check it before presenting it. Run ShellCheck as well when it is installed. Then scan it for backslashes in front of square brackets, because an escaped test bracket can still pass the syntax check. The scan avoids those characters in its own source. Review any hit, because a regular expression may legitimately need one:

```bash
bash -n /path/to/script.sh
shellcheck /path/to/script.sh
awk '
BEGIN { bs = sprintf("%c", 92); ob = sprintf("%c", 91); cb = sprintf("%c", 93) }
index($0, bs ob) { print FILENAME ":" FNR ": backslash before a bracket: " $0; next }
index($0, bs cb) { print FILENAME ":" FNR ": backslash before a bracket: " $0 }
' /path/to/script.sh
```

- If the script could not be syntax-checked, give the operator this check in the deployment summary. It needs bash on Linux, macOS or WSL, with the script saved to a file:

```bash
bash -n script.sh && echo "No syntax errors."
```

## Common Mistakes (Linux)

1. Unquoted variable expansions, which cause word splitting and glob expansion on values with spaces or wildcards.
2. Assuming Debian commands on RHEL, or the reverse. apt-get, dpkg and ufw do not exist on RHEL-family systems.
3. Running apt-get without DEBIAN_FRONTEND set to noninteractive.
4. Referencing an optional variable without a default under strict mode.
5. Editing files that another service manages, such as resolv.conf on systems that run systemd-resolved. Change the managing service's configuration instead.

## Example

Bad: not idempotent, Debian-only without saying so, apt-get may prompt, and no output.

```bash
#!/bin/bash
apt-get install chrony
systemctl start chrony
```

Good: the body of a root script built from the NINJAONE.md template, using the distribution check above. It installs only when needed and reports what it did. The service is called chrony on Debian and Ubuntu but chronyd on RHEL-family systems.

```bash
if [[ "$package_manager" == "apt" ]]; then
    service_name="chrony"
    if dpkg -s chrony >/dev/null 2>&1; then
        log_info "chrony is already installed."
    else
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq chrony
        log_info "chrony installed."
    fi
else
    service_name="chronyd"
    if rpm -q chrony >/dev/null 2>&1; then
        log_info "chrony is already installed."
    else
        dnf install -y -q chrony
        log_info "chrony installed."
    fi
fi

if systemctl is-active --quiet "$service_name"; then
    log_info "${service_name} is already running."
else
    systemctl enable --now "$service_name"
    log_info "${service_name} enabled and started."
fi

exit 0
```

## Response

Follow the response structure in CORE-CONVENTIONS.md. For reviews, follow CODE-REVIEW.md. For translations, follow CROSS-PLATFORM.md.

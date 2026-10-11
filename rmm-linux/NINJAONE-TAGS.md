# NinjaOne Device Tags on Linux

Read this file when a Linux script reads, assigns or removes NinjaOne device tags. Tags classify devices beyond roles and custom fields, and they can drive device searches, automation conditions and filters.

## Constraints

- Tags work only when the script runs as root, the same as custom fields.
- Tag commands work only inside automation scripts run by the NinjaOne agent, not in an interactive terminal session.
- A tag must already exist in the NinjaOne web console. Scripts can assign and remove existing tags, but cannot create new ones.
- Tag names are case-sensitive.
- ninjarmm-cli is not on the PATH. Define NINJA_CLI as shown in NINJAONE-CUSTOM-FIELDS.md.

## Commands

```bash
# All tags on this device, one per line
"$NINJA_CLI" tag-get

# Assign a tag
"$NINJA_CLI" tag-set "Production"

# Remove a tag
"$NINJA_CLI" tag-clear "Development"
```

## Pattern

Read the current tags first so that the script only makes the changes it needs, check every exit code, and remove temporary tags when the work is done.

```bash
if ! current_tags="$("$NINJA_CLI" tag-get)"; then
    log_error "Failed to read device tags."
    exit 1
fi

if printf '%s\n' "$current_tags" | grep -Fxq "Maintenance Approved"; then
    # Maintenance work here

    "$NINJA_CLI" tag-clear "Maintenance Approved" || { log_error "Failed to remove tag 'Maintenance Approved'."; exit 1; }
    "$NINJA_CLI" tag-set "Maintenance Completed" || { log_error "Failed to assign tag 'Maintenance Completed'."; exit 1; }
    log_info "Maintenance completed and tags updated."
else
    log_info "Tag 'Maintenance Approved' not present. No action taken."
fi
```

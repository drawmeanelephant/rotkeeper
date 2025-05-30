---
asset-meta:
  name: rc-utils.md
  version: "v0.2.1"
  updated: "2025-05-29"
  tags: [scripts, docs, utils]
---

# rc-utils.sh

**Purpose:** Shared helper library for all Rotkeeper scripts, providing common flag parsing, logging, dry-run support, dependency checks, and error handling.

## Usage

This script is not invoked directly. Instead, each `rc-*.sh` script sources it at the top:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
```

After sourcing, scripts call:

```bash
parse_flags "$@"
[[ "$HELP" == true ]] && show_help
```

then use the following helpers.

## Functions

- `parse_flags "$@"`
  Parses global flags:
  - `--dry-run`
  - `--verbose`
  - `--help`, `-h`

- `show_help()`
  Default help handler; overridden by individual scripts to display usage and exit.

- `log LEVEL MESSAGE…`
  Prints a timestamped log to stdout (and appended to script-specific log file).

- `run COMMAND…`
  Evaluates `COMMAND` unless `--dry-run` is set, in which case it logs a `DRY-RUN` message.

- `check_deps CMD…`
  Verifies each `CMD` is available; exits with error if any are missing.

- `trap_err LINE`
  Default error handler: logs an error with line number and exits.

- `cleanup()`
  No-op hook for cleanup; individual scripts can override to perform teardown.

## Example

```bash
# In rc-example.sh
#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
set -euo pipefail
IFS=$'\n\t'

parse_flags "$@"
[[ "$HELP" == true ]] && show_help

main() {
  check_deps git yq
  log "INFO" "Running example"
  run "echo Hello, world!"
}

main "$@"
```

<!-- 🎴 Limerick 1:
In the shadows of scripts all combined,
rc-utils keeps helpers aligned.
With flags parsed so neat,
Logs and runs compete,
And errors are neatly defined.
-->

<!-- 🎴 Limerick 2:
When each script needs a guiding hand,
rc-utils will take a bold stand.
It checks and it logs,
Guards against clogs,
And lights up the whole Rotkeeper land.
-->

---
title: "🆘 rc-help.sh Reference"
slug: rc-help
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-02"
description: "Aggregated help for all Rotkeeper scripts via rc-help.sh."
tags:
  - rotkeeper
  - scripts
---

## CLI Interface

```bash
rc-help.sh
```

- **Purpose**: Display combined usage instructions for all `rc-*.sh` scripts.
- **Flags**:
  - `-h`, `--help`
    Show this help page and exit (alias to display itself, though rc-help.sh ignores any args).

## Workflow Steps

1. **Locate Scripts**
   - Recursively search for executable `rc-*.sh` scripts in the same directory as `rc-help.sh`.

2. **Display Header**
   - Print a banner with the script’s name, version, and date.

3. **Aggregate Help Output**
   - For each executable `rc-*.sh` script found:
     - Print a separator header with the script name.
     - Invoke the script with `--help` to print its individual usage.

4. **Exit Behavior**
   - If no arguments are provided, display the aggregated help and exit with `0`.
   - If any arguments are provided, print a usage reminder and exit with `1`.

## Dependencies

- `bash` (≥5.0)
- `rc-*.sh` scripts must be located alongside `rc-help.sh` and have executable permissions.
- Individual scripts must support `--help`.

## Examples

- **Basic Usage**
  ```bash
  ./rc-help.sh
  ```
  Displays help for all Rotkeeper scripts in one consolidated report.

- **Passing Arguments (Error)**
  ```bash
  ./rc-help.sh foo
  ```
  Prints usage reminder:
  ```
  Usage: rc-help.sh [no arguments]

  Aggregates and displays help text from all Rotkeeper scripts.
  ```

## 🛣️ Navigation

- For detailed information on a specific script, run:
  ```bash
  ./scripts/rc-render.sh --help
  ```
  Replace `rc-render.sh` with any other `rc-*.sh` script name.

---
title: "🔍 rc-lint.sh Reference"
slug: rc-lint
template: rotkeeper-doc.html
version: "0.2.5-pre"
updated: "2025-06-02"
description: "Linter for Rotkeeper project: audits frontmatter, shell preludes, and Markdown links."
tags:
  - rotkeeper
  - scripts
  - lint
---

## CLI Interface

```bash
rc-lint.sh [--help] [--verbose]
```

- **Purpose**: Validate Rotkeeper files for required frontmatter keys, proper shell prelude (`set -euo pipefail`, `trap ERR`), and detect broken Markdown links.
- **Flags**:
  - `-h`, `--help`
    Show this help page and exit.
  - `-v`, `--verbose`
    Print extra information about each file being checked.

## Workflow Steps

1. **Scan Markdown Files**
   - Find all `*.md` files in the project root and subdirectories.
   - For each file:
     - Check for required frontmatter keys: `title`, `slug`, `template`, `version`, `updated`.
     - Warn about unknown frontmatter keys outside the allowed whitelist.

2. **Validate Markdown Links**
   - In each Markdown file, search for links with `*.md` targets.
   - Verify that each linked `.md` file exists relative to the source file.
   - Report any broken or missing links.

3. **Scan Shell Scripts**
   - Find all `rc-*.sh` scripts in the top level of `bones/scripts`.
   - For each script:
     - Check for presence of `set -euo pipefail`.
     - Warn if no `trap ... ERR` is found.

4. **Summarize Results**
   - Count errors encountered; if ≥1, exit with code `1`.
   - If no errors, exit with code `0` and a success message.

## Dependencies

- `bash` (≥5.0)
- `yq` (≥4.2) for parsing YAML frontmatter.
- `grep`, `sed`, `find` utilities (standard Unix tools).

## Examples

- **Run Linter**
  ```bash
  ./bones/scripts/rc-lint.sh
  ```
  Scans the project and outputs any missing frontmatter keys, unknown keys, or broken links.

- **Verbose Mode**
  ```bash
  ./bones/scripts/rc-lint.sh --verbose
  ```
  Prints each file being checked and details of any linting steps.

## 🛣️ Navigation

- To view details on frontmatter requirements, see `yaml.md`.
- For script help including lint integration, run:
  ```bash
  ./scripts/rc-render.sh --help
  ```
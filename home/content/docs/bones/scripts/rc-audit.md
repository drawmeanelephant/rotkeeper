---
title: "📝 rc-audit.sh Reference"
slug: rc-audit
template: rotkeeper-doc.html
version: "v0.1.1"
---
<!-- asset-meta: { name: "quickstart-guide.md", version: "v0.1.0" } -->
# 📝 rc-audit.sh

**Version:** v0.1.1
**Script Path:** `bones/scripts/rc-audit.sh`

## Purpose

- Audit tracked files to ensure each contains a proper `asset-meta` front-matter block.
- Detect missing, malformed, or incomplete metadata entries.
- Optionally inject a metadata stub when missing (`--fix` mode).

## CLI Interface

```bash
rc-audit.sh [flags]
```

Supported flags:

- `--help`, `-h`
  Show usage information and exit.

- `--dry-run`
  Perform checks and report errors without modifying files or writing reports.

- `--verbose`
  Print detailed progress and diagnostic messages.

- `--fix`
  Automatically insert a metadata stub into files missing `asset-meta`.

- `--json-only`
  Output only the JSON report.

- `--md-only`
  Output only the Markdown report.

## Workflow Steps

1. **Setup & Configuration**
   - Define manifest path (`bones/manifest.txt`), report/log directories, and default flags.
   - Parse CLI arguments and prepare environment.

2. **Load Manifest Entries**
   - Read each line of `bones/manifest.txt` into an array of file paths.

3. **Audit Loop**
   - For each file path:
     a. Check if the file exists; if missing, record an error.
     b. Open the file and search for an `asset-meta:` block at the top.
     c. If the block is missing or malformed, record an error.
     d. If `--fix` is enabled and missing, inject a default metadata stub into the file.

4. **Reporting**
   - Collect all audit results (errors and fixes performed).
   - Write a JSON report to `bones/reports/audit-report-<timestamp>.json`.
   - Write a Markdown report to `home/content/rotkeeper/audit-report-<timestamp>.md`.

5. **Exit Codes**
   - `0` — All files passed audit (or fixes applied).
   - `1` — Errors found and not all fixes applied.
   - `2` — Missing manifest file or critical failure.

## Examples

```bash
# Audit metadata, output both JSON and Markdown
./bones/scripts/rc-audit.sh

# Only generate Markdown report
./bones/scripts/rc-audit.sh --json-only=false --md-only

# Audit and auto-fix missing metadata stubs
./bones/scripts/rc-audit.sh --fix --verbose

# Dry-run to preview changes without writing
./bones/scripts/rc-audit.sh --dry-run
```

<!--
Next Steps:
- Link this page from scan-verify-tools.md.
- Add troubleshooting tips for common metadata formatting issues.
-->

<!--
LIMERICK 1
There once was a script called rc-audit,
Whose checks never failed to audit:
It sniffed out each stub,
With an automated rub,
And left every file perfectly plaudit.

LIMERICK 2
A metadata ghost in each page,
Was caught by our audit so sage:
It filled every block,
With no missing stock,
And secured them in versioned cage.
-->


---
title: "🧾 rc-audit.sh Reference"
slug: rc-audit
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Runs consistency checks across Rotkeeper directories, validating structure, file states, and manifest integrity."
tags:
  - rotkeeper
  - scripts
  - audit
  - validation
asset_meta:
  name: "rc-audit.md"
  version: "0.2.3-pre"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---
# 📝 rc-audit.sh

**Version:** v0.2.4-dev
**Script Path:** `bones/scripts/rc-audit.sh`

## Purpose

- Audit tracked files to ensure each contains a proper `asset-meta` front-matter block.
- Detect missing, malformed, or incomplete metadata entries.
- Properly report missing files as errors.
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
   - Define manifest path (`bones/asset-manifest.yaml`), report/log directories, and default flags.
   - Parse CLI arguments and prepare environment.

2. **Load Manifest Entries**
   - Read each asset path from `bones/asset-manifest.yaml` via yq.

3. **Audit Loop**
   - For each file path:
     a. Check if the file exists; if missing, record an error.
     b. Open the file and check for a valid `asset-meta:` block in the frontmatter.
     c. If the block is missing or malformed, record an error.
     d. If `--fix` is enabled and missing, inject a default metadata stub into the file.

4. **Reporting**
   - Collect all audit results (errors and fixes performed).
   - Write a JSON report to `bones/reports/asset-audit.json`.
   - Write a Markdown report to `bones/reports/asset-audit.md`.

5. **Exit Codes**
   - `0` — All files passed audit (or fixes applied).
   - `1` — Errors found including missing files, and not all fixes applied.
   - `2` — Missing manifest, critical YAML parse error, or failure to complete audit.

## Examples

```bash
# Audit metadata, output both JSON and Markdown
./bones/scripts/rc-audit.sh

# Only generate Markdown report
./bones/scripts/rc-audit.sh --md-only

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

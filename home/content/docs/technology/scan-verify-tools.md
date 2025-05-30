---
title: "Scan & Verify Tools"
slug: scan-verify-tools
template: rotkeeper-doc.html
---
<!-- asset-meta: { name: "scan-verify-tools.md", version: "v0.1.0" } -->

# 🔍 Scan & Verify Tools

Rotkeeper includes tooling to audit file rot, detect drift, and confirm tomb integrity before archiving. These tools are designed for paranoid deployments, CI pipelines, and changelog enforcement rituals.

They complement one another: `rc-scan.sh` surfaces issues **in the current filesystem**, while `rc-verify.sh` inspects **archived tombs** and ensures SHA integrity against manifests.

---

## 📂 What Gets Scanned?

Tools like `rc-scan.sh` and `rc-verify.sh` inspect:

- bones/manifest.txt: expected tomb contents
- bones/asset-manifest.yaml: tracked file versions
- home/content/**/*.md: user-written tombdocs
- output/**/*.html: rendered pages checked for missing assets
- Script and template `asset-meta` blocks
- Output folders (e.g. `/output/`, `/logs/`) for untracked files

For full usage details, see [`rc-scan.sh`](../bones/scripts/rc-scan.md) and [`rc-verify.sh`](../bones/scripts/rc-verify.md).

---

## 🧪 `rc-scan.sh`

This script walks the current environment and compares it to the tomb's manifest. It detects:

- Missing files listed in `bones/manifest.txt`
- Orphaned files that exist but are not tracked
- Assets referenced in rendered HTML that no longer exist
- Markdown or script files missing `asset-meta:` frontmatter

Flags supported:
- `--manifest-only`: skip disk scan, only report manifest status
- `--json-only`, `--md-only`: limit output format
- `--dry-run`: preview actions
- `--verbose`: show extra debug info

Output includes a Markdown report in `home/content/rotkeeper/scan-report-*.md` and a JSON version in `bones/reports/scan-report-*.json`.

---

## 📏 `rc-verify.sh`

This script compares file hashes against `asset-manifest.yaml`. It confirms that each listed file:

- Exists on disk
- Matches its recorded SHA256 checksum
- Was not silently modified or regenerated

This is most useful after a pack/unpack cycle or before release. Failure will surface any corrupted or tampered content.

Flags:
- `--quiet`: suppress normal output, exit codes only
- `--manifest`: verify manifest entries only, skip full tomb unpack

---

## 🧾 Sample Output: Markdown Scan Report

```markdown
## Missing Files
- bones/templates/ritual-missing.html

## Orphan Files
- home/assets/forgotten-favicon.ico

## File Digests
- `bones/scripts/rc-pack.sh`: a1b2c3d4e5f6…
```

---

## 🧠 Tips for Verification Workflows

- Run `rc-scan.sh` before every `rc-bless.sh` invocation
- Automate `rc-verify.sh` in your CI to validate `.tar.gz` outputs
- Consider writing diffs between manifest versions to surface unexpected drift

Example integration into a CI pipeline:

```bash
bash rc-render.sh
bash rc-pack.sh
bash rc-scan.sh --json-only
bash rc-verify.sh --quiet
```

Exit codes:
- `0`: no issues
- `1`: warnings or mismatches (non-fatal)
- `2`: missing dependencies, unreadable manifests, or structural failures

---

Back to [Documentation Index](index.md)  
Continue to [Changelog & Version Blessing](changelog-blessing.md)

<!--
LIMERICK

A scanner inspected the tomb,  
Declared certain headers in gloom.  
It flagged them with care,  
Some vanished, some bare—  
And verified files in the room.

SORA PROMPT

"a decaying command-line scanner analyzing a digital tomb's manifest, ghostly metadata scrolling past, flickering with errors and confirmations"
-->
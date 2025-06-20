---
title: "📚 Docs Fix Task"
slug: rc-docs-fix
template: rotkeeper-doc.html
version: "0.2.5"
updated: "2025-06-03"
description: "Task notes and fix log for the Rotkeeper documentation structure and metadata pass."
tags:
  - rotkeeper
  - docs
  - meta
  - task
asset_meta:
  name: "rc-docs-fix.md"
  version: "0.2.5"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

## 📑 Table of Contents

- [rc-docs-fix — Documentation Stub](#rc-docs-fix--documentation-stub)
  - [📝 Overview](#-overview)
  - [🚀 Usage](#-usage)
    - [Examples](#examples)
  - [🔍 Details](#-details)
  - [🛣️ Navigation](#️-navigation)
  - [🛠️ Troubleshooting](#️-troubleshooting)
  - [🎨 Sora Prompts](#-sora-prompts)
# rc-docs-fix — Documentation Stub

A concise overview of what `rc-docs-fix.sh` does in the Rotkeeper toolkit, providing automated insertion of standard sections into Markdown docs.

***

## 📝 Overview

<!-- The sacred audit and patch objectives -->

**Requirements:** Bash 4+, GNU or BSD sed, standard Unix utilities (grep, find, mkdir, cp).

The `rc-docs-fix.sh` utility audits and patches Markdown files by inserting stub sections for Purpose, Usage, Examples, Troubleshooting, and Future Plans if they are missing. **Inputs:** Target directory path (default: `home/content/docs/`). **Outputs:** Updated Markdown files with inserted section stubs and corresponding backups.

***

## 🚀 Usage

<!-- Invocation ceremony and options -->

```bash
rc-docs-fix.sh [OPTIONS] [DIR]
```

**Options:**

- `-h`, `--help` – Display help message.
- `DIR` – Directory to scan (default: `docs/docs`).
- `--dry-run` – Show what changes would be made without modifying files.

### Examples

Generating stubs in the default docs folder:
```bash
./bones/scripts/rc-docs-fix.sh
```

Targeting a specific directory:
```bash
./bones/scripts/rc-docs-fix.sh bones/archive
```

Display help:
```bash
rc-docs-fix --help
```

***

## 🔍 Details

<!-- Under-the-hood ritual mechanics -->

Upon invocation, the utility:
1. Parses flags, resolves the target directory, and confirms write access.
   - e.g., `rc-docs-fix bones/archive`
2. Detects the appropriate `sed` in-place flag for the host environment.
3. Creates a timestamped backup directory under the target.
   - Creates `bones/archive/.rc-docs-backups-20250515123045/filename.md`
4. Iterates over each `.md` file, backing it up and inserting missing stub sections.
5. Reports the files modified and backups created.
   - Summary printed to stdout, listing each file processed and backup location.

***

## 🛣️ Navigation
<!-- Quick navigation links -->
- [Scripts Index](scripts/index.html)
- [Docs-Fix Reference](scripts/rc-docs-fix.html)
- [Bones Home](index.html)

***

## 🛠️ Troubleshooting

- **Missing frontmatter errors?** Ensure each file begins with `---` on its own line.
- **Permission denied?** Verify you have write permissions for both the target directory and backup location.
- **Unsupported sed version?** Install GNU sed or adjust the script’s sed-detection logic.
- **No changes made?** Use `--dry-run` to inspect what would be added, or verify the files are missing known stub headings.

***

## 🎨 Sora Prompts

```sora
"An ancient archivist ghost, crafting stub sections in glowing Markdown crypts under flickering candlelight"
```

```sora
"A nameless scribe’s quill moving across digital parchment, leaving behind structured stubs of purpose and usage"
```


<!-- 🎴 Limerick 1:
A ghostly scribe in crypts so bare,
rc-docs-fix appeared with flair.
It wrote stubs with grace,
In each lonely space,
And left docs beyond all repair.
-->

<!-- 🎴 Limerick 2:
With patterns both ghastly and neat,
it patched headers with rhythmic beat.
No stub left behind,
As if fate had designed,
A structure both haunting and sweet.
-->
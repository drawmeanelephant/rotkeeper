---
title: "🔄 rc-cleanup-bones.sh Reference"
slug: rc-cleanup-bones
template: rotkeeper-doc.html
version: "v0.2.5"
updated: "2025-06-03"
description: "Backs up and prunes outdated directories and logs from the bones/ archive system."
tags:
  - rotkeeper
  - scripts
  - cleanup
  - backups
asset_meta:
  name: "rc-cleanup-bones.md"
  version: "v0.2.5"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# rc-cleanup-bones.sh

**Purpose:** Backup and prune unneeded directories and logs from `bones/` using configurable retention policies. Designed for safe dry-run previews and terminal confirmations.

## CLI Interface

```bash
rc-cleanup-bones.sh [--dry-run] [--verbose] [--help] [--days N]
```

Supported flags:

- `--help`, `-h`
  Show usage information and exit.
- `--dry-run`
  Preview actions without making changes.
- `--verbose`
  Show detailed logs.
- `--days N`
  Set retention window in days (default: 30).
 - `--force`
  Skip confirmation prompt (auto-confirm cleanup operations).

## Workflow Steps

1. **Parse Flags & Setup**
   - Ensure `bones/archive/cleanup-backups/` and `bones/logs/` exist.
   - Process `--dry-run`, `--verbose`, and `--days`.
   - Prompts for confirmation unless overridden.
   - All environment paths are sourced via `rc-utils.sh`.

2. **Backup**
   - Create a tar.gz of the entire `bones/` directory (excluding backups and existing archives) into `bones/archive/`.

3. **Prune Old Backups**
   - Delete backup archives older than `N` days.

4. **Prune Logs**
   - Delete log files in `bones/logs/` older than `N` days.

5. **Summary**
   - Log completion message indicating backup and prune results.
   - Honors DRY_RUN for all destructive actions and archive creation.

## Examples

```bash
# Preview cleanup without writing
./bones/scripts/rc-cleanup-bones.sh --dry-run --verbose

# Perform cleanup with a 14-day retention window
./bones/scripts/rc-cleanup-bones.sh --days 14

# Show help
./bones/scripts/rc-cleanup-bones.sh --help

# Force cleanup without prompt
./bones/scripts/rc-cleanup-bones.sh --force --days 7
```

<!-- 🎴 Limerick 1:
In bones that once held scripts and lore,
rc-cleanup-bones would save and restore.
It backed up the tombs neat,
Then pruned old defeat,
Leaving archives to honor folklore.
-->

<!-- 🎴 Limerick 2:
When backup folders grew out of hand,
This script lent a well-guided stand.
With tar and with find,
It culled what’s confined,
And kept your bones tidy and grand.
-->
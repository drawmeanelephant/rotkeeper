---
title: "🔄 rc-cleanup-bones.sh Reference"
slug: rc-cleanup-bones
template: rotkeeper-doc.html
version: "0.2.1"
updated: "2025-05-29"
---

# rc-cleanup-bones.sh

**Purpose:** Backup and prune unneeded directories and templates from bones/

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

## Workflow Steps

1. **Parse Flags & Setup**
   - Ensure `bones/archive/cleanup-backups/` and `bones/logs/` exist.
   - Process `--dry-run`, `--verbose`, and `--days`.

2. **Backup**
   - Create a tar.gz of the entire `bones/` directory (excluding its own backups folder) into `bones/backups/`.

3. **Prune Old Backups**
   - Delete backup archives older than `N` days.

4. **Prune Logs**
   - Delete log files in `bones/logs/` older than `N` days.

5. **Summary**
   - Log completion message indicating backup and prune results.

## Examples

```bash
# Preview cleanup without writing
./bones/scripts/rc-cleanup-bones.sh --dry-run --verbose

# Perform cleanup with a 14-day retention window
./bones/scripts/rc-cleanup-bones.sh --days 14

# Show help
./bones/scripts/rc-cleanup-bones.sh --help
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
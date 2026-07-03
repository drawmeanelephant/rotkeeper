---
title: "Soul Audit: Path Conventions & Ambiguities"
description: "Audit of folder-level soul path conventions and rc-glue.sh lookup rules."
status: "complete"
report_type: "necromancer-notes"
subject_script: "rc-glue.sh"
---

### Architectural Intent
This report details the findings from auditing the folder-level `.soul.md` coverage in relation to the `rc-glue.sh` dynamic index generator.

### Findings: Ambiguities and Fallthrough Conflicts

1. **Root Directory Fallthrough Mapping**
   The `rc-glue.sh` lookup logic relies on parsing subdirectories from `$CONTENT_DIR` (`home/content`). When evaluating a directory outside of `$CONTENT_DIR`, such as `bones/` or `home/assets/`, the `$REL_DIR_PATH` extraction yields the full absolute directory path or fails to trim properly. This ultimately triggers the fallback condition `SOUL_FILE="$META_DIR/rotkeeper.soul.md"`. This means all external directories currently share the same root `rotkeeper.soul.md` metadata, losing their distinct folder context in auto-generated indices.

2. **Mirrored vs. Flattened Paths**
   The prompt requested folder souls for `home/assets/` subdirectories to follow a flattened convention (e.g., `homeassetscss.soul.md` instead of `home/assets/css.soul.md`). However, `rc-glue.sh` inherently expects path mirroring inside the `$CONTENT_DIR` boundary (e.g., `docs/bones.soul.md` corresponding to `home/content/docs/bones/`).

3. **Misaligned Documentation Roots**
   Pre-existing souls for the `bones/` subdirectories (like `bones/config.soul.md` and `bones/templates.soul.md`) were placed mirroring the literal repository root. However, since `rc-glue.sh` operates inside `home/content/`, when rendering indices for `home/content/docs/bones/`, it expects the sidecar path to be `docs/bones/config.soul.md`. Thus, the literal root souls were disconnected from the `rc-glue.sh` documentation generation run. These have been repaired and moved inside the `docs/` mirror within `bones/meta/`.

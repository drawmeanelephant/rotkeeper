---
target_file: bones/scripts/rc-init.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Initializes directories and configuration without a content-deletion workflow. Real runs mark matching command scripts and Bats files executable, create content/output/configuration directories, seed an absent or empty configuration, and serialize the runtime paths block through yq. A forced strict environment reload follows the cache write. Optional starter content is `CONTENT_DIR/test-file.md` and is kept if already present.

### Limits

Does not copy or install templates and has no destructive `--force` mode. Optional assets/render work is delegated, and full mode adds sample content plus assets, render, and scan; those commands retain their own contracts. The dispatcher and script still pass through shared strict validation before the main initialization work, so bootstrap loading alone does not guarantee that every broken layout can be repaired.

### Cautions

Changing the configuration’s layout label and writing the current runtime cache does not move content, templates, or assets. Check the selected paths and reload result rather than assuming `--profile` migrates a repository. Dry-run skips chmod, configuration writes, sample writes, and delegated commands, but the core directory creation is unconditional and shared bootstrap logging still writes.

---
target_file: bones/scripts/rc-init.sh
reviewed: "2026-10-10"
reviewed_against: "0.8.1"
---

### Design

Initializes directories and configuration without a content-deletion workflow. The shared bootstrap ignores serialized paths and derives destinations from the physical repository root and active layout. It rejects malformed YAML and canonical paths that escape that root before logging or other writes. Real runs mark matching command scripts and Bats files executable, create core directories, seed an absent or empty configuration, and replace the paths block through yq. A forced strict environment reload follows the cache write. Optional starter content is `CONTENT_DIR/test-file.md` and is kept if already present.

### Limits

Does not copy or install templates and has no destructive `--force` mode. Plain `bash rotkeeper.sh init` repairs an initialized checkout copied or moved to another physical root, including stale or incomplete caches. It does not repair malformed YAML, escaping symlinks, or missing layout resources. Optional assets/render work is delegated, and full mode adds sample content plus assets, render, and scan; those commands retain their own contracts, except that scan findings (exit 3) are logged as a warning instead of failing init.

### Cautions

Changing the configuration’s layout label and writing the current runtime cache does not move content, templates, or assets. Check the selected paths and reload result rather than assuming `--profile` migrates a repository. `init --dry-run` skips chmod, core directory creation, configuration writes, sample writes, and delegated commands. Shared bootstrap logging still writes inside the current checkout, never through the discarded cache.

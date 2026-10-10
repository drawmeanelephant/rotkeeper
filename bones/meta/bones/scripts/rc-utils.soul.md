---
target_file: bones/scripts/rc-utils.sh
reviewed: "2026-10-02"
reviewed_against: "0.8.1"
---

### Design

Shared Bash helper library rather than a dispatcher command. Sourcing defines helpers and loads the canonical version; `rk_init_script` handles flags, traps, environment validation, per-run logs, and a saved stdout descriptor. Supplies dependency checks, path and deletion helpers, frontmatter/sidecar access, template resolution, navigation generation, portable checksum/mtime/find selection, and live Oliver preflight.

### Limits

`parse_flags` recognizes common flags anywhere in the argument list and skips command-specific arguments; callers still parse their own options from the full list. `run` suppresses only commands routed through it during dry-run, not arbitrary caller writes. Normal commands retain strict cache, relocation, layout, boundary, and readiness checks; the cache may hold only the path keys init writes, each a one-line string inside the root. Only init uses the shared bootstrap: it ignores cached destinations, validates YAML and every derived destination canonically before writes, and strictly reloads after replacing the cache. Canonical bootstrap validation requires GNU `realpath -m` or `readlink -m`. Sidecar mapping rejects escaping destinations by returning `bones/meta/null.soul.md`.

### Cautions

Canonical-path helpers have different fallback behavior, so callers must use the appropriate guard rather than assume every helper fails closed. Destructive callers must honor a failed `rk_guard_delete` result. Cleanup runs without masking the original exit status; scripts can override it. Help exits before environment/log initialization. Other initialization, including dry-run, creates logs, and Oliver preflight creates and removes its own smoke files and invokes the renderer.

---
target_file: bones/scripts/rc-render.sh
reviewed: "2026-10-02"
reviewed_against: "0.8.1"
---

### Design

Discovers Markdown, Textile, and Cooklang sources under the active `CONTENT_DIR`, checks output-basename collisions, obtains an Oliver TSV plan, and delegates page generation to `rc-oliver-adapter.sh`. Real runs synchronize assets and record rendered output paths in `bones/manifest.txt` through Oliver. Rendering writes mirrored `.html` pages under `OUTPUT_DIR`; tarball packaging belongs to pack, not render.

### Limits

Oliver is the only supported renderer. Discovery uses `RK_OLIVER_BIN` before PATH and includes a live smoke render. The theme-registry default precedes the legacy default-template key; an unavailable default falls back to the first sorted top-level HTML template. The adapter checks canonical source, output, template, and metadata boundaries. Only an existing per-page template within the template boundary replaces the planned template. `.textile` and `.cook` extensions override the configured source format; source frontmatter can override the site HTML/XHTML profile.

### Cautions

Stale HTML is pruned only from an output tree carrying `.rotkeeper-generated`; pruning and asset synchronization precede the adapter, so a failed batch is not a transactional rollback. `render_system_docs: false` excludes directories named docs, messages, or help from local discovery and filters Oliver's whole-tree plan before the adapter runs. Explicit false is preserved rather than passed through yq's default operator. A generated tree's previously rendered product-help pages are pruned on a real user-only build. XHTML requires a suitable wrapper and can fail on raw HTML. Dry-run skips the adapter, output writes, pruning, asset synchronization, and manifest updates, but still invokes Oliver preflight and plan and writes logs and temporary planning files.

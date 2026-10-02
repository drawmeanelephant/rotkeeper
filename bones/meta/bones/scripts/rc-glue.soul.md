---
target_file: bones/scripts/rc-glue.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Walks the active content tree, or a canonicalized subtree selected by `--path`, and creates missing `index.md` sources with links to immediate directories and Markdown, Textile, and Cooklang children. Default template selection uses the shared resolver. Directory-sidecar frontmatter overrides default metadata. A sidecar with nonempty `target_file` is a file sidecar and is not merged into an index, including the dispatcher sidecar at the content-root lookup path `bones/meta/rotkeeper.soul.md`.

### Limits

Existing indexes marked `rotkeeper_glued: true` are skipped unless forced. Custom indexes keep their frontmatter and prose; exactly one ordered glue-marker pair is replaced, while missing or ambiguous markers cause a new block to be appended. Marker recognition and the generated-index test are textual, not a structural Markdown/frontmatter parse. Links assume each child directory has an index and do not verify rendered destinations.

### Cautions

`--force` removes a marked generated index before recreating it, so manual edits in that file are lost and regeneration is not an atomic replacement. Custom-block replacement uses a temporary file and keeps the original on rewrite failure. Glue is inserted as literal environment data into gawk, not regex replacement text. Dry-run skips index mutations but still performs metadata/template resolution and writes bootstrap logs.

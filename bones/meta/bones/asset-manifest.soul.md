---
target_file: bones/asset-manifest.yaml
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

`assets` records accepted files from the source asset tree, not references
extracted from HTML. Each YAML sequence entry contains an asset-relative
`path` and a `sha256` checksum computed from the source file after copying.

In the default layout, `home/assets` contains static resources, including
stylesheets under `css`, imagery under `images`, and local fonts under
`fonts`. These are source assets, not content pages or a CDN service.
The command copies them without compiling CSS or processing images.

### Limits

The manifest contains no size, modification-time, or reference-count fields.
An empty asset tree produces the comment `# assets: []`, not a YAML sequence.
Paths rejected by the asset command are omitted.

### Cautions

The command archives the previous manifest under `bones/archive`, then
replaces it with its current report. Manual changes are not retained in the
new manifest. Minute-resolution names can collide on repeated runs.

---
target_file: "bones/config/version"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This plain-text file contains the canonical Rotkeeper version, currently
`0.8.1`. The dispatcher and `rk_load_version` in `rc-utils.sh` read it,
remove whitespace, and strip a leading `v`. The adapter feeds the loaded
value into the `$version$` template token.

Use the [bump command](../scripts/rc-bump.html) to change the version together
with CHANGELOG and the roadmap entry.

### Limits

The runtime readers do not validate semantic-version syntax. A missing or
empty file gives `unknown` unless a runtime override supplies a value.
`rk_load_version` also accepts a `VERSION_FILE` override; the dispatcher
reads the canonical path directly.

`rc-bump.sh` requires a numeric `X.Y.Z` canonical version and target. It reads
the canonical file for its calculation, not `ROTKEEPER_VERSION`.

### Cautions

`ROTKEEPER_VERSION` changes the runtime value without changing this file.
Rendered version labels can therefore differ from the canonical value.

Changing this file alone does not update CHANGELOG or the roadmap. Bump does
not commit unless `--commit` is supplied, and does not push.

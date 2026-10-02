---
target_file: bones/scripts/rc-book.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Creates separate script, documentation, configuration/template, content, metadata, filesystem-catalog, and collapsed-book retrieval artifacts under `bones/book-reports`. Each mode replaces its designated output. With no mode selected, it runs all binders. Bound source sections use path markers with a random per-run suffix. The filesystem catalog excludes configured generated/cache trees and supplies DIP discovery.

### Limits

The size check estimates the deduplicated documentation/content corpus and requires `--force-bind` above 5,242,880 bytes; it runs for every mode and does not measure every possible script/configuration/book input. Clean docbook strips frontmatter and emits title text, rather than deleting stale source documentation. Collapse reads existing `rotkeeper-*.md` book reports, not the content tree. `--config` is parsed but is not consumed by the binders.

### Cautions

Books are retrieval snapshots, not authoritative policy or backups. Some discovery loops use newline-separated paths, unlike the NUL-delimited content-metadata walk; do not assume arbitrary filenames are supported in every mode. Recognized dry-run flags skip report writes but still create the book-report directory and write bootstrap logs. Random section suffixes mean repeated real binds are not byte-identical.

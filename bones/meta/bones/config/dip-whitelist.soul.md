---
target_file: bones/config/dip-whitelist.txt
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

DIP reads exact repository-relative documentation paths, one per line.
It trims surrounding whitespace and ignores blank lines and comments
starting with `#`. Listed pages bypass the obsolete-document move check.

### Limits

Entries are not globs or directory-prefix rules. The whitelist does not
exempt pages from matrix reporting, reference generation, or pillar
stitching. It is not a sidecar coverage exception list.

### Cautions

A typo does not match the intended page. Keep only current page paths and
remove entries when their pages are retired.

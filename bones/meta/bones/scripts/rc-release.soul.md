---
target_file: bones/scripts/rc-release.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Stages a single framework distribution under `bones/tmp/release-staging-<pid>/rotkeeper`, using rsync exclusions. Generates `bones/config/release-manifest.txt` inside that staged tree, tests ZIP integrity, and checks archive entries against a root-entry allowlist, required framework files, forbidden runtime trees, and forbidden artifact patterns. Only a verified archive is promoted to `bones/archive/releases/rotkeeper-<version>.zip`.

### Limits

There are no lite or full tiers. This distribution is not a complete backup of author content. The allowlist constrains root entries, not every descendant file; the artifact checks cover the listed patterns rather than all possible private data. An omitted positional version uses the loaded version; the parser does not enforce the semver-style form advertised by help.

### Cautions

A successful release replaces an existing archive with the same name. Review staged content and the exclusion/verification rules before distributing it. Cleanup guards staging deletion and removes the in-flight ZIP. Dry-run still loads the environment, checks required tools, and writes bootstrap logs, but does not stage files, generate the manifest, or build and verify an archive.

---
target_file: bones/scripts/rc-bump.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Uses the canonical `bones/config/version` file for the bump calculation, independently of the display-version override. Updates that file, inserts the message after the roadmap buildlog anchor under `DOCS_DIR/road-to-bones/index.md`, and prepends a release section before the first `## [` heading in `CHANGELOG.md`. Major and minor bumps reset lower version segments.

### Limits

Requires exactly one version selector and a non-empty message. Versions have three numeric segments; prerelease and build suffixes are not accepted. Missing roadmap or changelog files produce warnings rather than blocking the version update. A missing insertion anchor leaves the corresponding document unchanged. The version write and document replacements are separate operations, not one transaction.

### Cautions

Committing is opt-in with `--commit`; there is no automatic commit or push. A dirty working tree is warned about, not rejected. Staging includes existing changes in the three touched files, and the commit includes any other already-staged changes. Dry-run previews payload updates without applying them, but shared bootstrap logging still writes; its commit preview is printed even without `--commit`.

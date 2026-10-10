---
target_file: bones/scripts/rc-bump.sh
reviewed: "2026-10-09"
reviewed_against: "0.8.1"
---

### Design

Uses the canonical `bones/config/version` file for the bump calculation, independently of the display-version override. Updates that file, inserts the message after the first roadmap buildlog anchor under `DOCS_DIR/road-to-bones/index.md`, and prepends a release section before the first `## [` heading in `CHANGELOG.md`. Every update is rendered into a scratch file beside its target before any target is replaced, and the version file is replaced last. Major and minor bumps reset lower version segments.

### Limits

Requires exactly one version selector and a non-empty message. Versions have three numeric segments; prerelease and build suffixes are not accepted. Missing roadmap or changelog files produce warnings rather than blocking the version update. A roadmap without the buildlog anchor, or a changelog without a `## [` heading, fails the bump (dry-run included) before any file changes. The final replacements are separate same-directory renames, not one transaction; a rename failure after staging can still leave the roadmap or changelog ahead of the version file, which is never moved early.

### Cautions

Committing is opt-in with `--commit`; there is no automatic commit or push. A dirty working tree is warned about, not rejected. Staging includes existing changes in the three touched files, and the commit includes any other already-staged changes. Dry-run previews payload updates without applying them, but shared bootstrap logging still writes; its commit preview is printed even without `--commit`.

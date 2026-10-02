---
target_file: bones/scripts/rc-dip.sh
reviewed: "2026-10-02"
reviewed_against: "0.8.1"
---

### Design

Builds a core-file inventory from `bones/book-reports/rotkeeper-files.md`, excluding runtime artifacts, content, assets, and metadata. Generates a missing catalog on a real run. Creates missing or empty references and regenerates explicitly owned shell-script references from source headers, static help, side-effect annotations, sidecar notes, and matching CHANGELOG bullets. Publishes the audit matrix at `DOCS_DIR/dip-matrix.md`.

Refreshes only the opt-in marked command table in the existing Docs index,
using dispatcher help and script mappings without executing them. Explicit
`doc_type: guide` pages with no core ownership under Docs or Help are
author-managed and have a separate review-date and placeholder report.

### Limits

Sidecars supply documentation prose, not executable behavior, and do not enter the expected-document ownership map. Recursive generated tails are removed when harvesting their bodies; empty or absent notes receive a factual fallback. Non-empty unowned script pages are preserved. Non-command mirrors retain authored prose while marker-owned sections are updated. Core staleness compares committed timestamps, not checkout mtimes. The whitelist only exempts obsolete moves, not all reporting or stitching.

The command index requires one ordered marker pair and agreement between
dispatcher help and script-backed case arms. Unmarked indexes are untouched.
Guide review state checks recorded calendar dates against the guide's own
known committed edit date, not every script a guide may discuss. Unknown
path history cannot establish an edit after review. Guide metadata does not
override a mapped core reference or exempt a target from sidecar coverage.

### Cautions

An obsolete move requires explicit `target_file` evidence that its target is absent from the core inventory; a missing filesystem catalog disables those moves. Destinations are under the content parent’s `obsolete/docs` tree, not `bones/obsolete`. Existing catalogs are consumed rather than automatically refreshed, so regenerate the catalog when inventory changes. Dry-run avoids document/matrix publication and catalog generation but still writes bootstrap logs; `--json` also creates and removes a scratch file and emits the computed `rotkeeper.dip-matrix.v1` envelope alongside normal console output.

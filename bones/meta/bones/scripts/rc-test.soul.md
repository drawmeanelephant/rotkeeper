---
target_file: bones/scripts/rc-test.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Bash integration harness shared by the dispatcher test and smoke commands. Creates crypt, busy, and sterile fixtures beneath `bones/tmp/rotkeeper-test-env`, exercises initialization, rendering, packaging, scanning, and release, and checks output pruning, archive integrity, metadata/template contracts, documentation navigation, and command help/version behavior. Includes isolated DIP generation and migration fixtures and removed-command regressions.

### Limits

Uses fixture Oliver executables for adapter contracts, with real-renderer smoke, CommonMark, XHTML, and template-golden checks when an executable Oliver is available. `RK_STRICT=1` makes specified missing real-renderer checks, fixtures, or XML tooling fatal rather than skipped. The dry-run mode runs only the removed-command regressions; it is not a preview of the full matrix. Dry-run payload non-mutation assertions compare file counts, not all file contents.

The isolated scaffold contract checks Markdown, Textile, and Cooklang
sidecars in every layout, including null review fields, dry-run non-publication,
and preservation of existing sidecars. It also checks that glue does not
merge the dispatcher's file sidecar into the content-root index.

### Cautions

The full run generates the filesystem catalog in the working repository as well as temporary fixtures, so its effects are not limited to fixture files. `RK_REGEN_TEMPLATE_GOLDENS=1` deliberately rewrites checked-in goldens during the crypt pass; review those changes before committing. Fixture cleanup uses the shared deletion guard. A passing fixture adapter is not proof of real CommonMark fidelity; report platform/tool failures rather than weakening assertions.

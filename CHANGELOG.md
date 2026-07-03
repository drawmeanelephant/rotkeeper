
## [0.4.0.4] - 2026-07-01
- Optimize rc-scan.sh to run faster on large filesystems.
- Enhance rc-ingest.sh to support multiple ingest sources.
- Update rc-pack.sh to include all config variations.
- Improve rc-render.sh error handling during template fallback.
- Fix rc-dip.sh to properly stitch empty sidecars.
- Optimize rc-env.sh variable resolution order.

## [0.4.0.5] - 2026-07-01
- Added parallel processing to rc-render.sh.
- Enhance rc-pack.sh compression algorithm for smaller tarballs.
- Improve rc-scan.sh orphaned file reporting format.
- Refactor rc-ingest.sh validation steps.
- Streamline rc-dip.sh parsing logic.
- Remove redundant subshells from rc-env.sh.

## [v0.2.6-pre] - 2025-06-05

### Added
- `rc-reseed.sh` now supports resurrection from scriptbook, docbook, and configbook
- `rc-book.sh` now supports `--all` mode and YAML collapse output

### Changed
- Unified all binder generation into `rc-book.sh` (removes `rc-docbook.sh`, `rc-webbook.sh`)
- `rc-reseed.sh` takes `--all` and restores from markdown binders, not archives
- Improved docbook formatting for clean frontmatter and accurate paths
- Asset scanner now archives old manifest and verifies selective assets

### Removed
- `rc-expand.sh` deprecated and deleted
- Legacy `rotkeeper-scriptbook.md` replaced with full-path `scriptbook-full.md`
- Removed `webbook` generation; HTML render handles public views

### Fixed
- Rendering fallback when no default template is configured
- Bats test suite skips validated edge cases (nested `run`, `trap_err` exits)

## v0.2.6-dev

- WIP: begin rc-help.sh smart indexing
- Added `rc-utils.bats`: Bats test suite for utility helpers (`log`, `run`, `trap_err`, `require_bins`)
- Updated `rc-utils.sh` to:
  - Respect DRY_RUN with proper logging
  - Safely export logs to both stdout and $LOG_FILE
  - Make `trap_err` shell-safe for test invocation
- Modified `README.md` to reflect testing support and current dev version
- Added new audit tasks and 4.5-import stubs to `todo.md`

## [0.3.0.2] - 2026-06-14
- test

## [0.3.0.3] - 2026-06-14
- Implemented automated sticky bump ritual to keep roadmaps from rotting

## [0.3.0.4] - 2026-06-15
- Integrate decentralized ingestion pipeline, CLI UX improvements, and Opus doc synchronization.

## [0.3.0.5] - 2026-06-15
- Presentation layer refactor: token-based CSS and Golden Path template

## [0.3.0.6] - 2026-06-15
- UX: added init warning to render and YAML syntax example to templates CLI

## [0.3.0.7] - 2026-06-15
- feat: added autoindex glue ritual to connect unindexed tombs

## [0.3.0.8] - 2026-06-15
- docs: documented architecture pillars and new rc rituals

## [0.3.0.9] - 2026-06-15
- fix: updated rc-glue.sh to support non-destructive overwriting using rotkeeper_glued frontmatter

## [0.3.0.10] - 2026-06-15
- fix: exclude bones/archive from release zip files to reduce bloat

## [0.3.0.11] - 2026-06-15
- fix: resolve reseed regex parsing bug and index post-increment strict mode crash

## [0.3.0.12] - 2026-06-15
- fix: cleaned up vendor bloat and excluded local inbox, messages, and reports from distribution payload

## [0.3.0.13] - 2026-06-15
- Add nice clean light and dark themes, set light as default

## [0.3.0.14] - 2026-06-15
- Strip frontmatter overrides and fix rc-render.sh to use rotkeeper.yaml

## [0.3.0.15] - 2026-06-15
- Cleaned up deprecated AI script bloat and fixed Pandoc markdown link rendering

## [0.3.0.16] - 2026-06-15
- Purged ghost scripts and perfectly synchronized documentation with active rituals

## [0.3.0.17] - 2026-06-15
- fix: correct home/content path resolution in rc-init.sh

## [0.3.0.18] - 2026-06-15
- Audit Refactoring Phase 1: standardized scaffolding, tightened day-1 UX, and simplified path logic

## [0.3.0.19] - 2026-06-15
- Refactor remaining scripts to use rk_init_script

## [0.3.0.20] - 2026-06-15
- Add test harness, agent-handoff, snapshot commands

## [0.3.1] - 2026-06-16
- Minor release: Framework stabilization and documentation scrub

## [0.3.1.1] - 2026-06-18
- Merge PRs #2 and #3: ASCII art headers and CI test suite updates

## [0.3.1.2] - 2026-06-19
- Restructure todo.md for Jules queue and move test.sh to bones/scripts/
- Purge obsolete references to `rc-unpack.sh` stub

## [0.3.1.3] - 2026-06-19
- Add --version flag to all rc-*.sh scripts

## [0.3.1.4] - 2026-06-22
- Fix template parsing bug in rc-render.sh using yq

## [0.4.0] - 2026-06-26
- Minor release: Integrates Inbox Autopilot, Frankenstein document engine, path-mirrored Necronotes architecture, and comprehensive sidecar documentation

## [0.4.0] - 2026-06-26
- Minor release: Integrates Inbox Autopilot, Frankenstein document engine, path-mirrored Necronotes architecture, and comprehensive sidecar documentation

## [0.4.0.1] - 2026-06-29
- Enforce 3-tier verbosity, prune redundant render backups, and optimize JSON AST packaging

## [0.4.0.2] - 2026-06-30
- Optimize rc-env.sh subshell parsing and harden sidecar path traversal boundaries

## [0.4.0.3] - 2026-06-30
- Ensure rc-render.sh outputs proper HTML with valid tags.
- Update rc-pack.sh to handle content flag natively.
- Optimize rc-scan.sh to quickly analyze missing references.
- Enhance rc-ingest.sh to validate payload checksums safely.
- Refactor rc-dip.sh to extract ritual history reliably.
- Optimize rc-env.sh to prevent unnecessary fork subshells.

## [0.4.0.3] - 2026-07-01
- release

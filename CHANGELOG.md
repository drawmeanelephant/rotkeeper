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
- Strip frontmatter overrides and fix rc-render to use rotkeeper.yaml

## [0.3.0.15] - 2026-06-15
- Cleaned up deprecated AI script bloat and fixed Pandoc markdown link rendering

## [0.3.0.16] - 2026-06-15
- Purged ghost scripts and perfectly synchronized documentation with active rituals

## [0.3.0.17] - 2026-06-15
- fix: correct home/content path resolution in rc-init

## [0.3.0.18] - 2026-06-15
- Audit Refactoring Phase 1: standardized scaffolding, tightened day-1 UX, and simplified path logic

## [0.3.0.19] - 2026-06-15
- Refactor remaining scripts to use rk_init_script

## [v0.2.6-pre] - 2025-06-05

### Added
- `rc-reseed.sh` now supports resurrection from scriptbook, docbook, and configbook
- `rc-configbook` and `rc-frontmatter-audit.sh` rituals added
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

- WIP: stub rc-lint.sh improvements
- WIP: begin rc-help.sh smart indexing
- Added `rc-utils.bats`: Bats test suite for utility helpers (`log`, `run`, `trap_err`, `require_bins`)
- Updated `rc-utils.sh` to:
  - Respect DRY_RUN with proper logging
  - Safely export logs to both stdout and $LOG_FILE
  - Make `trap_err` shell-safe for test invocation
- Modified `README.md` to reflect testing support and current dev version
- Added new audit tasks and 4.5-import stubs to `todo.md`

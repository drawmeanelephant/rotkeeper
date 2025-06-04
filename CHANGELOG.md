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

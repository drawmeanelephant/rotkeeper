---
target_file: rotkeeper.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The dispatcher derives the repository root from its own location and
loads `bones/scripts/rc-utils.sh` for version and help handling. It runs
command scripts with Bash. `test` and `smoke` select the same harness.
`release` supplies the current version unless a positional version is given.

### Limits

The dispatcher does not load the layout itself; command bootstraps do that.
It does not require the caller's working directory to be the repository
root. Unknown commands and the removed `ingest`, `sync-inbox`, `cleanup`,
and `reseed` commands fail.

### Cautions

Invoke project commands through `bash rotkeeper.sh <command>`, not by
executing `rc-*.sh` files directly. Subcommands have their own dependencies
and side effects. Top-level help and version output do not start a workflow.

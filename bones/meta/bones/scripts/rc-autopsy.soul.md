---
target_file: bones/scripts/rc-autopsy.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Catalogs command help and source-level output operations, not process logs or stack traces. Discovers top-level `rc-*.sh` files and the dispatcher; help collection executes only explicitly permitted basenames with `--help` and `ROT_SKIP_ENV=true`. Real runs replace `bones/reports/autopsy-help.md`, `bones/reports/autopsy-outputs.md`, or both.

### Limits

The output catalog uses line-oriented regular expressions for selected redirections, copies, moves, tee, and tar syntax. It substitutes exported directory variables and labels remaining variables unresolved. It is not a complete parser of shell behavior, quoting, multiline commands, or indirect writes. An empty help response falls back to flag strings found in source; captured error text can also appear in the report.

### Cautions

Verify report entries against current source before using them as operational facts. DIP may consume the output report for artifact exclusions, but harvests command help directly from source comments. `--dry-run` is honored before or after a report-mode flag; the shared parser sets it and the local mode parser ignores it. A dry-run skips report writes and help execution but still writes bootstrap logs.

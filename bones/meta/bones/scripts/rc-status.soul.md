---
target_file: bones/scripts/rc-status.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Reports version provenance, caller working directory and Git context, script inventory, bound-book sizes, release ZIPs, recent tarballs, content counts, render freshness, and selected configuration fields. Restores the caller’s output streams after shared bootstrap so reports remain visible. Short mode emits a single summary; JSON mode emits the full section data. Reporting writes a run log but does not generate content or repair state.

### Limits

Script health assigns the loaded canonical version to each discovered script; it does not execute script versions or run Bash syntax checks. Freshness compares the newest source mtime with the newest HTML mtime, not each source/output pair, templates, or assets. Stub/draft counts use literal status-line matches. Missing Git context becomes `[no git]` in human output and null fields in JSON, not a fatal Git dependency failure.

### Cautions

An “output is current” result is a coarse freshness heuristic, not proof that every page exists or matches its source. Git queries use the caller’s working directory, and release discovery uses a root-relative path, so run from the repository root for repository-wide results. `--dry-run` is a no-op report flag and does not suppress logging. `--json` takes precedence over `--short` when both are supplied.

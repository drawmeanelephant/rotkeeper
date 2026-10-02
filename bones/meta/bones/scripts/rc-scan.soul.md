---
target_file: bones/scripts/rc-scan.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

Audits `bones/manifest.txt` against disk and walks the rendered output tree for unlisted files. Generated assets and named runtime-support directories are excluded from the orphan walk. Reports missing entries, output orphans, present-file SHA-256 digests, and mismatches against ledger-recorded hashes. Real runs write selected Markdown/JSON reports under `bones/reports`; stdout JSON uses the `rotkeeper.scan.v2` envelope.

### Limits

Findings do not delete files and do not cause a nonzero result by themselves. A missing manifest is fatal only with `--manifest-only`; otherwise the output walk can still report orphans. Include/exclude filters affect orphan discovery, not ledger checks. Recorded hashes require the two-space path/hash form. Ledger normalization truncates at spaces and the output walk reads newline-delimited paths, so filenames containing spaces or newlines are not reliably represented.

### Cautions

Run from the repository root: the script converts manifest, output, report, and log locations to relative paths. Render-ledger entries can remain after stale pages are pruned, so a missing entry can reflect source removal rather than corruption. Dry-run skips final reports and the extra scan-specific log assignment, but shared bootstrap still writes a run log and the script creates report/log directories; stdout JSON also uses a scratch file and appends it to the current log.

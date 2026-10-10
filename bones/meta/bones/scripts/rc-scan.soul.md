---
target_file: bones/scripts/rc-scan.sh
reviewed: "2026-10-10"
reviewed_against: "0.8.1"
---

### Design

Audits `bones/manifest.txt` against disk and walks the rendered output tree for unlisted files. Generated assets and named runtime-support directories are excluded from the orphan walk. Reports missing entries, output orphans, present-file SHA-256 digests, and mismatches against ledger-recorded hashes. Real runs write selected Markdown/JSON reports under `bones/reports`; stdout JSON uses the `rotkeeper.scan.v2` envelope.

### Limits

Findings never delete files, but any missing file, orphan, or digest mismatch exits 3 so CI gates fail on a drifted ledger. A missing manifest is fatal only with `--manifest-only`; otherwise it is logged as a warning and the output walk can still report orphans. Include/exclude filters affect orphan discovery, not ledger checks. Recorded hashes require the two-space path/hash form; only a trailing 64-hex field is split from the path, so ledger paths may contain spaces. Ledger membership is an exact string comparison. The ledger and output walk are newline-delimited, so filenames containing newlines are not representable.

### Cautions

The script changes to the repository root before resolving the root-relative manifest, output, report, and log locations, so it audits the same repository from any working directory. Render-ledger entries can remain after stale pages are pruned, so a missing entry can reflect source removal rather than corruption; `init --full` logs such findings as a warning instead of failing. Dry-run skips final reports, scan-side report/log directory creation, and the extra scan-specific log assignment, but shared bootstrap still writes a run log; stdout JSON also uses a scratch file and appends it to the current log.

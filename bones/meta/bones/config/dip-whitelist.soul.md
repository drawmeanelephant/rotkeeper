---
title: "DIP Whitelist"
description: "Explicit rules for what files are skipped during obsolete culls."
status: "complete"
---

### Architectural Intent
A simple plain-text configuration file containing a newline-delimited list of files that should be whitelisted by the Document Improvement Project (DIP). Files listed here are ignored during audits and will not be flagged as obsolete or stubbed.

### Directory / File Schema Expectations
If an invalid filename or path containing a typo is added here, it fails silently, leaving the target file vulnerable to DIP sweeps. Do not add wildcard characters or directory globs unless supported by the parsing logic in `rc-dip.sh`. Keep comments prefixed with `#` to avoid parsing errors.

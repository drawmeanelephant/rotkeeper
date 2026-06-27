---
target_file: bones/config/dip-whitelist.txt
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
A simple plain-text configuration file containing a newline-delimited list of files that should be whitelisted by the Document Improvement Project (DIP). Files listed here are ignored during audits and will not be flagged as obsolete or stubbed.

### Restless Spirits
If an invalid filename or path containing a typo is added here, it fails silently, leaving the target file vulnerable to DIP sweeps.

### Ritual Warnings
Do not add wildcard characters or directory globs unless supported by the parsing logic in `rc-dip.sh`. Keep comments prefixed with `#` to avoid parsing errors.

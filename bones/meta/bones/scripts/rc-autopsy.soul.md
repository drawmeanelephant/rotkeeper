---
target_file: bones/scripts/rc-autopsy.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
An undertaker for dead processes. It attempts deep logging and error parsing by scraping raw text files. It's essentially a glorified `grep` wrapped in a burial shroud, pretending to understand the final cries of dying code.

### Restless Spirits
Runaway log files are the hungry ghosts here, waiting to devour every last byte of your disk space if left unchecked. Furthermore, its regex-based parsing of multi-line stack traces is comically inadequate. It will slice a stack trace in half and present you with a meaningless limb.

### Ritual Warnings
Monitor your disk space, or this script will fill it with the endless screaming of past errors. Do not trust its interpretation of multi-line errors; it only understands the simplest of death rattles.

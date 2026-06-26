---
target_file: bones/scripts/rc-utils.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The shared toolbox of rusty implements. It provides logging, color printing, and environment assertions for the rest of the scripts.

### Restless Spirits
Its attempts at portability often fall flat when encountering ancient or obscure shell environments. The 'robust' shell functions are one edge case away from a syntax error, especially when dealing with non-standard terminal emulators or deeply nested subshells.

### Ritual Warnings
Do not rely on these utilities in truly hostile environments. Their portability is an illusion maintained by sheer luck.

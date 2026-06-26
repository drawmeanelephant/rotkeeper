---
target_file: bones/scripts/rc-pack.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The embalmer. It wraps the project's remains in a tarball and shoves JSON metadata in alongside it, hoping the next entity to find it can make sense of the mess.

### Restless Spirits
Its absolute reliance on `jq` means that without it, the metadata creation process crashes and burns. Furthermore, the formatting of the JSON metadata is prone to breaking if shell variables contain unescaped quotes or newlines.

### Ritual Warnings
Ensure `jq` is installed and functioning. Beware of injecting raw, unescaped text into the JSON metadata fields.

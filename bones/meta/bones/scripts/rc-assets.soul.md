---
target_file: bones/scripts/rc-assets.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
This script trudges through the asset graveyard, cataloging artifacts and blindly copying them to `output/assets/`. It performs SHA256 checksum mapping, presumably because someone once trusted a file and paid the price. It's a glorified `cp` command with delusions of grandeur.

### Restless Spirits
The reliance on `sha256sum` or `shasum` preflights is a fragile pact; if the host lacks these, the ritual fails silently or spectacularly. More terrifyingly, it naively trusts asset filenames. A malicious filename could easily trigger a path traversal vulnerability, exfiltrating assets to wherever the dark forces desire.

### Ritual Warnings
Do not feed it untrusted zip files or chaotic directory structures unless you enjoy directory traversal exploits. Ensure `sha256sum` or `shasum` is bound to the environment before invoking this fragile magic.

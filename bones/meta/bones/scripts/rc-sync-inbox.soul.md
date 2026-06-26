---
target_file: bones/scripts/rc-sync-inbox.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The mailman of the underworld. It pulls incoming message payloads from presumably remote or isolated locations and dumps them into the inbox.

### Restless Spirits
It blindly syncs whatever it finds. Unvalidated sync paths mean that a malicious actor could drop a payload that overwrites existing files or plants executable scripts directly into your workflow.

### Ritual Warnings
Never sync from untrusted sources without sanitizing the payloads first. You are inviting vampires into your home.

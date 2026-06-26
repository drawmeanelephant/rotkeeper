---
target_file: bones/scripts/rc-ingest.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
A script that blindly swallows whatever garbage is thrown into `messages-from-my-friends/`. It performs decentralized content extraction, playing the role of a gullible archivist.

### Restless Spirits
Unpacking unverified `.tar.gz` payloads is a classic recipe for disaster. It practically begs for zip-slip vulnerabilities and directory traversal attacks. And let's not even start on malicious frontmatter injections—it will gladly execute whatever cursed metadata it finds.

### Ritual Warnings
Do not trust your 'friends'. Verify the contents of archives before extracting them, or risk overwriting critical files with malicious payloads.

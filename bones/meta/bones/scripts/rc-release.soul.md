---
target_file: bones/scripts/rc-release.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The merchant of death, packaging distribution zip files for the masses. It uses exclusion lists to decide what gets left behind in the crypt.

### Restless Spirits
The exclusion lists are a brittle defense. If a sensitive file gets created that doesn't match the hardcoded patterns, it will be happily zipped up and shipped to production. Its assumptions about the target environments are equally perilous.

### Ritual Warnings
Audit the exclusion lists regularly. Never assume that 'lite' means 'safe'—sensitive data will slip through if you aren't paying attention.

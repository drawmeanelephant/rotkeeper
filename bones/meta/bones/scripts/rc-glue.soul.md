---
target_file: bones/scripts/rc-glue.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The dark arts of code injection and template stitching. It relies heavily on `awk` and `sed` to find markers and cram new organs into existing corpses. It's a butcher shop masquerading as a templating engine.

### Restless Spirits
String replacements using `awk` or `sed` are fundamentally fragile. Throw in a stray ampersand, an unescaped slash, or nested brackets, and the whole operation turns to mush. It will happily inject malformed code and leave you with a syntax error wrapped in an enigma.

### Ritual Warnings
Sanitize your inputs. If your injected code contains special characters, prepare for the regex parser to summon something unholy.

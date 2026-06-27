---
target_file: bones/scripts/rewrite-links.lua
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
A simple Lua filter for Pandoc. It intercepts hyperlinks (`Link` AST nodes) and replaces `.md` suffixes with `.html`. This is the glue that allows developers to link `.md` files locally in their editors while keeping production site routing unbroken once rendered.

### Restless Spirits
The string replacements (`gsub("%.md$", ".html")`) are basic. If an internal link uses an absolute path or contains `.md` inside the domain name or anchor text in specific ways, it could face unintended mutation.

### Ritual Warnings
This filter is executed during Pandoc calls. If Pandoc lacks Lua support or the script is missing, markdown compilations will retain `.md` suffixes, breaking navigation on the live web portal.

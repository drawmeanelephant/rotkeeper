---
target_file: bones/scripts/rc-showcase.sh
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The template showcase generator. It loops through all theme templates under `bones/templates/` and spits out a static markdown file `showcase-${theme}.md` filled with nested headers, list elements, table patterns, and code fences. Its main purpose is to feed the rendering machine synthetic bodies to test layout aesthetics.

### Restless Spirits
This script is a vanity project for templates. It naively assumes `TEMPLATE_DIR` exists and contains standard files. It performs no safety check when stripping the `theme-` prefix, meaning a poorly named template could output files in unpredictable places.

### Ritual Warnings
Ensure `TEMPLATE_DIR` contains valid `.html` layouts. The output markdown is rewritten each run, meaning manual annotations added to the showcase files will be crushed.

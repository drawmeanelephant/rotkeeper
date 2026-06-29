---
title: "Templates Directory"
description: "Master index explaining the zero-hydration theme architecture."
status: "complete"
---

### Architectural Intent
The `bones/templates/` directory serves as the visual gatekeeper. It is the architectural mandate of this directory to house the raw HTML shells forcibly applied to markdown files during compilation. We do not hydrate. We do not run client-side JavaScript to construct the DOM. The final page structure is built statically at render time, yielding a lean, indestructible artifact.

### Directory / File Schema Expectations
This directory exclusively expects rigid HTML files equipped with standard Pandoc-compliant directives. Permitted assets include:
- Core structural templates containing necessary variables like `$title$`, `$body$`, and `$assets_root$` (e.g., `rotkeeper-blog.html`, `rotkeeper-doc.html`).
- Sub-theme wrappers that declare styling variables and font families (e.g., `theme-light.html`, `theme-dark.html`, `theme-phosphor.html`, `theme-kawaii.html`, `theme-overgrown.html`).
Any file lacking these standard Pandoc placeholders or attempting to introduce dynamic application logic will be considered invalid. Only valid HTML files with proper Pandoc-compliant directives are tolerated.

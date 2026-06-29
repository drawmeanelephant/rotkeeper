---
title: "Theme Suite (x5)"
description: "Defines CSS variables, fonts, and specific layouts for themes."
status: "complete"
---

### Architectural Intent
The overgrown theme layout is designed to offer a warm, bookish, literary reading experience. It utilizes forest and mossy earth tones, paired with rich serif typography and generous margins, to evoke the aesthetic of an old library book or a set of field notes.

### Directory / File Schema Expectations
The template file layout adheres to the following structural schema:
- CSS styling is mapped to `css/theme-overgrown.css` and is loaded via the `$assets_root$` path.
- Includes Google Font imports to load the elegant serif `Cormorant Garamond` for headings and the highly readable `Lora` for body text.
- The layout is structured using the `rk-shell` class, with the `$title$` variable populated inside the main header container, and the `$body$` variable populated within the `rk-article` container.

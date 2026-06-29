---
title: "🌿 theme-overgrown Layout Soul"
description: "Serif-heavy literary presentation tier pulling Cormorant Garamond / Lora typography pairings."
status: "complete"
---

## Architectural Intent
The overgrown theme layout is designed to offer a warm, bookish, literary reading experience. It utilizes forest and mossy earth tones, paired with rich serif typography and generous margins, to evoke the aesthetic of an old library book or a set of field notes.

## Directory / File Schema Expectations
The template file layout adheres to the following structural schema:
- CSS styling is mapped to `css/theme-overgrown.css` and is loaded via the `$assets_root$` path.
- Includes Google Font imports to load the elegant serif `Cormorant Garamond` for headings and the highly readable `Lora` for body text.
- The layout is structured using the `rk-shell` class, with the `$title$` variable populated inside the main header container, and the `$body$` variable populated within the `rk-article` container.

## Preservation Notes
Avoid bloating the layout with external assets, unnecessary scripts, or custom icons. Ensure that the serif typography definitions provide graceful fallbacks to standard system serifs (e.g., Georgia, Times New Roman). This ensures that the layout maintains its visual elegance and structural consistency even under offline conditions.

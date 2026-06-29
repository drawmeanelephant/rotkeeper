---
title: "Theme Suite (x5)"
description: "Defines CSS variables, fonts, and specific layouts for themes."
status: "complete"
---

### Architectural Intent
The dark layout theme is architected for strict utilitarian performance and low-light reading ergonomics. It leverages a high-contrast palette of near-black backgrounds and stark light-grey/white text to emulate the minimal, low-friction environment of modern terminal editors. Visual noise is eradicated. No hydration. Just bones.

### Directory / File Schema Expectations
The template relies on a rigid directory and variable schema to guarantee Pandoc compilation:
- **CSS Mappings**: Requires styling mapped to `css/theme-dark.css`, dynamically loaded via the `$assets_root$` variable path.
- **Typography**: Executes a network-level Google Font import targeting the `Inter` sans-serif font family.
- **DOM Structure**: Content is encapsulated in a primary `rk-shell` container, with the main `body` strictly enforcing the `rk-page rk-page--blog` class cascade.
- **Data Injection**: Expects `$title$` to be emitted precisely within the `rk-title` header block, and `$body$` to be injected directly into the `rk-article` container. Deviations will break the render state.

---
target_file: "bones/templates/theme-daisy.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-daisy.css`. It uses navbar, button, badge,
card, and card-body classes, a config-driven navigation slot, one H1 page
title, conditional description/date/author regions, and a literal body slot.
The footer carries the loaded version and optional asset metadata and tags.

The stylesheet imports the locally vendored DaisyUI 5.7.22 component and
theme files. `palette` becomes a `data-theme` attribute, not a
`palette-*` class. Without that attribute, the stylesheet supplies its
dracula defaults.

See the [DaisyUI map](../../daisyui-map.html),
[Oliver contract](../../oliver-contract.html),
[theme guidance](../../themes.html), and
[creating themes](../../creating-themes.html).

### Limits

The template itself adds no JavaScript, CDN link, or Node build step.
It differs from `theme-daisy-vanilla.html` only in the stylesheet href;
the CSS dependencies and palette coverage are not the same.

The stylesheet uses the vendored theme definitions for named palettes.
The static accessibility auditor's hex-token checks do not prove every
oklch palette passes.

### Cautions

Publish both vendored imports with the entry stylesheet. An unknown
`data-theme` value falls back to the vendored base palette, not necessarily
the absent-attribute dracula defaults.

Keep the navigation slot literal and preserve the shared component classes.
This HTML wrapper does not remove the raw-HTML restrictions of the
[XHTML profile](../../xhtml-profile.html).

---
target_file: "bones/templates/theme-pride.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-pride.css`. It includes a config-driven
site-navigation slot, one H1 page title, conditional description and
date/author/palette metadata, and a literal body slot inside `.pride-card`.
The footer carries the loaded version and optional asset metadata and tags.

`palette` adds a root class. The stylesheet defines `trans`, `bi`, and
`sunset` scopes. See [theme guidance](../../themes.html),
[creating themes](../../creating-themes.html), and the
[Oliver contract](../../oliver-contract.html).

### Limits

The `PRIDE 3.8` badge and telemetry text are fixed labels, not the Rotkeeper
version or measured timing. The scroll indicator, ambient mesh, and divider
are marked `aria-hidden="true"`.

The template has no script element. Palette values are class names, not a
validated selection.

### Cautions

Use the stylesheet's palette names to select a defined scope. The live
Rotkeeper version is the footer's `$version$`, not the header badge.

Keep navigation in the literal `<site-nav></site-nav>` slot. This is an
HTML wrapper, not the variant required by the
[XHTML guide](../../xhtml-profile.html).

---
target_file: "bones/templates/theme-daisy-vanilla.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This wrapper shares the DaisyUI template's markup; only the stylesheet href
changes to `css/theme-daisy-vanilla.css`. The stylesheet hand-defines the
navbar, button, badge, and card classes without vendored imports.

The wrapper includes a config-driven navigation slot, one H1 page title,
conditional description/date/author regions, a literal body slot, and a
version/asset-metadata/tags footer. `palette` still becomes `data-theme`.

See the [DaisyUI map](../../daisyui-map.html),
[Oliver contract](../../oliver-contract.html),
[theme guidance](../../themes.html), and
[creating themes](../../creating-themes.html).

### Limits

The stylesheet ships only its hand-written dracula colors. The template's
`data-theme` attribute does not supply the vendored twin's other palettes.
There is no script element, external stylesheet link, or CSS import.

Matching markup does not imply that every DaisyUI component available in
the vendored stylesheet is implemented by this stylesheet.

### Cautions

Do not infer palette support from the copied template comment; check the
vanilla stylesheet. Any palette value still uses its dracula color tokens.

Keep the shared component classes and navigation slot aligned with the
vendored twin. This HTML wrapper is not an XHTML variant; see the
[XHTML guide](../../xhtml-profile.html).

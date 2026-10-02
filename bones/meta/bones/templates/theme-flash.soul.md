---
target_file: "bones/templates/theme-flash.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-flash.css`. It includes a config-driven
site-navigation slot, one H1 page title, conditional description and
date/author/palette metadata, and a literal body slot inside `.flash-card`.
The footer includes the loaded version and optional asset metadata and tags.

`palette` adds a root class. The stylesheet defines `nova`, `aurora`, and
`hyper` scopes. See [theme guidance](../../themes.html),
[creating themes](../../creating-themes.html), and the
[Oliver contract](../../oliver-contract.html).

### Limits

The `FLASH 3.8` badge and `0.0ms` telemetry are fixed text, not the Rotkeeper
version or a measured render duration. The scroll indicator, ambient mesh,
and divider are marked `aria-hidden="true"`.

The template has no script element. Palette values are inserted into a
class name without template-side validation.

### Cautions

Use a defined stylesheet scope for palette selection. The footer's
`$version$` is the runtime version; the header badge does not track it.

The adapter fills navigation after wrapping, so keep the literal slot.
This is an HTML wrapper; see the [XHTML guide](../../xhtml-profile.html)
before selecting an XHTML body profile.

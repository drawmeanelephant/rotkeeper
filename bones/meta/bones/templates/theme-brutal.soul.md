---
target_file: "bones/templates/theme-brutal.html"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This HTML wrapper links `css/theme-brutal.css` and inserts `$body$` into
`.brutal-body`. It has one H1 title, optional description and date, and a
footer containing the loaded version and conditional author, asset metadata,
and tags.

`palette` adds `class="palette-$palette$"` to the root element. The stylesheet
defines `mac`, `unix`, and `pwsh` palette scopes. See
[theme guidance](../../themes.html),
[creating themes](../../creating-themes.html), and the
[Oliver contract](../../oliver-contract.html).

### Limits

There is no site-navigation slot or script element. The fixed overline is
marked `aria-hidden="true"`; it is decoration rather than a runtime status.

Palette names are inserted as classes, not validated by the template.
A value without a corresponding stylesheet scope does not select a new
palette.

### Cautions

The version label comes from the loaded Rotkeeper version, not page
frontmatter. Preserve the literal body slot and conditional footer fields
when changing the wrapper.

This is an HTML wrapper. See the [XHTML guide](../../xhtml-profile.html)
before using an XHTML body profile.

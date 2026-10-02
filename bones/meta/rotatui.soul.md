---
target_file: "rotatui.sh"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This standalone Gum interface selects commands from the dispatcher beside
the script. It provides menus for rendering, scaffolding, initialization,
packaging, status, assets, audits, documentation, version bumps, and tests.
Selected commands retain their own filesystem effects.

`glow` supplies Markdown previews when present; otherwise the interface uses
`gum format` and `gum pager`. Optional `skate` saves the last scaffold
subdirectory and slug after a successful creation. Preview styling uses the
page's template field or the legacy `default_template` setting.

Command spinners capture output in temporary logs and display the result.
`RK_SPINNER` overrides the selected spinner. Gum versions recognized as
2.0.2 or later skip the legacy echo-off and input-drain wrapper.

### Limits

There is no dispatcher command for this interface, no static help block,
and no command-line help, version, or dry-run parser. Dry-run choices exist
only in the relevant menus and pass flags to their selected commands.

Preview, fallback template discovery, and script-reference browsing use
fixed `home/content` and `bones/templates` paths. They do not follow every
layout mapping or the registry's default-template precedence.

The interface requires interactive terminal input and Gum. `glow` and
`skate` are optional; missing companions do not prevent startup.

### Cautions

Menus can run real writes, including `new`, `init`, `assets`, `dip`, `bump`,
and packaging. Use a menu's dry-run choice where offered; the interface has
no global preview mode.

The normal command paths remove their temporary logs after use. Legacy
spinner handling saves terminal settings, disables echo, drains input, and
restores the settings on exit or interruption. An unrecognized Gum version
uses that legacy path when terminal settings are available.

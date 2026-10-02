---
reference_contract: rotkeeper.command-reference.v1
title: rotatui.sh
slug: rotatui
target_file: rotatui.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Standalone Gum-powered interactive TUI companion for Rotkeeper
---

# rotatui.sh

## Overview

Standalone Gum-powered interactive TUI companion for Rotkeeper

Source: `rotatui.sh`.

## Usage

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Options

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Examples

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Exit codes

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Reads and writes

**Environment:** requires `gum`; optionally uses `glow` for previews and `skate` for saved choices. Reads `RK_SPINNER`, terminal state, and the dispatcher beside this file.

**Working directory:** none for command execution; dispatcher paths resolve against this script location.

**Inputs and outputs:** reads interactive terminal input and invokes dispatcher commands selected by the user. Writes temporary command logs and may save scaffold choices through `skate`. Selected commands perform their own filesystem changes. This script has no command-line help or dry-run parser; DIP documents missing help sections explicitly.

## Side effects

No side effects are documented in script annotations.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

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

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.

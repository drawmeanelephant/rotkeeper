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

No sidecar notes are documented for `rotatui.sh`.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.

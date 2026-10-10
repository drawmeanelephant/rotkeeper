---
reference_contract: rotkeeper.command-reference.v1
title: rc-preflight.sh
slug: rc-preflight
target_file: bones/scripts/rc-preflight.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Report Oliver renderer availability and compatibility
---

# rc-preflight.sh

## Overview

Report Oliver renderer availability and compatibility

Source: `bones/scripts/rc-preflight.sh`.

## Usage

```bash
rotkeeper.sh preflight [options]
```

## Options

```text
--verbose        Show detailed findings
--dry-run        Report the check without invoking the Oliver binary
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh preflight              # Verify rendering is ready
bash rotkeeper.sh preflight --verbose    # Show discovery details
```

## Exit codes

```text
0    Rendering ready
1    Renderer missing or unusable (with one actionable setup message)
```

## Reads and writes

**Environment:** reads DRY_RUN, OLIVER_BIN, RK_OLIVER_BIN, SCRIPT_DIR, TMP_DIR, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** discovers Oliver using `RK_OLIVER_BIN` then `PATH`, checks executability, and smoke-renders through the real CLI with the configured input format and HTML/XHTML profile.
Nonzero, empty, or non-HTML render output fails with an actionable setup message. The shared check also gates render. Real runs create and remove a private `TMP_DIR/oliver-preflight.XXXXXX` scratch directory holding the smoke `.md`, `.html`, and `.log`, so concurrent runs never share files; dry-run skips binary invocation. See `home/content/docs/oliver-contract.md`.

## Side effects

No side effects are documented in script annotations.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

The command delegates discovery and the live smoke render to
`rk_oliver_preflight` in `rc-utils.sh`. `render` uses the same helper, so both
commands report the same discovery and smoke-render failures.

An explicit `RK_OLIVER_BIN` takes precedence over `oliver` on `PATH`. The
helper invokes the configured input format and adds `--to xhtml` only for
the site's XHTML profile. It requires a zero exit status and nonempty output
containing at least one HTML element. Oliver emits markup for the smoke
heading in every input format and profile, so an executable that only echoes
its arguments or its input fails.
See the [Oliver contract](../../oliver-contract.html).

### Limits

The smoke input is a single heading, not a content or template audit. Passing
does not test `meta`, `plan`, `wrap`, or `manifest`, validate the installed
commit, or prove that every page can render. The HTML check tests output
shape, not identity: a wrapper that prints any markup passes.

`--dry-run` skips the helper entirely and returns success with a skipped-check
message. It does not establish that Oliver is present or usable.

### Cautions

A non-executable explicit override fails instead of falling back to `PATH`.
Check the override first when discovery fails.

A live check writes the smoke document, output, and stderr into a private
`oliver-preflight.XXXXXX` directory under `TMP_DIR`, so concurrent runs never
share files. The directory is removed afterwards, including on interruption
through the exit trap; only an untrappable kill can leave one behind, and it
does not affect later runs. Shared bootstrap logging also writes a run log,
including during `--dry-run`; help and version exit before that bootstrap.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.

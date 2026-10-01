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
Nonzero or empty render output fails with an actionable setup message. The shared check also gates render. Real runs create and remove `TMP_DIR/oliver-preflight-smoke.md`, `.html`, and `.log`; dry-run skips binary invocation. See `home/content/docs/oliver-contract.md`.

## Side effects

No side effects are documented in script annotations.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

No sidecar notes are documented for `bones/scripts/rc-preflight.sh`.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.

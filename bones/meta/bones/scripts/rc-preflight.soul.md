---
target_file: "bones/scripts/rc-preflight.sh"
reviewed: "2026-10-09"
reviewed_against: "0.8.1"
---

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

---
title: "version: canonical version source"
target_file: "bones/config/version"
date: "2026-08-11T22:00:00Z"
template: "rotkeeper-doc.html"
description: "The one plain version source read by scripts, dispatcher output, release names, tests, and docs."
---

# bones/config/version

The single canonical version source for Rotkeeper. It is a plain text file
containing one semver-style version line, currently `0.8.1`.

## Who reads it

- `rotkeeper.sh` reads it for dispatcher `--version`, the help header, and the default release version.
- `rc-utils.sh` (`rk_load_version`) loads `VERSION` for dispatcher scripts.
- `rc-bump.sh` reads it as the current version and writes a requested version change.
- `rc-status.sh` reports the loaded value as `canonical_version` and identifies its source.
- `rc-release.sh` uses the loaded version to name the distribution unless an explicit version is given.
- `rc-oliver-adapter.sh` supplies the loaded version to the `$version$` template token.

## How to change it

Use the bump command to update the version together with CHANGELOG and the
roadmap:

```bash
bash rotkeeper.sh bump --patch -m "message"
bash rotkeeper.sh bump --minor -m "message"
bash rotkeeper.sh bump --major -m "message"
bash rotkeeper.sh bump --to 0.8.2 -m "message"
```

`rc-bump.sh` validates the target as semver-style (`X.Y.Z`), writes the new
version here, and prepends the matching release entry in `CHANGELOG.md`.

## Overrides

`ROTKEEPER_VERSION` overrides the runtime value read from this file, but never
changes bump's version calculation. Bump reads the canonical file.

## Navigation

- [Config index](index.html)
- [Bones documentation](../index.html)

## Reads and writes
<!-- DIP-ENV-EXTRACTED: 2026-10-01T21:17:26Z -->

This file is not a script; no script environment contract applies.
## Usage
<!-- DIP-HELP-EXTRACTED: 2026-10-01T21:17:26Z -->

This file has no command-line interface.
## History
<!-- DIP-HISTORY-EXTRACTED: 2026-10-01T21:17:26Z -->

### [0.5.3] - 2026-08-13

- Made preflight gate on a live Oliver smoke render instead of a version range (Oliver's CLI is provisional and has no stable release yet); `render` routes its failure path through the same check so diagnostics cannot drift, and `scripts/setup-jules.sh` builds Oliver from source with Zig 0.16.

### [0.5.2] - 2026-08-12

- Added the `preflight` dispatcher command: one Apex availability check (discovery, executability, 1.1.x version range, runnable smoke) with a single actionable setup message; `render` routes its failure path through the same check so diagnostics cannot drift.

### [0.4.1] - 2026-07-22

- Added a dispatcher-backed, version-aware microbump flow and parameterized the
  release test against the dispatcher version.

### v0.2.6-dev

- Modified `README.md` to reflect testing support and current dev version

### [0.3.1.3] - 2026-06-19

- Add --version flag to all rc-*.sh scripts

## Notes
<!-- DIP-SOUL-EXTRACTED: 2026-10-02T01:22:51Z -->


### Design

This plain-text file contains the canonical Rotkeeper version, currently
`0.8.1`. The dispatcher and `rk_load_version` in `rc-utils.sh` read it,
remove whitespace, and strip a leading `v`. The adapter feeds the loaded
value into the `$version$` template token.

Use the [bump command](../scripts/rc-bump.html) to change the version together
with CHANGELOG and the roadmap entry.

### Limits

The runtime readers do not validate semantic-version syntax. A missing or
empty file gives `unknown` unless a runtime override supplies a value.
`rk_load_version` also accepts a `VERSION_FILE` override; the dispatcher
reads the canonical path directly.

`rc-bump.sh` requires a numeric `X.Y.Z` canonical version and target. It reads
the canonical file for its calculation, not `ROTKEEPER_VERSION`.

### Cautions

`ROTKEEPER_VERSION` changes the runtime value without changing this file.
Rendered version labels can therefore differ from the canonical value.

Changing this file alone does not update CHANGELOG or the roadmap. Bump does
not commit unless `--commit` is supplied, and does not push.

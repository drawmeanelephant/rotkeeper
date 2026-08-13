---
title: "Writing a New Rotkeeper Ritual"
slug: new-ritual
template: rotkeeper-doc.html
version: "1.0"
updated: "2026-08-13"
description: "The expected shape of a new rc-*.sh ritual: header, bootstrap, flags, dispatcher wiring, DIP/autopsy registration, boundary discipline, and required validation."
tags:
  - rotkeeper
  - development
  - reference
---

# Writing a New Rotkeeper Ritual

Every Rotkeeper command is a small Bash ritual under `bones/scripts/rc-<name>.sh`, invoked through the dispatcher. This page records what a new ritual must do to be accepted into the system. It is derived from the current scripts' common shape (`rc-preflight.sh` is a minimal complete example).

## Where new behaviors belong

- **Ritual scripts** live in `bones/scripts/rc-<name>.sh` and are invoked **only** via the dispatcher: `bash rotkeeper.sh <name>`. Do not call `bones/scripts/rc-*.sh` directly.
- Shared helpers belong in `rc-utils.sh` — do not copy them into a new ritual.
- A new ritual is a **new subsystem or dispatcher command**: adding one requires explicit human approval per the repository rules.

## Required shape (in order)

1. **Shebang and strict mode:**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   IFS=$'\n\t'
   ```
2. **Header block** identifying the script, its purpose, version, and update date. Keep the `Project / Script / Purpose / Version / Updated` layout used by the other rituals.
3. **`show_help()`** with a `--help`/`-h`, `--version`/`-v`, and `--dry-run` option (plus `--verbose`) consistent with the other rituals. The help text becomes the `DIP-HELP-EXTRACTED` pillar on the script's DIP page, so write it as the authoritative usage reference.
4. **Bootstrap** (always, in this order):
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
   rk_init_script "rc-<name>" "$@"
   ```
   `rk_init_script` parses common flags, installs traps, loads the canonical environment (`rk_load_env strict` — do not `source rc-env.sh` yourself), and opens the log. `ROT_SKIP_ENV=true` is reserved for help extraction by `rc-autopsy.sh`.
5. **Version**: read via the shared `rk_load_version` (sourced by rc-utils.sh). Never hard-code version strings.

## Registration (this is where rituals rot)

- **Dispatcher**: add a `case` arm in `rotkeeper.sh` mapping `bash rotkeeper.sh <name>` to `bash "$BONES/rc-<name>.sh" "$@"`, and mention the command in the dispatcher help block.
- **Autopsy whitelist**: `rc-autopsy.sh` only help-extracts scripts in its `PERMITTED_RITUALS` list. Add the new ritual there, or it silently vanishes from the help report and DIP pages show *no help block found* (this bit `rc-preflight.sh` in 0.5.2).
- **DIP**: no action needed — the fsbook catalog discovers the script and DIP stubs `home/content/docs/bones/scripts/rc-<name>.md` automatically on the next `book --fsbook && dip` run. Optionally write a `.soul.md` sidecar under `bones/meta` to feed the Necromancer's Notes pillar.
- **Tests**: the harness (`bones/scripts/rc-test.sh`) regenerates `crypt`/`busy`/`sterile` fixtures from `bones/scripts/rc-*.sh`, so a new ritual is exercised by `bash rotkeeper.sh test` once it exists in the tree. If the ritual has workflow contracts, extend the harness; if it is a new command, add a command-contract or removed-command regression as appropriate.

## Behavior rules

- **Boundaries**: every file a ritual reads or writes must stay inside its expected root (content under `home/content`, output under `output`, reports under `bones/reports`, binders under `bones/book-reports`). Use the shared `rk_canonical_path` resolution — never raw string-prefix checks.
- **Destructive paths**: honor `--dry-run` on every destructive operation and use the output-ownership marker rules for anything deleting under `output`.
- **Dependencies**: preflight (`require_bins` / `require_sha256`) each external tool only where the ritual actually needs it; prefer the shared wrappers (`rk_sha256`, checksum selection) over per-script reimplementation.
- **Quoting**: quote expansions unless deliberate shell semantics require otherwise; preserve the repository `.shellcheckrc` exemptions rather than adding blanket suppressions.
- **Side effects**: log file writes, deletes, archives, and Git operations clearly — the echoes hang around in `bones/logs`.

## Validation before merge

1. `bash -n` on the new script.
2. `shellcheck` with the repository `.shellcheckrc`.
3. `bash rotkeeper.sh test` (full harness — the new script is copied into every fixture pass).
4. `bash rotkeeper.sh status`.
5. The relevant `--dry-run`s.
6. Regenerate `book --fsbook` + `dip` so the new ritual's reference page exists before the docs are reviewed.

Keep the ritual reviewable as a single slice, and keep the harness green at every step.

**Back to**: [Documentation overview](index.html) · [Dispatcher reference](rotkeeper-reference.html)
---
title: "Writing a new Rotkeeper command"
slug: new-ritual
template: rotkeeper-doc.html
version: "1.0"
updated: "2026-10-01"
description: "Command development requirements, the help page contract, plain-language style, sidecar schema, and validation."
tags:
  - rotkeeper
  - development
  - reference
---

# Writing a new Rotkeeper command

Every Rotkeeper command is a Bash script invoked through the dispatcher.
This page defines the script requirements and the
[command reference contract](#command-reference-contract). Use
`rc-preflight.sh` as a minimal script example and the
[generated assets reference](bones/scripts/rc-assets.html) as the help-page
model.

## Where new behaviors belong

- Command scripts live in `bones/scripts/rc-<name>.sh`. Invoke them only through `bash rotkeeper.sh <name>`, not directly.
- Shared helpers belong in `rc-utils.sh`. Do not copy them into a command script.
- Adding a script, subsystem, dependency, or dispatcher command requires explicit human approval.

## Required shape (in order)

1. **Shebang and strict mode:**
   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   IFS=$'\n\t'
   ```
2. **Header block** identifying the script, purpose, version, and update date. Keep the `Project / Script / Purpose / Version / Updated` layout. Include `Env assumptions`, `CWD assumptions`, and `Input/Output contracts`. Name actual inputs, outputs, dependencies, and dry-run exceptions.
3. **Help block** between `# @HELP` and `# @END-HELP`, containing a title, Usage, Description, Options, realistic Examples, and Exit codes. Use the literal `{VERSION}` token. The shared emitter `rk_show_help` substitutes the loaded version for `--help`/`-h`; `rc-autopsy.sh` extracts the same text. Define a custom `show_help` only for runtime content, such as `rc-new` template completion. Support `--version`/`-v`, `--dry-run`, and `--verbose` where applicable. Show dispatcher commands in examples.
4. **Bootstrap** (always, in this order):
   ```bash
   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
   source "$SCRIPT_DIR/rc-utils.sh" || { echo "FATAL: cannot source rc-utils.sh" >&2; exit 1; }
   rk_init_script "rc-<name>" "$@"
   ```
   `rk_init_script` parses common flags, installs traps, loads the canonical environment through `rk_load_env strict`, and opens the log. Do not source `rc-env.sh` directly. `ROT_SKIP_ENV=true` is reserved for help extraction by `rc-autopsy.sh`.
5. **Version**: read via the shared `rk_load_version` (sourced by rc-utils.sh). Never hard-code version strings.
6. **Sidecar**: provide a reviewed file sidecar under `bones/meta` using the [sidecar contract](#sidecar-contract). Keep explanatory details there, rather than editing a generated reference page.

## Registration

- **Dispatcher**: add a `case` arm in `rotkeeper.sh` mapping `bash rotkeeper.sh <name>` to `bash "$BONES/rc-<name>.sh" "$@"`, and mention the command in the dispatcher help block.
- **Autopsy whitelist**: add the script to `PERMITTED_RITUALS` in `rc-autopsy.sh` for its standalone help report. DIP reads static script comments directly and does not depend on that allowlist or report.
- **DIP**: `book --fsbook` discovers core scripts. `dip` generates missing reference pages and rebuilds pages whose `target_file` matches the script, at the mirrored path under the active `DOCS_DIR`. Authored pages without matching ownership are not replaced.
- **Tests**: `bones/scripts/rc-test.sh` copies command scripts into `crypt`, `busy`, and `sterile` fixtures. Extend its workflow assertions and command-contract coverage for new behavior.

## Command reference contract <a id="command-reference-contract"></a>

The contract identifier is `rotkeeper.command-reference.v1`. DIP owns command
reference pages; authors own task guides. Change the script annotations,
help block, sidecar, or CHANGELOG when reference information is missing or
wrong. Do not repair a generated page by hand.

### Frontmatter

Use this key order and shape. Values shown here are placeholders, not
additional copies of command metadata:

```yaml
---
reference_contract: "rotkeeper.command-reference.v1"
title: "rc-name.sh"
slug: "rc-name"
target_file: "bones/scripts/rc-name.sh"
template: "rotkeeper-doc.html"
status: "active"
version: "<loaded Rotkeeper version>"
author: "Rotkeeper DIP"
project: "Rotkeeper"
description: "<script Purpose line>"
---
```

`target_file` is repository-relative and determines ownership. `version`
comes from the shared version loader, not the script's historical header
stamp. Omit generation timestamps so an unchanged source produces unchanged
bytes. `status: active` identifies the page type; it is not evidence of
completeness.

### Section order and sources

Use exactly one H1, the script filename. Every section below is an H2 and
appears once, in this order:

| Section | Authoritative source | Content |
| --- | --- | --- |
| Overview | Header `Purpose` | What the command does |
| Usage | `@HELP` Usage | Dispatcher syntax in a Bash code block |
| Options | `@HELP` Options | Flags, arguments, defaults, and relevant modes |
| Examples | `@HELP` Examples | Runnable dispatcher examples in a Bash code block |
| Exit codes | `@HELP` Exit codes | Success, expected failures, and propagated statuses |
| Reads and writes | Header `Env assumptions`, `CWD assumptions`, `Input/Output contracts` | Actual variables, dependencies, input/output paths, and dry-run behavior |
| Side effects | `SIDE EFFECT (...)` annotations | Writes, moves, deletions, and relevant guards |
| Notes | Reviewed file sidecar body | Design, Limits, and Cautions |
| History | CHANGELOG | Whole matching bullets with continuation lines, grouped by release |

Use H3 for Notes subheadings and release headings in History. Deeper headings
are unnecessary. Keep usage, options, and exit-code text literal; do not
interpret flags or paths as Markdown markup.

If a source is missing, retain the section and state what is not documented.
Do not invent an overview, imply that an empty section is complete, or
replace per-script contracts with a generic environment list. Description
text that carries facts beyond Purpose must be incorporated into Purpose,
the contracts, or the sidecar. The full engine work in #327 must include
command-specific help sections, such as Modes, under Options.

### Plain-language style

- Use plain, factual language in all help pages, titles, headings, and sidecars.
- Do not use emoji, lore, limericks (including hidden comments), opinion, rhetorical questions, or decorative prose.
- Use sentence-case titles and headings. Preserve the spelling and case of the project name, script filenames, command names, and source identifiers.
- Use one term per concept: command for a dispatcher action, script for its Bash file, reference page for generated command documentation, task guide for authored instructions, and sidecar for explanatory metadata.
- Keep exactly one H1 per page. Use H2 sections and H3 subsections without skipping heading levels.
- Format commands, flags, paths, environment variables, and literal examples as code. Prefer short sentences with an explicit actor and action.
- State conditions and limits precisely. Distinguish an asset mirror from reference discovery, skipped paths from fatal errors, and asset dry-run guarantees from bootstrap logging.
- Check every behavioral claim against source and shared helpers. Generated reports and old sidecars are not authoritative.

The selected pillar names are **Notes** and **History**, replacing
`Necromancer's Notes` and `Ritual History`. Keep the existing
`DIP-SOUL-EXTRACTED` and `DIP-HISTORY-EXTRACTED` marker identifiers. The
engine migrates marker-owned headings alongside reference generation,
including boundary recognition, stub templates, and TODO counting. It also
recognizes old heading names while reading older sidecar tails.

## Sidecar contract <a id="sidecar-contract"></a>

File sidecars use this frontmatter:

```yaml
---
target_file: "bones/scripts/rc-name.sh"
reviewed: "YYYY-MM-DD"
reviewed_against: "<Rotkeeper version>"
---
```

Use exactly these H3 body headings: Design, Limits, and Cautions. Describe
implementation choices, restrictions, and operational risks without
duplicating help text. Use an explicit statement when a category has no
additional information. Do not add a page H1, a Notes wrapper, DIP markers,
or a self-stitched copy of the body.

For directory sidecars, use `title`, `description`, and `reviewed`, with H3
body headings Purpose and Contents and conventions. Directory metadata is
merged into generated index frontmatter by `rc-glue`, so include only keys
intended for that page. Do not add file-only ownership/version keys.

Sidecar paths mirror their targets under `bones/meta`, with the final file
extension removed before `.soul.md`; directory paths keep the directory name.
Review each claim against the target and shared helpers, then update the
review date and version together. Remove generated tails at the source.
The existing sidecar migration and `rc-new --soul` scaffold alignment belong
to #329; the assets sidecar is the first reviewed example.

## Pilot findings and follow-up tasks

The [assets pilot](bones/scripts/rc-assets.html) is generated by DIP from
`rc-assets.sh`, its sidecar, and CHANGELOG. Its `reference_contract` field
identifies the contract. The engine applies the same source-based rebuilding
to all owned script references, whether or not that field already exists.
Internal libraries and standalone tools without static help retain every
section and explicitly state what is not documented; DIP never executes them
to discover their behavior.

Comparison with the previous hand-written page found these source gaps,
now corrected for the pilot:

- Purpose and Description incorrectly described selective reference scanning. The command mirrors the source tree.
- Contract headers omitted concrete read/write paths, dependencies, ownership-marker behavior, and bootstrap log writes during dry-run.
- Help omitted dependency exit code 2, propagated I/O statuses, and dispatcher equivalents of the old direct-script examples.
- Side effects named `bones/archives` instead of `bones/archive` and omitted the shared ownership-marker write.
- The sidecar contradicted the path allowlist, duplicated its own body, and lacked the workflow and manifest example. It now carries those verified facts, the empty-manifest format, and operational limits.

Follow-up tasks for [#327](https://github.com/drawmeanelephant/rotkeeper/issues/327):

- [x] Extend the opt-in pilot to all command pages and missing scripts without overwriting authored task guides.
- [x] Harvest command-specific help sections, multiline contracts, and continuation lines in side-effect annotations; define and test missing-source fallbacks.
- [x] Use complete CHANGELOG bullets only, including matches on continuation lines, with stable release grouping and byte-idempotent generation.
- [x] Migrate Notes and History together with section ordering, boundary handling, stub templates, TODO counting, and legacy page rewrites.

Follow-up tasks for [#329](https://github.com/drawmeanelephant/rotkeeper/issues/329):

- [ ] Apply the agreed file/directory schemas and plain-language body headings; remove all self-stitched tails and update the scaffold.
- [ ] Check other sidecars for the same drift as assets: false discovery claims, incorrect archive paths, missing dry-run exceptions, unsupported dependency/security claims, and omitted format or deletion limits.
- [ ] Record source-reviewed dates/versions and resolve unreachable sidecars before publishing them.

## Behavior rules

- **Boundaries**: keep reads and writes inside their expected roots, using the active layout. Use shared canonical path helpers, not raw string-prefix checks.
- **Destructive paths**: honor `--dry-run` on every destructive operation and use the output-ownership marker rules for anything deleting under `output`.
- **Dependencies**: check external tools with `require_bins` and `require_sha256` where needed. Prefer shared wrappers such as `rk_sha256`.
- **Quoting**: quote expansions unless deliberate shell semantics require otherwise; preserve the repository `.shellcheckrc` exemptions rather than adding blanket suppressions.
- **Side effects**: annotate writes, deletes, moves, and Git operations with `SIDE EFFECT (...)` comments. Log their outcomes clearly.

## Validation before merge

1. `bash -n` on the new script.
2. `shellcheck` with the repository `.shellcheckrc`.
3. `bash rotkeeper.sh test` (the full harness, including every layout).
4. `bash rotkeeper.sh status`.
5. The relevant `--dry-run`s.
6. Regenerate `bash rotkeeper.sh book --fsbook` and `bash rotkeeper.sh dip`. Check the reference against its sources and run DIP again to confirm unchanged page bytes.

On macOS, report a `realpath -m` portability failure rather than weakening
the harness.

**Back to**: [Documentation overview](index.html) · [Dispatcher reference](rotkeeper-reference.html)
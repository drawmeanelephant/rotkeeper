# Rotkeeper Agent Operating Manual

## What this project is

Rotkeeper is a Bash-native, Oliver-driven static site and content system. Markdown with YAML frontmatter is its source format; it has no Node or application-framework runtime requirement.

Use the dispatcher for project work:

```bash
bash rotkeeper.sh <command>
```

Do not invoke `bones/scripts/rc-*.sh` directly.

## Renderer: Oliver

- Rendering runs through the [Oliver](https://github.com/drawmeanelephant/oliver) binary: `oliver render --from markdown < file.md`, stdin → stdout body HTML, stderr = warnings. Discovery order is `RK_OLIVER_BIN` override, then `oliver` on `PATH`. The authoritative contract is `home/content/docs/oliver-contract.md`.
- `bash rotkeeper.sh preflight` is the single renderer health check (discovery, executability, live smoke render); `render` routes through the same check. The adapter (`rc-oliver-adapter.sh`) strips a leading YAML frontmatter block before invoking Oliver.
- Oliver has no stable release yet: `setup-jules.sh` (and CI) builds it from source with Zig 0.16. GFM pipe tables (alignment colons, escaped pipes) are supported; task lists and footnotes are not part of CommonMark and render literally — keep content CommonMark-safe for those.

## The BHO model

- `bones/` is the system: scripts, configuration, templates, reports, logs, archives, and metadata.
- `home/` is author-managed content and assets.
- `output/` is generated site output. Do not edit it directly; change source content and render again.

The active layout is derived from `bones/config/rotkeeper.yaml` and `rc-env.sh`. Layout styles change layout-dependent paths only:

| Style | Content | Templates | Assets | Output |
| --- | --- | --- | --- | --- |
| `crypt` | `home/content` | `bones/templates` | `home/assets` | `output` |
| `busy` | `home/content` | `templates` | `assets` | `output` |
| `sterile` | `src/content` | `config/templates` | `src/assets` | `dist` |

`bones/` remains the system root in every layout. A serialized `paths` block, when present, is validated against the active layout and repository root.

## Hard rules

- Do not add scripts, dispatcher commands, dependencies, or architectural subsystems without explicit human approval.
- Modify existing files only unless the task explicitly authorizes a new file.
- Preserve `set -euo pipefail` and `IFS=$'\n\t'` in Bash scripts. Quote expansions unless deliberate shell semantics require otherwise.
- Use the established script bootstrap: source `rc-utils.sh` and call `rk_init_script`. Do not add direct `source rc-env.sh` calls; `rk_init_script` invokes `rk_load_env`.
- Treat DIP-generated documentation as incomplete reference material, not ground truth. A stub or `TODO:` marker is evidence that the document needs verification.
- Do not edit generated `output/` artifacts or rely on generated reports as the sole source of operational truth.
- Keep ShellCheck's current project exemptions intact. Do not add blanket exemptions for quoting, strict-mode, or subshell warnings.

### Repository control files

- `.agentignore` currently names `bones/book-reports`. No Rotkeeper runtime script reads this file; avoid treating that generated directory as ordinary source work unless the task requires it.
- `.blessed` currently contains only the version tag `v0.2.0`. `rc-dip.sh` ignores non-path entries, so it presently protects no paths.
- `bones/config/dip-whitelist.txt` exempts listed documentation pages from DIP's obsolete-document move check. It is not a general exemption from matrix reporting or pillar stitching.
- `.shellcheckrc` has targeted exemptions: `SC1090`, `SC1091`, `SC2034`, `SC2317`, `SC2181`, `SC2076`, `SC2053`, `SC2155`, and `SC2269`.

## Required validation

Before considering a change complete, run the checks that apply:

- `bash -n` on every modified Bash script.
- `shellcheck` on every modified Bash script, using the repository `.shellcheckrc`.
- `bash rotkeeper.sh test`.
- `bash rotkeeper.sh status`.
- The relevant dispatcher command with `--dry-run`, where that command supports it.

Report any unavailable tool, unsupported flag, or unrelated pre-existing test failure; do not conceal it by weakening checks.

The dispatcher maps `test` and `smoke` to the same harness. With `--dry-run`, the harness runs only its removed-command regression checks. A full `test` builds temporary `crypt`, `busy`, and `sterile` fixtures, initializes each with sample content, runs the release packager, verifies the canonical archive, verifies that deprecated `-lite` and `-full` archives are absent, and checks removed legacy commands. On macOS, report a failure at the harness's `realpath -m` preflight as a portability issue; do not weaken the test to make it pass.

## Binder and retrieval artifacts

Use the dispatcher for book generation:

- `bash rotkeeper.sh book --fsbook` creates the filesystem catalog consumed by DIP for core-file discovery.
- `--docbook` and `--docbook-clean` bind documentation; `--scriptbook-full` binds active scripts; `--configbook` binds configuration/templates.
- `--contentbook`, `--contentmeta`, and `--collapse` create content-oriented retrieval artifacts.
- Outputs belong under `bones/book-reports`; the binder enforces its write boundary and has a size safeguard. Use `--force-bind` only when the larger artifact is intentional.

Book outputs are generated retrieval aids, not authoritative policy. Verify the source scripts and configuration when a binder conflicts with them.

## Read before making assumptions

- `bones/scripts/rc-utils.sh`: shared helpers, canonical environment loading, traps, and `validate_layout_alignment`.
- `bones/scripts/rc-env.sh`: path derivation, layout styles, cached paths, and the environment idempotency guard.
- `bones/config/rotkeeper.yaml`: active configuration and any saved `paths` cache.
- `rotkeeper.sh`: supported dispatcher commands and their script mappings.
- `bones/scripts/rc-book.sh`: binder modes, report destinations, boundary checks, and size safeguards.
- `bones/scripts/rc-dip.sh`: documentation discovery, ownership, obsolete handling, pillar stitching, and matrix generation. Read its output critically.

## Project-specific gotchas

- `rk_load_env` validates path boundaries with canonical `realpath -m` or `readlink -m` resolution. Do not replace that with raw string-prefix checks.
- Environment loading is idempotent for the same repository root. `rc-init.sh` deliberately uses `FORCE_ENV_RELOAD=true` after writing path mappings; do not set it elsewhere without a specific reason.
- DIP moves an obsolete doc only with strong evidence: explicit `target_file` frontmatter whose target is no longer in the core inventory. Ambiguous docs are reported as unowned, not moved.
- An expected documentation path does not make generated text authoritative. Verify source scripts and configuration before changing behavior based on a DIP page.

## Tone

Content documentation may use Rotkeeper's necropolis voice. This file stays plain and procedural.

# ✨ Gemini Core Directives for Rotkeeper

If you are a Gemini agent (or a specialized subagent spawned by Antigravity) working within this workspace, these are your core directives for modifying or assisting with the Rotkeeper project.

**Current Version:** `v0.8.0`

## Context

Rotkeeper is a terminal-driven flat-file system for compiling markdown "tombs" into static HTML archives. It relies on bash scripting (the "rituals" in `bones/scripts/`), Oliver HTML rendering, and a strict separation of concerns. The dispatcher is `rotkeeper.sh`.

## Golden Rules for Gemini Agents

1. **Do not break the Bash Scripts**: The core of Rotkeeper is its `.sh` scripts. When editing them, always preserve the `set -euo pipefail` architecture, the `trap_err` / `cleanup` trap mechanics defined in `rc-utils.sh`, and the `main()` guard pattern.

2. **Respect the Subdirectories**:
   - `home/content/` — Strictly for user markdown input. Write `.md`, `.textile`, or `.cook` files here.
   - `home/content/messages/` — Preserved payloads and messages. Don't write here directly.
   - `home/assets/` — Static assets (CSS, images, JS). Copied to `output/assets/` during `assets`.
   - `output/` — Strictly for generated HTML. Never edit files here manually; edit source markdown or templates instead.
   - `bones/scripts/` — Where the system logic lives. All scripts source `rc-utils.sh` → `rc-env.sh`.
   - `bones/config/` — System configuration (`rotkeeper.yaml`, `version`, `dip-whitelist.txt`).
   - `bones/templates/` — HTML templates used during render.
   - `bones/archive/` — Pack archives (tomb tarballs).
   - `bones/tmp/` — Temporary staging.

3. **Use the Dispatcher**: Never invoke `bones/scripts/rc-*.sh` directly. Always run `./rotkeeper.sh <command>`. Use `./rotkeeper.sh help` to see available actions.

4. **Agent Testing (`lite` distribution)**: If tasked with testing the framework as a blind agent, you may be operating in the `lite` distribution which strips out `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CREDITS.md`, and content documentation (`home/content/docs/`, `home/content/help/`). The `lite` distribution injects a micro-README. Rely on this `GEMINI.md` file, `AGENTS.md`, and `./rotkeeper.sh help` to navigate.

## Quick Command Reference

| Command | Purpose |
|---------|---------|
| `init` | Full workspace initialization (paths + assets + render + scan) |
| `render` | Convert Markdown / Textile / Cooklang → HTML via Oliver |
| `pack` | Archive output as `.tar.gz` tomb & export `source_markdown` JSON (also: `--content`, `--self`) |
| `preflight` | Report Oliver renderer availability and compatibility |
| `release` | Package canonical framework distribution `.zip` |
| `scan` | Audit files against manifest |
| `assets` | Generate asset manifest and copy to output |
| `autopsy` | Catalog script help and file-write behavior into reports |
| `glue` | Auto-generate navigation glue for unindexed content directories |
| `links` | Audit rendered HTML links and local asset references |
| `a11y` | Audit theme accessibility (contrast, focus states, legibility) |
| `showcase` | Generate showcase preview pages for every HTML template |
| `dip` | Audit documentation coverage via DIP |
| `book` | Aggregate docs into binders (`--docbook`, `--scriptbook-full`, etc.) |
| `status` | Display system state summary |
| `bump` | Explicit semver bump (--major/--minor/--patch/--to) + changelog + git commit |
| `test` | Multi-layout integration test harness matrix (alias: `smoke`) |

## Available Templates

Use in frontmatter as `template: <name>` (or select via `theme_registry` in `rotkeeper.yaml`):

- `theme-spooky-dark.html` — Fira Sans/Fira Code journal-terminal theme (default)
- `theme-spooky-light.html` — Light reading variant of the Spooky theme
- `theme-spooky-dark-xhtml.html` — Strict XHTML variant of Spooky Dark
- `theme-dark.html` — Clean, flat dark theme layout
- `theme-light.html` — Academic parchment light theme
- `theme-brutal.html` — High-contrast monospaced brutalist layout
- `theme-kawaii.html` — Pastel playful theme
- `theme-overgrown.html` — Forest decay mossy aesthetic
- `theme-phosphor.html` — Amber phosphor CRT terminal aesthetic
- `theme-textpattern.html` — Classic editorial layout with site navigation
- `theme-necropolis.html` — Dedicated 404 Tomb-Not-Found theme
- `theme-daisy.html` — DaisyUI presentation layer prototype
- `theme-daisy-vanilla.html` — Zero-dependency twin of DaisyUI theme
- `rotkeeper-blog.html` — Blog-style layout
- `rotkeeper-doc.html` — Documentation with navigation

## Preserving Content

When generating content that should be preserved:
1. Write `.md` files with YAML frontmatter in `home/content/`.
2. Run `./rotkeeper.sh pack --content` to bundle into a `.tar.gz`.
3. The archive lands in `bones/archive/`.

## Workflow Example: Building a New Feature

If the user asks you to build a new feature (e.g., an "audit" command):
1. Add the dispatcher case in `rotkeeper.sh`.
2. Create `bones/scripts/rc-audit.sh` sourcing `rc-utils.sh` as a base.
3. Use `init_log "rc-audit"` for logging setup.
4. Wire `trap cleanup EXIT INT TERM` and `trap 'trap_err $LINENO' ERR`.
5. Implement logic inside a `main()` function.
6. Ensure it writes logs to `bones/logs/` and reports to `bones/reports/`.
7. Test it thoroughly: `./rotkeeper.sh test` runs dry-run validation on all scripts.

## Workflow Example: Generating Content

If tasked with creating a page or report:
1. Run `./rotkeeper.sh init` (if workspace is fresh).
2. Run `./rotkeeper.sh new my-report` to automatically scaffold your `.md` file in `home/content/` with correct YAML frontmatter.
3. Run `./rotkeeper.sh render` to compile.
4. Run `./rotkeeper.sh pack --content` to preserve your work.
5. Verify with `./rotkeeper.sh status`.

## Dependencies

**Required:** `bash` 4+, `sha256sum`, `yq` v4+, `gawk`
**Rendering (Oliver — default):** `oliver` binary via `RK_OLIVER_BIN=/path/to/oliver` or in `$PATH` (test matrix uses fixture binary)
**Rendering (Oliver only):** the Pandoc renderer has been removed
**Optional:** `jq` (pack JSON export & metadata), `rsync` + `zip` (release), `python3` (links audit), `bats` (test)

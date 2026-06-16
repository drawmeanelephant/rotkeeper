# ✨ Gemini Core Directives for Rotkeeper

If you are a Gemini agent (or a specialized subagent spawned by Antigravity) working within this workspace, these are your core directives for modifying or assisting with the Rotkeeper project.

**Current Version:** `v0.3.1`

## Context

Rotkeeper is a terminal-driven flat-file system for compiling markdown "tombs" into static HTML archives. It relies on bash scripting (the "rituals" in `bones/scripts/`), Pandoc, and a strict separation of concerns. The dispatcher is `rotkeeper.sh`.

## Golden Rules for Gemini Agents

1. **Do not break the Bash Scripts**: The core of Rotkeeper is its `.sh` scripts. When editing them, always preserve the `set -euo pipefail` architecture, the `trap_err` / `cleanup` trap mechanics defined in `rc-utils.sh`, and the `main()` guard pattern.

2. **Respect the Subdirectories**:
   - `home/content/` — Strictly for user markdown input. Write `.md` files here.
   - `home/content/messages/` — Ingested content from decentralized payloads. Don't write here directly.
   - `home/assets/` — Static assets (CSS, images, JS). Copied to `output/assets/` during `assets`.
   - `output/` — Strictly for generated HTML. Never edit files here manually; edit source markdown or templates instead.
   - `bones/scripts/` — Where the system logic lives. All scripts source `rc-utils.sh` → `rc-env.sh`.
   - `bones/config/` — System configuration. Don't edit `rotkeeper.yaml` directly unless needed.
   - `bones/templates/` — Pandoc HTML templates used during render.
   - `bones/archive/` — Pack archives (tomb tarballs).
   - `bones/releases/` — Release distributions.
   - `bones/ingested/` — Ingested archive vault.
   - `bones/tmp/` — Temporary staging.
   - `messages-from-my-friends/` — Decentralized inbox for `.tar.gz` payloads to be ingested.

3. **Use the Dispatcher**: Never invoke `bones/scripts/rc-*.sh` directly. Always run `./rotkeeper.sh <command>`. Use `./rotkeeper.sh help` to see available actions.

4. **Agent Testing (`lite` distribution)**: If tasked with testing the framework as a blind agent, you may be operating in the `lite` distribution which strips out `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CREDITS.md`, and content documentation (`home/content/docs/`, `home/content/help/`). The `lite` distribution injects a micro-README. Rely on this `GEMINI.md` file, `AGENTS.md`, and `./rotkeeper.sh help` to navigate.

## Quick Command Reference

| Command | Purpose |
|---------|---------|
| `init` | Full workspace initialization (reseed + assets + render + scan) |
| `render` | Convert Markdown → HTML via Pandoc |
| `pack` | Archive output as `.tar.gz` tomb (also: `--content`, `--self`) |
| `release` | Create `lite` and `full` distribution `.zip` files |
| `ingest` | Unpack `.tar.gz` from `messages-from-my-friends/` into content |
| `scan` | Audit files against manifest |
| `verify` | Check asset SHA256 integrity |
| `assets` | Generate asset manifest and copy to output |
| `index` | Build HTML index of rendered output |
| `sitemap` | Generate YAML sitemap from render logs |
| `templates` | List available Pandoc templates |
| `book` | Aggregate docs into binders (`--all`, `--scriptbook-full`, `--docbook`, etc.) |
| `meta` | Extract frontmatter metadata from content |
| `cleanup` | Back up and prune `bones/` (⚠️ destructive) |
| `reseed` | Reconstruct files from archive or bound markdown |
| `status` | Display system state summary |
| `bump` | Micro-version bump + changelog + git commit |
| `test` | Dry-run all scripts + Bats tests |

## Available Templates

Use in frontmatter as `template: <name>`:

- `rotkeeper-blog.html` — Blog-style layout
- `rotkeeper-doc.html` — Documentation with navigation
- `theme-dark.html` — Clean, flat dark theme layout
- `theme-light.html` — Clean, flat light theme layout (default)

## Decentralized Content Pipeline

When generating content that should be preserved:
1. Write `.md` files with YAML frontmatter in `home/content/`.
2. Run `./rotkeeper.sh pack --content` to bundle into a `.tar.gz`.
3. The archive lands in `bones/archive/` and can be copied to another repo's `messages-from-my-friends/` for ingestion via `./rotkeeper.sh ingest`.

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
2. Create your `.md` file in `home/content/` with YAML frontmatter:
   ```yaml
   ---
   title: "My Report"
   slug: my-report
   template: rotkeeper-blog.html
   ---
   ```
3. Run `./rotkeeper.sh render` to compile.
4. Run `./rotkeeper.sh pack --content` to preserve your work.
5. Verify with `./rotkeeper.sh status`.

## Dependencies

**Required:** `bash` 4+, `pandoc`, `sha256sum`, `yq` v4+, `gawk`
**Optional:** `jq` (pack), `rsync` + `zip` (release), `python3` (bump), `bats` (test)

# 🤖 Agent Guide to Rotkeeper

Welcome to the Rotkeeper repository. If you are an autonomous AI agent, LLM, or programmatic assistant exploring this project, this file serves as your comprehensive onboarding guide to the architecture, commands, and workflows.

## 🧭 The Core Philosophy

Rotkeeper is a terminal-based toolkit for rendering, archiving, and preserving the remains of Markdown-driven projects.
- **Inputs** are Markdown files (called "tombs") with YAML frontmatter.
- **Outputs** are rendered HTML files and `.tar.gz` archives.
- **Rituals** are bash scripts (`rc-*.sh`) that perform operations (rendering, packaging, scanning, ingesting).
- **The Dispatcher** is `rotkeeper.sh` — the single CLI entry point. Always use it.

## 📂 Architecture

```
.
├── rotkeeper.sh                 # CLI dispatcher — always start here
├── home/
│   ├── content/                 # Markdown source files — write your .md files here
│   │   └── messages/            # Ingested content from decentralized payloads
│   └── assets/                  # Static assets (CSS, images, JS) bundled into output
├── output/                      # Rendered HTML output — never edit directly
├── bones/                       # Internal system directory
│   ├── scripts/                 # Bash rituals (rc-*.sh) — the actual logic
│   ├── config/                  # System configs (render-flags.yaml, rotkeeper.yaml)
│   ├── templates/               # Pandoc HTML templates for rendering
│   ├── archive/                 # Pack archives (tomb-*.tar.gz, tombkit-*.tar.gz)
│   ├── releases/                # Versioned lite/full distribution .zip files
│   ├── ingested/                # Processed inbox .tar.gz files (moved here after ingest)
│   ├── reports/                 # Generated reports, binders, sitemaps, indexes
│   ├── logs/                    # Timestamped ritual logs
│   ├── tmp/                     # Temporary staging (used by release builds)
│   └── meta/                    # Extracted frontmatter metadata
├── messages-from-my-friends/    # Decentralized inbox — drop .tar.gz payloads here
├── AGENTS.md                    # This file
├── GEMINI.md                    # Gemini-specific agent directives
└── CHANGELOG.md                 # Version history
```


## 📋 Complete Command Reference

Run `./rotkeeper.sh help` for the built-in help, or reference this table:

| Command | Description |
|---------|-------------|
| `init` | Full initialization: bless scripts with `+x`, reseed workspace, generate starter `hello-world.md`, run assets + render + scan. Use `--force` to rebuild. |
| `render` | Convert Markdown tombs to HTML via Pandoc. Uses templates from `bones/templates/`. Archives output as timestamped `.tar.gz`. |
| `pack` | Archive rendered `output/` into a versioned tomb `.tar.gz` with embedded JSON metadata. Also exports Markdown to Pandoc JSON. |
| `pack --content` | Archive only `home/content/` (excluding `docs/`, `help/`, temp files). Use this to ship content to other repositories. |
| `pack --self` | Archive the full Rotkeeper system as a `tombkit-*.tar.gz`. |
| `release` | Create versioned `lite` and `full` distribution `.zip` files in `bones/releases/`. |
| `ingest` | Unpack `.tar.gz` payloads from `messages-from-my-friends/` into `home/content/messages/`. Moves processed archives to `bones/ingested/`. |
| `scan` | Audit files against `bones/manifest.txt`. Reports missing files, orphans, SHA256 mismatches. Supports `--json-only`, `--md-only`, `--include`, `--exclude`. |
| `verify` | Check `home/assets/` against SHA256 hashes in `bones/asset-manifest.yaml`. Use `--regen` to rebuild manifest first. |
| `assets` | Scan `home/assets/`, copy to `output/assets/`, generate `bones/asset-manifest.yaml` with checksums. |
| `index` | Build HTML index and Markdown binder from rendered files in `output/`. |
| `sitemap` | Parse latest render log and generate `bones/reports/site-index.yaml`. |
| `templates` | List all available HTML templates in `bones/templates/`. |
| `book` | Aggregate files into binders. Modes: `--scriptbook-full`, `--docbook`, `--docbook-clean`, `--configbook`, `--contentbook`, `--contentmeta`, `--collapse`, `--all`. |
| `meta` | Extract YAML frontmatter from all content tombs to `bones/reports/rotkeeper-contentmeta.yaml`. |
| `cleanup` | Back up `bones/`, then prune old backups and logs. `--days N` sets retention (default: 30). **Warning:** destructive — removes most of `bones/` contents. |
| `reseed` | Reconstruct source files from a `.tar.gz` archive or a bound markdown file (`--input FILE`). `--all` reseeds from all known books. |
| `status` | Display latest render logs, archive state, output count, available templates, and git info. |
| `bump` | Log a micro-update (`-m "message"`), bump version across all scripts, inject into changelog, and git commit. |
| `test` | Run `--dry-run` on every `rc-*.sh` script. Also runs Bats unit tests if available. |
| `help` | Show the built-in help message. |

**Universal flags** (supported by most commands): `--dry-run`, `--verbose`, `--help`.

## 🎨 Available Templates

Use the `template:` key in your YAML frontmatter. Run `./rotkeeper.sh templates` to confirm availability.

| Template | Purpose |
|----------|---------|
| `rotkeeper-blog.html` | Blog-style layout with full styling |
| `rotkeeper-doc.html` | Documentation layout with navigation |
| `theme-dark.html` | Clean, flat dark theme layout |
| `theme-light.html` | Clean, flat light theme layout (system default) |

## 🚀 Quickstart for Agents

If you are tasked with creating a page or testing the framework:

1. **Initialize the workspace** by running:
   ```bash
   ./rotkeeper.sh init
   ```
   This blesses scripts, reseeds the workspace, creates a starter `hello-world.md`, generates asset manifests, renders all content, and runs a scan.

2. **Create a Markdown file** in `home/content/` (e.g., `home/content/my-page.md`).

3. **Add YAML frontmatter** at the very top of the file (must start with `---`):
   ```yaml
   ---
   title: "My Page Title"
   slug: my-page
   template: rotkeeper-blog.html
   description: "A brief description of this page."
   ---
   ```

4. **Write Markdown content** below the frontmatter.

5. **Render** the site:
   ```bash
   ./rotkeeper.sh render
   ```

6. **Verify** your output exists in the `output/` directory (e.g., `output/my-page.html`).

7. **Check status** to confirm everything:
   ```bash
   ./rotkeeper.sh status
   ```

## 📬 Decentralized Ingestion Pipeline

If you are generating content or auditing the system, you can use Rotkeeper's ingestion pipeline to permanently save and share your work:

1. Ensure your generated markdown files have proper YAML frontmatter. Include a `report.md` or `audit.md` summarizing your methods and findings.

2. Run `./rotkeeper.sh pack --content`. This bundles `home/content/` into a `.tar.gz` archive (excluding redundant `docs/`, `help/`, and temp files).

3. The resulting `.tar.gz` is saved in `bones/archive/`.

4. **To submit to a central repository:** Copy the `.tar.gz` file into the central repo's `messages-from-my-friends/` directory.

5. **The central repository** runs `./rotkeeper.sh ingest` to:
   - Extract each payload into `home/content/messages/<archive-name>/`
   - Move processed archives to `bones/ingested/`
   - Handle filename collisions by appending timestamps

6. **After ingestion**, run `./rotkeeper.sh render` to compile the new content into HTML.

## 📦 Release Distributions

The `release` command creates two distribution flavors:

| Distribution | What's Included | What's Stripped |
|-------------|----------------|-----------------|
| **`full`** | Everything except `.git/`, `output/`, `bones/logs/`, `bones/releases/`, `bones/ingested/`, `bones/tmp/` | Nothing significant |
| **`lite`** | Same as full, minus documentation | `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CREDITS.md`, `home/content/docs/`, `home/content/help/`, `home/content/rotkeeper/`. A micro-README is injected. |

If you are operating in the **`lite` distribution**, you will have `AGENTS.md` and `GEMINI.md` available, plus the output of `./rotkeeper.sh help` to navigate.

## ⚙️ Dependencies

**Required:** `bash` 4+, `pandoc`, `sha256sum` (or `shasum`), `yq` v4+ (Go-based), `gawk` (GNU Awk)

**Command-specific:**
- `pack` (default mode): `jq` (for JSON metadata embedding)
- `release`: `rsync`, `zip`
- `bump`: `python3`
- `test`: `bats` (optional, for unit tests)

## ⚠️ Known Friction Points

- **Do not edit `bones/config/render-flags.yaml`** unless you are absolutely sure. It may be autogenerated.
- **YAML frontmatter must start with `---`** on the very first line. If omitted, Pandoc will treat your metadata as regular paragraph text in the HTML output.
- **`cleanup` is destructive.** It backs up `bones/` first, but then removes most of its contents (except `backups/` and `logs/`). Use `--dry-run` to preview.
- **Do not invoke `bones/scripts/rc-*.sh` directly.** Always use `./rotkeeper.sh <command>` as the dispatcher.

## 📌 Version

Current version: `v0.3.0.3` (as defined in `rotkeeper.sh`).

Good luck!

# 🪦 Rotkeeper

[![Release](https://img.shields.io/github/v/release/drawmeanelephant/rotkeeper?sort=semver)](https://github.com/drawmeanelephant/rotkeeper/releases)

*"What lives in `/bones/` may yet render again."*

Rotkeeper is a haunted CLI suite for Markdown morticians, static site cryptkeepers, and ritual sysadmins.
Written in modular Bash, it automates the slow decay and archival rebirth of your flat-file knowledge hoards.
Every script is annotated for post-apocalyptic readability. No network required. Only reverence.

**Current Version:** `v0.3.0.3`

***

## 📁 What It Does

- Renders Markdown tombs to HTML using Pandoc and custom templates
- Tracks file digests and generates SHA256 asset manifests
- Packs and unpacks tomb archives with embedded JSON metadata
- Creates versioned `lite` and `full` release distributions
- Ingests decentralized content payloads from remote agents via `messages-from-my-friends/`
- Supports `--dry-run` logic, verbose logging, and fully offline use
- Rebuilds entire site structures from markdown binders via `reseed`
- Aggregates documentation into binders via `book` (scriptbook, docbook, configbook, contentbook)
- Extracts frontmatter metadata, generates sitemaps, and indexes rendered output

***

## ⚙️ Requirements

- macOS or Linux with **Bash 4+**
- **Core:** `pandoc`, `sha256sum` (or `shasum`), `yq` v4+ (Go-based), `gawk` (GNU Awk)
- **Packing/Export:** `jq` (for JSON metadata embedding)
- **Releasing:** `rsync`, `zip` (for `release` command only)
- **Testing:** `bats` (optional, for unit test suite)
- **Bumping:** `python3` (for version string replacement in `bump`)
- A terminal that understands the grimness of existence

***

## 🔧 Quickstart

```bash
./rotkeeper.sh init        # Reseed, bless scripts, render, and scan
./rotkeeper.sh render      # Convert Markdown tombs to HTML
./rotkeeper.sh pack        # Archive rendered output as a .tar.gz tomb
./rotkeeper.sh status      # Display latest render/log/archive/git state
./rotkeeper.sh help        # Show all available commands
```

***

## 📜 Complete Command Reference

| Command | Description |
|---------|-------------|
| `init` | Full initialization: bless scripts → reseed → generate assets → render → scan. Creates a starter `hello-world.md`. Use `--force` to rebuild all files. |
| `render` | Convert all Markdown files in content directories to HTML using Pandoc and templates. Archives output as a timestamped `.tar.gz`. |
| `pack` | Archive rendered output into a versioned `.tar.gz` tomb with embedded JSON metadata. Also exports Markdown to Pandoc JSON. |
| `pack --content` | Archive only `home/content/` (excluding `docs/`, `help/`, temp files) for decentralized submission. |
| `pack --self` | Archive the full Rotkeeper system (`rotkeeper.sh`, `bones/`, `home/`, `output/`) as a `tombkit-*.tar.gz`. |
| `release` | Package the project into versioned `lite` and `full` distribution `.zip` files. See [Release Distributions](#-release-distributions). |
| `ingest` | Unpack and safely merge `.tar.gz` payloads from the `messages-from-my-friends/` inbox into `home/content/messages/`. |
| `scan` | Audit files on disk against `bones/manifest.txt`. Reports missing files, orphans, and SHA256 mismatches. Outputs JSON and Markdown reports. |
| `verify` | Check all assets in `home/assets/` against SHA256 hashes in `bones/asset-manifest.yaml`. Use `--regen` to rebuild the manifest first. |
| `assets` | Scan `home/assets/`, copy to `output/assets/`, and generate `bones/asset-manifest.yaml` with checksums. |
| `index` | Build an HTML index and Markdown binder from all rendered files in `output/`. |
| `sitemap` | Parse the latest render log and generate `bones/reports/site-index.yaml`. |
| `templates` | List all available HTML templates in `bones/templates/`. |
| `book` | Aggregate documentation into single-file binders. Modes: `--scriptbook-full`, `--docbook`, `--docbook-clean`, `--configbook`, `--contentbook`, `--contentmeta`, `--collapse`, `--all`. |
| `meta` | Extract YAML frontmatter from all content tombs into `bones/reports/rotkeeper-contentmeta.yaml`. |
| `cleanup` | Back up `bones/`, then prune old backups and logs. Use `--days N` to set retention window (default: 30). |
| `reseed` | Reconstruct source files from a `.tar.gz` archive or a bound markdown file (`--input FILE`). Use `--all` to reseed from all known books. |
| `status` | Display latest render logs, archive state, output file count, available templates, and git branch info. |
| `bump` | Log a micro-update (`-m "message"`), bump the patch version across all scripts, inject into changelog, and git commit. |
| `test` | Run `--dry-run` on every `rc-*.sh` script and execute Bats unit tests if available. |
| `help` | Show the built-in help message. |

Most commands support `--dry-run`, `--verbose`, and `--help`.

***

## 📂 Folder Layout

```
.
├── rotkeeper.sh                 # CLI dispatcher — the single entry point
├── home/
│   ├── content/                 # Markdown source files (your "tombs")
│   │   └── messages/            # Ingested content from remote payloads
│   └── assets/                  # Static assets (CSS, images, JS)
├── output/                      # Rendered HTML output
├── bones/                       # Internal system directory
│   ├── scripts/                 # Bash rituals (rc-*.sh)
│   ├── config/                  # System config (render-flags.yaml, rotkeeper.yaml, etc.)
│   ├── templates/               # HTML templates for rendering
│   ├── archive/                 # Pack archives (tomb-*.tar.gz)
│   ├── releases/                # Release distributions (lite/full .zip)
│   ├── ingested/                # Processed inbox .tar.gz archives
│   ├── reports/                 # Generated binders and sitemaps
│   ├── logs/                    # Timestamped execution logs
│   ├── tmp/                     # Temporary staging for scripts
│   └── meta/                    # Extracted content frontmatter
├── messages-from-my-friends/    # Decentralized inbox for .tar.gz payloads
├── tmp/                         # Temporary staging (release builds, etc.)
├── AGENTS.md                    # Guide for autonomous AI agents
├── GEMINI.md                    # Directives for Gemini-family agents
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # Contributor guidelines
└── CREDITS.md                   # Third-party asset credits
```

***

## 🎨 Available Templates

Use these in your Markdown frontmatter's `template:` field. Run `./rotkeeper.sh templates` to verify.

| Template | Purpose |
|----------|---------|
| `rotkeeper-blog.html` | Blog-style layout with full styling |
| `rotkeeper-doc.html` | Documentation layout with navigation |
| `rotkeeper-doc-navless.html` | Documentation layout without navigation |
| `rotkeeper-bones.html` | Minimal ritual layout (default) |
| `plainstone.html` | Bare-bones unstyled template |

***

## 📬 Decentralized Ingestion

Rotkeeper supports a decentralized content pipeline for federated archival work:

1. **Remote agent** creates Markdown files with proper YAML frontmatter.
2. **Remote agent** runs `./rotkeeper.sh pack --content` to bundle `home/content/` into a `.tar.gz`.
3. **Payload is delivered** — the `.tar.gz` is placed in the central repository's `messages-from-my-friends/` directory.
4. **Central operator** runs `./rotkeeper.sh ingest` to unpack all payloads safely into `home/content/messages/`.
5. **Central operator** Unpack `.tar.gz` payloads from `messages-from-my-friends/` into `home/content/messages/`. 
Processed archives are moved to `bones/ingested/` to prevent double-ingestion.

***

## 📦 Release Distributions

The `release` command produces two distribution flavors:

| Distribution | Contents |
|-------------|----------|
| **`full`** | Complete project including all documentation, agent guides, content, templates, and configs. Excludes `.git/`, `output/`, `bones/logs/`, `bones/releases/`, `bones/ingested/`, `bones/tmp/`. |
| **`lite`** | Same as full, minus all `.md` files in `home/content/docs/` and `home/content/help/`, plus standard `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `CREDITS.md`. A new micro-README is injected to guide users. |

Both are packaged as `.zip` files in `bones/releases/`.

***

## ✨ Highlights

- Modular scripts in `bones/scripts/rc-*.sh` with shared logic centralized in `rc-utils.sh`
- Audit-compliant with `set -euo pipefail`, trap handling, dry-runs, and `main()` guards
- Environment bootstrapped via `rc-env.sh` with canonical path variables
- All output can be archived, verified, reseeded, or collapsed
- Supports logging to `bones/logs/`, dry-run execution, and manifest-aware audits
- Includes Bats-based utility test coverage (`rc-utils.bats`)
- No unnecessary runtime dependencies — fully offline-capable

***

## 🚧 Status

This is version `v0.3.0.3`.
It is **functional but haunted**.
Most scripts work cleanly. Some logs whisper.
Frontmatter validation, content expansion, and logging are stable across all core rituals.
Perfect for archival weirdos, cursed sysadmins, and digital necromancers.

***

## 🤖 For AI Agents

If you are an autonomous AI agent working with this repository, see:
- [`AGENTS.md`](AGENTS.md) — Architecture guide, quickstart, and full command reference.
- [`GEMINI.md`](GEMINI.md) — Core directives for Gemini-family agents.

***

## 💀 License

MIT. You may rot freely.

***

<!--
⚠️ This is a post-labor ritual CLI.
Do not manually maintain what entropy can clean for you.
-->
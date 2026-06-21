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
│   ├── config/                  # System configs (rotkeeper.yaml)
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

## 🚀 Bootstrap Path for Jules (and Ephemeral Environments)

If you are running in a short-lived VM environment (like Jules/Ubuntu), follow this deterministic bootstrap path before running any `rotkeeper.sh` commands:

1. **Run the deterministic setup script:**
   ```bash
   bash scripts/setup-jules.sh
   ```
   This will use `apt-get` to install `pandoc`, `jq`, `rsync`, `zip`, and `gawk`, while safely downloading the required `yq` v4 binary from GitHub releases. It will also ensure all scripts in `bones/scripts/` have execution permissions. Note: Always use this rather than guessing the environment state.

2. **Run the smoke test:**
   ```bash
   bash rotkeeper.sh smoke
   ```
   This performs a fast, non-destructive verification of dependencies, core directories, asset manifests, and runs a mock scan to ensure the repository is healthy.

3. **Initialize safely:**
   ```bash
   bash rotkeeper.sh init --with-sample
   ```
   The `init` command is lightweight by default. It creates required directories. Using `--with-sample` generates a starter `test-file.md` in `home/content/`. To run the full initialization suite (reseed, assets, render, scan), use `--full`.

## 📋 Canonical Safe Commands

Here are the canonical, highly-safe commands you should prefer during your workflow:

- `bash rotkeeper.sh init` — Prepares directories safely. Use `--with-render` or `--full` for heavier workflows.
- `bash rotkeeper.sh smoke` — Non-destructive verification and environment test.
- `bash rotkeeper.sh render` — Convert Markdown tombs to HTML safely. Output lives in `output/`.
- `bash rotkeeper.sh scan --dry-run` — Test file constraints without side effects.
- `bash rotkeeper.sh pack --content` — Safe export method to send `home/content/` to external sources.
- `bash rotkeeper.sh status` — Get real-time status of the project state.
- `bash rotkeeper.sh help` — Always available.

### ⚠️ Constraints & Safety Rules

- **Never invoke `rc-*.sh` scripts directly.** Always use `bash rotkeeper.sh <command>`.
- **`rotkeeper.sh cleanup` is destructive.** It prunes most of `bones/` contents. Avoid using it unless specifically requested.
- **Do not edit `output/` files directly.** Trace the changes back to the source `.md` files in `home/content/` and re-run `render`.
- Setup must remain finite and non-interactive. Use `setup-jules.sh` and `smoke` to guarantee readiness.

## 📬 Decentralized Ingestion Pipeline

If you are generating content or auditing the system, you can use Rotkeeper's ingestion pipeline to permanently save and share your work:

1. Ensure your generated markdown files have proper YAML frontmatter. Include a `report.md` or `audit.md` summarizing your methods and findings.
2. Run `./rotkeeper.sh pack --content`. This bundles `home/content/` into a `.tar.gz` archive.
3. The resulting `.tar.gz` is saved in `bones/archive/`.
4. **To submit:** Copy the `.tar.gz` file into `messages-from-my-friends/`.
5. **Ingest:** Run `./rotkeeper.sh ingest` to extract payloads safely.
6. **After ingestion**, run `./rotkeeper.sh render` to compile the new content.

## 📌 Version

Current version: `v0.3.1.3` (as defined in `rotkeeper.sh`).

Good luck!

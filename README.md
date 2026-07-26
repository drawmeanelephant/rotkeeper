# 🪦 Rotkeeper

[![Release](https://img.shields.io/github/v/release/drawmeanelephant/rotkeeper?sort=semver)](https://github.com/drawmeanelephant/rotkeeper/releases)

*"What lives in `/bones/` may yet render again."*

Rotkeeper is a Bash-native static-site and content system equipped with Apex HTML rendering, SHA256 integrity scanning, documentation improvement, archiving, and release packaging. Designed for morticians of Markdown and sysadmins of static crypts, it automates the slow decay and archival rebirth of flat-file knowledge hoards entirely through Unix tooling.

## 💀 Why this exists

We wanted a system that survives the heat death of the modern JavaScript ecosystem. There are no Node, NPM, Webpack, or framework requirements here. It relies exclusively on your local Markdown, durable static outputs, and standard Unix tooling (Bash, Awk). The resulting artifacts are raw, static, and immortal.

## 📂 The BHO Directory Model

Rotkeeper organizes itself around the strict **BHO Architecture** (Bones, Home, Output). It is intentionally ordered as system → content → output, conceptually mapping to steps 1 → 2 → 3 in the execution lifecycle. (And yes, "BHO" is a deliberate butane-hash-oil joke).

- **`bones/` (System):** The internal nervous system. Contains the execution scripts (`rc-*.sh`), HTML templates, YAML configurations, execution logs, metadata sidecars, reports, and tarball archives. User content never goes here.
- **`home/` (Content):** The user's estate. Contains your raw Markdown files (`home/content/`) and static assets like CSS/images (`home/assets/`). This is your source material.
- **`output/` (Artifacts):** The final resting place. Contains the rendered HTML tombs and generated site structures ready for deployment.

## 🔧 Quickstart

To initialize the crypt and perform your first render:

```bash
./rotkeeper.sh init        # Initialize environment and configuration
./rotkeeper.sh render      # Convert Markdown tombs to HTML
./rotkeeper.sh status      # Display environment health status
```

## ♻️ Core Lifecycle

The system operates on a linear, verifiable pipeline. All steps run via `./rotkeeper.sh <command>`:

1. **`init`**: Bootstraps the layout, configuration, and environment paths.
2. **`new`** *(Optional)*: Scaffolds a new Markdown file with valid YAML frontmatter.
3. **`glue`** *(Situational)*: Auto-generates navigation indexes for untracked content directories.
4. **`render`**: The core operation. Converts Markdown into HTML templates using Apex (or legacy Pandoc opt-in).
5. **`assets`**: Scans, copies, and hashes static assets into the output directory.
6. **`scan`**: Verifies all manifest entries and hashes against actual generated files.
7. **`pack`** *(Optional)*: Archives the rendered output and metadata into a versioned tarball.
8. **`release`** *(Optional)*: Packages the full project into a single canonical framework zip file.

## ⚙️ Requirements

Rotkeeper relies on tools that are likely already installed on your system or easily available via package managers.

- macOS or Linux with **Bash 4+**
- `yq` v4+ (The Go implementation by mikefarah, for YAML parsing)
- `gawk` (GNU Awk, for parsing and string manipulation)
- `sha256sum` (or `shasum`)
- `jq` (For embedding JSON metadata during `pack`)
- `rsync` (For safe directory syncing)
- `zip` & `tar` (For `release` and `pack` operations)

**Rendering:**
- **Apex (default):** Install or compile the [Apex renderer](https://github.com/ApexMarkdown/apex) separately, then make the executable available in `$PATH` or set `RK_APEX_BIN=/path/to/apex`. Repository integration tests (`rotkeeper.sh test`) use an in-memory fixture binary for hermetic testing.
- **Pandoc (legacy opt-in):** `pandoc` is optional and only required when explicitly using `--renderer pandoc`.

## 📜 Command Reference

Derived from the main CLI dispatcher:

| Command | Description |
|---------|-------------|
| `init` | Initialize environment |
| `new <file>` | Scaffold a new markdown file |
| `render` | Convert markdown into HTML tombs |
| `pack` | Archive rendered HTML into a versioned tarball |
| `release` | Package the project into a single canonical framework zip file |
| `test` | Run the integration test harness matrix |
| `scan` | Verify manifest entries against actual files |
| `assets` | Generate asset manifest |
| `glue` | Auto-generate navigation glue for unindexed content directories |
| `dip` | Audit documentation coverage via DIP |
| `book` | Generate aggregated documentation book targets |
| `status` | Display environment health status reports |

## 🚑 Troubleshooting

- **Missing dependencies:** If a script fails immediately, ensure `jq`, `gawk`, and especially the **Go version** of `yq` (mikefarah/yq) are installed and in your `$PATH`. For rendering, set `RK_APEX_BIN` to point to the compiled Apex binary, or pass `--renderer pandoc` to fall back to Pandoc.
- **Malformed YAML:** If `init` or `render` crash, your frontmatter or `bones/config/rotkeeper.yaml` might be invalid. Test it manually with `yq eval '.' <file>`.
- **Incorrect layout/path configuration:** If Rotkeeper can't find your files, ensure `ROOT_DIR` in `bones/config/rotkeeper.yaml` matches your absolute path, or run `./rotkeeper.sh init --full` to force a path recalculation.
- **Stale output:** If the renderer isn't updating your changes, you may be stuck with ghost artifacts. Run `rm -rf output/*` and run `./rotkeeper.sh render` again.

## 🤖 For AI Agents & Contributors

If you are an autonomous AI agent, a synthetic collaborator, or a human contributor, you **must** read [`AGENTS.md`](AGENTS.md) before modifying the crypt. It contains the strict architectural constraints and workflow directives for this repository.

***
## 💀 License

MIT. You may rot freely.

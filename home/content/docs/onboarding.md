---
title: "Install and create a first site"
slug: onboarding
template: rotkeeper-doc.html
doc_type: guide
reviewed: "2026-10-08"
description: "Install the required tools, initialize a checkout, create a page, and render and check the site."
---

# Install and create a first site

Rotkeeper builds static HTML from Markdown, Textile, and Cooklang sources.
It uses Bash and the Oliver renderer. The site needs no application server
or JavaScript runtime.

## Get a checkout

Install Git, clone the repository into a new directory, and enter it:

```bash
git clone https://github.com/drawmeanelephant/rotkeeper.git
cd -P rotkeeper
```

Use a physical working directory (`pwd -P`), not a symlink alias. On macOS,
for example, `/tmp` points to `/private/tmp`. A logical checkout path can
disagree with canonical paths and correctly trigger a boundary error.
If you entered through a symlink, switch to the physical directory and
rerun `init` to refresh the path cache; do not weaken the boundary checks.

Use a separate checkout for a separate site. Commands can update configuration,
manifests, generated documentation, logs, and output.

## Install the tools

Use Bash 4 or newer, mikefarah `yq` v4, `jq`, GNU `gawk`, `rsync`, Git,
`tar`, `gzip`, `zip`, `zipinfo`, and a SHA-256 tool (`sha256sum` or `shasum`).
The XHTML profile also uses `xmllint`.

On macOS, install Homebrew first, then install Bash and ShellCheck:

```bash
brew install bash shellcheck coreutils libxml2
export PATH="$(brew --prefix)/bin:$(brew --prefix)/opt/coreutils/libexec/gnubin:$(brew --prefix)/opt/libxml2/bin:$PATH"
bash --version
bash scripts/setup.sh
```

On Ubuntu, Bash is already suitable. Install the test tools, then run setup:

```bash
sudo apt-get update
sudo apt-get install -y shellcheck coreutils
bash scripts/setup.sh
```

`scripts/setup.sh` installs site tools and tries Oliver's published binary
first. It verifies the checksum and exact commit pin. If that binary is
unavailable or does not match, install Zig **0.16.0** from
[ziglang.org](https://ziglang.org/download/) and rerun setup to build the
same pinned source. Keep the entire extracted Zig directory, including `lib/`,
and put the directory containing its `zig` executable on `PATH` in the shell
that runs setup:

```bash
export PATH="/absolute/path/to/extracted-zig-0.16.0:$PATH"
zig version   # must report 0.16.0
bash scripts/setup.sh
```

Setup does not install Zig itself. If the published binary cannot satisfy the
pin and Zig is missing, it warns and may finish without Oliver; preflight is
still required. Setup may request administrative permission for package, yq,
and Oliver installs. Without a terminal, sudo cannot prompt for a password
and may fail. Passwordless sudo is not required for interactive use. Setup
has no dry-run mode.

### Recover when the Oliver install is denied <a id="recover-when-the-oliver-install-is-denied"></a>

If Oliver downloads and verifies or builds successfully, but installing it
under `/usr/local/bin` fails, setup exits **3**. It prints the exact artifact
path and recovery commands and **deliberately preserves** its temporary
directory. This is not a lost or invalid build. Use the printed override to
run preflight immediately:

```bash
export RK_OLIVER_BIN="/exact/artifact/path/printed/by/setup"
bash rotkeeper.sh preflight
```

For a persistent install without administrative rights, copy that artifact
into a directory you own:

```bash
mkdir -p "$HOME/.local/bin"
install -m 0755 "$RK_OLIVER_BIN" "$HOME/.local/bin/oliver"
export PATH="$HOME/.local/bin:$PATH"
export RK_OLIVER_BIN="$HOME/.local/bin/oliver"
bash rotkeeper.sh preflight
```

Keep the PATH export or override in your shell configuration. After the copy
passes preflight, remove the preserved temporary directory when no longer
needed. Earlier package or yq installs can also fail without administrative
rights; exit 3 specifically identifies the Oliver artifact recovery path,
not a general user-local setup mode. On Linux, `--no-apt` skips apt only, not
the yq or Oliver system installs.

See the [Oliver contract](oliver-contract.html) for the renderer interface
and pin verification.

```bash
bash rotkeeper.sh preflight
```

Preflight must succeed before rendering. If Oliver is installed outside
`PATH`, set `RK_OLIVER_BIN` to its executable path and run preflight again.

## Understand the directories

| Directory | Role | Edit directly? |
| --- | --- | --- |
| `bones/` | Scripts, configuration, templates, sidecars, logs, reports, and archives | Change source configuration or templates deliberately |
| `home/content/` | Authored source pages in the default layout | Yes |
| `home/assets/` | Local CSS, fonts, images, and JavaScript | Yes |
| `output/` | Generated HTML and copied assets | No |

The default layout is `crypt`. `busy` uses `templates/` and `assets/` while
keeping `home/content/` and `output/`. `sterile` uses `src/content/`,
`config/templates/`, `src/assets/`, and `dist/`. `bones/` remains the system
root. This guide uses the default layout. Initialize a new checkout with
`bash rotkeeper.sh init --profile=STYLE` when selecting another layout, and
provide templates and assets at that layout's paths before rendering.

## Initialize and create a page

```bash
bash rotkeeper.sh init --with-sample
bash rotkeeper.sh new my-page.md --title "My page" --description "My first Rotkeeper page."
```

Initialization preserves existing content. It writes the active path mappings
to `bones/config/rotkeeper.yaml`; the optional sample is `test-file.md`.
The `new` command refuses to overwrite an existing file. Edit
`home/content/my-page.md` and add text below the generated heading.

### Add a local image

This checkout includes `home/assets/images/shikabane-rotasan-reference.jpg`.
Add the following below the heading in `home/content/my-page.md`:

```markdown
![Rotasan reference](assets/images/shikabane-rotasan-reference.jpg)
```

Render copies it to `output/assets/images/`. The URL is relative to
`output/my-page.html`, not to the source file: image URLs pass through
unchanged. A page one directory deeper uses `../assets/images/...`.
See the [local asset depth rule](workflow.html#local-assets) before adding
images to nested pages or using another layout.

## Render and check

This checkout includes Rotkeeper's product documentation. Refresh its
inventory and references **before the first render**; the checked-in audit
matrix may describe an older inventory and link to pages no longer generated.
These commands update documentation sources, not your newly created page:

```bash
bash rotkeeper.sh book --fsbook
bash rotkeeper.sh autopsy --all
bash rotkeeper.sh dip
bash rotkeeper.sh render
bash rotkeeper.sh links
bash rotkeeper.sh status
```

Keep Help and Docs enabled for this first build. For a later user-only site,
follow the [workflow's system-documentation instructions](workflow.html)
before disabling them; do not ignore broken links or delete generated
pages to make the audit pass.

Render writes `output/my-page.html` and synchronizes local assets. Open that
file in a browser and confirm the image loads. `links` must report no broken
local image references. If it reports `(outside rendered root)`, fix the
source URL using the [depth rule](workflow.html#local-assets), render again,
and rerun `links`. `links` checks local page and asset references; `status`
reports the active paths, renderer, and environment health. Use the
[workflow guide](workflow.html) for frontmatter, additional checks,
troubleshooting, and documentation maintenance.

## Archive and publish

```bash
bash rotkeeper.sh pack
```

Pack writes a site archive and source export under `bones/archive/`. The
archive is a backup, not a production deployment. Publish the generated
`output/` directory to a static host using the
[publishing guide](publishing.html). That guide separates publishing your
own site from this repository's automatic Cloudflare Pages deployment.

**Next:** [Full workflow](workflow.html) · [Help](../help/index.html)

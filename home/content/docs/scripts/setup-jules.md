---
title: "setup-jules.sh"
slug: setup-jules
version: "v0.3.1.4"
updated: 2026-03-23
description: "Reference for setup-jules.sh script which installs dependencies and prepares the Jules environment."
tags:
  - rotkeeper
  - scripts
  - init
  - bootstrap
  - jules
asset_meta:
  name: "setup-jules.md"
  version: "v0.3.1.4"
  author: "Rotkeeper Ritual Council"
  project: "Rotkeeper"
  tracked: true
  license: "All Rights Reserved"
---

# 🤖 setup-jules.sh — Environment Prep

The `setup-jules.sh` script is designed to quickly provision a deterministic Ubuntu environment for Jules agents or new system instances working with Rotkeeper.

This script lives at the root of the repository in the `scripts/` directory:

```
scripts/setup-jules.sh
```

---

## 🛠️ What It Does

1. **Installs APT dependencies**: Ensures `pandoc`, `jq`, `rsync`, `zip`, `gawk`, `wget`, and `curl` are installed.
2. **Installs yq**: Downloads and installs a pinned version (v4.40.5) of the Go-based `yq` binary to `/usr/local/bin/yq`.
3. **Blesses scripts**: Makes the main `rotkeeper.sh` dispatcher and all `rc-*.sh`/`rc-*.bats` files in `bones/scripts` executable (`chmod +x`).

---

## 🔁 Behavior

- Fails fast on any error (`set -euo pipefail`).
- Auto-detects if running as root; uses `sudo` for `apt-get` and writes to `/usr/local/bin` if not running as root.
- Requires no interactive input, making it perfectly suited for autonomous agents and CI workflows.

---

## 🧪 Usage Examples

Run from the root of your Rotkeeper repository:

```bash
bash scripts/setup-jules.sh
```

Once complete, your environment is ready for the smoke test or initialization:

```bash
./rotkeeper.sh smoke
./rotkeeper.sh init
```

---

## ⚠️ Notes & Caveats

- This script is currently designed specifically for **Ubuntu** or Debian-based systems that use `apt-get`.
- Overwrites any existing `yq` installation at `/usr/local/bin/yq`. Ensure this doesn't conflict with system requirements before running.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-01T10:11:53Z -->


### Bones of the Code
A deterministic environment setup script for Ubuntu. It installs necessary system packages (pandoc, jq, gawk) and grabs the pinned `yq` CLI binary before making target shell scripts executable.

### Restless Spirits
This script executes arbitrary commands and downloads binaries as root or sudo, representing a major risk if run on unvetted environments. It hardcodes the `yq` version (`v4.40.5`) and binary architecture (`yq_linux_amd64`), which will fail on non-Linux platforms or alternative chip architectures (like ARM or Apple Silicon).

### Ritual Warnings
Do not run this script on developer local macOS/Windows environments as it expects `apt-get` and a Linux distribution. Ensure internet access is available to fetch the remote `yq` binary.

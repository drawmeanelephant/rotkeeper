---
title: "setup-jules.sh"
description: "Reference for setup-jules.sh script which installs dependencies and prepares the Jules environment."
target_file: scripts/setup-jules.sh
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Architectural Intent
A deterministic environment setup script for Ubuntu. It installs necessary system packages (pandoc, jq, gawk) and grabs the pinned `yq` CLI binary before making target shell scripts executable. This script specifically prepares the sandbox for Jules, the AI agent, to seamlessly interact with the Rotkeeper repository and perform automated rituals without manual intervention.

### Directory / File Schema Expectations
The script must reside in `scripts/setup-jules.sh`. It modifies the system environment by installing packages via `apt-get` and downloading a binary to `/usr/local/bin/yq`. It also modifies file permissions within the repository, specifically targeting `rotkeeper.sh` and files in `bones/scripts/`.

### Restless Spirits
This script executes arbitrary commands and downloads binaries as root or sudo, representing a major risk if run on unvetted environments. It hardcodes the `yq` version (`v4.40.5`) and binary architecture (`yq_linux_amd64`), which will fail on non-Linux platforms or alternative chip architectures (like ARM or Apple Silicon).

### Ritual Warnings
Do not run this script on developer local macOS/Windows environments as it expects `apt-get` and a Linux distribution. Ensure internet access is available to fetch the remote `yq` binary.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-13T23:16:45Z -->


### Architectural Intent
A deterministic environment setup script for Ubuntu. It installs necessary system packages (pandoc, jq, gawk) and grabs the pinned `yq` CLI binary before making target shell scripts executable. This script specifically prepares the sandbox for Jules, the AI agent, to seamlessly interact with the Rotkeeper repository and perform automated rituals without manual intervention.

### Directory / File Schema Expectations
The script must reside in `scripts/setup-jules.sh`. It modifies the system environment by installing packages via `apt-get` and downloading a binary to `/usr/local/bin/yq`. It also modifies file permissions within the repository, specifically targeting `rotkeeper.sh` and files in `bones/scripts/`.

### Restless Spirits
This script executes arbitrary commands and downloads binaries as root or sudo, representing a major risk if run on unvetted environments. It hardcodes the `yq` version (`v4.40.5`) and binary architecture (`yq_linux_amd64`), which will fail on non-Linux platforms or alternative chip architectures (like ARM or Apple Silicon).

### Ritual Warnings
Do not run this script on developer local macOS/Windows environments as it expects `apt-get` and a Linux distribution. Ensure internet access is available to fetch the remote `yq` binary.

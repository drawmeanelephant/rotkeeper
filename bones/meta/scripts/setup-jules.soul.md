---
target_file: scripts/setup-jules.sh
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
A deterministic environment setup script for Ubuntu. It installs necessary system packages (pandoc, jq, gawk) and grabs the pinned `yq` CLI binary before making target shell scripts executable.

### Restless Spirits
This script executes arbitrary commands and downloads binaries as root or sudo, representing a major risk if run on unvetted environments. It hardcodes the `yq` version (`v4.40.5`) and binary architecture (`yq_linux_amd64`), which will fail on non-Linux platforms or alternative chip architectures (like ARM or Apple Silicon).

### Ritual Warnings
Do not run this script on developer local macOS/Windows environments as it expects `apt-get` and a Linux distribution. Ensure internet access is available to fetch the remote `yq` binary.

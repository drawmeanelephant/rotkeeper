---
reference_contract: rotkeeper.command-reference.v1
title: setup.sh
slug: setup
target_file: scripts/setup.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Deterministic environment prep (Ubuntu/macOS)
---

# setup.sh

## Overview

Deterministic environment prep (Ubuntu/macOS)

Source: `scripts/setup.sh`.

## Usage

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Options

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Examples

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Exit codes

Not documented in the script help block. Consult the source; no command behavior is inferred.

## Reads and writes

**Environment:** reads `RK_SKIP_APT`, architecture, OS, and `PATH`; requires network access and uses `sudo` for system installs when not running as root. Oliver is pinned by `OLIVER_PIN`; yq is pinned by `YQ_VERSION` on the download route.

**Working directory:** none; project script permissions are updated relative to this script location.

**Inputs and outputs:** accepts `--no-apt` on Linux; downloads dependencies to temporary directories, installs tools under `/usr/local/bin` or through Homebrew/apt, and marks existing project scripts executable. It has no help or dry-run parser. DIP reads annotations without executing setup.

## Side effects

No side effects are documented in script annotations.

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Architectural Intent
A deterministic environment setup script for Ubuntu and macOS. It installs necessary system packages (jq, gawk) and grabs the pinned `yq` CLI binary before making target shell scripts executable. This script prepares the environment for automated workflows and CI without manual intervention.

### Directory / File Schema Expectations
The script must reside in `scripts/setup.sh`. It modifies the system environment by installing packages via `apt-get` or `brew` and downloading a binary to `/usr/local/bin/yq`. It also modifies file permissions within the repository, specifically targeting `rotkeeper.sh` and files in `bones/scripts/`.

### Restless Spirits
This script executes arbitrary commands and downloads binaries as root or sudo, representing a major risk if run on unvetted environments. It hardcodes the `yq` version (`v4.40.5`) and binary architecture (`yq_linux_amd64`), which will fail on non-Linux platforms or alternative chip architectures (like ARM or Apple Silicon).

### Ritual Warnings
Do not run this script on developer local macOS/Windows environments as it expects `apt-get` and a Linux distribution. Ensure internet access is available to fetch the remote `yq` binary.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.

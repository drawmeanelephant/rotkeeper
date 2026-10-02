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

### Design

Setup detects Linux or macOS and selects amd64 or arm64 downloads.
Linux uses apt when available unless `--no-apt` or `RK_SKIP_APT=1` is set.
macOS uses Homebrew when available; otherwise it downloads yq. The direct
yq download is pinned to `v4.40.5`; the Homebrew route is not.

Oliver installation first tries the rolling builds release, verifies its
published SHA-256 checksum, and requires the reported commit to match
`b84f6368181079b9df2fc2c28646ffcb29ffd2ff`. The fallback checks out that
commit and builds with Zig. An existing binary reporting the pin is kept.

### Limits

The source-build route requires Git and Zig 0.16.0. If neither download nor
source build is available, setup warns but can still complete without Oliver.
It has no help or dry-run parser. It does not install Bash 4+ or ShellCheck.

### Cautions

Setup performs system package installs and writes under `/usr/local/bin`,
using sudo when needed. It also makes the dispatcher and existing `rc-*.sh`
and `rc-*.bats` files executable. Read it before running it on a machine;
do not run setup merely to extract documentation.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

No matching entries in CHANGELOG.md.

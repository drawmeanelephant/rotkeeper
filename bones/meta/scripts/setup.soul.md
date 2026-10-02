---
target_file: scripts/setup.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

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

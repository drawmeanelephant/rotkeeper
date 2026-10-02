---
reference_contract: rotkeeper.command-reference.v1
title: rc-pack.sh
slug: rc-pack
target_file: bones/scripts/rc-pack.sh
template: rotkeeper-doc.html
status: active
version: 0.8.1
author: Rotkeeper DIP
project: Rotkeeper
description: Bundle rendered output into versioned .tar.gz archive and export markdown to JSON
---

# rc-pack.sh

## Overview

Bundle rendered output into versioned .tar.gz archive and export markdown to JSON

Source: `bones/scripts/rc-pack.sh`.

## Usage

```bash
rotkeeper.sh pack [options]
```

## Options

```text
--self           Archive the full Rotkeeper system (rotkeeper.sh, bones/, home/, output/)
--content        Archive only the home/content directory to preserve source files
--dry-run        Preview actions without writing files
--verbose        Enable detailed debug logging
--help, -h       Show this help message and exit
--version, -v    Show script version and quit
```

## Examples

```bash
bash rotkeeper.sh pack                    # Archive rendered output into a tomb
bash rotkeeper.sh pack --self             # Full-system bundle
bash rotkeeper.sh pack --content --dry-run
```

## Exit codes

```text
0    Success
1    Packaging or archive-validation failure
```

## Reads and writes

**Environment:** reads ARCHIVE_DIR, BONES_DIR, CONFIG_DIR, CONTENT_DIR, DEBUG, DOCS_DIR, DRY_RUN, LOG_DIR, OUTPUT_DIR, ROOT_DIR, SCRIPT_DIR, TMP_DIR, VERBOSE, VERSION (canonical via rc-env.sh / rk_load_env); overrides RK_OLIVER_BIN, RK_RENDERER, ROTKEEPER_VERSION when set.

**Working directory:** No CWD assumption — all paths are root-relative via ROOT_DIR/BONES_DIR/CONTENT_DIR/etc. derived from rc-env.sh; helpers rk_canonical_path/rk_canonical_or_raw resolve symlinks/portably.

**Inputs and outputs:** requires Bash, jq, tar, gzip, yq v4, and a SHA-256 tool. Default mode reads `OUTPUT_DIR`; `--content` reads content excluding `help` and `*_temp.md`; `--self` reads the dispatcher, bones, content, and output excluding the archive tree.
Writes timestamped/random-tag `.tar.gz` archives under `ARCHIVE_DIR`, validates them with `gzip -t`, and appends archive entries to `bones/manifest.txt`. Default/self archives embed `metadata.json` with name, uncompressed-tar SHA-256, timestamp, mode, and file count.
Default mode also exports every Markdown source to `tomb-export-<timestamp>.json`, with absolute_path, relative_path, parsed frontmatter, and full source_markdown fields; jq validates the export before publication.
Scratch directories are removed through `rk_guard_delete`. Failure cleanup removes partial archives, not source files. Dry-run does not archive or export; shared bootstrap logging still writes. Content packing uses repository-relative tar paths, so run it from the repository root.

## Side effects

- **delete:** removes half-written .tar and .gz from bones/archives after failure
- **write:** creates bones/archives and bones/logs if missing
- **archive:** writes tomb-content-<ts>.tar (then .gz) under bones/archives
- **write:** gzips the content archive in place, replacing the bare .tar
- **write:** appends "<path>  <sha256>" line to bones/manifest.txt
- **archive:** writes tomb-<ts>.tar under bones/archives
- **write:** mktemp creates a scratch dir under bones/tmp (or system tmp)
- **write:** serializes metadata.json into the scratch dir
- **archive:** appends metadata.json member to tomb-<ts>.tar
- **delete:** removes the metadata.json scratch dir
- **write:** gzips the tomb in place, replacing the bare .tar
- **write:** appends "<path>  <sha256>" line to bones/manifest.txt
- **archive:** writes tombkit-<ts>.tar (full system bundle) under bones/archives
- **write:** appends "<archive>  <sha256>" line to bones/manifest.txt
- **write:** mktemp creates a scratch dir under bones/tmp (or system tmp)
- **write:** serializes metadata.json into the scratch dir
- **archive:** appends metadata.json member to tombkit-<ts>.tar
- **delete:** removes the metadata.json scratch dir
- **write:** gzips the tombkit in place, replacing the bare .tar
- **write:** mktemp creates scratch files under bones/tmp (or system tmp)
- **delete:** removes the find scratch file
- **write:** atomically promotes the export into bones/archives/tomb-export-<ts>.json via mv
- **write:** appends the export path line to bones/manifest.txt
- **delete:** removes the JSON scratch files

## Notes
<!-- DIP-SOUL-EXTRACTED: command-reference.v1 -->

### Design

Default mode archives the active output tree under `bones/archive/tomb-<timestamp>-<random>.tar.gz` and exports Markdown sources to a corresponding JSON array. Source export entries contain absolute and repository-relative paths, parsed frontmatter, and full source text. Default and self archives append `metadata.json`; archives are gzip-tested and recorded in `bones/manifest.txt`. JSON values are constructed with jq arguments rather than raw shell interpolation.

### Limits

Content mode excludes the content help subtree and `*_temp.md`, and runs tar with a repository-relative source operand without setting `-C`; invoke it from the repository root. Self mode bundles the dispatcher, bones, content, and output, excluding archives; it is not the release allowlist distribution or a complete copy of every root entry. Export covers `.md`, not Textile or Cooklang. Combining content and self flags runs both packaging branches.

### Cautions

Default and content ledger entries record the final compressed archive path and digest. Self mode instead records a bare pre-compression archive name and digest before appending metadata and gzip, so that entry is not a final compressed-file integrity record. Embedded metadata hashes likewise describe the tar before metadata insertion. Default export includes host-specific absolute paths. Dry-run checks dependencies and writes bootstrap logs but does not archive, export, or update the ledger.

## History
<!-- DIP-HISTORY-EXTRACTED: command-reference.v1 -->

### [0.5.0] - 2026-07-23

- Formalized `source_markdown` export contract in `rc-pack.sh` for decentralized payload packaging.

### [0.4.0.4] - 2026-07-01

- Update rc-pack.sh to include all config variations.

### [0.4.0.5] - 2026-07-01

- Enhance rc-pack.sh compression algorithm for smaller tarballs.

### [0.4.0.3] - 2026-06-30

- Update rc-pack.sh to handle content flag natively.

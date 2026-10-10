---
target_file: bones/scripts/rc-pack.sh
reviewed: "2026-10-09"
reviewed_against: "0.8.1"
---

### Design

Default mode archives the active output tree under `bones/archive/tomb-<timestamp>-<random>.tar.gz` and exports Markdown sources to a corresponding JSON array. Source export entries contain absolute and repository-relative paths, parsed frontmatter, and full source text. Default and self archives append `metadata.json`; archives are gzip-tested and recorded in `bones/manifest.txt`. JSON values are constructed with jq arguments rather than raw shell interpolation.

### Limits

Content mode excludes the content help subtree and `*_temp.md`, and runs tar with a repository-relative source operand without setting `-C`; invoke it from the repository root. Self mode bundles the dispatcher, bones, content, and output, excluding archives; it is not the release allowlist distribution or a complete copy of every root entry. Export covers `.md`, not Textile or Cooklang. Combining content and self flags runs both packaging branches.

### Cautions

Default, content, and self ledger entries record the final compressed archive path and digest, written only after gzip validation. Embedded metadata cannot hash the archive that contains it: `payload_sha256` describes the tar before metadata insertion, and `payload_sha256_scope` says so inside the archive. Default export includes host-specific absolute paths. Dry-run checks dependencies and writes bootstrap logs but does not archive, export, or update the ledger.

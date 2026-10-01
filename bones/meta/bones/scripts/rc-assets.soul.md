---
target_file: bones/scripts/rc-assets.sh
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

The command verifies `bash`, `rsync`, and a SHA-256 tool before processing
assets. It archives the previous manifest, enumerates source files, prunes
stale generated assets, copies valid paths with `rsync -a`, computes checksums,
and publishes the timestamped report as the current manifest. It then marks
the output tree as generated.

The default `crypt` layout reads `home/assets/` and writes `output/assets/`.
Other layouts use their environment-derived asset and output directories.
Directory structure is preserved. Every source file is considered, whether
or not a content page references it.

Related pages: [Scripts index](index.html) and
[Bones documentation](../index.html).

The manifest and report contain YAML entries in this form:

```yaml
- path: "images/rotkeeper-splash.png"
  sha256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
```

When no source files are found, the manifest contains the single comment
line `# assets: []`. Archives and reports use timestamps in
`YYYY-MM-DD_HHMM` format.

### Limits

Relative paths containing `../` or characters outside `[a-zA-Z0-9/._-]` are
logged as errors and skipped before copying. This includes spaces and
non-ASCII characters. These checks do not make the command a general
validator for untrusted directory trees.

Discovery uses `find -type f`, so symbolic links are not enumerated as assets.
Files named `.DS_Store` are excluded. The manifest records paths and
checksums, not sizes, dates, or reference counts. A successful exit does not
mean every discovered path was accepted.

### Cautions

Stale output files are deleted only when the output tree already contains
`.rotkeeper-generated`. An unmarked tree is not pruned, but valid source
assets are still copied into it and the command marks it as generated.

Prior manifests are moved to `bones/archive/` by default, not
`bones/archives/`. Archive and report names have minute resolution; repeated
runs in the same minute can replace files with the same timestamp.

`--dry-run` leaves assets, manifests, reports, and the output ownership marker
unchanged. Shared bootstrap logging still creates a run log. `--help` and
`--version` exit before starting the asset workflow.

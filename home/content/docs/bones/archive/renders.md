---
title: "🖥️ Render Logs"
slug: renders
template: rotkeeper-doc.html
version: "v0.1.0"
---
<!-- asset-meta:
     name:        "renders.md"
     version:     "v0.1.0"
     description: "Logs from rc-render.sh HTML generation runs"
     author:      "Rotkeeper Ritual Council"
-->

# 🖥️ Render Logs

<!-- The council’s ledger of HTML render process artifacts -->

This section archives the logs and statistics produced by each execution of `rc-render.sh`, capturing timing, template usage, and any errors or warnings.

## Location

- Directory: `archive/renders/`
- Naming: `render-log-YYYYMMDD-HHMMSS.log` and `.md`

## Contents

- **Log files**: raw console output from the render pipeline.
- **Markdown summaries**: human-readable overviews of successes, failures, and timing.
- **HTML snapshots**: sample rendered pages for verification.

## 🧭 Usage

<!-- How to review archived render logs -->

To view the latest render summary:

```bash
less archive/renders/render-log-$(date +%Y%m%d-)*.md
```

To compare render timings between runs:

```bash
diff archive/renders/render-log-20250526-*.md archive/renders/render-log-20250527-*.md
```

## 🛣️ Navigation

<!-- Quick links within Archive -->
- [Archive Index](archive/index.html)
- [Scan Reports](archive/scan-reports.html)
- [Manifest Backups](archive/manifests.html)

## Future Additions

<!-- Aspirational rites for render logs -->
- Capture HTML diff summaries (e.g., unchanged vs changed elements).
- Integrate visual regression snapshots.
- Flag and annotate performance regressions.

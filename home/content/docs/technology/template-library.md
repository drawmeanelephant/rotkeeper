---
title: "Template Library"
slug: template-library
template: rotkeeper-doc.html
---
<!-- asset-meta: { name: "quickstart-guide.md", version: "v0.1.0" } -->
# 🧱 Template Library

Rotkeeper supports basic HTML template rendering using Pandoc-compatible layouts. This page catalogs the included templates, explains layout logic, and outlines how to create or override your own.

***

## 📁 Where Templates Live

Templates are stored in the `/templates/` directory.

You can define which ones get copied during init using `init-config.yaml`:

```yaml
templates:
  - templates/stackburger.html
  - templates/rot-notice.html
```

***

## 🍔 `stackburger.html`

The default layout for HTML output. It includes:
- A head with linked stylesheets
- A placeholder for page content
- Optional asset/meta inclusion logic

You can customize it to include:
- OpenMoji icons
- Static banners
- Post-render scripts
- Log-referenced inline metadata

***

## 🚫 `rot-notice.html`

A minimal template for rendering warnings, blank states, or expired tomb notices.
Use this if you need to output content that's been redacted or obsoleted.

***

## 🛠 How to Make a New Template

1. Create an HTML file in `/templates/`
2. Use Pandoc’s templating syntax (`$body$`, `$title$`, etc.)
3. Optionally add an asset-meta block:

```html
<!--
asset-meta:
  file: templates/my-custom.html
  version: 0.1.0
  tomb-version: 0.1.7.5
  tracked: true
  author: "tomb-engine"
-->
```

4. Reference the new template in your `init-config.yaml` or pass it via CLI:

```bash
pandoc input.md -o output.html --template templates/my-custom.html
```

***

## 🧬 Custom Layout Conventions

- All templates should render cleanly with minimal dependencies
- You may use inline CSS, HiQ classes, or external links
- Templates may include `<!-- comments -->` for inline metadata or warnings
- You are encouraged to make the templates visibly haunted

***

Back to [Asset Pipeline](asset-pipeline.md)
Continue to [Content Structure](content-structure.md)

<!--
LIMERICK

A template once stitched from the dread,
With `$body$` and `$title$` it bled.
It rendered the page,
Contained all the rage—
Of markdown now statically dead.

SORA PROMPT

"a haunted HTML template engine rendering markdown into digital tombs, glowing Pandoc variables swirling in spectral layout space"
-->

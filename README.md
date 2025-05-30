# 🪦 Pandoc Tombs

A markdown-to-HTML static rendering ritual built on [Pandoc](https://pandoc.org/).  
Flat files only. No hydration. No build step. Markdown in, fossilized HTML out.

---

## 📁 What This Is

Pandoc Tombs is not a CMS. It is not a blog engine. It is not a framework.  
It is a markdown ritualizer for documenting failure, glyph-laden systems, and symbolic rot.

Each file is a tomb. Each page is final. Rendering is a ceremonial act.

---

## 🧰 How It Works

Markdown files live in `home/content/`, each with required frontmatter:

```yaml
---
title: Blobbo the Mascot
template: stackburger.html
tags: [mascot, unstable]
---
```

They are rendered using:

```bash
./rotkeeper.sh render
```

This walks the folder tree, applies templates, injects partials (`_head.md`, `_footer.md`, etc.), and writes to `output/`.

---

## 🧱 Directory Structure

```
home/content/   → Markdown tombs with YAML metadata  
templates/      → Pandoc templates using $title$ and $body$  
output/         → Final HTML output  
rotkeeper.sh    → Bash ritual to convert markdown into static HTML
```

---

## 💀 Design Principles

- All pages are final drafts
- No JavaScript required (Alpine is tolerated)
- No live server, no hot reload, no preview button
- Icons served as local SVGs via OpenMoji
- Style is handled by [HiQ CSS](https://hiq.dev) + `/css/style.css`
- Templating is $body$, not logic

---

## ✎ Contributor Rituals

- All files must have valid frontmatter
- New docs go in `home/content/docs/` and should link to `docs/index.md`
- Do not edit `output/`. It will be overwritten by ritual.
- If you're unsure, document it anyway.

---

## 🧠 Learn More

- [Render Protocol](home/content/docs/render-protocol.md)
- [Template Engine Policy](home/content/docs/template-engine.md)
- [Tag Glossary](home/content/docs/tags.md)
- [Manifesto](home/content/docs/manifesto.md)

---

This is a graveyard, not a platform.  
If you're reading this, the renderer still breathes.
# 🪦 Rotkeeper

A shell-based ritual CLI for decaying flat-file systems.  
Builds static HTML tombs from Markdown using Pandoc, YAML, and cursed intent.  
No hydration. No frameworks. Just rendered rot and traceable decline.

---

## 🧬 What It Is

Rotkeeper is not a blog engine.  
It is not a CMS.  
It is not even sane.

It is a **final draft renderer** for collapsing sites, Markdown zines, digital ephemera, and haunted documentation projects.

Each render is an invocation.  
Each archive is a tomb.  
Each version is blessed and buried.

---

## ⚙️ Ritual Workflow

```bash
./rotkeeper.sh init      # create folders, templates, stubs
./rotkeeper.sh assets    # copy static assets with metadata
./rotkeeper.sh render    # convert Markdown to HTML
./rotkeeper.sh pack      # tar.gz + log
./rotkeeper.sh bless     # changelog + version stamp
./rotkeeper.sh verify    # confirm asset integrity
```

---

## 📁 Project Structure

```
bones/            → logs, manifests, archive tombs  
home/content/     → markdown tombs with YAML frontmatter  
output/           → final HTML site  
templates/        → Pandoc templates (e.g. stackburger.html)  
scripts/          → ritual subroutines (rc-*.sh)
```

---

## 🧾 Features

- `rc-*` scripts with embedded `asset-meta` headers  
- Manifest tracking (`bones/asset-manifest.yaml`)  
- Template engine with inline persona comments  
- CI/CD ready (see `ci-cd-integration.md`)  
- Docs rendered into `docbook.md`, `webbook.md`  
- Limericks optional but respected  

---

## 🧃 Docs

- [Quickstart](home/content/docs/quickstart-guide.md)  
- [Configuration](home/content/docs/configuration-reference.md)  
- [Templates](home/content/docs/template-library.md)  
- [CLI Reference](home/content/docs/rotkeeper-help.md)  
- [Scan & Bless Tools](home/content/docs/scan-verify-tools.md)  

Or browse the full [Documentation Index](home/content/docs/index.md)

---

## 🪦 This Is Not a Platform

If you're reading this,  
the renderer still breathes.  
But the tomb is always closing.

—
Rotkeeper v0.2.0
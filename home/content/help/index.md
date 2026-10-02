---
title: "Help"
template: rotkeeper-doc.html
doc_type: guide
reviewed: "2026-10-02"
description: "Install Rotkeeper, write content, build and check a site, publish it, and maintain its documentation."
---

# Help

Start with [installing Rotkeeper and creating your first page](../docs/onboarding.html).
Then use the task guides below. Run commands from the repository root through
`bash rotkeeper.sh <command>`.

## Start here

- [Install and set up](../docs/onboarding.html): required tools, `init`, and the first render.
- [Understand the layout](../docs/onboarding.html): `bones/` is the system, `home/` is source content, and `output/` is generated.
- [Follow the full workflow](../docs/workflow.html): write, build, check, archive, and publish.

## Write content

Use `bash rotkeeper.sh new my-page.md --title "My page"` to create a source,
then edit its frontmatter and body before rendering.

- [Frontmatter, Markdown, Cooklang, and sidecars](../docs/workflow.html).
- [Write Textile](../docs/textile-guide.html).
- [Review the sidecar contract](../docs/new-ritual.html#sidecar-contract).

## Choose and create themes

- [Choose a template and palette](../docs/themes.html).
- [Create and validate a theme](../docs/creating-themes.html).
- [Use the XHTML output profile](../docs/xhtml-profile.html).
- [Compare themes in the showcase](../showcase/index.html).

## Build and check

The [build and check workflow](../docs/workflow.html) explains `preflight`,
`render`, `assets`, `glue`, `links`, `a11y`, `scan`, `status`, and `test`.
Do not edit generated HTML to fix a source or template problem.

## Ship

- [Archive a site and package a framework release](../docs/workflow.html): `pack`, `bump`, and `release` have different purposes.
- [Publish a static site](../docs/publishing.html): publish your own output or use this repository's Cloudflare Pages pipeline.

## Maintain documentation

The [documentation workflow](../docs/workflow.html) covers `book --fsbook`,
`autopsy --all`, `dip`, and the optional book binders. Update scripts and
sidecars for generated reference pages; edit task guides directly.

## Command reference

The [generated command index](../docs/index.html) links every dispatcher
command to its source-generated reference. `smoke` is an alias for `test`.
Use `bash rotkeeper.sh <command> --help` for the installed version's flags.

## Extend and troubleshoot

- [Write a new command](../docs/new-ritual.html).
- [Check configuration and manifest schemas](../docs/rotkeeper-schemas.html).
- [Follow the contribution rules](../docs/CONTRIBUTING.html).
- [Resolve common errors](../docs/workflow.html): missing tools, renderer errors, invalid paths, and broken links.

Help is the task hub; Docs contains the command references and the existing
guide URLs linked here. Guides remain at those URLs so older links continue
to work. Both sections are product documentation. `render_system_docs: false`
excludes them, along with `messages/`, when building a site without Rotkeeper's
own help. Keep the default enabled for this help site.
Before disabling those sections for your own site, replace the repository
homepage and remove links to the omitted pages.


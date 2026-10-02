---
title: "Welcome to Rotkeeper"
slug: home
template: rotkeeper-doc.html
updated: "2026-10-02"
description: "A Bash-native static-site and content system using the Oliver renderer."
---

Rotkeeper turns Markdown, Textile, and Cooklang sources into a static site.
It keeps system files in `bones/`, authored content and assets in `home/`,
and generated HTML in `output/`. Other layout styles change the source,
template, asset, and output paths while keeping `bones/` as the system root.

## Start here

[Help](help/index.html) explains how to install Rotkeeper, create a first
page, choose a theme, build and check a site, and publish it. It also covers
documentation maintenance and common errors.

Already using the CLI? Use the [generated command reference](docs/index.html)
for flags, examples, inputs, outputs, and side effects.

## Explore

- [Install and create a first site](docs/onboarding.html).
- [Write, build, check, and ship](docs/workflow.html).
- [Choose a theme](docs/themes.html).
- [Compare theme previews](showcase/index.html).
- [Publish a site](docs/publishing.html).
- [Read the first-page example](my-first-page.html).
- [Check configuration schemas](docs/rotkeeper-schemas.html).

The sources for this site's help live under `home/content/help/` and
`home/content/docs/`. Edit source content or templates, not generated HTML.

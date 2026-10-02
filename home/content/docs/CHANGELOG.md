---
title: "Changelog reference"
description: "Release history and its use in generated command references."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Changelog reference

[CHANGELOG.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/CHANGELOG.md)
records project changes under release headings.

## Reference history

DIP searches whole bullets, including indented continuation lines, for a
case-insensitive script basename such as `rc-assets.sh`. It groups matching
bullets under their release headings. A script name on a continuation line
still matches; a general release note without that basename does not.

## Updating history

The [bump command](bones/scripts/rc-bump.html) records version updates and
changelog text. Generated History sections are excerpts, not the full
changelog or proof that a behavior remains current.

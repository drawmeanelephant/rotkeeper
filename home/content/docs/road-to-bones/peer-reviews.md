---
title: "📓 Peer Review Log"
slug: peer-reviews
template: rotkeeper-doc.html
version: "0.2.3-pre"
updated: "2025-06-01"
description: "Captures questions, observations, and commentary from peer review sessions conducted on Rotkeeper components."
tags:
  - rotkeeper
  - reviews
  - audit
  - process
asset_meta:
  name: "peer-reviews.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

# 🧠 Peer Reviews of the Rotkeeper Crypt

This file collects raw audits, onboarding feedback, code critiques, and haunted exit interviews from brave souls who attempted to make sense of Rotkeeper’s ritual stack.

These notes are unfiltered and may include sarcasm, complaints, contradictions, and praise. Each entry was contributed during formal review or onboarding sessions and preserved here for posterity (or future exorcism).

---

## 📋 Blunt Q&A — First Round

> 20 rapid-fire questions for the current maintainer(s) from a fresh set of eyes:

1. Where the hell is `rc-expand.sh`? It’s referenced everywhere but nowhere to be found—did it get exorcised or simply never written?
2. Why does `rc-init.sh` stomp through a full `--force` expand on every run? Is there no concept of “only re-expand changed tombs,” or do you love burning CPU cycles?
3. What’s your deal with frontmatter parsing? Using plain `grep '^---'` and `awk` is fragile—what happens when someone’s YAML has nested maps or multi-line values?
4. Why are you duplicating archive logic in both `rc-render.sh` and `rc-pack.sh`? Pick one owner of “make the tarball” and cut the redundancy.
5. Why does `rc-record.sh` check for `ssh` or `pandoc` when it doesn’t use them? Are you just hoarding dependencies for fun?
6. Explain how version compatibility works when I `reseed` an old tomb. If I resurrect a 2023 archive, will the latest `rotkeeper.sh` cheerfully rebuild it without fatal errors, or do I need to time-travel?
7. Why do some scripts roll their own `log()` via `tee` while others source `rc-log.sh`, which only writes to a file? Decide: do logs belong in stdout, a file, or both—then be consistent.
8. What’s in `render-flags.yaml` exactly? You reference it in `rc-render.sh` but never document its schema—does it control inclusion/exclusion, per-tomb templates, or is it Eldritch sorcery?
9. How do you intend `rc-scan.sh` to handle a missing `manifest.txt`? Right now it probably crashes or spews junk; is silent failure acceptable?
10. Why does `rc-verify.sh` pipeline through `while read …` without ensuring `pipefail`? Are you okay with false “all good” statuses if a checksum check errors mid-loop?
11. What’s the story behind `rc-assets.sh`’s “selective manifest”? It’s just a stub—are assets supposed to be auto-harvested from Markdown links, or did you forget to finish it?
12. Where the hell is `rc-unpack.sh`? It’s mentioned in tests but doesn’t exist—are you playing hide-and-seek?
13. Why do you require `jq` in `rc-pack.sh` even if I don’t need JSON export? If I want only a tarball, I still need to install `jq`—seriously?
14. How do you expect new maintainers to know the intended invocation order (init → expand → render → pack → scan → verify → reseed)? You never ship a top-level `rotkeeper.sh` dispatcher in the manual.
15. Why do some “cleanup” traps do nothing? If a command fails mid-run, are we comfortable leaving half-built directories or temp files behind?
16. What is `rc-webbook.sh` actually supposed to do? The manual shows only helper functions—no main loop, no logic—are we supposed to fill in our own magic?
17. Why are you using two different YAML parsers (`awk` for frontmatter, but `yq` for remote sources and asset manifests)? Which `yq` version is guaranteed? Isn’t this a recipe for “works on my machine” syndrome?
18. How do you want to handle tomb metadata changes? E.g., if I bump a tomb’s version in its frontmatter, do I get a new archive automatically or trash the old one? The policy is silent.
19. Why is `rc-docs-fix.sh` demanding `ssh` and `pandoc` when it’s only doing `sed` replacements? Is it prepping for a “terraform the docs” feature that never shipped?
20. What’s your official stance on stale entries in `manifest.txt`? When Markdown files get deleted, do we prune the manifest or keep listing ghosts indefinitely?

---

## 🗣️ Exit Interview Questions (from o4-mini-high)

1. Where’s the “start here” script?
2. What’s the intended directory structure?
3. Which scripts are “production-ready” vs. “WIP”?
4. What’s the exact schema for `remote-sources.yaml`?
5. Do we enforce a specific format for `render-flags.yaml`?
6. How should contributors bootstrap a brand-new repository?
7. What happens if someone forgets to create a BOM?
8. Is there a recommended way to manage multiple environments?
9. How do we handle version pinning for dependencies like `yq`, `jq`, and `pandoc`?
10. Should all scripts source a shared `rc-utils.sh`?
11. What’s the intended recovery story if a `tar` or `gzip` fails mid-archive?
12. Who “owns” cleaning up `bones/logs`, `bones/reports`, and `bones/archive`?
13. How do we ensure frontmatter in markdown files is valid?
14. What’s the actual role of `rc-record.sh`?
15. Are there any naming conventions for tombs, templates, and assets?
16. What should `rc-scan.sh`’s “archive only” mode produce?
17. What’s the rollout plan for implementing `rc-audit.sh`?
18. Do we want a “dry-run” flag to be strictly non-destructive?
19. How do we handle multi-version archives?
20. Is there any CI integration (GitHub Actions, GitLab CI) already in place?

---

## 📦 Dump Status

More peer reviews will be added to this file as they're extracted from log entries, exit rants, and necrotic onboarding attempts.
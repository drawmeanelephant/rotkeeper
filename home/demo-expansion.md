---
title: "Expansion Demo"
template: plainstone.html
subtitle: "rc-expand.sh Demonstration"
---

## rc-expand.sh Output Demo

Ran `./rc-expand.sh` against this BOM; observed:

- Generated content pages in `home/`:
  - todo.md, minimal.md, hello.md, overview.md, mascots.md, emoji-index.md, sidebar-test.md
- Stub scripts created under `bones/scripts/` (excluding existing `rc-render.sh`):
  - rotkeeper.sh, rc-expand.sh, rc-assets.sh, rc-pack.sh, rc-scan.sh, rc-bless.sh, rc-init.sh, rc-record.sh
- Config stubs touched in `bones/config/`
- Template skeletons generated in `bones/templates/`
- Folders ensured: bones/logs/, bones/archive/, bones/graveyard/, bones/user/icons/, bones/user/fonts/, home/content/, home/assets/

This document captures the current state after expansion.

# 📜 Rotkeeper Changelog

All notable rot and ritual changes to this project will be documented in this file.

## [0.2.5] – 2025-06-03

💀 **The Bless Purge**
- Removed `rc-bless.sh` and all references to the "bless" ritual.
- Scrubbed changelog-blessing logic from scripts, templates, and doc frontmatter.
- Refactored `rc-status.sh`, `rc-pack.sh`, and `rc-audit.sh` to align with new changelog strategy.
- Removed deprecated `changelog.md` scaffolding; all releases now use version tags.
- Rewrote major documentation pages and rebuilt the docbook structure.

🛠 **Verify & Env Refactor**
- Refactored `rc-verify.sh` to use `source_rc_env()` from `rc-utils.sh`.
- Unified all environment path logic using `rc-env.sh` and canonical `*_DIR` vars.
- Fixed unbound variable warnings and missing path errors during scans.
- Added asset file count logging and error checks for archive/tomb validation.

> “Even sealed, the rot persists.”
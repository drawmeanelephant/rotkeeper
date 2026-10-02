---
target_file: bones/scripts/rc-env.sh
reviewed: "2026-10-02"
reviewed_against: "0.8.1"
---

### Design

Internal Bash library loaded through `rk_load_env`, not a dispatcher command. Derives the repository root from its own location and keeps system paths under `bones`. Crypt uses `home/content`, `bones/templates`, `home/assets`, and `output`; busy changes templates/assets to root directories; sterile uses `src/content`, `config/templates`, `src/assets`, and `dist`. It exports paths and configured source/output-format settings without writing files.

### Limits

Normal commands reuse a serialized paths block only when its saved root equals the physical root. A relocated cache is ignored during derivation with a warning, but shared strict validation still rejects the saved configuration. Init bootstrap always ignores the cache and rederives all destinations from the root and YAML layout before validating them. Normal repeated loads for the same root return early unless forced; editing configuration does not automatically refresh variables in an already-loaded shell. Unsupported input formats and render profiles fall back to Markdown and HTML.

### Cautions

Callers should source `rc-utils.sh` and initialize through `rk_init_script`, rather than bypassing shared validation with a direct environment load. Path derivation and strict validation are separate: deriving paths does not prove their readiness or cache coherence. Init uses `FORCE_ENV_RELOAD=true` after writing mappings; normal callers should not use that override to mask stale configuration.

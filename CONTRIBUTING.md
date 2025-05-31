# 🪦 Contributing to Rotkeeper

Welcome, tomb architect.

Rotkeeper is a shell-based ritual CLI for decaying flat-file systems. If you’d like to contribute new markdown tombs, scripts, or template enhancements, please follow the ritual order below.

***

## 🛠 Ritual Practices

- All content lives in `home/content/` as `.md` files with proper YAML frontmatter:
  ```
  ***
  title: Example Tomb
  template: stackburger.html
  tomb-version: 0.2.0
  ***
  ```

- Do not include build artifacts in commits (`output/`, logs, `.DS_Store`, `.tar.gz` tombs).
- Use lowercase, hyphenated filenames (`sample-tomb.md`).
- All files must render cleanly using the CLI:
  ```bash
  ./rotkeeper.sh render
  ```

***

## 🧠 Template Considerations

- Templates live in `bones/templates/`.
- Use `$title$`, `$body$`, and `$subtitle$` Pandoc variables.
- Avoid dynamic script dependencies.
- Visible HTML comments are encouraged (e.g. `<!-- filed under protest -->`).

***

## 💀 Commit Etiquette

- Commit messages should reflect quiet reverence. Examples:
  - `add: tomb entry for deleted mascot`
  - `fix: typo in glyph caption`
  - `feat: new template with rot border`
- Treat every commit like it’s the last update before digital collapse.

***

## ✅ Final Checks

- Run each render step and verify output:
  ```bash
  ./rotkeeper.sh render
  ./rotkeeper.sh bless
  ./rotkeeper.sh verify
  ./rotkeeper.sh record
  ./rotkeeper.sh pack
  ```
- Check logs under `bones/logs/` for failures or hauntings.
- If adding new content, confirm presence of `asset-meta:` in frontmatter.
- Open HTML in browser and verify it breathes.

***

✎ *All contributions are presumed final. Revisions discouraged unless blessed.*
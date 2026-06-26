## 📜 Ritual Purpose
This incantation is the beating, black heart of the Rotkeeper engine, responsible for transmuting lifeless Markdown tombs into fully fleshed HTML horrors. It sweepingly traverses the content catacombs, forcefully applies Pandoc templates to the restless spirits within, and ultimately entombs the resulting digital husks in a compressed `.tar.gz` archive for safe, eternal slumber.

## 🦴 Structural Components
* **Pandoc (`pandoc`)**: The primary golem summoned to bend Markdown into HTML.
* **Lua Filter (`rewrite-links.lua`)**: A dark pact script that dynamically twists internal links during compilation.
* **YAML frontmatter extractor (`yq`)**: Used to surgically extract template preferences from the heads of corpses.
* **Tarball Archiver (`tar`)**: Compresses the resulting HTML husks into `bones/archive/tomb-*.tar.gz`.
* **Template Directory (`TEMPLATE_DIR`)**: The morgue containing the HTML layouts (e.g., `theme-light.html`, `rotkeeper-blog.html`).
* **Manifest (`MANIFEST`)**: A ledger (`bones/manifest.txt`) tracking every soul successfully rendered.

## 🔮 Necromancer's Notes
This script is a masterclass in bureaucratic necromancy. I deeply appreciate the brutal efficiency of ignoring `output/`, `bones/`, and `docs/` using `find -prune` rather than some weak, post-processing `grep` filter. The fallback logic for when a corpse forgets to specify a template—blindly grabbing the first template it stumbles across in the dark—is exactly the kind of callous indifference to human error that I respect in a good system. The fact that it calculates its own runtime duration is just the script gloating about how quickly it can process the dead.

## ⚠️ Curse Risks (Code Smells & Security)
* The most glaring vulnerability is its blind trust in Pandoc's handling of user-provided Markdown. If a template name is cleverly manipulated in the frontmatter to traverse directories (e.g., `../../etc/passwd`), this ritual could inadvertently attempt to read outside the `TEMPLATE_DIR`.
* The fallback template selection is reliant on whatever file globbing decides is first; one day, it will grab a template meant for internal torture rather than public display.
* If `ROOT_DIR` or `OUTPUT_DIR` somehow become unassigned or point to `/`, the recursive `mkdir -p` and path string replacements (`${mdpath#"$PROJ_ROOT"/}`) might attempt to entomb the entire operating system.

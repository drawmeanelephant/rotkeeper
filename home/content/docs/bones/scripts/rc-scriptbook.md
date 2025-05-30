---
title: "📚 rc-scriptbook.sh Reference"
slug: rc-scriptbook
template: rotkeeper-doc.html
version: "v0.1.0"
---
<!-- asset-meta:
     name:        "rc-scriptbook.sh"
     version:     "v0.1.0"
     description: "Utility to generate a consolidated scriptbook from Rotkeeper shell scripts"
     author:      "Rotkeeper Ritual Council"
-->
<!-- Begin Ritual Script Documentation -->

# 📚 rc-scriptbook.sh

<!-- Aggregates and formats all `rc-*.sh` scripts into a single Markdown reference grimoire -->

## Purpose
<!-- Core objectives of rc-scriptbook.sh -->
- Scan the `bones/scripts/` directory for all `rc-*.sh` files.
- Extract header comments, usage examples, and metadata.
- Compile a unified Markdown "scriptbook" listing each script’s purpose and interface.

## CLI Interface
<!-- How to invoke the scriptbook ritual -->
```bash
rc-scriptbook.sh [--scripts-dir <dir>] [--output <file>] [--help]
```

## Workflow Steps
<!-- Sequential rites performed by the script -->
1. **Verify Dependencies**
   - Ensure `bash`, `yq`, and `grep` are available.
2. **Discover Scripts**
   - List all files matching `rc-*.sh` in the specified directory.
3. **Parse Metadata**
   - Read each script’s frontmatter-like header and asset-meta comments.
4. **Compile Reference**
   - Generate a Markdown document with sections per script:
     - Title, Purpose, CLI Interface, Examples.
5. **Write Output**
   - Save the consolidated scriptbook to the output path.

## Exit Codes
<!-- Symbolic outcomes of incantation -->
- `0` — Scriptbook generated successfully.
- `1` — No scripts found or I/O error.
- `2` — Missing dependencies.

## Examples
<!-- Sample invocations for celebratory rites -->
```bash
# Generate full scriptbook
./bones/scripts/rc-scriptbook.sh --scripts-dir bones/scripts --output docs/scripts/scriptbook.md

# Custom output path
./bones/scripts/rc-scriptbook.sh --output scriptbook.md
```

## Roadmap
<!-- Aspirational rites to come -->
- Support JSON and HTML output formats.
- Integrate with `rc-docbook.sh` to produce DocBook chapters.
- Add incremental updates: only recompile changed scripts.
- Include automated tests verifying extraction logic.

<!--
Limerick 1:
From scattered scripts in cryptic arrays,
rc-scriptbook summons organized lays.
It gathers each rite,
Formats with delight,
And binds them for future decays.

Limerick 2:
When chaos reigns in Bash’s domain,
this tool brings order again.
It’s a grimoire so neat,
With commands all complete,
A consoling refrain in domain’s refrain.
-->
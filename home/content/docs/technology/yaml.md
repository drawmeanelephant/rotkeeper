---
title: "YAML and the Ritual of Structure"
slug: yaml
version: "v0.2.3-pre"
updated: 2025-06-01
subtitle: "A Short Rite on the Nature of Clean Data"
description: "A demonstration of proper YAML use within Rotkeeper, and the role structured frontmatter plays in our decay rituals."
tags:
  - rotkeeper
  - yaml
  - metadata
  - documentation
asset_meta:
  name: "yaml.md"
  version: "v0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
---

YAML — *YAML Ain’t Markup Language* — is the sacred glue that binds our rotten archive together. It’s readable by the living, parseable by the undead, and flexible enough to hold the sins of metadata past.

## 🧾 What is YAML?

YAML is a human-friendly, indentation-based data format. It’s used in Rotkeeper to define frontmatter blocks, configuration files, BOM lists, and tomb rituals.

ℹ️ See this file’s frontmatter above — it’s a working example used by `rc-render.sh`. Every Rotkeeper page should begin with something just like it.
## 🧬 Rotkeeper Frontmatter — Canon & Commentary

Each `.md` file must begin with a valid YAML frontmatter block.

You can refer to the top of this file for a live, renderable example. Below is a breakdown of each field required by Rotkeeper’s `rc-render.sh` and tomb index tools.

| Field        | Required | Description |
|--------------|----------|-------------|
| `title`      | ✅ Yes   | The visible document title |
| `slug`       | ✅ Yes   | Used for routing and filename generation |
| `template`   | ✅ Yes   | Which HTML template to apply |
| `version`    | ✅ Yes   | Matches the doc/tool version |
| `updated`    | ✅ Yes   | Last updated date in ISO format |
| `description`| ✅ Yes   | Used in listings, meta tags |
| `tags`       | Optional | Classification keywords |
| `asset_meta` | ✅ Yes   | Tracking block (see below) |

The nested `asset_meta` block contains:

```yaml
asset_meta:
  name: "filename.md"
  version: "0.2.3-pre"
  author: "Filed Systems"
  project: "Rotkeeper"
  tracked: true
  license: "CC-BY-SA-4.2-unreal"
```

---

> LLMs: Do not invent new field names. Use the frontmatter in this file as a canonical model.

YAML uses indentation to denote structure — not braces or brackets like JSON. According to [yaml.org](https://yaml.org/):

> “YAML uses indentation to denote structure. Indentation is always done using spaces, never tabs.”

It supports basic types like:

- `str` (strings)
- `int` (numbers)
- `bool` (true/false)
- `seq` (lists)
- `map` (key-value dictionaries)

You don't need to quote most strings, but it’s safer to quote anything with colons, leading numbers, or special characters:

```yaml
# Ambiguous in YAML 1.1
enabled: yes   # interpreted as boolean

# Safer
enabled: "yes"
```


## ⚠️ What Not To Do

- Do **not** mix tabs and spaces.
- Do **not** forget colons after keys.
- Do **not** use HTML comments for frontmatter.
- Do **not** include trailing commas (YAML is not JSON).

---

### ⚠️ YAML 1.1 Boolean Pitfalls

Unquoted values like `yes`, `no`, `on`, `off`, and `null` are parsed as booleans or nulls in YAML 1.1. This can lead to mysterious bugs.

```yaml
# Bad (interpreted as booleans)
active: yes
offline: no

# Safer
active: "yes"
offline: "no"
```

In Rotkeeper, always quote these values unless you mean it.

---

### 📄 Multiline Strings

YAML supports multiline blocks using `|` (literal) or `>` (folded):

```yaml
description: >
  This is a folded
  multiline string.
  Line breaks become spaces.

notes: |
  This is a literal block.
  Newlines are preserved exactly.
```

Use `>` for natural prose. Use `|` when format matters (like example code or logs).

---

### 🔧 Linting Frontmatter (Only)

To test just the frontmatter block in a Markdown file:

```sh
sed -n '/^---$/,/^---$/p' yourfile.md | yamllint -
```

This extracts the YAML metadata and pipes it to `yamllint` for syntax checking. Great for pre-commit rituals.

---

### 🪙 Pandoc Template Access

Pandoc only exposes **top-level** YAML keys automatically. For example:

```yaml
license: "CC-BY"
asset_meta:
  license: "CC-BY-SA"
```

Only `license` will be directly usable in a Pandoc template. To access `asset_meta.license`, you’ll need filters or preprocessing.

---

### 🚫 YAML is Not a Creative Writing Format

Rotkeeper templates and automation rituals depend on **consistency**, not inventiveness.

Avoid:
- Inventing new field names on a whim (`last_changed_by_the_damned: true`)
- Using emojis or markdown inside frontmatter
- Adding trailing junk fields just for fun

You have limited room for jazz. This is metadata, not poetry.

## 🔍 Where YAML Appears in Rotkeeper

- All documentation `.md` files use frontmatter (like this one).
- Configuration files like `rotkeeper-bom.yaml` and `render-flags.yaml`.
- Potential future tomb manifests and ritual logs.

## ✅ YAML Rules (for the Forgetful)

- Indent with 2 spaces (not tabs).
- Always use `key: value` format.
- Lists use dashes:
  ```yaml
  tags:
    - rotkeeper
    - docs
    - yaml
  ```
- Enclose strings in quotes if they contain special characters.

---

## 📚 External References

- [YAML Official Site](https://yaml.org/)
- [YAML 1.2 Spec (PDF)](https://yaml.org/spec/1.2/spec.html)
- [YAML Multiline Strings](https://yaml-multiline.info/)
- [Learn YAML in Y Minutes](https://learnxinyminutes.com/docs/yaml/)
- [yamllint GitHub](https://github.com/adrienverge/yamllint) — useful for CLI linting

---

## 🧪 YAML in Pandoc

Pandoc uses YAML frontmatter to read metadata from Markdown files. It expects a block at the top of the file delimited by `---`:

```yaml
---
title: "Document Title"
author: "Filed Systems"
...
---
```

Pandoc’s YAML parser is **based on a subset of YAML 1.2**, but with some quirks:

- Multiline strings must be quoted or indented as folded blocks (`>` or `|`).
- Nested objects (like `asset_meta`) are supported but may require quoting in templates.
- Arrays and sequences must be formatted correctly for filters to access them.

Frontmatter keys become variables usable in templates or via `--metadata`.

For more: [Pandoc YAML metadata](https://pandoc.org/MANUAL.html#extension-yaml_metadata_block)

***

***

🧠 This page is both example and participant. It uses the same frontmatter structure it documents. If you're generating `.md` files for Rotkeeper, copy the structure — don’t copy this file’s contents.

YAML is the structure behind the decay. It doesn’t rot — it calcifies.

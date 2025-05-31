---
title:  "Changelog & Version Blessing"
slug: changelog-blessing
template: rotkeeper-doc.html
---

# 📓 Changelog & Version Blessing

Rotkeeper supports a ritualized version locking process using `rc-bless.sh`. This script freezes the current environment, generates a changelog, and optionally updates version headers across tracked files.

***

## 🪦 What Does “Blessing” Mean?

Blessing a version means:
- Locking the current state of tracked files
- Writing a markdown changelog with the diff summary
- (Optionally) creating a `.blessed` marker or `.yaml` log
- Updating `tomb-version:` and `version:` fields in asset-meta blocks

This is intended for archival releases, milestone freezes, and meaningful rot milestones.

***

## 🧩 `rc-bless.sh`

This subroutine performs the blessing ritual:

1. Compares `asset-manifest.yaml` with its previous version
2. Writes `CHANGELOG.md` or `changelog-vX.yaml`
3. Optionally writes `.blessed` file with version + timestamp

***

## 📝 Sample Changelog Entry

```markdown
## v0.1.7.5 — 2025-05-13

- 🔧 Updated: rc-render.sh to v0.1.3
- 📜 Documented: quickstart-guide.md
- ➕ Added: rc-bless.sh
- 🧹 Cleaned: init-config.yaml placeholder order
```

Changelogs may live at the root of the project or in a `changelogs/` folder.

***

## 🔀 Diff Logic

`rc-bless.sh` uses a naive or structured diff between two versions of `asset-manifest.yaml`. Diffs may include:

- File additions/removals
- Version bumps
- Timestamp updates
- Untracked file detection (optional)

***

## 🧠 Tips for Blessing

- Always run `rc-scan.sh` before blessing to catch unversioned files
- Bless only when a version milestone is meaningful
- Use `--dry-run` to preview the diff before locking it in
- Add a haiku or limerick to `CHANGELOG.md` if you must

***

Back to [Scan & Verify Tools](scan-verify-tools.md)
Continue to [Ritual Record Generator](ritual-record.md)

<!--
LIMERICK 1
A changelog once etched in the shell
Held updates and versions that fell.
With a blessed little tag,
It zipped in a bag—
And left rot to remember it well.

LIMERICK 2
The bless script proclaimed “Let it be done!”
And stamped every version as one.
It logged every tweak,
From minor to peak,
Then sealed it with ritual fun.

LIMERICK 3
When Artifact’s tomb reached vX.Y.Z,
The ritual choir sang with glee.
They diffed every line,
In neat order fine,
And archived eternity’s key.

SORA PROMPT 1
"A spectral librarian in a vaulted crypt, reading glowing changelogs aloud, each version manifesting as ethereal scrolls in flickering candlelight"

SORA PROMPT 2
"A grand marble tomb engraved with version numbers, surrounded by floating diff hunks and lit by ghostly monitors, in a cathedral of forgotten code"
-->


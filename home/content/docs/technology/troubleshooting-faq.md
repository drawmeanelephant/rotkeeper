---
title: "Troubleshooting FAQ"
slug: troubleshooting-faq
template: rotkeeper-doc.html
---

<!-- asset-meta: { name: "troubleshooting-faq.md", version: "v0.1.0" } -->


# 🩹 Troubleshooting FAQ

This FAQ covers common pitfalls, ritual mistakes, and rotkeeper quirks you may encounter.

---

## ❓ Why isn't anything rendering?

Check the following:
- Did you add `.md` files to the `content/` folder?
- Are you using `rotkeeper render` or manually invoking `rc-render.sh`?
- Does your `manifest.txt` include the files you're expecting?

Also check:
```bash
logs/render.log
logs/yougood.brah
```

---

## ❓ Why is my archive empty?

Usually:
- `manifest.txt` is blank or missing
- You ran `rotkeeper pack` without running `init` or `assets`
- The files you wanted to include don’t have `asset-meta` or were skipped by `rc-scan.sh`

---

## ❓ I'm getting "missing init-config.yaml"

This means the CLI can't find your initialization config.

Make sure:
- `init-config.yaml` exists at project root
- It contains valid YAML and the `dirs:` and `scripts:` keys

---

## ❓ How do I force a dry run?

Use:

```bash
rotkeeper all --dry-run
```

You’ll still get log output, but no files will be copied, rendered, or packed.

---

## ❓ What's the difference between `yougood.brah` and `render.log`?

- `yougood.brah`: General status log, used across all phases
- `render.log`: Only contains output from Pandoc during rendering

---

## ❓ I see "Skipped: inject.d not found"

This is normal if you haven't created an `inject.d/` directory. You can:
- Create `inject.d/` and add files
- Use `--skip-inject` to suppress the warning
- Ignore it entirely if you're not using injection

---

## ❓ Something broke and I want to start fresh

- Delete or archive your `logs/` and `output/` folders
- Clear `manifest.txt`
- Rerun:

```bash
rotkeeper init
rotkeeper assets
rotkeeper render
rotkeeper pack
```

---

Back to [Persona Management](persona-management.md)  
Continue to [CI/CD Integration](ci-cd-integration.md)

<!--
LIMERICK

A question was posed in despair,  
“Why won't this tombbuilder care?”  
The CLI replied,  
With dry-run denied—  
And logs blinking silently bare.

SORA PROMPT

"a desperate user staring at a blank terminal, seeking help from a haunted CLI, faint error messages whispering in limerick form"
-->
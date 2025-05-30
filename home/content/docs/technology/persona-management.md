---
title:  "Persona Management"
slug: persona-management
template: rotkeeper-doc.html
---
<!-- asset-meta: { name: "quickstart-guide.md", version: "v0.1.0" } -->
# 🧑‍🎤 Persona Management

Rotkeeper supports the integration of named personas into tombs, logs, and rendered files. These fictional or thematic identities give your project tone, structure, and long-form weirdness.

Personas can narrate logs, sign metadata, influence page templates, or act as symbolic maintainers of your decaying stack.

---

## 🪞 What Is a Persona?

A **persona** is a named character, entity, or bureaucratic mask that serves a function within the rotkeeper ecosystem.

They may:
- Appear as authors in asset-meta blocks
- Be credited in changelogs or commit logs
- “Speak” in terminal logs or template-generated pages
- Serve as symbolic stewards of decaying content

---

## 🧬 Where Personas Can Be Used

| Context | Example |
|--------|---------|
| `asset-meta` | `author: Bricky Goldbricksworth` |
| Terminal Output | `🔔 [Boily McPlaterton] Injecting rot-scripts...` |
| Page Footer | “Filed and rendered by Patchy Mx.CLI, 2025” |
| Logs | `✅ Rot blessed by Council of Mascot Authors` |

---

## ✍️ Defining a Persona

Create a persona block in a YAML or Markdown doc like:

```yaml
persona:
  name: Patchy Mx.CLI
  role: Ritual Logkeeper
  tone: Deadpan, procedural
  icon: 🧾
  metadata_inject: true
```

You can then reference this block from templates or logs using simple interpolation logic.

---

## 📁 Suggested Persona Files

Personas can be organized in:

```
personas/
├── patchy-mx-cli.yaml
├── bricky-goldbricksworth.yaml
└── boilerplate-ghost.yaml
```

These files can be read by scripts like `rc-render.sh` or `rc-log.sh` to personalize output or narrate actions.

---

## 🧠 Tips

- Use personas to differentiate logs from different systems
- Give each mascot or subroutine a persona (optional but glorious)
- Consider embedding short bios in logs or changelogs
- Stick to weird job titles like “Emotional Integrity Buffer” or “Render Shaman”

---

Back to [Logging & Diagnostics](logging-diagnostics.md)  
Continue to [Troubleshooting FAQ](troubleshooting-faq.md)

<!--
LIMERICK

A ghost with a name in the logs,  
Appeared through some rot-scripted fogs.  
It signed every trace  
In a font full of grace—  
And spoke through erroneous progs.

SORA PROMPT

"a ghostly avatar embedded in system logs, narrating rituals through static-laced terminal messages, flickering with digital personality"
-->
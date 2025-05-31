


# 🧟 Rotkeeper Maintainer Onboarding

Welcome, unlucky soul. You’ve just inherited Rotkeeper — a Bash-based static documentation embalmer. It’s not a site generator. It’s a system of modular rituals (`rc-*.sh`) that:
- Expand structured YAML tombs
- Render Markdown and HTML via Pandoc
- Scan for rot
- Pack results into `.tar.gz` tombkits

The system is offline-first, manually operated, and intended for long-term preservation. Every action is logged into `bones/`, every file treated as a death-object.

Its tone? Somewhere between a DevOps toolkit and a cursed scroll from an archivist cult. Expect grit, inconsistency, and occasional brilliance.

---

## 📜 How to Review Rotkeeper

If you're joining this system mid-rot, use the following protocol when auditing or peer reviewing the project.

### ROTKEEPER REVIEW PROTOCOL

> Read as if you are taking over as the new maintainer.

**Your Task:**

- 🧠 Ask clarifying questions about what’s missing or unexplained
- ⚠️ Flag scripts that feel fragile, ambiguous, or overly complex
- 🛠 Suggest ways to modularize, test, harden, or improve naming
- ✨ Note anything that feels elegant, purposeful, or surprisingly solid

If you spot TODOs, unfinished rituals, or hallucinated AI logic, call it out. If you love a pattern, highlight it.

---

## 💀 Useful Files

- `rotkeeper-manual.md` — Generated from in-script comments via `rc-scriptbook.sh`. This is your living grimoire.
- `bones/` — Where logs, configs, and scan results are entombed.
- `home/` — Where your tombs and rendered results live.
- `rotkeeper-bom.yaml` — Required for `rc-expand.sh`; defines what gets generated.
- `render-flags.yaml` — Optional. Overrides rendering behavior for `rc-render.sh`.

---

## 🧩 Suggested Structure for Your Review

If contributing a formal review, structure it like this:

1. **🧐 Clarifying Questions** — About config, layout, script behavior
2. **🚩 Fragile / Complex Areas** — Any dangerous patterns, bad assumptions, or cursed logic
3. **💡 Suggestions** — Modularization, testing, validation, documentation
4. **✨ Highlights** — Anything elegant, poetic, or unusually clean

Bonus if your review concludes with “summary & next steps.” Bonus-er if it invokes the word "crypt."

---

## 🤘 Style Notes

Rotkeeper invites a certain tone:
- **Dry, sarcastic, slightly haunted** is encouraged.
- Feel free to swear at the shell scripts — they deserve it.
- Use the term "necromantic devops" at least once for luck.

CUNTIER™ reviews (Content Upgrades: Notably Thicker, Intensely Emphatic & Rot-bloated) are welcome.

Welcome to the bonepile.
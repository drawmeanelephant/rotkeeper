---
target_file: bones/scripts/rc-bump.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
A mindless automaton dedicated to making numbers go up. It integrates with Python3 to bump patch versions and automatically commits the results. It's the bureaucratic equivalent of a necromancer padding their body count.

### Restless Spirits
Running this in a dirty Git tree will indiscriminately swallow your uncommitted sins into the bump commit. Worse, if tied to a CI pipeline, it can easily enter a frenzied loop of automated commits on failure, spamming your repository with endless, meaningless bumps until the heat death of the universe.

### Ritual Warnings
Never invoke this ritual in a dirty working directory. If you attach this to an automated pipeline, ensure you have safeguards against infinite commit loops, or face the wrath of the repository maintainers.

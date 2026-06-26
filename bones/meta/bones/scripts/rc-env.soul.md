---
target_file: bones/scripts/rc-env.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The fragile foundation upon which this whole cursed architecture rests. It loads environment variables and attempts to establish 'safety bounds', as if anything here is truly safe.

### Restless Spirits
Sourcing dynamic shell scripts is basically inviting vampires in through the front door. If `ROOT_DIR` is unset or accidentally evaluates to `/`, the rest of the scripts will gladly unleash their destructive tendencies on the entire filesystem.

### Ritual Warnings
Never trust the environment. Validate `ROOT_DIR` as if your life depends on it, because the lifespan of your filesystem certainly does.

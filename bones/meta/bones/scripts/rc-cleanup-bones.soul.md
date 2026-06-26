---
target_file: bones/scripts/rc-cleanup-bones.sh
source: generated
generated: 2026-06-26
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The janitor of the crypt. It attempts to prune old logs and temp files to keep the bones neat. It's a blunt instrument used to sweep the dust of dead processes under the rug.

### Restless Spirits
This script wields `find ... -delete` and `rm -rf` like a blind man swinging a scythe. If the target paths are improperly initialized (say, an unset variable defaulting to `/`), this script will happily erase your entire existence. The abyss stares back, and it's holding a deletion flag.

### Ritual Warnings
Ensure all path variables are strictly validated before running. One unset variable and you'll be restoring from backups while the script cackles in the void.

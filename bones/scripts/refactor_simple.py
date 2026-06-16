import os
import glob

# Scripts that already have rk_init_script: rc-init, rc-render, rc-new, rc-pack, rc-assets
scripts = glob.glob("/Users/tbuddy/Documents/GitHub/rotkeeper/bones/scripts/rc-*.sh")
for filepath in scripts:
    with open(filepath, "r") as f:
        content = f.read()
    
    if "rk_init_script" in content or "rc-env.sh" in filepath or "rc-utils.sh" in filepath:
        continue

    script_name = os.path.basename(filepath).replace(".sh", "")

    # Clean up init_log
    import re
    content = re.sub(r'^\s*init_log\s+["\w$-]+.*$\n?', '', content, flags=re.MULTILINE)
    content = re.sub(r'^\s*trap\s+[\'"]trap_err.*?ERR.*$\n?', '', content, flags=re.MULTILINE)
    content = re.sub(r'^\s*trap\s+.*?EXIT.*$\n?', '', content, flags=re.MULTILINE)

    # Find the best place to insert rk_init_script "..." "$@"
    # Right after source .../rc-utils.sh
    # or set -euo pipefail
    
    lines = content.split('\n')
    insert_idx = -1
    for i, line in enumerate(lines):
        if "set -euo pipefail" in line or "IFS=$" in line:
            insert_idx = i + 1

    if insert_idx != -1:
        lines.insert(insert_idx, f'\nrk_init_script "{script_name}" "$@"')
        content = '\n'.join(lines)
        with open(filepath, "w") as f:
            f.write(content)
        print(f"Refactored {script_name}")
    else:
        print(f"Could not find insertion point for {script_name}")

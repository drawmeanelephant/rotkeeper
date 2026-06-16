import os
import glob
import re

scripts = glob.glob("/Users/tbuddy/Documents/GitHub/rotkeeper/bones/scripts/rc-*.sh")
for filepath in scripts:
    with open(filepath, "r") as f:
        content = f.read()

    # Find where source rc-utils.sh is
    source_match = re.search(r'^[ \t]*source.*rc-utils\.sh.*$\n?', content, flags=re.MULTILINE)
    if not source_match:
        print(f"No source rc-utils.sh found in {filepath}")
        continue

    # Remove rk_init_script from the file entirely
    content_clean = re.sub(r'^[ \t]*rk_init_script\s+["\w$-]+\s+"\$@".*$\n?', '', content, flags=re.MULTILINE)

    script_name = os.path.basename(filepath).replace(".sh", "")

    if script_name in ["rc-utils", "rc-env", "rc-log"]:
        continue

    # Insert rk_init_script immediately after the source line
    source_line = source_match.group(0)
    
    # We must replace the source line with itself + rk_init_script
    # in content_clean
    # Wait, the source line might be different in content_clean if it matched earlier
    source_match_clean = re.search(r'^[ \t]*source.*rc-utils\.sh.*$\n?', content_clean, flags=re.MULTILINE)
    if not source_match_clean:
        continue
        
    insert_str = f'{source_match_clean.group(0)}rk_init_script "{script_name}" "$@"\n'
    content_fixed = content_clean[:source_match_clean.start()] + insert_str + content_clean[source_match_clean.end():]

    if content_fixed != content:
        with open(filepath, "w") as f:
            f.write(content_fixed)
        print(f"Fixed {script_name}")

import os
import re
import glob

for filepath in glob.glob("/Users/tbuddy/Documents/GitHub/rotkeeper/bones/scripts/rc-*.sh"):
    with open(filepath, "r") as f:
        content = f.read()

    # Skip files that already have rk_init_script
    if "rk_init_script" in content and not filepath.endswith("rc-utils.sh"):
        continue

    script_name = os.path.basename(filepath).replace(".sh", "")

    # We want to replace the sequence of init_log and traps with rk_init_script.
    # Because they might be scattered, we'll just:
    # 1. Remove all init_log calls.
    # 2. Remove all trap 'trap_err $LINENO' ERR
    # 3. Remove all trap cleanup EXIT INT TERM (and similar)
    # 4. Insert rk_init_script at the first place we removed something.

    init_log_re = re.compile(r'^\s*init_log\s+["\w$-]+.*$', re.MULTILINE)
    trap_err_re = re.compile(r'^\s*trap\s+[\'"]trap_err.*?ERR.*$', re.MULTILINE)
    trap_exit_re = re.compile(r'^\s*trap\s+.*?EXIT.*$', re.MULTILINE)

    # Find the earliest index of any of these
    matches = []
    for match in init_log_re.finditer(content):
        matches.append((match.start(), match.end()))
    for match in trap_err_re.finditer(content):
        matches.append((match.start(), match.end()))
    for match in trap_exit_re.finditer(content):
        matches.append((match.start(), match.end()))

    if not matches:
        print(f"Skipping {filepath}, no boilerplate found.")
        continue

    matches.sort()
    insert_pos = matches[0][0]

    # Remove the lines
    content = init_log_re.sub('', content)
    content = trap_err_re.sub('', content)
    content = trap_exit_re.sub('', content)

    # Insert rk_init_script at insert_pos
    # But wait, insert_pos might be shifted because we did sub().
    # A better way is to do a single pass or insert a marker first.
    pass

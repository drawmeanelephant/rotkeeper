with open('bones/scripts/rc-env.sh', 'r') as f:
    content = f.read()

content = content.replace('ARCHIVE_DIR="$BONES_DIR/archive"', 'ARCHIVE_DIR="$BONES_DIR/archive"\nRELEASE_DIR="$ARCHIVE_DIR/releases"')

with open('bones/scripts/rc-env.sh', 'w') as f:
    f.write(content)

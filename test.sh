#!/bin/bash
git checkout bones/scripts/rc-dip.sh

awk '
/# 4. Stub Missing Docs/ {
    print "inject_cli_usage() {"
    print "    local doc_path=\"$1\""
    print "    local target_script=\"$2\""
    print "    local help_report=\"$REPORT_DIR/autopsy-help.md\""
    print ""
    print "    if [[ ! -f \"$help_report\" ]]; then"
    print "        return 0"
    print "    fi"
    print ""
    print "    local script_name"
    print "    script_name=$(basename \"$target_script\")"
    print ""
    print "    local help_content"
    print "    help_content=$(sed -n \"/^## $script_name\\$/,/^## /{ /^## /d; p; }\" \"$help_report\" | sed -e '\''1{/^$/d;}'\'' | sed -e '\''${/^$/d;}'\'')"
    print ""
    print "    if [[ -z \"$help_content\" ]]; then"
    print "        return 0"
    print "    fi"
    print ""
    print "    export HELP_CONTENT=\"$help_content\""
    print "    local marker=\"<!-- DIP-HELP-EXTRACTED: $(date +%F) -->\""
    print ""
    print "    awk -v marker=\"$marker\" '\''"
    print "    /^#### CLI Usage/ { print $0; print marker; next }"
    print "    /TODO: Stitch extracted help block\\./ { print ENVIRON[\"HELP_CONTENT\"]; next }"
    print "    { print $0 }"
    print "    '\'' \"$doc_path\" > \"${doc_path}.tmp\" && mv \"${doc_path}.tmp\" \"$doc_path\""
    print "}"
    print ""
}
{ print }
' bones/scripts/rc-dip.sh > bones/scripts/rc-dip.sh.tmp && mv bones/scripts/rc-dip.sh.tmp bones/scripts/rc-dip.sh

sed -i '/log "INFO" "Stubbed missing doc: $doc_path"/i \            inject_cli_usage "$doc_path" "$target_file"' bones/scripts/rc-dip.sh

sed -i 's/## CLI Usage/#### CLI Usage/g' bones/scripts/rc-dip.sh
sed -i '/<!-- DIP-HELP-EXTRACTED: 0000-00-00T00:00:00Z -->/d' bones/scripts/rc-dip.sh

start_line=$(grep -n "# Pillar 1: CLI Usage" bones/scripts/rc-dip.sh | cut -d: -f1)
if [[ -n "$start_line" ]]; then
    end_line=$((start_line + 9))
    sed -i "${start_line},${end_line}d" bones/scripts/rc-dip.sh
fi
chmod +x bones/scripts/rc-dip.sh
git commit -a --amend -m "fix: correctly inject cli usage with sed/awk"

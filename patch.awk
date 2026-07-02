/INGESTED_ARCHIVE_DIR="bones\/ingested"/ {
    print $0
    print "    QUARANTINE_DIR=\"bones/quarantine\""
    next
}
/mkdir -p "\$INGESTED_ARCHIVE_DIR"/ {
    print $0
    print "    mkdir -p \"$QUARANTINE_DIR\""
    next
}
/log "INFO" "Ingesting \$archive"/ {
    print $0
    print ""
    print "      # Validate archive paths against traversal attacks"
    print "      safe_archive=true"
    print "      while IFS= read -r archive_path; do"
    print "        if [[ \"$archive_path\" == /* ]] || [[ \"$archive_path\" == *\"../\"* ]]; then"
    print "          safe_archive=false"
    print "          break"
    print "        fi"
    print "      done < <(tar -tf \"$archive\" 2>/dev/null || true)"
    print ""
    print "      if [[ \"$safe_archive\" == false ]]; then"
    print "        log \"WARN\" \"Unsafe path detected in $archive. Moving to quarantine.\""
    print "        echo \"⚠️  WARNING: Unsafe paths (e.g. ../ or /) found in $archive. Moved to quarantine.\""
    print "        run mv \"$archive\" \"$QUARANTINE_DIR/\""
    print "        continue"
    print "      fi"
    next
}
{ print $0 }

#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-api.sh
# Purpose: Fetch and ingest remote content (templates, assets, packs)
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

init_log "rc-api"


main() {
    check_deps git rsync ssh pandoc date
    log "INFO" "Running rc-api.sh."

    CONFIG_FILE="bones/config/remote-sources.yaml"
    DEST_DIR="home/assets/remote"
    mkdir -p "$DEST_DIR"

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log "ERROR" "Missing config file: $CONFIG_FILE"
        exit 1
    fi

    count=$(yq e '.sources | length' "$CONFIG_FILE")
    log "INFO" "Found $count source(s) in config."

    for i in $(seq 0 $((count - 1))); do
        url=$(yq e ".sources[$i].url" "$CONFIG_FILE")
        filename=$(yq e ".sources[$i].filename" "$CONFIG_FILE")
        dest="$DEST_DIR/$filename"

        if [[ -z "$url" || -z "$filename" ]]; then
            log "WARN" "Skipping invalid entry at index $i"
            continue
        fi

        if [[ "$DRY_RUN" == true ]]; then
          log "DRY-RUN" "Would fetch: $url → $dest"
        else
          log "INFO" "Fetching: $url → $dest"
          curl -s -L -o "$dest" "$url" && \
              log "OK" "Fetched $filename" || \
              log "ERROR" "Failed to fetch $url"
        fi
    done
}

# =============================================================================
# remote-sources.yaml — Remote asset source declarations for rc-api.sh
# =============================================================================
# This file controls which external resources will be fetched when rc-api.sh runs.
# The assets retrieved here are stored in: home/assets/remote/
#
# Use this to define what we host on our own subdomains or asset servers.
# These may include:
#   - content packs (markdown ZIPs or json blobs)
#   - script updates
#   - shared templates
#   - icon sets or OpenMoji packs
#   - remote changelogs, metadata files, or server notices
#
# Each source block should define:
#   - url: the full URL to the file
#   - filename: the name it should be saved as locally
#
# Example sources:
#
# sources:
#   - url: "https://assets.rotkeeper.com/templates/plainstone.html"
#     filename: "plainstone.html"
#
#   - url: "https://assets.rotkeeper.com/scripts/rc-bless.sh"
#     filename: "rc-bless.sh"
#
#   - url: "https://assets.rotkeeper.com/packs/openmoji-icons.zip"
#     filename: "openmoji-icons.zip"
#
#   - url: "https://assets.rotkeeper.com/packs/core-tombdocs.zip"
#     filename: "core-tombdocs.zip"

main "$@"

#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-api.sh
# Purpose: Fetch and ingest remote content (templates, assets, packs)
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------
set -euo pipefail
IFS=$'\n\t'

LOG_FILE="rc-api.sh.log"

log() {
    local level="$1"; shift
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

cleanup() {
    log "INFO" "Cleaning up after rc-api.sh."
    # Add cleanup commands here
}
trap cleanup EXIT INT TERM

check_dependencies() {
    local deps=(git rsync ssh pandoc date)
    for cmd in "${deps[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 || {
            log "ERROR" "$cmd required but not installed."
            exit 1
        }
    done
}

main() {
    check_dependencies
    log "INFO" "Running rc-api.sh."
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

sources:
  - url: "https://assets.rotkeeper.com/templates/plainstone.html"
    filename: "plainstone.html"

  - url: "https://assets.rotkeeper.com/scripts/rc-bless.sh"
    filename: "rc-bless.sh"

  - url: "https://assets.rotkeeper.com/packs/openmoji-icons.zip"
    filename: "openmoji-icons.zip"

  - url: "https://assets.rotkeeper.com/packs/core-tombdocs.zip"
    filename: "core-tombdocs.zip"
    log "INFO" "rc-api.sh completed successfully."
}

main "$@"

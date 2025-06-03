#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-setenv.sh
# Purpose: Setup and validate all environment paths and dependencies
# Version: 0.2.5-pre
# Updated: 2025-06-03
# -----------------------------------------
# TODO:
# - Optionally dump created dirs to a tempfile for downstream inspection
# - Allow filtering which dirs to create via CLI args
set -euo pipefail

# Source rc-env.sh to get all required environment variables
source "$(dirname "${BASH_SOURCE[0]}")/rc-env.sh"
UTILS_PATH="$(dirname "${BASH_SOURCE[0]}")/rc-utils.sh"
if [[ ! -f "$UTILS_PATH" ]]; then
  echo "[FATAL] rc-utils.sh not found at $UTILS_PATH"
  exit 1
fi
source "$UTILS_PATH"

log "INFO" "Checking and creating expected directories from rc-env..."

# Extract all variables ending in _DIR or _PATH from the environment
for var in $(compgen -v); do
  if [[ "$var" =~ (_DIR|_PATH)$ ]]; then
    dir="${!var}"
    if [[ -n "$dir" && ! -d "$dir" && ! "$dir" =~ \.sh$ ]]; then
      if [[ "$dir" =~ ^/usr/ || "$dir" =~ ^/System/ ]]; then
        log "WARN" "Skipping system directory: $dir (from $var)"
        continue
      fi
      mkdir -p "$dir"
      log "INFO" "Created directory: $dir (from $var)"
    fi
  fi
done

# Optional: dependency check via rc-utils.sh
log "INFO" "Verifying known dependencies..."
require_bins bash awk grep sed tar date yq htmlq pandoc || {
  log "WARN" "One or more recommended tools are missing"
}

log "INFO" "Environment setup complete."
#!/usr/bin/env bash
# ============================================================
#  ██████╗  ██████╗ ████████╗██╗  ██╗███████╗███████╗██████╗
#  ██╔══██╗██╔═══██╗╚══██╔══╝██║ ██╔╝██╔════╝██╔════╝██╔══██╗
#  ██████╔╝██║   ██║   ██║   █████╔╝ █████╗  █████╗  ██████╔╝
#  ██╔══██╗██║   ██║   ██║   ██╔═██╗ ██╔══╝  ██╔══╝  ██╔═══╝
#  ██║  ██║╚██████╔╝   ██║   ██║  ██╗███████╗███████╗██║
#  ╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝
# ============================================================
#  Project : Rotkeeper
#  Repo    : https://github.com/drawmeanelephant/rotkeeper
#  Script  : rc-setenv.sh
#  Purpose : Set and verify runtime environment variables for Rotkeeper rituals
#  Version : 0.3.0.14
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

# TODO:
# - Optionally dump created dirs to a tempfile for downstream inspection
# - Allow filtering which dirs to create via CLI args
set -euo pipefail

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
check_dependencies

log "INFO" "Environment setup complete."

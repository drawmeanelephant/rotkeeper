

#!/usr/bin/env bash
# ░▒▓█ ROTKEEPER SCRIPT █▓▒░
# Script: rc-log.sh
# Purpose: Shared logging utility functions for all rc-*.sh scripts
# Version: 0.1.9.9
# Updated: 2025-05-27
# -----------------------------------------

# Auto-initialize log file path using script name
init_log() {
  local script_name
  script_name="$(basename "$0" .sh)"
  LOGFILE="bones/logs/${script_name}.log"
  mkdir -p "$(dirname "$LOGFILE")"
}

# Write a timestamped log entry to $LOGFILE
log() {
  local level="$1"
  shift
  echo "$(date +"%Y-%m-%d %H:%M:%S") [$level] $*" >>"$LOGFILE"
}
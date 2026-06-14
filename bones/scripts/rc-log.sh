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
#  Script  : rc-log.sh
#  Purpose : Shared logging utility functions for all rc-*.sh scripts
#  Version : 0.3.0.2
#  Updated : 2026-03-23
# ------------------------------------------------------------
#  Part of the Rotkeeper ritual system — bones, scripts, tombs.
# ============================================================

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


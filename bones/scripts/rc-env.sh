#!/usr/bin/env bash
# 🧱 rc-env.sh — Environment Bootstrap for Rotkeeper
# Provides canonical path variables for all rc-*.sh rituals.
# Source this at the top of every script to avoid hardcoded paths.

# Fail fast if sourced in a non-Bash shell
[[ -n "$BASH_VERSION" ]] || {
  echo "[ERROR] rc-env.sh must be sourced in Bash." >&2
  return 1 2>/dev/null || exit 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BONES_DIR="$ROOT_DIR/bones"
OUTPUT_DIR="$ROOT_DIR/output"
CONTENT_DIR="$ROOT_DIR/home/content"
LOG_DIR="$BONES_DIR/logs"
TMP_DIR="$ROOT_DIR/tmp"
CONFIG_DIR="$BONES_DIR/config"
ARCHIVE_DIR="$BONES_DIR/archive"
REPORT_DIR="$BONES_DIR/reports"
TEMPLATE_DIR="$BONES_DIR/templates"
DOCS_DIR="$ROOT_DIR/home/content/docs"
WEB_DIR="$OUTPUT_DIR"

export ROOT_DIR BONES_DIR OUTPUT_DIR CONTENT_DIR LOG_DIR TMP_DIR CONFIG_DIR
export ARCHIVE_DIR REPORT_DIR TEMPLATE_DIR DOCS_DIR WEB_DIR
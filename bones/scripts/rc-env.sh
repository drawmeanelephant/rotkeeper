#!/usr/bin/env bash
# 🧱 rc-env.sh — Environment Bootstrap for Rotkeeper
# Provides canonical path variables for all rc-*.sh rituals.
# Source this at the top of every script to avoid hardcoded paths.

# Fail fast if sourced in a non-Bash shell
[[ -n "$BASH_VERSION" ]] || {
  echo "[ERROR] rc-env.sh must be sourced in Bash." >&2
  return 1 2>/dev/null || exit 1
}

# Root
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Top-level
OUTPUT_DIR="$ROOT_DIR/output"
TMP_DIR="$ROOT_DIR/tmp"

# Home content
CONTENT_DIR="$ROOT_DIR/home/content"
ASSETS_DIR="$ROOT_DIR/home/assets"
DOCS_DIR="$CONTENT_DIR/docs"
HELP_DIR="$CONTENT_DIR/help"

# Bones
BONES_DIR="$ROOT_DIR/bones"
SCRIPT_DIR="$BONES_DIR/scripts"
CONFIG_DIR="$BONES_DIR/config"
LOG_DIR="$BONES_DIR/logs"
ARCHIVE_DIR="$BONES_DIR/archive"
REPORT_DIR="$BONES_DIR/reports"
TEMPLATE_DIR="$BONES_DIR/templates"
META_DIR="$BONES_DIR/meta"

# Web alias
WEB_DIR="$OUTPUT_DIR"

export ROOT_DIR BONES_DIR OUTPUT_DIR CONTENT_DIR ASSETS_DIR DOCS_DIR HELP_DIR
export LOG_DIR TMP_DIR CONFIG_DIR ARCHIVE_DIR REPORT_DIR SCRIPT_DIR TEMPLATE_DIR META_DIR
export WEB_DIR
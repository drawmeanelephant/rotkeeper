#!/usr/bin/env bash
# ============================================================
#  ███████╗███╗   ██╗██╗   ██╗
#  ██╔════╝████╗  ██║██║   ██║
#  █████╗  ██╔██╗ ██║██║   ██║
#  ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝
#  ███████╗██║ ╚████║ ╚████╔╝
#  ╚══════╝╚═╝  ╚═══╝  ╚═══╝
# ============================================================
#  Project : Rotkeeper
#  Script  : rc-env.sh
#  Purpose : Dynamic Environment Bootstrap — Portability Hardening
#  Version : 0.4.0.3
# ============================================================

VERSION="0.4.0.3"
[[ -n "$BASH_VERSION" ]] || {
  echo "[ERROR] rc-env.sh must be sourced in Bash." >&2
  return 1 2>/dev/null || exit 1
}

# Core structural bounds
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BONES_DIR="$ROOT_DIR/bones"
SCRIPT_DIR="$BONES_DIR/scripts"
CONFIG_DIR="$BONES_DIR/config"
LOG_DIR="$BONES_DIR/logs"
TMP_DIR="$BONES_DIR/tmp"
ARCHIVE_DIR="$BONES_DIR/archive"
REPORT_DIR="$BONES_DIR/reports"
BOOK_REPORT_DIR="$BONES_DIR/book-reports"
META_DIR="$BONES_DIR/meta"

# Dynamic layout parsing before fixing layout-dependent constants
# Looks at bones/config/rotkeeper.yaml first, drops back to root file for flat dist models
CONFIG_TARGET="$CONFIG_DIR/rotkeeper.yaml"
[[ ! -f "$CONFIG_TARGET" && -f "$ROOT_DIR/config/rotkeeper.yaml" ]] && CONFIG_TARGET="$ROOT_DIR/config/rotkeeper.yaml"

LAYOUT_STYLE="crypt"
if [[ -f "$CONFIG_TARGET" ]]; then
  LAYOUT_STYLE=$(grep -E '^layout_style:' "$CONFIG_TARGET" | cut -d'"' -f2 || echo "crypt")
fi

case "${LAYOUT_STYLE,,}" in
  "busy")
    # Pull templates, assets, and markdown roots up into visible project space
    TEMPLATE_DIR="$ROOT_DIR/templates"
    ASSETS_DIR="$ROOT_DIR/assets"
    CONTENT_DIR="$ROOT_DIR/home/content"
    OUTPUT_DIR="$ROOT_DIR/output"
    ;;

  "sterile")
    # Traditional non-spooky enterprise conventions
    TEMPLATE_DIR="$ROOT_DIR/config/templates"
    ASSETS_DIR="$ROOT_DIR/src/assets"
    CONTENT_DIR="$ROOT_DIR/src/content"
    OUTPUT_DIR="$ROOT_DIR/dist"
    ;;

  "crypt"|*)
    # Standard deep brutalist encapsulation mode
    TEMPLATE_DIR="$BONES_DIR/templates"
    ASSETS_DIR="$ROOT_DIR/home/assets"
    CONTENT_DIR="$ROOT_DIR/home/content"
    OUTPUT_DIR="$ROOT_DIR/output"
    ;;
esac

DOCS_DIR="$CONTENT_DIR/docs"
HELP_DIR="$CONTENT_DIR/help"
WEB_DIR="$OUTPUT_DIR"

export ROOT_DIR BONES_DIR OUTPUT_DIR CONTENT_DIR ASSETS_DIR DOCS_DIR HELP_DIR
export LOG_DIR TMP_DIR CONFIG_DIR ARCHIVE_DIR REPORT_DIR BOOK_REPORT_DIR SCRIPT_DIR TEMPLATE_DIR META_DIR
export WEB_DIR LAYOUT_STYLE

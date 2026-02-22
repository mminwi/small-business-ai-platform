#!/bin/bash
# convert.sh — Document conversion helper for Small Business AI Platform
# Wraps pandoc + Eisvogel for all common conversion directions.
#
# Usage:
#   bash tools/convert.sh md-to-pdf   input.md [output.pdf]
#   bash tools/convert.sh md-to-docx  input.md [output.docx]
#   bash tools/convert.sh docx-to-md  input.docx [output.md]
#
# See tools/pandoc-setup.md for installation instructions.

set -e

# ---------------------------------------------------------------------------
# Resolve tool paths (works regardless of whether PATH is updated in this shell)
# ---------------------------------------------------------------------------
PANDOC="/c/Users/$USERNAME/AppData/Local/Pandoc/pandoc.exe"
PDFLATEX_DIR="/c/Users/$USERNAME/AppData/Local/Programs/MiKTeX/miktex/bin/x64"
export PATH="$PDFLATEX_DIR:$PATH"

# ---------------------------------------------------------------------------
# Verify tools exist
# ---------------------------------------------------------------------------
check_tools() {
  local ok=true
  if [ ! -f "$PANDOC" ]; then
    echo "ERROR: pandoc not found at $PANDOC"
    echo "       Run: winget install --id JohnMacFarlane.Pandoc -e --silent --accept-source-agreements --accept-package-agreements"
    ok=false
  fi
  if [ ! -f "$PDFLATEX_DIR/pdflatex.exe" ]; then
    echo "ERROR: pdflatex not found at $PDFLATEX_DIR"
    echo "       Run: winget install --id MiKTeX.MiKTeX -e --silent --accept-source-agreements --accept-package-agreements"
    ok=false
  fi
  TEMPLATE="/c/Users/$USERNAME/AppData/Roaming/pandoc/templates/eisvogel.latex"
  if [ "$1" = "pdf" ] && [ ! -f "$TEMPLATE" ]; then
    echo "ERROR: Eisvogel template not found at $TEMPLATE"
    echo "       See tools/pandoc-setup.md Step 3 for install instructions."
    ok=false
  fi
  if [ "$ok" = false ]; then exit 1; fi
}

# ---------------------------------------------------------------------------
# Conversion functions
# ---------------------------------------------------------------------------
md_to_pdf() {
  local input="$1"
  local output="${2:-${input%.md}.pdf}"
  check_tools pdf
  echo "Converting: $input → $output"
  "$PANDOC" "$input" \
    --template eisvogel \
    --pdf-engine=pdflatex \
    -o "$output" \
    -V colorlinks=true \
    -V linkcolor=blue \
    -V "geometry:margin=1in" \
    -V fontsize=11pt
  echo "Done: $output"
}

md_to_docx() {
  local input="$1"
  local output="${2:-${input%.md}.docx}"
  check_tools
  echo "Converting: $input → $output"
  "$PANDOC" "$input" -o "$output"
  echo "Done: $output"
}

docx_to_md() {
  local input="$1"
  local output="${2:-${input%.docx}.md}"
  local media_dir
  media_dir="$(dirname "$output")/media"
  check_tools
  echo "Converting: $input → $output"
  echo "  (embedded images → $media_dir/)"
  "$PANDOC" "$input" --extract-media="$media_dir" -o "$output"
  echo "Done: $output"
  echo ""
  echo "Review checklist:"
  echo "  [ ] Headings look correct"
  echo "  [ ] Tables converted cleanly (merged cells may need manual fix)"
  echo "  [ ] Remove any leftover tracked-change markup"
  echo "  [ ] Move file to appropriate /procedures/ subfolder"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
COMMAND="${1:-help}"
INPUT="$2"
OUTPUT="$3"

case "$COMMAND" in
  md-to-pdf)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh md-to-pdf input.md [output.pdf]"; exit 1; fi
    md_to_pdf "$INPUT" "$OUTPUT"
    ;;
  md-to-docx)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh md-to-docx input.md [output.docx]"; exit 1; fi
    md_to_docx "$INPUT" "$OUTPUT"
    ;;
  docx-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh docx-to-md input.docx [output.md]"; exit 1; fi
    docx_to_md "$INPUT" "$OUTPUT"
    ;;
  help|*)
    echo ""
    echo "convert.sh — Document conversion for Small Business AI Platform"
    echo ""
    echo "Usage:"
    echo "  bash tools/convert.sh md-to-pdf   input.md [output.pdf]   # Markdown → PDF (Eisvogel)"
    echo "  bash tools/convert.sh md-to-docx  input.md [output.docx]  # Markdown → Word"
    echo "  bash tools/convert.sh docx-to-md  input.docx [output.md]  # Word → Markdown"
    echo ""
    echo "See tools/pandoc-setup.md for installation instructions."
    echo ""
    ;;
esac

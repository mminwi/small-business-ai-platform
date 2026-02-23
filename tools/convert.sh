#!/bin/bash
# convert.sh — Document conversion helper for Small Business AI Platform
# Wraps pandoc + Eisvogel for all common conversion directions.
#
# Usage:
#   bash tools/convert.sh md-to-pdf   input.md      [output.pdf]    # Markdown → PDF (Eisvogel)
#   bash tools/convert.sh md-to-docx  input.md      [output.docx]   # Markdown → Word
#   bash tools/convert.sh docx-to-md  input.docx    [output.md]     # Word → Markdown
#   bash tools/convert.sh xlsx-to-md  input.xlsx    [output.md]     # Excel → Markdown
#   bash tools/convert.sh csv-to-md   input.csv     [output.md]     # CSV → Markdown table
#   bash tools/convert.sh pptx-to-md  input.pptx    [output.md]     # PowerPoint → Markdown
#   bash tools/convert.sh html-to-md  input.html    [output.md]     # HTML → Markdown
#   bash tools/convert.sh rtf-to-md   input.rtf     [output.md]     # RTF → Markdown
#   bash tools/convert.sh any-to-md   input.xyz     [output.md]     # Any supported format → Markdown
#
# See tools/pandoc-setup.md for full format list and installation instructions.

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

md_to_letterhead_pdf() {
  local input="$1"
  local output="${2:-${input%.md}.pdf}"
  local logo="/c/Users/$USERNAME/AppData/Roaming/pandoc/credo-logo.png"
  local tex="/c/Users/$USERNAME/AppData/Roaming/pandoc/credo-letterhead.tex"
  check_tools pdf
  if [ ! -f "$logo" ]; then
    echo "ERROR: Logo not found at $logo"
    echo "       Copy credo-logo.png to %APPDATA%\\pandoc\\"
    exit 1
  fi
  if [ ! -f "$tex" ]; then
    echo "ERROR: Letterhead template not found at $tex"
    echo "       See tools/pandoc-setup.md for setup instructions."
    exit 1
  fi
  echo "Converting with Credo letterhead: $input → $output"
  "$PANDOC" "$input" \
    --template eisvogel \
    --pdf-engine=lualatex \
    --include-in-header="$tex" \
    -o "$output" \
    -V colorlinks=true \
    -V linkcolor=blue \
    -V "geometry:top=1.0in,left=1in,right=1in,bottom=1in" \
    -V fontsize=11pt \
    -V disable-header-and-footer=true
  echo "Done: $output"
}

md_to_qms_pdf() {
  local input="$1"
  local output="${2:-${input%.md}.pdf}"
  local logo="/c/Users/$USERNAME/AppData/Roaming/pandoc/credo-logo.png"
  local tex="/c/Users/$USERNAME/AppData/Roaming/pandoc/credo-qms-letterhead.tex"
  check_tools pdf
  if [ ! -f "$logo" ]; then
    echo "ERROR: Logo not found at $logo"
    echo "       Copy credo-logo.png to %APPDATA%\\pandoc\\"
    exit 1
  fi
  if [ ! -f "$tex" ]; then
    echo "ERROR: QMS letterhead template not found at $tex"
    echo "       Copy my-workspace/templates/credo-qms-letterhead.tex to %APPDATA%\\pandoc\\"
    exit 1
  fi
  echo "Converting with Credo QMS letterhead: $input → $output"
  "$PANDOC" "$input" \
    --template eisvogel \
    --pdf-engine=lualatex \
    --include-in-header="$tex" \
    -o "$output" \
    -V colorlinks=true \
    -V linkcolor=blue \
    -V "geometry:top=1.0in,left=1in,right=1in,bottom=1in" \
    -V fontsize=11pt \
    -V disable-header-and-footer=true
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
  _review_checklist "$output"
}

xlsx_to_md() {
  local input="$1"
  local output="${2:-${input%.xlsx}.md}"
  check_tools
  echo "Converting: $input → $output"
  echo "  (each worksheet becomes a markdown table)"
  "$PANDOC" "$input" -o "$output"
  echo "Done: $output"
  echo ""
  echo "Review checklist:"
  echo "  [ ] Each sheet/table has expected columns and data"
  echo "  [ ] Merged cells will have lost their merge — check data is intact"
  echo "  [ ] Formulas are replaced by their last calculated value"
  echo "  [ ] Charts are dropped — data only"
}

csv_to_md() {
  local input="$1"
  local output="${2:-${input%.csv}.md}"
  check_tools
  echo "Converting: $input → $output"
  "$PANDOC" "$input" -o "$output"
  echo "Done: $output"
}

pptx_to_md() {
  local input="$1"
  local output="${2:-${input%.pptx}.md}"
  local media_dir
  media_dir="$(dirname "$output")/media"
  check_tools
  echo "Converting: $input → $output"
  echo "  (slide titles → headings, bullets → lists, images → $media_dir/)"
  "$PANDOC" "$input" --extract-media="$media_dir" -o "$output"
  _review_checklist "$output"
}

html_to_md() {
  local input="$1"
  local output="${2:-${input%.html}.md}"
  check_tools
  echo "Converting: $input → $output"
  "$PANDOC" "$input" -o "$output"
  echo "Done: $output"
}

rtf_to_md() {
  local input="$1"
  local output="${2:-${input%.rtf}.md}"
  check_tools
  echo "Converting: $input → $output"
  "$PANDOC" "$input" -o "$output"
  _review_checklist "$output"
}

any_to_md() {
  local input="$1"
  local ext="${input##*.}"
  local output="${2:-${input%.*}.md}"
  local media_dir
  media_dir="$(dirname "$output")/media"
  check_tools
  echo "Converting: $input → $output  (auto-detecting format from .$ext)"
  "$PANDOC" "$input" --extract-media="$media_dir" -o "$output"
  _review_checklist "$output"
}

_review_checklist() {
  local output="$1"
  echo "Done: $output"
  echo ""
  echo "Review checklist:"
  echo "  [ ] Headings and structure look correct"
  echo "  [ ] Tables converted cleanly (merged cells may need manual fix)"
  echo "  [ ] Remove any tracked-change or revision markup artifacts"
  echo "  [ ] Move file to appropriate /procedures/ subfolder when clean"
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
  md-to-letterhead-pdf)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh md-to-letterhead-pdf input.md [output.pdf]"; exit 1; fi
    md_to_letterhead_pdf "$INPUT" "$OUTPUT"
    ;;
  md-to-qms-pdf)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh md-to-qms-pdf input.md [output.pdf]"; exit 1; fi
    md_to_qms_pdf "$INPUT" "$OUTPUT"
    ;;
  md-to-docx)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh md-to-docx input.md [output.docx]"; exit 1; fi
    md_to_docx "$INPUT" "$OUTPUT"
    ;;
  docx-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh docx-to-md input.docx [output.md]"; exit 1; fi
    docx_to_md "$INPUT" "$OUTPUT"
    ;;
  xlsx-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh xlsx-to-md input.xlsx [output.md]"; exit 1; fi
    xlsx_to_md "$INPUT" "$OUTPUT"
    ;;
  csv-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh csv-to-md input.csv [output.md]"; exit 1; fi
    csv_to_md "$INPUT" "$OUTPUT"
    ;;
  pptx-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh pptx-to-md input.pptx [output.md]"; exit 1; fi
    pptx_to_md "$INPUT" "$OUTPUT"
    ;;
  html-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh html-to-md input.html [output.md]"; exit 1; fi
    html_to_md "$INPUT" "$OUTPUT"
    ;;
  rtf-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh rtf-to-md input.rtf [output.md]"; exit 1; fi
    rtf_to_md "$INPUT" "$OUTPUT"
    ;;
  any-to-md)
    if [ -z "$INPUT" ]; then echo "Usage: convert.sh any-to-md input.file [output.md]"; exit 1; fi
    any_to_md "$INPUT" "$OUTPUT"
    ;;
  help|*)
    echo ""
    echo "convert.sh — Document conversion for Small Business AI Platform"
    echo ""
    echo "  → Markdown (ingest existing documents into the system):"
    echo "  bash tools/convert.sh docx-to-md  input.docx   [output.md]"
    echo "  bash tools/convert.sh xlsx-to-md  input.xlsx   [output.md]"
    echo "  bash tools/convert.sh csv-to-md   input.csv    [output.md]"
    echo "  bash tools/convert.sh pptx-to-md  input.pptx   [output.md]"
    echo "  bash tools/convert.sh html-to-md  input.html   [output.md]"
    echo "  bash tools/convert.sh rtf-to-md   input.rtf    [output.md]"
    echo "  bash tools/convert.sh any-to-md   input.xyz    [output.md]"
    echo ""
    echo "  From Markdown (produce deliverables):"
    echo "  bash tools/convert.sh md-to-pdf              input.md     [output.pdf]"
    echo "  bash tools/convert.sh md-to-letterhead-pdf  input.md     [output.pdf]"
    echo "  bash tools/convert.sh md-to-qms-pdf         input.md     [output.pdf]"
    echo "  bash tools/convert.sh md-to-docx            input.md     [output.docx]"
    echo ""
    echo "See tools/pandoc-setup.md for full format list and install instructions."
    echo ""
    ;;
esac

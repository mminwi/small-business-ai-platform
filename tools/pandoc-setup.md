# Pandoc + Eisvogel Setup Guide

This guide covers installation of Pandoc and the Eisvogel PDF template on Windows.
Once installed, the `convert.sh` script in this folder handles all document conversions.

**Why this matters:** All business logic in this platform lives in markdown files.
Pandoc converts those markdown files into professional PDFs or Word documents for clients.
It also converts a wide range of existing file types *into* markdown — Word docs, Excel
spreadsheets, HTML, PowerPoint, CSV, RTF, and more. Once something is markdown, the AI
can read it, reason about it, and maintain it.

---

## What Gets Installed

| Package | Purpose | Install size |
|---|---|---|
| **Pandoc** | Universal document converter | ~40 MB |
| **MiKTeX** | LaTeX engine (required for PDF output) | ~140 MB |
| **Eisvogel** | PDF template — clean, professional formatting | ~1 MB |

---

## Installation (Windows, one-time per PC)

### Step 1 — Install Pandoc

```bash
winget install --id JohnMacFarlane.Pandoc -e --silent --accept-source-agreements --accept-package-agreements
```

**Installs to:** `C:\Users\[username]\AppData\Local\Pandoc\`

### Step 2 — Install MiKTeX

```bash
winget install --id MiKTeX.MiKTeX -e --silent --accept-source-agreements --accept-package-agreements
```

**Installs to:** `C:\Users\[username]\AppData\Local\Programs\MiKTeX\`
**Takes 3–5 minutes** — it's a 140 MB download.

### Step 3 — Install the Eisvogel template

Create the pandoc templates folder and download the template:

```bash
mkdir -p "$APPDATA/pandoc/templates"
curl -L "https://github.com/Wandmalfarbe/pandoc-latex-template/releases/latest/download/Eisvogel.tar.gz" -o /tmp/eisvogel.tar.gz
tar -xzf /tmp/eisvogel.tar.gz -C /tmp/
cp /tmp/Eisvogel-*/eisvogel.latex "$APPDATA/pandoc/templates/eisvogel.latex"
```

**Template lands at:** `C:\Users\[username]\AppData\Roaming\pandoc\templates\eisvogel.latex`

### Step 4 — First-run MiKTeX setup (do this once)

Open **MiKTeX Console** from the Start menu → click **Updates** → **Check for updates** → install any available.

This silences the "you have not checked for MiKTeX updates" warning that appears on every
PDF conversion until you do it.

MiKTeX also auto-downloads any missing LaTeX packages on first use. The first PDF
conversion may take longer than expected while it pulls packages — that's normal.

---

## Verify the Install

Run this to confirm all three components are present:

```bash
PANDOC="/c/Users/$USERNAME/AppData/Local/Pandoc/pandoc.exe"
PDFLATEX="/c/Users/$USERNAME/AppData/Local/Programs/MiKTeX/miktex/bin/x64/pdflatex.exe"
TEMPLATE="/c/Users/$USERNAME/AppData/Roaming/pandoc/templates/eisvogel.latex"

echo "pandoc:    $(test -f $PANDOC    && echo OK || echo MISSING)"
echo "pdflatex:  $(test -f $PDFLATEX  && echo OK || echo MISSING)"
echo "eisvogel:  $(test -f $TEMPLATE  && echo OK || echo MISSING)"
```

---

## Known Gotchas

### Git Bash / MSYS2 does not pick up the new PATH automatically
Pandoc and MiKTeX add themselves to the Windows PATH, but Git Bash sessions started
*before* the install (or in some cases after) won't see them. The `convert.sh` script
handles this by using absolute paths — no manual PATH changes needed.

If you call pandoc directly from the command line, add this to your session first:

```bash
export PATH="/c/Users/$USERNAME/AppData/Local/Pandoc:/c/Users/$USERNAME/AppData/Local/Programs/MiKTeX/miktex/bin/x64:$PATH"
```

### winget prompts for msstore agreement interactively
Without `--accept-source-agreements`, winget opens an interactive prompt that fails
in non-interactive shells. Always include both flags:
`--accept-source-agreements --accept-package-agreements`

### Multi-line bash commands with backslash continuation fail in some shells
When calling pandoc with many flags, put the command in a `.sh` script file and run
`bash script.sh` rather than running it inline. The `convert.sh` script in this folder
is the right way to invoke conversions.

### MiKTeX auto-downloads missing packages on first PDF render
The first time you use a new template feature or LaTeX package, MiKTeX fetches it
automatically. This is correct behavior. If you're on a restricted network, you may
need to manually install packages via MiKTeX Console → Packages.

---

## Conversion Reference

Use `tools/convert.sh` in this repo. It handles paths automatically — no manual PATH setup needed.

```bash
bash tools/convert.sh md-to-pdf    input.md       [output.pdf]
bash tools/convert.sh md-to-docx   input.md       [output.docx]
bash tools/convert.sh docx-to-md   input.docx     [output.md]
bash tools/convert.sh xlsx-to-md   input.xlsx     [output.md]
bash tools/convert.sh csv-to-md    input.csv      [output.md]
bash tools/convert.sh pptx-to-md   input.pptx     [output.md]
bash tools/convert.sh html-to-md   input.html     [output.md]
bash tools/convert.sh rtf-to-md    input.rtf      [output.md]
bash tools/convert.sh any-to-md    input.xyz      [output.md]
```

`any-to-md` works for any supported input format — pandoc detects the format from the file extension.

### Markdown → PDF with title page
Add YAML front matter at the top of your `.md` file:
```yaml
---
title: "Invoicing Procedure"
subtitle: "AI Employee Handbook"
author: "Your Company Name"
date: "2026-02-22"
---
```
Eisvogel renders a title page automatically when these fields are present.

---

## Supported Input Formats (→ Markdown)

Pandoc can convert all of the following into markdown. Verified against Pandoc 3.9.

| Format | Extension | Notes |
|---|---|---|
| **Word** | `.docx` | Best supported. Tables, headings, lists convert cleanly. |
| **Excel** | `.xlsx` | Each sheet becomes a markdown table. Good for rate sheets, BOMs, checklists. |
| **PowerPoint** | `.pptx` | Slide titles become headings; bullet text becomes lists. Images dropped. |
| **CSV** | `.csv` | Converts to a single markdown table. |
| **TSV** | `.tsv` | Same as CSV. |
| **HTML** | `.html` | Very clean conversion. |
| **RTF** | `.rtf` | Rich Text Format — older Word-compatible format. |
| **OpenDocument** | `.odt` | LibreOffice Writer format. |
| **EPUB** | `.epub` | Ebooks. |
| **LaTeX** | `.tex` | Academic/technical documents. |
| **reStructuredText** | `.rst` | Python ecosystem docs. |
| **Jupyter Notebook** | `.ipynb` | Code + prose notebooks. |
| **MediaWiki** | `.mediawiki` | Wikipedia-style markup. |
| **Org-mode** | `.org` | Emacs format. |
| **AsciiDoc** | `.asciidoc` | Technical documentation format. |

**Cannot read (pandoc):** PDF, images, and binary formats not listed above.

**PDF → Markdown:** Do NOT use pandoc for this. Claude reads PDFs natively.
Give Claude the file path and ask it to convert to markdown. Claude uses its built-in
Read tool to extract the content and write a clean `.md` file — no additional software needed.

**Excel notes:** Pandoc reads `.xlsx` directly — no need to save as CSV first. Each worksheet
becomes a separate section with a markdown table. Complex formatting (merged cells, formulas,
charts) is dropped — only the data values come through. That's usually what you want.

---

## Supported Output Formats (from Markdown)

| Format | Extension | Use case |
|---|---|---|
| **PDF** | `.pdf` | Client deliverables, proposals, procedures |
| **Word** | `.docx` | Editable documents for clients who need Word |
| **HTML** | `.html` | Web publishing |
| **EPUB** | `.epub` | Ebook distribution |
| **PowerPoint** | `.pptx` | Slide decks from markdown outline |
| **OpenDocument** | `.odt` | LibreOffice |
| **RTF** | `.rtf` | Legacy compatibility |
| **LaTeX** | `.tex` | Academic publishing |
| **Plain text** | `.txt` | Stripped of all formatting |

---

## Where to Find Things (for future installs)

| What | Where to get it |
|---|---|
| Pandoc releases | https://github.com/jgm/pandoc/releases |
| Pandoc winget ID | `JohnMacFarlane.Pandoc` |
| MiKTeX winget ID | `MiKTeX.MiKTeX` |
| Eisvogel releases | https://github.com/Wandmalfarbe/pandoc-latex-template/releases |
| Eisvogel archive name | `Eisvogel.tar.gz` (inside: `eisvogel.latex`) |
| Pandoc templates folder | `%APPDATA%\pandoc\templates\` |
| Pandoc install folder | `%LOCALAPPDATA%\Pandoc\` |
| MiKTeX install folder | `%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64\` |

---

## Bringing Existing Documents into the System

Any document containing business procedures, SOPs, or ISO documentation
should be converted to markdown before being stored in this system. Markdown files
are readable by AI agents; binary files (Word, Excel, PDF) are not readable by pandoc,
and Word/Excel are not readable by Claude directly.

**Format routing:**

| File type | How to convert to markdown |
|---|---|
| `.docx` (Word) | `bash tools/convert.sh docx-to-md file.docx` |
| `.xlsx` (Excel) | `bash tools/convert.sh xlsx-to-md file.xlsx` |
| `.pptx` (PowerPoint) | `bash tools/convert.sh pptx-to-md file.pptx` |
| `.pdf` | Give Claude the file path — Claude reads PDFs natively and writes the markdown |
| `.csv` / `.tsv` | `bash tools/convert.sh csv-to-md file.csv` |
| `.html` / `.rtf` / `.odt` | `bash tools/convert.sh any-to-md file.ext` |

**Conversion process:**
1. Run `tools/convert.sh docx-to-md yourfile.docx`
2. Review the output — pandoc does a good job but tables and complex formatting
   may need cleanup
3. Remove any leftover Word artifacts (revision marks, tracked changes, etc.)
4. Save the `.md` file in the appropriate `/procedures/` subfolder

**What converts cleanly:** Headings, paragraphs, bold/italic, bullet lists, numbered
lists, simple tables, hyperlinks.

**What needs manual cleanup:** Complex tables with merged cells, text boxes, headers/footers,
embedded Excel charts, revision tracking markup.

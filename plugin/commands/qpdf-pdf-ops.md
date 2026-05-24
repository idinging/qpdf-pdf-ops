---
description: "Lossless PDF page manipulation using qpdf: merge, split, extract, delete, replace, insert, rotate, reorder, decrypt, encrypt PDFs."
argument-hint: "[operation] <files> - e.g. merge 1.pdf 2.pdf, split document.pdf, extract 1-5 from doc.pdf"
allowed-tools: "*"
---

Load the `qpdf-pdf-ops` skill and execute the requested PDF operation.

## Quick reference

| Operation | Command Pattern |
|-----------|---------------|
| Merge PDFs | `merge_pdfs.sh OUT.pdf A.pdf B.pdf ...` |
| Split PDF | `split_pdf.sh IN.pdf OUT_DIR/` |
| Extract pages | `extract_pages.sh IN.pdf RANGE OUT.pdf` |
| Delete pages | `delete_pages.sh IN.pdf RANGE OUT.pdf` |
| Replace page | `replace_page.sh IN.pdf N REPL.pdf M OUT.pdf` |
| Rotate pages | `qpdf --rotate=+90:RANGE IN.pdf OUT.pdf` |
| Inspect PDF | `pdf_info.sh IN.pdf` |
| Decrypt PDF | `qpdf --password=PW --decrypt IN.pdf OUT.pdf` |
| Encrypt PDF | `qpdf --encrypt PW PW 256 -- IN.pdf OUT.pdf` |

Always run `scripts/check_qpdf.sh` first to verify qpdf is installed.
For detailed recipes and edge cases, see `references/recipes.md`.

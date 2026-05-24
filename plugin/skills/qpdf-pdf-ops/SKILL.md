---
name: qpdf-pdf-ops
description: "Lossless PDF page manipulation using qpdf: merge PDFs, split PDFs, extract pages, delete pages, replace pages, insert pages, rotate pages, reorder pages, decrypt PDFs, encrypt PDFs. Use when the user wants structural PDF edits — \"合并PDF\", \"拆分PDF\", \"提取PDF页\", \"删除PDF页\", \"替换PDF页\", \"旋转PDF\", \"PDF倒序\", \"PDF解密\", \"merge PDF\", \"split PDF\", \"extract PDF pages\", \"delete PDF pages\", \"replace PDF page\", \"rotate PDF\", \"reorder PDF\", \"decrypt PDF\", \"encrypt PDF\". Content-preserving; does not rasterize or re-render."
license: MIT
metadata:
  author: idinging
  version: "0.1.0"
---

# qpdf PDF Operations

## Overview

Drive the [qpdf](https://qpdf.readthedocs.io) command-line tool to perform
content-preserving structural edits on PDF files: replace, insert, delete,
extract, merge, split, rotate, and reorder pages, plus handle encryption.
qpdf does **not** rasterize or re-render pages — original content streams
are kept intact, so output PDFs are lossless.

## Out of scope

qpdf is a structural tool. It does **not** do any of the following — if the
request needs one of these, say so and stop, do not improvise with qpdf:

- OCR or text recognition on scanned PDFs
- Editing text/images inside a page
- Filling out interactive forms
- Aggressive image recompression to shrink file size (use Ghostscript)
- Adding/verifying digital signatures
- Converting to/from other formats (DOCX, HTML, images)

## Preflight: ensure qpdf is installed

Before running any operation, verify qpdf is on PATH and at a supported
version:

```bash
bash scripts/check_qpdf.sh
```

The script prints the qpdf version on success. On failure or when the
version is below 10.6 (the minimum this skill targets), it prints
platform-specific install hints (apt/dnf/brew/choco). Surface the install
hint to the user and stop — do not attempt to substitute another tool
unless asked.

## When to invoke this skill

Trigger on requests that map to page-level PDF surgery, including but not
limited to:

- "用 X.pdf 的第 1 页替换 Y.pdf 的第 3 页" → `replace_page.sh`
- "删除第 5-7 页" / "去掉最后一页" → `delete_pages.sh`
- "提取第 3-5 页另存为新 PDF" → `extract_pages.sh`
- "把这几个 PDF 合并成一个" → `merge_pdfs.sh`
- "把 PDF 拆成单页" / "每 10 页一份" → `split_pdf.sh`
- "把第 2 页旋转 90 度" / "整个文档倒序" → `qpdf --rotate=...`
- "插入一页到现有 PDF"
- "这个 PDF 加了密码,帮我解开" → see recipe 12 in `references/recipes.md`

## Quick task map

| Task                              | Approach                                                   |
|-----------------------------------|------------------------------------------------------------|
| Inspect (page count, encryption)  | `scripts/pdf_info.sh IN.pdf`                               |
| Extract pages                     | `scripts/extract_pages.sh IN.pdf RANGE OUT.pdf`            |
| Delete pages                      | `scripts/delete_pages.sh IN.pdf RANGE OUT.pdf`             |
| Replace one page                  | `scripts/replace_page.sh IN.pdf N REPL.pdf M OUT.pdf`      |
| Insert a page                     | `qpdf IN.pdf --pages . 1-K INS.pdf P . K+1-z -- OUT.pdf`   |
| Merge PDFs                        | `scripts/merge_pdfs.sh OUT.pdf A.pdf B.pdf ...`            |
| Split (one file per page)         | `scripts/split_pdf.sh IN.pdf OUT_DIR/`                     |
| Rotate pages                      | `qpdf --rotate=+90:RANGE IN.pdf OUT.pdf`                   |
| Reorder pages                     | `qpdf IN.pdf --pages . <new-order-range> -- OUT.pdf`       |
| Decrypt (remove password)         | `qpdf --password=PW --decrypt IN.pdf OUT.pdf`              |
| Add password                      | `qpdf --encrypt PW PW 256 -- IN.pdf OUT.pdf`               |
| Overwrite in place                | append `--replace-input` (omit OUT.pdf)                    |

For the full set of recipes with worked examples and edge cases, load
`references/recipes.md`. For the page-range mini-language (`x` exclusion,
`r1`/`z`, `:even`/`:odd`, reversal via `b-a`), load
`references/page-ranges.md`.

## Core mental model

Most page operations boil down to **`qpdf --pages` with a list of `(file,
range)` pairs**, terminated by `--`:

```
qpdf PRIMARY.pdf --pages SRC1 RANGE1 SRC2 RANGE2 ... -- OUT.pdf
```

- `PRIMARY.pdf` is where document-level metadata (outlines, tags) is taken
  from. Use `--empty` instead if no carryover is desired.
- `.` inside the `--pages` block is shorthand for `PRIMARY.pdf`.
- Each `(SRC, RANGE)` pair contributes its pages, in order, to the output.
- The `--` separator after the last pair is **mandatory**.

Concrete example:

```bash
qpdf A.pdf --pages . 1-3 B.pdf 1 . 5-z -- OUT.pdf
#         ^pairs:   (A, 1-3) (B, 1)   (A, 5-end)
# Result: A.pdf pages 1,2,3 + B.pdf page 1 + A.pdf pages 5..end
```

Once this model is clear, replace/insert/delete/reorder/merge all reduce to
choosing the right list of pairs.

## Encrypted PDFs

If `scripts/pdf_info.sh` reports `Encrypted : yes`, every subsequent qpdf
invocation on that file needs `--password=...` placed **before** the
filename it unlocks. Workflow:

1. Ask the user for the password — never guess.
2. Pass `--password=PW` to qpdf for each protected input.
3. To strip the password permanently: `qpdf --password=PW --decrypt IN.pdf OUT.pdf`.

Full grammar (multi-file merges with different passwords, `--encrypt` to
add passwords) lives in recipe 12 of `references/recipes.md`.

## Execution guidelines

1. **Never overwrite the input by accident.** Always write to a new output
   path. Use `--replace-input` only when the user explicitly asks to modify
   in place; qpdf performs an atomic temp-file rename in that mode.
2. **Verify before destructive ops.** When the user asks to delete or
   replace pages, first run `scripts/pdf_info.sh` (or `qpdf --show-npages`)
   to confirm the page count, so range boundaries are sane.
3. **Quote filenames.** Paths often contain spaces or non-ASCII characters
   (e.g. Chinese filenames). Always quote arguments when invoking scripts or
   qpdf from shell snippets.
4. **Use relative rotation angles** (`+90`, `-90`) rather than absolute, so
   the rotation composes with any rotation already encoded in the page.
5. **Sanity-check output** for non-trivial transformations with
   `qpdf --check OUT.pdf`. This catches broken cross-references introduced
   by selecting pages whose annotations point at removed pages.
6. **Report what changed** back to the user: old page count → new page count,
   what was inserted/removed/replaced, and the output path.
7. **Stop on encrypted inputs without a password.** Ask, do not guess.

## Bundled resources

- `scripts/check_qpdf.sh` — detect qpdf, verify minimum version, print
  install hints when missing.
- `scripts/pdf_info.sh` — file size, page count, PDF version, encryption,
  and one-line integrity verdict. Pass `--verbose` for the full
  `qpdf --check` dump.
- `scripts/replace_page.sh` — replace page N of one PDF with page M of
  another; handles first-page and last-page edge cases and validates both
  page indices.
- `scripts/delete_pages.sh` — remove a page range using qpdf's `x`
  exclusion operator, hidden behind a friendlier signature.
- `scripts/extract_pages.sh` — extract a page range into a new PDF.
- `scripts/merge_pdfs.sh` — concatenate multiple PDFs (default: no metadata
  carryover; pass `--keep-metadata-from FIRST` to inherit from the first
  input).
- `scripts/split_pdf.sh` — split into one file per page or per N pages,
  writing into an output directory.
- `references/recipes.md` — copy-pasteable recipes for every supported
  operation including encryption, optimization, attachments, and `--qdf`
  debug output, with edge cases and gotchas. Load when the requested
  operation is non-trivial or unfamiliar.
- `references/page-ranges.md` — full grammar of qpdf page ranges (`r1`, `z`,
  `x` exclusion, `:even`/`:odd`, reversal). Load whenever a request requires
  a non-obvious range.

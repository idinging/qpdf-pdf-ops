---
name: qpdf-pdf-ops
description: Manipulate PDF files with the qpdf CLI — replace a page with one from another PDF, delete or extract pages, merge or split documents, rotate, and reorder pages. This skill should be used when the user wants to edit PDF page structure (e.g. "替换第N页", "删除某几页", "合并这些PDF", "把PDF拆成单页", "旋转第3页", "把PDF倒序") and the operation can be expressed as page-level changes rather than content editing.
---

# qpdf PDF Operations

## Overview

Drive the [qpdf](https://qpdf.readthedocs.io) command-line tool to perform
content-preserving structural edits on PDF files: replace, insert, delete,
extract, merge, split, rotate, and reorder pages. qpdf does **not** rasterize
or re-render pages — original content streams are kept intact, so output PDFs
are lossless.

This skill does **not** cover content editing inside a page (text, images,
form filling). For those, reach for a different tool.

## Preflight: ensure qpdf is installed

Before running any operation, verify qpdf is on PATH:

```bash
bash scripts/check_qpdf.sh
```

The script prints the qpdf version on success or platform-specific install
hints (apt/dnf/brew/choco) on failure. If qpdf is missing, surface the
install hint to the user and stop — do not attempt to substitute another
tool unless asked.

## When to invoke this skill

Trigger on requests that map to page-level PDF surgery, including but not
limited to:

- "用 X.pdf 的第 1 页替换 Y.pdf 的第 3 页" → see `replace_page.sh`
- "删除第 5-7 页" / "去掉最后一页" → exclusion ranges
- "把这几个 PDF 合并成一个" / "拆成单页"
- "把第 2 页旋转 90 度" / "整个文档倒序"
- "提取第 3-5 页另存为新 PDF"
- "插入一页到现有 PDF"

## Quick task map

| Task                              | Approach                                                   |
|-----------------------------------|------------------------------------------------------------|
| Inspect (page count, encryption)  | `scripts/pdf_info.sh IN.pdf`                               |
| Replace one page                  | `scripts/replace_page.sh IN.pdf N REPL.pdf M OUT.pdf`      |
| Extract pages                     | `qpdf IN.pdf --pages . RANGE -- OUT.pdf`                   |
| Delete pages                      | `qpdf IN.pdf --pages . 1-z,xN-M -- OUT.pdf`                |
| Insert a page                     | `qpdf IN.pdf --pages . 1-K INS.pdf P . K+1-z -- OUT.pdf`   |
| Merge PDFs                        | `qpdf --empty --pages A.pdf B.pdf -- OUT.pdf`              |
| Split (one file per page)         | `qpdf IN.pdf --split-pages OUT.pdf`                        |
| Rotate pages                      | `qpdf --rotate=+90:RANGE IN.pdf OUT.pdf`                   |
| Reorder pages                     | `qpdf IN.pdf --pages . <new-order-range> -- OUT.pdf`       |
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

Once this model is clear, replace/insert/delete/reorder/merge all reduce to
choosing the right list of pairs.

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

## Bundled resources

- `scripts/check_qpdf.sh` — detect qpdf and print install hints.
- `scripts/pdf_info.sh` — page count, encryption status, integrity check.
- `scripts/replace_page.sh` — replace page N of one PDF with page M of
  another; handles first-page and last-page edge cases.
- `references/recipes.md` — copy-pasteable recipes for every supported
  operation, with edge cases and gotchas. Load when the requested operation
  is non-trivial or unfamiliar.
- `references/page-ranges.md` — full grammar of qpdf page ranges (`r1`, `z`,
  `x` exclusion, `:even`/`:odd`, reversal). Load whenever a request requires
  a non-obvious range.

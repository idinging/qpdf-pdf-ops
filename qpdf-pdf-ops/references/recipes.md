# qpdf Recipes

Copy-pasteable recipes for common PDF operations with qpdf 11.x. All examples
write a **new** output file — qpdf refuses to overwrite the input in place
unless `--replace-input` is used.

> Notation: `IN`, `OUT`, `A`, `B`, `WM` are placeholders for filenames.
> `RANGE` is qpdf page-range syntax (see `references/page-ranges.md`).

## 1. Inspect a PDF

```bash
qpdf --show-npages IN.pdf            # page count
qpdf --is-encrypted IN.pdf; echo $?  # 0 = encrypted, 2 = not
qpdf --check IN.pdf                  # structural sanity check
qpdf --show-pages IN.pdf | head      # per-page object info
```

The bundled `scripts/pdf_info.sh IN.pdf` wraps the first three.

## 2. Extract pages → new PDF

```bash
qpdf IN.pdf --pages . RANGE -- OUT.pdf
```

Examples:

```bash
# Only page 3
qpdf IN.pdf --pages . 3 -- page3.pdf

# Pages 2-5
qpdf IN.pdf --pages . 2-5 -- pages2-5.pdf

# First and last page
qpdf IN.pdf --pages . 1,z -- ends.pdf
```

The `.` is shorthand for the primary input file.

## 3. Delete pages

Deletion is "select everything except the deleted pages" using the `x`
exclusion operator:

```bash
# Drop page 3
qpdf IN.pdf --pages . 1-z,x3 -- OUT.pdf

# Drop pages 3-5
qpdf IN.pdf --pages . 1-z,x3-5 -- OUT.pdf

# Drop the last page
qpdf IN.pdf --pages . 1-r2 -- OUT.pdf
```

## 4. Replace a page

Stitch: pages before + replacement + pages after. Use the bundled helper:

```bash
scripts/replace_page.sh IN.pdf <page_num> REPL.pdf <repl_page> OUT.pdf
```

Or call qpdf directly. To replace page 3 of `IN.pdf` with page 1 of `REPL.pdf`:

```bash
qpdf IN.pdf --pages . 1-2 REPL.pdf 1 . 4-z -- OUT.pdf
```

Edge cases:

- Replacing the **first** page: omit the leading `. 1-2` segment.

  ```bash
  qpdf IN.pdf --pages REPL.pdf 1 . 2-z -- OUT.pdf
  ```

- Replacing the **last** page: omit the trailing `. N-z` segment.

  ```bash
  qpdf IN.pdf --pages . 1-r2 REPL.pdf 1 -- OUT.pdf
  ```

## 5. Insert a page (without replacing)

To **insert** a page from `INS.pdf` before page 3 of `IN.pdf` (so it becomes
the new page 3):

```bash
qpdf IN.pdf --pages . 1-2 INS.pdf 1 . 3-z -- OUT.pdf
```

## 6. Merge / concatenate PDFs

```bash
# Append all pages of A then all of B onto IN; document-level info from IN is kept
qpdf IN.pdf --pages . A.pdf B.pdf -- OUT.pdf

# Start from scratch (no carryover metadata)
qpdf --empty --pages A.pdf B.pdf C.pdf -- OUT.pdf

# Merge with specific ranges
qpdf --empty --pages A.pdf 1-5 B.pdf z-1 C.pdf 3,6 -- OUT.pdf
```

## 7. Split a PDF

```bash
# One file per page (output-1.pdf, output-2.pdf, ...)
qpdf IN.pdf --split-pages output.pdf

# One file per N pages
qpdf IN.pdf --split-pages=10 output.pdf

# Custom naming with %d placeholder for zero-padded page index
qpdf IN.pdf --split-pages chunk-%d.pdf
```

## 8. Rotate pages

`--rotate=[+|-]angle[:RANGE]`. Always prefer relative angles (`+90`, `-90`).

```bash
# Rotate every page 90° clockwise
qpdf --rotate=+90 IN.pdf OUT.pdf

# Rotate only pages 2 and 4-6 by 180°
qpdf --rotate=+180:2,4-6 IN.pdf OUT.pdf

# Counter-clockwise 90°
qpdf --rotate=-90 IN.pdf OUT.pdf
```

Multiple `--rotate` options can stack in a single invocation:

```bash
qpdf --rotate=+90:1 --rotate=+180:z IN.pdf OUT.pdf
```

## 9. Reorder pages

Re-list every page in the desired order:

```bash
# Reverse the document
qpdf IN.pdf --pages . z-1 -- OUT.pdf

# Move page 5 to the front
qpdf IN.pdf --pages . 5 1-4,6-z -- OUT.pdf

# Custom order: 3, 1, 2, then the rest
qpdf IN.pdf --pages . 3,1,2,4-z -- OUT.pdf
```

## 10. Collate pages (alternating from multiple files)

```bash
# Interleave 1 page from A, 1 from B, repeating
qpdf --empty --pages A.pdf B.pdf --collate -- OUT.pdf

# 2 from A, then 1 from B, repeating
qpdf --empty --pages A.pdf B.pdf --collate=2,1 -- OUT.pdf
```

Useful for combining odd/even scans from a duplex-less scanner.

## 11. Overwrite the original file safely

By default qpdf refuses to write back to its input. Use `--replace-input` to
overwrite atomically (qpdf writes to a temp file then renames):

```bash
qpdf --rotate=+90 IN.pdf --replace-input
```

When `--replace-input` is used, no output filename is given.

## 12. Linearize (optimize for web)

```bash
qpdf --linearize IN.pdf OUT.pdf
```

## Gotchas

- The `--` separator after `--pages ...` is **mandatory**; it tells qpdf the
  page-selection block has ended.
- Filenames containing leading dashes need `./` prefix or `--` separators to
  avoid being parsed as options.
- `--pages` rebuilds the document; some annotations or form fields that
  reference removed pages may break. Use `--check OUT.pdf` to sanity-check.
- Document-level info (outlines, tags, metadata) comes from the **primary
  input** (the file before `--pages`), not from `--empty` or later files.

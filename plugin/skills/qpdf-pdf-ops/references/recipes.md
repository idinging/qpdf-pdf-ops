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

## 12. Encrypted / password-protected PDFs

### Detect encryption

```bash
qpdf --is-encrypted IN.pdf   # exit 0 = encrypted, 2 = not encrypted
```

The bundled `scripts/pdf_info.sh` already does this and prints a friendly line.

### Operate on an encrypted PDF

Every read-side flag accepts `--password=...`. The password applies to the
**preceding** input file in `--pages` (qpdf reads them positionally):

```bash
# Inspect
qpdf --password=secret --show-npages IN.pdf

# Extract pages
qpdf --password=secret IN.pdf --pages . 1-3 -- OUT.pdf

# Merge two protected files (each gets its own --password)
qpdf --empty \
     --pages --password=pw-a A.pdf \
             --password=pw-b B.pdf -- OUT.pdf
```

### Remove the password

```bash
qpdf --password=secret --decrypt IN.pdf OUT.pdf
```

OUT.pdf is unencrypted; downstream commands no longer need `--password`.

### Add / change encryption

`--encrypt` takes the user password, owner password, key length, then any
permission flags, then `--`:

```bash
# AES-256, same password for user/owner, default permissions
qpdf --encrypt secret secret 256 -- IN.pdf OUT.pdf

# Restrict printing; let the owner password override
qpdf --encrypt user-pw owner-pw 256 --print=none -- IN.pdf OUT.pdf
```

### Workflow note

If a user asks for an operation on an encrypted PDF without providing the
password, stop and ask — never guess passwords and never strip encryption
without being asked.

## 13. Optimize / linearize

```bash
# Linearize: enables "fast web view" — browsers can render page 1 before
# the rest downloads. Use this for PDFs served from a web server.
qpdf --linearize IN.pdf OUT.pdf

# Recompress object streams for a smaller file (qpdf does NOT recompress
# images; for that, use a separate tool like Ghostscript).
qpdf --object-streams=generate --compress-streams=y IN.pdf OUT.pdf

# Strip metadata while you're at it
qpdf --linearize --remove-metadata IN.pdf OUT.pdf
```

qpdf will not aggressively shrink a PDF the way Ghostscript or `pdf2ps` round-trips
do — its job is to preserve content. Tell the user when their goal is "make
this PDF smaller" so they can pick the right tool.

## 14. Attachments

```bash
# List embedded file attachments
qpdf --list-attachments IN.pdf

# Show a specific attachment (raw bytes to stdout)
qpdf --show-attachment=NAME IN.pdf > extracted.bin

# Add an attachment
qpdf IN.pdf --add-attachment file.txt -- OUT.pdf

# Remove an attachment by key
qpdf IN.pdf --remove-attachment=NAME -- OUT.pdf
```

## 15. Debug / inspect structure (`--qdf`)

```bash
# Write a "QDF" file: uncompressed, human-readable PDF source for diffing
qpdf --qdf IN.pdf OUT.qdf.pdf
```

Useful for understanding what changed between two qpdf invocations, or for
hand-patching object streams. Don't ship a QDF file as the final output —
it's many times larger than a normal PDF.

## Gotchas

- The `--` separator after `--pages ...` is **mandatory**; it tells qpdf the
  page-selection block has ended.
- Filenames containing leading dashes need `./` prefix or `--` separators to
  avoid being parsed as options. Filenames containing spaces or non-ASCII
  characters (Chinese, emoji, etc.) work fine but must be quoted in shell.
- `--pages` rebuilds the document; some annotations or form fields that
  reference removed pages may break. Use `--check OUT.pdf` to sanity-check.
- Document-level info (outlines, tags, metadata) comes from the **primary
  input** (the file before `--pages`), not from `--empty` or later files.
- qpdf does **not** do OCR, content editing, form filling, image
  recompression, signing, or format conversion. Page-level structural ops
  only.
- For encrypted inputs, `--password=` must precede the file it unlocks
  (positional). See recipe 12 for the full grammar.

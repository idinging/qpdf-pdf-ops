# qpdf Page Range Syntax

Reference for the page-range mini-language used inside `--pages ... --` and
`--rotate=...:RANGE`. Pulled from `qpdf --help=page-ranges` (qpdf 11.9).

## Basic tokens

| Token   | Meaning                                                   |
|---------|-----------------------------------------------------------|
| `n`     | The n-th page (1-based)                                   |
| `r<n>`  | The n-th page counted from the **end** (`r1` = last page) |
| `z`     | The last page (alias of `r1`)                             |

## Groups

| Form        | Meaning                                                       |
|-------------|---------------------------------------------------------------|
| `a,b,c`     | Pages a, b, and c (comma-separated list)                      |
| `a-b`       | Pages a through b inclusive. If `a > b`, the range counts down (reverses) |
| `a-b,xc`    | Pages a..b excluding page c                                   |
| `a-b,xc-d`  | Pages a..b excluding pages c..d                               |

The `x` prefix marks the next token as an **exclusion** from the previous group.

## Filters

Append `:even` or `:odd` to a group to keep every other page from the
**resulting set** (not from the original page numbers):

- `:odd`  → 1st, 3rd, 5th, ... of the resulting set
- `:even` → 2nd, 4th, 6th, ... of the resulting set

Example: `1-z:even` = every even-indexed page of the whole document.

## Common patterns

| Goal                            | Range                                |
|---------------------------------|--------------------------------------|
| All pages                       | `1-z` (or omit range entirely)        |
| First 3 pages                   | `1-3`                                 |
| Last page only                  | `z` or `r1`                           |
| Last 5 pages                    | `r5-r1`                               |
| All but page 3                  | `1-z,x3`                              |
| Reverse the whole document      | `z-1`                                 |
| Pages 1-10 in reverse           | `10-1`                                |
| Odd pages only                  | `1-z:odd`                             |
| Even pages only                 | `1-z:even`                            |
| Pages 1, 3, and 7-9             | `1,3,7-9`                             |

## Rotate-specific notes

For `--rotate=[+|-]angle[:RANGE]`:

- Omit the range to rotate **all** pages.
- Prefer relative angles (`+90`, `-90`) over absolute (`90`, `180`) so the
  rotation composes with any existing page rotation in the source PDF.
- Example: `--rotate=+90:2,4-6` rotates pages 2, 4, 5, 6 by 90° clockwise.

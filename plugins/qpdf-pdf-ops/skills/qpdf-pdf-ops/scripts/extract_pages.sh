#!/usr/bin/env bash
# Extract one or more pages from a PDF into a new PDF.
#
# Usage:
#   extract_pages.sh <input.pdf> <range> <output.pdf>
#
# <range> uses qpdf page-range syntax (see references/page-ranges.md).
# Common forms:
#   3            page 3 only
#   2-5          pages 2 through 5
#   1,3,5-7      pages 1, 3, and 5-7
#   r3-r1        the last three pages
#   1-z:odd      odd pages
#
# Examples:
#   extract_pages.sh report.pdf 3 page3.pdf
#   extract_pages.sh report.pdf 2-5 chapter1.pdf
#   extract_pages.sh report.pdf 1-z:even even-pages.pdf

set -euo pipefail

if [[ $# -ne 3 ]]; then
    cat >&2 <<EOF
Usage: $0 <input.pdf> <range> <output.pdf>

  input.pdf      Source PDF
  range          qpdf page-range of pages to KEEP (e.g. 3, 2-5, 1,3,5-7, r3-r1)
  output.pdf     Destination file (must not equal input.pdf)
EOF
    exit 2
fi

input="$1"
range="$2"
output="$3"

if [[ ! -f "$input" ]]; then
    echo "Input not found: $input" >&2; exit 2
fi
if [[ "$input" -ef "$output" ]]; then
    echo "Refusing to overwrite input in place. Choose a different output path." >&2
    exit 2
fi

out_dir=$(dirname -- "$output")
if [[ -n "$out_dir" && ! -d "$out_dir" ]]; then
    mkdir -p -- "$out_dir"
fi

total=$(qpdf --show-npages "$input")

qpdf "$input" --pages . "$range" -- "$output"

new_total=$(qpdf --show-npages "$output")
echo "Wrote $output (extracted ${new_total} pages from ${total}; range: ${range})"

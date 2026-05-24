#!/usr/bin/env bash
# Delete one or more pages from a PDF.
#
# Usage:
#   delete_pages.sh <input.pdf> <range> <output.pdf>
#
# <range> uses qpdf page-range syntax of the pages to REMOVE, NOT to keep.
# Common forms:
#   3            delete page 3
#   3-5          delete pages 3 through 5
#   1,4,7-9      delete pages 1, 4, and 7-9
#   z            delete the last page
#   r1-r3        delete the last 3 pages
#
# Examples:
#   delete_pages.sh report.pdf 3 report-no3.pdf
#   delete_pages.sh report.pdf 3-5 report-trim.pdf
#   delete_pages.sh report.pdf z report-no-last.pdf

set -euo pipefail

if [[ $# -ne 3 ]]; then
    cat >&2 <<EOF
Usage: $0 <input.pdf> <range> <output.pdf>

  input.pdf      Source PDF
  range          qpdf page-range of pages to DELETE (e.g. 3, 3-5, 1,4,7-9, z)
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

# Translate "delete range" into qpdf's "keep everything except range":
#   --pages . 1-z,x<range> --
# Guard against deleting every page.
qpdf "$input" --pages . "1-z,x${range}" -- "$output"

new_total=$(qpdf --show-npages "$output")
echo "Wrote $output (${total} pages -> ${new_total} pages; removed: ${range})"

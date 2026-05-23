#!/usr/bin/env bash
# Replace one page in a PDF with a page taken from another PDF.
#
# Usage:
#   replace_page.sh <input.pdf> <page_num> <replacement.pdf> <replacement_page> <output.pdf>
#
# Example:
#   replace_page.sh report.pdf 3 cover.pdf 1 report-fixed.pdf
#   -> output has report.pdf's pages with page 3 replaced by cover.pdf's page 1.
#
# Implementation: qpdf --pages stitches three ranges from the original file
# (pages before, the replacement page, pages after) into one output.

set -euo pipefail

if [[ $# -ne 5 ]]; then
    cat >&2 <<EOF
Usage: $0 <input.pdf> <page_num> <replacement.pdf> <replacement_page> <output.pdf>

  input.pdf          PDF whose page will be replaced
  page_num           1-based page index in input.pdf to replace
  replacement.pdf    PDF that supplies the replacement page
  replacement_page   1-based page index in replacement.pdf
  output.pdf         Destination file (must not equal input.pdf)
EOF
    exit 2
fi

input="$1"
page_num="$2"
repl="$3"
repl_page="$4"
output="$5"

if [[ ! -f "$input" ]];   then echo "Input not found: $input" >&2; exit 2; fi
if [[ ! -f "$repl" ]];    then echo "Replacement not found: $repl" >&2; exit 2; fi
if [[ "$input" -ef "$output" ]]; then
    echo "Refusing to overwrite input in place. Choose a different output path." >&2
    exit 2
fi
if ! [[ "$page_num" =~ ^[0-9]+$ ]] || [[ "$page_num" -lt 1 ]]; then
    echo "page_num must be a positive integer" >&2; exit 2
fi
if ! [[ "$repl_page" =~ ^[0-9]+$ ]] || [[ "$repl_page" -lt 1 ]]; then
    echo "replacement_page must be a positive integer" >&2; exit 2
fi

total=$(qpdf --show-npages "$input")
if [[ "$page_num" -gt "$total" ]]; then
    echo "page_num ($page_num) exceeds total pages ($total) in $input" >&2
    exit 2
fi

# Build the page list:
#  - pages 1 .. (page_num-1) from input
#  - replacement page from repl
#  - pages (page_num+1) .. end from input
args=( "$input" --pages )

if [[ "$page_num" -gt 1 ]]; then
    args+=( . "1-$((page_num - 1))" )
fi

args+=( "$repl" "$repl_page" )

if [[ "$page_num" -lt "$total" ]]; then
    args+=( . "$((page_num + 1))-z" )
fi

args+=( -- "$output" )

qpdf "${args[@]}"
echo "Wrote $output (replaced page $page_num of $input with page $repl_page of $repl)"

#!/usr/bin/env bash
# Split a PDF into multiple smaller PDFs.
#
# Usage:
#   split_pdf.sh <input.pdf> <out_dir> [pages_per_chunk]
#
# pages_per_chunk defaults to 1 (one file per page).
#
# Output files land in <out_dir>/ named "<basename>-NN.pdf" where NN is the
# zero-padded chunk index (qpdf chooses the width automatically).
#
# Examples:
#   split_pdf.sh report.pdf chunks/        # one file per page
#   split_pdf.sh report.pdf chunks/ 10     # ten pages per file

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
    cat >&2 <<EOF
Usage: $0 <input.pdf> <out_dir> [pages_per_chunk]

  input.pdf          Source PDF
  out_dir            Destination directory (created if missing)
  pages_per_chunk    Pages per output file (default 1)
EOF
    exit 2
fi

input="$1"
out_dir="$2"
per_chunk="${3:-1}"

if [[ ! -f "$input" ]]; then
    echo "Input not found: $input" >&2; exit 2
fi
if ! [[ "$per_chunk" =~ ^[0-9]+$ ]] || [[ "$per_chunk" -lt 1 ]]; then
    echo "pages_per_chunk must be a positive integer" >&2; exit 2
fi

mkdir -p -- "$out_dir"

base=$(basename -- "$input")
stem="${base%.pdf}"
prefix="${out_dir%/}/${stem}.pdf"

if [[ "$per_chunk" -eq 1 ]]; then
    qpdf "$input" --split-pages "$prefix"
else
    qpdf "$input" --split-pages="$per_chunk" "$prefix"
fi

count=$(find "$out_dir" -maxdepth 1 -name "${stem}-*.pdf" -type f | wc -l)
echo "Wrote ${count} files to ${out_dir}/ (prefix: ${stem}-NN.pdf)"
